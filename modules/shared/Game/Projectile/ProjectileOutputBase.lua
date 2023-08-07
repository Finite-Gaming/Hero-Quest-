--- Provides an output for projectiles given a projectile type
-- @classmod ProjectileOutputBase
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Projectile = require("Projectile")
local ProjectileService = require("ProjectileService")
local ProjectileTypeProvider = require("ProjectileTypeProvider")
local ProjectileRenderer = require("ProjectileRenderer")
local Raycaster = require("Raycaster")

local ProjectileOutputBase = setmetatable({}, BaseObject)
ProjectileOutputBase.__index = ProjectileOutputBase

function ProjectileOutputBase.new(obj)
    local self = setmetatable(BaseObject.new(obj), ProjectileOutputBase)

    self._projectileType = ProjectileTypeProvider:Get(self._obj:GetAttribute("ProjectileType"))

    return self
end

function ProjectileOutputBase:Ignore(ignoreObject)
    if not self._raycaster then
        self:SetRaycaster(Raycaster.new())
    end

    self._raycaster:Ignore(ignoreObject)
end

function ProjectileOutputBase:SetOwner(player)
    self._owner = player
end

function ProjectileOutputBase:SetRaycaster(raycaster)
    self._raycaster = raycaster
end

function ProjectileOutputBase:Fire(startTick, position, direction)
    local projectile = Projectile.new(self._projectileType, {
        Position = position or self._obj.WorldPosition;
        Direction = direction or -self._obj.WorldCFrame.RightVector;
        StartTick = startTick;
    }, self._owner, self._raycaster)

    ProjectileService:AddProjectile(projectile)
    return projectile
end

function ProjectileOutputBase:FireLocal(startTick, firePos, direction)
    startTick = startTick or workspace:GetServerTimeNow()
    firePos = firePos or self._obj.WorldPosition
    direction = direction or -self._obj.WorldCFrame.RightVector

    local renderer = ProjectileRenderer.new(self._projectileType)
    local projectile = self:Fire(startTick, firePos, direction)
    projectile:SetRenderer(renderer)

    return projectile
end

function ProjectileOutputBase:GetOutput()
    return self._obj
end

function ProjectileOutputBase:GetProjectileType()
    return self._projectileType
end

return ProjectileOutputBase