-- Mulgore FM: namespace, constants, saved settings, messages, events and slash commands.
local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
-- The version comes from the TOC, where the release packager writes the tag;
-- an unpackaged copy still holds the "@project-version@" keyword and shows "dev".
local function AddonVersion()
	local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	local ok, version = pcall(get, ADDON_NAME, "Version")
	if ok and type(version) == "string" and version ~= "" and not version:find("@", 1, true) then
		return (version:gsub("^v", "")) -- the packager writes the tag, "v1.0.0"
	end
	return "dev"
end
ns.VERSION = AddonVersion()
ns.SCHEMA_VERSION = 5

ns.MAX_TOKENS_PER_MESSAGE = 3 -- moos taken from one chat message, in written order
ns.MAX_PENDING_MIN = 1
ns.MAX_PENDING_MAX = 30
ns.VOLUME_STEP_MIN = 10 -- "Moo volume" steps of 10: 20 is the original recording, 50 about +10 dB
ns.VOLUME_STEP_MAX = 100 -- (clean), 60-100 louder still with soft clipping. 0 on the slider = "Moo sounds" off.

-------------------------------------------------------------------------------
-- Localization (English default, Russian when the client runs ruRU)
-------------------------------------------------------------------------------
local isRU = type(GetLocale) == "function" and GetLocale() == "ruRU"
local L = {}
ns.L = L
local function T(key, en, ru)
	L[key] = isRU and ru or en
end

T("ENABLED", "Addon enabled", "Аддон включён")
T("ENABLED_TIP", "React to chat: a standalone moo in chat becomes a cow call.",
	"Реагировать на чат: отдельное «му» в чате звучит коровьим мычанием.")
T("SOUND", "Moo sounds", "Звук коров")
T("SOUND_TIP", "Off: the cows are silent at once, waiting calls are dropped and new moos are not queued. On: the last volume comes back. Calls play on the game's Sound Effects channel, so they are also silent while the game's sound effects or all sound are off.",
	"Выкл.: коровы сразу замолкают, ожидающие реплики удаляются, новые «му» в очередь не попадают. Вкл.: возвращается прежняя громкость. Реплики идут через канал звуковых эффектов игры, поэтому молчат и тогда, когда в игре выключены эффекты или весь звук.")
T("VOLUME", "Moo volume", "Громкость му")
T("VOLUME_TIP", "20% plays the recordings as they are, 50% is about twice as loud, 60-100% louder still with a slight overdrive, like a cow at full voice. Moving it to 0 turns Moo sounds off. Works on top of the game's Master and Effects sliders, which the addon never changes.",
	"20% — записи как есть, 50% — примерно вдвое громче, 60–100% ещё громче с лёгким перегрузом, как корова в полный голос. Положение 0 выключает «Звук коров». Действует поверх ползунков игры «Общая громкость» и «Эффекты», их аддон не меняет.")
T("VOLUME_OFF", "Off", "Выкл.")
T("SOUND_IS_OFF", "Moo sounds are off.", "звук коров выключен.")
T("SUBTITLE", "A standalone moo in chat becomes a cow call. /mfm test · /mfm clear · /mfm status",
	"Отдельное «му» в чате звучит коровьим мычанием. /mfm test · /mfm clear · /mfm status")
T("MAX_PENDING", "Max waiting calls", "Максимум ожидающих")
T("MAX_PENDING_TIP", "Calls sounding plus calls waiting, all players together, stay within this number + 1, so it also caps how many cows moo at once. Extra moos are dropped. The game mixes 32 sounds at a time by default (Options > Game > Audio > Audio Channels); above about 20 raise that to 64 so game sounds are not cut.",
	"Звучащие и ожидающие реплики всех игроков вместе — не больше этого числа + 1, поэтому оно же ограничивает, сколько коров мычит сразу. Лишние «му» отбрасываются. Игра по умолчанию сводит 32 звука одновременно (Options > Game > Audio > Audio Channels); при значении выше ~20 поднимите его до 64, чтобы не обрезались звуки игры.")
T("ANTISPAM", "Anti-spam", "Антиспам")
T("ANTISPAM_TIP", "Each player can have at most one message waiting behind the one their cow is mooing; further messages from them are dropped until it starts. Other players are not affected.",
	"У каждого игрока может ждать не больше одного сообщения за тем, которое сейчас мычит его корова; следующие его сообщения отбрасываются, пока ожидающее не начнётся. На других игроков не влияет.")
T("OWN", "My own messages", "Свои сообщения")
T("OWN_TIP", "Also moo for what you write, including whispers you send.",
	"Озвучивать и ваши сообщения, включая отправленный шёпот.")
T("IN_WORDS", "Moo inside words", "Му внутри слов")
T("IN_WORDS_TIP", "Also moo for a moo anywhere inside a longer word, in every supported language: «музыка», «почему», «кому», much, moon, Mutter, musique. Off by default: in chat this fires very often.",
	"Мычать и на «му» в любом месте слова, во всех поддерживаемых языках: «музыка», «почему», «кому», much, moon, Mutter, musique. По умолчанию выключено: в чате это срабатывает очень часто.")
T("CHATS", "Chats", "Чаты")
T("G_SAY", "Say and Yell", "Сказать и Крик")
T("G_CHANNEL", "Channels (General, Trade, custom)", "Каналы (General, Trade, свои)")
T("G_GROUP", "Party, raid and instance", "Группа, рейд и подземелье")
T("G_GUILD", "Guild and officers", "Гильдия и офицеры")
T("G_WHISPER", "Whispers, incoming and sent", "Шёпот, входящий и отправленный")
T("ACTIONS", "Actions", "Действия")
T("TEST_BUTTON", "Test", "Тест")
T("TEST_TIP", "Plays your own cow (calm, medium) at the chosen volume, through the same scheduler as chat. Works while the addon is disabled, but not while Moo sounds are off.",
	"Проигрывает вашу корову (calm, medium) с выбранной громкостью через тот же планировщик, что и чат. Работает при выключенном аддоне, но не при выключенном «Звуке коров».")
T("CLEAR_BUTTON", "Clear queue", "Очистить очередь")
T("CLEAR_TIP", "Drops every waiting call of every player and stops the cows that are mooing when the game allows it.",
	"Удаляет ожидающие реплики всех игроков и останавливает мычащих коров, если игра это позволяет.")
T("QUEUE_FULL", "the queue is full.", "очередь заполнена.")
T("CLEARED", "queue cleared.", "очередь очищена.")
T("CHANNEL_OFF", "sound effects are off in the game's sound settings, so the cows are silent.",
	"в настройках звука игры выключены эффекты, коровы молчат.")
T("PLAY_FAILED", "a sound file did not play. After installing or updating, restart the game completely.",
	"звуковой файл не проигрался. После установки или обновления полностью перезапустите игру.")
T("NO_SOUNDS", "the sound catalog is empty; reinstall the addon.", "каталог звуков пуст, переустановите аддон.")
T("REPAIRED", "some saved settings were invalid and were reset to defaults.",
	"часть сохранённых настроек была повреждена и сброшена по умолчанию.")
T("NO_PANEL", "the settings panel is unavailable here; see /mfm help.", "панель настроек недоступна, см. /mfm help.")
T("DEBUG_ON", "debug output on (selection and skip reasons, no message text or names).",
	"отладка включена (выбор реплики и причины пропуска, без текста и имён).")
T("DEBUG_OFF", "debug output off.", "отладка выключена.")
T("HELP", "/mfm: settings · /mfm test: test call · /mfm clear: stop mooing · /mfm status · /mfm debug",
	"/mfm: настройки · /mfm test: тест · /mfm clear: остановить мычание · /mfm status · /mfm debug")

-------------------------------------------------------------------------------
-- Messages: short, prefixed, rate limited for repeated problems
-------------------------------------------------------------------------------
local PREFIX = "|cffc69b6dMulgore FM|r: "
local lastNotice = {}

function ns.Print(text)
	local frame = DEFAULT_CHAT_FRAME
	if frame and frame.AddMessage then
		frame:AddMessage(PREFIX .. tostring(text))
	end
end

-- Prints a problem at most once per `interval` seconds per kind.
function ns.Notice(kind, text, interval)
	local now = GetTime()
	local last = lastNotice[kind]
	if last and now - last < (interval or 60) then
		return
	end
	lastNotice[kind] = now
	ns.Print(text)
end

ns.debug = false
function ns.Debug(fmt, ...)
	if ns.debug then
		ns.Print("|cff888888" .. string.format(fmt, ...) .. "|r")
	end
end

-- Counters for /mfm status. Memory only.
ns.Stats = {}
function ns.Count(name, amount)
	ns.Stats[name] = (ns.Stats[name] or 0) + (amount or 1)
end

-------------------------------------------------------------------------------
-- Saved settings: MulgoreFMDB with a schema version, validated on load
--
-- `sound` is the "Moo sounds" checkbox and `volume` the last chosen non-zero
-- step (10-100), kept while the sound is off so switching it on brings it back.
-------------------------------------------------------------------------------
ns.DEFAULTS = {
	enabled = true,
	sound = true,
	volume = 50,
	maxPending = 10,
	antispam = true,
	ownMessages = true,
	inWords = false,
}
ns.GROUP_DEFAULTS = { say = true, channel = true, group = true, guild = true, whisper = true }

-- Returns valid, normalizedValue.
function ns.ValidateOption(key, value)
	if ns.DEFAULTS[key] == nil then
		return false
	end
	if key == "maxPending" then
		if type(value) ~= "number" or value ~= value then
			return false
		end
		value = math.floor(value + 0.5)
		if value < ns.MAX_PENDING_MIN or value > ns.MAX_PENDING_MAX then
			return false
		end
		return true, value
	elseif key == "volume" then
		if type(value) ~= "number" or value ~= value then
			return false
		end
		value = math.floor(value / 10 + 0.5) * 10
		if value < ns.VOLUME_STEP_MIN or value > ns.VOLUME_STEP_MAX then
			return false
		end
		return true, value
	end
	return type(value) == "boolean", value
end

-- The current step whose gain (dB vs the original recording) is closest.
local function StepForGain(wanted)
	local gains = ns.AudioCatalog and ns.AudioCatalog.levelGainDb
	if type(gains) ~= "table" or type(wanted) ~= "number" then
		return nil
	end
	local best, bestDistance
	for step = 10, 100, 10 do
		local gain = gains[step]
		if gain then
			local distance = math.abs(gain - wanted)
			if not best or distance < bestDistance - 1e-9 then
				best, bestDistance = step, distance
			end
		end
	end
	return best
end

-- 0.2.0 (schema 2) saved the volume as a percentage of the original amplitude,
-- 20-100 with 100 = original.
local function MigratePercent(percent)
	if type(percent) ~= "number" or percent < 20 or percent > 100 then
		return nil
	end
	return StepForGain(20 * math.log10(percent / 100))
end

-- Gains of the 0.3.0-0.6.1 slider (schemas 3 and 4), where 70 was the original
-- and 100 about +10 dB. In 0.7.0 the scale moved up: old 100 is now 50.
local OLD_STEP_GAIN_DB = {
	[10] = -24, [20] = -18, [30] = -14, [40] = -10.5, [50] = -7,
	[60] = -3.5, [70] = 0, [80] = 3.5, [90] = 7, [100] = 10,
}

-- Builds a clean settings table from whatever was saved. Unknown and obsolete
-- fields (such as the 0.2/0.3 `channel`, now always SFX) are dropped; wrong
-- types and out-of-range values fall back to defaults.
function ns.ValidateDB(raw)
	local repaired = 0
	if raw ~= nil and type(raw) ~= "table" then
		repaired = repaired + 1
	end
	if type(raw) ~= "table" then
		raw = {}
	end
	local db = { schema = ns.SCHEMA_VERSION }
	if raw.schema ~= nil and type(raw.schema) ~= "number" then
		repaired = repaired + 1
	end

	local migrated = {}
	if type(raw.schema) == "number" and raw.schema < 5 then
		-- Keep the loudness the player chose: map the old step to the current one.
		local volume = raw.volume
		if raw.schema == 2 then
			volume = MigratePercent(volume) or volume
		elseif type(volume) == "number" and OLD_STEP_GAIN_DB[volume] then
			volume = StepForGain(OLD_STEP_GAIN_DB[volume]) or volume
		end
		if raw.schema < 4 then
			migrated.sound = volume ~= 0 -- before 0.4.0 the slider's 0 was the only "off"
		end
		if volume == 0 then
			-- A muted profile starts with Moo sounds off; with no earlier non-zero
			-- level saved, switching it on uses the default volume.
			migrated.sound = false
			migrated.volume = ns.DEFAULTS.volume
		else
			migrated.volume = volume
		end
	end

	for key, default in pairs(ns.DEFAULTS) do
		local value = raw[key]
		if migrated[key] ~= nil then
			value = migrated[key]
		end
		local valid, normalized = ns.ValidateOption(key, value)
		if valid then
			db[key] = normalized
		else
			db[key] = default
			if value ~= nil then
				repaired = repaired + 1
			end
		end
	end
	local groups = raw.groups
	if groups ~= nil and type(groups) ~= "table" then
		repaired = repaired + 1
		groups = nil
	end
	db.groups = {}
	for key, default in pairs(ns.GROUP_DEFAULTS) do
		local value = groups and groups[key]
		if type(value) == "boolean" then
			db.groups[key] = value
		else
			db.groups[key] = default
			if value ~= nil then
				repaired = repaired + 1
			end
		end
	end
	return db, repaired
end

-- Turns "Moo sounds" on or off. Off stops every sound of this addon, drops
-- everything waiting and keeps the volume step for later.
function ns.SetSound(on)
	local db = ns.db
	if not db or type(on) ~= "boolean" then
		return false
	end
	db.sound = on
	if on then
		local valid = ns.ValidateOption("volume", db.volume)
		if not valid then
			db.volume = ns.DEFAULTS.volume
		end
	else
		ns.Playback.Clear()
	end
	return true
end

function ns.SetOption(key, value)
	local db = ns.db
	if not db then
		return false
	end
	if key == "sound" then
		return ns.SetSound(value)
	end
	if key == "volume" and type(value) == "number" and value == value and math.floor(value / 10 + 0.5) <= 0 then
		-- The slider's 0 is the same as unticking "Moo sounds".
		return ns.SetSound(false)
	end
	local valid, normalized = ns.ValidateOption(key, value)
	if not valid then
		return false
	end
	db[key] = normalized
	if key == "enabled" and not normalized then
		ns.Playback.Clear()
	end
	return true
end

function ns.SetGroup(key, value)
	local db = ns.db
	if not db or ns.GROUP_DEFAULTS[key] == nil or type(value) ~= "boolean" then
		return false
	end
	db.groups[key] = value
	return true
end

-------------------------------------------------------------------------------
-- Events: one frame, one handler per event
-------------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}
ns.eventFrame = frame

function ns.RegisterEvent(event, handler)
	local ok = pcall(frame.RegisterEvent, frame, event)
	if ok then
		handlers[event] = handler
	end
	return ok
end

function ns.UnregisterEvent(event)
	handlers[event] = nil
	pcall(frame.UnregisterEvent, frame, event)
end

frame:SetScript("OnEvent", function(_, event, ...)
	local handler = handlers[event]
	if handler then
		handler(event, ...)
	end
end)

local loginDone = false
local function OnLogin()
	if loginDone then
		return
	end
	loginDone = true
	ns.UnregisterEvent("PLAYER_LOGIN")
	ns.Voices.RefreshOwnKey()
	ns.SettingsUI.Init()
	if ns.repairedOnLoad then
		ns.Print(L.REPAIRED)
	end
end

ns.RegisterEvent("ADDON_LOADED", function(_, name)
	if name ~= ADDON_NAME then
		return
	end
	ns.UnregisterEvent("ADDON_LOADED")
	local db, repaired = ns.ValidateDB(MulgoreFMDB)
	MulgoreFMDB = db
	ns.db = db
	ns.repairedOnLoad = repaired > 0
	if ns.Voices.Init(ns.AudioCatalog) == 0 then
		ns.Print(L.NO_SOUNDS)
	end
	ns.Chat.Init()
	-- Fires for sounds started with a finish callback; harmless if ours never use it.
	ns.RegisterEvent("SOUNDKIT_FINISHED", function(_, handle)
		ns.Playback.OnSoundFinished(handle)
	end)
	ns.RegisterEvent("PLAYER_LOGIN", OnLogin)
	if type(IsLoggedIn) == "function" and IsLoggedIn() then
		OnLogin()
	end
end)

-------------------------------------------------------------------------------
-- Actions shared by the slash command and the settings buttons
-------------------------------------------------------------------------------
local TEST_REQUEST = { { emotion = "calm", length = "medium" } }

-- The test call is a message of the player's own cow: same volume, same SFX
-- channel, same lane and pacing as their chat. It never writes to chat. It
-- plays while the addon is disabled, but not while "Moo sounds" is off.
function ns.Test()
	local db = ns.db
	if not db then
		return
	end
	if not db.sound then
		ns.Notice("sound_off_test", L.SOUND_IS_OFF, 2)
		return
	end
	local key = ns.Voices.OwnKey() or "MulgoreFM-Test"
	local voice = ns.Voices.VoiceForKey(key)
	if not voice then
		ns.Notice("no_sounds", L.NO_SOUNDS)
		return
	end
	local accepted = ns.Playback.Enqueue(key, voice, TEST_REQUEST, 1, db.maxPending, "test")
	if accepted == 0 then
		ns.Notice("queue_full_test", L.QUEUE_FULL, 2)
	end
end

function ns.ClearQueue(announce)
	ns.Playback.Clear()
	if announce then
		ns.Print(L.CLEARED)
	end
end

local STAT_ORDER = {
	"messages_matched", "queued", "played", "finished", "fallback_file", "fallback_level",
	"skip_spam", "skip_duplicate", "skip_own", "skip_secret", "skip_lockdown", "skip_nokey", "skip_muted",
	"drop_queue_full", "drop_profile_missing", "play_failed", "drop_play_failed", "drop_channel_off",
	"stuck_stopped", "handle_lost", "cleared",
}

function ns.PrintStatus()
	local db = ns.db
	if not db then
		return
	end
	local P = ns.Playback
	local sfx = P.ChannelEnabled()
	local sound
	if db.sound then
		sound = string.format("moo sounds on, volume %d%%", db.volume)
	else
		sound = string.format("moo sounds off (volume %d%% when on)", db.volume)
	end
	ns.Print(string.format("v%s · %s%s · %s, SFX%s · sounding %d, waiting %d (limit %d)",
		ns.VERSION, db.enabled and "chat on" or "chat off", db.inWords and ", moo inside words" or "", sound,
		sfx == false and " off in game" or "", P.ActiveCount(), P.PendingCount(), db.maxPending + 1))
	local own = ns.Voices.OwnKey()
	if own then
		ns.Print(string.format("your voice: %s (key #%d, realm suffix %s)",
			ns.Voices.VoiceForKey(own) or "?", ns.Voices.Hash(own), own:match("%-([^%-]*)$") or "?"))
	end
	local parts = {}
	for _, name in ipairs(STAT_ORDER) do
		local value = ns.Stats[name]
		if value and value > 0 then
			parts[#parts + 1] = name .. "=" .. value
		end
	end
	ns.Print("counters: " .. (#parts > 0 and table.concat(parts, " ") or "none"))
	local last = ns.lastPlayed
	if last then
		ns.Print(string.format("last: %s asked %s/%s, got %s/%s, %s", last.voice, last.reqEmotion, last.reqLength,
			last.emotion, last.length, last.path))
	end
end

SLASH_MULGOREFM1 = "/mfm"
SLASH_MULGOREFM2 = "/mulgorefm"
SlashCmdList.MULGOREFM = function(message)
	local command = string.lower(string.match(message or "", "^%s*(%S*)") or "")
	if command == "" or command == "options" or command == "config" then
		ns.SettingsUI.Open()
	elseif command == "test" then
		ns.Test()
	elseif command == "clear" or command == "stop" then
		ns.ClearQueue(true)
	elseif command == "status" then
		ns.PrintStatus()
	elseif command == "debug" then
		ns.debug = not ns.debug
		ns.Print(ns.debug and L.DEBUG_ON or L.DEBUG_OFF)
	else
		ns.Print(L.HELP)
	end
	if ns.SettingsUI.Refresh then
		ns.SettingsUI.Refresh()
	end
end
