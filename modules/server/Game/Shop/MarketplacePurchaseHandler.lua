--- Handles item purchases, rewards players who've bought items (unfinished)
-- @classmod MarketplacePurchaseHandler
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local ShopConstants = require("ShopConstants")

-- local MarketplaceService = game:GetService("MarketplaceService")

local MarketplacePurchaseHandler = {}

function MarketplacePurchaseHandler:Init()
    self._remoteEvent = Network:GetRemoteEvent(ShopConstants.REMOTE_EVENT_NAME)

    self._remoteEvent.OnServerEvent:Connect(function(player, itemData)
        
    end)

    -- MarketplaceService.ProcessReceipt = function(receiptData)

    -- end
end

return MarketplacePurchaseHandler