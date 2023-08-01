--- this is the jankiest system in this game please dont judge me i will redo it :grin:
-- @classmod CleaverTossAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")
local Raycaster = require("Raycaster")
local Network = require("Network")
local CleaverTossConstants = require("CleaverTossConstants")
local AttackTelegrapherService = require("AttackTelegrapherService")

local CURVE_ANGLE = 210
local CURVE_EXPANSION = 6

local RIGHT_HAND_BONE_OFFSET = CFrame.new(
    12.6180878, 2.45693588, 3.96075439,
    -0.258950084, 0.930726647, 0.25826221,
    0.965575933, 0.256288886, 0.0445336625,
    -0.0247411951, 0.260903478, -0.965050995
)

local CleaverTossAttack = setmetatable({}, AttackBase)
CleaverTossAttack.__index = CleaverTossAttack

function CleaverTossAttack.new(npc)
    local self = setmetatable(AttackBase.new(npc, npc._obj.Animations.Attacks.Toss), CleaverTossAttack)

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(npc._obj)

    self._weapon = npc._obj.Axe
    self._throwTime = 1

    self._remoteEvent = Network:GetRemoteEvent(CleaverTossConstants.REMOTE_EVENT_NAME)
    self._rigidConstraint = self._weapon.RigidConstraint
    self._throwAnimation = self:GetAnimationTrack(1)
    self._throwing = false

    -- self._maid:AddTask(self.AttackPlayed:Connect(function()
    --     local curvePoints = self:GetCurvePoints()
    --     local rootCFrame = npc._humanoidRootPart.CFrame
    --     local startPos = (rootCFrame * RIGHT_HAND_BONE_OFFSET).Position

    --     table.insert(curvePoints, 1, startPos)
    --     table.insert(curvePoints, startPos)

    --     AttackTelegrapherService:TelegraphCurve(curvePoints, 0.4)
    -- end))

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
        local posDiff = rootPart.Position - startPos
        local distance = posDiff.Magnitude

        local curvePoints = self:GetCurvePoints()
        local startTime = workspace:GetServerTimeNow()

        self._rigidConstraint.Enabled = false
        self._weapon.Anchored = true
        self._throwTime = math.clamp(distance/30, 1, 4)
        self._remoteEvent:FireAllClients(npc._obj, self._throwTime, curvePoints, startTime)

        task.delay(self._throwTime - (self._throwAnimation.Length/2), function()
            self._throwAnimation:Play(nil, nil, -1)
        end)

        task.delay(self._throwTime, function()
            self._weapon.Anchored = false
            self._rigidConstraint.Enabled = true
            self._throwing = false
        end)
    end))

    return self
end

function CleaverTossAttack:GetCurvePoints()
    local rootPart = self._obj:GetTarget():FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local startPos = self._weapon.Position
    local posDiff = rootPart.Position - startPos
    local rootPos = rootPart.Position
    local rootLCFrame = CFrame.lookAt(rootPos, rootPos + posDiff.Unit)

    local pointB = rootLCFrame * CFrame.Angles(0, -math.rad(CURVE_ANGLE/1.5), 0) * CFrame.new(0, 0, -CURVE_EXPANSION * 2.4)
    local pointC = rootLCFrame * CFrame.Angles(0, -math.rad(CURVE_ANGLE/2), 0) * CFrame.new(0, 0, -CURVE_EXPANSION)
    local pointD = rootLCFrame * CFrame.Angles(0, math.rad(CURVE_ANGLE/2), 0) * CFrame.new(0, 0, -CURVE_EXPANSION)
    local pointE = rootLCFrame * CFrame.Angles(0, math.rad(CURVE_ANGLE/1.5), 0) * CFrame.new(0, 0, -CURVE_EXPANSION * 2.4)

    return {pointB.Position, pointC.Position, pointD.Position, pointE.Position}
end

function CleaverTossAttack:GetHitDebounce()
    return self._throwTime + 0.3
end

return CleaverTossAttack