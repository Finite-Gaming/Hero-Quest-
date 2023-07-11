---
-- @classmod PlayerTeleportAnimation
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AnimationTrack = require("AnimationTrack")
local AlignPosition = require("AlignPosition")
local AlignOrientation = require("AlignOrientation")
local EffectPlayerClient = require("EffectPlayerClient")
local SoundPlayer = require("SoundPlayer")
local Raycaster = require("Raycaster")

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

    local ascendTrack = AnimationTrack.new("rbxassetid://13130377197", humanoid)
    local ascendLoopTrack = AnimationTrack.new("rbxassetid://13130361221", humanoid)

    local attachment1 = Instance.new("Attachment")
    local alignPosition = AlignPosition.new(rootPart.RootRigAttachment, attachment1)
    local alignOrientation = AlignOrientation.new(rootPart.RootRigAttachment)

    alignPosition.MaxForce = 40000 * rootPart.AssemblyMass
    alignPosition.MaxVelocity = 64

    alignOrientation.RigidityEnabled = true
    local rigCFrame = rootPart.RootRigAttachment.WorldCFrame
    alignOrientation.CFrame = rigCFrame

    local effectColor = Color3.fromHSV(Random.new():NextNumber(), 1, 1)

    ascendTrack:GetMarkerReachedSignal("StartFloat"):Connect(function()
        local rootPos = rootPart.Position
        attachment1.WorldPosition = rootPos + Vector3.new(0, 2048, 0)
        workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed

        alignOrientation.CFrame = rootPart.RootRigAttachment.WorldCFrame

        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.AssemblyLinearVelocity = Vector3.zero
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        humanoid.PlatformStand = true

        alignPosition.Enabled = true
        alignOrientation.Enabled = true

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("SurfaceAppearance") then
                part:Destroy()
                continue
            end
            if not part:IsA("BasePart") then
                continue
            end

            part.CanCollide = false
            part.Material = Enum.Material.ForceField
            part.Color = effectColor
        end
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

    task.delay(1.3, function()
        EffectPlayerClient:PlayEffect(
            "TPEffectStart",
            rigCFrame.Position,
            effectColor
        )
    end)

    task.delay(0.2, function()
        SoundPlayer:PlaySound("Teleport_PhaseOut")
    end)
    ascendTrack:Play()

    return self
end

function PlayerTeleportAnimation.enter(player)
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

    local animationTrack = AnimationTrack.new("rbxassetid://13121349036", humanoid)
    local rigCFrame = rootPart.CFrame
    if player == Players.LocalPlayer then
        self._maid.HumanoidStateEvent = humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Landed then
                self._maid.HumanoidStateEvent = nil
                animationTrack:AdjustSpeed(1)
                rootPart.AssemblyAngularVelocity = Vector3.zero
                rootPart.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end

    local bubbleDelay = 0.9
    local raycaster = self._maid:AddTask(Raycaster.new(nil, function(raycastResult)
        return not raycastResult.Instance.CanCollide
    end))
    raycaster:Ignore(character)

    local origin, direction = rigCFrame.Position, Vector3.yAxis * (workspace.Gravity * bubbleDelay)
    local raycastResult = raycaster:Cast(origin, direction)
    local fallFrom = origin + direction
    if raycastResult then
        fallFrom = raycastResult.Position
    end
    fallFrom -= Vector3.new(0, 3, 0)

    local fallTime = fallFrom.Y/workspace.Gravity
    local effectColor = Color3.fromHSV(Random.new():NextNumber(), 1, 1)
    EffectPlayerClient:PlayEffect(
        "TPEffectEnd",
        rigCFrame.Position,
        effectColor
    )


    -- task.delay(0.2, function()
    --     SoundPlayer:PlaySound("Teleport_PhaseOut")
    -- end)
    if player == Players.LocalPlayer then
        animationTrack:Play()
        animationTrack:AdjustSpeed(0)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.CFrame = CFrame.new(fallFrom)
        rootPart.Anchored = true

        task.delay(math.clamp(bubbleDelay - fallTime, 0, math.huge), function()
            rootPart.Anchored = false
        end)
    end

    return self
end

return PlayerTeleportAnimation