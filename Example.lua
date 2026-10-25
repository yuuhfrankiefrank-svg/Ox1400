-- Example menu using LinoriaRivalsSafe (Rivals-safe, mobile + PC)
-- Upload LinoriaRivalsSafe.lua to this repo path first.

local repo = "https://raw.githubusercontent.com/yuuhfrankiefrank-svg/Ox1400/main/"
local Library = loadstring(game:HttpGet(repo .. "LinoriaRivalsSafe.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = false
Library.NotifySide = "Left"

local Window = Library:CreateWindow({
	Title = "Example menu",
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = false,
	NotifySide = "Left",
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
	Default = "Option A",
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

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

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

-- Optional: ThemeManager / SaveManager stubs are inside the lib
-- so these calls will not crash if present on getgenv
pcall(function()
	local ThemeManager = getgenv().ThemeManager
	local SaveManager = getgenv().SaveManager
	if ThemeManager and SaveManager then
		ThemeManager:SetLibrary(Library)
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
		ThemeManager:SetFolder("MyScriptHub")
		SaveManager:SetFolder("MyScriptHub/specific-game")
		SaveManager:BuildConfigSection(Tabs["UI Settings"])
		ThemeManager:ApplyToTab(Tabs["UI Settings"])
		SaveManager:LoadAutoloadConfig()
	end
end)

Library:Notify("Example loaded", 3)
