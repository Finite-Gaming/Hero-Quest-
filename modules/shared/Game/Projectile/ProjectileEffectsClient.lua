---
-- @classmod ProjectileEffectsClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ProjectileService = require("ProjectileService")

local Players = game:GetService("Players")

local ProjectileEffectsClient = {}

function ProjectileEffectsClient:Init()
    ProjectileService.Hit:Connect(function(projectile, raycastResult)
        local hitEffects = projectile:GetProjectileType():GetHitEffects()

        if hitEffects then
            local part = raycastResult.Instance
            part = if part:IsA("BasePart") then part else nil

            for _, hitEffect in pairs(hitEffects) do
                hitEffect.new(raycastResult.Position, raycastResult.Normal, part)
            end
        end

        -- if projectile:GetOwner() == Players.LocalPlayer then

        -- end
    end)
end

return ProjectileEffectsClient