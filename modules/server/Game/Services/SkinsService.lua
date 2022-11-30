---
-- @classmod SkinsService
-- @author unknown, frick

local cRequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerScriptService = game:GetService("ServerScriptService")

local Network = cRequire("Network")
local SkinsServiceConstants = cRequire("SkinsServiceConstants")

local UserData = require(ServerScriptService:WaitForChild("PlayerData"):WaitForChild("UserData")) -- TODO: Move this to use Compliance
local Skins = ServerScriptService:WaitForChild("Skins") -- TODO: Move this to something like SkinProvider.lua

-- Skin UUID -> Internal skin ID mappings
local CompanionSkins = require(Skins:WaitForChild("Companion"))
local WeaponSkins = require(Skins:WaitForChild("Weapon"))
local ArmorSkins = require(Skins:WaitForChild("Armor"))

local SecureGetSettings = { -- Hashmap supremacy
    ["Armors"] = true,
    ["Companions"] = true,
    ["Weapons"] = true,
}
local SecureSetSettings = {
    ["Armor"] = true,
    ["Companion"] = true,
    ["Weapon"] = true
}

local SkinsService = {}

function SkinsService:Init()
    Network:GetRemoteFunction(SkinsServiceConstants.GET_SKINS_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player, settingName: string)
        assert(SecureGetSettings[settingName], "Did not receive a secure setting")
        local profile = UserData:WaitForProfile(player.UserId)

        local data = profile.Data
        local toReturn = {}
        if settingName == "Armors" then
            for _, Data in next, data.Armors do
                if ArmorSkins[Data.SkinID] then
                    local tab = {
                        SkinID = Data.SkinID,
                        DecodeName = ArmorSkins[Data.SkinID].Name
                    }
                    table.insert(toReturn, tab)
                end
            end
        end
        
        return toReturn
    end

    Network:GetRemoteFunction(SkinsServiceConstants.SET_SKINS_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player, settingName: string, settingData: any)
        assert(SecureSetSettings[settingName], "Did not receive a secure setting")
        warn('req for', settingData)
        local ownCheck = UserData:HasArmor(player.UserId, settingData)
        if ownCheck then
            UserData:UpdateSkin(player.UserId, 'Armor', settingData)
            return true
        else
            return false
        end
        -- TODO finish setting armor/validating they own
    end
end

return SkinsService