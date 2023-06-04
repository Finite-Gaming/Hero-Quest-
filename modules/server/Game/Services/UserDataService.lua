---
-- @classmod UserDataService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local UserDataServiceConstants = require("UserDataServiceConstants")
local UserData = require("UserData")
local ServerClassBinders = require("ServerClassBinders")
local DungeonData = require("DungeonData")
local TableUtils = require("TableUtils")
local ArmorService = require("ArmorService")
local PetService = require("PetService")
local WeaponService = require("WeaponService")
local RewardCodes = require("RewardCodes")
local UpgradePriceUtil = require("UpgradePriceUtil")
local ProgressionHelper = require("ProgressionHelper")

local secureGetTypes = {
    ["Armors"] = true,
    ["Helmets"] = true,
    ["Pets"] = true,
    ["Weapons"] = true,
    ["Abilities"] = true
}
local secureSetTypes = {
    ["Armor"] = true,
    ["Helmet"] = true,
    ["Pet"] = true,
    ["Weapon"] = true,
    ["Ability"] = true
}

local function getDungeonByIndex(index)
    for dungeonTag, dungeonData in pairs(DungeonData) do
        if dungeonData.PlayIndex == index then
            return dungeonTag
        end
    end
end

local function getNextDungeon(dungeonTag)
    local totalDungeons = TableUtils.count(DungeonData)
    local currentIndex = DungeonData[dungeonTag].PlayIndex
    return getDungeonByIndex(math.clamp(currentIndex + 1, 1, totalDungeons))
end

local DATE_TIME_0 = DateTime.fromUnixTimestamp(0)
local DATE_TIME_9999 = DateTime.fromUnixTimestamp(253402300799) -- funny magic numbe

local UserDataService = {}

function UserDataService:Init()
    do -- items
        self:_connectRemote("GetItems", UserDataServiceConstants.GET_ITEMS_REMOTE_FUNCTION_NAME, function(player, itemType)
            assert(typeof(itemType) == "string", "Invalid itemType")
            assert(secureGetTypes[itemType], "Did not receive a secure setting")

            return UserData:GetOwnedItems(player.UserId, itemType)
        end)

        self:_connectRemote("SetEquipped", UserDataServiceConstants.SET_EQUIPPED_ITEM_REMOTE_FUNCTION_NAME, function(player, itemType, itemKey)
            assert(typeof(itemType) == "string", "Invalid itemType")
            assert(secureSetTypes[itemType], "Did not receive a secure setting")
            assert(itemKey == nil or typeof(itemKey) == "string", "Invalid itemKey")
            warn('req for', itemKey)
            print(player, itemType, itemKey)

            if itemKey and UserData:HasItem(player.UserId, itemType, itemKey) or not itemKey then
                UserData:UpdateEquipped(player.UserId, itemType, itemKey)

                local character = player.Character
                if character then
                    if itemType == "Ability" then
                        local playerAbility = ServerClassBinders.PlayerAbility:Get(character) -- TODO: move to abilityservice
                        if playerAbility then
                            playerAbility:UpdateAbility(itemKey)
                        end
                    elseif itemType == "Armor" then
                        ArmorService:ApplyArmor(character, itemKey)
                    elseif itemType == "Helmet" then
                        ArmorService:ApplyHelmet(character, itemKey)
                    elseif itemType == "Pet" then
                        PetService:ApplyPet(character, itemKey)
                    elseif itemType == "Weapon" then
                        WeaponService:ApplyWeapon(character, itemKey)
                    end
                end

                return true
            else
                return false
            end
        end)

        self:_connectRemote("GetEquipped", UserDataServiceConstants.GET_EQUIPPED_ITEM_REMOTE_FUNCTION_NAME, function(player, itemType)
            return UserData:WaitForProfile(player.UserId).Data.EquippedItems[itemType]
        end)
    end

    do -- settings
        self:_connectRemote("SetSetting", UserDataServiceConstants.SET_SETTING_REMOTE_FUNCTION_NAME, function(player, settingName, settingValue)
            local profile = UserData:WaitForProfile(player.UserId)

            local data = profile.Data
            local settings = data.Settings

            -- TODO: Validate types
            settings[settingName] = settingValue
        end)

        self:_connectRemote("GetSetting", UserDataServiceConstants.GET_SETTING_REMOTE_FUNCTION_NAME, function(player)
            local profile = UserData:WaitForProfile(player.UserId)

            local data = profile.Data
            local settings = data.Settings

            return settings
        end)

        self:_connectRemote("GetSettings", UserDataServiceConstants.GET_SETTINGS_REMOTE_FUNCTION_NAME, function(player, settingName)
            local profile = UserData:WaitForProfile(player.UserId)

            local data = profile.Data
            local settings = data.Settings

            return settings[settingName]
        end)
    end

    do -- misc data
        self:_connectRemote("HasBeatenDungeon", UserDataServiceConstants.HAS_BEATEN_DUNGEON_REMOTE_FUNCTION_NAME, function(player)
            return UserData:WaitForProfile(player.UserId).Data.DungeonsCompleted[workspace:GetAttribute("DungeonTag")] ~= nil
        end)

        self:_connectRemote("HasPlayedDungeon", UserDataServiceConstants.HAS_PLAYED_DUNGEON_REMOTE_FUNCTION_NAME, function(player)
            return UserData:WaitForProfile(player.UserId).Data.DungeonsPlayed[workspace:GetAttribute("DungeonTag")] ~= nil
        end)

        self:_connectRemote("GetNextDungeon", UserDataServiceConstants.GET_NEXT_DUNGEON_REMOTE_FUNCTION_NAME, function(player)
            local userData = UserData:WaitForProfile(player.UserId).Data
            local currentDungeon = userData.CurrentDungeon

            if currentDungeon then
                return currentDungeon.Tag, currentDungeon.Floor
            else
                local maxIndex = 1
                for dungeonTag, _ in pairs(userData.DungeonsCompleted) do
                    local index = DungeonData[dungeonTag].PlayIndex
                    if index > maxIndex then
                        maxIndex = index
                    end
                end

                return getNextDungeon(getDungeonByIndex(maxIndex)), 1 -- TODO
            end
        end)
    end

    do -- codes
        self:_connectRemote("RedeemCode", UserDataServiceConstants.REDEEM_CODE_REMOTE_FUNCTION_NAME, function(player, rewardCode)
            assert(typeof(rewardCode) == "string")
            local redeemedCodes = UserData:WaitForProfile(player.UserId).Data.RedeemedRewardCodes
            if redeemedCodes[rewardCode] then
                return false, "Code already redeemed!"
            end

            local rewardData = RewardCodes[rewardCode]
            if not rewardData then
                return false, "Invalid code!"
            end

            local validFrom = rewardData.ValidFrom or DATE_TIME_0 -- default to infinitely avaliable if value not present
            local validTo = rewardData.ValidTo or DATE_TIME_9999

            local currentDateTime = DateTime.now()
            if currentDateTime.UnixTimestamp < validFrom.UnixTimestamp then
                return false, "Code not valid yet!"
            end
            if currentDateTime.UnixTimestamp >= validTo.UnixTimestamp then
                return false, "Code expired!"
            end

            if not rewardData.SpecialReward then
                return false, ("Error: Please contact a developer if you see this (Code: %s)"):format(rewardCode)
            end

            redeemedCodes[rewardCode] = true
            UserData:GiveSpecialReward(player.UserId, rewardData.SpecialReward)

            return true, "Success!"
        end)
    end

    do -- umm stuff
        local secureUpgradeNames = {
            Damage = true;
            Health = true;
            MagicDamage = true;
        }

        self:_connectRemote("GetUpgradeLevel", UserDataServiceConstants.GET_UPGRADE_LEVEL_REMOTE_FUNCTION_NAME, function(player, upgradeName)
            assert(typeof(upgradeName) == "string")
            assert(secureUpgradeNames[upgradeName])

            local upgrades = UserData:WaitForProfile(player.UserId).Data.UpgradeData
            return upgrades[upgradeName]
        end)

        self:_connectRemote("GetUpgradeData", UserDataServiceConstants.GET_UPGRADE_DATA_REMOTE_FUNCTION_NAME, function(player)
            local upgrades = UserData:WaitForProfile(player.UserId).Data.UpgradeData
            local dataTable = {}

            for upgradeName, upgradeLevel in pairs(upgrades) do
                dataTable[upgradeName] = upgradeLevel
            end

            return dataTable
        end)

        self:_connectRemote("UpgradeStat", UserDataServiceConstants.UPGRADE_STAT_REMOTE_FUNCTION_NAME, function(player, upgradeName)
            local data = UserData:WaitForProfile(player.UserId).Data
            local upgradeLevel = self:GetUpgradeLevel(player, upgradeName)
            local upgradePrice = UpgradePriceUtil:GetPriceFromLevel(upgradeLevel, upgradeName)
            -- TODO: cap level to player level?
            if UserData:HasCurrency(player.UserId, "Money", upgradePrice) then
                UserData:TakeCurrency(player.UserId, "Money", upgradePrice)

                data.UpgradeData[upgradeName] += 1

                return true, "Success!", data.UpgradeData[upgradeName]
            else
                return false, "Insufficent funds"
            end
        end)
    end

    do -- currency stuff
        self:_connectRemote("GetExperience", UserDataServiceConstants.GET_EXPERIENCE_REMOTE_FUNCTION_NAME, function(player)
            return UserData:WaitForProfile(player.UserId).Data.XP
        end)
        self:_connectRemote("GetMoney", UserDataServiceConstants.GET_MONEY_REMOTE_FUNCTION_NAME, function(player)
            return UserData:WaitForProfile(player.UserId).Data.Money
        end)
    end

    do -- play data
        self:_connectRemote("IsFirstTimer", UserDataServiceConstants.IS_FIRST_TIMER_REMOTE_FUNCTION_NAME, function(player)
            return ProgressionHelper:IsFirstTimer(player)
        end)
    end
end

function UserDataService:_connectRemote(methodName, remoteFunctionName, onInvoke)
    Network:GetRemoteFunction(remoteFunctionName).OnServerInvoke = onInvoke

    self[methodName] = function(self, ...)
        return onInvoke(...)
    end
end

return UserDataService