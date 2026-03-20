local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Utility = {}

function Utility.Create(className, properties)
    local instance = Instance.new(className)

    for key, value in pairs(properties or {}) do
        if key ~= "Children" and key ~= "CornerRadius" and key ~= "Stroke" and key ~= "Gradient" and key ~= "Padding" then
            instance[key] = value
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
            stroke[key] = value
        end
        stroke.Parent = instance
    end

    if properties and properties.Gradient then
        local gradient = Instance.new("UIGradient")
        for key, value in pairs(properties.Gradient) do
            gradient[key] = value
        end
        gradient.Parent = instance
    end

    if properties and properties.Padding then
        local padding = Instance.new("UIPadding")
        for key, value in pairs(properties.Padding) do
            padding[key] = value
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
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
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

    root.Destroying:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)
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
    local root = target:FindFirstAncestorOfClass("ScreenGui")
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
