---
-- @classmod SettingsUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ExitButtonMixin = require("ExitButtonMixin")
local UIToggle = require("UIToggle")
local UISlider = require("UISlider")
local UserSettingsClient = require("UserSettingsClient")

local SettingsUI = setmetatable({}, BaseObject)
SettingsUI.__index = SettingsUI

function SettingsUI.new(character)
    local self = setmetatable(BaseObject.new(character), SettingsUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("SettingsUI"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("SettingsUITemplate")

    self._mainFrame = self._gui.MainFrame
    self._contentFrame = self._mainFrame.ScrollingFrame.ContentListFrame

    ExitButtonMixin:Add(self)
    self._objectCount = 0

    self._defaultSettings = UserSettingsClient:GetSettings()

    self:Header("Audio")
    self:Setting(UISlider, "Music", "MusicVolume")
    self:Setting(UISlider, "Voicelines", "VoicelineVolume")
    self:Setting(UISlider, "SFX", "SFXVolume")
    self:Setting(UISlider, "Ambient", "AmbientVolume")
    self:Header("Effects")
    self:Setting(UIToggle, "Disable camera shake", "DisableCameraShake")
    self:Setting(UIToggle, "Auto target enemies", "AutoTarget")
    self:Setting(UIToggle, "Reduced shadows", "ReducedShadows")
    self:Setting(UIToggle, "Disable teammates damage hints", "DisableTeamatesDamageHints")

    self._gui.Parent = self._screenGui

    return self
end

function SettingsUI:Header(text)
    self._objectCount += 1
    local object = GuiTemplateProvider:Get("HeaderObjectTemplate")
    object.TextLabel.Text = text
    object.ZIndex = self._objectCount
    object.Parent = self._contentFrame
    return object
end

function SettingsUI:Setting(settingClass, text, settingName)
    local defaultValue = self._defaultSettings[settingName]
    local class = self._maid:AddTask(settingClass.new({Text = text, Value = defaultValue}))

    self._maid:AddTask((class.Released or class.Changed):Connect(function(value)
        UserSettingsClient:SetSetting(settingName, value)
    end))

    local object = class:GetObject()
    object.ZIndex = self._objectCount
    object.Parent = self._contentFrame
end

return SettingsUI