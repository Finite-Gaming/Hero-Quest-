--- Makes remote events/functions if they do not exist
-- @classmod ProjectileCacher
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ProjectileTypeProvider = require("ProjectileTypeProvider")

local NAN_CFRAME = CFrame.new(0/0, 0/0, 0/0)

local ProjectileCacher = {}

function ProjectileCacher:Init()
    self._cache = {}

    for projectileName, _ in pairs(ProjectileTypeProvider:GetTypes()) do
        self._cache[projectileName] = {}
    end
end

function ProjectileCacher:GetProjectile(projectileType)
    local projectile = self._cache[projectileType:GetName()][1]

    if projectile then
        table.remove(self._cache[projectileType:GetName()], 1)
        local trail = projectile:FindFirstChild("Trail")
        if trail then
            trail.Enabled = true
        end

        return projectile
    else
        return self:_makeProjectile(projectileType)
    end
end

function ProjectileCacher:_makeProjectile(projectileType)
    local projectile = projectileType:GetBuilder()()
    projectile.Parent = workspace:WaitForChild("Effects")
    return projectile
end

function ProjectileCacher:StoreProjectile(projectileType, projectile)
    local trail = projectile:FindFirstChild("Trail")
    if trail then
        trail.Enabled = false
    end

    projectile.CFrame = NAN_CFRAME
    table.insert(self._cache[projectileType:GetName()], projectile)
end

return ProjectileCacher