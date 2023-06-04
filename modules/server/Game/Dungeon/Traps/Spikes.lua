---
-- @classmod Spikes
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local SpikesConstants = require("SpikesConstants")
local DebugVisualizer = require("DebugVisualizer")
local HumanoidUtils = require("HumanoidUtils")
local PlayerDamageService = require("PlayerDamageService")

local DAMAGE_COOLDOWN = 0.5

local DEBUG_ENABLED = false

local Spikes = setmetatable({}, BaseObject)
Spikes.__index = Spikes

function Spikes.new(obj)
    local self = setmetatable(BaseObject.new(obj), Spikes)

    self._damageTimes = {}

    self._overlapParams = OverlapParams.new()
    self._ignoreList = {workspace.Map, workspace.Traps}

    local modelCFrame, modelSize = self._obj:GetBoundingBox()

    self._hitregPart = DebugVisualizer:GhostPart()
    self._hitregPart.Name = "HitregPart"
    self._hitregPart.Transparency = DEBUG_ENABLED and 0.5 or 1
    self._hitregPart.BrickColor = BrickColor.Red()

    self._hitregPart.Size = modelSize
    self._hitregPart.CFrame = modelCFrame
    self._hitregPart.CanTouch = true
    self._hitregPart.Parent = self._obj

    self._maid:AddTask(self._hitregPart.Touched:Connect(function(part)
        if not self._state then
            return
        end

        local humanoid = HumanoidUtils.getHumanoid(part)

        if humanoid then
            self:_damageHumanoid(humanoid)
        end
    end))

    self._state = false

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = SpikesConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    self:_setState(false)
    self._maid:AddTask(task.spawn(function()
        while true do
            task.wait(self._state and 2 or 4)

            self:_setState(not self._state)
        end
    end))

    return self
end

function Spikes:_damageHumanoid(humanoid)
    PlayerDamageService:DamageCharacter(humanoid.Parent, 30, DAMAGE_COOLDOWN)
end

function Spikes:_setState(bool)
    self._state = bool

    self._remoteEvent:FireAllClients("SetState", bool)

    if bool then
        self._maid.DamageUpdate = task.spawn(function()
            while true do
                for _, part in ipairs(workspace:GetPartsInPart(self._hitregPart, self._overlapParams)) do
                    local humanoid = HumanoidUtils.getHumanoid(part)

                    if humanoid then
                        self:_damageHumanoid(humanoid)
                    else
                        table.insert(self._ignoreList, part)
                        self._overlapParams.FilterDescendantsInstances = self._ignoreList
                    end
                end

                task.wait(DAMAGE_COOLDOWN + 0.05)
            end
        end)
    else
        self._maid.DamageUpdate = nil
    end
end

return Spikes