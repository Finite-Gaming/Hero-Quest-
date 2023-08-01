--- Client projectile simulation
-- @classmod Projectile
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
--local DebugVisualizer = require("DebugVisualizer")
local ProjectilePhysics = require("ProjectilePhysics")
local ProjectileService = require("ProjectileService")
local StickHitEffect = require("StickHitEffect")
local Raycaster = require("Raycaster")
local SoundPlayer = require("SoundPlayer")
local DebugVisualizer = require("DebugVisualizer")

local GRAVITY_FORCE = Vector3.new(0, -workspace.Gravity, 0)
local DESTROY_HEIGHT = workspace.FallenPartsDestroyHeight

local Projectile = setmetatable({}, BaseObject)
Projectile.__index = Projectile

function Projectile.new(projectileType, physicsData, ignoreObject)
    local self = setmetatable(
        BaseObject.new(),
        Projectile
    )

    self._projectileType = projectileType
    self._physicsData = physicsData
    self._startTick = physicsData.StartTick or workspace:GetServerTimeNow()
    self._physics = ProjectilePhysics.new(nil, self._startTick)
    self._physics:SetData(
        self._startTick,
        physicsData.Position,
        self._physicsData.Direction.Unit * self._projectileType:GetSpeed(),
        GRAVITY_FORCE
    )

    self._raycastParams = RaycastParams.new()
    self._raycastParams.IgnoreWater = true -- TODO: Remove this but pass through water so we can do splash effects

    self._raycaster = Raycaster.new(self._raycastParams)
    self._raycaster:Ignore(ignoreObject)
    -- if game:GetService("RunService"):IsServer() then
    --     self._raycaster.Visualize = true
    -- end

    self._active = true
    self._lastPosition = physicsData.Position

    if projectileType:DoesBounce() then
        self._bounceData = self._projectileType:GetBounceData()
        self._bouncesLeft = self._bounceData.Bounces
        self._bounceSound = self._projectileType:GetBounceSound()
    end

    self._maid:AddTask(function()
        if self._projectileRenderer then
            self._projectileRenderer:Destroy()
        end
    end)

    return self
end

function Projectile:SetRenderer(projectileRenderer)
    self._projectileRenderer = projectileRenderer
    self._projectileRenderer:Init(self._physics)
end

function Projectile:Update()
    if not self._firstUpdate then
        self._firstUpdate = true
        return
    end

    local newPos = self._physics.Position
    local result = self._raycaster:Cast(
        self._lastPosition,
        newPos - self._lastPosition
    )

    if result then
        ProjectileService.Hit:Fire(self, result)

        if self._projectileType:DoesBounce() and self._bouncesLeft > 0 then
            local velocity = self._physics.Velocity
            local reflectedNormal = (velocity.Unit - (2 * velocity.Unit:Dot(result.Normal) * result.Normal))
            self._physics.Velocity =
                reflectedNormal *
                (velocity.Magnitude * self._bounceData.VelocityPreserved)
            self._lastPosition = result.Position
            self._physics.Position = result.Position
            self._bouncesLeft -= 1

            if self._bounceSound then
                SoundPlayer:PlaySoundAtPart(SoundPlayer[self._bounceSound], self._obj)
            end

            -- if game:GetService("RunService"):IsServer() then
            --     DebugVisualizer:LookAtPart(result.Position, result.Position + reflectedNormal, 0.5, 0.05).Parent = workspace.Terrain
            -- end

            self:_position()
        else
            if self._projectileType:DoesStick() then
                if self._projectileRenderer then
                    StickHitEffect.new(self, result.Instance, result.Position)
                end
            end

            self._active = false
        end
    else
        self._lastPosition = newPos
        self:_position()
    end
end

function Projectile:_position(...)
    if self._projectileRenderer then
        self._projectileRenderer:Position(...)
    end
end

function Projectile:GetRenderer()
    return self._projectileRenderer
end

function Projectile:ShouldUpdate()
    return self._active and
        self._physics.Age < self._projectileType:GetLifetime() and
        self._physics.Position.Y > DESTROY_HEIGHT
end

function Projectile:GetProjectileType()
    return self._projectileType
end

return Projectile