--- Shop gui for purchasing items with robux
-- @classmod ShopInterface
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local MarketplaceService = game:GetService("MarketplaceService")

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ShopData = require("ShopData")
local Network = require("Network")
local ShopConstants = require("ShopConstants")
local ExitButtonMixin = require("ExitButtonMixin")

local DEFAULT_THUMBNAIL = "rbxassetid://12017700691" -- Image that will be displayed if an item is missing a thumbnail

local ShopInterface = setmetatable({}, BaseObject)
ShopInterface.__index = ShopInterface

function ShopInterface.new(character)
    local self = setmetatable(BaseObject.new(character), ShopInterface)

    self._remoteEvent = Network:GetRemoteEvent(ShopConstants.REMOTE_EVENT_NAME) -- Process buying items
    -- (this should be changed to a RemoteFunction for user feedback, eg. the request was denied, play boowomp.mp3)

    self._orderedElements = {} -- This table holds each category of item with its respective children
    -- in the proper display order
    self._displayedElements = {} -- This table holds the item gui elements that are currently being displayed

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("ShopInterface"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("ShopInterfaceTemplate")

    self:_setupGui()
    self._gui.Parent = self._screenGui

    -- self:SetEnabled(true)

    return self
end

function ShopInterface:_setupGui()
    self._mainFrame = self._gui.MainFrame
    self._scrollingFrame = self._mainFrame.ScrollingFrame

    self._subframe = GuiTemplateProvider:Get("ShopSubframeTemplate")
    self._subframe.Visible = false
    self._subframe.Parent = self._gui

    self._subframeScrollingFrame = self._subframe.ScrollingFrame

    for layoutOrder, shopCategory in ipairs(ShopData) do
        local gridItem = GuiTemplateProvider:Get("ShopGridItemTemplate")

        gridItem.LayoutOrder = layoutOrder
        gridItem.TextLabel.Text = shopCategory.DisplayName
        gridItem.ImageButton.Activated:Connect(function()
            self:_showCategory(shopCategory.Key)
        end)
        gridItem.Parent = self._scrollingFrame

        local orderedElements = {}

        for itemKey, itemData in pairs(shopCategory.Items) do
            if itemData.NotBuyable then
                continue
            end
            if not itemData.ProductId then
                warn(("[ShopInterface] - Item %q has no ProductId!")
                    :format(itemKey))
                continue
            end

            local itemGridItem = GuiTemplateProvider:Get("ItemGridItemTemplate")
            local imageButton = itemGridItem.ImageButton

            imageButton.ImageLabel.Image = itemData.Thumbnail or DEFAULT_THUMBNAIL
            imageButton.BuyButton.TextLabel.Text = "..."
            task.spawn(function()
                local productInfo = MarketplaceService:GetProductInfo(itemData.ProductId, Enum.InfoType.Product)
                imageButton.BuyButton.TextLabel.Text = ("R$%i"):format(productInfo.PriceInRobux)
            end)

            local function buyProduct() -- Communicate with server, provide user feedback

            end

            local itemLayoutOrder = itemData.LayoutOrder or 1
            itemGridItem.LayoutOrder = itemLayoutOrder
            itemGridItem.TextLabel.Text = itemData.DisplayName
            itemGridItem.Visible = false
            itemGridItem.Parent = self._subframeScrollingFrame

            orderedElements[itemLayoutOrder] = itemGridItem
        end

        self._orderedElements[shopCategory.Key] = orderedElements
    end

    self._mainFrame.ExitButton.Activated:Connect(function()
        self:_showCategory(self._currentCategory)
    end)

    ExitButtonMixin:Add(self)
    self._subframe.ExitButton.Activated:Connect(function()
        self:_showCategory(self._currentCategory)
    end)
end

function ShopInterface:_showCategory(categoryKey)
    if self._currentCategory == categoryKey then
        self._subframe.Visible = false
        self._currentCategory = nil
        return
    end

    self._subframe.Visible = true
    self._currentCategory = categoryKey

    for index, element in ipairs(self._displayedElements) do
        element.Visible = false
        self._displayedElements[index] = nil
    end

    for layoutOrder, itemElement in ipairs(self._orderedElements[categoryKey]) do
        itemElement.Visible = true
        self._displayedElements[layoutOrder] = itemElement
    end
end

return ShopInterface