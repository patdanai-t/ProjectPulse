local compatUnpack = table.unpack or unpack
local compatTypeOf = typeof or type
local compatRound = math.round or function(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function safeTableClone(source)
    local copy = {}
    if type(source) ~= "table" then
        return copy
    end
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function safeAssign(target, key, value)
    pcall(function()
        target[key] = value
    end)
end

local function compatDelay(duration, callback, ...)
    if type(callback) ~= "function" then
        return nil
    end

    local args = {...}
    local taskLibrary = rawget(_G, "task")
    if taskLibrary and type(taskLibrary.delay) == "function" then
        return taskLibrary.delay(duration, callback, compatUnpack(args))
    end

    if type(delay) == "function" then
        return delay(duration, function()
            callback(compatUnpack(args))
        end)
    end

    local waitFunction = (taskLibrary and type(taskLibrary.wait) == "function" and taskLibrary.wait) or wait
    return coroutine.wrap(function()
        if type(waitFunction) == "function" then
            waitFunction(duration)
        end
        callback(compatUnpack(args))
    end)()
end

local function findAncestorOfClass(instance, className)
    if not instance then
        return nil
    end

    if type(instance.FindFirstAncestorOfClass) == "function" then
        local ok, result = pcall(instance.FindFirstAncestorOfClass, instance, className)
        if ok and result then
            return result
        end
    end

    local current = instance.Parent
    while current do
        local matches = current.ClassName == className
        if not matches and type(current.IsA) == "function" then
            local ok, result = pcall(current.IsA, current, className)
            matches = ok and result or false
        end
        if matches then
            return current
        end
        current = current.Parent
    end

    return nil
end
local Theme = (function()
local Theme = {}
Theme.__index = Theme

local DEFAULT = {
    Background = Color3.fromRGB(11, 12, 16),
    Surface = Color3.fromRGB(18, 20, 27),
    SurfaceAlt = Color3.fromRGB(23, 26, 35),
    Sidebar = Color3.fromRGB(14, 15, 20),
    Border = Color3.fromRGB(46, 49, 60),
    Text = Color3.fromRGB(240, 242, 247),
    TextMuted = Color3.fromRGB(148, 153, 168),
    Accent = Color3.fromRGB(255, 56, 121),
    AccentDark = Color3.fromRGB(168, 24, 81),
    Success = Color3.fromRGB(80, 220, 160),
    Warning = Color3.fromRGB(255, 191, 89),
    Danger = Color3.fromRGB(255, 94, 94),
    Shadow = Color3.fromRGB(0, 0, 0),
    Overlay = Color3.fromRGB(0, 0, 0),
}

function Theme.new()
    local self = setmetatable({}, Theme)
    self.Values = safeTableClone(DEFAULT)
    return self
end

function Theme:Apply(overrides)
    for key, value in pairs(overrides or {}) do
        self.Values[key] = value
    end
end

function Theme:Get(key)
    return self.Values[key]
end

return Theme

end)()

local Utility = (function()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Utility = {}

function Utility.Create(className, properties)
    local instance = Instance.new(className)

    for key, value in pairs(properties or {}) do
        if key ~= "Children" and key ~= "CornerRadius" and key ~= "Stroke" and key ~= "Gradient" and key ~= "Padding" then
            safeAssign(instance, key, value)
        end
    end

    if properties and properties.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = properties.CornerRadius
        corner.Parent = instance
    end

    if properties and properties.Stroke then
        local stroke = Instance.new("UIStroke")
        for key, value in pairs(properties.Stroke) do
            safeAssign(stroke, key, value)
        end
        stroke.Parent = instance
    end

    if properties and properties.Gradient then
        local gradient = Instance.new("UIGradient")
        for key, value in pairs(properties.Gradient) do
            safeAssign(gradient, key, value)
        end
        gradient.Parent = instance
    end

    if properties and properties.Padding then
        local padding = Instance.new("UIPadding")
        for key, value in pairs(properties.Padding) do
            safeAssign(padding, key, value)
        end
        padding.Parent = instance
    end

    if properties and properties.Children then
        for _, child in ipairs(properties.Children) do
            child.Parent = instance
        end
    end

    return instance
end

function Utility.Tween(instance, info, properties)
    local ok, tween = pcall(function()
        return TweenService:Create(instance, info, properties)
    end)

    if ok and tween then
        tween:Play()
        return tween
    end

    for key, value in pairs(properties or {}) do
        safeAssign(instance, key, value)
    end

    return {
        Completed = {
            Connect = function(_, callback)
                if type(callback) == "function" then
                    callback()
                end
            end,
        },
    }
end

function Utility.FastTween(instance, properties, time, style, direction)
    return Utility.Tween(
        instance,
        TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        properties
    )
end

function Utility.FormatValue(value)
    if math.abs(value - math.floor(value)) < 0.001 then
        return tostring(math.floor(value))
    end

    return string.format("%.2f", value)
end

function Utility.Shadow(parent, transparency)
    return Utility.Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.45,
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        Size = UDim2.new(1, 48, 1, 48),
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = math.max(parent.ZIndex - 1, 0),
        Parent = parent,
    })
end

function Utility.MakeDraggable(handle, root)
    local dragging = false
    local dragStart
    local startPosition
    local connection

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = root.Position

        local changedConnection
        changedConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                changedConnection:Disconnect()
            end
        end)
    end)

    connection = RunService.RenderStepped:Connect(function()
        if not dragging or not dragStart then
            return
        end

        local mousePosition = UserInputService:GetMouseLocation()
        local delta = mousePosition - dragStart
        root.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    local destroyingSignal = root.Destroying
    if destroyingSignal and destroyingSignal.Connect then
        destroyingSignal:Connect(function()
            if connection then
                connection:Disconnect()
            end
        end)
    end
end

function Utility.Ripple(button, theme)
    button.ClipsDescendants = true

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        local ripple = Utility.Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme:Get("Text"),
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(input.Position.X - button.AbsolutePosition.X, input.Position.Y - button.AbsolutePosition.Y),
            Size = UDim2.fromOffset(0, 0),
            ZIndex = button.ZIndex + 1,
            Parent = button,
            CornerRadius = UDim.new(1, 0),
        })

        local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8
        local expand = Utility.FastTween(ripple, {
            Size = UDim2.fromOffset(maxSize, maxSize),
            BackgroundTransparency = 1,
        }, 0.45)

        expand.Completed:Connect(function()
            ripple:Destroy()
        end)
    end)
end

function Utility.Tooltip(target, text, theme)
    local root = findAncestorOfClass(target, "ScreenGui")
    if not root then
        return
    end

    local tooltip = Utility.Create("TextLabel", {
        Name = "Tooltip",
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme:Get("Surface"),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Size = UDim2.fromOffset(0, 0),
        Text = "  " .. text .. "  ",
        TextColor3 = theme:Get("Text"),
        TextSize = 12,
        TextTransparency = 1,
        Visible = false,
        ZIndex = 200,
        Parent = root,
        CornerRadius = UDim.new(0, 8),
        Stroke = {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme:Get("Border"),
            Transparency = 0.25,
            Thickness = 1,
        },
    })

    target.MouseEnter:Connect(function()
        tooltip.Position = UDim2.fromOffset(target.AbsolutePosition.X, target.AbsolutePosition.Y - 28)
        tooltip.Visible = true
        Utility.FastTween(tooltip, {TextTransparency = 0}, 0.12)
    end)

    target.MouseLeave:Connect(function()
        local tween = Utility.FastTween(tooltip, {TextTransparency = 1}, 0.12)
        tween.Completed:Connect(function()
            tooltip.Visible = false
        end)
    end)
end

function Utility.NewListLayout(parent, padding)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding or 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

function Utility.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

return Utility

end)()

local Config = (function()
local HttpService = game:GetService("HttpService")

local Config = {}
Config.__index = Config

function Config.new(folderName)
    local self = setmetatable({}, Config)
    self.FolderName = folderName or "ProjectPulse"
    self.CurrentProfile = "default"
    self.Cache = {}
    return self
end

function Config:_canUseFs()
    return writefile and readfile and isfolder and makefolder and isfile
end

function Config:_profilePath(name)
    return string.format("%s/%s.json", self.FolderName, name)
end

function Config:EnsureFolder()
    if not self:_canUseFs() then
        return false
    end

    if not isfolder(self.FolderName) then
        makefolder(self.FolderName)
    end

    return true
end

function Config:Save(name, payload)
    name = name or self.CurrentProfile
    self.CurrentProfile = name
    self.Cache[name] = payload

    if not self:EnsureFolder() then
        return false
    end

    writefile(self:_profilePath(name), HttpService:JSONEncode(payload))
    return true
end

function Config:Load(name)
    name = name or self.CurrentProfile
    self.CurrentProfile = name

    if self.Cache[name] then
        return self.Cache[name]
    end

    if not self:_canUseFs() then
        return nil
    end

    local path = self:_profilePath(name)
    if not isfile(path) then
        return nil
    end

    local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if success then
        self.Cache[name] = decoded
        return decoded
    end

    return nil
end

function Config:Profiles()
    if not self:_canUseFs() or not isfolder(self.FolderName) or not listfiles then
        return {"default"}
    end

    local profiles = {}
    for _, file in ipairs(listfiles(self.FolderName)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(profiles, name)
        end
    end

    table.sort(profiles)
    return profiles
end

return Config

end)()

local Keybinds = (function()
local UserInputService = game:GetService("UserInputService")

local Keybinds = {}
Keybinds.__index = Keybinds

function Keybinds.new()
    local self = setmetatable({}, Keybinds)
    self.Bindings = {}
    self.LibraryToggle = nil
    self.Connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        for _, binding in pairs(self.Bindings) do
            if binding.KeyCode == input.KeyCode and binding.Callback then
                binding.Callback()
            end
        end

        if self.LibraryToggle and self.LibraryToggle.KeyCode == input.KeyCode then
            self.LibraryToggle.Callback()
        end
    end)
    return self
end

function Keybinds:Bind(id, keyCode, callback)
    self.Bindings[id] = {
        KeyCode = keyCode,
        Callback = callback,
    }
end

function Keybinds:Update(id, keyCode)
    if self.Bindings[id] then
        self.Bindings[id].KeyCode = keyCode
    end
end

function Keybinds:Unbind(id)
    self.Bindings[id] = nil
end

function Keybinds:BindLibraryToggle(keyCode, callback)
    self.LibraryToggle = {
        KeyCode = keyCode,
        Callback = callback,
    }
end

return Keybinds

end)()

local Notifications = (function()
local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(library, screenGui)
    local self = setmetatable({}, Notifications)
    self.Library = library
    self.ScreenGui = screenGui
    self.Container = Utility.Create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.fromOffset(340, 400),
        Parent = screenGui,
    })

    local layout = Utility.NewListLayout(self.Container, 10)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    return self
end

function Notifications:Notify(options)
    local theme = self.Library.Theme
    options = options or {}

    local card = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Surface"),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(320, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Container,
        CornerRadius = UDim.new(0, 12),
        Stroke = {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme:Get("Border"),
            Transparency = 0.15,
            Thickness = 1,
        },
        Padding = {
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 12),
        },
    })

    Utility.Shadow(card, 0.55)
    Utility.NewListLayout(card, 6)

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = options.Title or "ProjectPulse",
        TextColor3 = theme:Get("Text"),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    Utility.Create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Font = Enum.Font.Gotham,
        Text = options.Content or "Notification",
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local bar = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Accent"),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        Parent = card,
        CornerRadius = UDim.new(1, 0),
    })

    card.Position = UDim2.fromOffset(80, 0)
    card.BackgroundTransparency = 1
    Utility.FastTween(card, {Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.04}, 0.26)
    Utility.FastTween(bar, {Size = UDim2.new(0, 0, 0, 3)}, options.Duration or 3, Enum.EasingStyle.Linear)

    compatDelay(options.Duration or 3, function()
        if not card.Parent then
            return
        end

        local tween = Utility.FastTween(card, {Position = UDim2.fromOffset(80, 0), BackgroundTransparency = 1}, 0.22)
        tween.Completed:Connect(function()
            card:Destroy()
        end)
    end)
end

return Notifications

end)()

local Window = (function()
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Window = {}
Window.__index = Window

local function refreshCanvas(frame, layout, padding)
    frame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (padding or 0))
end

local function createIconButton(theme, parent, text)
    local button = Utility.Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme:Get("SurfaceAlt"),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(28, 28),
        Text = "",
        Parent = parent,
        CornerRadius = UDim.new(1, 0),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.25,
            Thickness = 1,
        },
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromScale(1, 1),
        Text = text,
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 12,
        Parent = button,
    })

    Utility.Ripple(button, theme)
    return button
end

function Window.new(library, title, options)
    local self = setmetatable({}, Window)
    self.Library = library
    self.Theme = library.Theme
    self.Title = title
    self.Options = options
    self.Tabs = {}
    self.Components = {}
    self.Registry = {}
    self.State = {
        Hidden = false,
        Minimized = false,
        Maximized = false,
        Blur = options.Blur ~= false,
    }

    self:_build()

    if options.AutoLoad ~= false then
        local config = library.Config:Load(options.Profile or "default")
        if config then
            self:ApplyConfig(config)
        end
    end

    return self
end

function Window:_build()
    local theme = self.Theme

    if self.State.Blur then
        local blur = Lighting:FindFirstChild("ProjectPulseBlur") or Instance.new("BlurEffect")
        blur.Name = "ProjectPulseBlur"
        blur.Size = 0
        blur.Parent = Lighting
        self.BlurEffect = blur
    end

    self.Root = Utility.Create("Frame", {
        Name = "WindowRoot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(980, 640),
        Parent = self.Library.ScreenGui,
    })

    self.Main = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Background"),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = self.Root,
        CornerRadius = UDim.new(0, 18),
        Stroke = {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme:Get("Border"),
            Transparency = 0.1,
            Thickness = 1,
        },
        Gradient = {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme:Get("Background")),
                ColorSequenceKeypoint.new(1, theme:Get("Surface")),
            }),
            Rotation = 90,
        },
    })
    Utility.Shadow(self.Main, 0.5)

    self.Topbar = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 0, 52),
        Parent = self.Main,
    })

    self.Sidebar = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Sidebar"),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 74),
        Size = UDim2.new(0, 210, 1, -88),
        Parent = self.Main,
        CornerRadius = UDim.new(0, 16),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.16,
            Thickness = 1,
        },
    })

    self.ContentShell = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Surface"),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 236, 0, 74),
        Size = UDim2.new(1, -250, 1, -88),
        Parent = self.Main,
        CornerRadius = UDim.new(0, 16),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.16,
            Thickness = 1,
        },
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Text = self.Title,
        TextColor3 = theme:Get("Text"),
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Topbar,
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.fromOffset(10, 24),
        Size = UDim2.new(0.5, 0, 0, 20),
        Text = "Premium Roblox interface toolkit",
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Topbar,
    })

    local controls = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(118, 32),
        Parent = self.Topbar,
    })
    local controlsLayout = Utility.NewListLayout(controls, 8)
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    self.MinimizeButton = createIconButton(theme, controls, "_")
    self.MaximizeButton = createIconButton(theme, controls, "[]")
    self.CloseButton = createIconButton(theme, controls, "X")

    self.SearchBox = Utility.Create("TextBox", {
        BackgroundColor3 = theme:Get("SurfaceAlt"),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = theme:Get("TextMuted"),
        PlaceholderText = "Search controls...",
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.new(1, -28, 0, 38),
        Text = "",
        TextColor3 = theme:Get("Text"),
        TextSize = 13,
        Parent = self.Sidebar,
        CornerRadius = UDim.new(0, 10),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.2,
            Thickness = 1,
        },
        Padding = {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        },
    })

    self.TabButtonHolder = Utility.Create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(10, 62),
        ScrollBarImageColor3 = theme:Get("Accent"),
        ScrollBarThickness = 3,
        Size = UDim2.new(1, -20, 1, -124),
        Parent = self.Sidebar,
    })
    self.TabButtonLayout = Utility.NewListLayout(self.TabButtonHolder, 8)
    self.TabButtonLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        refreshCanvas(self.TabButtonHolder, self.TabButtonLayout, 8)
    end)

    self.SidebarFooter = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.new(1, -24, 0, 42),
        Parent = self.Sidebar,
    })

    Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Accent"),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 17),
        Size = UDim2.fromOffset(8, 8),
        Parent = self.SidebarFooter,
        CornerRadius = UDim.new(1, 0),
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.fromOffset(18, 4),
        Size = UDim2.new(1, -18, 0, 16),
        Text = "RightShift",
        TextColor3 = theme:Get("Text"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SidebarFooter,
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.fromOffset(18, 20),
        Size = UDim2.new(1, -18, 0, 16),
        Text = "Toggle library visibility",
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SidebarFooter,
    })

    self.ContentPages = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = self.ContentShell,
    })

    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:Filter(self.SearchBox.Text)
    end)

    self.MinimizeButton.MouseButton1Click:Connect(function()
        self:SetMinimized(not self.State.Minimized)
    end)
    self.MaximizeButton.MouseButton1Click:Connect(function()
        self:SetMaximized(not self.State.Maximized)
    end)
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    Utility.MakeDraggable(self.Topbar, self.Root)
    self:Open()
end

function Window:Open()
    self.Root.Size = UDim2.fromOffset(920, 580)
    self.Main.BackgroundTransparency = 1
    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = 16}, 0.3)
    end
    Utility.FastTween(self.Root, {Size = UDim2.fromOffset(980, 640)}, 0.28)
    Utility.FastTween(self.Main, {BackgroundTransparency = 0}, 0.24)
end

function Window:SetVisible(state)
    self.State.Hidden = not state
    self.Root.Visible = true

    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = state and 16 or 0}, 0.24)
    end

    local tween = Utility.FastTween(self.Main, {BackgroundTransparency = state and 0 or 1}, 0.2)
    Utility.FastTween(self.Root, {Size = state and UDim2.fromOffset(980, 640) or UDim2.fromOffset(920, 580)}, 0.22)

    if not state then
        tween.Completed:Connect(function()
            if self.State.Hidden and self.Root then
                self.Root.Visible = false
            end
        end)
    end
end

function Window:SetMinimized(state)
    self.State.Minimized = state
    self.Sidebar.Visible = not state
    self.ContentShell.Visible = not state
    Utility.FastTween(self.Root, {Size = state and UDim2.fromOffset(980, 78) or UDim2.fromOffset(980, 640)}, 0.22)
end

function Window:SetMaximized(state)
    self.State.Maximized = state
    Utility.FastTween(self.Root, {Size = state and UDim2.fromScale(0.88, 0.86) or UDim2.fromOffset(980, 640)}, 0.24)
end

function Window:RefreshTheme()
    local theme = self.Theme
    self.Main.BackgroundColor3 = theme:Get("Background")
    self.Sidebar.BackgroundColor3 = theme:Get("Sidebar")
    self.ContentShell.BackgroundColor3 = theme:Get("Surface")
    self.SearchBox.BackgroundColor3 = theme:Get("SurfaceAlt")
    self.SearchBox.TextColor3 = theme:Get("Text")
    self.SearchBox.PlaceholderColor3 = theme:Get("TextMuted")

    for _, tab in ipairs(self.Tabs) do
        if tab.Selected then
            tab.Button.BackgroundColor3 = theme:Get("AccentDark")
            tab.IconLabel.TextColor3 = theme:Get("Text")
            tab.NameLabel.TextColor3 = theme:Get("Text")
        else
            tab.Button.BackgroundColor3 = theme:Get("SurfaceAlt")
            tab.IconLabel.TextColor3 = theme:Get("Accent")
            tab.NameLabel.TextColor3 = theme:Get("TextMuted")
        end
    end
end

function Window:_registerSearch(entry)
    table.insert(self.Registry, entry)
end

function Window:Filter(query)
    query = string.lower(query or "")
    for _, entry in ipairs(self.Registry) do
        local matches = query == "" or string.find(string.lower(entry.Text), query, 1, true)
        entry.Frame.Visible = matches
    end
end

function Window:Serialize()
    local output = {
        Profile = self.Library.Config.CurrentProfile,
        Components = {},
    }

    for id, component in pairs(self.Components) do
        output.Components[id] = component:GetSerialized()
    end

    return output
end

function Window:ApplyConfig(config)
    if not config or not config.Components then
        return
    end

    for id, state in pairs(config.Components) do
        local component = self.Components[id]
        if component and component.Set then
            local value = state.Value
            if component.Kind == "Keybind" and compatTypeOf(value) == "string" then
                value = Enum.KeyCode[value] or component.Value
            elseif component.Kind == "ColorPicker" and compatTypeOf(value) == "table" then
                value = Color3.new(value[1], value[2], value[3])
            end
            component:Set(value, true)
        end
    end
end

function Window:SaveConfig(profile)
    return self.Library.Config:Save(profile, self:Serialize())
end

function Window:LoadConfig(profile)
    local config = self.Library.Config:Load(profile)
    self:ApplyConfig(config)
    return config
end

function Window:CreateTab(name, icon)
    local theme = self.Theme
    local tab = {
        Window = self,
        Name = name,
        Icon = icon or "•",
        Sections = {},
        Selected = false,
    }

    tab.Button = Utility.Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme:Get("SurfaceAlt"),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 42),
        Text = "",
        Parent = self.TabButtonHolder,
        CornerRadius = UDim.new(0, 12),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.35,
            Thickness = 1,
        },
    })

    tab.IconLabel = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.fromOffset(20, 42),
        Text = tab.Icon,
        TextColor3 = theme:Get("Accent"),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Button,
    })

    tab.NameLabel = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Text = name,
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Button,
    })

    Utility.Ripple(tab.Button, theme)

    tab.Page = Utility.Create("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = theme:Get("Accent"),
        ScrollBarThickness = 4,
        Size = UDim2.new(1, -28, 1, -28),
        Position = UDim2.fromOffset(14, 14),
        Visible = false,
        Parent = self.ContentPages,
    })
    local pageLayout = Utility.NewListLayout(tab.Page, 14)
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        refreshCanvas(tab.Page, pageLayout, 24)
    end)

    function tab:Select()
        for _, other in ipairs(self.Window.Tabs) do
            other.Selected = false
            other.Page.Visible = false
            other.Button.BackgroundColor3 = theme:Get("SurfaceAlt")
            other.IconLabel.TextColor3 = theme:Get("Accent")
            other.NameLabel.TextColor3 = theme:Get("TextMuted")
        end

        self.Selected = true
        self.Page.Visible = true
        self.Button.BackgroundColor3 = theme:Get("AccentDark")
        self.IconLabel.TextColor3 = theme:Get("Text")
        self.NameLabel.TextColor3 = theme:Get("Text")
    end

    function tab:CreateSection(sectionName)
        local section = {
            Tab = self,
            Name = sectionName,
            Elements = {},
        }

        section.Frame = Utility.Create("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = theme:Get("SurfaceAlt"),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = self.Page,
            CornerRadius = UDim.new(0, 14),
            Stroke = {
                Color = theme:Get("Border"),
                Transparency = 0.18,
                Thickness = 1,
            },
            Padding = {
                PaddingBottom = UDim.new(0, 14),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
                PaddingTop = UDim.new(0, 14),
            },
        })

        Utility.Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(1, 0, 0, 18),
            Text = sectionName,
            TextColor3 = theme:Get("Text"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = section.Frame,
        })

        Utility.Create("Frame", {
            BackgroundColor3 = theme:Get("Border"),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Parent = section.Frame,
        })

        Utility.NewListLayout(section.Frame, 12)

        local function registerComponent(component)
            section.Elements[component.Id] = component
            section.Tab.Window.Components[component.Id] = component
            section.Tab.Window:_registerSearch({
                Text = component.SearchText,
                Frame = component.Frame,
            })
            return component
        end

        local function baseElement(kind, labelText, callback, defaultValue)
            local id = string.format("%s_%s_%s", self.Name, sectionName, labelText):gsub("%W", "_")
            local holder = Utility.Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 48),
                Parent = section.Frame,
            })

            local label = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Position = UDim2.fromOffset(0, 2),
                Size = UDim2.new(0.6, 0, 0, 16),
                Text = labelText,
                TextColor3 = theme:Get("Text"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            return {
                Id = id,
                Kind = kind,
                Label = label,
                Frame = holder,
                SearchText = labelText,
                Callback = callback,
                Value = defaultValue,
                Set = nil,
            }
        end

        function section:CreateLabel(title, text)
            local component = baseElement("Label", title, nil, text)
            component.Frame.Size = UDim2.new(1, 0, 0, 62)
            component.Label.Size = UDim2.new(1, 0, 0, 16)

            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.new(1, 0, 0, 34),
                Text = text,
                TextColor3 = theme:Get("TextMuted"),
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = component.Frame,
            })

            function component:GetSerialized()
                return {Value = self.Value}
            end

            return registerComponent(component)
        end

        function section:CreateParagraph(title, text)
            return self:CreateLabel(title, text)
        end

        function section:CreateButton(labelText, callback, tooltip)
            local component = baseElement("Button", labelText, callback, false)
            local button = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = theme:Get("AccentDark"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -150, 0, 0),
                Size = UDim2.fromOffset(150, 38),
                Text = "Execute",
                Font = Enum.Font.GothamBold,
                TextColor3 = theme:Get("Text"),
                TextSize = 13,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 10),
            })
            Utility.Ripple(button, theme)

            button.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end)

            if tooltip then
                Utility.Tooltip(button, tooltip, theme)
            end

            function component:GetSerialized()
                return {Value = false}
            end

            return registerComponent(component)
        end

        function section:CreateToggle(labelText, callback, defaultValue, tooltip)
            local component = baseElement("Toggle", labelText, callback, defaultValue or false)
            local pill = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = component.Value and theme:Get("Accent") or theme:Get("Border"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -58, 0, 6),
                Size = UDim2.fromOffset(58, 26),
                Text = "",
                Parent = component.Frame,
                CornerRadius = UDim.new(1, 0),
            })
            local knob = Utility.Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Position = component.Value and UDim2.fromOffset(34, 3) or UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(20, 20),
                Parent = pill,
                CornerRadius = UDim.new(1, 0),
            })

            local function apply(state, silent)
                component.Value = state
                Utility.FastTween(pill, {BackgroundColor3 = state and theme:Get("Accent") or theme:Get("Border")}, 0.18)
                Utility.FastTween(knob, {Position = state and UDim2.fromOffset(34, 3) or UDim2.fromOffset(3, 3)}, 0.18)
                if callback and not silent then
                    callback(state)
                end
            end

            component.Set = apply
            pill.MouseButton1Click:Connect(function()
                apply(not component.Value)
            end)

            if tooltip then
                Utility.Tooltip(pill, tooltip, theme)
            end

            function component:GetSerialized()
                return {Value = self.Value}
            end

            return registerComponent(component)
        end

        function section:CreateSlider(labelText, options, callback)
            options = options or {}
            local min = options.Min or 0
            local max = options.Max or 100
            local component = baseElement("Slider", labelText, callback, options.Default or min)
            component.Frame.Size = UDim2.new(1, 0, 0, 60)

            local valueLabel = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Position = UDim2.new(1, -64, 0, 0),
                Size = UDim2.fromOffset(64, 16),
                Text = Utility.FormatValue(component.Value),
                TextColor3 = theme:Get("Accent"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = component.Frame,
            })

            local track = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Border"),
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(0, 30),
                Size = UDim2.new(1, 0, 0, 8),
                Parent = component.Frame,
                CornerRadius = UDim.new(1, 0),
            })
            local fill = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Accent"),
                BorderSizePixel = 0,
                Size = UDim2.new((component.Value - min) / (max - min), 0, 1, 0),
                Parent = track,
                CornerRadius = UDim.new(1, 0),
            })

            local dragging = false
            local function setFromRatio(ratio, silent)
                ratio = Utility.Clamp(ratio, 0, 1)
                local value = min + ((max - min) * ratio)
                if options.Rounding then
                    local factor = 10 ^ options.Rounding
                    value = compatRound(value * factor) / factor
                else
                    value = math.floor(value + 0.5)
                end
                component.Value = value
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                valueLabel.Text = Utility.FormatValue(value)
                if callback and not silent then
                    callback(value)
                end
            end

            component.Set = function(value, silent)
                setFromRatio((value - min) / (max - min), silent)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setFromRatio((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromRatio((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            function component:GetSerialized()
                return {Value = self.Value}
            end

            return registerComponent(component)
        end

        local function buildDropdown(labelText, list, callback, multi)
            list = list or {}
            local defaultValue = multi and {} or (list[1] or "")
            local component = baseElement(multi and "MultiDropdown" or "Dropdown", labelText, callback, defaultValue)
            local button = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -220, 0, 0),
                Size = UDim2.fromOffset(220, 38),
                Text = "",
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 10),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.25,
                    Thickness = 1,
                },
            })
            local textLabel = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -36, 1, 0),
                Text = multi and "Select..." or tostring(component.Value),
                TextColor3 = theme:Get("Text"),
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = button,
            })
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Position = UDim2.new(1, -20, 0, 0),
                Size = UDim2.fromOffset(16, 38),
                Text = "v",
                TextColor3 = theme:Get("TextMuted"),
                TextSize = 12,
                Parent = button,
            })

            local menu = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 6),
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = button,
                CornerRadius = UDim.new(0, 10),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.2,
                    Thickness = 1,
                },
            })
            local menuList = Utility.Create("ScrollingFrame", {
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.fromOffset(0, 0),
                ScrollBarThickness = 3,
                Size = UDim2.new(1, -8, 1, -8),
                Position = UDim2.fromOffset(4, 4),
                Parent = menu,
            })
            Utility.NewListLayout(menuList, 4)

            local open = false
            local selected = multi and {} or component.Value

            local function syncLabel()
                if multi then
                    local values = {}
                    for _, item in ipairs(list) do
                        if selected[item] then
                            table.insert(values, item)
                        end
                    end
                    component.Value = values
                    textLabel.Text = #values > 0 and table.concat(values, ", ") or "Select..."
                else
                    component.Value = selected
                    textLabel.Text = tostring(selected)
                end
            end

            local function toggle(state)
                open = state
                menu.Visible = true
                Utility.FastTween(menu, {Size = state and UDim2.new(1, 0, 0, math.min(#list * 30 + 8, 154)) or UDim2.new(1, 0, 0, 0)}, 0.16)
                if not state then
                    compatDelay(0.17, function()
                        if not open then
                            menu.Visible = false
                        end
                    end)
                end
            end

            for _, value in ipairs(list) do
                local option = Utility.Create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme:Get("SurfaceAlt"),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 26),
                    Text = value,
                    Font = Enum.Font.Gotham,
                    TextColor3 = theme:Get("Text"),
                    TextSize = 12,
                    Parent = menuList,
                    CornerRadius = UDim.new(0, 8),
                })

                option.MouseButton1Click:Connect(function()
                    if multi then
                        if selected[value] then
                            selected[value] = nil
                        else
                            selected[value] = true
                        end
                    else
                        selected = value
                        toggle(false)
                    end
                    syncLabel()
                    if callback then
                        callback(component.Value)
                    end
                end)
            end

            button.MouseButton1Click:Connect(function()
                toggle(not open)
            end)

            component.Set = function(value, silent)
                if multi then
                    selected = {}
                    for _, item in ipairs(value or {}) do
                        selected[item] = true
                    end
                else
                    selected = value
                end
                syncLabel()
                if callback and not silent then
                    callback(component.Value)
                end
            end

            syncLabel()

            function component:GetSerialized()
                return {Value = self.Value}
            end

            return registerComponent(component)
        end

        function section:CreateDropdown(labelText, list, callback)
            return buildDropdown(labelText, list, callback, false)
        end

        function section:CreateMultiDropdown(labelText, list, callback)
            return buildDropdown(labelText, list, callback, true)
        end

        function section:CreateTextbox(labelText, placeholder, callback)
            local component = baseElement("Textbox", labelText, callback, "")
            local box = Utility.Create("TextBox", {
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Font = Enum.Font.Gotham,
                PlaceholderColor3 = theme:Get("TextMuted"),
                PlaceholderText = placeholder or "Enter text",
                Position = UDim2.new(1, -220, 0, 0),
                Size = UDim2.fromOffset(220, 38),
                Text = "",
                TextColor3 = theme:Get("Text"),
                TextSize = 12,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 10),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.25,
                    Thickness = 1,
                },
                Padding = {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                },
            })

            box.FocusLost:Connect(function(enterPressed)
                component.Value = box.Text
                if callback then
                    callback(box.Text, enterPressed)
                end
            end)

            component.Set = function(value, silent)
                component.Value = value
                box.Text = value or ""
                if callback and not silent then
                    callback(component.Value, false)
                end
            end

            function component:GetSerialized()
                return {Value = self.Value}
            end

            return registerComponent(component)
        end

        function section:CreateKeybind(labelText, defaultKey, callback)
            local component = baseElement("Keybind", labelText, callback, defaultKey or Enum.KeyCode.E)
            local bindId = component.Id .. "_bind"
            local button = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -120, 0, 0),
                Size = UDim2.fromOffset(120, 38),
                Text = component.Value.Name,
                Font = Enum.Font.GothamBold,
                TextColor3 = theme:Get("Text"),
                TextSize = 12,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 10),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.25,
                    Thickness = 1,
                },
            })

            self.Tab.Window.Library.Keybinds:Bind(bindId, component.Value, function()
                if callback then
                    callback(component.Value)
                end
            end)

            local picking = false
            button.MouseButton1Click:Connect(function()
                if picking then
                    return
                end
                picking = true
                button.Text = "..."
                local connection
                connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end
                    component.Value = input.KeyCode
                    button.Text = component.Value.Name
                    self.Tab.Window.Library.Keybinds:Update(bindId, component.Value)
                    picking = false
                    connection:Disconnect()
                end)
            end)

            component.Set = function(value)
                component.Value = value
                button.Text = value.Name
                self.Tab.Window.Library.Keybinds:Update(bindId, value)
            end

            function component:GetSerialized()
                return {Value = self.Value.Name}
            end

            return registerComponent(component)
        end

        function section:CreateColorPicker(labelText, defaultColor, callback)
            local component = baseElement("ColorPicker", labelText, callback, defaultColor or theme:Get("Accent"))
            local preview = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = component.Value,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -58, 0, 0),
                Size = UDim2.fromOffset(58, 38),
                Text = "",
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 10),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.25,
                    Thickness = 1,
                },
            })

            local popup = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -230, 1, 6),
                Size = UDim2.fromOffset(230, 0),
                Visible = false,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 12),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.2,
                    Thickness = 1,
                },
                Padding = {
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 10),
                },
            })
            Utility.NewListLayout(popup, 8)

            local hue, sat, val = Color3.toHSV(component.Value)
            local colorArea = Utility.Create("ImageButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                BorderSizePixel = 0,
                Image = "rbxassetid://4155801252",
                Size = UDim2.fromOffset(210, 120),
                Parent = popup,
                CornerRadius = UDim.new(0, 10),
            })
            local colorCursor = Utility.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(sat, 0, 1 - val, 0),
                Size = UDim2.fromOffset(10, 10),
                Parent = colorArea,
                CornerRadius = UDim.new(1, 0),
                Stroke = {
                    Color = Color3.new(0, 0, 0),
                    Transparency = 0,
                    Thickness = 1,
                },
            })
            local hueBar = Utility.Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(210, 12),
                Parent = popup,
                CornerRadius = UDim.new(1, 0),
                Gradient = {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                    }),
                },
            })
            local hueCursor = Utility.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(hue, 0, 0.5, 0),
                Size = UDim2.fromOffset(8, 16),
                Parent = hueBar,
                CornerRadius = UDim.new(0, 4),
            })

            local open = false
            local draggingArea = false
            local draggingHue = false

            local function syncColor(silent)
                local color = Color3.fromHSV(hue, sat, val)
                component.Value = color
                preview.BackgroundColor3 = color
                colorArea.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                if callback and not silent then
                    callback(color)
                end
            end

            local function setOpen(state)
                open = state
                popup.Visible = true
                Utility.FastTween(popup, {Size = state and UDim2.fromOffset(230, 178) or UDim2.fromOffset(230, 0)}, 0.18)
                if not state then
                    compatDelay(0.19, function()
                        if not open then
                            popup.Visible = false
                        end
                    end)
                end
            end

            colorArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingArea = true
                end
            end)
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingHue = true
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                    return
                end
                if draggingArea then
                    sat = Utility.Clamp((input.Position.X - colorArea.AbsolutePosition.X) / colorArea.AbsoluteSize.X, 0, 1)
                    val = 1 - Utility.Clamp((input.Position.Y - colorArea.AbsolutePosition.Y) / colorArea.AbsoluteSize.Y, 0, 1)
                    colorCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                    syncColor()
                elseif draggingHue then
                    hue = Utility.Clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                    hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
                    syncColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingArea = false
                    draggingHue = false
                end
            end)
            preview.MouseButton1Click:Connect(function()
                setOpen(not open)
            end)

            component.Set = function(value, silent)
                hue, sat, val = Color3.toHSV(value)
                hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
                colorCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                syncColor(silent)
            end

            syncColor(true)

            function component:GetSerialized()
                return {Value = {self.Value.R, self.Value.G, self.Value.B}}
            end

            return registerComponent(component)
        end

        table.insert(self.Sections, section)
        return section
    end

    tab.Button.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:Select()
    end

    return tab
end

function Window:Destroy()
    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = 0}, 0.2)
    end
    if self.Root then
        self.Root:Destroy()
    end
end

return Window

end)()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library

local function createGuiParent()
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

    if playerGui then
        return playerGui
    end

    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    return game:GetService("CoreGui")
end

function Library.new()
    local self = setmetatable({}, Library)

    self.Theme = Theme.new()
    self.Utility = Utility
    self.Config = Config.new("ProjectPulse")
    self.Keybinds = Keybinds.new()
    self.GuiParent = createGuiParent()
    self.Windows = {}
    self.ScreenGui = nil
    self.Notifications = nil

    return self
end

function Library:_ensureGui()
    if self.ScreenGui then
        return
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProjectPulse"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = self.GuiParent

    self.ScreenGui = screenGui
    local notificationOk, notificationObject = pcall(Notifications.new, self, screenGui)
    if notificationOk and type(notificationObject) == "table" then
        self.Notifications = notificationObject
    else
        self.Notifications = {
            Notify = function()
            end,
        }
    end
    self.Keybinds:BindLibraryToggle(Enum.KeyCode.RightShift, function()
        for _, window in ipairs(self.Windows) do
            window:SetVisible(window.State.Hidden)
        end
    end)
end

function Library:CreateWindow(title, options)
    self:_ensureGui()

    local ok, window = pcall(Window.new, self, title or "ProjectPulse", options or {})
    if ok and type(window) == "table" then
        table.insert(self.Windows, window)
        return window
    end

    return {
        State = {
            Hidden = false,
            Minimized = false,
            Maximized = false,
        },
        CreateTab = function()
            return {
                CreateSection = function()
                    return {}
                end,
            }
        end,
        SetVisible = function()
        end,
        RefreshTheme = function()
        end,
        SaveConfig = function()
            return false
        end,
        LoadConfig = function()
            return nil
        end,
        Destroy = function()
        end,
    }
end

function Library:Notify(options)
    self:_ensureGui()
    if self.Notifications and type(self.Notifications.Notify) == "function" then
        pcall(self.Notifications.Notify, self.Notifications, options)
    end
end

function Library:SetTheme(overrides)
    self.Theme:Apply(overrides)

    for _, window in ipairs(self.Windows) do
        if window and type(window.RefreshTheme) == "function" then
            pcall(window.RefreshTheme, window)
        end
    end
end

function Library:SaveProfile(name, payload)
    self.Config:Save(name, payload)
end

function Library:LoadProfile(name)
    return self.Config:Load(name)
end

function Library:Encode(value)
    return HttpService:JSONEncode(value)
end

function Library:Decode(value)
    return HttpService:JSONDecode(value)
end

local function createLibrary()
    local ok, libraryObject = pcall(Library.new)
    if ok and type(libraryObject) == "table" then
        return libraryObject
    end

    local fallback = {
        Theme = Theme.new(),
        Utility = Utility,
        Config = Config.new("ProjectPulse"),
        Keybinds = Keybinds.new(),
        Windows = {},
    }

    setmetatable(fallback, {__index = Library})
    return fallback
end

return createLibrary()


