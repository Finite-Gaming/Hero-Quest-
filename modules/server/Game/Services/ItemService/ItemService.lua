--- Returns data pertaining to items to the client
-- @classmod ItemService
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local ItemServiceConstants = require("ItemServiceConstants")
local UserData = require("UserData")

local secureGetTypes = { -- Hashmap supremacy
    ["Armors"] = true,
    ["Pets"] = true,
    ["Weapons"] = true,
}
local secureSetTypes = {
    ["Armor"] = true,
    ["Pet"] = true,
    ["Weapon"] = true
}

local ItemService = {}

-- Initialize remote functions, return respective data on invoke
function ItemService:Init()
    self._armorEvent = Network:GetRemoteEvent(ItemServiceConstants.ARMOR_EVENT_REMOTE_EVENT_NAME)

    Network:GetRemoteFunction(ItemServiceConstants.GET_ITEMS_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player, itemType)
        assert(typeof(itemType) == "string", "Invalid itemType")
        assert(secureGetTypes[itemType], "Did not receive a secure setting")

        return UserData:GetOwnedItems(player.UserId, itemType)
    end

    Network:GetRemoteFunction(ItemServiceConstants.SET_EQUIPPED_ITEM_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player, itemType, itemKey)
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
    end
end

return ItemService