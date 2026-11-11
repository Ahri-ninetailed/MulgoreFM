-- Mulgore FM: one sender, one voice; choosing a file inside that voice.
--
-- Sender key: "<name>-<realm>". The chat sender argument is trimmed and its
-- inner whitespace collapsed. A suffix after the last "-" is taken as the
-- realm (spaces removed); without one the player's own normalized realm is
-- appended, so "Name" and "Name-OwnRealm" give the same key while the same
-- name on two realms gives two keys. The player's own key is built once from
-- the unit API and used for every own message, outgoing whispers included.
-- When no usable name exists but a player GUID does, the key is "guid:<GUID>".
--
-- Voice: a polynomial hash of the key's bytes modulo the prime 2^31-1, with
-- products below 2^39, so Lua 5.1 doubles compute it exactly on every client.
-- The voice list is sorted, so the result does not depend on table order,
-- random seeds or who spoke first.
local _, ns = ...

local Voices = {}
ns.Voices = Voices

local byte = string.byte

local CLASS_INDEX = { short = 1, medium = 2, long = 3 }
Voices.CLASS_INDEX = CLASS_INDEX

local voiceList = {}
local byVoice = {}
local rankCache = {}
local ownKey

local function IsSecret(value)
	return type(issecretvalue) == "function" and issecretvalue(value) == true
end
Voices.IsSecret = IsSecret

-------------------------------------------------------------------------------
-- Catalog
-------------------------------------------------------------------------------

-- Indexes the static catalog. Returns the number of usable entries.
function Voices.Init(catalog)
	voiceList, byVoice, rankCache = {}, {}, {}
	if type(catalog) ~= "table" or type(catalog.entries) ~= "table" then
		return 0
	end
	local used = 0
	for _, e in ipairs(catalog.entries) do
		if type(e) == "table" and type(e.voice) == "string" and type(e.emotion) == "string"
			and CLASS_INDEX[e.class] and type(e.path) == "string"
			and type(e.duration) == "number" and e.duration > 0 then
			local voice = byVoice[e.voice]
			if not voice then
				voice = { id = e.voice, pairs = {}, pairList = {} }
				byVoice[e.voice] = voice
				voiceList[#voiceList + 1] = e.voice
			end
			local key = e.emotion .. "_" .. e.class
			local pair = voice.pairs[key]
			if not pair then
				pair = { key = key, emotion = e.emotion, class = e.class, entries = {} }
				voice.pairs[key] = pair
				voice.pairList[#voice.pairList + 1] = pair
			end
			pair.entries[#pair.entries + 1] = e
			used = used + 1
		end
	end
	table.sort(voiceList)
	for _, voice in pairs(byVoice) do
		table.sort(voice.pairList, function(a, b) return a.key < b.key end)
		for _, pair in ipairs(voice.pairList) do
			table.sort(pair.entries, function(a, b) return a.path < b.path end)
		end
	end
	return used
end

function Voices.List()
	return voiceList
end

-------------------------------------------------------------------------------
-- Sender keys and voices
-------------------------------------------------------------------------------
local HASH_MOD = 2147483647 -- 2^31 - 1, prime
local HASH_MUL = 131

function Voices.Hash(key)
	local h = 5381
	for i = 1, #key do
		h = (h * HASH_MUL + byte(key, i)) % HASH_MOD
	end
	return h
end

function Voices.VoiceForKey(key)
	local count = #voiceList
	if count == 0 or type(key) ~= "string" or key == "" then
		return nil
	end
	return voiceList[Voices.Hash(key) % count + 1]
end

local function Collapse(s)
	s = s:gsub("%s+", " ")
	s = s:gsub("^ ", "")
	s = s:gsub(" $", "")
	return s
end

function Voices.LocalRealm()
	local realm
	if type(GetNormalizedRealmName) == "function" then
		local ok, value = pcall(GetNormalizedRealmName)
		if ok and type(value) == "string" and not IsSecret(value) then
			realm = value
		end
	end
	if (realm == nil or realm == "") and type(GetRealmName) == "function" then
		local ok, value = pcall(GetRealmName)
		if ok and type(value) == "string" and not IsSecret(value) then
			realm = value:gsub("[%s%-]", "")
		end
	end
	if realm == "" then
		realm = nil
	end
	return realm
end

function Voices.CanonicalKey(sender)
	if type(sender) ~= "string" or IsSecret(sender) then
		return nil
	end
	local s = Collapse(sender)
	if s == "" then
		return nil
	end
	local base, realm = s:match("^(.-)%-([^%-]*)$")
	if not base then
		base = s
	end
	base = Collapse(base)
	if base == "" then
		return nil
	end
	if realm then
		realm = realm:gsub("%s", "")
	end
	if realm == nil or realm == "" then
		realm = Voices.LocalRealm()
		if not realm then
			return nil
		end
	end
	return base .. "-" .. realm
end

local function OwnFullName()
	local name
	if type(NameUtil) == "table" and type(NameUtil.GetUnmodifiedUnitFullName) == "function" then
		local ok, value = pcall(NameUtil.GetUnmodifiedUnitFullName, "player")
		if ok then
			name = value
		end
	end
	if (type(name) ~= "string" or name == "") and type(UnitName) == "function" then
		local first, second = UnitName("player")
		name = first
		-- With regional unique names the second value is the surname, not a realm.
		if type(first) == "string" and type(second) == "string" and second ~= ""
			and type(RegionalUniqueNamesEnabled) == "function" and RegionalUniqueNamesEnabled() then
			local separator = " "
			if type(Constants) == "table" and type(Constants.CharacterNameSeparatorConsts) == "table" then
				separator = Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or separator
			end
			name = first .. separator .. second
		end
	end
	if type(name) ~= "string" or IsSecret(name) then
		return nil
	end
	name = Collapse(name)
	if name == "" or name == UNKNOWNOBJECT then
		return nil
	end
	return name
end

function Voices.OwnKey()
	if ownKey then
		return ownKey
	end
	local name, realm = OwnFullName(), Voices.LocalRealm()
	if name and realm then
		ownKey = name .. "-" .. realm
	end
	return ownKey
end

function Voices.RefreshOwnKey()
	ownKey = nil
	return Voices.OwnKey()
end

-------------------------------------------------------------------------------
-- File choice inside one voice
--
-- cost = 2 * class distance + emotion cost; emotion cost is 0 for the same
-- emotion, 3 for calm/angry, 2 for crescendo/fade_out, 1 otherwise. Ties go
-- to the nearer class, then the nearer emotion, then the pair name. Another
-- voice is never used.
-------------------------------------------------------------------------------
local function EmotionCost(a, b)
	if a == b then
		return 0
	elseif (a == "calm" and b == "angry") or (a == "angry" and b == "calm") then
		return 3
	elseif (a == "crescendo" and b == "fade_out") or (a == "fade_out" and b == "crescendo") then
		return 2
	end
	return 1
end
Voices.EmotionCost = EmotionCost

function Voices.Rank(voiceId, emotion, length)
	local cacheKey = voiceId .. "|" .. emotion .. "|" .. length
	local ranked = rankCache[cacheKey]
	if ranked then
		return ranked
	end
	local voice = byVoice[voiceId]
	local wanted = CLASS_INDEX[length]
	if not voice or not wanted then
		return nil
	end
	local scored = {}
	for _, pair in ipairs(voice.pairList) do
		local classDistance = math.abs(CLASS_INDEX[pair.class] - wanted)
		local emotionCost = EmotionCost(emotion, pair.emotion)
		scored[#scored + 1] = {
			pair = pair, cost = 2 * classDistance + emotionCost, cd = classDistance, ec = emotionCost,
		}
	end
	table.sort(scored, function(a, b)
		if a.cost ~= b.cost then
			return a.cost < b.cost
		elseif a.cd ~= b.cd then
			return a.cd < b.cd
		elseif a.ec ~= b.ec then
			return a.ec < b.ec
		end
		return a.pair.key < b.pair.key
	end)
	ranked = {}
	for i, s in ipairs(scored) do
		ranked[i] = s.pair
	end
	rankCache[cacheKey] = ranked
	return ranked
end

Voices.Random = function(n)
	return math.random(n)
end

-- Returns entry, pair for the best available file of this voice, skipping
-- paths in `exclude`. With useRandom, one of several takes is picked at random;
-- otherwise the first by path.
function Voices.Select(voiceId, emotion, length, useRandom, exclude)
	local ranked = Voices.Rank(voiceId, emotion, length)
	if not ranked then
		return nil
	end
	for _, pair in ipairs(ranked) do
		local entries = pair.entries
		local available = 0
		for i = 1, #entries do
			if not (exclude and exclude[entries[i].path]) then
				available = available + 1
			end
		end
		if available > 0 then
			local pick = 1
			if useRandom and available > 1 then
				pick = Voices.Random(available)
			end
			local seen = 0
			for i = 1, #entries do
				local e = entries[i]
				if not (exclude and exclude[e.path]) then
					seen = seen + 1
					if seen == pick then
						return e, pair
					end
				end
			end
		end
	end
	return nil
end
