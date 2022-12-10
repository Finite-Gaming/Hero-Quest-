---
-- @classmod PlayerInfoDisplay
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")

local PlayerInfoDisplay = setmetatable({}, BaseObject)
PlayerInfoDisplay.__index = PlayerInfoDisplay

function PlayerInfoDisplay.new(character)
    local self = setmetatable(BaseObject.new(character), PlayerInfoDisplay)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("PlayerInfoDisplay"))
    self._screenGui.IgnoreGuiInset = true
    self._gui = GuiTemplateProvider:Get("PlayerInfoDisplayTemplate")

    self:_setupGui()
    self._gui.Parent = self._screenGui

    self._humanoid = self._obj:WaitForChild("Humanoid")
    self._maxHealth = self._humanoid.MaxHealth

    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        self._maxHealth = self._humanoid.MaxHealth
    end))
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        self:_updateSlider(self._healthBar, math.clamp(self._humanoid.Health, 0, self._maxHealth), self._maxHealth)
    end))

    return self
end

function PlayerInfoDisplay:_setupGui()
    self._mainFrame = self._gui.MainFrame
    self._portraitImage = self._mainFrame.Portrait
    self._sliders = self._mainFrame.Sliders
    self._playerLabel = self._mainFrame.NameLabel

    self._healthBar = self._sliders.HealthBar
    self._experienceBar = self._sliders.ExperienceBar
    self._currencyBar = self._sliders.CurrencyBar
end

function PlayerInfoDisplay:_updateSlider(slider, value, maxValue)
    local percent = value/maxValue
    local displayText = ("%i/%i"):format(math.round(value), math.round(maxValue))

    slider.Label.Text = displayText
    slider.AccentBar.Size = UDim2.fromScale(percent, 1)
end

return PlayerInfoDisplay