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
