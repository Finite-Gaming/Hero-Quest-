---
-- @classmod ShopInterface
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")

local ShopData = require("ShopData")

local ShopInterface = setmetatable({}, BaseObject)
ShopInterface.__index = ShopInterface

function ShopInterface.new(character)
    local self = setmetatable(BaseObject.new(character), ShopInterface)

    self._orderedElements = {}
    self._displayedElements = {}

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("ShopInterface"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("ShopInterfaceTemplate")

    self:_setupGui()
    self._gui.Parent = self._screenGui

    -- self:SetEnabled(true)

    return self
end

function ShopInterface:SetEnabled(bool)
    self._screenGui.Enabled = bool
end

function ShopInterface:IsEnabled()
    return self._screenGui.Enabled
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
        local itemLayoutOrder = 0

        for _, itemData in pairs(shopCategory.Items) do
            itemLayoutOrder += 1

            local itemGridItem = GuiTemplateProvider:Get("ItemGridItemTemplate")

            itemGridItem.LayoutOrder = itemLayoutOrder
            itemGridItem.TextLabel.Text = itemData.Name
            itemGridItem.Visible = false
            itemGridItem.Parent = self._subframeScrollingFrame

            orderedElements[itemLayoutOrder] = itemGridItem
        end

        self._orderedElements[shopCategory.Key] = orderedElements
    end

    self._mainFrame.ExitButton.Activated:Connect(function()
        self:SetEnabled(false)
        self:_showCategory(self._currentCategory)
    end)

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