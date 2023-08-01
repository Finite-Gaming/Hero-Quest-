--- Does cool things
-- @classmod ExplosiveDamage
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local Raycaster = require("Raycaster")
local HumanoidUtils = require("HumanoidUtils")
local ApplyImpulse = require("ApplyImpulse")
local PlayerDamageService = require("PlayerDamageService")

local function easeCirc(x)
    return 1 - math.sqrt(1 - (x^2))
end

local ExplosiveDamage = {}
ExplosiveDamage.__index = ExplosiveDamage

function ExplosiveDamage.new(damage, radius, damageTag)
    local self = setmetatable({}, ExplosiveDamage)

    self._raycastParams = RaycastParams.new()
    self._raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    self._raycaster = Raycaster.new(self._raycastParams)
    self._randomObject = Random.new()

    self._damage = damage
    self._radius = radius
    self._damageTag = damageTag

    return self
end

function ExplosiveDamage:Apply(raycastResult)
    local position = raycastResult.Position
    local hashed = {}

    for _, part in ipairs(workspace:GetPartBoundsInRadius(position, self._radius)) do
        self._raycastParams.FilterDescendantsInstances = {part}
        local diff = part.Position - position
        local distanceResult = self._raycaster:Cast(position + (raycastResult.Normal * 0.1), diff)
        if not distanceResult then
            continue
        end

        local damageCalculated = self:_calculateDamage(position, distanceResult.Position)
        local humanoid = HumanoidUtils.getHumanoid(part)
        if humanoid and not hashed[humanoid] then
            hashed[humanoid] = true
            PlayerDamageService:DamageHumanoid(humanoid, damageCalculated, self._damageTag, 0, position, 312, self._radius)
        end
    end
end

function ExplosiveDamage:_calculateDamage(positionA, positionB)
    local distance = (positionA - positionB).Magnitude
    local percent = 1 - (math.clamp(distance, 0, self._radius)/self._radius)

    return self._damage * percent
end

return ExplosiveDamage