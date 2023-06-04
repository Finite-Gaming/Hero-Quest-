---
-- @classmod CharacterClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ClientClassBinders = require("ClientClassBinders")
local GameManager = require("GameManager")

local Players = game:GetService("Players")

local CharacterClient = setmetatable({}, BaseObject)
CharacterClient.__index = CharacterClient

function CharacterClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), CharacterClient)

    local localCharacter = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    if self._obj ~= localCharacter then
        return
    end

    ClientClassBinders.PlayerInfoDisplay:BindAsync(self._obj)
    ClientClassBinders.InventoryUI:BindAsync(self._obj)

    if GameManager:IsLobby() then
        ClientClassBinders.ShopInterface:BindAsync(self._obj)
        ClientClassBinders.UpgradeUI:BindAsync(self._obj)
        ClientClassBinders.PlayScreen:BindAsync(self._obj)
        ClientClassBinders.RedeemCodeUI:BindAsync(self._obj)
    elseif GameManager:IsDungeon() then
        ClientClassBinders.PlayerAbilityUI:BindAsync(self._obj)
    end

    ClientClassBinders.MainButtonsInterface:BindAsync(self._obj)

    return self
end

return CharacterClient