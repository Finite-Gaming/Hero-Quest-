--!strict
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local skins = ServerScriptService:WaitForChild("Skins")

-- Skin UUID -> Internal skin ID mappings
local CompanionSkins = require("CompanionConstants")
local WeaponSkins = require("WeaponConstants")
local ArmorSkins = require("ArmorConstants")

-- ProfileService (data storage)
local ProfileService = require("ProfileService")
local PROFILE_KEY_FORMAT = "USER_%d"

-- Time constants
local MINUTE = 60
local HOUR = 60 * MINUTE
local DAY = HOUR * 24
local WEEK = DAY * 7
local MONTH = DAY * 30

export type ItemUUID = string;
export type Companion = {
	SkinID: CompanionSkins.SkinID; -- ID of the particular companion skin
	
	-- The unique ID of the companion
	UUID: ItemUUID;
	
	-- Companion data
	Nickname: string?;
	Level: number;
}
export type Weapon = {
	SkinID: WeaponSkins.SkinID; -- ID of the particular weapon skin
	
	-- The unique ID of the weapon
	UUID: ItemUUID;
}
export type Armor = {
	SkinID: ArmorSkins.SkinID; -- ID of the particular armor skin
	
	-- The unique ID of the armor
	UUID: ItemUUID;
}

local function getSkin(skins, skinName: string): string
	local skinIndex
	for index, name in pairs(skins) do
		if name.Name == skinName then
			skinIndex = index
			break
		end
	end
	--assert(skinIndex, string.format("No skin with name '%s'.", skinName))
	return skinIndex
end

local DefaultData = {
	-- Coins
	Money = 0;
	-- Essence (XP standin)
	XP = 0;
	
	-- Owned skins
	Weapons = {} :: {[ItemUUID]: Weapon};
	Armors = {} :: {[ItemUUID]: Armor};
	Companions = {} :: {[ItemUUID]: Companion};
	
	-- Special rewards
	SpecialRewards = {} :: {[string]: boolean?};
	
	-- Active skins
	ActiveSkins = {
		Weapon = nil :: ItemUUID?;
		Armor = nil :: ItemUUID?;
		Companion = nil :: ItemUUID?;
	};
	
	-- Login date
	LastLogin = 0;
	
	-- Successive login days
	SuccessiveDailyLogins = 0;
	
	-- Login rewards
	NextLoginReward = 0;
	AvailableLoginRewards = 0;
	
	-- Settings
	Settings = {
		MusicVolume = 1; -- Volume of 
		SFXVolume = 1; -- Volume of SFX
		AmbienceVolume = 1; -- Volume of ambient/background noise

		CameraShake = true; -- Enables/disables screen shake
		PitchCorrection = true; -- Pitch correction for various SFX (Slow)
		ReducedParticles = false; -- Reduces particles for low-end devices
		ReducedShadows = false; -- Whether or not to disable shadows
		ShowOtherPlayerDamage = true; -- Indicates whether or not other player's damage numbers should be displayed
	};
}

local ProfileStore = ProfileService.GetProfileStore(
	"UserData",
	DefaultData
)

local UserData = {
	UserProfiles = {};
}

local profileReady = Instance.new("BindableEvent")

local loggedIn = Instance.new("BindableEvent")
UserData.LoggedIn = loggedIn.Event

function UserData:CreateItemUUID(): ItemUUID
	return HttpService:GenerateGUID(false)
end

function UserData:CreateWeapon(skinId: WeaponSkins.SkinID): Weapon
	return {
		SkinID = skinId;
		UUID = self:CreateItemUUID();
	}
end
function UserData:CreateArmor(skinId: ArmorSkins.SkinID): Armor
	return {
		SkinID = skinId;
		UUID = self:CreateItemUUID();
	}
end
function UserData:CreateCompanion(skinId: CompanionSkins.SkinID): Companion
	return {
		SkinID = skinId;
		UUID = self:CreateItemUUID();
		
		Level = 0;
	}
end

-- Checks if a user profile exists and returns it without creating any new one
function UserData:FindLoadedProfile(userId: number)
	assert(type(userId) == "number", "UserId is not a number.")
	
	local key = string.format(PROFILE_KEY_FORMAT, userId)
	return self.UserProfiles[key]
end

-- Waits for a player's profile to load
function UserData:WaitForProfile(userId: number)
	local profile = self:FindLoadedProfile(userId)
	while not profile do
		warn("Profile not loaded, waiting...")
		profileReady.Event:Wait()
		profile = self:FindLoadedProfile(userId)
	end
	return profile
end

-- Special rewards
export type SpecialReward = {
	Weapons: {WeaponSkins.SkinID}?;
	Armors: {ArmorSkins.SkinID}?;
	Companions: {CompanionSkins.SkinID}?;

	Money: number?;
	XP: number?;
}

local SpecialRewards = {
	-- Default
	Starter = {
		Weapons = {
			getSkin(WeaponSkins, "Basic");
		};
		Armors = {
			getSkin(ArmorSkins, "Basic");
		};
		Companions = {
			getSkin(CompanionSkins, "Basic");
		};
	};
	-- Alpha tester gear
	ItCameFromTheDeep = {
		Weapons = {
			getSkin(WeaponSkins, "Diver");
		};
		Armors = {
			getSkin(ArmorSkins, "Diver");
		};
	};
} :: {[string]: SpecialReward}

-- Gives a special reward from the table above (will only provide it once)
function UserData:GiveSpecialReward(userId: number, rewardName: string)
	local profile = self:WaitForProfile(userId)
	local data = profile.Data
	
	local rewards = data.SpecialRewards
	if not rewards[rewardName] then
		local reward = assert(SpecialRewards[rewardName], string.format("%s is not a valid special reward.", rewardName))
		
		local weapons = reward.Weapons
		local armors = reward.Armors
		local companions = reward.Companions
		
		local money = reward.Money
		local xp = reward.XP
		
		-- Award weapons
		if weapons then
			if not data.Weapons then
				data.Weapons = {}
			end
			for _, skinId in ipairs(weapons) do
				local weapon = self:CreateWeapon(skinId)
				data.Weapons[weapon.UUID] = weapon
			end
		end
		-- Award armors
		if armors then
			if not data.Armors then
				data.Armors = {}
			end
			for _, skinId in ipairs(armors) do
				local armor = self:CreateArmor(skinId)
				data.Armors[armor.UUID] = armor
			end
		end
		-- Award companions
		if companions then
			if not data.Companions then
				data.Companions = {}
			end
			for _, skinId in ipairs(companions) do
				local companion = self:CreateCompanion(skinId)
				data.Companions[companion.UUID] = companion
			end
		end
		
		-- Award money
		if money then
			self:AwardCurrency("Money", money)
		end
		-- Award XP
		if xp then
			self:AwardCurrency("XP", xp)
		end
		
		print(string.format("Gave user %d special reward %s.", userId, rewardName), weapons, armors, companions, money, xp)
		print("Has weapons:", data.Weapons)
		print("Has armors:", data.Armors)
		print("Has companions:", data.Companions)
		rewards[rewardName] = true
	else
		-- Player already has the reward
		warn(string.format("User %d already has the special reward %s", userId, rewardName))
	end
end

-- Retrieves a user's profile and creates it if it does not exist
function UserData:GetProfile(userId: number)
	local key = string.format(PROFILE_KEY_FORMAT, userId)
	local profile = self:FindLoadedProfile(userId)
	if not profile then
		profile = ProfileStore:LoadProfileAsync(key)
		profile = self.UserProfiles[key] or profile
		self.UserProfiles[key] = profile
		
		if profile then
			-- Set up user profile
			-- GDPR compliance
			profile:AddUserId(userId)
			-- Reconcile against the defaults so no expected data is missing
			profile:Reconcile()
			-- When the profile released, remove their data from the local server
			profile:ListenToRelease(function()
				print("Released player data for user", userId)
				self.UserProfiles[key] = nil
				
				-- If the player by this user ID is in the server, disconnect them
				local player = Players:GetPlayerByUserId(userId)
				if player then
					warn("Player's data was loaded by another server.")
					-- Kick the player, their data is potentially loaded by another server and we do not want to make any modifications
					player:Kick("Your data was loaded by another server. You have been kicked to make sure that you don't lose any progress.")
				end
			end)
		end
		
		-- Profile is ready
		warn("Profile ready", userId, key, self:FindLoadedProfile(userId) == profile)
		profileReady:Fire(userId)
	end
	return profile
end
-- Handle validating user owned items
function UserData:HasArmor(userId: number, value: any?)
	local Profile = UserData:GetProfile(userId)
	local doesOwn = false
	for _, ArmorData in next, Profile.Data.Armors do
		if value.SkinID == ArmorData.SkinID then
			doesOwn = true
			break
		end
	end
	return doesOwn
end

function UserData:UpdateSkin(userId: number, settingType: string, valueData)
	local Profile = UserData:GetProfile(userId)
	Profile.Data['ActiveSkins'][settingType] = valueData.SkinID
	warn(Profile)
	if settingType == "Armor" then
		local Player = Players:GetPlayerByUserId(userId)
		Player:SetAttribute("ArmorSet", valueData.DecodeName)
		local ArmorData = ArmorSkins[valueData.SkinID]
		if ArmorData.Health then
			Player.Character.Humanoid.MaxHealth = math.floor(100 * ArmorData.Health)
			Player.Character.Humanoid.Health = Player.Character.Humanoid.MaxHealth
		end
	end
end

-- Gives a player currency (As a reward, will avoid taking currency)

function UserData:AwardCurrency(userId: number, currencyType: string, amount: number)
	local profile = self:WaitForProfile(userId)
	assert(profile, "Data is not loaded.")
	
	-- If we're not giving money, do not do anything to the player's data
	if amount <= 0 then
		return
	end
	
	-- Make sure the player has the currency, and if they don't, give them 0
	local data = profile.Data
	if not data[currencyType] then
		data[currencyType] = 0
	end
	
	-- Add the awarded currency
	data[currencyType] += amount
end
-- Checks if a user has enough currency (e.g. for a transaction)
function UserData:HasCurrency(userId: number, currencyType: string, amount: number)
	local profile = self:WaitForProfile(userId)
	assert(profile, "Data is not loaded.")

	-- If the amount is not greater than zero, they must have enough
	if amount <= 0 then
		return true
	end
	
	-- Make sure the player has the currency, and if they don't, give them 0
	local data = profile.Data
	if not data[currencyType] then
		data[currencyType] = 0
	end
	
	-- Return whether or not they do have enough
	return data[currencyType] >= amount
end
-- Takes currency away
function UserData:TakeCurrency(userId: number, currencyType: string, amount: number)
	local profile = self:WaitForProfile(userId)
	assert(profile, "Data is not loaded.")

	-- If we're not taking money, do not do anything to the player's data
	if amount <= 0 then
		return
	end

	-- Make sure the player has the currency, and if they don't, give them 0
	local data = profile.Data
	if not data[currencyType] then
		data[currencyType] = 0
	end
	
	-- Ensure the player has enough currency
	assert(self:HasCurrency(userId, currencyType, amount), string.format("Player does not have enough of the currency %s.", currencyType))
	
	-- Take the awarded currency
	data[currencyType] -= amount
end

-- When a player joins set up their profile automatically
local function handlePlayer(player: Player)
	local userId = player.UserId
	local profile = UserData:GetProfile(userId)

	if not profile then
		-- If the player's data fails to load it is not safe to allow them to play
		player:Kick("Failed to load your data. You have been kicked to make sure that you don't lose any progress.")
		return error(string.format("Failed to load %s's (id %d) profile.", player.DisplayName, userId))
	end
	warn(profile)
	-- Award starter gear
	UserData:GiveSpecialReward(userId, "Starter")
	
	loggedIn:Fire(player)
end

-- For all players that join or have joined
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayer, player)
end
Players.PlayerAdded:Connect(handlePlayer)

-- When a player leaves we need to clean up their data
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local profile = UserData:FindLoadedProfile(userId)
	
	if profile then
		-- Release the user's profile
		profile:Release()
	end
end)

-- When a user logs in
UserData.LoggedIn:Connect(function(player: Player)
	local profile = UserData:FindLoadedProfile(player.UserId)
	assert(profile, "Profile not loaded.")
	local data = profile.Data

	local timeSinceLastLogin = os.time() - (data.LastLogin or os.time())
	if timeSinceLastLogin <= 1 * DAY then
		-- Daily login reward
		data.AvailableLoginRewards = (data.AvailableLoginRewards or 0) + 1

		-- Increment their daily logins
		data.SuccessiveDailyLogins = (data.SuccessiveDailyLogins or 0) + 1
	else
		-- Reset their daily logins
		data.SuccessiveDailyLogins = 0
	end

	-- Update the user's last login date
	data.LastLogin = os.time()
end)

return UserData