--- Does cool things
-- @classmod ExplosionHitEffect
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")

local BaseObject = require("BaseObject")
local ClientClassBinders = require("ClientClassBinders")
local DebugVisualizer = require("DebugVisualizer")

local EXPLOSION_COLOR = Color3.new(0.7, 0.4)
local SPREAD_ANGLE = math.rad(40)

local ExplosionHitEffect = setmetatable({}, BaseObject)
ExplosionHitEffect.__index = ExplosionHitEffect

function ExplosionHitEffect.new(position, normal, part)
    local self = setmetatable(BaseObject.new(Instance.new("Attachment")), ExplosionHitEffect)

    self._maid:AddTask(self._obj)
    self._randomObject = Random.new()

    local explosionPart = self._maid:AddTask(DebugVisualizer:GhostPart())

    explosionPart.Shape = Enum.PartType.Ball
    explosionPart.Color = EXPLOSION_COLOR
    explosionPart.Material = Enum.Material.Neon
    explosionPart.Size = Vector3.zero
    explosionPart.Position = position

    local sizeTween = self._maid:AddTask(TweenService:Create(
        explosionPart,
        TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Size = Vector3.one * 16}
    ))

    local colorTween = self._maid:AddTask(TweenService:Create(
        explosionPart,
        TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Color = EXPLOSION_COLOR:Lerp(Color3.new(1, 1, 1), 0.3), Transparency = 0.2}
    ))

    sizeTween.Completed:Connect(function()
        local fadeTween = self._maid:AddTask(TweenService:Create(
            explosionPart,
            TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Size = Vector3.one * 8, Transparency = 1}
        ))

        fadeTween.Completed:Connect(function()
            self:Destroy()
        end)

        task.delay(0.3, function()
            fadeTween:Play()
        end)
    end)

    task.delay(0.3, function()
        colorTween:Play()
    end)

    explosionPart.Parent = workspace.Terrain
    sizeTween:Play()

    self._obj.WorldPosition = position
    self._obj:SetAttribute("ProjectileType", "Debris")
    self._obj.Parent = workspace.Terrain

    local projectileOutput = ClientClassBinders.ProjectileOutputBase:BindAsync(self._obj)
    for _ = 1, self._randomObject:NextInteger(7, 12) do
        local renderer = projectileOutput:FireLocal(nil, position, self:_getBloomedNormal(position, normal)):GetRenderer()
        local projectileObject = renderer:GetObject()

        projectileObject.Material = part.Material
        projectileObject.Color = part.Color
        projectileObject.Transparency = part.Transparency
    end
end

function ExplosionHitEffect:_getBloomedNormal(position, normal)
    return (CFrame.new(
		position,
		position + normal
	) * CFrame.Angles(
		self._randomObject:NextNumber(-SPREAD_ANGLE, SPREAD_ANGLE),
		self._randomObject:NextNumber(-SPREAD_ANGLE, SPREAD_ANGLE),
		0
	)).LookVector
end

return ExplosionHitEffect