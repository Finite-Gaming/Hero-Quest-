---
-- @classmod ArmorApplier
-- @author

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local WeldUtils = require("WeldUtils")
local AssemblyUtils = require("AssemblyUtils")
local ModelUtils = require("ModelUtils")
local ItemConstants = require("ItemConstants")

local RunService = game:GetService("RunService")

local ArmorSets = ReplicatedStorage.ArmorSets
local Helmets = ReplicatedStorage.Helmets

local BASE_PART_NAMES = {
    "Head";
    "Chest";
    "BasicArmorPiece";
}

local ArmorApplier = {}

function ArmorApplier:_applyStats(character, setData, multiplier)
    if not RunService:IsServer() then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.MaxHealth += (setData.Health or 0) * (multiplier or 1)
        humanoid.WalkSpeed += (setData.Speed or 0) * (multiplier or 1)

        local spawnTime = character:GetAttribute("SpawnTime")
        if os.clock() - 3 - spawnTime < 2 then
            humanoid.Health = humanoid.MaxHealth
        end
    else
        warn("[ArmorApplier] - No humanoid!")
    end
end

function ArmorApplier:ClearArmor(character)
    local armorSet = character:GetAttribute("Armor")
    if armorSet then
        self:_applyStats(character, ItemConstants.Armors[armorSet], -1)
    end

    character:SetAttribute("Armor", nil)
	for _, armorPiece in ipairs(character:GetDescendants()) do
		if armorPiece:GetAttribute("ArmorPiece") then
			armorPiece:Destroy()
		end
	end
end

function ArmorApplier:ClearHelmet(character)
    local helmet = character:GetAttribute("Helmet")
    if helmet then
        self:_applyStats(character, ItemConstants.Helmets[helmet], -1)
    end

    character:SetAttribute("Helmet", nil)
    for _, child in ipairs(character.Head:GetChildren()) do
        if child:GetAttribute("HelmetPiece") then
            child:Destroy()
        end
    end
end

function ArmorApplier:ApplyArmor(character, armorSet, setKey)
    if not armorSet then
        return
    end

    local armorModel = assert(ArmorSets:FindFirstChild(armorSet)):Clone()
    character:SetAttribute("Armor", armorSet)
    self:_applyStats(character, ItemConstants.Armors[armorSet])

    for _, armorPiece in ipairs(armorModel:GetChildren()) do
        local limbPiece = self:_applyToLimb(character, armorPiece)
        limbPiece:SetAttribute("ArmorPiece", true)
        limbPiece:SetAttribute("SetKey", setKey)
    end

    armorModel:Destroy()
end

function ArmorApplier:ApplyHelmet(character, helmetName, setKey)
    if not helmetName then
        return
    end

    local helmetModel = assert(Helmets:FindFirstChild(helmetName)):Clone()
    character:SetAttribute("Helmet", helmetName)
    self:_applyStats(character, ItemConstants.Helmets[helmetName])

    local limbPiece = self:_applyToLimb(character, helmetModel.Head)
    limbPiece:SetAttribute("HelmetPiece", true)
    limbPiece:SetAttribute("SetKey", setKey)
    helmetModel:Destroy()
end

function ArmorApplier:_applyToLimb(character, armorPiece)
    local limb = character:FindFirstChild(armorPiece.Name)
    if not limb then
        warn(("[ArmorApplier] - Could not find limb for %q")
            :format(armorPiece.Name))
        return
    end

    local primaryPart = if armorPiece:IsA("Model") then armorPiece.PrimaryPart else armorPiece
    if not primaryPart then
        for _, partName in ipairs(BASE_PART_NAMES) do
            local basePart = armorPiece:FindFirstChild(partName)
            if basePart then
                primaryPart = basePart
                break
            end
        end
    end
    if not primaryPart then
        primaryPart = armorPiece:FindFirstChildWhichIsA("BasePart")
    end

    primaryPart.Name = "Handle"
    primaryPart.Anchored = true
    armorPiece.PrimaryPart = nil

    -- primaryPart.Size = limb.Size + Vector3.one * 0.2
    -- TODO: scale entire model, kinda waiting on :ScaleTo to release :grin:
    AssemblyUtils.rigidAssemble(armorPiece)
    armorPiece:PivotTo(limb:GetPivot())

    primaryPart.Anchored = false
    if armorPiece:IsA("BasePart") then
        self:_processPart(armorPiece)
    end
    for _, part in ipairs(ModelUtils.getParts(armorPiece)) do
        self:_processPart(part)
    end
    WeldUtils.weld(primaryPart, limb)
    armorPiece.Parent = limb

    return armorPiece
end

function ArmorApplier:_processPart(part)
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
end

return ArmorApplier