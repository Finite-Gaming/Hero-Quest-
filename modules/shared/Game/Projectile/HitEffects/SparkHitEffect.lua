--- Does cool things
-- @classmod SparkHitEffect
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ClientClassBinders = require("ClientClassBinders")

local SPREAD_ANGLE = math.rad(25)
local SPARKABLE_MATERIALS = {
    [Enum.Material.DiamondPlate] = true;
    [Enum.Material.Metal] = true;
    [Enum.Material.Foil] = true;
}

local SparkHitEffect = setmetatable({}, BaseObject)
SparkHitEffect.__index = SparkHitEffect

function SparkHitEffect.new(position, normal, part)
    if part and not SPARKABLE_MATERIALS[part.Material] then
        return
    end
    if (workspace.CurrentCamera.CFrame.Position - position).Magnitude > 256 then
        return
    end

    local self = setmetatable(BaseObject.new(Instance.new("Attachment")), SparkHitEffect)
    -- This process is a bit jank, we temporarily bind ProjectileOutputBase and destroy it in the same timeframe

    self._randomObject = Random.new()

    self._obj.WorldPosition = position
    self._obj.Parent = workspace.Terrain
    self._obj:SetAttribute("ProjectileType", "Spark")

    local projectileOutput = ClientClassBinders.ProjectileOutputBase:BindAsync(self._obj)
    for _ = 1, math.random(4, 7) do
        projectileOutput:FireLocal(nil, position, self:_getBloomedNormal(position, normal))
    end

    self._obj:Destroy()

    return self
end

function SparkHitEffect:_getBloomedNormal(position, normal)
    return (CFrame.new(
		position,
		position + normal
	) * CFrame.Angles(
		self._randomObject:NextNumber(-SPREAD_ANGLE, SPREAD_ANGLE),
		self._randomObject:NextNumber(-SPREAD_ANGLE, SPREAD_ANGLE),
		0
	)).LookVector
end

return SparkHitEffect