-- Mulgore FM: finds standalone moos in chat text.
--
-- The text is decoded as UTF-8 code points with strict validation. Words are
-- runs of letters, digits, combining marks and underscores; everything else
-- (spaces, line breaks, punctuation, dashes, quotes, symbols, emoji) separates
-- them. Unknown non-ASCII code points count as word characters, so an odd
-- neighbour can only prevent a match, never create one. A word that holds an
-- invalid byte sequence, or that is longer than MAX_TOKEN_CP, is skipped.
--
-- WoW escape sequences are not words: colour codes are transparent, hyperlink
-- addresses, textures, atlases and protected names are skipped entirely.
--
-- Accepted forms (whole words only, any letter case, one script per word);
-- the leading М/m may repeat ("ММУУУУ", "mmmoo") and only vowels set the length:
--   Cyrillic  м + у{1,}          Latin  m + o{2,}   m + u{1,}   m + u{1,} + h
--   French    m + e + u{1,} + h  Dutch  b + o + e{1,}
--   Look-alike m + y{2,} ("MYYY"; one y is the English "my")
-- In a word with a Cyrillic letter, Latin M/m and Y/y count as М and У.
-- A word may also be several of these glued together ("муму", "мууму",
-- "moomoo"); every piece then counts as its own moo. With the opt-in "Moo
-- inside words" setting, a form anywhere inside any word counts too.
local _, ns = ...

local Parser = {}
ns.Parser = Parser

local byte, find = string.byte, string.find

local MAX_SCAN_BYTES = 4096 -- work bound per message; chat lines are far shorter
local MAX_TOKEN_CP = 255    -- longer words are skipped as unsafe
Parser.MAX_SCAN_BYTES = MAX_SCAN_BYTES
Parser.MAX_TOKEN_CP = MAX_TOKEN_CP

local INVALID = -1

-------------------------------------------------------------------------------
-- Strict UTF-8 decoding. Returns codePoint (or INVALID) and the next index.
-- An invalid lead or continuation consumes exactly one byte.
-------------------------------------------------------------------------------
local function Decode(s, i)
	local b1 = byte(s, i)
	if b1 < 0x80 then
		return b1, i + 1
	elseif b1 < 0xC2 then
		return INVALID, i + 1
	elseif b1 < 0xE0 then
		local b2 = byte(s, i + 1)
		if b2 and b2 >= 0x80 and b2 <= 0xBF then
			return (b1 - 0xC0) * 64 + (b2 - 0x80), i + 2
		end
		return INVALID, i + 1
	elseif b1 < 0xF0 then
		local b2, b3 = byte(s, i + 1, i + 2)
		local lo, hi = 0x80, 0xBF
		if b1 == 0xE0 then
			lo = 0xA0
		elseif b1 == 0xED then
			hi = 0x9F -- no UTF-16 surrogates
		end
		if b2 and b2 >= lo and b2 <= hi and b3 and b3 >= 0x80 and b3 <= 0xBF then
			return (b1 - 0xE0) * 4096 + (b2 - 0x80) * 64 + (b3 - 0x80), i + 3
		end
		return INVALID, i + 1
	elseif b1 <= 0xF4 then
		local b2, b3, b4 = byte(s, i + 1, i + 3)
		local lo, hi = 0x80, 0xBF
		if b1 == 0xF0 then
			lo = 0x90
		elseif b1 == 0xF4 then
			hi = 0x8F
		end
		if b2 and b2 >= lo and b2 <= hi and b3 and b3 >= 0x80 and b3 <= 0xBF and b4 and b4 >= 0x80 and b4 <= 0xBF then
			return (b1 - 0xF0) * 262144 + (b2 - 0x80) * 4096 + (b3 - 0x80) * 64 + (b4 - 0x80), i + 4
		end
		return INVALID, i + 1
	end
	return INVALID, i + 1
end
Parser.Decode = Decode

-------------------------------------------------------------------------------
-- Word characters
-------------------------------------------------------------------------------
local ASCII_WORD = {}
for c = 48, 57 do ASCII_WORD[c] = true end  -- 0-9
for c = 65, 90 do ASCII_WORD[c] = true end  -- A-Z
for c = 97, 122 do ASCII_WORD[c] = true end -- a-z
ASCII_WORD[95] = true                        -- _

local function IsWord(cp)
	if cp < 0x80 then
		return ASCII_WORD[cp] == true
	elseif cp < 0xA0 then
		return false -- C1 controls
	elseif cp < 0xC0 then
		-- Latin-1 punctuation and symbols separate; ª µ º, superscript digits,
		-- fractions and the soft hyphen continue a word.
		return cp == 0xAA or cp == 0xB5 or cp == 0xBA or cp == 0xB2 or cp == 0xB3 or cp == 0xB9
			or cp == 0xAD or (cp >= 0xBC and cp <= 0xBE)
	elseif cp == 0xD7 or cp == 0xF7 then
		return false -- × ÷
	elseif cp < 0x2000 then
		return cp ~= 0x037E and cp ~= 0x0387 and cp ~= 0x1680 -- Greek ; and ·, Ogham space
	elseif cp <= 0x200B then
		return false -- spaces, zero width space
	elseif cp <= 0x200F then
		return true -- ZWNJ, ZWJ, direction marks
	elseif cp <= 0x2029 then
		return false -- hyphens, dashes, quotes, bullets, ellipsis, line separators
	elseif cp <= 0x202E then
		return true -- bidi controls
	elseif cp <= 0x205F then
		return false -- narrow spaces, primes, angle quotes, punctuation
	elseif cp <= 0x209F then
		return true -- invisible operators, super- and subscripts
	elseif cp <= 0x20CF then
		return false -- currency
	elseif cp <= 0x218F then
		return true -- combining marks for symbols, letterlike symbols, number forms
	elseif cp <= 0x245F then
		return false -- arrows, mathematical and technical symbols
	elseif cp <= 0x24FF then
		return true -- enclosed alphanumerics
	elseif cp <= 0x2BFF then
		return false -- box drawing, shapes, miscellaneous symbols, dingbats
	elseif cp >= 0x2E00 and cp <= 0x2E7F then
		return false -- supplemental punctuation
	elseif cp >= 0x3000 and cp <= 0x303F then
		return cp == 0x3005 or cp == 0x3006 or cp == 0x3007 or (cp >= 0x3021 and cp <= 0x302F)
			or (cp >= 0x3031 and cp <= 0x303C)
	elseif cp >= 0xFE10 and cp <= 0xFE1F then
		return false
	elseif cp >= 0xFE30 and cp <= 0xFE6F then
		return false
	elseif cp >= 0xFF01 and cp <= 0xFF0F then
		return false
	elseif cp >= 0xFF1A and cp <= 0xFF20 then
		return false
	elseif cp >= 0xFF3B and cp <= 0xFF40 then
		return cp == 0xFF3F -- fullwidth low line joins words like "_"
	elseif cp >= 0xFF5B and cp <= 0xFF65 then
		return false
	elseif cp >= 0x1F000 and cp <= 0x1FAFF then
		return false -- emoji and pictographs
	end
	return true
end
Parser.IsWord = IsWord

-------------------------------------------------------------------------------
-- WoW escape sequences, called with s:byte(i) == "|".
-- Returns the next index and whether the sequence separates words.
-------------------------------------------------------------------------------
local function SkipTo(s, i, closing, n)
	local e = find(s, closing, i, true)
	if e then
		return e + #closing
	end
	return n + 1
end

local function SkipEscape(s, i, n)
	local c = byte(s, i + 1)
	if c == 0x63 then -- |c: colour, transparent
		if find(s, "^%x%x%x%x%x%x%x%x", i + 2) then
			return i + 10, false
		end
		if byte(s, i + 2) == 0x6E then -- |cnNAME: named colour
			local e = find(s, ":", i + 3, true)
			if e and e - i <= 64 then
				return e + 1, false
			end
		end
		return i + 1, true
	elseif c == 0x72 then -- |r
		return i + 2, false
	elseif c == 0x48 then -- |H address |h: skip the address, keep the visible text
		return SkipTo(s, i + 2, "|h", n), true
	elseif c == 0x54 then -- |T texture |t
		return SkipTo(s, i + 2, "|t", n), true
	elseif c == 0x41 then -- |A atlas |a
		return SkipTo(s, i + 2, "|a", n), true
	elseif c == 0x4B then -- |K protected name |k
		return SkipTo(s, i + 2, "|k", n), true
	elseif c == 0x7C or c == 0x68 or c == 0x6E then -- ||, closing |h, |n
		return i + 2, true
	end
	return i + 1, true -- a lone or unknown pipe is punctuation
end

-------------------------------------------------------------------------------
-- Classification of one word
-------------------------------------------------------------------------------
local LETTER = {
	[0x041C] = "Mc", [0x043C] = "Mc", -- М м (Cyrillic)
	[0x0423] = "Uc", [0x0443] = "Uc", -- У у (Cyrillic)
	[0x4D] = "m", [0x6D] = "m",
	[0x4F] = "o", [0x6F] = "o",
	[0x55] = "u", [0x75] = "u",
	[0x48] = "h", [0x68] = "h",
	[0x45] = "e", [0x65] = "e",
	[0x42] = "b", [0x62] = "b",
	[0x59] = "y", [0x79] = "y", -- only in "m + y{2,}", the Latin look-alike of МУУ
}
local UPPER = {
	[0x041C] = true, [0x0423] = true,
	[0x4D] = true, [0x4F] = true, [0x55] = true, [0x48] = true, [0x45] = true, [0x42] = true, [0x59] = true,
}
-- Latin letters that look like М and У. In a word that has a Cyrillic letter
-- they are read as Cyrillic, so "MУУУ" typed with a Latin M still moos.
-- Without a Cyrillic letter they stay Latin ("my" is English).
local CYRILLIC_LOOKALIKE = { [0x4D] = "Mc", [0x6D] = "Mc", [0x59] = "Uc", [0x79] = "Uc" }

-- Letter classes of the word being classified; false for any other character,
-- and a false sentinel right after the word.
local letters = {}

-- Fills letters for buf[1..n]; returns whether the word has a Cyrillic letter.
local function ClassifyLetters(buf, n)
	local cyrillic = false
	for k = 1, n do
		local cp = buf[k]
		if cp >= 0x0400 and cp <= 0x04FF then
			cyrillic = true
			break
		end
	end
	for k = 1, n do
		local cp = buf[k]
		letters[k] = (cyrillic and CYRILLIC_LOOKALIKE[cp]) or LETTER[cp] or false
	end
	letters[n + 1] = false
	return cyrillic
end

-- Index just after the run of `letter` that starts at k.
local function Run(k, n, letter)
	while k <= n and letters[k] == letter do
		k = k + 1
	end
	return k
end

-- The moo that starts at letters[k], if any: returns its last index, form,
-- vowel count and length rule. Several M at the start are one moo
-- ("ММУУУ", "mmmoo"); the length counts only the vowels.
local function MatchAt(k, n)
	local first = letters[k]
	if first == "Mc" then
		local v = Run(k, n, "Mc")
		local e = Run(v, n, "Uc")
		if e > v then
			return e - 1, "mu_cyr", e - v, "single"
		end
	elseif first == "m" then
		local v = Run(k, n, "m")
		local second = letters[v]
		if second == "o" then
			local e = Run(v, n, "o")
			if e - v >= 2 then
				return e - 1, "moo", e - v, "moo"
			end
		elseif second == "u" then
			local e = Run(v, n, "u")
			if letters[e] == "h" then
				return e, "muh", e - v, "single"
			end
			return e - 1, "mu", e - v, "single"
		elseif second == "e" then
			local u = v + 1
			local e = Run(u, n, "u")
			if e > u and e <= n and letters[e] == "h" then
				return e, "meuh", e - u, "single"
			end
		elseif second == "y" then
			-- "MYYY" in Latin letters that look like МУУУ. Needs two Y at least:
			-- a single one is the English "my". Counted like у.
			local e = Run(v, n, "y")
			if e - v >= 2 then
				return e - 1, "my_lat", e - v, "single"
			end
		end
	elseif first == "b" then
		if letters[k + 1] == "o" then
			local e = Run(k + 2, n, "e")
			if e > k + 2 then
				return e - 1, "boe", e - k - 2, "single"
			end
		end
	end
	return nil
end

local function Emotion(buf, i, j)
	local firstUpper = UPPER[buf[i]] == true
	local previous = firstUpper
	local transitions, rising = 0, false
	for k = i + 1, j do
		local upper = UPPER[buf[k]] == true
		if upper ~= previous then
			transitions = transitions + 1
			rising = upper
			previous = upper
		end
	end
	if transitions == 0 then
		return firstUpper and "angry" or "calm"
	elseif transitions == 1 then
		return rising and "crescendo" or "fade_out"
	end
	return "calm" -- chaotic case
end

local function Length(count, rule)
	if rule == "moo" then
		if count <= 2 then
			return "short"
		elseif count == 3 then
			return "medium"
		end
		return "long"
	end
	if count <= 1 then
		return "short"
	elseif count <= 3 then
		return "medium"
	end
	return "long"
end

local function Emit(buf, out, count, i, j, form, vowels, rule)
	count = count + 1
	out[count] = {
		form = form,
		emotion = Emotion(buf, i, j),
		length = Length(vowels, rule),
		vowels = vowels < 4 and vowels or 4, -- saturates at the long threshold
	}
	return count
end

local pieceStart, pieceEnd, pieceForm, pieceVowels, pieceRule = {}, {}, {}, {}, {}

-- A whole word as one moo ("мууу") or several glued together ("муму",
-- "ммуумму", "moomoo"); each piece is its own moo with its own case and
-- length. If the pieces do not cover the whole word, or the word mixes
-- scripts beyond the М/У look-alikes, nothing is added. Returns the new count
-- and whether the word was a moo word.
local function ClassifyWord(buf, n, out, count, limit)
	local cyrillic = ClassifyLetters(buf, n)
	for k = 1, n do
		local letter = letters[k]
		if not letter or (cyrillic and letter ~= "Mc" and letter ~= "Uc") then
			return count, false
		end
	end
	local pieces, k = 0, 1
	while k <= n do
		local last, form, vowels, rule = MatchAt(k, n)
		if not last then
			return count, false
		end
		pieces = pieces + 1
		pieceStart[pieces], pieceEnd[pieces] = k, last
		pieceForm[pieces], pieceVowels[pieces], pieceRule[pieces] = form, vowels, rule
		k = last + 1
	end
	for p = 1, pieces do
		if count >= limit then
			break
		end
		count = Emit(buf, out, count, pieceStart[p], pieceEnd[p], pieceForm[p], pieceVowels[p], pieceRule[p])
	end
	return count, true
end

-- "Moo inside words" (an opt-in setting): in a word that is not itself a moo,
-- every moo of any form anywhere counts, left to right: "музыка", "почему",
-- "кому", "much", "moon", "Mutter", "musique". Case and length come from the
-- piece itself. Uses the letter classes ClassifyWord just filled.
local function InWordMoos(buf, n, out, count, limit)
	local k = 1
	while k <= n and count < limit do
		local last, form, vowels, rule
		if letters[k] then
			last, form, vowels, rule = MatchAt(k, n)
		end
		if last then
			count = Emit(buf, out, count, k, last, form, vowels, rule)
			k = last + 1
		else
			k = k + 1
		end
	end
	return count
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Cheap test before decoding: does the text contain a possible first letter?
function Parser.MayContain(text)
	return find(text, "[mMbB]") ~= nil or find(text, "\208[\156\188]") ~= nil
end

local buf = {}

local function Word(word, n, out, count, limit, inWords)
	local matched
	count, matched = ClassifyWord(word, n, out, count, limit)
	if inWords and not matched then
		count = InWordMoos(word, n, out, count, limit)
	end
	return count
end

-- Parses text and stores up to `limit` requests in `out` (array part), in the
-- order written. Returns out, count. Each request is
-- { form, emotion = calm|angry|crescendo|fade_out, length = short|medium|long, vowels }.
-- With `inWords`, "му" inside longer words counts as well (opt-in setting).
function Parser.Parse(text, limit, out, inWords)
	out = out or {}
	if type(text) ~= "string" then
		return out, 0
	end
	local n = #text
	limit = limit or ns.MAX_TOKENS_PER_MESSAGE or 3
	local count = 0
	if n == 0 or limit < 1 then
		return out, 0
	end
	local scanEnd = n < MAX_SCAN_BYTES and n or MAX_SCAN_BYTES
	local i = 1
	local tlen, bad, over = 0, false, false
	while i <= scanEnd do
		local separator = false
		if byte(text, i) == 0x7C then
			i, separator = SkipEscape(text, i, n)
		else
			local cp
			cp, i = Decode(text, i)
			if cp == INVALID then
				bad = true
				tlen = tlen + 1
			elseif IsWord(cp) then
				tlen = tlen + 1
				if tlen <= MAX_TOKEN_CP then
					buf[tlen] = cp
				else
					over = true
				end
			else
				separator = true
			end
		end
		if separator and tlen > 0 then
			if not bad and not over then
				count = Word(buf, tlen, out, count, limit, inWords)
				if count >= limit then
					return out, count
				end
			end
			tlen, bad, over = 0, false, false
		end
	end
	-- A word still open here is complete only if the whole text was scanned.
	if tlen > 0 and not bad and not over and i > n then
		count = Word(buf, tlen, out, count, limit, inWords)
	end
	return out, count
end
