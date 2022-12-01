--- Returns data pertaining to items to the client
-- @classmod ItemService
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require("Network")
local ItemServiceConstants = require("ItemServiceConstants")
-- Skin UUID -> Internal skin ID mappings
local CompanionSkins = require("CompanionConstants")
local WeaponSkins = require("WeaponConstants")
local ArmorSkins = require("ArmorConstants")
local UserData = require("UserData")

local Skins = ServerScriptService:WaitForChild("Skins") -- TODO: Move this to something like SkinProvider.lua

--//Source
local BodyFolder = ServerStorage["Body Armor"]
local HelmetFolder = ServerStorage["Helmet Armor"]
local WeaponFolder = ServerStorage.Weapon

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

local ItemService = {}

-- Initialize remote functions, return respective data on invoke
function ItemService:Init()
    self._armorEvent = Network:GetRemoteEvent(ItemServiceConstants.ARMOR_EVENT_REMOTE_EVENT_NAME)

    Network:GetRemoteFunction(ItemServiceConstants.GET_SKINS_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player, settingName: string)
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

    Network:GetRemoteFunction(ItemServiceConstants.SET_SKINS_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player: Player, settingName: string, settingData: any)
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

function ItemService:SetEquipped(Chr,EquippedTable)
	wait()
	print(Chr)
	self:ClearArmor(Chr)
	--print(EquippedTable)

	local FolderMain = Instance.new("Folder")
	FolderMain.Name = 'ArmorFolder'

	--Chr variables
	local ChrHead = Chr.Head
	local ChrRoot = Chr.HumanoidRootPart
	local ChrUpperTorso = Chr.UpperTorso

	local SelectedBodyFolder = BodyFolder[EquippedTable.Body]
	local SelectedHelmetFolder = HelmetFolder[EquippedTable.Helmet]

	--//Loading wep
	local WeaponClone = WeaponFolder[EquippedTable.Weapon]:FindFirstChildOfClass("Tool"):Clone()
	WeaponClone.Parent = game.Players:GetPlayerFromCharacter(Chr).Backpack


	--//Connecting head	
	local HeadModelClone = SelectedHelmetFolder.Head:Clone()

	ChrHead.Anchored = true
	HeadModelClone.PrimaryPart.Anchored = true

	HeadModelClone:SetPrimaryPartCFrame(ChrHead.CFrame * CFrame.Angles(0,math.rad(180),0))

	for _, v in pairs(Chr:GetChildren()) do
		if v:IsA("Accoutrement") or v:IsA("Accessory") then
			v:Destroy()
		end
	end

	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Part0 = HeadModelClone.PrimaryPart
	WeldConstraint.Part1 = ChrHead
	WeldConstraint.Parent = HeadModelClone

	ChrHead.Anchored = false
	HeadModelClone.PrimaryPart.Anchored = false

	HeadModelClone.Parent = FolderMain

	--//Connecting body
	for _,Limb in pairs(SelectedBodyFolder:GetChildren()) do

		local clonedLimbModel = Limb:Clone()
		local realLimb = Chr[Limb.Name]

		clonedLimbModel.PrimaryPart.Anchored = true
		realLimb.Anchored = true

		clonedLimbModel:SetPrimaryPartCFrame(realLimb.CFrame * CFrame.Angles(0,math.rad(180),0) )

		local WeldConstraint = Instance.new("WeldConstraint")
		WeldConstraint.Part0 = realLimb
		WeldConstraint.Part1 = clonedLimbModel.PrimaryPart
		WeldConstraint.Parent = clonedLimbModel

		clonedLimbModel.PrimaryPart.Anchored = false
		realLimb.Anchored = false
		clonedLimbModel.Parent = FolderMain

	end

	FolderMain.Parent = Chr
	self._armorEvent:FireAllClients(FolderMain)
end

function ItemService:ClearArmor(Chr)
	--local Plr = game.Players:GetPlayerFromCharacter(Chr)
	--local ArmorFolder = Chr:FindFirstChild("ArmorFolder")
	--local ChrWeapon = Chr:FindFirstChildOfClass("Tool")
	--local BackpackWeapon = Plr.Backpack:FindFirstChildOfClass("Tool")
	--if ChrWeapon then ChrWeapon:Destroy() end
	--if BackpackWeapon then BackpackWeapon:Destroy() end
	--if ArmorFolder then ArmorFolder:Destroy() end
end

return ItemService