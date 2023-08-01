--- Holder for for projectile specific data
-- @classmod ProjectileType
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ProjectileType = {}
ProjectileType.__index = ProjectileType

function ProjectileType.new(data)
    local self = setmetatable({}, ProjectileType)

    self._data = assert(data, "No data")

    return self
end

function ProjectileType:GetName()
    return self._data.Name
end

function ProjectileType:GetBuilder()
    return self._data.Builder
end

function ProjectileType:GetSpeed()
    return self._data.Speed
end

function ProjectileType:DoesStick()
    return self._data.StickToTarget
end

function ProjectileType:DoesBounce()
    return self:GetBounceData() and true or false
end

function ProjectileType:GetBounceData()
    return self._data.BounceData
end

function ProjectileType:GetLifetime()
    return self._data.Lifetime
end

function ProjectileType:GetHitEffects()
    return self._data.HitEffects
end

function ProjectileType:GetDamageEffects()
    return self._data.DamageEffects
end

function ProjectileType:GetBounceSound()
    local bounceData = self:GetBounceData()
    return bounceData and bounceData.Sound or nil
end

return ProjectileType