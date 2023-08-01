---
-- @classmod ChargeAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")
local Raycaster = require("Raycaster")
local AnimationTrack = require("AnimationTrack")
local VoicelineService = require("VoicelineService")
local PlayerDamageService = require("PlayerDamageService")
local CameraShakeService = require("CameraShakeService")
local HitscanPartService = require("HitscanPartService")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ChargeAttack = setmetatable({}, AttackBase)
ChargeAttack.__index = ChargeAttack

function ChargeAttack.new(npc)
    local self = setmetatable(AttackBase.new(npc, npc._obj.Animations.Attacks.Charge), ChargeAttack)

    self._npc = npc

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(workspace.Rooms)

    self._chargeHit = AnimationTrack.new(npc._obj.Animations.ChargeHit, self._humanoid)

    self._damage = 50 -- change to attribute later or something yes
    self._hitRadius = 10

    self._maid:AddTask(self.AttackPlayed:Connect(function(character)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end

        local raycastResult = self:_floorCast()
        if raycastResult then
            local pointA = raycastResult.Position
            local lookVector = CFrame.lookAt(Vector3.new(pointA.X, rootPart.Position.Y, pointA.Z), rootPart.Position).RightVector
            local pointB = pointA + (lookVector * 128)
            local distance = (pointA - pointB).Magnitude

            HitscanPartService:Add({
                BrickColor = BrickColor.new("Persimmon");
                CFrame = CFrame.lookAt(pointA, pointB) * CFrame.new(-distance/2, 0, 0);
                Size = Vector3.new(distance, 1, 12);
                Material = Enum.Material.Neon;
            }, NumberRange.new(self._damage - 12, self._damage), 2, 0.25)
        end

        self._npc.StateChanged:Fire("Charge")
        npc:_lockHumanoid()
        self._humanoid.WalkSpeed = npc._settings.RunSpeed + 20

        local moveDirection = (rootPart.Position - self._humanoid.RootPart.Position).Unit * 512
        local moveToPos = self._humanoid.RootPart.Position + Vector3.new(moveDirection.X, 0, moveDirection.Z)

        npc:StartWalkEffects()
        self._humanoid:MoveTo(moveToPos)
        self._maid.ObstructionCheck = RunService.Heartbeat:Connect(function()
            local rootCFrame = self._humanoid.RootPart.CFrame
            local obstructionCast = self._raycaster:Cast(rootCFrame.Position, rootCFrame.LookVector * 12)
            if obstructionCast and obstructionCast.Instance:IsGrounded() --[[and obstructionCast.Instance:FindFirstAncestor("Map") ]]then
                self:_cancel()
                self._maid.CheckFallback = nil

                VoicelineService:PlayRandomGroup(("%s_Crash"):format(npc._variant), npc._humanoidRootPart)
                local player = Players:GetPlayerFromCharacter(character)
                if player then
                    local maxDist = 64
                    local distance = (rootPart.Position - rootCFrame.Position).Magnitude
                    local shakeStrength = 7 * (1 - ((math.clamp(distance, 0.1, maxDist)/maxDist))) * 2

                    CameraShakeService:Shake(player, shakeStrength)
                end

                self._maid:AddTask(task.delay(0.8, function()
                    VoicelineService:PlayRandomGroup(("%s_Charge"):format(npc._variant), npc._humanoidRootPart)
                end))
            end
        end)
        self._maid.CheckFallback = task.delay(4, function()
            self:_cancel()
        end)
        -- self.StartHitscan:Fire()
    end))

    return self
end

function ChargeAttack:_floorCast()
    return self._raycaster:Cast(self._humanoid.RootPart.Position, -Vector3.yAxis * (self._humanoid.HipHeight + 6))
end

function ChargeAttack:HandleHit(raycastResult)
    local simHitPos = self._npc._humanoidRootPart.Position
    PlayerDamageService:DamageHitPart(
        raycastResult.Instance,
        0,
        self._npc._obj.Name,
        0.5,
        Vector3.new(simHitPos.X, raycastResult.Instance.Position.Y, simHitPos.Z),
        256,
        self._hitRadius
    )
end

function ChargeAttack:GetHitDebounce()
    return self._chargeHit.Length
end

function ChargeAttack:_cancel()
    self._maid.ObstructionCheck = nil

    self.EndHitscan:Fire()
    local rootCFrame = self._humanoid.RootPart.CFrame
    self._humanoid:MoveTo(rootCFrame.Position + self._humanoid.MoveDirection)
    self._humanoid.WalkSpeed = self._npc._settings.WalkSpeed

    self._npc:StopWalkEffects()
    self:GetAnimationTrack(1):Stop()
    self._chargeHit:Play()

    if math.random(1, 4) == 4 then
        self._maid:AddTask(task.delay(3, function()
            VoicelineService:PlayRandomGroup(("%s_Rage"):format(self._npc._variant), self._npc._humanoidRootPart)
        end))
    end
end

return ChargeAttack