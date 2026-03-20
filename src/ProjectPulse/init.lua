local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Theme = require(script.Theme)
local Utility = require(script.Utility)
local Config = require(script.Config)
local Keybinds = require(script.Keybinds)
local Notifications = require(script.Notifications)
local Window = require(script.Window)

local Library = {}
Library.__index = Library

local function createGuiParent()
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

    if playerGui then
        return playerGui
    end

    if gethui then
        return gethui()
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
    self.Notifications = Notifications.new(self, screenGui)
    self.Keybinds:BindLibraryToggle(Enum.KeyCode.RightShift, function()
        for _, window in ipairs(self.Windows) do
            window:SetVisible(window.State.Hidden)
        end
    end)
end

function Library:CreateWindow(title, options)
    self:_ensureGui()

    local window = Window.new(self, title or "ProjectPulse", options or {})
    table.insert(self.Windows, window)

    return window
end

function Library:Notify(options)
    self:_ensureGui()
    self.Notifications:Notify(options)
end

function Library:SetTheme(overrides)
    self.Theme:Apply(overrides)

    for _, window in ipairs(self.Windows) do
        window:RefreshTheme()
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

return function()
    return Library.new()
end
