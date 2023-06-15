---
-- @classmod EnemyDeathEffect
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local LensFlareEffect = require("LensFlareEffect")

local TweenService = game:GetService("TweenService")

local EnemyDeathEffect = setmetatable({}, BaseObject)
EnemyDeathEffect.__index = EnemyDeathEffect

function EnemyDeathEffect.new(pos)
    local self = setmetatable(BaseObject.new(), EnemyDeathEffect)

    local part = self._maid:AddTask(Instance.new("Part"))

    part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * 2
	part.Transparency = 0
	part.Material =  Enum.Material.ForceField
	part.Color = Color3.fromRGB(255, 255, 255)
	part.Position = pos

    local outTween = self._maid:AddTask(TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {Size = Vector3.one * 20, Transparency = 1}))
    self._maid:AddTask(outTween.Completed:Connect(function()
        self:Destroy()
    end))
	LensFlareEffect.new(pos)

	part.Parent = workspace.Terrain
    outTween:Play()

    return self
end

return EnemyDeathEffect