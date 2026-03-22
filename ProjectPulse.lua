local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library

local Theme = {
	Background = Color3.fromRGB(13, 13, 13),
	Surface = Color3.fromRGB(19, 19, 22),
	SurfaceLight = Color3.fromRGB(26, 26, 30),
	Sidebar = Color3.fromRGB(17, 17, 19),
	Overlay = Color3.fromRGB(255, 255, 255),
	Stroke = Color3.fromRGB(52, 52, 60),
	Accent = Color3.fromRGB(122, 92, 255),
	AccentDark = Color3.fromRGB(92, 66, 204),
	AccentSoft = Color3.fromRGB(164, 146, 255),
	Text = Color3.fromRGB(245, 245, 248),
	SubText = Color3.fromRGB(155, 155, 168),
	Success = Color3.fromRGB(96, 216, 152),
	Danger = Color3.fromRGB(255, 96, 118),
}

local Fonts = {
	Main = Enum.Font.Gotham,
	Bold = Enum.Font.GothamBold,
	Code = Enum.Font.Code,
}

local DEFAULT_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FAST_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function create(className, props)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	return object
end

local function tween(object, info, props)
	return TweenService:Create(object, info or DEFAULT_TWEEN, props)
end

local function corner(parent, radius)
	local c = create("UICorner", {
		CornerRadius = UDim.new(0, radius or 12),
	})
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = create("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	})
	s.Parent = parent
	return s
end

local function gradient(parent, colors, rotation)
	local g = create("UIGradient", {
		Color = ColorSequence.new(colors),
		Rotation = rotation or 0,
	})
	g.Parent = parent
	return g
end

local function shadow(parent, transparency, size)
	local image = create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(),
		ImageTransparency = transparency or 0.52,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, size or 80, 1, size or 80),
		ZIndex = math.max(parent.ZIndex - 1, 0),
	})
	image.Parent = parent
	return image
end

local function glass(frame, radius)
	frame.BackgroundTransparency = 0.12
	corner(frame, radius or 12)
	stroke(frame, Theme.Overlay, 1, 0.9)
	return frame
end

local function safeFlag(text)
	return string.lower((text or "option"):gsub("%W+", "_"))
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

local function animatedAccent(parent)
	local bar = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 1, 0),
	})
	corner(bar, 12)
	bar.Parent = parent

	local glow = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		Position = UDim2.new(-0.2, 0, 0.5, 0),
		Size = UDim2.new(0, 160, 1.8, 0),
		Rotation = 12,
	})
	corner(glow, 999)
	glow.Parent = bar

	task.spawn(function()
		while bar.Parent do
			local moveA = tween(glow, TweenInfo.new(3.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(1.2, 0, 0.5, 0),
			})
			moveA:Play()
			moveA.Completed:Wait()
			if not bar.Parent then
				break
			end
			glow.Position = UDim2.new(-0.2, 0, 0.5, 0)
		end
	end)

	return bar
end

local function attachHoverTracker(button, target)
	local glow = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 0.84,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 0, 0),
		ZIndex = target.ZIndex + 1,
	})
	corner(glow, 999)
	glow.Parent = target

	local baseColor = target.BackgroundColor3
	local hovered = false

	button.MouseEnter:Connect(function()
		hovered = true
		tween(target, FAST_TWEEN, {
			BackgroundColor3 = Color3.fromRGB(
				math.clamp(baseColor.R * 255 + 10, 0, 255),
				math.clamp(baseColor.G * 255 + 10, 0, 255),
				math.clamp(baseColor.B * 255 + 10, 0, 255)
			),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		hovered = false
		tween(target, FAST_TWEEN, {BackgroundColor3 = baseColor}):Play()
		tween(glow, FAST_TWEEN, {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0, 0),
		}):Play()
	end)

	button.InputChanged:Connect(function(input)
		if not hovered or input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local relative = input.Position - target.AbsolutePosition
		glow.Position = UDim2.new(0, relative.X, 0, relative.Y)
		tween(glow, FAST_TWEEN, {
			BackgroundTransparency = 0.86,
			Size = UDim2.new(0, 110, 0, 110),
		}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		tween(target, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Theme.AccentDark,
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		if hovered then
			tween(target, FAST_TWEEN, {
				BackgroundColor3 = Color3.fromRGB(
					math.clamp(baseColor.R * 255 + 10, 0, 255),
					math.clamp(baseColor.G * 255 + 10, 0, 255),
					math.clamp(baseColor.B * 255 + 10, 0, 255)
				),
			}):Play()
		end
	end)
end

local function ripple(button)
	button.MouseButton1Down:Connect(function(x, y)
		local circle = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
			Size = UDim2.new(0, 0, 0, 0),
			ZIndex = button.ZIndex + 3,
		})
		corner(circle, 999)
		circle.Parent = button

		local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.15
		local anim = tween(circle, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, maxSize, 0, maxSize),
			BackgroundTransparency = 1,
		})
		anim:Play()
		anim.Completed:Connect(function()
			circle:Destroy()
		end)
	end)
end

local function makeInteractive(button, target)
	target.ClipsDescendants = true
	attachHoverTracker(button, target)
	ripple(button)
end

function Library:_createGui()
	if self.ScreenGui and self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = "PremiumExecutorLibrary",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	gui.Parent = game:GetService("CoreGui")
	self.ScreenGui = gui

	local notifications = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.new(0, 320, 1, -40),
	})
	notifications.Parent = gui

	local notifList = create("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	notifList.Parent = notifications

	self.NotificationHolder = notifications
end

function Library:_setupBlur()
	if self.Blur and self.Blur.Parent then
		return
	end

	self.Blur = Lighting:FindFirstChild("PremiumExecutorBlur")
	if not self.Blur then
		self.Blur = create("BlurEffect", {
			Name = "PremiumExecutorBlur",
			Enabled = false,
			Size = 0,
		})
		self.Blur.Parent = Lighting
	end
end

function Library:_setBlur(state)
	self:_setupBlur()
	self.Blur.Enabled = true
	tween(self.Blur, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = state and 18 or 0,
	}):Play()

	if not state then
		task.delay(0.28, function()
			if self.Blur then
				self.Blur.Enabled = false
			end
		end)
	end
end

function Library:Notify(title, text, duration)
	if not self.NotificationHolder then
		return
	end

	local toast = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
	})
	glass(toast, 14)
	shadow(toast, 0.62, 70)
	toast.Parent = self.NotificationHolder

	local accent = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
	})
	corner(accent, 999)
	accent.Parent = toast

	local pad = create("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 12),
	})
	pad.Parent = toast

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = tostring(title or "Notification"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -10, 0, 18),
		Position = UDim2.new(0, 10, 0, 0),
	})
	titleLabel.Parent = toast

	local body = create("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Fonts.Main,
		Text = tostring(text or ""),
		TextColor3 = Theme.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 10, 0, 22),
		Size = UDim2.new(1, -10, 0, 18),
	})
	body.Parent = toast

	RunService.Heartbeat:Wait()
	local finalHeight = math.max(60, 34 + body.TextBounds.Y)
	tween(toast, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, finalHeight),
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

function Library:Toggle()
	self.Visible = not self.Visible
	if not self.Root then
		return
	end

	self.Root.Visible = true
	self:_setBlur(self.Visible)
	local openSize = UDim2.new(0, 1080, 0, 680)
	local closedSize = UDim2.new(0, 1080, 0, 0)
	local anim = tween(self.Root, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = self.Visible and openSize or closedSize,
		BackgroundTransparency = self.Visible and 0.02 or 1,
	})
	anim:Play()

	if not self.Visible then
		task.delay(0.3, function()
			if self.Root then
				self.Root.Visible = false
			end
		end)
	end
end

function Library:_bindToggle()
	if self.InputConnection then
		self.InputConnection:Disconnect()
	end

	self.InputConnection = UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Enum.KeyCode.RightShift then
			self:Toggle()
		end
	end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Window:_setFlag(flag, value)
	self.Flags[flag] = value
end

function Window:SaveConfig(name)
	local config = tostring(name or self.ConfigName or "premium_executor_config")
	self.ConfigName = config
	if writefile then
		writefile(config .. ".json", HttpService:JSONEncode(self.Flags))
		self.Library:Notify("Config Saved", config .. ".json", 3)
	end
end

function Window:LoadConfig(name)
	local config = tostring(name or self.ConfigName or "premium_executor_config")
	self.ConfigName = config
	if readfile and isfile and isfile(config .. ".json") then
		local data = HttpService:JSONDecode(readfile(config .. ".json"))
		for flag, value in pairs(data) do
			self.Flags[flag] = value
			local setter = self.Setters[flag]
			if setter then
				setter(value)
			end
		end
		self.Library:Notify("Config Loaded", config .. ".json", 3)
	end
end

function Window:_switchPage(tab)
	if self.CurrentTab == tab then
		return
	end

	if self.CurrentTab then
		local old = self.CurrentTab
		tween(old.Page, FAST_TWEEN, {
			Position = UDim2.new(0, 22, 0, 0),
			BackgroundTransparency = 1,
		}):Play()
		tween(old.ButtonFill, FAST_TWEEN, {
			BackgroundTransparency = 1,
		}):Play()
		tween(old.ButtonLabel, FAST_TWEEN, {
			TextColor3 = Theme.SubText,
		}):Play()
		task.delay(0.14, function()
			if old.Page then
				old.Page.Visible = false
			end
		end)
	end

	self.CurrentTab = tab
	tab.Page.Visible = true
	tab.Page.Position = UDim2.new(0, -12, 0, 0)
	tab.Page.BackgroundTransparency = 1
	tween(tab.Page, DEFAULT_TWEEN, {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0,
	}):Play()
	tween(tab.ButtonFill, FAST_TWEEN, {
		BackgroundTransparency = 0.08,
	}):Play()
	tween(tab.ButtonLabel, FAST_TWEEN, {
		TextColor3 = Theme.Text,
	}):Play()
end

function Window:_makeEditorTab(name, content)
	local editorTab = {
		Name = name,
		Content = content or "",
	}

	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.SurfaceLight,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Font = Fonts.Main,
		Text = editorTab.Name,
		TextColor3 = Theme.SubText,
		TextSize = 13,
		Size = UDim2.new(0, 120, 0, 34),
		ZIndex = 6,
	})
	glass(button, 10)
	button.Parent = self.EditorTabsHolder
	makeInteractive(button, button)

	editorTab.Button = button
	table.insert(self.EditorTabs, editorTab)

	button.MouseButton1Click:Connect(function()
		self:SetEditorTab(editorTab)
	end)

	if not self.ActiveEditorTab then
		self:SetEditorTab(editorTab)
	end

	return editorTab
end

function Window:SetEditorTab(editorTab)
	self.ActiveEditorTab = editorTab

	for _, tab in ipairs(self.EditorTabs) do
		local active = tab == editorTab
		tween(tab.Button, FAST_TWEEN, {
			BackgroundColor3 = active and Theme.Accent or Theme.SurfaceLight,
			BackgroundTransparency = active and 0.02 or 0.12,
		}):Play()
		tab.Button.TextColor3 = active and Theme.Text or Theme.SubText
	end

	self.EditorBox.Text = editorTab.Content or ""
end

function Window:_buildEditor(parent)
	local holder = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 260),
		ZIndex = 4,
	})
	glass(holder, 14)
	shadow(holder, 0.6, 90)
	holder.Parent = parent

	local topGlow = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
	})
	topGlow.Parent = holder
	animatedAccent(topGlow)

	local pad = create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	})
	pad.Parent = holder

	local topRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
	})
	topRow.Parent = holder

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = "Script Editor",
		TextColor3 = Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0, 130, 1, 0),
	})
	title.Parent = topRow

	local tabsHolder = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 140, 0, 0),
		ScrollBarThickness = 0,
		Size = UDim2.new(1, -420, 1, 0),
	})
	tabsHolder.Parent = topRow
	self.EditorTabsHolder = tabsHolder

	local tabList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	tabList.Parent = tabsHolder

	local function actionButton(text, position, color)
		local button = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			AutoButtonColor = false,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Font = Fonts.Bold,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 13,
			Position = position,
			Size = UDim2.new(0, 82, 0, 34),
			ZIndex = 6,
		})
		glass(button, 10)
		button.Parent = topRow
		makeInteractive(button, button)
		return button
	end

	local addTab = actionButton("+", UDim2.new(1, -278, 0, 0), Theme.SurfaceLight)
	addTab.Size = UDim2.new(0, 34, 0, 34)
	local copyButton = actionButton("Copy", UDim2.new(1, -188, 0, 0), Theme.SurfaceLight)
	local clearButton = actionButton("Clear", UDim2.new(1, -96, 0, 0), Theme.SurfaceLight)
	local execButton = actionButton("Execute", UDim2.new(1, 0, 0, 0), Theme.Accent)

	local editorFrame = create("Frame", {
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		ZIndex = 4,
	})
	glass(editorFrame, 12)
	editorFrame.Parent = holder

	local lineFade = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 2, 1, 0),
		ZIndex = 5,
	})
	lineFade.Parent = editorFrame

	local code = create("TextBox", {
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Fonts.Code,
		MultiLine = true,
		PlaceholderColor3 = Theme.SubText,
		PlaceholderText = "-- premium executor editor",
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 15,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 14, 0, 12),
		Size = UDim2.new(1, -28, 1, -24),
		ZIndex = 6,
	})
	code.Parent = editorFrame
	self.EditorBox = code
	self.EditorTabs = {}

	code:GetPropertyChangedSignal("Text"):Connect(function()
		if self.ActiveEditorTab then
			self.ActiveEditorTab.Content = code.Text
		end
	end)

	addTab.MouseButton1Click:Connect(function()
		local tab = self:_makeEditorTab("Script " .. (#self.EditorTabs + 1), "")
		self:SetEditorTab(tab)
	end)

	clearButton.MouseButton1Click:Connect(function()
		code.Text = ""
		if self.ActiveEditorTab then
			self.ActiveEditorTab.Content = ""
		end
	end)

	copyButton.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(code.Text)
			self.Library:Notify("Copied", "Editor text copied to clipboard.", 2.6)
		else
			self.Library:Notify("Copy Failed", "setclipboard is unavailable.", 2.6)
		end
	end)

	execButton.MouseButton1Click:Connect(function()
		local source = code.Text
		if source:gsub("%s+", "") == "" then
			self.Library:Notify("Executor", "Editor is empty.", 2.5)
			return
		end

		local compiler = loadstring or load
		if not compiler then
			self.Library:Notify("Executor", "loadstring is unavailable.", 2.5)
			return
		end

		local chunk, compileErr = compiler(source)
		if not chunk then
			self.Library:Notify("Compile Error", tostring(compileErr), 4)
			return
		end

		local ok, runtimeErr = pcall(chunk)
		if ok then
			self.Library:Notify("Executed", "Script ran successfully.", 2.5)
		else
			self.Library:Notify("Runtime Error", tostring(runtimeErr), 4)
		end
	end)

	self:_makeEditorTab("Script 1", "")
end

function Window:CreateTab(name, icon)
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = tostring(name or "Tab")
	tab.Icon = tostring(icon or "*")

	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.SurfaceLight,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 46),
		Text = "",
	})
	corner(button, 12)
	button.Parent = self.SidebarTabs

	local fill = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	})
	corner(fill, 12)
	fill.Parent = button

	local iconLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = tab.Icon,
		TextColor3 = Theme.Text,
		TextSize = 14,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		ZIndex = 4,
	})
	iconLabel.Parent = button

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
		Text = tab.Name,
		TextColor3 = Theme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 40, 0, 0),
		Size = UDim2.new(1, -50, 1, 0),
		ZIndex = 4,
	})
	title.Parent = button

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
	page.Parent = self.PageHolder

	local list = create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	list.Parent = page

	makeInteractive(button, button)

	button.MouseButton1Click:Connect(function()
		self:_switchPage(tab)
	end)

	tab.Button = button
	tab.ButtonFill = fill
	tab.ButtonLabel = title
	tab.Page = page
	tab.Container = page

	table.insert(self.Tabs, tab)
	if not self.CurrentTab then
		self:_switchPage(tab)
	end

	return tab
end

function Tab:_base(height)
	local frame = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 0, height),
	})
	glass(frame, 12)
	frame.Parent = self.Container
	return frame
end

function Tab:AddLabel(text)
	local frame = self:_base(42)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
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
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Font = Fonts.Bold,
		Text = tostring(text or "Button"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		Size = UDim2.new(1, -4, 0, 42),
	})
	glass(button, 12)
	button.Parent = self.Container
	makeInteractive(button, button)

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
	self.Window:_setFlag(flag, state)

	local frame = self:_base(48)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
		Text = tostring(text or "Toggle"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -92, 1, 0),
	})
	label.Parent = frame

	local toggle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 52, 0, 26),
		Text = "",
	})
	corner(toggle, 999)
	toggle.Parent = frame

	local knob = create("Frame", {
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		Position = UDim2.new(0, state and 28 or 3, 0, 3),
		Size = UDim2.new(0, 20, 0, 20),
	})
	corner(knob, 999)
	knob.Parent = toggle

	local function setState(value)
		state = value and true or false
		self.Window:_setFlag(flag, state)
		tween(toggle, FAST_TWEEN, {
			BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight,
		}):Play()
		tween(knob, FAST_TWEEN, {
			Position = UDim2.new(0, state and 28 or 3, 0, 3),
		}):Play()
		if callback then
			task.spawn(callback, state)
		end
	end

	toggle.MouseButton1Click:Connect(function()
		setState(not state)
	end)

	self.Window.Setters[flag] = setState
	return {Set = setState, Get = function() return state end}
end

function Tab:AddSlider(text, min, max, default, callback)
	local flag = safeFlag(text)
	local minimum = tonumber(min) or 0
	local maximum = tonumber(max) or 100
	local value = math.clamp(tonumber(default) or minimum, minimum, maximum)
	self.Window:_setFlag(flag, value)

	local frame = self:_base(64)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
		Text = tostring(text or "Slider"),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -86, 0, 18),
	})
	label.Parent = frame

	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = tostring(value),
		TextColor3 = Theme.AccentSoft,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.new(0, 60, 0, 18),
	})
	valueLabel.Parent = frame

	local bar = create("Frame", {
		BackgroundColor3 = Theme.SurfaceLight,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 14, 0, 38),
		Size = UDim2.new(1, -28, 0, 10),
	})
	corner(bar, 999)
	bar.Parent = frame

	local fill = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0),
	})
	corner(fill, 999)
	fill.Parent = bar

	local glow = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 0.38,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
	})
	corner(glow, 999)
	glow.Parent = fill

	local dragging = false

	local function setValue(newValue)
		value = math.clamp(math.floor(newValue + 0.5), minimum, maximum)
		self.Window:_setFlag(flag, value)
		valueLabel.Text = tostring(value)
		tween(fill, FAST_TWEEN, {
			Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0),
		}):Play()
		if callback then
			task.spawn(callback, value)
		end
	end

	local function update(input)
		local pct = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setValue(minimum + ((maximum - minimum) * pct))
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			update(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	self.Window.Setters[flag] = setValue
	return {Set = setValue, Get = function() return value end}
end

function Tab:AddTextbox(text, placeholder, callback)
	local flag = safeFlag(text)
	self.Window:_setFlag(flag, "")

	local frame = self:_base(78)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
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
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Fonts.Main,
		PlaceholderColor3 = Theme.SubText,
		PlaceholderText = tostring(placeholder or "Enter text..."),
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 36),
		Size = UDim2.new(1, -28, 0, 30),
	})
	glass(box, 10)
	box.Parent = frame

	local function setText(value)
		box.Text = tostring(value or "")
		self.Window:_setFlag(flag, box.Text)
		if callback then
			task.spawn(callback, box.Text)
		end
	end

	box.FocusLost:Connect(function()
		setText(box.Text)
	end)

	self.Window.Setters[flag] = setText
	return {Set = setText, Get = function() return box.Text end}
end

function Tab:AddDropdown(text, options, callback)
	local flag = safeFlag(text)
	local items = options or {}
	local selected = items[1] or ""
	self.Window:_setFlag(flag, selected)

	local frame = self:_base(84)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
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
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Font = Fonts.Main,
		Text = selected ~= "" and selected or "Select...",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 36),
		Size = UDim2.new(1, -28, 0, 32),
	})
	glass(main, 10)
	main.Parent = frame
	makeInteractive(main, main)

	local arrow = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = "v",
		TextColor3 = Theme.SubText,
		TextSize = 14,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
	})
	arrow.Parent = main

	local listFrame = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 14, 0, 74),
		Size = UDim2.new(1, -28, 0, 0),
		ZIndex = 14,
	})
	glass(listFrame, 10)
	listFrame.Parent = frame

	local optionsHolder = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 15,
	})
	optionsHolder.Parent = listFrame

	local optionsLayout = create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	optionsLayout.Parent = optionsHolder

	local open = false

	local function setDropdown(value)
		selected = value
		main.Text = tostring(value)
		arrow.Parent = main
		self.Window:_setFlag(flag, selected)
		if callback then
			task.spawn(callback, selected)
		end
	end

	local function rebuild()
		for _, child in ipairs(optionsHolder:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for _, option in ipairs(items) do
			local itemButton = create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Theme.SurfaceLight,
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				Font = Fonts.Main,
				Text = tostring(option),
				TextColor3 = Theme.Text,
				TextSize = 13,
				Size = UDim2.new(1, 0, 0, 28),
				ZIndex = 16,
			})
			glass(itemButton, 8)
			itemButton.Parent = optionsHolder
			makeInteractive(itemButton, itemButton)

			itemButton.MouseButton1Click:Connect(function()
				setDropdown(option)
				open = false
				tween(listFrame, DEFAULT_TWEEN, {Size = UDim2.new(1, -28, 0, 0)}):Play()
			end)
		end
	end

	rebuild()

	main.MouseButton1Click:Connect(function()
		open = not open
		tween(listFrame, DEFAULT_TWEEN, {
			Size = UDim2.new(1, -28, 0, open and math.min(#items * 34 + 6, 140) or 0),
		}):Play()
	end)

	self.Window.Setters[flag] = setDropdown
	return {
		Set = setDropdown,
		Get = function()
			return selected
		end,
		Refresh = function(newOptions)
			items = newOptions or {}
			rebuild()
		end,
	}
end

function Library:CreateWindow(title)
	self:_createGui()
	self:_bindToggle()
	self.Visible = true

	local window = setmetatable({
		Library = self,
		Tabs = {},
		Flags = {},
		Setters = {},
		ConfigName = "premium_executor_config",
	}, Window)

	local root = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 1080, 0, 680),
		ZIndex = 3,
	})
	glass(root, 14)
	shadow(root, 0.42, 100)
	root.Parent = self.ScreenGui
	self.Root = root

	gradient(root, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 19, 23)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(13, 13, 13)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 17, 20)),
	}, 105)

	local animated = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Position = UDim2.new(-0.2, 0, 0.35, 0),
		Rotation = 14,
		Size = UDim2.new(0, 220, 1.4, 0),
		ZIndex = 3,
	})
	corner(animated, 999)
	animated.Parent = root

	task.spawn(function()
		while animated.Parent do
			local move = tween(animated, TweenInfo.new(4.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(1.2, 0, 0.65, 0),
			})
			move:Play()
			move.Completed:Wait()
			if animated.Parent then
				animated.Position = UDim2.new(-0.2, 0, 0.35, 0)
			end
		end
	end)

	local loading = create("Frame", {
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 50,
	})
	loading.Parent = root

	local loadingText = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = "INITIALIZING EXECUTOR",
		TextColor3 = Theme.Text,
		TextSize = 16,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 260, 0, 24),
		ZIndex = 51,
	})
	loadingText.Parent = loading

	local loadingBar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.SurfaceLight,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.56, 0),
		Size = UDim2.new(0, 220, 0, 6),
		ZIndex = 51,
	})
	corner(loadingBar, 999)
	loadingBar.Parent = loading

	local loadingFill = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 52,
	})
	corner(loadingFill, 999)
	loadingFill.Parent = loadingBar

	local topbar = create("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 50),
		ZIndex = 4,
	})
	topbar.Parent = root

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = tostring(title or "Premium Executor"),
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(0, 280, 1, 0),
		ZIndex = 5,
	})
	titleLabel.Parent = topbar

	local controls = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -12, 0, 9),
		Size = UDim2.new(0, 88, 0, 32),
		ZIndex = 5,
	})
	controls.Parent = topbar

	local controlsLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	controlsLayout.Parent = controls

	local function topButton(label, color)
		local button = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			Font = Fonts.Bold,
			Text = label,
			TextColor3 = Theme.Text,
			TextSize = 14,
			Size = UDim2.new(0, 24, 0, 24),
			ZIndex = 6,
		})
		corner(button, 999)
		button.Parent = controls
		makeInteractive(button, button)
		return button
	end

	local minimize = topButton("-", Theme.SurfaceLight)
	local close = topButton("x", Theme.Danger)

	local sidebar = create("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 50),
		Size = UDim2.new(0, 220, 1, -74),
		ZIndex = 4,
	})
	sidebar.Parent = root

	local sidePad = create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	})
	sidePad.Parent = sidebar

	local brand = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 72),
		ZIndex = 5,
	})
	glass(brand, 14)
	brand.Parent = sidebar

	local brandGlow = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 4,
	})
	corner(brandGlow, 14)
	brandGlow.Parent = brand

	local brandIcon = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = "M",
		TextColor3 = Theme.Text,
		TextSize = 26,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(0, 28, 1, 0),
		ZIndex = 6,
	})
	brandIcon.Parent = brand

	local brandTitle = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		Text = "Max Premium",
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 56, 0, 16),
		Size = UDim2.new(1, -66, 0, 18),
		ZIndex = 6,
	})
	brandTitle.Parent = brand

	local brandSub = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
		Text = "High-End Executor UI",
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 56, 0, 36),
		Size = UDim2.new(1, -66, 0, 16),
		ZIndex = 6,
	})
	brandSub.Parent = brand

	local sidebarTabs = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 86),
		ScrollBarThickness = 0,
		Size = UDim2.new(1, 0, 1, -86),
	})
	sidebarTabs.Parent = sidebar

	local sideList = create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	sideList.Parent = sidebarTabs
	window.SidebarTabs = sidebarTabs

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 220, 0, 50),
		Size = UDim2.new(1, -220, 1, -74),
		ZIndex = 4,
	})
	content.Parent = root

	local contentPad = create("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	})
	contentPad.Parent = content

	local contentList = create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	contentList.Parent = content

	local pageWrap = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -272),
		ZIndex = 4,
	})
	glass(pageWrap, 14)
	pageWrap.Parent = content

	local pagePad = create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	pagePad.Parent = pageWrap

	local pageHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 5,
	})
	pageHolder.Parent = pageWrap
	window.PageHolder = pageHolder

	window:_buildEditor(content)

	local statusBar = create("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -24),
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = 4,
	})
	statusBar.Parent = root

	local statusLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Fonts.Main,
		Text = "Ready  |  RightShift to toggle  |  Premium Executor Interface",
		TextColor3 = Theme.SubText,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		ZIndex = 5,
	})
	statusLabel.Parent = statusBar

	close.MouseButton1Click:Connect(function()
		self.Visible = false
		self:_setBlur(false)
		if root then
			root:Destroy()
		end
	end)

	minimize.MouseButton1Click:Connect(function()
		self:Toggle()
	end)

	dragify(topbar, root)
	self:_setBlur(true)

	local loadTween = tween(loadingFill, TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0),
	})
	loadTween:Play()
	loadTween.Completed:Wait()
	local hideLoading = tween(loading, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	hideLoading:Play()
	tween(loadingText, FAST_TWEEN, {TextTransparency = 1}):Play()
	tween(loadingBar, FAST_TWEEN, {BackgroundTransparency = 1}):Play()
	tween(loadingFill, FAST_TWEEN, {BackgroundTransparency = 1}):Play()
	task.delay(0.28, function()
		if loading then
			loading:Destroy()
		end
	end)

	self:Notify("Premium Executor", "Loaded successfully. Press RightShift to toggle.", 3.4)
	return window
end

return setmetatable({}, Library)
