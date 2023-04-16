--- this is the jankiest system in this game please dont judge me i will redo it :grin:
-- @classmod CleaverTossAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")
local Raycaster = require("Raycaster")
local Network = require("Network")
local CleaverTossConstants = require("CleaverTossConstants")

local CURVE_ANGLE = 210
local CURVE_EXPANSION = 6

local CleaverTossAttack = setmetatable({}, AttackBase)
CleaverTossAttack.__index = CleaverTossAttack

function CleaverTossAttack.new(npc)
    local self = setmetatable(AttackBase.new(npc, npc._obj.Animations.Attacks.Toss), CleaverTossAttack)

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(npc._obj)

    self._weapon = npc._obj.Axe

    self._remoteEvent = Network:GetRemoteEvent(CleaverTossConstants.REMOTE_EVENT_NAME)
    self._rigidConstraint = self._weapon.RigidConstraint
    self._throwAnimation = self:GetAnimationTrack(1)
    self._throwing = false

    self._maid:AddTask(self._throwAnimation:GetMarkerReachedSignal("Throw"):Connect(function()
        if self._throwing then
            return
        end
        self._throwing = true

        local target = npc:GetTarget()
        local rootPart = target:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end

        local startPos = self._weapon.Position
        local lookDir = (rootPart.Position - startPos).Unit
        local rootPos = rootPart.Position
        local rootLCFrame = CFrame.lookAt(rootPos, rootPos + lookDir)

        local pointB = rootLCFrame * CFrame.Angles(0, -math.rad(CURVE_ANGLE/1.5), 0) * CFrame.new(0, 0, -CURVE_EXPANSION * 2.4)
        local pointC = rootLCFrame * CFrame.Angles(0, -math.rad(CURVE_ANGLE/2), 0) * CFrame.new(0, 0, -CURVE_EXPANSION)
        local pointD = rootLCFrame * CFrame.Angles(0, math.rad(CURVE_ANGLE/2), 0) * CFrame.new(0, 0, -CURVE_EXPANSION)
        local pointE = rootLCFrame * CFrame.Angles(0, math.rad(CURVE_ANGLE/1.5), 0) * CFrame.new(0, 0, -CURVE_EXPANSION * 2.4)

        local startTime = workspace:GetServerTimeNow()

        self._rigidConstraint.Enabled = false
        self._weapon.Anchored = true
        self._remoteEvent:FireAllClients(npc._obj, {pointB.Position, pointC.Position, pointD.Position, pointE.Position}, startTime)

        task.delay(CleaverTossConstants.THROW_TIME - (self._throwAnimation.Length/2), function()
            self._throwAnimation:Play(nil, nil, -1)
        end)

        task.delay(CleaverTossConstants.THROW_TIME, function()
            self._weapon.Anchored = false
            self._rigidConstraint.Enabled = true
            self._throwing = false
        end)
    end))

    return self
end

function CleaverTossAttack:GetHitDebounce()
    return CleaverTossConstants.THROW_TIME + 0.3
end

return CleaverTossAttack