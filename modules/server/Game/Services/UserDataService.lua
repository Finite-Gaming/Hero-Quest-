---
-- @classmod UserDataService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local UserDataServiceConstants = require("UserDataServiceConstants")
local UserData = require("UserData")

local secureGetTypes = {
    ["Armors"] = true,
    ["Pets"] = true,
    ["Weapons"] = true,
}
local secureSetTypes = {
    ["Armor"] = true,
    ["Pet"] = true,
    ["Weapon"] = true
}

local UserDataService = {}

function UserDataService:Init()
    do -- items
        self:_connectRemote(UserDataServiceConstants.GET_ITEMS_REMOTE_FUNCTION_NAME, function(player, itemType)
            assert(typeof(itemType) == "string", "Invalid itemType")
            assert(secureGetTypes[itemType], "Did not receive a secure setting")

            return UserData:GetOwnedItems(player.UserId, itemType)
        end)

        self:_connectRemote(UserDataServiceConstants.SET_EQUIPPED_ITEM_REMOTE_FUNCTION_NAME, function(player, itemType, itemKey)
            assert(typeof(itemType) == "string", "Invalid itemType")
            assert(secureSetTypes[itemType], "Did not receive a secure setting")
            assert(typeof(itemKey) == "string", "Invalid itemKey")
            warn('req for', itemKey)

            if UserData:HasItem(player.UserId, itemType, itemKey) then
                UserData:UpdateEquipped(player.UserId, itemType, itemKey)
                return true
            else
                return false
            end
            -- TODO finish setting armor/validating they own
        end)
    end

    do -- settings
        self:_connectRemote(UserDataServiceConstants.SET_SETTING_REMOTE_FUNCTION_NAME, function(player, settingName, settingValue)
            local profile = UserData:WaitForProfile(player.UserId)

            local data = profile.Data
            local settings = data.Settings

            -- TODO: Validate types
            settings[settingName] = settingValue
        end)

        self:_connectRemote(UserDataServiceConstants.GET_SETTING_REMOTE_FUNCTION_NAME, function(player)
            local profile = UserData:WaitForProfile(player.UserId)

            local data = profile.Data
            local settings = data.Settings

            return settings
        end)

        self:_connectRemote(UserDataServiceConstants.GET_SETTINGS_REMOTE_FUNCTION_NAME, function(player, settingName)
            local profile = UserData:WaitForProfile(player.UserId)

            local data = profile.Data
            local settings = data.Settings

            return settings[settingName]
        end)
    end

    do -- misc data
        self:_connectRemote(UserDataServiceConstants.HAS_BEATEN_DUNGEON_REMOTE_FUNCTION_NAME, function(player)
            return UserData:WaitForProfile(player.UserId).Data.DungeonsCompleted[workspace:GetAttribute("DungeonTag")] ~= nil
        end)

        self:_connectRemote(UserDataServiceConstants.HAS_PLAYED_DUNGEON_REMOTE_FUNCTION_NAME, function(player)
            return UserData:WaitForProfile(player.UserId).Data.DungeonsPlayed[workspace:GetAttribute("DungeonTag")] ~= nil
        end)
    end
end

function UserDataService:_connectRemote(remoteFunctionName, onInvoke)
    Network:GetRemoteFunction(remoteFunctionName).OnServerInvoke = onInvoke
end

return UserDataService