---
-- @classmod Axe
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local AxeConstants = require("AxeConstants")
local DamageFeedback = require("DamageFeedback")

local TARGET_ANGLE = 20
local SPEED = 2
local DAMAGE = 30

local Axe = setmetatable({}, BaseObject)
Axe.__index = Axe

function Axe.new(obj)
    local self = setmetatable(BaseObject.new(obj), Axe)

    self._hinge = self._obj.Hinge
    self._hinge.AngularSpeed = SPEED

    self._sound = self._obj:FindFirstChild("Swing")

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = AxeConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player)
        self:_handleHit(player)
    end))

    self._lastUpdate = os.clock()
    self._hinge.TargetAngle = TARGET_ANGLE * (math.random(1, 2) == 1 and 1 or -1)
    self._maid:AddTask(RunService.Heartbeat:Connect(function()
        local updateTick = os.clock()
        if updateTick - self._lastUpdate < 1/20 then
            return
        end
        self._lastUpdate = updateTick

        local currentAngle = math.round(self._hinge.CurrentAngle)

        if math.abs(currentAngle) + 1 >= TARGET_ANGLE then
            self._hinge.TargetAngle = -currentAngle
            self:_playSound()
            self._remoteEvent:FireAllClients()
        end
    end))

    return self
end

function Axe:_playSound()
    if self._sound then
        self._sound:Play()
    end
end

function Axe:_handleHit(player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:TakeDamage(DAMAGE)
        DamageFeedback:SendFeedback(humanoid, DAMAGE)
    end
end

return Axe