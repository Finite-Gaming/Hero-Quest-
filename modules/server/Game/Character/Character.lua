---
-- @classmod Character
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ServerClassBinders = require("ServerClassBinders")
local GameManager = require("GameManager")
local QuestDataUtil = require("QuestDataUtil")

local Players = game:GetService("Players")

local Character = setmetatable({}, BaseObject)
Character.__index = Character

function Character.new(obj)
    local self = setmetatable(BaseObject.new(obj), Character)

    self._player = Players:GetPlayerFromCharacter(self._obj)

    ServerClassBinders.PlayerInfoDisplay:Bind(self._obj)
    ServerClassBinders.InventoryUI:Bind(self._obj)
    ServerClassBinders.QuestUI:Bind(self._obj)
    ServerClassBinders.SettingsUI:Bind(self._obj)

    if GameManager:IsLobby() then
        ServerClassBinders.ShopInterface:Bind(self._obj)
        ServerClassBinders.UpgradeUI:Bind(self._obj)
        ServerClassBinders.PlayScreen:Bind(self._obj)
        ServerClassBinders.RedeemCodeUI:Bind(self._obj)
    -- elseif GameManager:IsDungeon() then
    end

    ServerClassBinders.PlayerAbilityUI:BindAsync(self._obj)
    ServerClassBinders.PlayerAbility:Bind(self._obj)
    ServerClassBinders.MainButtonsInterface:Bind(self._obj)

    self._humanoid = self._obj.Humanoid
    self.DamageTracker = ServerClassBinders.DamageTracker:BindAsync(self._humanoid)
    self._maid:AddTask(self.DamageTracker.Damaged:Connect(function(damage, _, _, damageTag)
        QuestDataUtil.increment(self._player, "DamageTaken", damage, damageTag)
    end))

    return self
end

return Character