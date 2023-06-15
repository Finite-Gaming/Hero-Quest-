---
-- @classmod ArmorEquipEffect
-- @author

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ModelUtils = require("ModelUtils")
local ClientTemplateProvider = require("ClientTemplateProvider")
local Maid = require("Maid")

local ArmorSets = ReplicatedStorage:WaitForChild("ArmorSets")
local Helmets = ReplicatedStorage:WaitForChild("Helmets")

local RANGE = NumberRange.new(12, 20)
local ROTATION_STEP = math.pi/32

local runningEffects = {
    Armor = {};
    Helmet = {};
}

local ArmorEquipEffect = setmetatable({}, BaseObject)
ArmorEquipEffect.__index = ArmorEquipEffect

function ArmorEquipEffect.new(character, armorName, endTime)
    local self = setmetatable(BaseObject.new(), ArmorEquipEffect)

    local setModel = ArmorSets:FindFirstChild(armorName)
    local isArmor = true
    if not setModel then
        setModel = Helmets:FindFirstChild(armorName)
        isArmor = false
    end

    local oldEffect = nil
    local cleanTable = nil
    if isArmor then
        cleanTable = runningEffects.Armor
        oldEffect = cleanTable[character]
        cleanTable[character] = self
    else
        cleanTable = runningEffects.Helmet
        oldEffect = cleanTable[character]
        cleanTable[character] = self
    end
    if oldEffect then
        oldEffect:Destroy()
    end

    self._randomObject = Random.new()

    local totalLimbs = 0
    local limbsFinished = 0
    local armorSet = assert(setModel):Clone()
    self._maid:AddTask(task.spawn(function()
        local armorPieces = armorSet:GetChildren()
        for _, armorPiece in ipairs(armorPieces) do
            local limb = character:FindFirstChild(armorPiece.Name)
            if not limb then
                continue
            end
            totalLimbs += 1

            local shouldSkip = false
            for _, replicatedArmor in ipairs(limb:GetChildren()) do
                if replicatedArmor:GetAttribute("SetKey") == endTime then
                    shouldSkip = true
                end
            end
            if shouldSkip then
                continue
            end

            local signalKey = self:_animateLimb(limb, armorPiece, endTime)
            local addedKey = ("Added_%s"):format(HttpService:GenerateGUID(false))
            self._maid[addedKey] = limb.ChildAdded:Connect(function(child)
                if child:GetAttribute("SetKey") == endTime and child ~= armorPiece then
                    self._maid[addedKey] = nil
                    self._maid[signalKey] = nil

                    limbsFinished += 1

                    if limbsFinished == totalLimbs then
                        cleanTable[character] = nil
                    end
                end
            end)

            task.wait(math.clamp((endTime - workspace:GetServerTimeNow() - 1)/#armorPieces, 0, math.huge))
        end
    end))

    return self
end

function ArmorEquipEffect.cancel(character, armorType)
    local oldEffect = runningEffects[armorType][character]
    if oldEffect then
        oldEffect:Destroy()
        runningEffects[armorType][character] = nil
    end
end

function ArmorEquipEffect:_animateLimb(limb, armorPiece, endTime)
    local currentRotation = 0
    local timeDiff = endTime - workspace:GetServerTimeNow()
    local maid = Maid.new()

    local heightOffset = self._randomObject:NextNumber(0, 2)
    armorPiece:PivotTo((limb:GetPivot() + Vector3.new(
        self._randomObject:NextNumber(RANGE.Min, RANGE.Max),
        heightOffset,
        self._randomObject:NextNumber(RANGE.Min, RANGE.Max)
    )) * CFrame.Angles(
        self._randomObject:NextNumber(-math.pi, math.pi),
        self._randomObject:NextNumber(-math.pi, math.pi),
        self._randomObject:NextNumber(-math.pi, math.pi)
    ))
    local relativePosition = armorPiece:GetPivot().Position - limb:GetPivot().Position
    local pieceDistance = relativePosition.Magnitude

    local originalProperties = {}
    for _, part in ipairs(ModelUtils.getParts(armorPiece)) do
        local originals = {}
        originals.Color = part.Color
        originals.Material = part.Material

        -- part.Color = Color3.new(1, 1, 1)
        -- part.Material = Enum.Material.ForceField

        originalProperties[part] = originals

        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
    end

    local trail = maid:AddTask(ClientTemplateProvider:Get("ArmorEffectTrailTemplate"))
    local att0, att1 = maid:AddTask(Instance.new("Attachment")), maid:AddTask(Instance.new("Attachment"))
    local basePart = armorPiece:FindFirstChildWhichIsA("BasePart")

    maid:AddTask(armorPiece)

    att0.Position = Vector3.new((basePart.Size.X/2) - 0.05, 0, 0)
    att1.Position = -att0.Position
    trail.Attachment0, trail.Attachment1 = att0, att1
    trail.Parent, att0.Parent, att1.Parent = basePart, basePart, basePart
    trail.Enabled = true

    armorPiece.Parent = workspace.Terrain

    local signalKey = ("Signal_%s"):format(HttpService:GenerateGUID(false))
    maid:AddTask(RunService.Heartbeat:Connect(function()
        currentRotation += ROTATION_STEP
        currentRotation %= math.pi * 2

        local currentTime = workspace:GetServerTimeNow()
        local lerpAmount = 1 - math.clamp((endTime - currentTime)/timeDiff, 0, 1)

        local limbCFrame = limb:GetPivot()
        local limbPosition = limbCFrame.Position

        local relativeEased = relativePosition * (1 - lerpAmount)
        local positionRotated =
            limbPosition +
            (Vector3.new(
                math.sin(currentRotation),
                heightOffset,
                math.cos(currentRotation)
            ) * relativeEased)

        local distance = (limbPosition - positionRotated).Magnitude

        local rotationAmount = TweenService:GetValue(1 - (distance - 1) / (pieceDistance - 1), Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
        local rotationEasedCFrame = CFrame.fromOrientation(0, currentRotation * 8, 0):Lerp(CFrame.fromOrientation(limbCFrame:ToOrientation()), rotationAmount)

        armorPiece:PivotTo(CFrame.fromMatrix(positionRotated, rotationEasedCFrame.XVector, rotationEasedCFrame.YVector, rotationEasedCFrame.ZVector))
    end))

    self._maid[signalKey] = maid

    return signalKey
end

return ArmorEquipEffect