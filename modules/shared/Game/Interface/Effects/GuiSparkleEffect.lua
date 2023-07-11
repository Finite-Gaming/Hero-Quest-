---
-- @classmod GuiSparkleEffect
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local GuiTemplateProvider = require("GuiTemplateProvider")

local TweenService = game:GetService("TweenService")

local GuiSparkleEffect = setmetatable({}, BaseObject)
GuiSparkleEffect.__index = GuiSparkleEffect

function GuiSparkleEffect.new(obj, color)
    local self = setmetatable(BaseObject.new(obj), GuiSparkleEffect)

    self._randomObject = Random.new()
    self._color = color

    self._maid:AddTask(task.spawn(function()
        while true do
            self:_sparkle()

            task.wait(0.2)
        end
    end))

    return self
end

function GuiSparkleEffect:_sparkle()
    local sparkle = self._maid:AddTask(GuiTemplateProvider:Get("SparkleTemplate"))
    sparkle.ImageColor3 = self._color or Color3.new(1, 1, 1)

    local size = UDim2.fromScale(self._randomObject:NextNumber(0.11, 0.18), 1)
    local position = UDim2.fromScale(self._randomObject:NextNumber(), self._randomObject:NextNumber())

    sparkle.Position = position
    sparkle.ImageTransparency = 1
    sparkle.Size = UDim2.fromScale(0, 0)

    local tween = self._maid:AddTask(TweenService:Create(
        sparkle,
        TweenInfo.new(
            self._randomObject:NextNumber(1.1, 1.4),
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            0,
            true,
            0
        ),
        {ImageTransparency = -0.2, Size = size}
    ))
    self._maid:AddTask(tween.Completed:Connect(function()
        tween:Destroy()
        tween = nil
    end))

    sparkle.Parent = self._obj
    tween:Play()
end

return GuiSparkleEffect