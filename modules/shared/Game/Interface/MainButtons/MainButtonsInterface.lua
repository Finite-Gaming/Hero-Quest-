---
-- @classmod MainButtonsInterface
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ClientClassBinders = require("ClientClassBinders")
local UIBlur = require("UIBlur")

local MainButtonsInterface = setmetatable({}, BaseObject)
MainButtonsInterface.__index = MainButtonsInterface

function MainButtonsInterface.new(character)
    local self = setmetatable(BaseObject.new(character), MainButtonsInterface)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("MainButtons"))
    self._gui = GuiTemplateProvider:Get("MainButtonsTemplate")

    self:_setupGui()
    self._gui.Parent = self._screenGui

    return self
end

function MainButtonsInterface:_setupGui()
    self._mainFrame = self._gui.MainFrame

    self:_bindGui(self._mainFrame.PlayButton, ClientClassBinders.PlayScreen)
    self:_bindGui(self._mainFrame.ShopButton, ClientClassBinders.ShopInterface)
    self:_bindGui(self._mainFrame.InventoryButton, ClientClassBinders.InventoryUI)
    self:_bindGui(self._mainFrame.CodeButton, ClientClassBinders.RedeemCodeUI)
end

function MainButtonsInterface:_bindGui(button, binder)
    local class = binder:Get(self._obj)
    if not class then
        button.Visible = false
        return
    end

    self._maid:AddTask(button.Activated:Connect(function()
        if self._activeClass and class ~= self._activeClass then
            self._activeClass:SetEnabled(false)
        end

        class:SetEnabled(not class:IsEnabled())
    end))

    self._maid:AddTask(class.EnabledChanged:Connect(function(bool)
        if bool then
            self._activeClass = class
        else
            self._activeClass = nil
        end

        UIBlur:SetEnabled(bool)
    end))
end

return MainButtonsInterface