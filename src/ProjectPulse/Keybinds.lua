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
