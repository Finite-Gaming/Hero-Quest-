---
-- @classmod DashAbilityClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AlignPosition = require("AlignPosition")
local AnimationTrack = require("AnimationTrack")
local GameManager = require("GameManager")
local ClientTemplateProvider = require("ClientTemplateProvider")
local ModelUtils = require("ModelUtils")
local Maid = require("Maid")
local DashAbilityConstants = require("DashAbilityConstants")
local DebugVisualizer = require("DebugVisualizer")

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BASE_ANIMATION_SPEED = 1.3
local DASH_DISTANCE = 16
local DIRECTIONAL_MAP = {
    [0] = "ForwardDash";
    [360] = "ForwardDash";
    [315] = "RightDash";
    [270] = "RightDash";
    [225] = "RightDash";
    [180] = "BackDash";
    [135] = "LeftDash";
    [90] = "LeftDash";
    [45] = "LeftDash";
}

local function roundAngle(angle)
    local roundedAngle = angle % 360
    if roundedAngle < 0 then
        roundedAngle = 360 + roundedAngle
    end

    local remainder = roundedAngle % 45
    if remainder < 22.5 then
        return math.floor(roundedAngle / 45) * 45
    else
        return math.ceil(roundedAngle / 45) * 45
    end
end

local function normalizeAngle(angle)
    if angle >= 0 and angle <= 360 then
        return angle
    elseif angle < 0 then
        return angle + 360
    else
        return angle % 360
    end
end

local function getRelative(dir1, dir2)
    -- Calculate the angle between dir2 and the positive x-axis
    local angleDir2 = math.atan2(dir2.Z, dir2.X)

    -- Calculate the angle between dir1 and the positive x-axis
    local angleDir1 = math.atan2(dir1.Z, dir1.X)

    -- Calculate the relative angle between dir1 and dir2
    local relativeAngle = angleDir1 - angleDir2

    -- Normalize the angle to be between -pi and pi
    while relativeAngle > math.pi do
        relativeAngle = relativeAngle - 2 * math.pi
    end

    while relativeAngle < -math.pi do
        relativeAngle = relativeAngle + 2 * math.pi
    end

    -- Convert the relative angle back to a Vector2 direction
    local relativeDir = Vector3.new(math.cos(relativeAngle), 0, math.sin(relativeAngle))

    return relativeDir
end

local function XZDistance(posA, posB)
    return math.sqrt((posB.X - posA.X)^2 + (posB.Z - posA.Z)^2)
end

local DashAbilityClient = setmetatable({}, BaseObject)
DashAbilityClient.__index = DashAbilityClient

function DashAbilityClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), DashAbilityClient)

    self._humanoid = self._obj:WaitForChild("Humanoid")
    self._humanoidRootPart = self._obj:WaitForChild("HumanoidRootPart")
    self._rootAttachment = self._humanoidRootPart:WaitForChild("RootAttachment")

    self._randomObject = Random.new()

    if Players.LocalPlayer.Character == self._obj then
        self._alignPosition = AlignPosition.new(self._rootAttachment)

        self._alignPosition.Enabled = false
        self._alignPosition.MaxForce = 1000
        self._alignPosition.Responsiveness = 200
        self._alignPosition.RigidityEnabled = true
        self._alignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
        self._alignPosition.ForceRelativeTo = Enum.ActuatorRelativeTo.World
        self._alignPosition.MaxAxesForce = Vector3.new(1, 0, 1)
        self._alignPosition.Parent = self._humanoidRootPart

        self._raycastParams = RaycastParams.new()
        self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        self._raycastParams.FilterDescendantsInstances = {self._obj}
        if GameManager:IsDungeon() then
            self._raycastParams.CollisionGroup = "NPC"
        end

        self._animations = {}
        for _, animation in ipairs(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Dash"):GetChildren()) do
            self._animations[animation.Name] = AnimationTrack.new(animation, self._humanoid)
        end
    end

    self._remoteEvent = self._obj:WaitForChild(DashAbilityConstants.REMOTE_EVENT_NAME)
    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(player, state)
        if player == Players.LocalPlayer then
            return
        end

        self:_setEffectsEnabled(state)
    end))

    return self
end

function DashAbilityClient:_setEffectsEnabled(state)
    if state then
        local effectsMaid = Maid.new()

        local shockwave = effectsMaid:AddTask(ClientTemplateProvider:Get("ShockwaveTemplate"))
        shockwave.Size *= self._obj:GetScale()
        shockwave.Position = self._humanoidRootPart.Position + Vector3.new(0, (-self._humanoidRootPart.Size.Y/2) - self._humanoid.HipHeight + (shockwave.Size.Y/2))
        self:_processPart(shockwave)
        shockwave.Parent = workspace.Terrain

        self:_createLines(15)
        local pseudoModel = effectsMaid:AddTask(Instance.new("Model"))
        for _, part in ipairs(ModelUtils.getParts(self._obj)) do
            local newPart = part:Clone()
            self:_processPart(newPart)

            newPart.Parent = pseudoModel
        end
        pseudoModel.Parent = workspace.Terrain

        self._maid.EffectsMaid = effectsMaid
    else
        self._maid.EffectsMaid = nil
    end
end

function DashAbilityClient:SetEffectsEnabled(state)
    self:_setEffectsEnabled(state)
    self._remoteEvent:FireServer(state)
end

function DashAbilityClient:_processPart(part)
    for _, part in ipairs(part:GetDescendants()) do
        if not part:IsA("BasePart") then
            part:Destroy()
        end
    end
    part.CanCollide = false
    part.Anchored = true
    part.CanQuery = false
    part.CanTouch = false

    part.Material = Enum.Material.Neon
    part.Transparency = 0.8
    part.BrickColor = BrickColor.new("Institutional white")
end

function DashAbilityClient:CanActivate()
    return self._humanoid.Health > 0
end

function DashAbilityClient:_createLines(rate)
    local BOUNDS = 3
    self._maid:AddTask(task.spawn(function()
        local velocity = nil
        local initialPos = self._humanoidRootPart.Position
        RunService.Heartbeat:Wait()
        local difference = self._humanoidRootPart.Position - initialPos
        if difference ~= Vector3.zero then
            velocity = difference
        else
            velocity = self._humanoidRootPart.CFrame.LookVector
        end

        for _ = 1, rate do
            local rootPos = self._humanoidRootPart.Position
            local part = DebugVisualizer:GhostPart()
            part.Material = Enum.Material.Neon
            part.BrickColor = BrickColor.new("Institutional white")
            part.Transparency = self._randomObject:NextNumber(0.5, 0.8)
            part.Size = Vector3.new(0.15, 0.15, self._randomObject:NextNumber(2, 3.5))

            local partPos = rootPos + Vector3.new(
                self._randomObject:NextNumber(-BOUNDS, BOUNDS),
                2 + self._randomObject:NextNumber(-BOUNDS, BOUNDS),
                self._randomObject:NextNumber(-BOUNDS, BOUNDS)
            )
            local partCFrame = CFrame.new(partPos, partPos + velocity * 100)

            part.CFrame = partCFrame
            part.Parent = workspace.Terrain

            local tween = self._maid:AddTask(TweenService:Create(
                part,
                TweenInfo.new(0.3, Enum.EasingStyle.Linear),
                {
                    Position = part.Position + (partCFrame.LookVector * - self._randomObject:NextNumber(-5, -10)),
                    Transparency = 1;
                    Size = part.Size/2
                }
            ))
            self._maid:AddTask(tween.Completed:Connect(function()
                tween:Destroy()
                part:Destroy()
            end))
            tween:Play()
        end
    end))
end

function DashAbilityClient:Activate()
    local rootCFrame = self._humanoidRootPart.CFrame
    local rootSize = self._humanoidRootPart.Size
    local lookDirection = rootCFrame.LookVector
    local dashDirection = self._humanoid.MoveDirection
    if dashDirection == Vector3.zero then
        dashDirection = lookDirection
    end
    dashDirection *= DASH_DISTANCE

    local finalDashPos = nil
    local castResult = workspace:Blockcast(rootCFrame, rootSize, dashDirection, self._raycastParams)
    if castResult then
        finalDashPos = rootCFrame.Position + (dashDirection.Unit * (castResult.Distance - (rootSize.Z/2)))
    else
        finalDashPos = rootCFrame.Position + dashDirection
    end

    local relative = getRelative(lookDirection.Unit, dashDirection.Unit)
    local angle = math.deg(math.atan2(relative.Z, relative.X))
    local nearest = roundAngle(normalizeAngle(angle))

    if not DIRECTIONAL_MAP[nearest] then
        return
    end
    local originalDistance = XZDistance(self._rootAttachment.WorldPosition, finalDashPos)
    local animation = self._animations[DIRECTIONAL_MAP[nearest]]
    local animationSpeed = BASE_ANIMATION_SPEED + (BASE_ANIMATION_SPEED * (1 - (math.clamp(originalDistance, 0, DASH_DISTANCE)/DASH_DISTANCE)))

    animation:Play()
    animation:AdjustSpeed(animationSpeed)
    self:SetEffectsEnabled(true)

    self._maid.Update = RunService.Heartbeat:Connect(function()
        local distance = XZDistance(self._rootAttachment.WorldPosition, finalDashPos)
        if distance > originalDistance then
            self:_cancelForces()
        elseif distance <= 1 then
            self:_cancelForces()
        end
    end)

    self._alignPosition.Position = finalDashPos
    self._alignPosition.Enabled = true
end

function DashAbilityClient:_cancelForces()
    self._maid.Update = nil
    self._alignPosition.Enabled = false
    self:SetEffectsEnabled(false)
end

return DashAbilityClient