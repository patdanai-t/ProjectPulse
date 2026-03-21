--[[
ProjectPulse - Simple Example

local Library = loadstring(game:HttpGet("URL"))()
local UI = Library.new()
local Window = UI:Window("My UI")

local Main = Window:Tab("Main")

Main:Button("Click", function()
    print("Hello")
end)

Main:Toggle("Auto Farm", false, function(value)
    print(value)
end)

Main:Slider("Speed", 0, 100, 25, function(value)
    print(value)
end)
]]
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
    Background = Color3.fromRGB(29, 29, 31),
    Surface = Color3.fromRGB(35, 35, 37),
    SurfaceAlt = Color3.fromRGB(42, 42, 45),
    Sidebar = Color3.fromRGB(32, 32, 34),
    Border = Color3.fromRGB(58, 58, 61),
    Text = Color3.fromRGB(235, 235, 236),
    TextMuted = Color3.fromRGB(156, 156, 160),
    Accent = Color3.fromRGB(255, 32, 93),
    AccentDark = Color3.fromRGB(185, 24, 72),
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
        ImageTransparency = transparency or 0.7,
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        Size = UDim2.new(1, 30, 1, 30),
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = math.max(parent.ZIndex - 1, 0),
        Parent = parent,
    })
end

function Utility.PointInBounds(point, gui)
    local position = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

function Utility.IsInteractiveObject(object)
    return object:IsA("TextButton")
        or object:IsA("ImageButton")
        or object:IsA("TextBox")
        or object:IsA("ScrollingFrame")
end

function Utility.HasInteractiveDescendantAt(root, point)
    local screenGui = findAncestorOfClass(root, "ScreenGui")
    if screenGui and type(screenGui.GetGuiObjectsAtPosition) == "function" then
        local ok, objects = pcall(screenGui.GetGuiObjectsAtPosition, screenGui, point.X, point.Y)
        if ok and objects then
            for _, object in ipairs(objects) do
                if Utility.IsInteractiveObject(object) then
                    return true
                end
            end
            return false
        end
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if Utility.IsInteractiveObject(descendant) and descendant.Visible and Utility.PointInBounds(point, descendant) then
            return true
        end
    end

    return false
end

function Utility.MakeDraggable(handle, root)
    local dragging = false
    local dragStart
    local startPosition
    local dragConnection
    local endConnection

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        local mousePosition = UserInputService:GetMouseLocation()
        if Utility.HasInteractiveDescendantAt(root, mousePosition) then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = root.Position

        local changedConnection
        changedConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if changedConnection then
                    changedConnection:Disconnect()
                end
            end
        end)
    end)

    dragConnection = UserInputService.InputChanged:Connect(function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart
        root.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    endConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local destroyingSignal = root.Destroying
    if destroyingSignal and destroyingSignal.Connect then
        destroyingSignal:Connect(function()
            if dragConnection then
                dragConnection:Disconnect()
            end
            if endConnection then
                endConnection:Disconnect()
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
        TextSize = 10,
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
        CornerRadius = UDim.new(0, 4),
        Stroke = {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme:Get("Border"),
            Transparency = 0.15,
            Thickness = 1,
        },
        Padding = {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 6),
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
        TextSize = 11,
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
        TextSize = 10,
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

local function createIconButton(theme, parent, color, glyph)
    local button = Utility.Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(14, 14),
        Text = "",
        Parent = parent,
        CornerRadius = UDim.new(1, 0),
        Stroke = {
            Color = color:Lerp(Color3.new(0, 0, 0), 0.35),
            Transparency = 0.42,
            Thickness = 1,
        },
    })

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local icon = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromScale(1, 1),
        Text = glyph,
        TextColor3 = Color3.fromRGB(35, 35, 35),
        TextSize = 9,
        TextTransparency = 0.35,
        Parent = button,
    })

    button.MouseEnter:Connect(function()
        Utility.FastTween(scale, {Scale = 1.12}, 0.14, Enum.EasingStyle.Quad)
        Utility.FastTween(button, {
            BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.12),
        }, 0.14)
        Utility.FastTween(icon, {TextTransparency = 0.05}, 0.14)
    end)

    button.MouseLeave:Connect(function()
        Utility.FastTween(scale, {Scale = 1}, 0.14, Enum.EasingStyle.Quad)
        Utility.FastTween(button, {
            BackgroundColor3 = color,
        }, 0.14)
        Utility.FastTween(icon, {TextTransparency = 0.35}, 0.14)
    end)

    button.MouseButton1Down:Connect(function()
        Utility.FastTween(scale, {Scale = 0.9}, 0.08, Enum.EasingStyle.Quad)
    end)

    button.MouseButton1Up:Connect(function()
        Utility.FastTween(scale, {Scale = 1.08}, 0.1, Enum.EasingStyle.Quad)
    end)

    return button
end

local function createTopbarNavButton(theme, parent, glyph)
    local button = Utility.Create("TextButton", {
        BackgroundColor3 = theme:Get("Surface"),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(18, 18),
        Text = "",
        Parent = parent,
        CornerRadius = UDim.new(0, 5),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.72,
            Thickness = 1,
        },
    })

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local icon = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromScale(1, 1),
        Text = glyph,
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 10,
        Parent = button,
    })
    button.IconLabel = icon

    button.MouseEnter:Connect(function()
        Utility.FastTween(scale, {Scale = 1.08}, 0.12, Enum.EasingStyle.Quad)
        Utility.FastTween(button, {BackgroundColor3 = theme:Get("SurfaceAlt")}, 0.12)
        Utility.FastTween(icon, {TextColor3 = theme:Get("Text")}, 0.12)
    end)

    button.MouseLeave:Connect(function()
        Utility.FastTween(scale, {Scale = 1}, 0.12, Enum.EasingStyle.Quad)
        Utility.FastTween(button, {BackgroundColor3 = theme:Get("Surface")}, 0.12)
        Utility.FastTween(icon, {TextColor3 = theme:Get("TextMuted")}, 0.12)
    end)

    button.MouseButton1Down:Connect(function()
        Utility.FastTween(scale, {Scale = 0.93}, 0.08, Enum.EasingStyle.Quad)
    end)

    button.MouseButton1Up:Connect(function()
        Utility.FastTween(scale, {Scale = 1.04}, 0.08, Enum.EasingStyle.Quad)
    end)

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
        BlurAfterClose = options.BlurAfterClose == true,
        Closed = false,
        ReopenWithoutBlur = false,
        Destroyed = false,
    }

    self.DefaultSize = UDim2.fromOffset(816, 492)
    self.MinimizedSize = UDim2.fromOffset(816, 42)
    self.MaximizedSize = UDim2.fromScale(0.78, 0.72)

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
        Size = self.DefaultSize,
        Parent = self.Library.ScreenGui,
    })

    self.Main = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Background"),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = self.Root,
        CornerRadius = UDim.new(0, 14),
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
    Utility.Shadow(self.Main, 0.82)

    self.Topbar = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("SurfaceAlt"),
        BackgroundTransparency = 0.04,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 42),
        Parent = self.Main,
        CornerRadius = UDim.new(0, 14),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.72,
            Thickness = 1,
        },
        Padding = {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        },
    })

    self.Sidebar = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Sidebar"),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 42),
        Size = UDim2.new(0, 138, 1, -42),
        Parent = self.Main,
        CornerRadius = UDim.new(0, 0),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.7,
            Thickness = 1,
        },
    })

    self.ContentShell = Utility.Create("Frame", {
        BackgroundColor3 = theme:Get("Surface"),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 138, 0, 42),
        Size = UDim2.new(1, -138, 1, -42),
        Parent = self.Main,
        CornerRadius = UDim.new(0, 0),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.85,
            Thickness = 1,
        },
    })

    local titleGroup = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -322, 1, 0),
        Parent = self.Topbar,
    })

    self.TitleLabel = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Position = UDim2.fromOffset(0, -2),
        Size = UDim2.new(1, 0, 0, 24),
        Text = self.Title,
        TextColor3 = theme:Get("Text"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleGroup,
    })

    self.SubtitleLabel = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 16),
        Text = "Made by ProjectPulse Hub",
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleGroup,
    })

    self.SearchShell = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme:Get("Surface"),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -92, 0.5, 0),
        Size = UDim2.fromOffset(154, 24),
        Parent = self.Topbar,
        CornerRadius = UDim.new(0, 6),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 0.78,
            Thickness = 1,
        },
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.fromOffset(12, 24),
        Text = "S",
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 9,
        Parent = self.SearchShell,
    })

    self.SearchBox = Utility.Create("TextBox", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = theme:Get("TextMuted"),
        PlaceholderText = "Search",
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Text = "",
        TextColor3 = theme:Get("Text"),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SearchShell,
    })

    local controls = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.fromOffset(64, 18),
        Parent = self.Topbar,
    })
    local controlsLayout = Utility.NewListLayout(controls, 6)
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    self.CloseButton = createIconButton(theme, controls, Color3.fromRGB(255, 95, 87), "")
    self.MinimizeButton = createIconButton(theme, controls, Color3.fromRGB(255, 189, 46), "")
    self.MaximizeButton = createIconButton(theme, controls, Color3.fromRGB(39, 201, 63), "")

    self.TabButtonHolder = Utility.Create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(10, 14),
        ScrollBarImageColor3 = theme:Get("Accent"),
        ScrollBarThickness = 3,
        Size = UDim2.new(1, -20, 1, -76),
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
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -18, 0, 16),
        Text = "Toggle Key",
        TextColor3 = theme:Get("Text"),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SidebarFooter,
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.fromOffset(12, 10),
        Size = UDim2.new(1, -18, 0, 16),
        Text = "RightShift",
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
        self.State.Closed = false
        self:SetVisible(false)
    end)
    self.MaximizeButton.MouseButton1Click:Connect(function()
        self:SetMaximized(not self.State.Maximized)
    end)
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    self.WindowScale = Instance.new("UIScale")
    self.WindowScale.Scale = 1
    self.WindowScale.Parent = self.Main

    Utility.MakeDraggable(self.Main, self.Root)
    self:UpdateNavigationButtons()
    self:Open()
end

function Window:Open()
    if self.State.Destroyed or not self.Root then
        return
    end

    self.Root.Size = UDim2.fromOffset(self.DefaultSize.X.Offset - 70, self.DefaultSize.Y.Offset - 70)
    self.Main.BackgroundTransparency = 1
    self.Main.Position = UDim2.fromOffset(0, 10)
    self.WindowScale.Scale = 0.965
    self.State.Hidden = false

    local shouldBlur = self.State.Blur and not self.State.ReopenWithoutBlur
    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = shouldBlur and 16 or 0}, 0.3)
    end

    Utility.FastTween(self.Root, {Size = self.DefaultSize}, 0.32)
    Utility.FastTween(self.Main, {BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.26)
    Utility.FastTween(self.WindowScale, {Scale = 1}, 0.28)
end

function Window:SetVisible(state)
    if self.State.Destroyed or not self.Root then
        return
    end

    self.State.Hidden = not state
    self.Root.Visible = true

    local shouldBlur = state and self.State.Blur and not self.State.ReopenWithoutBlur
    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = shouldBlur and 16 or 0}, 0.24)
    end

    local targetSize = self.State.Maximized and self.MaximizedSize or self.DefaultSize
    local tween = Utility.FastTween(self.Main, {
        BackgroundTransparency = state and 0 or 1,
        Position = state and UDim2.fromOffset(0, 0) or UDim2.fromOffset(0, 10),
    }, 0.22)

    Utility.FastTween(self.WindowScale, {Scale = state and 1 or 0.965}, 0.22)
    Utility.FastTween(self.Root, {
        Size = state and targetSize or UDim2.fromOffset(self.DefaultSize.X.Offset - 70, self.DefaultSize.Y.Offset - 70),
    }, 0.24)

    if state then
        self.State.Closed = false
    end

    if not state then
        tween.Completed:Connect(function()
            if self.State.Hidden and self.Root then
                self.Root.Visible = false
            end
        end)
    end
end

function Window:SetBlur(enabled)
    self.State.Blur = enabled == true

    if not self.State.Blur then
        self.State.ReopenWithoutBlur = true
        if self.BlurEffect then
            Utility.FastTween(self.BlurEffect, {Size = 0}, 0.2)
        end
    elseif not self.State.Hidden and not self.State.Closed and self.BlurEffect then
        self.State.ReopenWithoutBlur = false
        Utility.FastTween(self.BlurEffect, {Size = 16}, 0.2)
    end
end

function Window:Close()
    self.State.Closed = true
    self.State.ReopenWithoutBlur = not self.State.BlurAfterClose

    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = 0}, 0.2)
    end

    self:SetVisible(false)
end
function Window:SetMinimized(state)
    if self.State.Destroyed or not self.Root then
        return
    end

    self.State.Minimized = state

    if state then
        self.State.Maximized = false
        Utility.FastTween(self.Sidebar, {BackgroundTransparency = 1}, 0.16)
        Utility.FastTween(self.ContentShell, {BackgroundTransparency = 1}, 0.16)
        compatDelay(0.16, function()
            if self.State.Minimized then
                self.Sidebar.Visible = false
                self.ContentShell.Visible = false
            end
        end)
    else
        self.Sidebar.Visible = true
        self.ContentShell.Visible = true
        Utility.FastTween(self.Sidebar, {BackgroundTransparency = 0}, 0.18)
        Utility.FastTween(self.ContentShell, {BackgroundTransparency = 0}, 0.18)
    end

    Utility.FastTween(self.Root, {
        Size = state and self.MinimizedSize or (self.State.Maximized and self.MaximizedSize or self.DefaultSize),
    }, 0.26)
end

function Window:SetMaximized(state)
    if self.State.Destroyed or not self.Root then
        return
    end

    self.State.Maximized = state

    if state and self.State.Minimized then
        self.State.Minimized = false
        self.Sidebar.Visible = true
        self.ContentShell.Visible = true
        Utility.FastTween(self.Sidebar, {BackgroundTransparency = 0}, 0.18)
        Utility.FastTween(self.ContentShell, {BackgroundTransparency = 0}, 0.18)
    end

    Utility.FastTween(self.Root, {
        Size = state and self.MaximizedSize or (self.State.Minimized and self.MinimizedSize or self.DefaultSize),
    }, 0.28)
end

function Window:RefreshTheme()
    local theme = self.Theme
    self.Main.BackgroundColor3 = theme:Get("Background")
    self.Topbar.BackgroundColor3 = theme:Get("SurfaceAlt")
    self.Sidebar.BackgroundColor3 = theme:Get("Sidebar")
    self.ContentShell.BackgroundColor3 = theme:Get("Surface")
    self.SearchBox.BackgroundColor3 = theme:Get("SurfaceAlt")
    self.SearchBox.TextColor3 = theme:Get("Text")
    self.SearchBox.PlaceholderColor3 = theme:Get("TextMuted")

    if self.TitleLabel then
        self.TitleLabel.TextColor3 = theme:Get("Text")
    end
    if self.SubtitleLabel then
        self.SubtitleLabel.TextColor3 = theme:Get("TextMuted")
    end

    for _, tab in ipairs(self.Tabs) do
        if tab.Selected then
            tab.SidebarButton.BackgroundColor3 = theme:Get("AccentDark")
            tab.IconLabel.TextColor3 = theme:Get("Text")
            tab.NameLabel.TextColor3 = theme:Get("Text")
        else
            tab.SidebarButton.BackgroundColor3 = theme:Get("SurfaceAlt")
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

function Window:UpdateNavigationButtons()
    if not self.BackButton or not self.ForwardButton then
        return
    end

    local canGoBack = (self.HistoryIndex or 0) > 1
    local canGoForward = (self.HistoryIndex or 0) < #(self.History or {})

    self.BackButton.Active = canGoBack
    self.ForwardButton.Active = canGoForward
    self.BackButton.AutoButtonColor = false
    self.ForwardButton.AutoButtonColor = false
    self.BackButton.BackgroundTransparency = canGoBack and 0 or 0.28
    self.ForwardButton.BackgroundTransparency = canGoForward and 0 or 0.28

    if self.BackButton.IconLabel then
        self.BackButton.IconLabel.TextTransparency = canGoBack and 0 or 0.55
    end
    if self.ForwardButton.IconLabel then
        self.ForwardButton.IconLabel.TextTransparency = canGoForward and 0 or 0.55
    end
end

function Window:_pushHistory(tab)
    if self.SuppressHistory then
        return
    end

    self.History = self.History or {}
    self.HistoryIndex = self.HistoryIndex or 0

    if self.History[self.HistoryIndex] == tab then
        self:UpdateNavigationButtons()
        return
    end

    for index = #self.History, self.HistoryIndex + 1, -1 do
        self.History[index] = nil
    end

    table.insert(self.History, tab)
    self.HistoryIndex = #self.History
    self:UpdateNavigationButtons()
end

function Window:NavigateHistory(step)
    self.History = self.History or {}
    self.HistoryIndex = self.HistoryIndex or 0

    local targetIndex = self.HistoryIndex + step
    local targetTab = self.History[targetIndex]
    if not targetTab then
        self:UpdateNavigationButtons()
        return
    end

    self.HistoryIndex = targetIndex
    self.SuppressHistory = true
    targetTab:Select()
    self.SuppressHistory = false
    self:UpdateNavigationButtons()
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

    tab.SidebarButton = Utility.Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme:Get("SurfaceAlt"),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "",
        Parent = self.TabButtonHolder,
        CornerRadius = UDim.new(0, 4),
        Stroke = {
            Color = theme:Get("Border"),
            Transparency = 1,
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
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.SidebarButton,
    })

    tab.NameLabel = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Text = name,
        TextColor3 = theme:Get("TextMuted"),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.SidebarButton,
    })

    Utility.Ripple(tab.SidebarButton, theme)

    tab.Page = Utility.Create("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        ScrollBarImageColor3 = theme:Get("TextMuted"),
        ScrollBarImageTransparency = 0.18,
        ScrollBarThickness = 6,
        Size = UDim2.new(1, -22, 1, -28),
        Position = UDim2.fromOffset(16, 12),
        Visible = false,
        Parent = self.ContentPages,
    })
    local pageLayout = Utility.NewListLayout(tab.Page, 14)
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        refreshCanvas(tab.Page, pageLayout, 24)
    end)

    function tab:Select()
        if self.Window.CurrentTab == self then
            self.Window:UpdateNavigationButtons()
            return
        end

        for _, other in ipairs(self.Window.Tabs) do
            if other == self then
            else
                other.Selected = false
                other.SidebarButton.BackgroundColor3 = theme:Get("SurfaceAlt")
                other.IconLabel.TextColor3 = theme:Get("Accent")
                other.NameLabel.TextColor3 = theme:Get("TextMuted")

                if other.Page.Visible then
                    local previousPage = other.Page
                    Utility.FastTween(previousPage, {
                        Position = UDim2.fromOffset(34, 14),
                        ScrollBarImageTransparency = 1,
                    }, 0.12, Enum.EasingStyle.Quad)
                    compatDelay(0.12, function()
                        if not other.Selected and previousPage then
                            previousPage.Visible = false
                            previousPage.Position = UDim2.fromOffset(14, 14)
                        end
                    end)
                end
            end
        end

        self.Selected = true
        self.Window.CurrentTab = self
        self.Page.Visible = true
        self.Page.Position = UDim2.fromOffset(-6, 14)
        self.Page.ScrollBarImageTransparency = 1
        self.SidebarButton.BackgroundColor3 = theme:Get("AccentDark")
        self.IconLabel.TextColor3 = theme:Get("Text")
        self.NameLabel.TextColor3 = theme:Get("Text")
        Utility.FastTween(self.Page, {
            Position = UDim2.fromOffset(16, 12),
            ScrollBarImageTransparency = 0,
        }, 0.16, Enum.EasingStyle.Quad)

        self.Window:_pushHistory(self)
        self.Window:UpdateNavigationButtons()
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
            CornerRadius = UDim.new(0, 0),
            Stroke = {
                Color = theme:Get("Border"),
                Transparency = 1,
                Thickness = 1,
            },
            Padding = {
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 18),
                PaddingRight = UDim.new(0, 18),
                PaddingTop = UDim.new(0, 8),
            },
        })

        Utility.Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(1, 0, 0, 18),
            Text = sectionName,
            TextColor3 = theme:Get("Text"),
            TextSize = 12,
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

        local function baseElement(kind, labelText, callback, defaultValue, description)
            local id = string.format("%s_%s_%s", self.Name, sectionName, labelText):gsub("%W", "_")
            local hasDescription = description ~= nil and description ~= ""
            local holder = Utility.Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, hasDescription and 50 or 34),
                Parent = section.Frame,
            })

            local label = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(0.62, 0, 0, 14),
                Text = labelText,
                TextColor3 = theme:Get("Text"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local descriptionLabel = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(0.62, 0, 0, 14),
                Text = description or "",
                TextColor3 = theme:Get("TextMuted"),
                TextSize = 10,
                TextTransparency = hasDescription and 0 or 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            Utility.Create("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = theme:Get("Border"),
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
                Parent = holder,
            })

            return {
                Id = id,
                Kind = kind,
                Label = label,
                DescriptionLabel = descriptionLabel,
                Frame = holder,
                SearchText = labelText,
                Callback = callback,
                Value = defaultValue,
                Set = nil,
            }
        end

        function section:CreateLabel(title, text)
            local component = baseElement("Label", title, nil, text)
            component.Frame.Size = UDim2.new(1, 0, 0, 40)
            component.Label.Size = UDim2.new(1, 0, 0, 16)

            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, 0, 0, 34),
                Text = text,
                TextColor3 = theme:Get("TextMuted"),
                TextSize = 10,
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
            local component = baseElement("Button", labelText, callback, false, tooltip)
            local button = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = theme:Get("AccentDark"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -112, 0, 5),
                Size = UDim2.fromOffset(112, 24),
                Text = labelText,
                Font = Enum.Font.GothamBold,
                TextColor3 = theme:Get("Text"),
                TextSize = 10,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 5),
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
            local component = baseElement("Toggle", labelText, callback, defaultValue or false, tooltip)
            local pill = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = component.Value and theme:Get("Accent") or Color3.fromRGB(82, 82, 86),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -38, 0, 15),
                Size = UDim2.fromOffset(30, 16),
                Text = "",
                Parent = component.Frame,
                CornerRadius = UDim.new(1, 0),
            })
            local knob = Utility.Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Position = component.Value and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2),
                Size = UDim2.fromOffset(14, 14),
                Parent = pill,
                CornerRadius = UDim.new(1, 0),
            })

            local function apply(state, silent)
                component.Value = state
                Utility.FastTween(pill, {BackgroundColor3 = state and theme:Get("Accent") or Color3.fromRGB(82, 82, 86)}, 0.18)
                Utility.FastTween(knob, {Position = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)}, 0.18)
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
            local component = baseElement("Slider", labelText, callback, options.Default or min, options.Description)
            component.Frame.Size = UDim2.new(1, 0, 0, component.DescriptionLabel.TextTransparency == 0 and 52 or 36)

            local valueLabel = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Position = UDim2.new(0, 96, 0, 0),
                Size = UDim2.fromOffset(52, 14),
                Text = "(" .. Utility.FormatValue(component.Value) .. ")",
                TextColor3 = theme:Get("TextMuted"),
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = component.Frame,
            })

            local sliderHitbox = Utility.Create("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -158, 0, 9),
                Size = UDim2.fromOffset(136, 24),
                Text = "",
                Parent = component.Frame,
            })

            local track = Utility.Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(82, 82, 86),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(126, 5),
                Parent = sliderHitbox,
                CornerRadius = UDim.new(1, 0),
            })
            local fill = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Accent"),
                BorderSizePixel = 0,
                Size = UDim2.new((component.Value - min) / (max - min), 0, 1, 0),
                Parent = track,
                CornerRadius = UDim.new(1, 0),
            })
            local knob = Utility.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Position = UDim2.new((component.Value - min) / (max - min), 0, 0.5, 0),
                Size = UDim2.fromOffset(10, 10),
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
                local alpha = (value - min) / (max - min)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                valueLabel.Text = "(" .. Utility.FormatValue(value) .. ")"
                if callback and not silent then
                    callback(value)
                end
            end

            component.Set = function(value, silent)
                setFromRatio((value - min) / (max - min), silent)
            end

            sliderHitbox.InputBegan:Connect(function(input)
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
                Position = UDim2.new(1, -148, 0, 2),
                Size = UDim2.fromOffset(148, 34),
                Text = "",
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 8),
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
                TextSize = 10,
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
                TextSize = 10,
                Parent = button,
            })

            local menu = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 6),
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = button,
                CornerRadius = UDim.new(0, 8),
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
            local closedHeight = 34
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
                local menuHeight = math.min(#list * 30 + 8, 154)
                component.Frame.Size = UDim2.new(1, 0, 0, state and (closedHeight + menuHeight + 8) or closedHeight)
                menu.Visible = true
                Utility.FastTween(menu, {Size = state and UDim2.new(1, 0, 0, menuHeight) or UDim2.new(1, 0, 0, 0)}, 0.16)
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
                    Size = UDim2.new(1, 0, 0, 22),
                    Text = value,
                    Font = Enum.Font.Gotham,
                    TextColor3 = theme:Get("Text"),
                    TextSize = 10,
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
                Position = UDim2.new(1, -148, 0, 2),
                Size = UDim2.fromOffset(148, 34),
                Text = "",
                TextColor3 = theme:Get("Text"),
                TextSize = 10,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 8),
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
                Position = UDim2.new(1, -84, 0, 2),
                Size = UDim2.fromOffset(84, 34),
                Text = component.Value.Name,
                Font = Enum.Font.GothamBold,
                TextColor3 = theme:Get("Text"),
                TextSize = 10,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 8),
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
                Position = UDim2.new(1, -62, 0, 2),
                Size = UDim2.fromOffset(62, 34),
                Text = "",
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 8),
                Stroke = {
                    Color = theme:Get("Border"),
                    Transparency = 0.25,
                    Thickness = 1,
                },
            })

            local popup = Utility.Create("Frame", {
                BackgroundColor3 = theme:Get("Surface"),
                BorderSizePixel = 0,
                Position = UDim2.new(1, -198, 1, 6),
                Size = UDim2.fromOffset(198, 0),
                Visible = false,
                Parent = component.Frame,
                CornerRadius = UDim.new(0, 4),
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
                Size = UDim2.fromOffset(178, 120),
                Parent = popup,
                CornerRadius = UDim.new(0, 8),
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
                Size = UDim2.fromOffset(178, 12),
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
                Utility.FastTween(popup, {Size = state and UDim2.fromOffset(198, 178) or UDim2.fromOffset(198, 0)}, 0.18)
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

        function section:Label(...)
            return self:CreateLabel(...)
        end

        function section:Paragraph(...)
            return self:CreateParagraph(...)
        end

        function section:Button(...)
            return self:CreateButton(...)
        end

        function section:Toggle(...)
            return self:CreateToggle(...)
        end

        function section:Slider(labelText, min, max, defaultValue, callback)
            if type(min) == "table" then
                return self:CreateSlider(labelText, min, max)
            end

            return self:CreateSlider(labelText, {
                Min = min or 0,
                Max = max or 100,
                Default = defaultValue or min or 0,
            }, callback)
        end

        function section:Dropdown(...)
            return self:CreateDropdown(...)
        end

        function section:MultiDropdown(...)
            return self:CreateMultiDropdown(...)
        end

        function section:Textbox(...)
            return self:CreateTextbox(...)
        end

        function section:Keybind(...)
            return self:CreateKeybind(...)
        end

        function section:ColorPicker(...)
            return self:CreateColorPicker(...)
        end

        table.insert(self.Sections, section)
        return section
    end

    function tab:_ensureSection()
        if not self._defaultSection then
            self._defaultSection = self:CreateSection("General")
        end

        return self._defaultSection
    end

    function tab:Section(name)
        return self:CreateSection(name or "General")
    end

    function tab:Button(labelText, callback, tooltip)
        return self:_ensureSection():Button(labelText or "Button", callback, tooltip)
    end

    function tab:Toggle(labelText, defaultValue, callback, tooltip)
        if type(defaultValue) == "function" and callback == nil then
            callback = defaultValue
            defaultValue = false
        end

        return self:_ensureSection():Toggle(labelText or "Toggle", callback, defaultValue or false, tooltip)
    end

    function tab:Slider(labelText, min, max, defaultValue, callback)
        if type(min) == "table" then
            return self:_ensureSection():Slider(labelText or "Slider", min, max)
        end

        return self:_ensureSection():Slider(labelText or "Slider", min or 0, max or 100, defaultValue or min or 0, callback)
    end

    function tab:Dropdown(labelText, values, callback)
        return self:_ensureSection():Dropdown(labelText or "Dropdown", values or {}, callback)
    end

    function tab:MultiDropdown(labelText, values, callback)
        return self:_ensureSection():MultiDropdown(labelText or "Multi Dropdown", values or {}, callback)
    end

    function tab:Textbox(labelText, placeholder, callback)
        return self:_ensureSection():Textbox(labelText or "Textbox", placeholder or "Enter text", callback)
    end

    function tab:Keybind(labelText, defaultKey, callback)
        return self:_ensureSection():Keybind(labelText or "Keybind", defaultKey or Enum.KeyCode.E, callback)
    end

    function tab:ColorPicker(labelText, defaultColor, callback)
        return self:_ensureSection():ColorPicker(labelText or "Color Picker", defaultColor or theme:Get("Accent"), callback)
    end

    function tab:Label(title, text)
        return self:_ensureSection():Label(title or "Label", text or "")
    end

    function tab:Paragraph(title, text)
        return self:_ensureSection():Paragraph(title or "Paragraph", text or "")
    end

    tab.SidebarButton.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:Select()
    end

    return tab
end

function Window:Tab(name, icon)
    return self:CreateTab(name, icon)
end

function Window:Destroy()
    self.State.Closed = true
    self.State.Hidden = true
    self.State.Destroyed = true
    if self.BlurEffect then
        Utility.FastTween(self.BlurEffect, {Size = 0}, 0.2)
    end
    if self.Root then
        self.Root:Destroy()
        self.Root = nil
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
            if window and window.Root and not window.State.Destroyed then
                window:SetVisible(window.State.Hidden)
            end
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
        Tab = function(self, ...)
            return self:CreateTab(...)
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

function Library:Window(title, options)
    return self:CreateWindow(title, options)
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
        libraryObject.new = createLibrary
        return libraryObject
    end

    local fallback = {
        Theme = Theme.new(),
        Utility = Utility,
        Config = Config.new("ProjectPulse"),
        Keybinds = Keybinds.new(),
        Windows = {},
    }

    fallback.new = createLibrary
    setmetatable(fallback, {__index = Library})
    return fallback
end

return createLibrary()
