---
-- @classmod WeaponService
-- @author frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local ItemDirectory = require("ItemDirectory")

local Players = game:GetService("Players")

local WeaponService = {}

-- Applies wapen to a character
function WeaponService:ApplyWeapon(character, weaponName)
    if not character then
        return
    end
    local player = assert(Players:FindFirstChild(character.Name))

    self:ClearWeapon(character)

    if not weaponName then
        return
    end

    local weapon = assert(ItemDirectory.Weapons:FindFirstChild(weaponName)):Clone()
    weapon:SetAttribute("EquippedWeapon", true)
    weapon.Parent = player.Backpack
end

function WeaponService:ClearWeapon(character)
    local player = assert(Players:FindFirstChild(character.Name))

    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:GetAttribute("EquippedWeapon") then
            tool:Destroy()
        end
    end

    for _, tool in ipairs(character:GetChildren()) do
        if not tool:IsA("Tool") then
            continue
        end

        if tool:GetAttribute("EquippedWeapon") then
            tool:Destroy()
        end
    end
end

return WeaponService