--- Does cool things
-- @classmod StickHitEffect
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")

local BaseObject = require("BaseObject")
local ProjectileCacher = require("ProjectileCacher")
local WeldUtils = require("WeldUtils")

local DELAY_TIME = 1

local StickHitEffect = setmetatable({}, BaseObject)
StickHitEffect.__index = StickHitEffect

function StickHitEffect.new(projectile, part, position) -- Note: This is structured as such since it should not be used like a normal hit effect, this class is only to be used by Projectile.lua under the "if :DoesStick()" statement
    local renderer = projectile:GetRenderer()
    local self = setmetatable(BaseObject.new(renderer:GetObject()), StickHitEffect)

    self._originalSize = self._obj.Size
    self._originalColor = self._obj.Color

    local cframe = renderer:Position(position)
    self._obj.Anchored = false
    self._maid:AddTask(WeldUtils.weld(self._obj, part, cframe:ToObjectSpace(part.CFrame)))

    local newColor = part.Material == Enum.Material.Neon and
        part.Color
    or
        Color3.new()

    local TWEEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    -- god this code is so damn gross i want to GRAAAAAAAAAA
    self._maid:AddTask(TweenService:Create(self._obj, TWEEEN_INFO, {Color = newColor})):Play()
    local trail = self._obj:FindFirstChild("Trail")
    if trail then
        self._originalTrailColor = trail.Color
        local color3Value = self._maid:AddTask(Instance.new("Color3Value"))
        color3Value.Value = trail.Color.Keypoints[1].Value

        self._maid:AddTask(color3Value.Changed:Connect(function()
            trail.Color = ColorSequence.new(color3Value.Value)
        end))
        self._maid:AddTask(TweenService:Create(color3Value, TWEEEN_INFO, {Value = newColor})):Play()
    end

    self._maid:AddTask(function()
        self._obj.Size = self._originalSize
        self._obj.Color = self._originalColor
        if trail then
            trail.Color = self._originalTrailColor
        end

        ProjectileCacher:StoreProjectile(projectile:GetProjectileType(), self._obj)
    end)

    self._maid:AddTask(task.delay(DELAY_TIME, function()
        local sizeTween = self._maid:AddTask(TweenService:Create(self._obj, TWEEEN_INFO, {Size = Vector3.zero}))

        sizeTween.Completed:Connect(function()
            self:Destroy()
        end)
        sizeTween:Play()
    end))

    return self
end

return StickHitEffect