--!strict
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
-- local skins = ServerScriptService:WaitForChild("Skins")

local ItemConstants = require("ItemConstants")
local DefaultData = require("DefaultData")

-- ProfileService (data storage)
local ProfileService = require("ProfileService")
local PROFILE_KEY_FORMAT = "USER_%d"

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	DefaultData
)

local UserData = {
	UserProfiles = {};
}

local profileReady = Instance.new("BindableEvent")

local loggedIn = Instance.new("BindableEvent")
UserData.LoggedIn = loggedIn.Event

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

-- Time constants
local MINUTE = 60
local HOUR = 60 * MINUTE
local DAY = HOUR * 24
local WEEK = DAY * 7
local MONTH = DAY * 30

--[[ type SpecialReward {
    Weapons = {[itemKey] = str}
    Armor = {[itemKey] = str}
    Pets = {[itemKey] = str}

    Money = int
    XP = int
}]]
local SpecialRewards = {
	-- Default
	Starter = {
		Weapons = {
			BasicSword = 1;
		};
		Armor = {
			BasicArmor = 1;
		};
		Pets = {
			StarterPet = 1;
		};
	};
	-- Alpha tester gear
	ItCameFromTheDeep = {
		Weapons = {
			AlphaHammer = 1;
		};
		Armor = {
			AlphaArmor = 1;
		};
	};
}

-- Gives a special reward from the table above (will only provide it once)
function UserData:GiveSpecialReward(userId, rewardName)
	local profile = self:WaitForProfile(userId)
	local data = profile.Data

	local rewards = data.SpecialRewards
	if not rewards[rewardName] then
		local reward = assert(SpecialRewards[rewardName], string.format("%s is not a valid special reward.", rewardName))

		for _, itemType in ipairs({"Weapons", "Armor", "Pets"}) do
            for _, itemKey in ipairs(reward[itemType] or {}) do
                self:AwardItem(userId, itemType, itemKey)
            end
        end

		-- Award money
		if reward.Money then
			self:AwardCurrency("Money", reward.Money)
		end
		-- Award XP
		if reward.XP then
			self:AwardCurrency("XP", reward.XP)
		end

		print(string.format("Gave user %d special reward %s.", userId, rewardName))
		print("Has weapons:", data.Weapons)
		print("Has armors:", data.Armors)
		print("Has pets:", data.Pets)
		rewards[rewardName] = true
	else
		-- Player already has the reward
		warn(string.format("User %d already has the special reward %s", userId, rewardName))
	end
end

local secureOwnedItemTypeKeys = {
    Weapons = true;
    Armor = true;
    Pets = true;
}
function UserData:AwardItem(userId, itemType, itemKey, amount)
    print(userId, itemType, itemKey, amount)
    amount = amount or 1
    assert(amount == amount and amount > 0, "Invalid amount")
    assert(secureOwnedItemTypeKeys[itemType], "Invalid itemType")
    local itemConstants = assert(ItemConstants[itemType][itemKey], "Invalid itemKey")
    assert(not itemConstants.Stackable and amount > 1, "Item is not stackable, higher quantity than 1 was provided")

	local profile = UserData:GetProfile(userId)
    local itemEntry = profile.Data[itemType][itemKey]

    if itemEntry then
        if itemConstants.Stackable then
            itemEntry.Quantity += amount
        else
            itemEntry.Quantity = 1
        end
    else
        profile.Data[itemType][itemKey] = {Quantity = amount}
    end
end

function UserData:GetOwnedItems(userId, itemType)
    assert(secureOwnedItemTypeKeys[itemType], "Invalid itemType")
	local profile = UserData:GetProfile(userId)

    return profile.Data[itemType]
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
function UserData:HasItem(userId, itemType, itemKey)
    assert(secureOwnedItemTypeKeys[itemType], "Invalid itemType")
    assert(ItemConstants[itemType][itemKey], "Invalid itemKey")
	local profile = UserData:GetProfile(userId)

    return profile.Data[itemType][itemKey] and true or false
end

-- Handle equipping item requests
local secureEquippedItemMap = {
    Weapon = "Weapons";
    Armor = "Armor";
    Pet = "Pets";
}
function UserData:UpdateEquipped(userId, itemType, itemKey)
    local constantKey = assert(secureEquippedItemMap[itemType])
    assert(ItemConstants[constantKey][itemKey])

	local profile = UserData:GetProfile(userId)
	profile.Data.EquippedItems[itemType] = itemKey

    local player = Players:GetPlayerByUserId(userId)
    if player and player.Character then
        local character = player.Character

        if itemType == "Armor" then
            player:SetAttribute("ArmorSet", itemKey)
            local armorData = ItemConstants.Armor[itemKey]

            if armorData.Health then
                character.Humanoid.MaxHealth = math.floor(100 * armorData.Health)
                character.Humanoid.Health = character.Humanoid.MaxHealth
            end
        end
    else
        warn(("[UserData] - Equipped %s successfully updated for player %i, player is not in-game.")
            :format(itemType, userId))
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