---
-- @classmod UpgradeUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local UserDataClient = require("UserDataClient")
local UpgradePriceUtil = require("UpgradePriceUtil")
local NotificationService = require("NotificationService")
local VoicelineService = require("VoicelineService")
local SoundPlayer = require("SoundPlayer")
local ExitButtonMixin = require("ExitButtonMixin")

local ALIGNMENT_CODES = { -- i know these are confusing just ignore it
    Health = 1;
    Damage = 3;
    MagicDamage = 8;

    AllEqual = 12;
}
local CODE_MAP = {
    [1] = "Tank";
    [3] = "Warrior";
    [8] = "Wizard";

    [4] = "Juggernaut"; -- health + damage
    [9] = "Hefty Wizard"; -- health + magic damage
    [11] = "Battle Wizard";-- damage + magic damage
    [12] = "Living Legend"; -- all
}

-- TODO: cap level (wait for level calculation math)
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
    local upgradeData = UserDataClient:GetUpgradeData()
    local highestLevel = 0

    for upgradeName, upgradeLevel in pairs(upgradeData) do
        if upgradeLevel > highestLevel then
            highestLevel = upgradeLevel
        end

        local container = self._containers[upgradeName]

        container.BuyButton.TextLabel.Text = ("$%i"):format(math.round(UpgradePriceUtil:GetPriceFromLevel(upgradeLevel)))
        container.LevelLabel.TextLabel.Text = ("LVL: %i"):format(upgradeLevel)
    end

    local debugTable = {}
    local compoundCode = 0
    for upgradeName, upgradeLevel in pairs(upgradeData) do
        if upgradeLevel == highestLevel then
            compoundCode += ALIGNMENT_CODES[upgradeName]
            table.insert(debugTable, upgradeName)
        end
    end

    -- dont forget to update level here
    local classAlignment = nil
    if highestLevel == 1 then
        classAlignment = "Newbie"
    else
        local code = CODE_MAP[compoundCode]
        if not code then
            warn("[UpgradeUI] - No code for combination:", debugTable)
            code = "Error"
        end
        classAlignment = code
    end
    self._gui.MainFrame.RedBox.TextLabel.Text = ("Maximum Level: 128\nCurrent Class Alignment: %s")
        :format(classAlignment)
end

function UpgradeUI:_bindButton(button, upgradeName)
    self._maid:AddTask(button.Activated:Connect(function()
        local success, code = UserDataClient:UpgradeStat(upgradeName)

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