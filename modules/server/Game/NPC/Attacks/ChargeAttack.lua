---
-- @classmod ChargeAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")
local Raycaster = require("Raycaster")
local AnimationTrack = require("AnimationTrack")
local VoicelineService = require("VoicelineService")
local PlayerDamageService = require("PlayerDamageService")

local RunService = game:GetService("RunService")

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
        -- move past player
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
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
            if obstructionCast and obstructionCast.Instance:FindFirstAncestor("Map") then
                self:_cancel()
                self._maid.CheckFallback = nil

                VoicelineService:PlayRandomGroup(("%s_Crash"):format(npc._variant), npc._humanoidRootPart)
                self._maid:AddTask(task.delay(0.8, function()
                    VoicelineService:PlayRandomGroup(("%s_Charge"):format(npc._variant), npc._humanoidRootPart)
                end))
            end
        end)
        self._maid.CheckFallback = task.delay(5, function()
            self:_cancel()
        end)
        self.StartHitscan:Fire()
    end))

    return self
end

function ChargeAttack:HandleHit(raycastResult)
    local simHitPos = self._npc._humanoidRootPart.Position
    PlayerDamageService:DamageHitPart(raycastResult.Instance, self._damage, 0.5, Vector3.new(simHitPos.X, raycastResult.Instance.Position.Y, simHitPos.Z), 512, self._hitRadius)
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