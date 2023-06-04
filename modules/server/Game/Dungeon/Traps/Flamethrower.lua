---
-- @classmod Flamethrower
-- @author

local HttpService = game:GetService("HttpService")
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local FlamethrowerConstants = require("FlamethrowerConstants")  
local HumanoidUtils = require("HumanoidUtils")
local PlayerDamageService = require("PlayerDamageService")

local RunService = game:GetService("RunService")

local MIN_DAMAGE = 10
local MAX_DAMAGE = 30

local MIN_WAIT = 7 -- should be at least 4
local MAX_WAIT = 13

local Flamethrower = setmetatable({}, BaseObject)
Flamethrower.__index = Flamethrower

function Flamethrower.new(obj)
    local self = setmetatable(BaseObject.new(obj), Flamethrower)

    self._immuneTracker = {}

    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterDescendantsInstances = {workspace.Map, workspace.Terrain}
    self._overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    self._remoteEvent = Instance.new("RemoteEvent")
    self._remoteEvent.Name = FlamethrowerConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    self._maid:AddTask(self._obj.Output.ShotStart.Ended:Connect(function()
        self._maid.Update = nil
        self._obj.Output.ShotEnd:Play()
        self._obj.Output.Attachment.FireEffect.Enabled = false
        self._obj.Output.Attachment.SmokeEffect.Enabled = false
    end))

    self._maid:AddTask(task.spawn(function()
        while true do
            task.wait(math.random(MIN_WAIT, MAX_WAIT))

            self:Fire()
        end
    end))

    return self
end

function Flamethrower:Fire()
    local ignoreTable = {}

    self._obj.Output.ShotStart:Play()
    self._obj.Output.Attachment.FireEffect.Enabled = true
    self._obj.Output.Attachment.SmokeEffect.Enabled = true
    self._maid.Update = RunService.Heartbeat:Connect(function()
        table.clear(ignoreTable)

        for _, part in ipairs(workspace:GetPartsInPart(self._obj.Hitbox, self._overlapParams)) do
            local humanoid = HumanoidUtils.getHumanoid(part)
            if humanoid then
                if ignoreTable[humanoid] then
                    continue
                end
                local hitUpdate = os.clock()
                local lastHit = self._immuneTracker[humanoid] or 0
                if hitUpdate - lastHit < 0.25 then
                    continue
                end
                ignoreTable[humanoid] = true
                self._immuneTracker[humanoid] = hitUpdate

                local damage = math.random(MIN_DAMAGE, MAX_DAMAGE)
                PlayerDamageService:DamageCharacter(humanoid.Parent, damage)
            end
        end
    end)
end

return Flamethrower