---
-- @classmod MainButtonsInterface
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ClientClassBinders = require("ClientClassBinders")
local UIBlur = require("UIBlur")
local GuiSparkleEffect = require("GuiSparkleEffect")

local Players = game:GetService("Players")

local MainButtonsInterface = setmetatable({}, BaseObject)
MainButtonsInterface.__index = MainButtonsInterface

function MainButtonsInterface.new(character)
    local self = setmetatable(BaseObject.new(character), MainButtonsInterface)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("MainButtons"))
    self._gui = GuiTemplateProvider:Get("MainButtonsTemplate")

    self._mainFrame = self._gui.MainFrame

    self._maid:AddTask(function()
        UIBlur:SetEnabled(false)
    end)
    self._maid:AddTask(self._mainFrame.PlayButton:GetPropertyChangedSignal("Visible"):Connect(function()
        if self._mainFrame.PlayButton.Visible then
            self._maid.PlaySparkle = GuiSparkleEffect.new(self._mainFrame.PlayButton, Color3.new(1, 0.925490, 0.517647))
        else
            self._maid.PlaySparkle = nil
        end
    end))
    self._maid:AddTask(task.spawn(function()
        local touchGui = Players.LocalPlayer.PlayerGui:WaitForChild("TouchGui", 5)
        if not touchGui then
            return
        end

        local jumpButton = touchGui:WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
        jumpButton.Position = UDim2.fromScale(0.87, 0.87)
        jumpButton.AnchorPoint = Vector2.new(1, 1)
    end))

    self:_setupGui()
    self._gui.Parent = self._screenGui

    return self
end

function MainButtonsInterface:_setupGui()
    self:_bindGui(self._mainFrame.PlayButton, ClientClassBinders.PlayScreen)
    self:_bindGui(self._mainFrame.ShopButton, ClientClassBinders.ShopInterface)
    self:_bindGui(self._mainFrame.InventoryButton, ClientClassBinders.InventoryUI)
    self:_bindGui(self._mainFrame.SettingsButton, ClientClassBinders.SettingsUI)
    self:_bindGui(self._mainFrame.CodeButton, ClientClassBinders.RedeemCodeUI)
    self:_bindGui(self._mainFrame.QuestButton, ClientClassBinders.QuestUI)
end

function MainButtonsInterface:_bindGui(button, binder)
    self._maid:AddTask(task.spawn(function()
        button.Visible = false
        if not binder then
            return
        end
        local class = binder:GetAsync(self._obj, 5)
        if not class then
            return
        end
        button.Visible = true

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
    end))
end

return MainButtonsInterface