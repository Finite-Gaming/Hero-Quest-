--- Does cool things
-- @classmod HumanoidDamage
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local HumanoidUtils = require("HumanoidUtils")
local PlayerDamageService = require("PlayerDamageService")

local HumanoidDamage = {}
HumanoidDamage.__index = HumanoidDamage

function HumanoidDamage.new(damage, damageTag)
    local self = setmetatable({}, HumanoidDamage)

    self._damage = damage
    self._damageTag = damageTag

    return self
end

function HumanoidDamage:Apply(raycastResult)
    local humanoid = HumanoidUtils.getHumanoid(raycastResult.Instance)
    if humanoid then
        PlayerDamageService:DamageHumanoid(humanoid, self._damage, self._damageTag)
    end
end

return HumanoidDamage