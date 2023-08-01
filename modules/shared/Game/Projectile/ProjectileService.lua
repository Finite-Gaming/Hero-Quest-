--- Handles all projectiles with a single heartbeat connection
-- @classmod ProjectileService
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

local Signal = require("Signal")

local ProjectileService = {}

function ProjectileService:Init()
    self._projectiles = {}
    self.Hit = Signal.new()

    RunService.Heartbeat:Connect(function(dt)
        for index, projectile in pairs(self._projectiles) do
            if projectile:ShouldUpdate() then
                projectile:Update(dt)
            else
                self._projectiles[index] = nil

                if not projectile:GetProjectileType():DoesStick() then
                    projectile:Destroy()
                end
            end
        end
    end)
end

function ProjectileService:AddProjectile(projectile)
    self._projectiles[#self._projectiles + 1] = projectile
    return projectile
end

return ProjectileService