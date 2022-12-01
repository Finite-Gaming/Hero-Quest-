--- Crosses client-server datastore boundry for settings
-- @classmod SettingsService
-- @author unknown, frick

local cRequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerScriptService = game:GetService("ServerScriptService")

local Network = cRequire("Network")
local SettingsServiceConstants = cRequire("SettingsServiceConstants")

local UserData = require(ServerScriptService.PlayerData.UserData) -- TODO: Move this to use Compliance

local SettingsService = {}

-- Initialize remote functions
function SettingsService:Init()
    Network:GetRemoteFunction(SettingsServiceConstants.GET_SETTING_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player, settingName: string, settingValue: any)
        local profile = UserData:WaitForProfile(player.UserId)

        local data = profile.Data
        local settings = data.Settings

        -- TODO: Validate types
        settings[settingName] = settingValue
    end

    Network:GetRemoteFunction(SettingsServiceConstants.GET_SETTING_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player)
        local profile = UserData:WaitForProfile(player.UserId)

        local data = profile.Data
        local settings = data.Settings

        return settings
    end

    Network:GetRemoteFunction(SettingsServiceConstants.GET_SETTINGS_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player, settingName: string)
        local profile = UserData:WaitForProfile(player.UserId)

        local data = profile.Data
        local settings = data.Settings

        return settings[settingName]
    end
end

return SettingsService