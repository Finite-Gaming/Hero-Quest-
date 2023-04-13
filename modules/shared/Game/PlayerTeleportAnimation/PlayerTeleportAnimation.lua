---
-- @classmod PlayerTeleportAnimation
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AnimationTrack = require("AnimationTrack")
local AlignPosition = require("AlignPosition")
local AlignOrientation = require("AlignOrientation")

local Players = game:GetService("Players")

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

    local ascendTrack = AnimationTrack.new("rbxassetid://12930398663", humanoid)
    local ascendLoopTrack = AnimationTrack.new("rbxassetid://12930410713", humanoid)

    local attachment1 = Instance.new("Attachment")
    local alignPosition = AlignPosition.new(rootPart.RootRigAttachment, attachment1)
    local alignOrientation = AlignOrientation.new(rootPart.RootRigAttachment)

    alignPosition.MaxForce = 20000
    alignPosition.MaxVelocity = 3

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
    end)
    ascendTrack.Stopped:Connect(function()
        ascendLoopTrack:Play()
    end)

    for _, part in ipairs(player:GetDescendants()) do
        if not part:IsA("BasePart") then
            continue
        end

        part.Material = Enum.Material.ForceField
        part.Color = Color3.new(1, 1, 1)
    end

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

return PlayerTeleportAnimation