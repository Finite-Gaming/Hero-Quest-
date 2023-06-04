---
-- @classmod BeamAbility
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local BeamAbilityConstants = require("BeamAbilityConstants")
local NPCOverlapParams = require("NPCOverlapParams")
local PlayerDamageService = require("PlayerDamageService")
local PlayerAbilityData = require("PlayerAbilityData")
local Raycaster = require("Raycaster")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BeamAbility = setmetatable({}, BaseObject)
BeamAbility.__index = BeamAbility

function BeamAbility.new(obj)
    local self = setmetatable(BaseObject.new(obj), BeamAbility)

    self._overlapParams = NPCOverlapParams:Get()
    self._player = Players[self._obj.Name]
    self._abilityData = PlayerAbilityData.LightAbility
    self._baseStats = self._abilityData.BaseStats

    self._humanoidRootPart = self._obj.HumanoidRootPart

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore({self._obj, workspace.Terrain})

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = BeamAbilityConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj
    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if player.Character ~= self._obj then
            return
        end

        if action == "Activate" then
            self:_activate(...)
        end
    end))

    return self
end

function BeamAbility:_fireOtherClients(...)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == self._obj.Name then
            continue
        end

        self._remoteEvent:FireClient(player, ...)
    end
end

function BeamAbility:_activate(state)
    assert(typeof(state) == "boolean")
    if state and self._active then
        return
    end
    self._active = state
    -- TODO: Verify timing

    self._maid.Update = RunService.Heartbeat:Connect(function()
        local rootPos = self._humanoidRootPart.Position
        local distanceMap = {}
        local sortedParts = {}
        for _, part in ipairs(workspace:GetPartBoundsInRadius(rootPos, self._baseStats.Range, self._overlapParams)) do
            distanceMap[part] = (rootPos - part.Position).Magnitude
            table.insert(sortedParts, part)
        end

        table.sort(sortedParts, function(a, b)
            return distanceMap[b] > distanceMap[a]
        end)

        for i = 1, #sortedParts do
            local part = sortedParts[i]
            local partPos = part.Position

            local raycastResult = self._raycaster:CastTo(rootPos, partPos)
            print(raycastResult)
            if raycastResult and raycastResult.Instance:IsDescendantOf(part.Parent) then
                print(true)
                PlayerDamageService:DamageHitPart(part, self._baseStats.Damage, self._baseStats.DamageCooldown, self._player)
                break
            end
        end
    end)

    if state then
        self:_fireOtherClients("Activate", state)

        self._maid:AddTask(task.delay(self._baseStats.AbilityLength, function()
            self:_activate(false)
        end))
    else
        self._maid.Update = nil
        self._remoteEvent:FireAllClients("Activate", state)
    end
end

return BeamAbility