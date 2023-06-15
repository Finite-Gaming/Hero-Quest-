---
-- @classmod ItemRewardClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ItemRewardConstants = require("ItemRewardConstants")
local ItemConstants = require("ItemConstants")
local Network = require("Network")
local PopulateItemFrame = require("PopulateItemFrame")

local Players = game:GetService("Players")

local ItemRewardClient = {}

function ItemRewardClient:Init()
    self._screenGui = ScreenGuiProvider:Get("RewardScreenGui")
    self._screenGui.Enabled = false

    self._itemFrames = {}
    self._gui = GuiTemplateProvider:Get("RewardScreenTemplate")

    self:_bindToClose(self._gui:WaitForChild("ExitButton"))
    self:_bindToClose(self._gui:WaitForChild("ClaimButton"))

    self._gui.Parent = self._screenGui

    self._eventQueue = {}
    Players.LocalPlayer.CharacterAdded:Connect(function()
        self:_processQueue()
    end)
    Network:GetRemoteEvent(ItemRewardConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(keyTable, message)
        table.insert(self._eventQueue, {keyTable, message})
        self:_processQueue()
    end)
end

function ItemRewardClient:_processQueue()
    if self._screenGui.Enabled then
        return
    end
    if not Players.LocalPlayer.Character then
        return
    end
    if #self._eventQueue == 0 then
        return
    end

    local keyTable, message = unpack(table.remove(self._eventQueue, 1))
    local header = self._gui:FindFirstChild("Header")
    if header then
        if message then
            self._gui:WaitForChild("Header").TextLabel.Text = message
        else
            self._gui:WaitForChild("Header").TextLabel.Text = "Rewards"
        end
    else
        warn("[ItemRewardClient] - No header!")
    end

    self:_populate(keyTable)
    self._screenGui.Enabled = true
end

function ItemRewardClient:_bindToClose(button)
    button.MouseButton1Click:Connect(function()
        self._screenGui.Enabled = false
        for _, oldFrame in ipairs(self._itemFrames) do
            oldFrame:Destroy()
        end
        table.clear(self._itemFrames)
        self:_processQueue()
    end)
end

function ItemRewardClient:_populate(itemDict)
    for itemCategory, keyTable in pairs(itemDict) do
        if itemCategory == "Money" or itemCategory == "XP" then
            self:_addContainer(itemCategory, nil, keyTable)
            continue
        end
        for itemKey, count in pairs(keyTable) do
            self:_addContainer(itemCategory, itemKey, count)
        end
    end
end

local SUFFIX_OVERRIDES = {
    Money = "$%i";
    XP = "%i";
}

function ItemRewardClient:_addContainer(itemCategory, itemKey, count)
    local itemData = ItemConstants[itemCategory] and ItemConstants[itemCategory][itemKey]
    local itemFrame = GuiTemplateProvider:Get("RewardGridItemTemplate")

    itemFrame.NameLabel.Text = itemData and itemData.DisplayName or itemCategory

    local suffix = SUFFIX_OVERRIDES[itemCategory] or "x%i"
    itemFrame.CountLabel.Text = suffix:format(count)
    PopulateItemFrame(itemFrame.ImageLabel.IconLabel, itemCategory, itemKey)
    itemFrame.LayoutOrder = count

    itemFrame.Parent = self._gui.ScrollingFrame
    table.insert(self._itemFrames, itemFrame)
end

return ItemRewardClient