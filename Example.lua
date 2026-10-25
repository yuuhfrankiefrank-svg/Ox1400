local repo = "https://raw.githubusercontent.com/yuuhfrankiefrank-svg/Ox1400/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = getgenv().Options or Library.Options
local Toggles = getgenv().Toggles or Library.Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"
Library.UseBlur = true

local Window = Library:CreateWindow({
	Title = "Example menu",
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = true,
	UnlockMouseWhileOpen = true,
	NotifySide = "Left",
	TabPadding = 8,
	MenuFadeTime = 0.2,
})

local Tabs = {
	Main = Window:AddTab("Main"),
	Combat = Window:AddTab("Combat"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

-- Main left
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox")

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Example Toggle",
	Default = false,
	Tooltip = "Example tooltip",
	Callback = function(Value)
		print("Toggle:", Value)
	end,
})

LeftGroupBox:AddToggle("MyToggle2", {
	Text = "Another Toggle",
	Default = true,
	Callback = function(Value) end,
})

LeftGroupBox:AddSlider("MySlider", {
	Text = "Example Slider",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Callback = function(Value)
		print("Slider:", Value)
	end,
})

LeftGroupBox:AddSlider("MySlider2", {
	Text = "Speed",
	Default = 16,
	Min = 1,
	Max = 100,
	Rounding = 0,
})

LeftGroupBox:AddDropdown("MyDropdown", {
	Values = { "Option A", "Option B", "Option C" },
	Default = 1,
	Multi = false,
	Text = "Example Dropdown",
	Callback = function(Value)
		print("Dropdown:", Value)
	end,
})

LeftGroupBox:AddDropdown("MyMultiDropdown", {
	Values = { "One", "Two", "Three", "Four" },
	Default = 1,
	Multi = true,
	Text = "Multi Dropdown",
})

LeftGroupBox:AddButton({
	Text = "Notify Test",
	Func = function()
		Library:Notify("Hello from example.lua", 3)
	end,
})

LeftGroupBox:AddButton({
	Text = "Second Button",
	Func = function()
		Library:Notify("Second button pressed", 2)
	end,
})

-- Main right
local RightGroupBox = Tabs.Main:AddRightGroupbox("Another Box")

RightGroupBox:AddToggle("AnotherToggle", {
	Text = "Feature Toggle",
	Default = true,
	Callback = function(Value)
		print("Another:", Value)
	end,
})

RightGroupBox:AddLabel("This is a label")
RightGroupBox:AddDivider()

RightGroupBox:AddSlider("FOVSlider", {
	Text = "FOV",
	Default = 90,
	Min = 60,
	Max = 120,
	Rounding = 0,
})

RightGroupBox:AddDropdown("HitPart", {
	Values = { "Head", "Body", "Closest" },
	Default = 1,
	Text = "Hit Part",
})

RightGroupBox:AddButton({
	Text = "Print Toggles",
	Func = function()
		for name, toggle in pairs(Toggles) do
			print(name, toggle.Value)
		end
	end,
})

-- Combat tab extra content
local CombatLeft = Tabs.Combat:AddLeftGroupbox("Aim")
CombatLeft:AddToggle("AimEnabled", { Text = "Enable Aim", Default = false })
CombatLeft:AddSlider("AimSmooth", { Text = "Smoothness", Default = 5, Min = 0, Max = 50, Rounding = 0 })
CombatLeft:AddDropdown("AimMode", { Values = { "FOV", "Distance", "Health" }, Default = 1, Text = "Priority" })

local CombatRight = Tabs.Combat:AddRightGroupbox("Checks")
CombatRight:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
CombatRight:AddToggle("WallCheck", { Text = "Wall Check", Default = false })
CombatRight:AddToggle("VisibleCheck", { Text = "Visible Check", Default = true })
CombatRight:AddSlider("MaxDist", { Text = "Max Distance", Default = 500, Min = 50, Max = 2000, Rounding = 0 })

-- ===== UI Settings =====
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

pcall(function()
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
		Text = "Open Keybind Menu",
		Callback = function(Value)
			if Library.KeybindFrame then
				Library.KeybindFrame.Visible = Value
			end
		end,
	})
end)

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddToggle("UseBlur", {
	Text = "Background Blur",
	Default = true,
	Callback = function(Value)
		Library.UseBlur = Value
		if not Value and Library.BlurEffect then
			Library.BlurEffect.Size = 0
			Library.BlurEffect.Enabled = false
		elseif Value and Library.Toggled and Library.BlurEffect then
			Library.BlurEffect.Enabled = true
			Library.BlurEffect.Size = Library.BlurSize or 15
		end
	end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

MenuGroup:AddButton({
	Text = "Unload",
	Func = function()
		Library:Unload()
	end,
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- force white accent after themes
Library.AccentColor = Color3.fromRGB(255, 255, 255)
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
pcall(function() Library:UpdateColorsUsingRegistry() end)

SaveManager:LoadAutoloadConfig()
Library:Notify("Example loaded", 3)
