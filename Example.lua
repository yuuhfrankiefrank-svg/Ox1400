local repo = "https://raw.githubusercontent.com/yuuhfrankiefrank-svg/Ox1400/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = getgenv().Options or Library.Options
local Toggles = getgenv().Toggles or Library.Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

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
	["UI Settings"] = Window:AddTab("UI Settings"),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox")

LeftGroupBox:AddToggle("MyToggle", {
	Text = "Example Toggle",
	Default = false,
	Tooltip = "Example tooltip",
	Callback = function(Value)
		print("Toggle:", Value)
	end,
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

LeftGroupBox:AddDropdown("MyDropdown", {
	Values = { "Option A", "Option B", "Option C" },
	Default = 1,
	Multi = false,
	Text = "Example Dropdown",
	Callback = function(Value)
		print("Dropdown:", Value)
	end,
})

LeftGroupBox:AddButton({
	Text = "Notify Test",
	Func = function()
		Library:Notify("Hello from example.lua", 3)
	end,
})

local RightGroupBox = Tabs.Main:AddRightGroupbox("Another Box")

RightGroupBox:AddToggle("AnotherToggle", {
	Text = "Another Toggle",
	Default = true,
	Callback = function(Value)
		print("Another:", Value)
	end,
})

RightGroupBox:AddLabel("This is a label")
RightGroupBox:AddDivider()
RightGroupBox:AddButton({
	Text = "Print Toggles",
	Func = function()
		for name, toggle in pairs(Toggles) do
			print(name, toggle.Value)
		end
	end,
})

-- ===== UI Settings (full) =====
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
	Text = "Open Keybind Menu",
	Callback = function(Value)
		if Library.KeybindFrame then
			Library.KeybindFrame.Visible = Value
		end
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
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

SaveManager:LoadAutoloadConfig()
