---
-- @classmod PlayerLevelCalculator
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BASE_XP = 100
local MAX_LEVEL = 8000
local EXPONENT_FACTOR = 2.2

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

local RANK_TITLES = {
    [1] = {
        [1] = "Novice";
        [2] = "Scout";
        [3] = "Guardian";
        [4] = "Sentinel";
        [5] = "Protector";
        [6] = "Defender";
        [7] = "Champion";
        [8] = "Vanquisher";
        [9] = "Paladin";
        [10] = "Master";
    };
    [2] = {
        [1] = "Apprentice";
        [2] = "Pathfinder";
        [3] = "Sentinel";
        [4] = "Vanguard";
        [5] = "Stalwart";
        [6] = "Guardian";
        [7] = "Avenger";
        [8] = "Hero";
        [9] = "Exalted";
        [10] = "Grandmaster";
    };
    [3] = {
        [1] = "Adept";
        [2] = "Wayfarer";
        [3] = "Sentinel";
        [4] = "Warden";
        [5] = "Archon";
        [6] = "Champion";
        [7] = "Paragon";
        [8] = "Ascendant";
        [9] = "Eternal";
        [10] = "Legend";
        [11] = "Divine";
        [12] = "Celestial";
    };
}

local PlayerLevelCalculator = {}

function PlayerLevelCalculator:GetLevelFromXP(xpValue)
    return math.clamp(math.floor((xpValue / BASE_XP) ^ (1 / EXPONENT_FACTOR)), 1, MAX_LEVEL) -- replace formula later
end

function PlayerLevelCalculator:GetXPFromLevel(levelValue)
    return BASE_XP * (levelValue ^ EXPONENT_FACTOR)
end

function PlayerLevelCalculator:GetClassAlignment(upgradeData)
    local highestLevel = 0

    for _, upgradeLevel in pairs(upgradeData) do
        if upgradeLevel > highestLevel then
            highestLevel = upgradeLevel
        end
    end

    local debugTable = {}
    local compoundCode = 0
    for upgradeName, upgradeLevel in pairs(upgradeData) do
        if upgradeLevel == highestLevel then
            compoundCode += ALIGNMENT_CODES[upgradeName]
            table.insert(debugTable, upgradeName)
        end
    end

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

    return classAlignment
end

function PlayerLevelCalculator:GetRankFromLevel(levelValue)
    local indexTable = RANK_TITLES[math.clamp(math.floor(levelValue/100) + 1, 1, 3)]
    local guildCompletion = (levelValue%100)/100
    if levelValue >= 300 then
        guildCompletion = 1
    end

    return indexTable[math.clamp(math.round(#indexTable * guildCompletion), 1, #indexTable)]
end

function PlayerLevelCalculator:GetRankFromXP(xpValue)
    return self:GetRankFromLevel(self:GetLevelFromXP(xpValue))
end

return PlayerLevelCalculator