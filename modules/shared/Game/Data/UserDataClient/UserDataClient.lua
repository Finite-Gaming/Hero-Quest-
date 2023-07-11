---
-- @classmod UserDataClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local UserDataServiceConstants = require("UserDataServiceConstants")
local StudioDebugConstants = require("StudioDebugConstants")

local RunService = game:GetService("RunService")

local UserDataClient = {}

function UserDataClient:Init()
    self:_addMethod("GetOwnedItems", Network:GetRemoteFunction(UserDataServiceConstants.GET_ITEMS_REMOTE_FUNCTION_NAME))
    self:_addMethod("SetEquipped", Network:GetRemoteFunction(UserDataServiceConstants.SET_EQUIPPED_ITEM_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetEquipped", Network:GetRemoteFunction(UserDataServiceConstants.GET_EQUIPPED_ITEM_REMOTE_FUNCTION_NAME))
    self:_addMethod("SetSetting", Network:GetRemoteFunction(UserDataServiceConstants.SET_SETTING_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetSetting", Network:GetRemoteFunction(UserDataServiceConstants.GET_SETTING_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetSettings", Network:GetRemoteFunction(UserDataServiceConstants.GET_SETTINGS_REMOTE_FUNCTION_NAME))
    self:_addMethod("HasPlayedDungeon", Network:GetRemoteFunction(UserDataServiceConstants.HAS_PLAYED_DUNGEON_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetNextDungeon", Network:GetRemoteFunction(UserDataServiceConstants.GET_NEXT_DUNGEON_REMOTE_FUNCTION_NAME))
    self:_addMethod("RedeemCode", Network:GetRemoteFunction(UserDataServiceConstants.REDEEM_CODE_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetUpgradeLevel", Network:GetRemoteFunction(UserDataServiceConstants.GET_UPGRADE_LEVEL_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetUpgradeData", Network:GetRemoteFunction(UserDataServiceConstants.GET_UPGRADE_DATA_REMOTE_FUNCTION_NAME))
    self:_addMethod("UpgradeStat", Network:GetRemoteFunction(UserDataServiceConstants.UPGRADE_STAT_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetExperience", Network:GetRemoteFunction(UserDataServiceConstants.GET_EXPERIENCE_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetMoney", Network:GetRemoteFunction(UserDataServiceConstants.GET_MONEY_REMOTE_FUNCTION_NAME))
    self:_addMethod("IsFirstTimer", Network:GetRemoteFunction(UserDataServiceConstants.IS_FIRST_TIMER_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetQuestData", Network:GetRemoteFunction(UserDataServiceConstants.GET_QUEST_DATA_REMOTE_FUNCTION_NAME))

    self._hasBeatenDungeon = Network:GetRemoteFunction(UserDataServiceConstants.HAS_BEATEN_DUNGEON_REMOTE_FUNCTION_NAME)
end

function UserDataClient:HasBeatenDungeon()
    if RunService:IsStudio() and StudioDebugConstants.SimulateNewPlayer then
        return true
    end

    return self._hasBeatenDungeon:InvokeServer()
end

function UserDataClient:_addMethod(methodName, remoteFunction) -- we typecheck on server soooo.. WE BALL!
    self[methodName] = function(self, ...)
        if methodName == "UpgradeStat" then
            print(...)
        end
        return remoteFunction:InvokeServer(...)
    end
end

return UserDataClient