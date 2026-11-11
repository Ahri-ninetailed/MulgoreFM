-- Mulgore FM: playback, one lane per sender.
--
-- Every sender (the full sender key, not the cow) has a lane. A lane plays its
-- calls in written order, one at a time; different lanes play at the same
-- time, so several players mooing together are heard together. Two players who
-- share a cow still have separate lanes.
--
-- Between the actual end of the last sound of a sender's previous message and
-- the first sound of their next message there are at least MESSAGE_GAP seconds;
-- silence that already passed counts. Inside one message the next call starts
-- as soon as the previous one has ended. The gap is measured from the computed
-- end of the sound (start + OGG duration, or the moment it was stopped), not
-- from when a timer noticed it, so timer granularity cannot stretch it.
--
-- End detection per sound: with a handle and C_Sound.IsPlaying the sound is
-- checked every POLL_INTERVAL seconds while it plays; never seen playing after
-- START_GRACE -> wait out the duration; still playing after duration +
-- STUCK_MARGIN -> StopSound. Without a handle the manifest duration plus
-- END_MARGIN is used. Each sound has its own token; a timer or event carrying
-- an old token is ignored, so nothing stale can end another call.
--
-- Capacity: calls playing plus calls waiting, over all lanes, never exceed
-- maxPending + 1. With anti-spam on, a sender can have at most one message
-- waiting behind the one they are mooing. All sound goes to the SFX channel.
local _, ns = ...

local Playback = {}
ns.Playback = Playback

local CHANNEL = "SFX"
local POLL_INTERVAL = 0.25
local START_GRACE = 0.30
local END_MARGIN = 0.15
local STUCK_MARGIN = 1.0
local MAX_ATTEMPTS = 3
local MESSAGE_GAP = 0.25
local LANE_PRUNE_AT = 32

Playback.CHANNEL = CHANNEL
Playback.POLL_INTERVAL = POLL_INTERVAL
Playback.START_GRACE = START_GRACE
Playback.END_MARGIN = END_MARGIN
Playback.STUCK_MARGIN = STUCK_MARGIN
Playback.MAX_ATTEMPTS = MAX_ATTEMPTS
Playback.MESSAGE_GAP = MESSAGE_GAP

local lanes = {}
local laneCount = 0
local serial = 0
local delaySerial = 0

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
local function Waiting(lane)
	return lane.tail - lane.head + 1
end

local function Idle(lane)
	return not lane.active and not lane.delayed and lane.head > lane.tail
end

-- Calls waiting to start, over all lanes.
function Playback.PendingCount()
	local count = 0
	for _, lane in pairs(lanes) do
		count = count + Waiting(lane)
	end
	return count
end

-- Calls sounding right now.
function Playback.ActiveCount()
	local count = 0
	for _, lane in pairs(lanes) do
		if lane.active then
			count = count + 1
		end
	end
	return count
end

function Playback.IsActive()
	return Playback.ActiveCount() > 0
end

function Playback.LaneCount()
	return laneCount
end

-- Room for new calls: playing plus waiting stays within maxPending + 1.
function Playback.FreeSlots(maxPending)
	local free = maxPending + 1 - Playback.PendingCount() - Playback.ActiveCount()
	return free > 0 and free or 0
end

-- SFX state from the game's sound CVars: true, false, or nil if unknown. Read only.
function Playback.ChannelEnabled()
	local get = C_CVar and C_CVar.GetCVarBool or GetCVarBool
	if type(get) ~= "function" then
		return nil
	end
	local okAll, all = pcall(get, "Sound_EnableAllSound")
	local okSfx, sfx = pcall(get, "Sound_EnableSFX")
	if not okAll or all == nil or not okSfx or sfx == nil then
		return nil
	end
	return (all and sfx) and true or false
end

-- The copy of an entry at a "Moo volume" step; the catalog's originalLevel
-- (20) is the original file itself.
function Playback.PathFor(entry, volume)
	local catalog = ns.AudioCatalog
	if not volume or not entry.file or not catalog or type(catalog.levelPath) ~= "string"
		or volume == catalog.originalLevel or not (catalog.levelGainDb and catalog.levelGainDb[volume]) then
		return entry.path
	end
	return string.format(catalog.levelPath, volume, entry.file)
end

-------------------------------------------------------------------------------
-- Ending a sound
-------------------------------------------------------------------------------
local PumpLane -- forward

local function Finish(lane, token, actualEnd)
	local active = lane.active
	if not active or active.token ~= token then
		return
	end
	lane.active = nil
	lane.lastEnd = actualEnd
	ns.Count("finished")
	PumpLane(lane)
end

local function Schedule(lane, delay, token, callback)
	C_Timer.After(delay, function()
		local active = lane.active
		if active and active.token == token then
			callback(lane, token)
		end
	end)
end

local function NominalEnd(active)
	return active.started + active.duration
end

local function FinishAtNominalEnd(lane, token)
	Finish(lane, token, NominalEnd(lane.active))
end

local function FinishAfterDuration(lane, token)
	local active = lane.active
	local remaining = NominalEnd(active) + END_MARGIN - GetTime()
	if remaining <= 0 then
		Finish(lane, token, math.min(GetTime(), NominalEnd(active)))
	else
		active.mode = "timer"
		Schedule(lane, remaining, token, FinishAtNominalEnd)
	end
end

local function StopHandle(handle)
	return handle ~= nil and type(StopSound) == "function" and (pcall(StopSound, handle))
end

local function Poll(lane, token)
	local active = lane.active
	local now = GetTime()
	local isPlaying = C_Sound and C_Sound.IsPlaying
	local ok, playing = false, nil
	if type(isPlaying) == "function" then
		ok, playing = pcall(isPlaying, active.handle)
	end
	if not ok then
		FinishAfterDuration(lane, token) -- the check stopped working: use the duration
		return
	end
	if playing then
		active.seenPlaying = true
		if now >= NominalEnd(active) + STUCK_MARGIN then
			ns.Count("stuck_stopped")
			StopHandle(active.handle)
			Finish(lane, token, now)
			return
		end
	elseif active.seenPlaying then
		Finish(lane, token, math.min(now, NominalEnd(active)))
		return
	elseif now - active.started >= START_GRACE then
		ns.Count("handle_lost")
		FinishAfterDuration(lane, token)
		return
	end
	Schedule(lane, POLL_INTERVAL, token, Poll)
end

-------------------------------------------------------------------------------
-- Starting a sound
-------------------------------------------------------------------------------

-- Up to MAX_ATTEMPTS starts: the entry at the chosen volume, then (if that copy
-- fails) its original file, then other files of the same voice.
local function TryPlay(item)
	local volume = ns.db and ns.db.volume or (ns.AudioCatalog and ns.AudioCatalog.originalLevel)
	local entry = item.entry
	local tried
	local attempts = 0
	while entry do
		local chosen = Playback.PathFor(entry, volume)
		local candidates = { chosen }
		if chosen ~= entry.path then
			candidates[2] = entry.path
		end
		for index, path in ipairs(candidates) do
			if attempts >= MAX_ATTEMPTS then
				return nil, "play_failed"
			end
			attempts = attempts + 1
			local ok, willPlay, handle = pcall(PlaySoundFile, path, CHANNEL)
			if ok and willPlay then
				if index > 1 then
					ns.Count("fallback_level")
				end
				return entry, handle, path
			end
			ns.Count("play_failed")
			if Playback.ChannelEnabled() == false then
				return nil, "channel_off"
			end
		end
		tried = tried or {}
		tried[entry.path] = true
		entry = ns.Voices.Select(item.voice, item.emotion, item.length, false, tried)
	end
	return nil, "play_failed"
end

local function Start(lane, item)
	if ns.db and not ns.db.sound then
		ns.Count("skip_muted")
		return false
	end
	local entry, handle, path = TryPlay(item)
	if not entry then
		if handle == "channel_off" then
			ns.Count("drop_channel_off")
			ns.Notice("channel_off", ns.L.CHANNEL_OFF, 120)
		else
			ns.Count("drop_play_failed")
			ns.Notice("play_failed", ns.L.PLAY_FAILED, 120)
		end
		ns.Debug("skip: %s %s/%s, %s", item.voice, item.emotion, item.length, tostring(handle))
		return false
	end
	if entry ~= item.entry then
		ns.Count("fallback_file")
	end
	serial = serial + 1
	local token = serial
	local active = {
		token = token,
		item = item,
		entry = entry,
		path = path,
		handle = type(handle) == "number" and handle or nil,
		started = GetTime(),
		duration = entry.duration,
	}
	lane.active = active
	ns.Count("played")
	ns.lastPlayed = {
		voice = item.voice, reqEmotion = item.emotion, reqLength = item.length,
		emotion = entry.emotion, length = entry.class, path = path, source = item.source,
	}
	ns.Debug("play %s: asked %s/%s, got %s/%s, %s · sounding %d, waiting %d", item.voice, item.emotion, item.length,
		entry.emotion, entry.class, path:match("[^\\]+\\[^\\]+\\[^\\]+$") or path, Playback.ActiveCount(),
		Playback.PendingCount())
	if Playback.TestHook then -- nil in the game; the offline tests set it
		Playback.TestHook(lane.key, item)
	end
	if active.handle and C_Sound and type(C_Sound.IsPlaying) == "function" then
		active.mode = "poll"
		Schedule(lane, POLL_INTERVAL, token, Poll)
	else
		active.mode = "timer"
		Schedule(lane, entry.duration + END_MARGIN, token, FinishAtNominalEnd)
	end
	return true
end

-- Waits until `wait` seconds from now, then tries the lane again.
local function Delay(lane, wait)
	delaySerial = delaySerial + 1
	local id = delaySerial
	lane.delayed = id
	C_Timer.After(wait, function()
		if lanes[lane.key] == lane and lane.delayed == id then
			lane.delayed = nil
			PumpLane(lane)
		end
	end)
end

PumpLane = function(lane)
	if lane.pumping then
		return
	end
	lane.pumping = true
	while not lane.active and not lane.delayed and lane.head <= lane.tail do
		local item = lane.items[lane.head]
		if item.first and lane.lastEnd then
			local wait = lane.lastEnd + MESSAGE_GAP - GetTime()
			if wait > 1e-9 then
				Delay(lane, wait)
				break
			end
		end
		lane.items[lane.head] = nil
		lane.head = lane.head + 1
		if item.first then
			lane.waitingMessages = lane.waitingMessages - 1
		end
		Start(lane, item)
	end
	if lane.head > lane.tail then
		lane.head, lane.tail = 1, 0
	end
	lane.pumping = false
end

-- Forgets lanes that are idle and whose gap has run out.
local function PruneLanes()
	local now = GetTime()
	for key, lane in pairs(lanes) do
		if Idle(lane) and (not lane.lastEnd or now - lane.lastEnd >= MESSAGE_GAP) then
			lanes[key] = nil
			laneCount = laneCount - 1
		end
	end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Queues up to `count` requests of one message from sender `key` (cow `voice`)
-- in written order. Returns the number accepted, plus "muted" or "spam" when
-- the whole message was refused for that reason.
function Playback.Enqueue(key, voice, requests, count, maxPending, source)
	local db = ns.db
	if not db or not db.sound then
		return 0, "muted"
	end
	local lane = lanes[key]
	if db.antispam and lane and lane.waitingMessages >= 1 then
		ns.Count("skip_spam")
		return 0, "spam"
	end
	local free = Playback.FreeSlots(maxPending)
	if free == 0 then
		return 0
	end
	if not lane then
		if laneCount >= LANE_PRUNE_AT then
			PruneLanes()
		end
		lane = { key = key, voice = voice, items = {}, head = 1, tail = 0, waitingMessages = 0 }
		lanes[key] = lane
		laneCount = laneCount + 1
	end
	local accepted = 0
	for i = 1, count do
		if accepted >= free then
			break
		end
		local request = requests[i]
		-- Where a cow has several takes of the chosen call, one is picked at random.
		local entry = ns.Voices.Select(voice, request.emotion, request.length, true)
		if entry then
			lane.tail = lane.tail + 1
			lane.items[lane.tail] = {
				voice = voice, emotion = request.emotion, length = request.length, entry = entry,
				source = source, first = accepted == 0,
			}
			accepted = accepted + 1
		else
			ns.Count("drop_profile_missing")
		end
	end
	if accepted > 0 then
		lane.waitingMessages = lane.waitingMessages + 1
		ns.Count("queued", accepted)
		PumpLane(lane)
	end
	return accepted
end

-- Drops every waiting call of every sender and stops every sound this addon is
-- playing when StopSound works. A sound that cannot be stopped plays out, and
-- its sender's next call waits for it (plus the gap); other senders are free.
function Playback.Clear()
	ns.Count("cleared")
	local now = GetTime()
	for _, lane in pairs(lanes) do
		for i = lane.head, lane.tail do
			lane.items[i] = nil
		end
		lane.head, lane.tail, lane.waitingMessages, lane.delayed = 1, 0, 0, nil
		local active = lane.active
		if active then
			if StopHandle(active.handle) then
				lane.active = nil
				lane.lastEnd = now
			else
				active.cleared = true
			end
		end
	end
end

-- SOUNDKIT_FINISHED(soundHandle)
function Playback.OnSoundFinished(handle)
	if handle == nil then
		return
	end
	for _, lane in pairs(lanes) do
		local active = lane.active
		if active and active.handle == handle then
			Finish(lane, active.token, GetTime())
			return
		end
	end
end

-- For tests and /mfm status.
function Playback.LaneInfo(key)
	local lane = lanes[key]
	if not lane then
		return nil
	end
	return {
		waiting = Waiting(lane), messages = lane.waitingMessages, lastEnd = lane.lastEnd,
		delayed = lane.delayed ~= nil, active = lane.active and lane.active.path or nil,
		cleared = lane.active and lane.active.cleared == true or false,
	}
end
