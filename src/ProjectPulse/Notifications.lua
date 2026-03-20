local Utility = require(script.Parent.Utility)

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

    task.delay(options.Duration or 3, function()
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
