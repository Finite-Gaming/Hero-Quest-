---
-- @classmod WeaponApplier
-- @author

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local WeldUtils = require("WeldUtils")
local ItemDirectory = require("ItemDirectory")

local WeaponApplier = {}

function WeaponApplier:ApplyWeapon(character, weaponName)
    
end

function WeaponApplier:ClearWeapon(character)

end

return WeaponApplier