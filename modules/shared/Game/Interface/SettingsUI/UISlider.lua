---
-- @classmod UISlider
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local GuiTemplateProvider = require("GuiTemplateProvider")
local Signal = require("Signal")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UISlider = setmetatable({}, BaseObject)
UISlider.__index = UISlider

function UISlider.new(settings)
    local self = setmetatable(BaseObject.new(GuiTemplateProvider:Get("SliderObjectTemplate")), UISlider)

    self._settings = settings

    self.Changed = Signal.new()
    self.Released = Signal.new()

    self._inputImage = self._obj.InputImage
    self._textLabel = self._obj.TextLabel
    self._button = self._inputImage.SliderButton
    self._textBox = self._inputImage.TextBox
    self._sliderBar = self._inputImage.SliderBar
    self._accentBar = self._sliderBar.AccentBar

    self._maid:AddTask(self._button.MouseButton1Down:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        self:_update(mousePos)

        local lastMousePos = mousePos
        self._maid.UpdateInput = RunService.RenderStepped:Connect(function()
            mousePos = UserInputService:GetMouseLocation()
            if mousePos == lastMousePos then
                return
            end
            lastMousePos = mousePos

            self:_update(mousePos)
        end)
        self._maid.InputCancel = UserInputService.InputEnded:Connect(function(inputObject)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or
                inputObject.UserInputType == Enum.UserInputType.Touch
            then
                self._maid.UpdateInput = nil
                self._maid.InputCancel = nil
                self.Released:Fire(self:GetValue())
            end
        end)
    end))


    self._maid:AddTask(self._textBox.FocusLost:Connect(function()
        local text = self._textBox.Text:gsub("%%", "")
        local value = tonumber(text) or self._value

        self:SetValue(value)
        self.Released:Fire(self:GetValue())
    end))

    self._textLabel.Text = settings.Text or "Slider"
    self:SetValue(self._settings.Value or 50)

    return self
end

function UISlider:_update(mousePos)
    local xValue = self:_getXScale(mousePos) * 100
    self:SetValue(xValue)
end

function UISlider:_getXScale(mousePos)
    mousePos = mousePos or UserInputService:GetMouseLocation()
    local aSize = self._sliderBar.AbsoluteSize
    local aTopLeft = self._sliderBar.AbsolutePosition
    local aBottomRight = aTopLeft + aSize

    return (math.clamp(mousePos.X, aTopLeft.X, aBottomRight.X) - aTopLeft.X)/aSize.X
end

function UISlider:SetValue(value)
    value = math.round(math.clamp(value, 0, 100))

    self._value = value
    self.Changed:Fire(value)

    self._textBox.Text = ("%i%%"):format(value)
    self._accentBar.Size = UDim2.fromScale(value/100, 1)
end

function UISlider:GetValue()
    return self._value
end

return UISlider