---
-- @classmod RedeemCodeUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local UserDataClient = require("UserDataClient")
local NotificationService = require("NotificationService")
local ExitButtonMixin = require("ExitButtonMixin")
local SoundPlayer = require("SoundPlayer")
local ConfirmationPrompt = require("ConfirmationPrompt")

local RedeemCodeUI = setmetatable({}, BaseObject)
RedeemCodeUI.__index = RedeemCodeUI

function RedeemCodeUI.new(character)
    local self = setmetatable(BaseObject.new(character), RedeemCodeUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("RedeemCodeUI"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("RedeemCodeUITemplate")

    self._maid:AddTask(self._gui.MainFrame.RedeemButton.Activated:Connect(function()
        local rewardCode = self._gui.MainFrame.InputImage.TextBox.Text
        if rewardCode == "RESET_DATA" then
            local prompt = self._maid:AddTask(ConfirmationPrompt.new("Are you sure you would like to reset your data? (This cannot be undone)"))

            local response = self._maid:AddTask(prompt.OnResponse:Wait())
            if response ~= 1 then
                return
            end
        end
        local success, code = UserDataClient:RedeemCode(rewardCode)

        local notificationType = success and "Success" or "Error"
        NotificationService:Notify(code, notificationType)
        if success then
            SoundPlayer:PlaySound("RedeemCode")
        end
    end))

    ExitButtonMixin:Add(self)
    self._gui.Parent = self._screenGui

    return self
end

return RedeemCodeUI