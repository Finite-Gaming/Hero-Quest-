--- Client projectile simulation
-- @classmod ProjectileRenderer
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ProjectileCacher = require("ProjectileCacher")

local ProjectileRenderer = setmetatable({}, BaseObject)
ProjectileRenderer.__index = ProjectileRenderer

function ProjectileRenderer.new(projectileType)
    local self = setmetatable(
        BaseObject.new(ProjectileCacher:GetProjectile(projectileType)),
        ProjectileRenderer
    )

    self._projectileType = projectileType

    return self
end

function ProjectileRenderer:Init(projectilePhysics)
    self._projectilePhysics = projectilePhysics

    self:Position(self._projectilePhysics.StartPosition, self._projectilePhysics.StartVelocity)
end

function ProjectileRenderer:Position(position, velocity)
    position = position or self._projectilePhysics.Position
    velocity = velocity or self._projectilePhysics.Velocity

    position += velocity.Unit * (self._obj.Size.Z/2)
    local cframe = CFrame.lookAt(position, position + velocity)

    self._obj.CFrame = cframe

    return cframe
end

function ProjectileRenderer:Destroy()
    ProjectileCacher:StoreProjectile(self._projectileType, self._obj)
end

return ProjectileRenderer