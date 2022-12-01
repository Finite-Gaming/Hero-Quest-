--- Server party implementation
-- @classmod BaseService
-- @author

local cRequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local PartyHandlerConstants = cRequire("PartyHandlerConstants")

-- Configuration
local partyExpirationTime = PartyHandlerConstants.PARTY_EXPIRATION_TIME -- Specifies how many seconds a party will last for
local dungeonPlaceId = PartyHandlerConstants.TEMP_DUNGEONPLACEID -- A temporary attribute to specify the place players will be teleported to

-- Btw for future reference, :WaitForChild doesn't need to be called on the
-- server as everything is already replicated ~frick
-- TODO: Fix this

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local onNotification = remotes:WaitForChild("Notification")

local partyRemotes = remotes:WaitForChild("Parties")

local createParty = partyRemotes:WaitForChild("CreateParty") -- Called by the client to create a new party
local inviteUser = partyRemotes:WaitForChild("InviteUser") -- Called by the client to invite another user
local revokeUser = partyRemotes:WaitForChild("RevokeUser")
local startDungeon = partyRemotes:WaitForChild("StartDungeon")

local queryParties = partyRemotes:WaitForChild("QueryParties") -- Called by the client to retrieve a list of parties they can join
local requestJoinParty = partyRemotes:WaitForChild("RequestJoinParty") -- Called by the client to request joining a party
local leaveParty = partyRemotes:WaitForChild("LeaveParty") -- Called by the client to leave their active party

local partyLeft = partyRemotes:WaitForChild("PartyLeft") -- Fired when a player is removed from their active party
local partyChanged = partyRemotes:WaitForChild("PartyChanged") -- Fired when the active party is updated

local partiesUpdated = partyRemotes:WaitForChild("PartiesUpdated") -- Fired when the parties list updates

local partyPlayerAdded = partyRemotes:WaitForChild("PartyPlayerAdded") -- Fired when a player joins the player's active party
local partyPlayerRemoved = partyRemotes:WaitForChild("PartyPlayerRemoved") -- Fired when a player leaves the player's active party

-- MemoryStore
local partyQueue = MemoryStoreService:GetQueue("Parties", 1)

-- List of all dungeon information
local DUNGEONS = require(ReplicatedStorage:WaitForChild("DungeonEntries"))

export type Session = {
	AccessCode: string,
	PlaceId: number,
	ServerId: string,
	
	PartyUUID: string
}
export type PartyParameters = {
	MapId: string;
	Difficulty: number;
	MaxPlayers: number;
}
export type Party = {
	OwnerId: number, -- The UserID of the party's owner
	AccessCode: string?, -- If the party is private, this will be a unique "invite code"
	UUID: string, -- A unique ID for the party
	Members: {[number]: boolean}, -- A map of user IDs in the party
	
	Disbanded: boolean?, -- Whether or not the party has been disbanded
	
	InvitedUsers: {[number]: boolean}?, -- Players who have been explicitly invited to the party
	RevokedUsers: {[number]: boolean}, -- Players who have been banned from the party by the owner can't rejoin
	
	Session: Session?,
	
	Parameters: PartyParameters
}

local defaultPartyParameters: PartyParameters = {
	MapId = "HauntedCastle";
	Difficulty = 0;
	MaxPlayers = 10;
}

local Parties = {}

-- Map of local users currently within parties, and the UUID of the party they're in
Parties.PlayerActiveParty = {} :: {
	[number]: Party
}

-- Map of parties by their UUIDs
Parties.PartiesByUUIDs = {} :: {
	[string]: Party
}

-- Map of parties by owner's user IDs
Parties.PartiesByOwnerIds = setmetatable({} :: {
	[number]: Party
}, {
	-- Use weakly referenced values to avoid creating memory leaks (Party can garbage collect even if contained in this table)
	__mode = "v"
})

function Parties:Notify(actionName: string, data: any, priority: number?)
	if partyQueue then
		partyQueue:AddAsync({
			Action = actionName,
			UUID = HttpService:GenerateGUID(false),
			Data = data
		}, partyExpirationTime, priority)
	else
		warn("Parties notification can't be sent (no party queue)", actionName, data, priority)
	end
end

function Parties:UserCanCreateParty(player: Player)
	if self.PlayerActiveParty[player.UserId] then
		-- Player cannot already be in a party
		return false
	end
end

function Parties:UserCanJoinParty(player: Player, party: Party)
	if self.PlayerActiveParty[player.UserId] then
		-- Player is already in a party
		--return false
	end
	
	-- Override in studio
	if RunService:IsStudio() then
		return true
	end
	
	if party.RevokedUsers and party.RevokedUsers[player.UserId] then
		print("User is revoked.")
		-- User is revoked from joining this party
		return false
	elseif party.AccessCode then
		-- Override for invited users
		if party.InvitedUsers and party.InvitedUsers[player.UserId] then
			-- User is invited
			return true
		end

		print("Party is private.")
		
		-- The party is private
		return false
	end
	return true
end

function Parties:SetPlayerActiveParty(player: Player, party: Party, message: string?)
	-- Update their active party UUID
	self.PlayerActiveParty[player.UserId] = party.UUID
	
	-- Notify them that their party has changed
	partyChanged:FireClient(player, party.UUID, party.OwnerId == player.UserId, message)
end

function Parties:GetPartyListForPlayer(player: Player)
	local parties = {}
	for uuid, party in pairs(self.PartiesByUUIDs) do
		if party.Members[player.UserId] or self:UserCanJoinParty(player, party) or RunService:IsStudio() then
			if party.OwnerId == player.UserId then
				self:SetPlayerActiveParty(player, party)
			end
			table.insert(parties, party)
		end
	end
	return parties
end

function Parties:RegisterParty(party: Party, noNotify: boolean)
	local existingParty: Party? = self.PartiesByOwnerIds[party.OwnerId]
	if existingParty then
		self.PartiesByUUIDs[existingParty.UUID] = nil
	end
	
	-- Keep track of the party
	self.PartiesByUUIDs[party.UUID] = party

	-- Keep track of the party by the owner
	self.PartiesByOwnerIds[party.OwnerId] = party

	if not noNotify then
		self:Notify("Create", party, 0)
	end
	
	-- Add party members locally
	local memberCount = 0
	for userId, _ in pairs(party.Members) do
		self:AddToParty(party, userId, true)
		memberCount += 1
	end
	
	-- If no members, disband the party
	if memberCount <= 0 then
		self:DisbandParty(party, noNotify)
	end

	-- Update clients
	self:UpdateClientsAll()
end

function Parties:CreateParty(owner: Player, invitedUsers: {[number]: boolean}?, isPrivate: boolean?, parameters: PartyParameters?)
	if not parameters then
		parameters = table.clone(defaultPartyParameters)
	end
	
	-- If the user is already in a party, they can't create a new one.
	if self.PlayerActiveParty[owner.UserId] then
		return false, "You're already in a party."
	end
	
	local ownedParty = self.PartiesByOwnerIds[owner.UserId]
	-- If the user already owns a party, disband it
	if ownedParty then
		warn("[FIXME] User already owned a party when creating a new one. This is a synchronization bug.")
		self:DisbandParty(ownedParty.UUID)
	end
	
	local party: Party = {
		OwnerId = owner.UserId,
		AccessCode = if isPrivate then HttpService:GenerateGUID(false) else nil,
		UUID = HttpService:GenerateGUID(false),
		Members = {},
		
		InvitedUsers = invitedUsers,
		RevokedUsers = {},
		
		Parameters = parameters
	}

	-- Add the owner to the party locally
	self:AddToParty(party, party.OwnerId, true)
	
	-- Register the party globally
	self:RegisterParty(party, false)
	
	return party, "Successfully created a party."
end

function Parties:DisbandParty(uuid: string, noNotify: boolean?)
	local party = self.PartiesByUUIDs[uuid]
	
	self.PartiesByUUIDs[uuid] = nil
	
	if party and not party.Disbanded then
		party.Disbanded = true
		
		self.PartiesByOwnerIds[party.OwnerId] = nil
		for userId, _ in pairs(party.Members) do
			if userId ~= party.OwnerId then
				self:RemoveFromParty(party, userId, true)
			end
		end

		-- Update clients
		self:UpdateClientsAll()
		
		if not noNotify then
			self:Notify("Disband", {
				UUID = uuid
			}, -2)
		end
	end
end

function Parties:UpdateClients(party: Party)
	for userId, _ in pairs(party.Members) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			partiesUpdated:FireClient(player, self:GetPartyListForPlayer(player))
		end
	end
end

function Parties:UpdateClientsAll()
	for _, player in ipairs(Players:GetPlayers()) do
		partiesUpdated:FireClient(player, self:GetPartyListForPlayer(player))
	end
end

type PlayerJoinLeaveEvent = {
	UUID: string,
	UserId: number
}
function Parties:AddToParty(party: Party, userId: number, noNotify: boolean?)
	userId = assert(tonumber(userId), "UserId is not a number.")
	
	local player = Players:GetPlayerByUserId(userId)
	-- If the user is in this server
	if player then
		-- If the user is already in a party
		local userPartyUUID = self.PlayerActiveParty[player.UserId]
		-- If the user's current party is different from the party they're being added to
		if userPartyUUID ~= party.UUID then
			local userParty = userPartyUUID and self.PartiesByUUIDs[userPartyUUID]
			-- Remove from existing party (and notify since they're in this server)
			if userParty then
				self:RemoveFromParty(userParty, userId)
			end

			-- Update their current party
			self:SetPlayerActiveParty(player, party, player.UserId ~= party.OwnerId and string.format("You've been added to %s's party.", Players:GetNameFromUserIdAsync(party.OwnerId)) or nil)
		end
	end
	
	if not party.Members[userId] then
		for memberId, _ in pairs(party.Members) do
			local player = Players:GetPlayerByUserId(memberId)
			if player then
				partyPlayerAdded:FireClient(player, userId)
			end
		end
		
		party.Members[userId] = true
		if not noNotify then
			self:Notify("AddPlayer", {
				UserId = userId,
				UUID = party.UUID
			}, -1)
		end
	end
	
	self:UpdateClients(party)
end
function Parties:RemoveFromParty(party: Party, userId: number, noNotify: boolean?)
	userId = assert(tonumber(userId), "UserId is not a number.")
	
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local userPartyUUID = self.PlayerActiveParty[player.UserId]
		if userPartyUUID then
			-- Unmark the user's active party
			if userPartyUUID == party.UUID then
				self.PlayerActiveParty[player.UserId] = nil
			end
		end
		
		-- Notify them that they left the party
		local ownerName = Players:GetNameFromUserIdAsync(party.OwnerId)
		local message = if party.Disbanded then string.format("%s's party has disbanded.", ownerName) else string.format("You've been removed from %s's party.", ownerName)
		partyLeft:FireClient(player, party.UUID, party.OwnerId == player.UserId, message)
	end
	
	--print("Removing user from party:", userId)
	--print("Is member:", party.Members[userId])
	--print("Is owner:", party.OwnerId == userId)

	-- If the user is the owner of the party, disband it
	if party.OwnerId == userId then
		-- Disband the party
		self:DisbandParty(party.UUID, noNotify)
		return
	end
	
	if party.Members[userId] then
		for memberId, _ in pairs(party.Members) do
			local player = Players:GetPlayerByUserId(memberId)
			if player then
				partyPlayerRemoved:FireClient(player, userId)
			end
		end
		party.Members[userId] = nil
		
		if not noNotify then
			self:Notify("RemovePlayer", {
				UserId = userId,
				UUID = party.UUID
			}, -1)
		end
	end

	self:UpdateClients(party)
end

function Parties:NotifyPartyMembers(party: Party, messageType: string, message: string)
	for userId, _ in pairs(party.Members) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			onNotification:FireClient(player, messageType, message)
		end
	end
end

function Parties:StartDungeon(party: Party, noNotify: boolean?)
	-- TODO: Replace placeholders
	--print("Start dungeon", debug.traceback())
	
	local playersToTeleport = {}
	for userId, _ in pairs(party.Members) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			--print("Starting dungeon for", player, debug.traceback())
			table.insert(playersToTeleport, player)
			
			onNotification:FireClient(player, "Success", "Connecting your party to the dungeon...")
		end
	end
	
	if not party.Session then
		-- Reserve the server
		warn("Reserving a server...")
		local success, accessCode = pcall(function()
			return TeleportService:ReserveServer(dungeonPlaceId)
		end)
		if not success then
			self:NotifyPartyMembers(party, "Error", "Could not reserve your session.")
			return false
		end
		warn("Dungeon access code:", accessCode)
		
		party.Session = {
			AccessCode = accessCode,
			PlaceId = dungeonPlaceId,
			ServerId = "<INVALID>",
			
			PartyUUID = party.UUID
		}
	end
	
	-- Ensure the party has a session
	assert(party.Session, "Can't join dungeon. Party does not have a session.")
	
	-- Teleport to the server
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = party.Session.AccessCode
	
	local success, teleportResult = pcall(function()
		return TeleportService:TeleportAsync(dungeonPlaceId, playersToTeleport, teleportOptions) :: TeleportAsyncResult
	end)
	
	-- Update the session's ServerId
	party.Session.ServerId = teleportResult.PrivateServerId
	
	-- Publish session start globally
	if not noNotify then
		-- Re-register the party globally
		self:RegisterParty(party, false)
		
		print("Starting session...")
		MessagingService:PublishAsync("Party:StartSession", {
			AuthorId = game.JobId,
			Party = party
		})
	end
	
	if not success then
		self:NotifyPartyMembers(party, "Error", "Couldn't connect you to the session. Please reconnect.")
		return false
	end
	return true
end

-- Sends a ping to the session's server. If a response is received, players will be teleported
export type SessionPing = {
	ServerId: string,
	AuthorId: string,
	Action: string,
	
	Data: any
}
function Parties:PingSession(session: Session)
	MessagingService:PublishAsync("Party:SessionPing", {
		ServerId = session.ServerId,
		AuthorId = game.JobId,
		
		Action = "StartDungeon",
		Data = session
	} :: SessionPing)
end

-- Party queue processing
do
	type QueueItem = {
		Action: string,
		Data: any,
		UUID: string
	}

	local QueueActions = {}
	
	-- Registers a party locally
	function QueueActions.Create(data: Party)
		local ownerId = data.OwnerId
		
		-- Remove existing party
		local existingParty = Parties.PartiesByOwnerIds[ownerId]
		if existingParty then
			Parties:DisbandParty(existingParty.UUID, true)
		end

		for userId, value in pairs(data.Members) do
			data.Members[userId] = nil
			data.Members[assert(tonumber(userId), "UserId is not a number")] = value
		end
		if data.InvitedUsers then
			for userId, value in pairs(data.InvitedUsers) do
				data.InvitedUsers[userId] = nil
				data.InvitedUsers[assert(tonumber(userId), "UserId is not a number")] = value
			end
		end
		if data.RevokedUsers then
			for userId, value in pairs(data.RevokedUsers) do
				data.RevokedUsers[userId] = nil
				data.RevokedUsers[assert(tonumber(userId), "UserId is not a number")] = value
			end
		end
		
		Parties:RegisterParty(data, true)
	end
	-- Disbands a party locally
	function QueueActions.Disband(data)
		Parties:DisbandParty(data.UUID, true)
	end
	-- Adds a player to a party locally
	function QueueActions.AddPlayer(data)
		local party = assert(Parties.PartiesByUUIDs[data.UUID], string.format("No party with UUID '%s' when processing RemovePlayer on the queue.", data.UUID))
		
		Parties:AddToParty(party, data.UserId, true)
	end
	-- Removes a player from a party locally
	function QueueActions.RemovePlayer(data)
		local party = assert(Parties.PartiesByUUIDs[data.UUID], string.format("No party with UUID '%s' when processing RemovePlayer on the queue.", data.UUID))
		
		Parties:RemoveFromParty(party, data.UserId, true)
	end
	
	local processedItems = {}
	task.spawn(function()
		if not partyQueue then
			return
		end
		
		-- Process all items
		while true do
			--print("Updating from queue...")
			
			-- Read the next batch of items in the event queue
			local success, queueItems, queryId = pcall(function()
				return partyQueue:ReadAsync(100, false, 1)
			end)
			
			if not success then
				warn("Failed to read from queue:", queueItems)
			end
			
			--print("Read from queue:", queueItems, queryId)
			
			-- Process items in the event queue
			local didProcessQueueItems = success and queueItems and queueItems[1]
			if success and queueItems then
				for _, item: QueueItem in ipairs(queueItems) do
					if type(item) ~= "table" then
						warn("Skipped an erroneous item on the party queue which was not of type table:", item)
						continue
					end
					
					-- If the item was already processed in a previous step (e.g. if an item failed to process in a previous batch of items) skip it
					if processedItems[item.UUID] then
						--warn("Item was already processed previosuly:", item)
						continue
					end
					
					--print("Process:", item.Action, item)
					
					-- Try to process the queue item
					local action = QueueActions[item.Action]
					if action then
						local success, errorMessage = pcall(action, item.Data)
						if not success then
							didProcessQueueItems = false
							warn(string.format("Error while processing message on the MemoryStoreService party queue: %s", errorMessage))
						end
					end
					
					-- Mark the item as having been processed
					processedItems[item.UUID] = true
				end
			end
			
			-- Remove queue items
			--if didProcessQueueItems then
			--	table.clear(processedItems) -- Clear processed items map
			--	partyQueue:RemoveAsync(queryId) -- Remove the processed items from the queue
			--end
			
			task.wait()
		end
	end)
end

-- Remotes
function queryParties.OnServerInvoke(player)
	return Parties:GetPartyListForPlayer(player)
end

function requestJoinParty.OnServerInvoke(player, partyId)
	assert(partyId, "Must specify a party UUID to join")
	assert(type(partyId) == "string", "Party UUID must be a string")
	
	local party = Parties.PartiesByUUIDs[partyId]
	if not party then
		-- Party does not exist
		return false, "The party no longer exists."
	end
	
	if not Parties:UserCanJoinParty(player, party) then
		-- User cannot join the party
		return false, "You cannot join the party."
	end
	
	Parties:AddToParty(party, player.UserId)
	
	return true, string.format("You have joined %s's party.", Players:GetNameFromUserIdAsync(party.OwnerId))
end

function leaveParty.OnServerInvoke(player, UUID)
	local userPartyUUID = Parties.PlayerActiveParty[player.UserId]
	local userParty = userPartyUUID and Parties.PartiesByUUIDs[userPartyUUID]
	if not userParty then
		Parties.PlayerActiveParty[player.UserId] = nil
		partyLeft:FireClient(player, UUID)
		return true
	end
	
	Parties:RemoveFromParty(userParty, player.UserId)
	return true, "Left the party."
end

function createParty.OnServerInvoke(player, usersToInvite, isPrivate, parameters: PartyParameters)
	assert(type(usersToInvite) == "table", "usersToInvite must be a table of userIds")
	assert(type(isPrivate) == "boolean", "isPrivate must be a boolean")
	
	local usersToInvite_Map = {}
	for _, userId in ipairs(usersToInvite) do
		assert(type(userId) == "number", "usersToInvite can only contain user IDs")
		usersToInvite_Map[userId] = true
	end
	
	return Parties:CreateParty(player, usersToInvite_Map, isPrivate, parameters)
end

function inviteUser.OnServerInvoke(player, userId)
	assert(type(userId) == "number", "userId must be a number")
	
	local userPartyUUID = Parties.PlayerActiveParty[player.UserId]
	local userParty = userPartyUUID and Parties.PartiesByUUIDs[userPartyUUID]
	if not userParty then
		return false, "You are not in a party. You should create one!"
	end
	
	if userParty.OwnerId ~= player.UserId then
		return false, "Only the owner can invite other players."
	end
	
	if userParty.Members[userId] then
		return false, "That player is already in the party!"
	end
	
	userParty.InvitedUsers[userId] = true
	
	-- Grab their username for the response
	local username = Players:GetNameFromUserIdAsync(userId)

	-- TODO: Utilize MessagingService to send out an invite instead
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return true, string.format("%s isn't in your server, but they'll be able to join your party.", username)
	end
	
	return true, string.format("Invited %s to join your dungeon.", username)
end

function revokeUser.OnServerInvoke(player, userId, revoked)
	assert(type(userId) == "number", "userId must be a number")
	assert(type(revoked) == "boolean", "revoked status must be a boolean")

	local userPartyUUID = Parties.PlayerActiveParty[player.UserId]
	local userParty = userPartyUUID and Parties.PartiesByUUIDs[userPartyUUID]
	if not userParty then
		return false, "You are not in a party."
	end

	if userParty.OwnerId ~= player.UserId then
		return false, "Only the owner can revoke other player's access."
	end

	userParty.RevokedUsers[userId] = revoked or nil
	if revoked then
		userParty.InvitedUsers[userId] = nil
	end
	
	if userParty.Members[userId] then
		Parties:RemoveFromParty(userParty, userId)
	end
end

function startDungeon.OnServerInvoke(player)
	print("Received start dungeon request...")
	
	local userPartyUUID = Parties.PlayerActiveParty[player.UserId]
	local userParty = userPartyUUID and Parties.PartiesByUUIDs[userPartyUUID]
	if not userParty then
		return false, "You are not in a party."
	end

	if userParty.OwnerId ~= player.UserId then
		return false, "Only the owner can start the dungeon."
	end
	
	return Parties:StartDungeon(userParty)
end

Players.PlayerAdded:Connect(function(player)
	local userPartyUUID = Parties.PlayerActiveParty[player.UserId]
	local userParty = userPartyUUID and Parties.PartiesByUUIDs[userPartyUUID]
	
	if not userParty then
		userParty = Parties.PartiesByOwnerIds[player.UserId]
		if userParty then
			userPartyUUID = userParty.UUID
		end
	end
	
	if userParty then
		partyChanged:FireClient(player, userPartyUUID)

		--local partySession = userParty.Session
		--if partySession then
		--	onNotification:FireClient(player, "Searching for your previous session...")
		--	Parties:PingSession(partySession)
		--end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	local userPartyUUID = Parties.PlayerActiveParty[player.UserId]
	local userParty = userPartyUUID and Parties.PartiesByUUIDs[userPartyUUID] :: Party
	
	--if userParty and not userParty.Session then
	--	Parties:RemoveFromParty(userParty, player.UserId)
	--end
end)

MessagingService:SubscribeAsync("Party:SessionPing", function(message)
	local sessionPing = message.Data :: SessionPing
	if game.PrivateServerId == sessionPing.ServerId then
		MessagingService:PublishAsync("Party:SessionPong", sessionPing)
	end
end)
MessagingService:SubscribeAsync("Party:SessionPong", function(message)
	local sessionPing = message.Data :: SessionPing
	if sessionPing.AuthorId == game.JobId then
		if sessionPing.Action == "StartDungeon" then
			local session: Session = sessionPing.Data
			local partyUUID = session.PartyUUID
			local party = partyUUID and Parties.PartiesByUUIDs[partyUUID]
			if party then
				party.Session = session
				Parties:StartDungeon(party, true)
			end
		end
	end
end)
MessagingService:SubscribeAsync("Party:StartSession", function(message)
	local startSessionRequest = message.Data
	local authorId = startSessionRequest.AuthorId
	
	if authorId ~= game.JobId then
		local party = startSessionRequest.Party :: Party
		local session: Session = assert(party.Session, "Party does not have a session to start.")
		
		local partyUUID = session.PartyUUID
		local sessionParty = partyUUID and Parties.PartiesByUUIDs[partyUUID]
		
		if sessionParty then
			local playerList = {}
			for userId, value in pairs(party.Members) do
				party.Members[userId] = nil
				party.Members[assert(tonumber(userId), "UserId is not a number")] = value
				table.insert(playerList, tostring(userId))
			end
			print(string.format("Starting session.\n Access code: %s\n PlaceId: %d\n Members: %s", session.AccessCode, session.PlaceId, table.concat(playerList, ", ")))
			
			print("Received session start...")
			
			sessionParty.Members = party.Members
			sessionParty.Session = session
			Parties:StartDungeon(sessionParty, true)
		end
	end
end)

return Parties