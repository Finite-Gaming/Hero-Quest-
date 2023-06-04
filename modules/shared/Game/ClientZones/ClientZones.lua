---
-- @classmod ClientZones
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClientClassBinders = require("ClientClassBinders")

local Players = game:GetService("Players")

local ClientZones = {}

function ClientZones:Init()
    local upgradeZone = workspace:WaitForChild("Zones"):WaitForChild("UpgradeZone")
    local upgradeClientZone = ClientClassBinders.ClientZone:BindAsync(upgradeZone)

    upgradeClientZone.OnEnter:Connect(function()
        local character = Players.LocalPlayer.Character

        local upgradeUI = ClientClassBinders.UpgradeUI:Get(character)
        if not upgradeUI then
            return
        end

        upgradeUI:SetEnabled(true)
    end)
    upgradeClientZone.OnLeave:Connect(function()
        local character = Players.LocalPlayer.Character
        if not character then
            return
        end

        local upgradeUI = ClientClassBinders.UpgradeUI:Get(character)
        if not upgradeUI then
            return
        end

        upgradeUI:SetEnabled(false)
    end)
end

return ClientZones