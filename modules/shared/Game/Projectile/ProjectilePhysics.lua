--- Projectile physics
-- @classmod ProjectilePhysics
-- @author

local ProjectilePhysics = {}
ProjectilePhysics.__index = ProjectilePhysics

function ProjectilePhysics.new(initial)
	local self = setmetatable({}, ProjectilePhysics)

	initial = initial or Vector3.zero

	rawset(self, "_position0", initial)
	rawset(self, "_velocity0", 0 * initial)
	rawset(self, "_acceleration", 0 * initial)
	rawset(self, "_time0", workspace:GetServerTimeNow())
	rawset(self, "_creationTime", os.clock())

	return self
end

function ProjectilePhysics:SetData(startTime, position0, velocity0, acceleration)
	rawset(self, "_time0", startTime)
	rawset(self, "_position0", position0)
	rawset(self, "_velocity0", velocity0)
	rawset(self, "_acceleration", acceleration)
end

function ProjectilePhysics:__index(index)
	local time = workspace:GetServerTimeNow()

	if ProjectilePhysics[index] then
		return ProjectilePhysics[index]
	elseif index == "Position" then
		local position, _ = self:_positionVelocity(time)
		return position
	elseif index == "Velocity" then
		local _, velocity = self:_positionVelocity(time)
		return velocity
	elseif index == "Acceleration" then
		return rawget(self, "_acceleration")
	elseif index == "StartTime" then
		return rawget(self, "_time0")
	elseif index == "StartPosition" then
		return rawget(self, "_position0")
	elseif index == "StartVelocity" then
		return rawget(self, "_velocity0")
	elseif index == "Age" then
		return os.clock() - rawget(self, "_creationTime")
	else
		error(("%q is not a valid member of ProjectilePhysics"):format(tostring(index)))
	end
end

function ProjectilePhysics:__newindex(index, value)
	local time = workspace:GetServerTimeNow()

	if index == "Position" then
		local _, velocity = self:_positionVelocity(time)
		rawset(self, "_position0", value)
		rawset(self, "_velocity0", velocity)
	elseif index == "Velocity" then
		local position, _ = self:_positionVelocity(time)
		rawset(self, "_position0", position)
		rawset(self, "_velocity0", value)
	elseif index == "Acceleration" then
		local position, velocity = self:_positionVelocity(time)
		rawset(self, "_position0", position)
		rawset(self, "_velocity0", velocity)
		rawset(self, "_acceleration", value)
	else
		error(("%q is not a valid member of ProjectilePhysics"):format(tostring(index)), 2)
	end
	rawset(self, "_time0", time)
end

function ProjectilePhysics:_positionVelocity(time)
	local dt = time - rawget(self, "_time0")
	local a0 = rawget(self, "_acceleration")
	local v0 = rawget(self, "_velocity0")
	local p0 = rawget(self, "_position0")
	return p0 + v0 * dt + 0.5 * dt * dt * a0,
	       v0 + a0 * dt
end

return ProjectilePhysics
