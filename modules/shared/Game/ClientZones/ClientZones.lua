---
-- @classmod ClientZones
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClientClassBinders = require("ClientClassBinders")

local Players = game:GetService("Players")

local ClientZones = {}

function ClientZones:Init()
    local zones = workspace:WaitForChild("Zones")

    self:_bindZone(zones:WaitForChild("UpgradeZone"), ClientClassBinders.UpgradeUI)
    -- self:_bindZone(zones:WaitForChild("QuestZone"), ClientClassBinders.QuestUI)
end

function ClientZones:_bindZone(zone, uiBinder)
    local upgradeClientZone = ClientClassBinders.ClientZone:BindAsync(zone)
    upgradeClientZone.OnEnter:Connect(function()
        local character = Players.LocalPlayer.Character

        local uiObject = uiBinder:Get(character)
        if not uiObject then
            return
        end

        uiObject:SetEnabled(true)
    end)
    upgradeClientZone.OnLeave:Connect(function()
        local character = Players.LocalPlayer.Character
        if not character then
            return
        end

        local uiObject = uiBinder:Get(character)
        if not uiObject then
            return
        end

        uiObject:SetEnabled(false)
    end)
end

return ClientZones