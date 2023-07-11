---
-- @classmod UserSettingsClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataClient = require("UserDataClient")

local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local function soundGroupChanger(soundGroupName)
    return function(value)
        SoundService[soundGroupName].Volume = value/100
    end
end

local UserSettingsClient = {}

function UserSettingsClient:Init()
    self._settings = UserDataClient:GetSettings()
    self._methods = {}

    self:_addMethod("MusicVolume", soundGroupChanger("Music"))
    self:_addMethod("VoicelineVolume", soundGroupChanger("Voicelines"))
    self:_addMethod("SFXVolume", soundGroupChanger("SFX"))
    self:_addMethod("AmbientVolume", soundGroupChanger("Ambient"))

    self:_addMethod("ReducedShadows", function(value)
        Lighting.GlobalShadows = not value
    end)
end

function UserSettingsClient:_addMethod(settingName, method)
    self._methods[settingName] = method
    method(self._settings[settingName])
end

function UserSettingsClient:GetSettings()
    return self._settings
end

function UserSettingsClient:GetSetting(settingName)
    return self._settings[settingName]
end

function UserSettingsClient:SetSetting(settingName, value)
    self._settings[settingName] = value
    local changeMethod = self._methods[settingName]
    if changeMethod then
        changeMethod(value)
    end

    task.spawn(function()
        UserDataClient:SetSetting(settingName, value)
    end)
end

return UserSettingsClient