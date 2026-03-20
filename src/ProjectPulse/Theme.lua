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
    self.Values = table.clone(DEFAULT)
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
