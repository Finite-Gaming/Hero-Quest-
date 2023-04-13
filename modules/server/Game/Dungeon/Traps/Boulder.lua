---
-- @classmod Boulder
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local BoulderConstants = require("BoulderConstants")
local PlayerDamageService = require("PlayerDamageService")
local SoundPlayerService = require("SoundPlayerService")

local RunService = game:GetService("RunService")

local Boulder = setmetatable({}, BaseObject)
Boulder.__index = Boulder

function Boulder.new(obj)
    local self = setmetatable(BaseObject.new(obj), Boulder)

    self._remoteEvent = Instance.new("RemoteEvent")
    self._remoteEvent.Name = BoulderConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj
    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player, action)
        if action == "Trigger" then
            self:Trigger()
        elseif action == "Hit" then
            self:_handleHit(player)
        end
    end))

    self._rollSpeed = self._obj:GetAttribute("RollSpeed")

    self._boulder = self._obj.Boulder
    self._endPoint = self._obj.EndPoint
    self._sound = self._boulder:FindFirstChildOfClass("Sound")

    self._diameter = self._boulder.Size.Y

    self._startPosition = self._boulder.Position
    self._endPosition = self._endPoint.Position
    self._initialDir = (self._endPosition - self._startPosition).Unit

    for _, part in ipairs({self._obj.Trigger, self._endPoint}) do
        self:_handleDebugPart(part)
    end

    return self
end

function Boulder:_handleDebugPart(part)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false

    part.Transparency = 1
end

function Boulder:_setSoundState(state)
    if self._sound then
        if state then
            self._sound:Play()
        else
            self._sound:Stop()
        end
    end
end

function Boulder:_handleHit(player)
    if not self._triggered then
        return
    end

    PlayerDamageService:DamagePlayer(player, 128, 0.5, self._boulder, 2048, self._diameter + 12)
    SoundPlayerService:PlaySound("Body_Impact_1")
end

function Boulder:Trigger()
    if self._triggered then
        return
    end
    self._triggered = true

    self._lastUpdate = os.clock()
    self:_setSoundState(true)
    self._maid.Update = RunService.Stepped:Connect(function()
        local updateTime = os.clock()
        local deltaTime = updateTime - self._lastUpdate
        self._lastUpdate = updateTime

        local prevCFrame = self._boulder.CFrame
        local direction = (self._endPosition - prevCFrame.Position).Unit
        if direction:Dot(self._initialDir) < 0.9 then
            self._maid.Update = nil
            self:_setSoundState(false)
            return
        end

        local boulderVelocity = direction * deltaTime * self._rollSpeed
        local newCFrame = (prevCFrame + boulderVelocity) * CFrame.Angles(boulderVelocity.Z/9, 0, -boulderVelocity.X/9)
        self._boulder.CFrame = newCFrame
    end)
end

function Boulder:Reset()
    error("Not implemented")
end

return Boulder