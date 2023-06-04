---
-- @classmod ConfirmationPrompt
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local Signal = require("Signal")

local TweenService = game:GetService("TweenService")

local VISIBLE_POSITION = UDim2.fromScale(0.5, 0.5)
local NOT_VISIBLE_POSITION = UDim2.fromScale(0.5, -0.5)

local SHOW_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HIDE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local ConfirmationPrompt = setmetatable({}, BaseObject)
ConfirmationPrompt.__index = ConfirmationPrompt

function ConfirmationPrompt.new(message)
    local self = setmetatable(BaseObject.new(GuiTemplateProvider:Get("ConfirmationPromptTemplate")), ConfirmationPrompt)

    self.OnResponse = Signal.new()

    self._screenGui = ScreenGuiProvider:Get("ConfirmationPrompt")
    local showTween = self._maid:AddTask(
        TweenService:Create(self._obj, SHOW_TWEEN_INFO, {Position = VISIBLE_POSITION})
    )
    local hideTween = self._maid:AddTask(
        TweenService:Create(self._obj, HIDE_TWEEN_INFO, {Position = NOT_VISIBLE_POSITION})
    )

    self._obj.TextLabel.Text = message
    self._obj.Position = NOT_VISIBLE_POSITION

    self._maid:AddTask(hideTween.Completed:Connect(function()
        self._screenGui:Destroy()
    end))
    self._maid:AddTask(self._obj.YesButton.Activated:Connect(function()
        self.OnResponse:Fire(1)
        self:Destroy()
    end))
    self._maid:AddTask(self._obj.NoButton.Activated:Connect(function()
        self.OnResponse:Fire(0)
        self:Destroy()
    end))
    self._maid:AddTask(self._obj.ExitButton.Activated:Connect(function()
        self.OnResponse:Fire(0)
        self:Destroy()
    end))
    self._maid:AddTask(function()
        hideTween:Play()
    end)

    self._obj.Parent = self._screenGui
    showTween:Play()

    return self
end

return ConfirmationPrompt