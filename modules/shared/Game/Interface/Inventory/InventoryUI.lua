---
-- @classmod InventoryUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local UserDataClient = require("UserDataClient")
local ItemConstants = require("ItemConstants")
local PopulateItemFrame = require("PopulateItemFrame")
local ClientTemplateProvider = require("ClientTemplateProvider")
local HumanoidUtils = require("HumanoidUtils")
local AnimationTrack = require("AnimationTrack")
local ArmorApplier = require("ArmorApplier")
local ConfirmationPrompt = require("ConfirmationPrompt")
local ExitButtonMixin = require("ExitButtonMixin")
local SoundPlayer = require("SoundPlayer")

local UserInputService = game:GetService("UserInputService")

local SETTING_TRANSLATIONS = { -- we should move this to a module later on for sync
    Armors = "Armor";
    Helmets = "Helmet";
    Weapons = "Weapon";
    Pets = "Pet";
    Abilities = "Ability";
}

local InventoryUI = setmetatable({}, BaseObject)
InventoryUI.__index = InventoryUI

function InventoryUI.new(character)
    local self = setmetatable(BaseObject.new(character), InventoryUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("InventoryUI"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("InventoryUITemplate")
    self._subframe = GuiTemplateProvider:Get("InventorySubframeTemplate")
    self._subframe.Visible = false

    self._equippedItems = {}

    self._maid:AddTask(self._subframe.ExitButton.Activated:Connect(function()
        self._selectedCategory = nil
        self._subframe.Visible = false
    end))

    self._viewAngleY, self._viewAngleX = 150, -15

    self._characterViewport = Instance.new("ViewportFrame")

    self._characterViewport.BackgroundTransparency = 1
	self._characterViewport.Size = UDim2.fromScale(1, 1)
	self._characterViewport.AnchorPoint = Vector2.new(0.5, 0.5)
	self._characterViewport.Position = UDim2.fromScale(0.5, 0.5)
	self._characterViewport.LightDirection = Vector3.new(1, -1, 1)

    self._viewportButton = Instance.new("ImageButton")

    self._viewportButton.BackgroundTransparency = 1
    self._viewportButton.Image = ""
	self._viewportButton.Size = UDim2.fromScale(1, 1)
	self._viewportButton.AnchorPoint = Vector2.new(0.5, 0.5)
	self._viewportButton.Position = UDim2.fromScale(0.5, 0.5)
    self._viewportButton.Parent = self._characterViewport

    self._maid:AddTask(self._viewportButton.MouseButton1Down:Connect(function()
        local lastMousePos = UserInputService:GetMouseLocation()
        self._maid.MouseMoveEvent = UserInputService.InputChanged:Connect(function(inputObject)
            if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end

            local mousePos = Vector2.new(inputObject.Position.X, inputObject.Position.Y + 36)
            local delta = lastMousePos - mousePos

            self._viewAngleY += delta.X
            self._viewAngleX = math.clamp(self._viewAngleX + delta.Y, -25, 25)
            self:_updateViewAngle()

            lastMousePos = mousePos
        end)

        self._maid.MouseClickEvent = UserInputService.InputEnded:Connect(function(inputObject)
            if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end

            self._maid.MouseMoveEvent = nil
            self._maid.MouseClickEvent = nil
        end)
    end))

    self._characterModel = ClientTemplateProvider:Get("R15BlockRig")
    self._characterModel:PivotTo(CFrame.identity)
    HumanoidUtils.cleanDescription(self._characterModel.Humanoid)

    self._camera = Instance.new("Camera")
    self._camera.Parent = self._characterViewport
    self:_updateViewAngle()

    self._characterViewport.CurrentCamera = self._camera
    self._characterModel.Parent = self._characterViewport

    self._characterViewport.Parent = self._gui.MainFrame.Border.ViewportContainer

    ExitButtonMixin:Add(self)
    self._gui.Parent = self._screenGui

    self._maid:AddTask(AnimationTrack.new("rbxassetid://507766388", self._characterModel.Humanoid)):Play()

    self._contentFrame = self._subframe.Content
    self._basicHolder = self._contentFrame.BasicHolder
    self._cursedHolder = self._contentFrame.CursedHolder

    self._basicGridLayout = self._basicHolder.ScrollingFrame.PlaceholderFrame.GridLayoutFrame
    self._cursedGridLayout = self._cursedHolder.ScrollingFrame.PlaceholderFrame.GridLayoutFrame

    self._containerMap = {}
    self._gridItemCache = {}

    for _, container in ipairs(self._gui.MainFrame.ItemContainer:GetChildren()) do
        local dataKey = container:GetAttribute("DataKey")
        if not dataKey then
            continue
        end

        self._containerMap[dataKey] = container
        local equipped = UserDataClient:GetEquipped(SETTING_TRANSLATIONS[dataKey])
        self._equippedItems[dataKey] = equipped

        PopulateItemFrame(container.ImageButton.ImageLabel, dataKey, equipped)
        if equipped then
            if dataKey == "Armors" then
                ArmorApplier:ApplyArmor(self._characterModel, equipped)
            elseif dataKey == "Helmets" then
                ArmorApplier:ApplyHelmet(self._characterModel, equipped)
            end
        end

        self._maid:AddTask(container.ImageButton.Activated:Connect(function()
            if self._selectedCategory == dataKey then
                self._subframe.Visible = false
                self._selectedCategory = nil
                return
            end

            local ownedItems = UserDataClient:GetOwnedItems(dataKey)
            self:_clearGridItems()
            self._selectedCategory = dataKey
            for itemKey, data in pairs(ownedItems) do
                self:_addItem(dataKey, itemKey, data)
            end
            self._subframe.Visible = true
        end))
    end

    self._maid:AddTask(self._gui.MainFrame.ItemContainer.Sell.ImageButton.Activated:Connect(function()
        self._inSellMode = not self._inSellMode

        for _, container in pairs(self._gridItemCache) do
            container.ImageButton.QuantityLabel.Visible = not self._inSellMode
            container.ImageButton.SellButton.Visible = self._inSellMode
        end
    end))

    self._subframe.Parent = self._gui -- is canvas groppe

    return self
end

function InventoryUI:_updateViewAngle()
    self._camera.CFrame = CFrame.fromOrientation(math.rad(self._viewAngleX), math.rad(self._viewAngleY), 0) * CFrame.new(0, 0, 5)
end

function InventoryUI:_clearGridItems()
    for _, v in pairs(self._gridItemCache) do
        v.Visible = false
    end
end

function InventoryUI:_addItem(category, itemKey, data)
    local constantData = ItemConstants[category][itemKey]
    local oldItem = self._gridItemCache[itemKey]
    local gridItem = oldItem or GuiTemplateProvider:Get("InventoryGridItemTemplate")

    if not oldItem then
        gridItem.NameLabel.Text = data.DisplayName or constantData.DisplayName
        PopulateItemFrame(gridItem.ImageButton.ImageLabel, category, itemKey)

        self:_bindButton(gridItem.ImageButton, category, itemKey)
        self:_bindButton(gridItem.ImageButton.SellButton, category, itemKey)

        gridItem.ImageButton.SellButton.Visible = self._inSellMode
        gridItem.ImageButton.QuantityLabel.Visible = not self._inSellMode

        self._gridItemCache[itemKey] = gridItem

        if constantData.Cursed then
            gridItem.NameLabel.TextColor3 = Color3.new(0.27, 0, 0.07)
            gridItem.Parent = self._cursedGridLayout
        else
            gridItem.Parent = self._basicGridLayout
        end
    end

    gridItem.ImageButton.QuantityLabel.Text = ("x%i"):format(data.Quantity)
    gridItem.Visible = true
end

function InventoryUI:_bindButton(button, category, itemKey)
    self._maid:AddTask(button.Activated:Connect(function()
        if self._inSellMode then
            if self._sellingInProgress then
                return
            end
            self._sellingInProgress = true
            local prompt = ConfirmationPrompt.new(("Are you sure you want to sell %q?")
                :format(ItemConstants[category][itemKey].DisplayName))

            prompt.OnResponse:Connect(function(code)
                if code == 0 then
                    warn("dont sell item")
                else
                    warn("sell item lol")
                end

                self._sellingInProgress = false
            end)
        else
            local equipped = self._equippedItems[category]
            local toEquip = itemKey
            if equipped == itemKey then
                toEquip = nil
                SoundPlayer:PlaySound("UnequipItem")
            else
                SoundPlayer:PlaySound("EquipItem")
            end

            self._equippedItems[category] = toEquip
            UserDataClient:SetEquipped(SETTING_TRANSLATIONS[category], toEquip)
            PopulateItemFrame(self._containerMap[category].ImageButton.ImageLabel, category, toEquip)

            if category == "Armors" then
                ArmorApplier:ClearArmor(self._characterModel)
                ArmorApplier:ApplyArmor(self._characterModel, toEquip)
            elseif category == "Helmets" then
                ArmorApplier:ClearHelmet(self._characterModel)
                ArmorApplier:ApplyHelmet(self._characterModel, toEquip)
            end
        end
    end))
end

return InventoryUI