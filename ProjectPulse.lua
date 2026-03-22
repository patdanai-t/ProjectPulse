local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library

local Theme = {
	Background = Color3.fromRGB(10, 10, 14),
	Panel = Color3.fromRGB(16, 16, 22),
	PanelDark = Color3.fromRGB(12, 12, 18),
	Card = Color3.fromRGB(20, 20, 28),
	Stroke = Color3.fromRGB(48, 48, 66),
	Accent = Color3.fromRGB(145, 92, 255),
	AccentDark = Color3.fromRGB(92, 56, 176),
	Text = Color3.fromRGB(245, 245, 250),
	SubText = Color3.fromRGB(170, 170, 185),
	Danger = Color3.fromRGB(255, 95, 110),
}

local FontMap = {
	Main = Enum.Font.Gotham,
	Bold = Enum.Font.GothamBold,
	Code = Enum.Font.Code,
}

local DEFAULT_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FAST_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function tween(object, info, properties)
	return TweenService:Create(object, info or DEFAULT_TWEEN, properties)
end

local function create(className, properties)
	local instance = Instance.new(className)
	for key, value in pairs(properties or {}) do
		instance[key] = value
	end
	return instance
end

local function round(object, radius)
	local corner = create("UICorner", {
		CornerRadius = UDim.new(0, radius or 10),
	})
	corner.Parent = object
	return corner
end

local function stroke(object, color, thickness, transparency)
	local uiStroke = create("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	uiStroke.Parent = object
	return uiStroke
end

local function gradient(object, colors, rotation)
	local uiGradient = create("UIGradient", {
		Rotation = rotation or 0,
		Color = ColorSequence.new(colors),
	})
	uiGradient.Parent = object
	return uiGradient
end

local function shadow(parent, transparency)
	local image = create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = transparency or 0.45,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, 56, 1, 56),
		ZIndex = math.max(parent.ZIndex - 1, 0),
	})
	image.Parent = parent
	return image
end

local function hoverTint(color, amount)
	local shift = amount or 10
	return Color3.fromRGB(
		math.clamp(color.R * 255 + shift, 0, 255),
		math.clamp(color.G * 255 + shift, 0, 255),
		math.clamp(color.B * 255 + shift, 0, 255)
	)
end

local function makeButtonHover(button, target)
	local base = target.BackgroundColor3
	local hover = hoverTint(base, 8)

	button.MouseEnter:Connect(function()
		tween(target, FAST_TWEEN, {BackgroundColor3 = hover}):Play()
	end)

	button.MouseLeave:Connect(function()
		tween(target, FAST_TWEEN, {BackgroundColor3 = base}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		tween(target, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Theme.AccentDark,
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		tween(target, FAST_TWEEN, {BackgroundColor3 = hover}):Play()
	end)
end

local function dragify(handle, target)
	local dragging = false
	local dragStart
	local startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local delta = input.Position - dragStart
		target.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)
end

local function safeFlag(text)
	return string.lower((text or "option"):gsub("%W+", "_"))
end

function Library:Notify(title, message, duration)
	if not self.NotificationHolder or not self.NotificationHolder.Parent then
		return
	end

	local toast = create("Frame", {
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
	})
	round(toast, 12)
	stroke(toast, Theme.Stroke, 1, 0.1)
	shadow(toast, 0.58)
	toast.Parent = self.NotificationHolder

	local accent = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
	})
	round(accent, 12)
	accent.Parent = toast

	local padding = create("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	padding.Parent = toast

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = tostring(title or "Notification"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -10, 0, 18),
	})
	titleLabel.Parent = toast

	local messageLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(message or ""),
		TextColor3 = Theme.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 10, 0, 20),
		Size = UDim2.new(1, -10, 0, 20),
	})
	messageLabel.Parent = toast

	RunService.Heartbeat:Wait()
	local finalSize = math.max(56, titleLabel.TextBounds.Y + messageLabel.TextBounds.Y + 30)
	tween(toast, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, finalSize),
	}):Play()

	task.delay(duration or 3.5, function()
		if toast.Parent then
			local closeTween = tween(toast, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
			})
			closeTween:Play()
			closeTween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

function Library:_createScreenGui()
	if self.ScreenGui and self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = "PulseExecutorUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})
	gui.Parent = game:GetService("CoreGui")
	self.ScreenGui = gui

	local notifHolder = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -22, 0, 22),
		Size = UDim2.new(0, 320, 1, -44),
	})
	notifHolder.Parent = gui

	local notifList = create("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	notifList.Parent = notifHolder

	self.NotificationHolder = notifHolder
end

function Library:_setBlur(enabled)
	if not self.BlurEffect then
		self.BlurEffect = Lighting:FindFirstChild("PulseExecutorBlur")
		if not self.BlurEffect then
			self.BlurEffect = create("BlurEffect", {
				Name = "PulseExecutorBlur",
				Size = 0,
				Enabled = false,
			})
			self.BlurEffect.Parent = Lighting
		end
	end

	self.BlurEffect.Enabled = true
	tween(self.BlurEffect, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = enabled and 18 or 0,
	}):Play()

	if not enabled then
		task.delay(0.3, function()
			if self.BlurEffect then
				self.BlurEffect.Enabled = false
			end
		end)
	end
end

function Library:Toggle()
	self.Visible = not self.Visible
	if self.Root then
		self.Root.Visible = true
		local targetSize = self.Visible and UDim2.new(0, 1040, 0, 640) or UDim2.new(0, 980, 0, 0)
		self:_setBlur(self.Visible)
		tween(self.Root, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = targetSize,
			BackgroundTransparency = self.Visible and 0 or 1,
		}):Play()
		if not self.Visible then
			task.delay(0.28, function()
				if self.Root then
					self.Root.Visible = false
				end
			end)
		end
	end
end

function Library:_registerInput()
	if self._boundInput then
		self._boundInput:Disconnect()
	end

	self._boundInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
			self:Toggle()
		end
	end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Window:_switchTab(targetTab)
	if self.CurrentTab == targetTab then
		return
	end

	if self.CurrentTab and self.CurrentTab.Page then
		local previous = self.CurrentTab
		tween(previous.Page, FAST_TWEEN, {
			Position = UDim2.new(0, 16, 0, 0),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.16, function()
			if previous.Page then
				previous.Page.Visible = false
			end
		end)

		tween(previous.ButtonFill, FAST_TWEEN, {BackgroundTransparency = 1}):Play()
		tween(previous.ButtonTitle, FAST_TWEEN, {TextColor3 = Theme.SubText}):Play()
	end

	self.CurrentTab = targetTab
	targetTab.Page.Visible = true
	targetTab.Page.Position = UDim2.new(0, 24, 0, 0)
	targetTab.Page.BackgroundTransparency = 1
	tween(targetTab.Page, DEFAULT_TWEEN, {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0,
	}):Play()
	tween(targetTab.ButtonFill, FAST_TWEEN, {BackgroundTransparency = 0}):Play()
	tween(targetTab.ButtonTitle, FAST_TWEEN, {TextColor3 = Theme.Text}):Play()
end

function Window:_storeFlag(flag, value)
	self.Flags[flag] = value
end

function Window:SaveConfig(name)
	local configName = tostring(name or self.ConfigName or "pulse_config")
	self.ConfigName = configName

	if writefile then
		writefile(configName .. ".json", HttpService:JSONEncode(self.Flags))
		self.Library:Notify("Config Saved", "Saved settings to " .. configName .. ".json", 3)
	end
end

function Window:LoadConfig(name)
	local configName = tostring(name or self.ConfigName or "pulse_config")
	self.ConfigName = configName

	if readfile and isfile and isfile(configName .. ".json") then
		local decoded = HttpService:JSONDecode(readfile(configName .. ".json"))
		for flag, value in pairs(decoded) do
			self.Flags[flag] = value
			local setter = self.Setters[flag]
			if setter then
				setter(value)
			end
		end
		self.Library:Notify("Config Loaded", "Loaded settings from " .. configName .. ".json", 3)
	end
end

function Window:_newEditorTab(name, content)
	local tabData = {
		Name = name,
		Content = content or "",
	}

	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Font = FontMap.Main,
		Text = tabData.Name,
		TextColor3 = Theme.SubText,
		TextSize = 13,
		Size = UDim2.new(0, 110, 0, 32),
	})
	round(button, 8)
	stroke(button, Theme.Stroke, 1, 0.15)
	button.Parent = self.EditorTabButtons
	makeButtonHover(button, button)

	tabData.Button = button
	table.insert(self.EditorTabs, tabData)

	button.MouseButton1Click:Connect(function()
		self:SetEditorTab(tabData)
	end)

	if not self.ActiveEditorTab then
		self:SetEditorTab(tabData)
	end

	return tabData
end

function Window:SetEditorTab(tabData)
	self.ActiveEditorTab = tabData
	for _, scriptTab in ipairs(self.EditorTabs) do
		local active = scriptTab == tabData
		tween(scriptTab.Button, FAST_TWEEN, {
			BackgroundColor3 = active and Theme.Accent or Theme.Card,
			BackgroundTransparency = active and 0 or 0.18,
		}):Play()
		scriptTab.Button.TextColor3 = active and Theme.Text or Theme.SubText
	end
	self.EditorBox.Text = tabData.Content or ""
end

function Window:_buildEditor(parent)
	local editorPanel = create("Frame", {
		BackgroundColor3 = Theme.PanelDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 220),
	})
	round(editorPanel, 12)
	stroke(editorPanel, Theme.Stroke, 1, 0.08)
	gradient(editorPanel, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 26)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 18)),
	}, 90)
	editorPanel.Parent = parent

	local padding = create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	padding.Parent = editorPanel

	local topRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
	})
	topRow.Parent = editorPanel

	local editorTitle = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = "Script Editor",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0, 120, 1, 0),
	})
	editorTitle.Parent = topRow

	local tabScroll = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 128, 0, 0),
		ScrollBarImageColor3 = Theme.Accent,
		ScrollBarThickness = 0,
		Size = UDim2.new(1, -260, 1, 0),
	})
	tabScroll.Parent = topRow

	local tabList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	tabList.Parent = tabScroll
	self.EditorTabButtons = tabScroll

	local addScript = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Font = FontMap.Bold,
		Text = "+",
		TextColor3 = Theme.Text,
		TextSize = 20,
		Position = UDim2.new(1, -196, 0, 0),
		Size = UDim2.new(0, 32, 0, 32),
	})
	round(addScript, 8)
	stroke(addScript, Theme.Stroke, 1, 0.1)
	addScript.Parent = topRow
	makeButtonHover(addScript, addScript)

	local execute = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Font = FontMap.Bold,
		Text = "Execute",
		TextColor3 = Theme.Text,
		TextSize = 13,
		Position = UDim2.new(1, -94, 0, 0),
		Size = UDim2.new(0, 88, 0, 32),
	})
	round(execute, 8)
	stroke(execute, Theme.Accent, 1, 0.1)
	execute.Parent = topRow
	makeButtonHover(execute, execute)

	local clear = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Font = FontMap.Bold,
		Text = "Clear",
		TextColor3 = Theme.Text,
		TextSize = 13,
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 88, 0, 32),
	})
	round(clear, 8)
	stroke(clear, Theme.Stroke, 1, 0.1)
	clear.Parent = topRow
	makeButtonHover(clear, clear)

	local editorBody = create("Frame", {
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 1, -42),
	})
	round(editorBody, 10)
	stroke(editorBody, Theme.Stroke, 1, 0.1)
	editorBody.Parent = editorPanel

	local editorBox = create("TextBox", {
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = FontMap.Code,
		MultiLine = true,
		PlaceholderColor3 = Theme.SubText,
		PlaceholderText = "-- print('Hello from Pulse Executor')",
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
	})
	editorBox.Parent = editorBody
	self.EditorBox = editorBox
	self.EditorTabs = {}

	editorBox:GetPropertyChangedSignal("Text"):Connect(function()
		if self.ActiveEditorTab then
			self.ActiveEditorTab.Content = editorBox.Text
		end
	end)

	addScript.MouseButton1Click:Connect(function()
		local newTab = self:_newEditorTab("Script " .. (#self.EditorTabs + 1), "")
		self:SetEditorTab(newTab)
	end)

	clear.MouseButton1Click:Connect(function()
		editorBox.Text = ""
		if self.ActiveEditorTab then
			self.ActiveEditorTab.Content = ""
		end
	end)

	execute.MouseButton1Click:Connect(function()
		local source = editorBox.Text
		if source:gsub("%s+", "") == "" then
			self.Library:Notify("Executor", "Editor is empty.", 2.5)
			return
		end

		local compiler = loadstring or load
		if not compiler then
			self.Library:Notify("Executor", "loadstring is not available.", 3)
			return
		end

		local chunk, compileError = compiler(source)
		if not chunk then
			self.Library:Notify("Compile Error", tostring(compileError), 4)
			return
		end

		local ok, runtimeError = pcall(chunk)
		if ok then
			self.Library:Notify("Executor", "Script executed successfully.", 2.5)
		else
			self.Library:Notify("Runtime Error", tostring(runtimeError), 4)
		end
	end)

	self:_newEditorTab("Script 1", "")
end

function Window:CreateTab(name, icon)
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = name or "Tab"
	tab.Icon = icon or "*"

	local tabButton = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		Text = "",
	})
	round(tabButton, 10)
	tabButton.Parent = self.SidebarList

	local fill = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	})
	round(fill, 10)
	fill.Parent = tabButton

	local iconLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = tostring(tab.Icon),
		TextColor3 = Theme.Text,
		TextSize = 14,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0, 18, 1, 0),
	})
	iconLabel.Parent = tabButton

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(tab.Name),
		TextColor3 = Theme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 40, 0, 0),
		Size = UDim2.new(1, -46, 1, 0),
	})
	titleLabel.Parent = tabButton

	local page = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = Theme.Accent,
		ScrollBarThickness = 3,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
	})
	page.Parent = self.PageContainer

	local layout = create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	layout.Parent = page

	tab.Page = page
	tab.Button = tabButton
	tab.ButtonFill = fill
	tab.ButtonTitle = titleLabel
	tab.Container = page

	tabButton.MouseButton1Click:Connect(function()
		self:_switchTab(tab)
	end)

	tabButton.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then
			tween(tabButton, FAST_TWEEN, {BackgroundTransparency = 0.18}):Play()
		end
	end)

	tabButton.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then
			tween(tabButton, FAST_TWEEN, {BackgroundTransparency = 1}):Play()
		end
	end)

	table.insert(self.Tabs, tab)
	if not self.CurrentTab then
		self:_switchTab(tab)
	end

	return tab
end

function Tab:_baseElement(height)
	local frame = create("Frame", {
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 0, height),
	})
	round(frame, 10)
	stroke(frame, Theme.Stroke, 1, 0.1)
	frame.Parent = self.Container
	return frame
end

function Tab:AddLabel(text)
	local frame = self:_baseElement(42)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(text or "Label"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
	})
	label.Parent = frame
	return label
end

function Tab:AddButton(text, callback)
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Font = FontMap.Bold,
		Text = tostring(text or "Button"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		Size = UDim2.new(1, -4, 0, 42),
	})
	round(button, 10)
	stroke(button, Theme.Stroke, 1, 0.1)
	button.Parent = self.Container
	makeButtonHover(button, button)

	button.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)

	return button
end

function Tab:AddToggle(text, default, callback)
	local flag = safeFlag(text)
	local state = default and true or false
	self.Window:_storeFlag(flag, state)

	local frame = self:_baseElement(48)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(text or "Toggle"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -84, 1, 0),
	})
	label.Parent = frame

	local toggle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(40, 40, 54),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 48, 0, 24),
		Text = "",
	})
	round(toggle, 12)
	toggle.Parent = frame

	local knob = create("Frame", {
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		Position = UDim2.new(0, state and 26 or 2, 0, 2),
		Size = UDim2.new(0, 20, 0, 20),
	})
	round(knob, 10)
	knob.Parent = toggle

	local function setToggle(value)
		state = value and true or false
		self.Window:_storeFlag(flag, state)
		tween(toggle, FAST_TWEEN, {
			BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(40, 40, 54),
		}):Play()
		tween(knob, FAST_TWEEN, {
			Position = UDim2.new(0, state and 26 or 2, 0, 2),
		}):Play()
		if callback then
			task.spawn(callback, state)
		end
	end

	toggle.MouseButton1Click:Connect(function()
		setToggle(not state)
	end)

	self.Window.Setters[flag] = setToggle
	return {
		Set = setToggle,
		Get = function()
			return state
		end,
	}
end

function Tab:AddSlider(text, min, max, default, callback)
	local flag = safeFlag(text)
	local minimum = tonumber(min) or 0
	local maximum = tonumber(max) or 100
	local value = math.clamp(tonumber(default) or minimum, minimum, maximum)
	self.Window:_storeFlag(flag, value)

	local frame = self:_baseElement(62)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(text or "Slider"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 6),
		Size = UDim2.new(1, -80, 0, 18),
	})
	label.Parent = frame

	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = tostring(value),
		TextColor3 = Theme.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -14, 0, 6),
		Size = UDim2.new(0, 60, 0, 18),
	})
	valueLabel.Parent = frame

	local bar = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(35, 35, 46),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 14, 0, 36),
		Size = UDim2.new(1, -28, 0, 10),
	})
	round(bar, 999)
	bar.Parent = frame

	local fill = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0),
	})
	round(fill, 999)
	fill.Parent = bar

	local dragging = false

	local function setSlider(newValue)
		value = math.clamp(math.floor(newValue + 0.5), minimum, maximum)
		self.Window:_storeFlag(flag, value)
		valueLabel.Text = tostring(value)
		tween(fill, FAST_TWEEN, {
			Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0),
		}):Play()
		if callback then
			task.spawn(callback, value)
		end
	end

	local function updateFromInput(input)
		local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setSlider(minimum + ((maximum - minimum) * percent))
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	self.Window.Setters[flag] = setSlider
	return {
		Set = setSlider,
		Get = function()
			return value
		end,
	}
end

function Tab:AddTextbox(text, placeholder, callback)
	local flag = safeFlag(text)
	self.Window:_storeFlag(flag, "")

	local frame = self:_baseElement(76)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(text or "Textbox"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -28, 0, 18),
	})
	label.Parent = frame

	local box = create("TextBox", {
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = FontMap.Main,
		PlaceholderColor3 = Theme.SubText,
		PlaceholderText = tostring(placeholder or "Enter text..."),
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 34),
		Size = UDim2.new(1, -28, 0, 30),
	})
	round(box, 8)
	stroke(box, Theme.Stroke, 1, 0.1)
	box.Parent = frame

	local function setTextbox(value)
		box.Text = tostring(value or "")
		self.Window:_storeFlag(flag, box.Text)
		if callback then
			task.spawn(callback, box.Text)
		end
	end

	box.FocusLost:Connect(function()
		setTextbox(box.Text)
	end)

	self.Window.Setters[flag] = setTextbox
	return {
		Set = setTextbox,
		Get = function()
			return box.Text
		end,
	}
end

function Tab:AddDropdown(text, options, callback)
	local flag = safeFlag(text)
	local list = options or {}
	local selected = list[1] or ""
	self.Window:_storeFlag(flag, selected)

	local frame = self:_baseElement(82)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = tostring(text or "Dropdown"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -28, 0, 18),
	})
	label.Parent = frame

	local main = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Font = FontMap.Main,
		Text = selected ~= "" and selected or "Select...",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 34),
		Size = UDim2.new(1, -28, 0, 34),
	})
	round(main, 8)
	stroke(main, Theme.Stroke, 1, 0.1)
	main.Parent = frame

	local arrow = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = "v",
		TextColor3 = Theme.SubText,
		TextSize = 14,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
	})
	arrow.Parent = main

	local dropdown = create("Frame", {
		BackgroundColor3 = Theme.PanelDark,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 14, 0, 72),
		Size = UDim2.new(1, -28, 0, 0),
		ZIndex = 30,
	})
	round(dropdown, 8)
	stroke(dropdown, Theme.Stroke, 1, 0.1)
	dropdown.Parent = frame

	local optionHolder = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
	})
	optionHolder.Parent = dropdown

	local optionLayout = create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	optionLayout.Parent = optionHolder

	local open = false

	local function setDropdown(value)
		selected = value
		main.Text = tostring(value)
		arrow.Parent = main
		self.Window:_storeFlag(flag, selected)
		if callback then
			task.spawn(callback, selected)
		end
	end

	local function rebuild()
		for _, child in ipairs(optionHolder:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for _, option in ipairs(list) do
			local optionButton = create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Card,
				BorderSizePixel = 0,
				Font = FontMap.Main,
				Text = tostring(option),
				TextColor3 = Theme.Text,
				TextSize = 13,
				Size = UDim2.new(1, 0, 0, 28),
			})
			round(optionButton, 8)
			optionButton.Parent = optionHolder
			makeButtonHover(optionButton, optionButton)

			optionButton.MouseButton1Click:Connect(function()
				setDropdown(option)
				open = false
				tween(dropdown, FAST_TWEEN, {Size = UDim2.new(1, -28, 0, 0)}):Play()
			end)
		end
	end

	rebuild()

	main.MouseButton1Click:Connect(function()
		open = not open
		tween(dropdown, DEFAULT_TWEEN, {
			Size = UDim2.new(1, -28, 0, open and math.min(#list * 34 + 6, 132) or 0),
		}):Play()
	end)

	self.Window.Setters[flag] = setDropdown
	return {
		Set = setDropdown,
		Get = function()
			return selected
		end,
		Refresh = function(newOptions)
			list = newOptions or {}
			rebuild()
		end,
	}
end

function Library:CreateWindow(title)
	self:_createScreenGui()
	self:_registerInput()
	self.Visible = true

	local window = setmetatable({
		Library = self,
		Tabs = {},
		Flags = {},
		Setters = {},
		ConfigName = "pulse_config",
	}, Window)

	local root = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 1040, 0, 640),
	})
	round(root, 12)
	stroke(root, Theme.Stroke, 1, 0.08)
	shadow(root, 0.38)
	root.Parent = self.ScreenGui
	self.Root = root

	gradient(root, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 24)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(12, 12, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
	}, 90)

	local topbar = create("Frame", {
		BackgroundColor3 = Theme.PanelDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 48),
	})
	topbar.Parent = root

	local topbarLine = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
	})
	topbarLine.Parent = topbar

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = tostring(title or "Pulse Executor"),
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(0, 260, 1, 0),
	})
	titleLabel.Parent = topbar

	local subtitle = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = "Professional UI Library",
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 160, 0, 0),
		Size = UDim2.new(0, 180, 1, 0),
	})
	subtitle.Parent = topbar

	local controls = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.new(0, 92, 0, 32),
	})
	controls.Parent = topbar

	local controlList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	controlList.Parent = controls

	local function makeWindowButton(symbol, color)
		local btn = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Font = FontMap.Bold,
			Text = symbol,
			TextColor3 = Theme.Text,
			TextSize = 14,
			Size = UDim2.new(0, 24, 0, 24),
		})
		round(btn, 999)
		btn.Parent = controls
		makeButtonHover(btn, btn)
		return btn
	end

	local minimize = makeWindowButton("-", Color3.fromRGB(72, 72, 92))
	local close = makeWindowButton("x", Theme.Danger)

	local sidebar = create("Frame", {
		BackgroundColor3 = Theme.PanelDark,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(0, 220, 1, -48),
	})
	sidebar.Parent = root

	local sidebarPadding = create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	})
	sidebarPadding.Parent = sidebar

	local brand = create("Frame", {
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 64),
	})
	round(brand, 12)
	stroke(brand, Theme.Stroke, 1, 0.1)
	brand.Parent = sidebar

	local brandIcon = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = "M",
		TextColor3 = Theme.Text,
		TextSize = 24,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(0, 32, 1, 0),
	})
	brandIcon.Parent = brand

	local brandName = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Bold,
		Text = "Max Style",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 54, 0, 12),
		Size = UDim2.new(1, -62, 0, 18),
	})
	brandName.Parent = brand

	local brandDesc = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FontMap.Main,
		Text = "Executor Dashboard",
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 54, 0, 30),
		Size = UDim2.new(1, -62, 0, 16),
	})
	brandDesc.Parent = brand

	local tabScroll = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 78),
		ScrollBarThickness = 0,
		Size = UDim2.new(1, 0, 1, -78),
	})
	tabScroll.Parent = sidebar

	local tabList = create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	tabList.Parent = tabScroll
	window.SidebarList = tabScroll

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 220, 0, 48),
		Size = UDim2.new(1, -220, 1, -48),
	})
	content.Parent = root

	local contentPadding = create("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	})
	contentPadding.Parent = content

	local contentList = create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	contentList.Parent = content

	local pageArea = create("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -232),
	})
	round(pageArea, 12)
	stroke(pageArea, Theme.Stroke, 1, 0.08)
	pageArea.Parent = content

	local pagePadding = create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	pagePadding.Parent = pageArea

	local pageContainer = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	})
	pageContainer.Parent = pageArea
	window.PageContainer = pageContainer

	window:_buildEditor(content)

	close.MouseButton1Click:Connect(function()
		self.Visible = false
		self:_setBlur(false)
		root:Destroy()
	end)

	minimize.MouseButton1Click:Connect(function()
		self:Toggle()
	end)

	dragify(topbar, root)
	self:_setBlur(true)
	self:Notify("Pulse Executor", "Press RightShift to toggle the UI.", 3.5)

	return window
end

return setmetatable({}, Library)
