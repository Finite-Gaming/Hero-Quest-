---
-- @classmod BeamAbilityClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ClientTemplateProvider = require("ClientTemplateProvider")
local AnimationTrack = require("AnimationTrack")
local BeamAbilityConstants = require("BeamAbilityConstants")
local HumanoidLockerService = require("HumanoidLockerService")
local Raycaster = require("Raycaster")
local Spring = require("Spring")
local NPCOverlapParams = require("NPCOverlapParams")
local Maid = require("Maid")
local PlayerAbilityData = require("PlayerAbilityData")
local AbilityStatMixin = require("AbilityStatMixin")

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EFFECT_TYPES = {
    ["PointLight"] = true;
    ["ParticleEmitter"] = true;
    ["Beam"] = true;
    ["Trail"] = true;
}

local BeamAbilityClient = setmetatable({}, BaseObject)
BeamAbilityClient.__index = BeamAbilityClient

function BeamAbilityClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), BeamAbilityClient)

    self._humanoid = self._obj:WaitForChild("Humanoid")
    self._humanoidRootPart = self._obj:WaitForChild("HumanoidRootPart")

    self._leftGrip = self._obj:WaitForChild("LeftHand"):WaitForChild("LeftGripAttachment")
    self._abilityPack = self._maid:AddTask(ClientTemplateProvider:Get("__LightAbilityPack"))
    self._startAtt = self._maid:AddTask(self._abilityPack.BeamStart)
    self._endAtt = self._maid:AddTask(self._abilityPack.BeamEnd)

    self._abilityData = PlayerAbilityData.LightAbility
    self._baseStats = self._abilityData.BaseStats

    self._overlapParams = NPCOverlapParams:Get()
    self._raycaster = Raycaster.new()
    self._raycaster:Ignore({self._obj, workspace.Terrain})
    -- self._raycaster.Visualize = true
    AbilityStatMixin:Add(self)

    self._remoteEvent = self._obj:WaitForChild(BeamAbilityConstants.REMOTE_EVENT_NAME)

    self:_setEffectsEnabled(false)

    self._startAtt.CFrame = self._leftGrip.CFrame
    self._startAtt.Parent = self._leftGrip.Parent

    self._endAtt.Parent = workspace.Terrain
    self._runningLocally = self._obj == Players.LocalPlayer.Character

    self._maid:AddTask(self._humanoid.Died:Connect(function()
        self:_activate(false)
    end))

    if self._runningLocally then
        self._animationTracks = {
            Start = self._maid:AddTask(AnimationTrack.new(self._abilityPack.StartAnimation, self._humanoid));
            Loop = self._maid:AddTask(AnimationTrack.new(self._abilityPack.LoopAnimation, self._humanoid));
        }

        self._animationTracks.Start.Priority = Enum.AnimationPriority.Action3
        self._animationTracks.Loop.Priority = Enum.AnimationPriority.Action4

        self._maid:AddTask(self._animationTracks.Start.Stopped:Connect(function()
            self._animationTracks.Loop:Play()
        end))
    else

    end

    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(action, ...)
        if action == "Activate" then
            self:_activate(...)
        end
    end))

    return self
end

function BeamAbilityClient:_setEffectsEnabled(state)
    self._effectsEnabled = state
    for _, attachment in ipairs({self._startAtt, self._endAtt}) do
        for _, effect in ipairs(attachment:GetDescendants()) do
            if not EFFECT_TYPES[effect.ClassName] then
                continue
            end

            effect.Enabled = state
        end
    end
end

function BeamAbilityClient:CanActivate()
    return
        self._humanoid.Health > 0 and
        #workspace:GetPartBoundsInRadius(self._humanoidRootPart.Position, self:GetRange(), self._overlapParams) ~= 0
end

function BeamAbilityClient:Activate(state)
    self._remoteEvent:FireServer("Activate", state)

    self:_activate(state)
end

function BeamAbilityClient:_activate(state)
    self._active = state
    if state then
        local runnerMaid = Maid.new()
        if self._runningLocally then
            self._humanoid:UnequipTools()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

            self._animationTracks.Start:Play()
        end

        runnerMaid:AddTask(function()
            self:_setEffectsEnabled(false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

            if self._runningLocally then
                HumanoidLockerService:LockHumanoid(nil)

                for _, animationTrack in pairs(self._animationTracks) do
                    if animationTrack.IsPlaying then
                        animationTrack:Stop()
                    end
                end
            end
        end)

        self._maid.RunnerMaid = runnerMaid
        runnerMaid:AddTask(RunService.Heartbeat:Connect(function()
            if not self._active then
                return
            end

            local rootPos = self._humanoidRootPart.Position
            local distanceMap = {}
            local sortedParts = {}
            for _, part in ipairs(workspace:GetPartBoundsInRadius(rootPos, self:GetRange(), self._overlapParams)) do
                distanceMap[part] = (rootPos - part.Position).Magnitude
                table.insert(sortedParts, part)
            end

            table.sort(sortedParts, function(a, b)
                return distanceMap[b] > distanceMap[a]
            end)

            local humanoid = nil

            for i = 1, #sortedParts do
                local part = sortedParts[i]
                local partPos = part.Position

                local raycastResult = self._raycaster:CastTo(rootPos, partPos)
                if raycastResult and raycastResult.Instance:IsDescendantOf(part.Parent) then
                    self._endAtt.WorldPosition = partPos

                    humanoid = part.Parent:FindFirstChild("Humanoid")
                    break
                end
            end

            self:_lockHumanoid(humanoid)
            if not self._active then
                return
            end
            if humanoid and not self._effectsEnabled then
                self:_setEffectsEnabled(true)
            elseif not humanoid then
                self:Activate(false)
            end
        end))
    else
        self._maid.RunnerMaid = nil
    end
end

function BeamAbilityClient:_lockHumanoid(humanoid)
    if self._runningLocally then
        HumanoidLockerService:LockHumanoid(humanoid)
    end
end

return BeamAbilityClient