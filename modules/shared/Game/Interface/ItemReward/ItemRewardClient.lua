---
-- @classmod ItemRewardClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ItemRewardConstants = require("ItemRewardConstants")
local ItemConstants = require("ItemConstants")
local Network = require("Network")

local DEFAULT_THUMBNAIL = "rbxassetid://12017700691"

local ItemRewardClient = {}

function ItemRewardClient:Init()
    self._screenGui = ScreenGuiProvider:Get("RewardScreenGui")
    self._screenGui.Enabled = false

    self._itemFrames = {}
    self._gui = GuiTemplateProvider:Get("RewardScreenTemplate")

    self:_bindToClose(self._gui.ExitButton)
    self:_bindToClose(self._gui.ClaimButton)

    self._gui.Parent = self._screenGui

    Network:GetRemoteEvent(ItemRewardConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(keyTable)
        self:_populate(keyTable)
        self._screenGui.Enabled = true
    end)
end

function ItemRewardClient:_bindToClose(button)
    button.MouseButton1Click:Connect(function()
        self._screenGui.Enabled = false
        for _, oldFrame in ipairs(self._itemFrames) do
            oldFrame:Destroy()
        end
        table.clear(self._itemFrames)
    end)
end

function ItemRewardClient:_populate(itemDict)
    for itemCategory, keyTable in pairs(itemDict) do
        for itemKey, count in pairs(keyTable) do
            local itemData = ItemConstants[itemCategory][itemKey]
            local itemFrame = GuiTemplateProvider:Get("RewardGridItemTemplate")
            itemFrame.NameLabel.Text = itemData.DisplayName or itemKey
            itemFrame.CountLabel.Text = ("x%i"):format(count)
            itemFrame.IconLabel.Image = itemData.Thumbnail or DEFAULT_THUMBNAIL
            itemFrame.LayoutOrder = count

            itemFrame.Parent = self._gui.ScrollingFrame
            table.insert(self._itemFrames, itemFrame)
        end
    end
end

return ItemRewardClient