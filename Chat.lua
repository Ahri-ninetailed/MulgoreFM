-- Mulgore FM: chat events.
--
-- All chat events are registered here, once. Payload positions (Forever
-- 1.60.1 ChatInfoDocumentation): 1 text, 2 playerName, 11 lineID, 12 guid.
-- Text and name may be secret during chat messaging lockdown; such messages
-- are skipped untouched. NPC, system, combat log and addon traffic is never
-- registered, and the addon never sends chat messages.
--
-- The same lineID delivered twice is played once (always, even without
-- anti-spam). Messages without a lineID are never merged by text. Pacing per
-- sender (the 250 ms gap, one waiting message with anti-spam) lives in
-- Playback's lanes; nothing about a message is stored.
local _, ns = ...

local Chat = {}
ns.Chat = Chat

local EVENT_GROUP = {
	CHAT_MSG_SAY = "say",
	CHAT_MSG_YELL = "say",
	CHAT_MSG_CHANNEL = "channel",
	CHAT_MSG_PARTY = "group",
	CHAT_MSG_PARTY_LEADER = "group",
	CHAT_MSG_RAID = "group",
	CHAT_MSG_RAID_LEADER = "group",
	CHAT_MSG_RAID_WARNING = "group",
	CHAT_MSG_INSTANCE_CHAT = "group",
	CHAT_MSG_INSTANCE_CHAT_LEADER = "group",
	CHAT_MSG_GUILD = "guild",
	CHAT_MSG_OFFICER = "guild",
	CHAT_MSG_WHISPER = "whisper",
	CHAT_MSG_WHISPER_INFORM = "whisper", -- sent whisper: playerName is the recipient
}
Chat.EVENT_GROUP = EVENT_GROUP

local DEDUP_SIZE = 128
local DEDUP_TTL = 120

local IsSecret = ns.Voices.IsSecret
local registered = false
local requests = {}

-------------------------------------------------------------------------------
-- Technical duplicates: a ring of recent line IDs
-------------------------------------------------------------------------------
local ringIds, ringTimes, seenAt = {}, {}, {}
local ringPos = 0

local function SeenLine(lineID, now)
	local t = seenAt[lineID]
	if t and now - t <= DEDUP_TTL then
		return true
	end
	ringPos = ringPos % DEDUP_SIZE + 1
	local old = ringIds[ringPos]
	if old ~= nil and seenAt[old] == ringTimes[ringPos] then
		seenAt[old] = nil
	end
	ringIds[ringPos] = lineID
	ringTimes[ringPos] = now
	seenAt[lineID] = now
	return false
end

-------------------------------------------------------------------------------
-- Handler
-------------------------------------------------------------------------------
local function InLockdown()
	local info = C_ChatInfo
	if info and type(info.InChatMessagingLockdown) == "function" then
		local ok, restricted = pcall(info.InChatMessagingLockdown)
		return ok and restricted == true
	end
	return false
end

local function IsOwnGuid(guid)
	if type(guid) ~= "string" or guid == "" or IsSecret(guid) or type(UnitGUID) ~= "function" then
		return false
	end
	local mine = UnitGUID("player")
	return type(mine) == "string" and not IsSecret(mine) and guid == mine
end

local function SenderKey(event, sender, guid)
	local own = ns.Voices.OwnKey()
	if event == "CHAT_MSG_WHISPER_INFORM" or IsOwnGuid(guid) then
		return own, true
	end
	local key = ns.Voices.CanonicalKey(sender)
	if key then
		return key, own ~= nil and key == own
	end
	if type(guid) == "string" and not IsSecret(guid) and guid:find("^Player%-") then
		return "guid:" .. guid, false
	end
	return nil, false
end

function Chat.OnEvent(event, text, sender, _, _, _, _, _, _, _, _, lineID, guid)
	local db = ns.db
	if not db or not db.enabled or not db.sound then
		return
	end
	local group = EVENT_GROUP[event]
	if not group or not db.groups[group] then
		return
	end
	if IsSecret(text) or IsSecret(sender) then
		ns.Count("skip_secret")
		return
	end
	if type(text) ~= "string" or text == "" or not ns.Parser.MayContain(text) then
		return
	end
	if InLockdown() then
		ns.Count("skip_lockdown")
		return
	end
	local now = GetTime()
	if type(lineID) == "number" and lineID > 0 and not IsSecret(lineID) and SeenLine(lineID, now) then
		ns.Count("skip_duplicate")
		ns.Debug("skip: duplicate line")
		return
	end

	for k in pairs(requests) do
		requests[k] = nil
	end
	local _, count = ns.Parser.Parse(text, ns.MAX_TOKENS_PER_MESSAGE, requests, db.inWords)
	if count == 0 then
		return
	end
	ns.Count("messages_matched")

	local key, isSelf = SenderKey(event, sender, guid)
	if isSelf and not db.ownMessages then
		ns.Count("skip_own")
		return
	end
	if not key then
		ns.Count("skip_nokey")
		ns.Debug("skip: no sender key")
		return
	end
	local voice = ns.Voices.VoiceForKey(key) -- once per message; all its moos share it
	if not voice then
		ns.Count("drop_profile_missing", count)
		return
	end
	local accepted, refused = ns.Playback.Enqueue(key, voice, requests, count, db.maxPending, "chat")
	if refused == "spam" then
		ns.Debug("skip: sender already has a message waiting")
	elseif accepted < count and refused == nil then
		ns.Count("drop_queue_full", count - accepted)
		ns.Debug("queue full: %d of %d dropped", count - accepted, count)
	end
end

function Chat.Init()
	if registered then
		return
	end
	registered = true
	for event in pairs(EVENT_GROUP) do
		ns.RegisterEvent(event, Chat.OnEvent)
	end
end
