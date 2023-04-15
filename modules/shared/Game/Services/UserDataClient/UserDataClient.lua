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
    self:_addMethod("SetSetting", Network:GetRemoteFunction(UserDataServiceConstants.SET_SETTING_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetSetting", Network:GetRemoteFunction(UserDataServiceConstants.GET_SETTING_REMOTE_FUNCTION_NAME))
    self:_addMethod("GetSettings", Network:GetRemoteFunction(UserDataServiceConstants.GET_SETTINGS_REMOTE_FUNCTION_NAME))
    self:_addMethod("HasPlayedDungeon", Network:GetRemoteFunction(UserDataServiceConstants.HAS_PLAYED_DUNGEON_REMOTE_FUNCTION_NAME))

    self._hasBeatenDungeon = Network:GetRemoteFunction(UserDataServiceConstants.HAS_BEATEN_DUNGEON_REMOTE_FUNCTION_NAME)
end

function UserDataClient:HasBeatenDungeon()
    if RunService:IsStudio() then
        return StudioDebugConstants.SimulateRecurringPlayer
    end

    return self._hasBeatenDungeon:InvokeServer()
end

function UserDataClient:_addMethod(methodName, remoteFunction) -- we typecheck on server soooo.. WE BALL!
    self[methodName] = function(...)
        return remoteFunction:InvokeServer(...)
    end
end

return UserDataClient