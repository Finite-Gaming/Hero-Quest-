---
-- @classmod LootChest
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local HumanoidUtils = require("HumanoidUtils")
local UserData = require("UserData")

local Players = game:GetService("Players")

local LootChest = setmetatable({}, BaseObject)
LootChest.__index = LootChest

function LootChest.new(obj)
    local self = setmetatable(BaseObject.new(obj), LootChest)

    self._hingeConstraint = assert(self._obj:FindFirstChild("HingeConstraint"), "No HingeConstraint!")
    self._specialReward = assert(self._obj:GetAttribute("SpecialReward"), "No SpecialReward Attribute!")

    for _, part in ipairs(self._obj:GetChildren()) do
        if not part:IsA("BasePart") then
            continue
        end

        self:_connectPart(part)
    end
    self:SetEffectsState(true)

    return self
end

function LootChest:_connectPart(part)
    self._maid:AddTask(part.Touched:Connect(function(touchingPart)
        if self._opened then
            return
        end

        local humanoid = HumanoidUtils.getHumanoid(touchingPart)
        if not humanoid then
            return
        end

        local character = humanoid.Parent
        if not character then
            return
        end
        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        self._opened = true
        UserData:GiveSpecialReward(player.UserId, self._specialReward)
        self:SetEffectsState(false)
        self:SetAngle(self._hingeConstraint.UpperAngle)
    end))
end

function LootChest:SetEffectsState(state)
    for _, particle in ipairs(self._obj:GetDescendants()) do
        if not particle:IsA("ParticleEmitter") and not particle:IsA("PointLight") then
            continue
        end

        particle.Enabled = state
    end
end

function LootChest:SetAngle(angle)
    self._hingeConstraint.TargetAngle = angle
end

return LootChest