--[[
    Linoria-compatible UI (Rivals-safe)
    - No Drawing API
    - Safe gethui / CoreGui / PlayerGui parenting
    - Mobile + PC UIScale
    - pcall-hardened; no camera unlock spam
    API mirrors common Linoria usage: CreateWindow, AddTab, AddLeft/RightGroupbox,
    AddToggle, AddSlider, AddDropdown, AddButton, AddLabel, AddDivider, AddKeyPicker, etc.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Library = {
	Options = {},
	Toggles = {},
	Unloaded = false,
	Toggled = true,
	ToggleKeybind = Enum.KeyCode.RightShift,
	ShowCustomCursor = false,
	KeybindFrame = { Visible = false },
	CornerRadius = 4,
	DPIScale = 1,
	NotifySide = "Right",
	ForceCheckbox = false,
	ShowToggleFrameInKeybinds = true,
}

getgenv().Library = Library
getgenv().Options = Library.Options
getgenv().Toggles = Library.Toggles

local Theme = {
	Background = Color3.fromRGB(18, 18, 22),
	Panel = Color3.fromRGB(24, 24, 30),
	Element = Color3.fromRGB(30, 30, 38),
	ElementHover = Color3.fromRGB(38, 38, 48),
	Border = Color3.fromRGB(45, 45, 55),
	Accent = Color3.fromRGB(0, 162, 255),
	Text = Color3.fromRGB(230, 230, 235),
	SubText = Color3.fromRGB(150, 150, 160),
	Risk = Color3.fromRGB(255, 80, 80),
}

local function safeParent(gui)
	local ok
	ok = pcall(function()
		if gethui then
			gui.Parent = gethui()
			return
		end
	end)
	if gui.Parent then return end
	ok = pcall(function()
		gui.Parent = CoreGui
	end)
	if gui.Parent then return end
	pcall(function()
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 3)
		if pg then gui.Parent = pg end
	end)
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or Theme and Library.CornerRadius or 4)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function pad(parent, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 6)
	p.PaddingRight = UDim.new(0, r or 6)
	p.PaddingTop = UDim.new(0, t or 6)
	p.PaddingBottom = UDim.new(0, b or 6)
	p.Parent = parent
	return p
end

local function isMobile()
	local ok, touch = pcall(function()
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end)
	return ok and touch
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LinoriaRivalsSafe"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 200
safeParent(ScreenGui)

local RootScale = Instance.new("UIScale")
RootScale.Name = "RootScale"
RootScale.Parent = ScreenGui

local function applyDPI()
	local cam = workspace.CurrentCamera
	local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
	local shortest = math.min(vp.X, vp.Y)
	local base = 1
	if isMobile() or shortest < 700 then
		base = math.clamp(shortest / 820, 0.55, 0.88)
	elseif shortest < 950 then
		base = math.clamp(shortest / 1050, 0.8, 1)
	else
		base = math.clamp(math.min(vp.X / 1440, vp.Y / 900), 0.9, 1.15)
	end
	RootScale.Scale = base * (Library.DPIScale or 1)
end
applyDPI()
pcall(function()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(applyDPI)
	end)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyDPI)
	end
end)

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "Notifications"
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Size = UDim2.fromScale(1, 1)
NotifyHolder.Parent = ScreenGui

function Library:SetDPIScale(n)
	Library.DPIScale = (tonumber(n) or 100) / 100
	applyDPI()
end

function Library:SetNotifySide(side)
	Library.NotifySide = side
end

function Library:Notify(text, duration)
	duration = duration or 3
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(260, 40)
	f.BackgroundColor3 = Theme.Panel
	f.BorderSizePixel = 0
	f.Parent = NotifyHolder
	corner(f, 6)
	stroke(f, Theme.Accent, 1)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextColor3 = Theme.Text
	label.Text = tostring(text)
	label.TextWrapped = true
	label.Parent = f
	pad(label, 10, 10, 4, 4)
	local side = Library.NotifySide == "Left" and 0 or 1
	f.AnchorPoint = Vector2.new(side, 0)
	f.Position = UDim2.new(side, side == 0 and 12 or -12, 0, 12 + (#NotifyHolder:GetChildren() - 1) * 48)
	task.delay(duration, function()
		pcall(function() f:Destroy() end)
	end)
end

local function makeScroll(parent)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 3
	s.ScrollBarImageColor3 = Theme.Accent
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.Size = UDim2.fromScale(1, 1)
	s.Active = true
	s.ScrollingEnabled = true
	s.Parent = parent
	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 6)
	lay.Parent = s
	pad(s, 8, 8, 8, 8)
	return s
end

local function registerToggle(flag, data)
	local obj = {
		Value = data.Default == true,
		Type = "Toggle",
		Flag = flag,
	}
	function obj:SetValue(v)
		self.Value = v and true or false
		if data._setVisual then data._setVisual(self.Value) end
		if data.Callback then
			pcall(data.Callback, self.Value)
		end
	end
	function obj:OnChanged(fn)
		local old = data.Callback
		data.Callback = function(v)
			if old then pcall(old, v) end
			pcall(fn, v)
		end
	end
	Library.Toggles[flag] = obj
	return obj
end

local function registerOption(flag, data)
	local obj = {
		Value = data.Default,
		Type = data.Type or "Option",
		Flag = flag,
	}
	function obj:SetValue(v)
		self.Value = v
		if data._setVisual then data._setVisual(v) end
		if data.Callback then pcall(data.Callback, v) end
	end
	function obj:OnChanged(fn)
		local old = data.Callback
		data.Callback = function(v)
			if old then pcall(old, v) end
			pcall(fn, v)
		end
	end
	Library.Options[flag] = obj
	return obj
end

local function addToggleTo(container, order, flag, cfg)
	cfg = cfg or {}
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Theme.Element
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 28)
	row.LayoutOrder = order
	row.Parent = container
	corner(row, 4)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(8, 0)
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Text
	label.Text = cfg.Text or flag
	label.Parent = row

	local box = Instance.new("TextButton")
	box.AutoButtonColor = false
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -8, 0.5, 0)
	box.Size = UDim2.fromOffset(18, 18)
	box.BackgroundColor3 = Theme.Background
	box.Text = ""
	box.Parent = row
	corner(box, 3)
	stroke(box, Theme.Border, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Visible = cfg.Default == true
	fill.Parent = box
	corner(fill, 3)

	local data = {
		Default = cfg.Default == true,
		Callback = cfg.Callback,
	}
	data._setVisual = function(v)
		fill.Visible = v
	end
	local obj = registerToggle(flag, data)

	box.MouseButton1Click:Connect(function()
		obj:SetValue(not obj.Value)
	end)
	return obj
end

local function addSliderTo(container, order, flag, cfg)
	cfg = cfg or {}
	local min = cfg.Min or 0
	local max = cfg.Max or 100
	local default = cfg.Default or min
	local rounding = cfg.Rounding or 0

	local row = Instance.new("Frame")
	row.BackgroundColor3 = Theme.Element
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 42)
	row.LayoutOrder = order
	row.Parent = container
	corner(row, 4)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(8, 2)
	title.Size = UDim2.new(1, -16, 0, 16)
	title.Font = Enum.Font.Gotham
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Text
	title.Text = (cfg.Text or flag) .. ": " .. tostring(default) .. (cfg.Suffix or "")
	title.Parent = row

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(8, 24)
	bar.Size = UDim2.new(1, -16, 0, 10)
	bar.BackgroundColor3 = Theme.Background
	bar.BorderSizePixel = 0
	bar.Parent = row
	corner(bar, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(math.clamp((default - min) / math.max(max - min, 1e-6), 0, 1), 1)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	corner(fill, 3)

	local data = { Default = default, Type = "Slider", Callback = cfg.Callback }
	local obj = registerOption(flag, data)

	local function setFromAlpha(a)
		a = math.clamp(a, 0, 1)
		local v = min + (max - min) * a
		if rounding <= 0 then
			v = math.floor(v + 0.5)
		else
			local m = 10 ^ rounding
			v = math.floor(v * m + 0.5) / m
		end
		fill.Size = UDim2.fromScale(a, 1)
		title.Text = (cfg.Text or flag) .. ": " .. tostring(v) .. (cfg.Suffix or "")
		obj.Value = v
		if cfg.Callback then pcall(cfg.Callback, v) end
	end

	data._setVisual = function(v)
		local a = math.clamp((v - min) / math.max(max - min, 1e-6), 0, 1)
		fill.Size = UDim2.fromScale(a, 1)
		title.Text = (cfg.Text or flag) .. ": " .. tostring(v) .. (cfg.Suffix or "")
	end

	local dragging = false
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local rel = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
			setFromAlpha(rel)
		end
	end)
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local rel = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
			setFromAlpha(rel)
		end
	end)

	return obj
end

local function addDropdownTo(container, order, flag, cfg)
	cfg = cfg or {}
	local values = cfg.Values or {}
	local default = cfg.Default or values[1]

	local row = Instance.new("Frame")
	row.BackgroundColor3 = Theme.Element
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 48)
	row.LayoutOrder = order
	row.Parent = container
	corner(row, 4)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(8, 2)
	title.Size = UDim2.new(1, -16, 0, 14)
	title.Font = Enum.Font.Gotham
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.SubText
	title.Text = cfg.Text or flag
	title.Parent = row

	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.Position = UDim2.fromOffset(8, 20)
	btn.Size = UDim2.new(1, -16, 0, 22)
	btn.BackgroundColor3 = Theme.Background
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 12
	btn.TextColor3 = Theme.Text
	btn.Text = tostring(default or "Select")
	btn.Parent = row
	corner(btn, 3)
	stroke(btn, Theme.Border, 1)

	local data = { Default = default, Type = "Dropdown", Callback = cfg.Callback }
	data._setVisual = function(v)
		btn.Text = tostring(v)
	end
	local obj = registerOption(flag, data)

	local open = false
	local list
	btn.MouseButton1Click:Connect(function()
		if open and list then
			list:Destroy()
			list = nil
			open = false
			return
		end
		open = true
		list = Instance.new("Frame")
		list.BackgroundColor3 = Theme.Panel
		list.BorderSizePixel = 0
		list.Size = UDim2.new(1, -16, 0, math.min(28 * #values, 140))
		list.Position = UDim2.fromOffset(8, 44)
		list.ZIndex = 50
		list.Parent = row
		corner(list, 4)
		stroke(list, Theme.Accent, 1)
		local lay = Instance.new("UIListLayout")
		lay.Parent = list
		for _, v in ipairs(values) do
			local item = Instance.new("TextButton")
			item.AutoButtonColor = false
			item.Size = UDim2.new(1, 0, 0, 28)
			item.BackgroundColor3 = Theme.Element
			item.Text = tostring(v)
			item.Font = Enum.Font.Gotham
			item.TextSize = 12
			item.TextColor3 = Theme.Text
			item.ZIndex = 51
			item.Parent = list
			item.MouseButton1Click:Connect(function()
				obj:SetValue(v)
				if list then list:Destroy() end
				list = nil
				open = false
			end)
		end
		row.Size = UDim2.new(1, 0, 0, 48 + list.Size.Y.Offset + 4)
	end)

	function obj:SetValues(newVals)
		values = newVals or values
	end

	return obj
end

local function addButtonTo(container, order, cfg)
	cfg = type(cfg) == "table" and cfg or { Text = tostring(cfg) }
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = Theme.Element
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.TextColor3 = Theme.Text
	btn.Text = cfg.Text or "Button"
	btn.LayoutOrder = order
	btn.Parent = container
	corner(btn, 4)
	stroke(btn, Theme.Border, 1)
	btn.MouseButton1Click:Connect(function()
		if cfg.Func then pcall(cfg.Func) end
		if cfg.Callback then pcall(cfg.Callback) end
	end)
	return btn
end

local function addLabelTo(container, order, text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.SubText
	label.Text = tostring(text)
	label.LayoutOrder = order
	label.Parent = container
	local api = {}
	function api:AddKeyPicker(flag, cfg)
		cfg = cfg or {}
		local data = { Default = cfg.Default or "RightShift", Type = "KeyPicker" }
		local obj = registerOption(flag, data)
		local map = {
			RightShift = Enum.KeyCode.RightShift,
			LeftShift = Enum.KeyCode.LeftShift,
			RightControl = Enum.KeyCode.RightControl,
			LeftControl = Enum.KeyCode.LeftControl,
			End = Enum.KeyCode.End,
			Home = Enum.KeyCode.Home,
			Insert = Enum.KeyCode.Insert,
			Delete = Enum.KeyCode.Delete,
		}
		obj.Value = data.Default
		function obj:Get()
			return map[self.Value] or Enum.KeyCode[self.Value] or Enum.KeyCode.RightShift
		end
		return obj
	end
	return api
end

local function addDividerTo(container, order)
	local d = Instance.new("Frame")
	d.BackgroundColor3 = Theme.Border
	d.BorderSizePixel = 0
	d.Size = UDim2.new(1, 0, 0, 1)
	d.LayoutOrder = order
	d.Parent = container
end

local function makeGroupbox(sideParent, name)
	local orderCounter = 0
	local box = Instance.new("Frame")
	box.BackgroundColor3 = Theme.Panel
	box.BorderSizePixel = 0
	box.Size = UDim2.new(1, 0, 0, 40)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.Parent = sideParent
	corner(box, 6)
	stroke(box, Theme.Border, 1)

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, -12, 0, 22)
	header.Position = UDim2.fromOffset(8, 4)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Theme.Accent
	header.Text = name or "Groupbox"
	header.Parent = box

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(6, 28)
	body.Size = UDim2.new(1, -12, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Parent = box
	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 5)
	lay.Parent = body

	local api = {}
	local function nextOrder()
		orderCounter += 1
		return orderCounter
	end

	function api:AddToggle(flag, cfg)
		return addToggleTo(body, nextOrder(), flag, cfg)
	end
	function api:AddSlider(flag, cfg)
		return addSliderTo(body, nextOrder(), flag, cfg)
	end
	function api:AddDropdown(flag, cfg)
		return addDropdownTo(body, nextOrder(), flag, cfg)
	end
	function api:AddButton(cfg, fn)
		if type(cfg) == "string" then
			cfg = { Text = cfg, Func = fn }
		end
		return addButtonTo(body, nextOrder(), cfg)
	end
	function api:AddLabel(text)
		return addLabelTo(body, nextOrder(), text)
	end
	function api:AddDivider()
		return addDividerTo(body, nextOrder())
	end
	function api:AddInput(flag, cfg)
		cfg = cfg or {}
		local row = Instance.new("Frame")
		row.BackgroundColor3 = Theme.Element
		row.Size = UDim2.new(1, 0, 0, 44)
		row.LayoutOrder = nextOrder()
		row.Parent = body
		corner(row, 4)
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(8, 2)
		title.Size = UDim2.new(1, -16, 0, 14)
		title.Font = Enum.Font.Gotham
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Theme.SubText
		title.Text = cfg.Text or flag
		title.Parent = row
		local box = Instance.new("TextBox")
		box.Position = UDim2.fromOffset(8, 18)
		box.Size = UDim2.new(1, -16, 0, 20)
		box.BackgroundColor3 = Theme.Background
		box.Font = Enum.Font.Gotham
		box.TextSize = 12
		box.TextColor3 = Theme.Text
		box.PlaceholderText = cfg.Placeholder or ""
		box.Text = tostring(cfg.Default or "")
		box.ClearTextOnFocus = false
		box.Parent = row
		corner(box, 3)
		local data = { Default = box.Text, Type = "Input", Callback = cfg.Callback }
		local obj = registerOption(flag, data)
		box.FocusLost:Connect(function()
			obj:SetValue(box.Text)
		end)
		return obj
	end
	function api:AddDependencyBox()
		return api
	end

	return api
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local titleText = cfg.Title or "Window"

	local outer = Instance.new("Frame")
	outer.Name = "MainWindow"
	outer.AnchorPoint = Vector2.new(0.5, 0.5)
	outer.Position = UDim2.fromScale(0.5, 0.5)
	outer.Size = cfg.Size or UDim2.fromOffset(560, 420)
	outer.BackgroundColor3 = Theme.Background
	outer.BorderSizePixel = 0
	outer.Active = true
	outer.Parent = ScreenGui
	corner(outer, 8)
	stroke(outer, Theme.Accent, 1.5)

	-- prevent camera drag when interacting
	outer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pcall(function()
				UserInputService.ModalEnabled = true
			end)
		end
	end)
	outer.InputEnded:Connect(function()
		pcall(function()
			UserInputService.ModalEnabled = false
		end)
	end)

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 32)
	titleBar.BackgroundColor3 = Theme.Panel
	titleBar.BorderSizePixel = 0
	titleBar.Parent = outer
	corner(titleBar, 8)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(12, 0)
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Text
	title.Text = titleText
	title.Parent = titleBar

	-- drag (PC + mobile)
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = outer.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			outer.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	local tabBar = Instance.new("Frame")
	tabBar.Position = UDim2.fromOffset(0, 32)
	tabBar.Size = UDim2.new(1, 0, 0, 30)
	tabBar.BackgroundColor3 = Theme.Panel
	tabBar.BorderSizePixel = 0
	tabBar.Parent = outer
	local tabLay = Instance.new("UIListLayout")
	tabLay.FillDirection = Enum.FillDirection.Horizontal
	tabLay.Padding = UDim.new(0, 4)
	tabLay.Parent = tabBar
	pad(tabBar, 6, 6, 2, 2)

	local content = Instance.new("Frame")
	content.Position = UDim2.fromOffset(0, 62)
	content.Size = UDim2.new(1, 0, 1, -62)
	content.BackgroundTransparency = 1
	content.Parent = outer

	local windowApi = {}
	local tabs = {}
	local currentTab

	function windowApi:AddTab(name)
		local tabBtn = Instance.new("TextButton")
		tabBtn.AutoButtonColor = false
		tabBtn.Size = UDim2.fromOffset(90, 24)
		tabBtn.BackgroundColor3 = Theme.Element
		tabBtn.Font = Enum.Font.Gotham
		tabBtn.TextSize = 12
		tabBtn.TextColor3 = Theme.Text
		tabBtn.Text = name
		tabBtn.Parent = tabBar
		corner(tabBtn, 4)

		local page = Instance.new("Frame")
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.Visible = false
		page.Parent = content

		local left = Instance.new("ScrollingFrame")
		left.Name = "Left"
		left.BackgroundTransparency = 1
		left.BorderSizePixel = 0
		left.ScrollBarThickness = 3
		left.ScrollBarImageColor3 = Theme.Accent
		left.AutomaticCanvasSize = Enum.AutomaticSize.Y
		left.CanvasSize = UDim2.new()
		left.Size = UDim2.new(0.5, -6, 1, -8)
		left.Position = UDim2.fromOffset(6, 4)
		left.Active = true
		left.Parent = page
		local leftLay = Instance.new("UIListLayout")
		leftLay.Padding = UDim.new(0, 8)
		leftLay.SortOrder = Enum.SortOrder.LayoutOrder
		leftLay.Parent = left

		local right = Instance.new("ScrollingFrame")
		right.Name = "Right"
		right.BackgroundTransparency = 1
		right.BorderSizePixel = 0
		right.ScrollBarThickness = 3
		right.ScrollBarImageColor3 = Theme.Accent
		right.AutomaticCanvasSize = Enum.AutomaticSize.Y
		right.CanvasSize = UDim2.new()
		right.Size = UDim2.new(0.5, -6, 1, -8)
		right.Position = UDim2.new(0.5, 2, 0, 4)
		right.Active = true
		right.Parent = page
		local rightLay = Instance.new("UIListLayout")
		rightLay.Padding = UDim.new(0, 8)
		rightLay.SortOrder = Enum.SortOrder.LayoutOrder
		rightLay.Parent = right

		local tabApi = {}
		function tabApi:AddLeftGroupbox(name)
			return makeGroupbox(left, name)
		end
		function tabApi:AddRightGroupbox(name)
			return makeGroupbox(right, name)
		end
		function tabApi:AddGroupbox(cfg)
			cfg = cfg or {}
			if cfg.Side == "Right" then
				return makeGroupbox(right, cfg.Name or "Groupbox")
			end
			return makeGroupbox(left, cfg.Name or "Groupbox")
		end

		tabBtn.MouseButton1Click:Connect(function()
			if currentTab then currentTab.Visible = false end
			page.Visible = true
			currentTab = page
			for _, b in ipairs(tabBar:GetChildren()) do
				if b:IsA("TextButton") then
					b.BackgroundColor3 = Theme.Element
				end
			end
			tabBtn.BackgroundColor3 = Theme.Accent
		end)

		if not currentTab then
			page.Visible = true
			currentTab = page
			tabBtn.BackgroundColor3 = Theme.Accent
		end

		tabs[name] = tabApi
		return tabApi
	end

	function windowApi:SetAlwaysOnTop(v)
		ScreenGui.DisplayOrder = v and 1000 or 200
	end

	function windowApi:SetCornerRadius(r)
		Library.CornerRadius = r
	end

	-- menu toggle key
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if Library.Unloaded then return end
		local key = Library.ToggleKeybind
		if typeof(key) == "table" and key.Get then
			key = key:Get()
		end
		if typeof(key) == "string" then
			key = Enum.KeyCode[key] or Enum.KeyCode.RightShift
		end
		if input.KeyCode == key then
			Library.Toggled = not Library.Toggled
			outer.Visible = Library.Toggled
		end
	end)

	Library._window = windowApi
	Library._outer = outer
	return windowApi
end

function Library:Toggle(vis)
	if vis == nil then vis = not Library.Toggled end
	Library.Toggled = vis
	if Library._outer then
		Library._outer.Visible = vis
	end
end

function Library:Unload()
	Library.Unloaded = true
	pcall(function() ScreenGui:Destroy() end)
end

function Library:OnUnload(fn)
	Library._onUnload = fn
end

-- minimal ThemeManager / SaveManager stubs so example scripts don't crash
local ThemeManager = {}
function ThemeManager:SetLibrary() end
function ThemeManager:SetFolder() end
function ThemeManager:ApplyToTab() end
function ThemeManager:ApplyToGroupbox() end

local SaveManager = {}
function SaveManager:SetLibrary() end
function SaveManager:SetFolder() end
function SaveManager:SetSubFolder() end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetIgnoreIndexes() end
function SaveManager:BuildConfigSection() end
function SaveManager:LoadAutoloadConfig() end

getgenv().ThemeManager = ThemeManager
getgenv().SaveManager = SaveManager

return Library
