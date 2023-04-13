---
-- @classmod VoicelineService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local VoicelineService = {}

function VoicelineService:Init()
    self._soundDirectory = {}
    self._groupDirectory = {}

    self:_processFolder(ReplicatedStorage.Voicelines)

    self._zoneTracker = {}
    self._zoneQueue = {}
end

function VoicelineService:PlayRandomGroupForZone(categoryName, zoneName, part)
    return self:PlayGroupForZone(self:GetRandomGroup(categoryName), zoneName, part)
end

function VoicelineService:PlayRandomGroup(categoryName, part)
    return self:PlayGroup(self:GetRandomGroup(categoryName), part)
end

function VoicelineService:PlayGroupForZone(groupName, zoneName, part, ignoreQueue)
    local directory = self._soundDirectory[groupName]
    if not directory then
        return
    end
    local sound = directory[math.random(1, #directory)]:Clone()

    local oldSound = self._zoneTracker[zoneName]
    if oldSound then
        if not ignoreQueue then
            self._zoneQueue[zoneName] = groupName
        end

        return
    end

    self._zoneTracker[zoneName] = sound

    sound.Parent = part or SoundService
    sound.Ended:Connect(function()
        self._zoneTracker[zoneName] = nil

        if self._zoneQueue[groupName] then
            self:PlayGroupForZone(self._zoneQueue[zoneName], zoneName, part)
            self._zoneQueue[zoneName] = nil
        end

        sound:Destroy()
    end)
    sound:Play()

    return sound
end

function VoicelineService:PlayGroup(groupName, part)
    local directory = self._soundDirectory[groupName]
    if not directory then
        return
    end
    local sound = directory[math.random(1, #directory)]:Clone()

    sound.Parent = part or SoundService
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    sound:Play()

    return sound
end

function VoicelineService:GetRandomGroup(category)
    local folder = ReplicatedStorage.Voicelines:FindFirstChild(category)
    if not folder then
        return ""
    end
    local folderChildren = folder:GetChildren()
    return folderChildren[math.random(1, #folderChildren)].Name
end

function VoicelineService:_processFolder(folder)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Folder") then
            self:_processFolder(child)
        elseif child:IsA("Sound") then
            local soundGroup = self._soundDirectory[folder.Name]
            if not soundGroup then
                soundGroup = {}
                self._soundDirectory[folder.Name] = soundGroup
            end

            child.Volume *= 0.5
            child.RollOffMaxDistance = 100
            table.insert(soundGroup, child)
        else
            warn(("[VoicelineService] - Foreign object %q in %q"):format(folder.Name, child.Name))
        end
    end
end

return VoicelineService