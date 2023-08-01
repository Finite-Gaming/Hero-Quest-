---
-- @classmod ProjectileHitHandler
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ProjectileService = require("ProjectileService")

local ProjectileHitHandler = {}

function ProjectileHitHandler:Init()
    ProjectileService.Hit:Connect(function(projectile, raycastResult)
        for _, damageEffect in ipairs(projectile:GetProjectileType():GetDamageEffects() or {}) do
            damageEffect:Apply(raycastResult)
        end
    end)
end

return ProjectileHitHandler