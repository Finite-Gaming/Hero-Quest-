---
-- @classmod UIToggle
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local GuiTemplateProvider = require("GuiTemplateProvider")
local Signal = require("Signal")

local UIToggle = setmetatable({}, BaseObject)
UIToggle.__index = UIToggle

function UIToggle.new(settings)
    local self = setmetatable(BaseObject.new(GuiTemplateProvider:Get("ToggleObjectTemplate")), UIToggle)

    self._settings = settings

    self.Changed = Signal.new()

    self._button = self._obj.ImageButton
    self._textLabel = self._obj.TextLabel
    self._maid:AddTask(self._button.Activated:Connect(function()
        self:SetValue(not self:GetValue())
    end))

    self._textLabel.Text = settings.Text or "Toggle"
    self:SetValue(self._settings.Value or false)

    return self
end

function UIToggle:SetValue(value)
    self._value = value
    self.Changed:Fire(value)

    if value then
        self._button.ImageTransparency = 0
    else
        self._button.ImageTransparency = 1
    end
end

function UIToggle:GetValue()
    return self._value
end

return UIToggle