---
-- @classmod ArmorApplier
-- @author

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local WeldUtils = require("WeldUtils")
local AssemblyUtils = require("AssemblyUtils")
local ModelUtils = require("ModelUtils")

local RunService = game:GetService("RunService")

local ArmorSets = ReplicatedStorage.ArmorSets
local Helmets = ReplicatedStorage.Helmets

local BASE_PART_NAMES = {
    "Head";
    "Chest";
    "BasicArmorPiece";
}

local ArmorApplier = {}

function ArmorApplier:UpdateStats(...)
    if not RunService:IsServer() then
        return
    end

    require("CharacterHelper"):UpdateStats(...)
end

function ArmorApplier:ClearArmor(character)
    self:UpdateStats(character)
    character:SetAttribute("Armor", nil)
	for _, armorPiece in ipairs(character:GetDescendants()) do
		if armorPiece:GetAttribute("ArmorPiece") then
			armorPiece:Destroy()
		end
	end
end

function ArmorApplier:ClearHelmet(character)
    self:UpdateStats(character)

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
    self:UpdateStats(character)

    for _, armorPiece in ipairs(armorModel:GetChildren()) do
        local limbPiece = self:_applyToLimb(character, armorPiece, setKey)
        limbPiece:SetAttribute("ArmorPiece", true)
    end

    armorModel:Destroy()
end

function ArmorApplier:ApplyHelmet(character, helmetName, setKey)
    if not helmetName then
        return
    end

    local helmetModel = assert(Helmets:FindFirstChild(helmetName)):Clone()
    character:SetAttribute("Helmet", helmetName)
    self:UpdateStats(character)

    local limbPiece = self:_applyToLimb(character, helmetModel.Head, setKey)
    limbPiece:SetAttribute("HelmetPiece", true)
    helmetModel:Destroy()
end

function ArmorApplier:_applyToLimb(character, armorPiece, setKey)
    local limb = character:FindFirstChild(armorPiece.Name)
    if not limb then
        warn(("[ArmorApplier] - Could not find limb for %q")
            :format(armorPiece.Name))
        return
    end

    armorPiece:ScaleTo(character:GetScale())
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
    armorPiece.PrimaryPart = nil

    AssemblyUtils.rigidAssemble(armorPiece)
    self:_processPart(primaryPart)

    if armorPiece:IsA("BasePart") then
        self:_processPart(armorPiece)
    end
    for _, part in ipairs(ModelUtils.getParts(armorPiece)) do
        self:_processPart(part)
    end

    for _, part in ipairs(armorPiece:GetDescendants()) do
        if not part:IsA("BasePart") then
            continue
        end

        self:_processPart(part)
    end

    if setKey then
        armorPiece:SetAttribute("SetKey", setKey)
    end

    local limbPivot = limb:GetPivot()
    armorPiece:PivotTo(limbPivot)
    local relative = primaryPart.CFrame:ToObjectSpace(limbPivot)
    WeldUtils.weld(primaryPart, limb, relative)
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