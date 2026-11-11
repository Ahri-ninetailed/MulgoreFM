-- Mulgore FM: the settings page (Options > AddOns > Mulgore FM).
--
-- The page is a canvas category: one frame of our own with our own widgets.
-- It registers no Blizzard settings and uses none of the panel's pooled
-- controls. Version 0.1.0 used proxy settings and Blizzard's list controls;
-- those shared, pooled frames carried the addon's taint onto Blizzard's own
-- pages (Game > Audio), which then had a protected action blocked.
-- The page only reads sound CVars, never writes any game setting.
local _, ns = ...

local SettingsUI = {}
ns.SettingsUI = SettingsUI

local L = ns.L
local controls = {}
SettingsUI.controls = controls

local LEFT, RIGHT = 16, 4 -- x offsets inside the left and right halves of the page
local ROW = 28

local function AddTooltip(widget, title, text)
	widget:HookScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		if text then
			GameTooltip:AddLine(text, nil, nil, nil, true)
		end
		GameTooltip:Show()
	end)
	widget:HookScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
end

local function Label(parent, text, font)
	local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
	label:SetJustifyH("LEFT")
	label:SetText(text)
	return label
end

local function Header(parent, x, y, text)
	local label = Label(parent, text, "GameFontNormal")
	label:SetPoint("TOPLEFT", x, y)
	return label
end

-- A checkbox bound to get/set; the page refreshes all widgets after a change.
local function Checkbox(parent, x, y, text, tooltip, get, set, template)
	local button = CreateFrame("CheckButton", nil, parent, template or "UICheckButtonTemplate")
	button:SetSize(26, 26)
	button:SetPoint("TOPLEFT", x, y)
	local label = Label(parent, text)
	label:SetPoint("LEFT", button, "RIGHT", 4, 0)
	button.label = label
	button:SetScript("OnClick", function(self)
		set(self:GetChecked() and true or false)
		SettingsUI.Refresh()
	end)
	button.Refresh = function(self)
		self:SetChecked(get() and true or false)
	end
	AddTooltip(button, text, tooltip)
	return button
end

local function Slider(parent, x, y, text, tooltip, minValue, maxValue, step, format, get, set)
	local title = Label(parent, text)
	title:SetPoint("TOPLEFT", x + 4, y)
	local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
	slider:SetWidth(250)
	slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -4, -2)
	slider.label = title
	local formatters = {
		[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
			MinimalSliderWithSteppersMixin.Label.Right, format),
	}
	slider:Init(get(), minValue, maxValue, (maxValue - minValue) / step, formatters)
	local refreshing = false
	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not refreshing then
			set(value)
			SettingsUI.Refresh()
		end
	end, slider)
	slider.Refresh = function(self)
		refreshing = true
		self:SetValue(get())
		refreshing = false
	end
	AddTooltip(slider, text, tooltip)
	return slider
end

local function Button(parent, text, width, tooltip, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 24)
	button:SetText(text)
	button:SetScript("OnClick", onClick)
	AddTooltip(button, text, tooltip)
	return button
end

local function Option(key)
	return function()
		return ns.db[key]
	end, function(value)
		ns.SetOption(key, value)
	end
end

local function Group(key)
	return function()
		return ns.db.groups[key]
	end, function(value)
		ns.SetGroup(key, value)
	end
end

local function Percent(value)
	value = math.floor(value + 0.5)
	if value == 0 then
		return L.VOLUME_OFF
	end
	return string.format("%d%%", value)
end

local function Whole(value)
	return tostring(math.floor(value + 0.5))
end

function SettingsUI.Refresh()
	if not ns.db then
		return
	end
	for _, control in pairs(controls) do
		if control.Refresh then
			control:Refresh()
		end
	end
end

local function Build()
	local page = CreateFrame("Frame")
	page:Hide()

	local title = Label(page, "Mulgore FM", "GameFontHighlightHuge")
	title:SetPoint("TOPLEFT", LEFT, -14)
	local subtitle = Label(page, L.SUBTITLE, "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	subtitle:SetPoint("RIGHT", page, "RIGHT", -16, 0)

	-- Two halves of the page, so nothing depends on the panel's exact width
	-- (about 670 units on Forever 1.60.1).
	local left = CreateFrame("Frame", nil, page)
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMRIGHT", page, "BOTTOM")
	local right = CreateFrame("Frame", nil, page)
	right:SetPoint("TOPLEFT", page, "TOP")
	right:SetPoint("BOTTOMRIGHT")

	-- Left half: sound and behaviour
	local y = -70
	controls.enabled = Checkbox(left, LEFT, y, L.ENABLED, L.ENABLED_TIP, Option("enabled"))
	y = y - ROW
	controls.sound = Checkbox(left, LEFT, y, L.SOUND, L.SOUND_TIP, Option("sound"))

	-- While Moo sounds is off the slider sits at 0, greyed out with its arrows,
	-- and reads "Off"; the saved step comes back when the sound is switched on.
	y = y - ROW - 6
	local function SliderVolume()
		return ns.db.sound and ns.db.volume or 0
	end
	local function SetVolume(value)
		ns.SetOption("volume", value)
	end
	controls.volume = Slider(left, LEFT, y, L.VOLUME, L.VOLUME_TIP, 0, ns.VOLUME_STEP_MAX, 10, Percent,
		SliderVolume, SetVolume)
	local refreshVolume = controls.volume.Refresh
	controls.volume.Refresh = function(self)
		refreshVolume(self)
		self:SetEnabled(ns.db.sound and true or false)
	end

	y = y - 62
	controls.maxPending = Slider(left, LEFT, y, L.MAX_PENDING, L.MAX_PENDING_TIP, ns.MAX_PENDING_MIN,
		ns.MAX_PENDING_MAX, 1, Whole, Option("maxPending"))

	y = y - 64
	controls.antispam = Checkbox(left, LEFT, y, L.ANTISPAM, L.ANTISPAM_TIP, Option("antispam"))
	y = y - ROW
	controls.ownMessages = Checkbox(left, LEFT, y, L.OWN, L.OWN_TIP, Option("ownMessages"))
	y = y - ROW
	controls.inWords = Checkbox(left, LEFT, y, L.IN_WORDS, L.IN_WORDS_TIP, Option("inWords"))

	-- Right half: chats and actions
	y = -70
	Header(right, RIGHT + 4, y, L.CHATS)
	y = y - 20
	controls.g_say = Checkbox(right, RIGHT, y, L.G_SAY, nil, Group("say"))
	y = y - ROW
	controls.g_channel = Checkbox(right, RIGHT, y, L.G_CHANNEL, nil, Group("channel"))
	y = y - ROW
	controls.g_group = Checkbox(right, RIGHT, y, L.G_GROUP, nil, Group("group"))
	y = y - ROW
	controls.g_guild = Checkbox(right, RIGHT, y, L.G_GUILD, nil, Group("guild"))
	y = y - ROW
	controls.g_whisper = Checkbox(right, RIGHT, y, L.G_WHISPER, nil, Group("whisper"))

	y = y - ROW - 18
	Header(right, RIGHT + 4, y, L.ACTIONS)
	y = y - 22
	controls.test = Button(right, L.TEST_BUTTON, 170, L.TEST_TIP, function()
		ns.Test()
	end)
	controls.test:SetPoint("TOPLEFT", RIGHT + 4, y)
	controls.test.Refresh = function(self)
		self:SetEnabled(ns.db.sound and true or false)
	end
	controls.clear = Button(right, L.CLEAR_BUTTON, 170, L.CLEAR_TIP, function()
		ns.ClearQueue(false)
	end)
	controls.clear:SetPoint("TOPLEFT", controls.test, "BOTTOMLEFT", 0, -8)

	-- The panel calls OnRefresh through securecallfunction right after it shows
	-- the page. There is deliberately no OnShow script, which would run
	-- unprotected inside the panel's own code, and no OnDefault: the game's
	-- Defaults button ("All Settings") leaves Mulgore FM's settings alone.
	page.OnRefresh = function()
		SettingsUI.Refresh()
	end
	SettingsUI.page = page

	local category = Settings.RegisterCanvasLayoutCategory(page, "Mulgore FM")
	Settings.RegisterAddOnCategory(category)
	SettingsUI.Refresh()
	return category
end

function SettingsUI.Init()
	if SettingsUI.category or SettingsUI.failed then
		return
	end
	if type(Settings) ~= "table" or type(Settings.RegisterCanvasLayoutCategory) ~= "function"
		or type(Settings.RegisterAddOnCategory) ~= "function" then
		SettingsUI.failed = true
		return
	end
	local ok, result = pcall(Build)
	if ok then
		SettingsUI.category = result
	else
		SettingsUI.failed = true
		ns.Debug("settings page error: %s", tostring(result))
	end
end

function SettingsUI.Open()
	local category = SettingsUI.category
	if category and type(Settings.OpenToCategory) == "function" then
		local ok = pcall(Settings.OpenToCategory, category:GetID())
		if ok then
			return
		end
	end
	ns.Print(L.NO_PANEL)
	ns.Print(L.HELP)
end
