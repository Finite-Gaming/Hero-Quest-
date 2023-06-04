---
-- @classmod WeaponHandler
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataService = require("UserDataService")
local WeaponService = require("WeaponService")

local WeaponHandler = {}

function WeaponHandler:UpdateWeapon(player, character)
    if not character then
        return
    end

    local equippedWeapon = UserDataService:GetEquipped(player, "Weapon")
    WeaponService:ApplyWeapon(character, equippedWeapon)
end

return WeaponHandler