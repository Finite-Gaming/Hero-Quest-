---
-- @classmod CharacterHelper
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataService = require("UserDataService")
local ItemConstants = require("ItemConstants")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BASE_HEALTH = 100
local BASE_SPEED = 16
local BASE_SCALE = 1

local CharacterHelper = {}

function CharacterHelper:UpdateStats(character)
    if not RunService:IsServer() then
        return
    end

    local player = nil
    if character:IsA("Player") then
        player = character
        character = character.Character
    else
        player = Players:GetPlayerFromCharacter(character)
    end

    if not character then
        warn("[CharacterHelper] - No character!")
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        warn("[CharacterHelper] - No humanoid!")
        return
    end

    local equippedArmor = UserDataService:GetEquipped(player, "Armor")
    local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
    local healthUpgradeLevel = UserDataService:GetUpgradeLevel(player, "Health")

    local healthMultipliers = {
        self:GetItemStat("Armors", equippedArmor, "Health");
        self:GetItemStat("Helmets", equippedHelmet, "Health");
        healthUpgradeLevel/76; -- TODO: change this?
    }
    local playerHealth = BASE_HEALTH
    for _, multiplier in ipairs(healthMultipliers) do
        playerHealth += BASE_HEALTH * multiplier
    end

    local speedModifiers = {
        self:GetItemStat("Armors", equippedArmor, "Speed");
        self:GetItemStat("Helmets", equippedHelmet, "Speed");
    }
    local playerSpeed = BASE_SPEED
    for _, speedModifier in ipairs(speedModifiers) do
        playerSpeed += speedModifier
    end

    character:ScaleTo(BASE_SCALE + (BASE_SCALE * (healthUpgradeLevel/150))) -- TODO: change this?

    local equippedTool = character:FindFirstChildOfClass("Tool")
    local tools = player.Backpack:GetChildren()
    table.insert(tools, equippedTool)
    for _, tool in ipairs(tools) do
        local damageUpgradeLevel = UserDataService:GetUpgradeLevel(player, "Damage")
        tool:ScaleTo(BASE_SCALE + (BASE_SCALE * (damageUpgradeLevel/150))) -- TODO: change this?
    end

    local healed = humanoid.Health == humanoid.MaxHealth
    humanoid.MaxHealth = playerHealth
    humanoid.WalkSpeed = playerSpeed
    if healed then
        humanoid.Health = playerHealth
    end
end

function CharacterHelper:GetItemStat(category, itemName, stat)
    local itemStats = ItemConstants[category][itemName]
    if not itemStats then
        return 0
    end

    return itemStats[stat]
end


return CharacterHelper