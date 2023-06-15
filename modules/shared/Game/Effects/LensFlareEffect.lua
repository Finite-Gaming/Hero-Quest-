---
-- @classmod LevelUpEffect
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local GuiTemplateProvider = require("GuiTemplateProvider")
local DebugVisualizer = require("DebugVisualizer")

local TweenService = game:GetService("TweenService")

local LevelUpEffect = setmetatable({}, BaseObject)
LevelUpEffect.__index = LevelUpEffect

function LevelUpEffect.new(part, scale, color, lifetime)
    local self = setmetatable(BaseObject.new(GuiTemplateProvider:Get("LensFlareTemplate")), LevelUpEffect)

    if typeof(part) == "Vector3" then
        local position = part
        part = DebugVisualizer:GhostPart()
        part.Position = position
        part.Size = Vector3.zero
        part.Transparency = 1
        part.Parent = workspace.Terrain
    end
    scale = scale or 1
    lifetime = lifetime or 0.225
    local IN_TWEEN_INFO = TweenInfo.new(lifetime * (0.025/0.225), Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
    local OUT_TWEEN_INFO = TweenInfo.new(lifetime * (0.2/0.225), Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

    self._maid:AddTask(self._obj)

    local originalSize = self._obj.Size
    local scaledSize = UDim2.fromScale(originalSize.X.Scale * scale, originalSize.Y.Scale * scale)
    self._tweenIn = self._maid:AddTask(TweenService:Create(
        self._obj,
        IN_TWEEN_INFO,
        {Size = scaledSize}
    ))
    self._tweenOut = self._maid:AddTask(TweenService:Create(
        self._obj,
        OUT_TWEEN_INFO,
        {Size = UDim2.fromScale(0, 0)}
    ))
    self._maid:AddTask(self._tweenIn.Completed:Connect(function()
        self._tweenOut:Play()
    end))
    self._maid:AddTask(self._tweenOut.Completed:Connect(function()
        self:Destroy()
    end))

    self._obj.Size = UDim2.fromScale(0, 0)
    self._obj.ImageLabel.ImageColor3 = color or Color3.new(1, 1, 1)

    self._obj.Parent = part
    self._maid:AddTask(TweenService:Create(self._obj.ImageLabel, IN_TWEEN_INFO, {ImageTransparency = 0.2})):Play()
    self._tweenIn:Play()

    return self
end

return LevelUpEffect