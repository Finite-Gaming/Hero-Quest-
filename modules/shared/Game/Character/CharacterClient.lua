---
-- @classmod CharacterClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ClientClassBinders = require("ClientClassBinders")
local GameManager = require("GameManager")
local CameraShaker = require("CameraShaker")
local SoundPlayer = require("SoundPlayer")
local Network = require("Network")
local CameraShakeServiceConstants = require("CameraShakeServiceConstants")
local UserSettingsClient = require("UserSettingsClient")
local ClientOverlapParams = require("ClientOverlapParams")
local WorldTutorialClient = require("WorldTutorialClient")

local Players = game:GetService("Players")

local CharacterClient = setmetatable({}, BaseObject)
CharacterClient.__index = CharacterClient

function CharacterClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), CharacterClient)

    if self._obj.Name ~= Players.LocalPlayer.Name then
        return
    end
    local localCharacter = Players.LocalPlayer.Character
    while not localCharacter or localCharacter ~= self._obj do
        localCharacter = Players.LocalPlayer.CharacterAdded:Wait()
    end

    if GameManager:IsLobby() then
        WorldTutorialClient:Play()
    end
    ClientOverlapParams:Add(self._obj)

    self._camera = workspace.CurrentCamera
    self._cameraShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cframe)
        self._camera.CFrame *= cframe
    end)
    self._cameraShaker:Start()

    self._humanoid = self._obj:WaitForChild("Humanoid")
    self._humanoidRootPart = self._obj:WaitForChild("HumanoidRootPart")
    self._oldHealth = self._humanoid.Health
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        local newHealth = self._humanoid.Health
        local healthDiff = newHealth - self._oldHealth
        if newHealth == self._humanoid.MaxHealth then
            return
        end

        local intensity = math.abs(healthDiff) * 0.2
        if math.sign(healthDiff) == -1 then
            if not UserSettingsClient:GetSetting("DisableCameraShake") then
                self._cameraShaker:ShakeOnce(intensity, intensity * 4, 0, intensity/16, intensity/16, 0.7)
            end

            if self._obj:GetAttribute("Armor") then
                SoundPlayer:PlaySoundAtPart(self._humanoidRootPart, "Armor_Hit")
            end
            SoundPlayer:PlaySoundAtPart(self._humanoidRootPart, "Body_Hit")
        end
        self._oldHealth = newHealth
    end))

    self._maid:AddTask(Network:GetRemoteEvent(CameraShakeServiceConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(intensity)
        if UserSettingsClient:GetSetting("DisableCameraShake") then
            return
        end
        self._cameraShaker:ShakeOnce(intensity, intensity * 4, 0, intensity/16, intensity/16, 0.7)
    end))

    return self
end

return CharacterClient