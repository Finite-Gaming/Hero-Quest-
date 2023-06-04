--!strict
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
-- local skins = ServerScriptService:WaitForChild("Skins")

local ItemConstants = require("ItemConstants")
local Signal = require("Signal")
local DefaultData = require("DefaultData")
local Network = require("Network")
local ItemRewardConstants = require("ItemRewardConstants")
local SpecialRewards = require("SpecialRewards")
local TableUtils = require("TableUtils")

-- ProfileService (data storage)
local ProfileService = require("ProfileService")
local PROFILE_KEY_FORMAT = "USER_%d"

local ProfileStore = ProfileService.GetProfileStore(
	"UserData_TEST_6",
	DefaultData
)

local UserData = {
	UserProfiles = {};
    _rewardRemoteEvent = Network:GetRemoteEvent(ItemRewardConstants.REMOTE_EVENT_NAME);
}

local profileReady = Instance.new("BindableEvent")

local loggedIn = Instance.new("BindableEvent")
UserData.LoggedIn = Signal.new()

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

function UserData:FindPlayer(userId)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            return player
        end
    end
end

-- Gives a special reward from the table above (will only provide it once)
function UserData:GiveSpecialReward(userId, rewardName)
	local profile = self:WaitForProfile(userId)
	local data = profile.Data

	local rewards = data.SpecialRewards
	if not rewards[rewardName] then
		local reward = assert(SpecialRewards[rewardName], string.format("%s is not a valid special reward.", rewardName))

        local keyTable = {}
		for _, itemType in ipairs({"Weapons", "Armors", "Pets", "Helmets", "Abilities"}) do
            local countTable = reward[itemType] or {}
            local tableCopy = {}
            for itemKey, count in pairs(countTable) do
                if typeof(count) == "NumberRange" then
                    count = math.random(count.Min, count.Max)
                end
                tableCopy[itemKey] = count
                self:AwardItem(userId, itemType, itemKey, count)
            end
            keyTable[itemType] = tableCopy
        end

        if reward.PromptReward then
            local player = self:FindPlayer(userId)
            if player then
                self._rewardRemoteEvent:FireClient(player, keyTable)
            end
        end

		-- Award money
		if reward.Money then
			self:AwardCurrency(userId, "Money", reward.Money)
		end
		-- Award XP
		if reward.XP then
			self:AwardCurrency(userId, "XP", reward.XP)
		end

		print(string.format("Gave user %d special reward %s.", userId, rewardName))
		-- print("Has weapons:", data.Weapons)
		-- print("Has armors:", data.Armors)
		-- print("Has pets:", data.Pets)
        if not reward.RewardMultiple then
		    rewards[rewardName] = true
        end
	else
		-- Player already has the reward
		warn(string.format("User %d already has the special reward %s", userId, rewardName))
	end
end

local secureOwnedItemTypeKeys = {
    Weapons = true;
    Armors = true;
    Helmets = true;
    Pets = true;
    Abilities = true;
}
function UserData:AwardItem(userId, itemType, itemKey, amount)
    -- Strict arg validating here as we dont want to corrupt data
    amount = amount or 1
    assert(amount == amount and amount > 0, "Invalid amount")
    assert(secureOwnedItemTypeKeys[itemType], "Invalid itemType")
    local itemConstants = assert(ItemConstants[itemType][itemKey], "Invalid itemKey")
    assert(not itemConstants.Stackable and amount == 1, "Item is not stackable, higher quantity than 1 was provided")

	local profile = self:WaitForProfile(userId)
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
	local profile = self:WaitForProfile(userId)
    local tableCopy = {} -- returning a reference can be bad here

    for key, data in pairs(profile.Data[itemType]) do
        tableCopy[key] = data
    end

    return tableCopy
end

-- Retrieves a user's profile and creates it if it does not exist
function UserData:GetProfile(userId: number)
	local key = string.format(PROFILE_KEY_FORMAT, userId)
	local profile = self:FindLoadedProfile(userId)
	if not profile then
		profile = ProfileStore:LoadProfileAsync(key)
		self.UserProfiles[key] = profile

		if profile then
			-- Set up user profile
			-- GDPR compliance
			profile:AddUserId(userId)
			-- Reconcile against the defaults so no expected data is missing
			profile:Reconcile()
			-- When the profile released, remove their data from the local server
			profile:ListenToRelease(function()
				-- print("Released player data for user", userId)
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

local secureEquippedItemMap = {
    Weapon = "Weapons";
    Armor = "Armors";
    Helmet = "Helmets";
    Pet = "Pets";
    Ability = "Abilities";
}
local iEquippedMap = TableUtils.swapArrange(secureEquippedItemMap)

-- Handle validating user owned items
function UserData:HasItem(userId, itemType, itemKey)
    -- Auto translate key (ex: "Weapon" is provided instead of "Weapon")
    local iKey = secureEquippedItemMap[itemType]
    if iKey then
        itemType = iKey
    end

    assert(secureOwnedItemTypeKeys[itemType] or iEquippedMap[itemType], "Invalid itemType")
    assert(ItemConstants[itemType][itemKey], "Invalid itemKey")
	local profile = UserData:GetProfile(userId)

    return profile.Data[itemType][itemKey] and true or false
end

-- Handle equipping item requests
function UserData:UpdateEquipped(userId, itemType, itemKey)
    local constantKey = assert(secureEquippedItemMap[itemType])
    assert(itemKey and ItemConstants[constantKey][itemKey] or not itemKey)

	local profile = UserData:GetProfile(userId)
	profile.Data.EquippedItems[itemType] = itemKey
end

local secureCurrencies = {
    Money = true;
    XP = true;
}

-- Gives a player currency (As a reward, will avoid taking currency)

function UserData:AwardCurrency(userId: number, currencyType: string, amount: number)
	local profile = self:WaitForProfile(userId)
	assert(profile, "Data is not loaded.")

    if not secureCurrencies[currencyType] then
        return
    end

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
    local newCurrency = data[currencyType] + amount
	data[currencyType] = newCurrency

    local player = Players:GetPlayerByUserId(userId)
    if player then
        player:SetAttribute(currencyType, newCurrency)
    end
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
    local newCurrency = data[currencyType] - amount
	data[currencyType] = newCurrency

    local player = Players:GetPlayerByUserId(userId)
    if player then
        player:SetAttribute(currencyType, newCurrency)
    end
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
loggedIn.Event:Connect(function(player: Player)
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
    data.PlayCount += 1

    UserData.LoggedIn:Fire(player, profile)
end)

return UserData