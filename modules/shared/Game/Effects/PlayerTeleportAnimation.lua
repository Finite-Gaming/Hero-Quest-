---
-- @classmod PlayerTeleportAnimation
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AnimationTrack = require("AnimationTrack")
local AlignPosition = require("AlignPosition")
local AlignOrientation = require("AlignOrientation")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local PlayerTeleportAnimation = setmetatable({}, BaseObject)
PlayerTeleportAnimation.__index = PlayerTeleportAnimation

function PlayerTeleportAnimation.exit(player)
    local self = setmetatable(BaseObject.new(), PlayerTeleportAnimation)

    local character = player.Character
    if not character then
        warn("[PlayerTeleportAnimation] - No Character!")
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        warn("[PlayerTeleportAnimation] - No Humanoid!")
        return
    end

    local rootPart = humanoid.RootPart
    if not rootPart then
        warn("[PlayerTeleportAnimation] - No HumanoidRootPart!")
        return
    end

    local ascendTrack = AnimationTrack.new("rbxassetid://13130377197", humanoid)
    local ascendLoopTrack = AnimationTrack.new("rbxassetid://13130361221", humanoid)

    local attachment1 = Instance.new("Attachment")
    local alignPosition = AlignPosition.new(rootPart.RootRigAttachment, attachment1)
    local alignOrientation = AlignOrientation.new(rootPart.RootRigAttachment)

    alignPosition.MaxForce = 20000
    alignPosition.MaxVelocity = 24

    alignOrientation.RigidityEnabled = true
    alignOrientation.CFrame = rootPart.RootRigAttachment.WorldCFrame

    ascendTrack:GetMarkerReachedSignal("StartFloat"):Connect(function()
        local rootPos = rootPart.Position
        attachment1.WorldPosition = rootPos + Vector3.new(0, 15, 0)

        alignPosition.Enabled = true

        alignOrientation.CFrame = rootPart.RootRigAttachment.WorldCFrame
        alignOrientation.Enabled = true

        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        humanoid.PlatformStand = true

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("SurfaceAppearance") then
                part:Destroy()
                continue
            end
            if not part:IsA("BasePart") then
                continue
            end
    
            part.Material = Enum.Material.ForceField
            part.Color = Color3.new(1, 1, 1)
        end

        local ballPart = self:_makeNeonPart(Enum.PartType.Ball)
        local cylinderPart = self:_makeNeonPart(Enum.PartType.Cylinder)

        ballPart.Size, cylinderPart.Size = Vector3.zero, Vector3.xAxis * 2048
        ballPart.Position, cylinderPart.CFrame = rootPos, CFrame.new(rootPos + Vector3.new(0, 1024)) * CFrame.Angles(0, 0, math.pi/2)
        ballPart.Transparency, cylinderPart.Transparency = 1, 1

        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(ballPart, tweenInfo, {Transparency = 0.3, Size = Vector3.one * 16}):Play()
        TweenService:Create(cylinderPart, tweenInfo, {Transparency = 0.3, Size = Vector3.new(2048, 8, 8)}):Play()

        ballPart.Parent, cylinderPart.Parent = workspace.Terrain, workspace.Terrain
    end)
    ascendTrack.Stopped:Connect(function()
        ascendLoopTrack:Play()
    end)

    if player == Players.LocalPlayer then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end

    attachment1.Parent = workspace.Terrain
    alignPosition.Parent = rootPart
    alignOrientation.Parent = rootPart

    ascendTrack:Play()

    return self
end

function PlayerTeleportAnimation:_makeNeonPart(shape)
    local part = Instance.new("Part")
    part.Shape = shape
    part.Material = Enum.Material.Neon
    part.CanCollide = false
    part.Anchored = true
    part.CanTouch = false
    part.CanQuery = false
    return part
end

return PlayerTeleportAnimation