---
-- @classmod Boulder
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local BoulderConstants = require("BoulderConstants")
local PlayerDamageService = require("PlayerDamageService")
local SoundPlayerService = require("SoundPlayerService")
local ParametricCurve = require("ParametricCurve");

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
    self._sound = self._boulder:FindFirstChildOfClass("Sound")

    self._diameter = self._boulder.Size.Y
    self._travelTime = self._obj:GetAttribute("TravelTime")
    self._rollInTime = self._obj:GetAttribute("RollIn") or 0

    self._sortedPoints = self._obj.TravelPoints:GetChildren()
    table.sort(self._sortedPoints, function(a, b)
        return tonumber(a.Name) < tonumber(b.Name)
    end)
    for index, part in ipairs(self._sortedPoints) do
        self:_handleDebugPart(part)
        self._sortedPoints[index] = part.Position
    end
    self._curve = ParametricCurve.new(self._sortedPoints, 1000)

    self._startPosition = self._sortedPoints[1]
    self._endPosition = self._sortedPoints[#self._sortedPoints]

    for _, part in ipairs(self._obj.Triggers:GetChildren()) do
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

    PlayerDamageService:DamagePlayer(player, 128, "Boulder", 0.5, self._boulder, 256, self._diameter + 12)
    SoundPlayerService:PlaySound("Body_Impact_1")
end

function Boulder:Trigger()
    if self._triggered then
        return
    end
    self._triggered = true
    -- self._curve:Visualize()

    self._startTime = os.clock()
    self._maid.Update = RunService.Stepped:Connect(function(deltaTime)
        local updateTime = os.clock()
        local elapsedTime = (updateTime - self._startTime)
        local plottedDelta = math.clamp(elapsedTime/self._travelTime, 0, 1)

        local prevCFrame = self._boulder.CFrame
        local direction = (self._curve:GetPoint(math.clamp(plottedDelta + deltaTime, 0, 1)) - prevCFrame.Position).Unit

        local boulderVelocity = direction * deltaTime * 40
        local newCFrame = CFrame.new(self._curve:GetPoint(plottedDelta))
        if elapsedTime >= self._rollInTime then
            if not self._rolling then
                self._rolling = true
                self:_setSoundState(true)
            end
            newCFrame *= CFrame.Angles(boulderVelocity.Z/9, 0, -boulderVelocity.X/9)
        end

        self._boulder.CFrame = newCFrame

        if plottedDelta == 1 then
            self:Reset()
            self._maid.Update = nil
        end
    end)
end

function Boulder:Reset()
    self._triggered = false
    self:_setSoundState(false)
    self._boulder.CFrame = CFrame.new(self._startPosition)
end

return Boulder