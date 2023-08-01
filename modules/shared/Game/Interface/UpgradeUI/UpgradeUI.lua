---
-- @classmod UpgradeUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local UpgradePriceUtil = require("UpgradePriceUtil")
local NotificationService = require("NotificationService")
local VoicelineService = require("VoicelineService")
local SoundPlayer = require("SoundPlayer")
local PlayerLevelCalculator = require("PlayerLevelCalculator")
local ExitButtonMixin = require("ExitButtonMixin")
local EffectPlayerClient = require("EffectPlayerClient")
local UserUpgradesClient = require("UserUpgradesClient")

-- TODO: cap level?
local UpgradeUI = setmetatable({}, BaseObject)
UpgradeUI.__index = UpgradeUI

function UpgradeUI.new(character)
    local self = setmetatable(BaseObject.new(character), UpgradeUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("UpgradeUI"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("UpgradeUITemplate")

    self._containers = {}
    for _, upgradeName in ipairs({"Damage", "Health", "MagicDamage"}) do
        local container = self._gui.MainFrame.ItemContainer[upgradeName]
        self._containers[upgradeName] = container
        self:_bindContainer(container, upgradeName)
    end
    self:_updateLabels()

    ExitButtonMixin:Add(self)
    self._gui.Parent = self._screenGui

    return self
end

function UpgradeUI:_bindContainer(container, upgradeName)
    self:_bindButton(container.BuyButton, upgradeName)
    self:_bindButton(container.ImageButton, upgradeName)
end

function UpgradeUI:_updateLabels()
    local upgradeData = UserUpgradesClient:GetUpgradeData()

    for upgradeName, upgradeLevel in pairs(upgradeData) do
        local container = self._containers[upgradeName]

        container.BuyButton.TextLabel.Text = ("$%i"):format(math.round(UpgradePriceUtil:GetPriceFromLevel(upgradeLevel)))
        container.LevelLabel.TextLabel.Text = ("LVL: %i"):format(upgradeLevel)
    end

    local classAlignment = PlayerLevelCalculator:GetClassAlignment(upgradeData)
    self._gui.MainFrame.RedBox.TextLabel.Text = ("Current Class Alignment: %s")
        :format(classAlignment)
end

function UpgradeUI:_bindButton(button, upgradeName)
    self._maid:AddTask(button.Activated:Connect(function()
        local success, code = UserUpgradesClient:UpgradeStat(upgradeName)

        if success then
            local buttonSound = button.Parent:GetAttribute("ButtonSound")
            if buttonSound then
                SoundPlayer:PlaySound(buttonSound, function()
                    local voiceline = button.Parent:GetAttribute("Voiceline")
                    if voiceline and math.random(1, 4) == 4 then
                        VoicelineService:PlayGroupForZone(voiceline, "UpgradeUI")
                    end
                end)
            end

            local humanoid = self._obj:FindFirstChild("Humanoid")
            if humanoid then
                local rootPart = humanoid.rootPart
                if rootPart then
                    EffectPlayerClient:PlayEffect(("%sUpgrade"):format(upgradeName), rootPart.Position + Vector3.new(0, -humanoid.HipHeight, 0))
                end
            end

            self:_updateLabels()
        else
            if code == "Insufficent funds" then
                VoicelineService:PlayGroupForZone("UpgradeInsufficentFunds", "UpgradeUI")
            end
        end

        NotificationService:Notify(code, success and "Success" or "Error")
    end))
end

return UpgradeUI