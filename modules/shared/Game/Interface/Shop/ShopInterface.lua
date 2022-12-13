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

    self._categoryElements = {}
    self._orderedElements = {}

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("ShopInterface"))
    self._screenGui.IgnoreGuiInset = true
    self._gui = GuiTemplateProvider:Get("ShopInterfaceTemplate")

    self:_setupGui()
    self._gui.Parent = self._screenGui

    return self
end

function ShopInterface:_setupGui()
    self._mainFrame = self._gui.MainFrame
    self._scrollingFrame = self._mainFrame.ScrollingFrame

    for layoutOrder, shopCategory in ipairs(ShopData) do
        local gridItem = ScreenGuiProvider:Get("ShopGridItemTemplate")

        gridItem.LayoutOrder = layoutOrder
        gridItem.TextLabel.Text = shopCategory.DisplayName
        gridItem.ImageButton.Activated:Connect(function()
            self:_showCategory(shopCategory.Key)
        end)

        local orderedElements = {}
        local itemLayoutOrder = 0
        for UUID, itemData in pairs(shopCategory.Items) do
            itemLayoutOrder += 1

            local itemGridItem = ScreenGuiProvider:Get("ShopGridItemTemplate")

            itemGridItem.LayoutOrder = itemLayoutOrder
            itemGridItem.TextLabel.Text = itemData.Name
            orderedElements[itemLayoutOrder] = itemGridItem
        end

        self._orderedElements[shopCategory.Key] = orderedElements
        self._categoryElements[shopCategory.Key] = gridItem
    end
end

function ShopInterface:_showCategory(categoryKey)

end

return ShopInterface