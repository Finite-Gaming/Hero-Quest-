--- Initializes and provides server class binders
-- @classmod ServerClassBinders
-- @author Hexcede probably, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

-- TODO: Migrate bounding box detection to a global Zones handler.
-- This would keep behaviour consistent across all enterable regions (e.g. NPCs, pose regions, and this portal)
-- TODO: Migrate this script to ServerScriptService and utilize Zones code to handle by zone name, rather than requiring the portal part be directly available to the script.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BaseObject = require("BaseObject")
local PortalConstants = require("PortalConstants")

-- Configuration
local timeout = PortalConstants.Time -- How long players must wait to be teleported
local maxPlayers = PortalConstants.MaxPlayers -- The maximum number of players who can be in a portal before initiating a teleport

local rejectTransitionTime = PortalConstants.RejectTransitionTime -- This specifies the animation length for when a player is rejected from teleporting

local teleportingText = PortalConstants.TeleportText -- The text to display once players are being teleported
local exclusionTimeout = PortalConstants.ExclusionTimeout -- How long to exclude teleporting players from counts for

local teleportFailedText = PortalConstants.TeleportFailedText -- The text to display if a teleport fails
local failTextDuration = PortalConstants.FailTextDuration -- How long the fail text should be displayed for

-- Rejection transition options
local rejectTweenStyleIn = Enum.EasingStyle.Circular -- The style as the tween is eased in
local rejectTweenStyleOut = Enum.EasingStyle.Elastic -- The style as the tween is eased out

local PortalTeleport = {}
PortalTeleport.__index = PortalTeleport

function PortalTeleport.new(teleporterModel)
    local self = setmetatable(BaseObject.new(teleporterModel), PortalTeleport)

    -- A map to keep track of which players are currently teleporting (and when), in order to avoid counting them
    self._teleportingPlayers = {}

    -- Teleport options used to teleport players to a dungeon
    self._teleportOptions = Instance.new("TeleportOptions")
    self._teleportOptions.ShouldReserveServer = true

    self._rejectLocationAttachment = self._obj.RejectLocation -- An attachment to specify the location players are moved when a teleport fails or is rejected

    self._aboutToBegin = false
    self._teleportFailed = nil
    self._teleporting = false
    self._startTime = nil

    -- Remove players who leave from the self._teleportingPlayers map (to avoid creating memory leaks)
    self._maid:AddTask(Players.PlayerRemoving:Connect(function(playerRemoving)
        if self._teleportingPlayers[playerRemoving] then
            self._teleportingPlayers[playerRemoving] = nil
        end

        if self._teleporting then
            local teleportingCount = 0
            for _, _ in pairs(self._teleportingPlayers) do
                teleportingCount += 1
            end

            if teleportingCount <= 0 then
                self:_clearTimer()
            end
        end
    end))

    -- Update status text
    self._joinTextUI = self._obj.JoinText
    self._titleText = self._joinTextUI.Title
    self._statusText = self._joinTextUI.Status

    self._statusTemplate = self._statusText.Text

    self:_updateTimerTexts()

    self._maid:AddTask(task.spawn(function()
        while true do
            task.wait(0.1)
            self:_checkForStart()
        end
    end))

    self._maid:AddTask(self._obj.Touched:Connect(function()
        self:_checkForStart()
    end))

    return self
end

-- Returns whether or not the player began teleporting within the exclusion timeout
function PortalTeleport:_didStartTeleportingRecently(player)
	return self._teleportingPlayers[player] and (os.clock() - self._teleportingPlayers[player]) < exclusionTimeout
end

-- Returns a list of player's characters (excluding players who are actively teleporting)
function PortalTeleport:_getCharacters()
	local players = Players:GetPlayers()

	local characters = table.create(#players) -- Bit of a weird optimization here as we're most likely allocating more indices than nessescary ~frick
	for _, player in ipairs(players) do
		-- Skip players who recently started teleporting to avoid counting them in any queries
		if self:_didStartTeleportingRecently(player) then
			continue
		end

		local character = player.Character
		if character then
			table.insert(characters, character)
		end
	end
	return characters
end

-- Returns a list of player's root parts
function PortalTeleport:_getRootParts()
	local characters = self:_getCharacters()

	local rootParts = table.create(#characters)
	for _, character in ipairs(characters) do
		local rootPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			table.insert(rootParts, rootPart)
		end
	end
	return rootParts
end

-- Finds all players standing around the portal
local playerParams = OverlapParams.new()
playerParams.FilterType = Enum.RaycastFilterType.Whitelist

function PortalTeleport:_queryPlayersInPortal(playerLimit)
	playerParams.FilterDescendantsInstances = self:_getRootParts()
	playerParams.MaxParts = playerLimit or math.huge

	-- Find all root parts of players in the portal
	local playerRootPartsInPortal = workspace:GetPartsInPart(self._obj, playerParams)

	local players = table.create(#playerRootPartsInPortal)
	for _, rootPart in ipairs(playerRootPartsInPortal) do
		local character = rootPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			table.insert(players, player)
		end
	end
	return players
end

function PortalTeleport:_didTeleportJustFail()
	return self._teleportFailed and os.clock() - self._teleportFailed < failTextDuration
end

function PortalTeleport:_updateStatus(timeLeft, playersInPortalCount)
	if self:_didTeleportJustFail() then
		self._statusText.Text = teleportFailedText
		return
	end

	if not self._teleporting then
		self._statusText.Text = string.format(self._statusTemplate, timeLeft, playersInPortalCount, maxPlayers)
	else
		-- Display texts, and animate with 3 "." symbols
		self._statusText.Text = string.format(teleportingText, string.rep(".", os.clock() % 3 + 1))
	end
end

function PortalTeleport:_updateTimerTexts()
	local playersInPortal = self:_queryPlayersInPortal(maxPlayers)

	-- Measure the elapsed time
	local timeElapsed = if self._startTime then os.clock() - self._startTime else 0
	local timeLeft = math.max(timeout - timeElapsed, 0)

	-- Update the UI text
	if self._joinTextUI.Enabled then
		self:_updateStatus(timeLeft, #playersInPortal)
	end

	if #playersInPortal >= maxPlayers then
		return 0
	end
	return timeLeft
end

-- Clears the join timer
function PortalTeleport:_clearTimer()
	self._teleporting = false
	self._aboutToBegin = false
	self._startTime = nil

	if self._maid.TimerConnection then
		self._maid.TimerConnection = nil
	end

	self:_updateTimerTexts()
end

function PortalTeleport:_freezePlayer(player, state)
	local character = player.Character
	if character then
		local rootPart = character.PrimaryPart or character.HumanoidRootPart
		rootPart.Anchored = state
	end
end

-- Moves a player to the RejectLocation attachment when a teleport has been denied
function PortalTeleport:_rejectPlayerTeleport(player)
	local character = player.Character
	if character then
		local rootPart: BasePart = character.PrimaryPart or character.HumanoidRootPart
		-- Make sure the player is grounded, and is in the workspace
		if not rootPart:IsGrounded() or not rootPart:IsDescendantOf(workspace) then
			return
		end

		-- Reset their movement
		rootPart.AssemblyLinearVelocity = Vector3.new()
		rootPart.AssemblyAngularVelocity = Vector3.new()

		-- Transition them to the RejectLocation
		local transitionStart = os.clock()
		local initialCFrame = rootPart.CFrame
		local targetCFrame = CFrame.fromMatrix(self._rejectLocationAttachment.WorldPosition, initialCFrame.XVector, initialCFrame.YVector, initialCFrame.ZVector)
		while os.clock() - transitionStart < rejectTransitionTime do
			task.wait()

			local elapsed = math.clamp(os.clock() - transitionStart, 0, rejectTransitionTime)
			local alphaLinear = elapsed / rejectTransitionTime

			local alphaIn = TweenService:GetValue(alphaLinear, rejectTweenStyleIn, Enum.EasingDirection.In)
			local alphaOut = TweenService:GetValue(alphaIn, rejectTweenStyleOut, Enum.EasingDirection.Out)
			rootPart.CFrame = initialCFrame:Lerp(targetCFrame, alphaOut)
		end
		rootPart.CFrame = targetCFrame
	end
end

-- Teleports all players standing around the portal
function PortalTeleport:_commenceTeleport()
	local playersInPortal = self:_queryPlayersInPortal(maxPlayers)
	if playersInPortal[1] then
		-- Teleport players (as party)
		if not self._teleporting then
			self._teleporting = true

			-- Find all players in the portal, including ones not part of the teleport
			local allPlayersInPortal = self:_queryPlayersInPortal()

			-- Mark relevant players as teleporting
			for _, player in ipairs(playersInPortal) do
				self._teleportingPlayers[player] = os.clock()
			end

			-- Transition each player around the portal
			for _, player in ipairs(allPlayersInPortal) do
				-- Freeze the player
				self:_freezePlayer(player, true)

				-- Move players who will not be teleported to the reject location and unfreeze them
				if not self:_didStartTeleportingRecently(player) then
					self:_rejectPlayerTeleport(player)
					self:_freezePlayer(player, false)
				end
			end

			-- Enable collisions on the portal hitbox to prevent new players from entering
			self._obj.CanCollide = true
			self:_updateTimerTexts()

			local success, result = xpcall(function()
				return TeleportService:TeleportAsync(9678777751, playersInPortal, self._teleportOptions)
			end, debug.traceback)

			if success then
				print(string.format("%d player(s) teleporting to dungeon:", #playersInPortal), result.PrivateServerId, result.ReservedServerAccessCode)
			else
				warn(string.format("Failed to teleport %d player(s) to a dungeon. Error: %s", #playersInPortal, result))

				-- Mark that the teleport failed, and update the status
				self._teleportFailed = os.clock()
				self:_updateTimerTexts()

				for _, player in ipairs(playersInPortal) do
					-- Move players to the reject location and unfreeze them (teleport failed)
					self:_rejectPlayerTeleport(player)
					self:_freezePlayer(player, false)

					-- We know the teleport failed, so mark the player as no longer teleporting
					self._teleportingPlayers[player] = nil
				end
			end

			-- Timeout after 5 seconds and reset the state
			task.delay(5, function()
				if self._teleporting then
					self:_clearTimer()
				end
			end)

			--teleporting = false
			self._obj.CanCollide = false
		end
	end
end

-- If the timer isn't active, checks if a player is standing in the portal
function PortalTeleport:_checkForStart()
	if not self._aboutToBegin then
		local playersInPortal = self:_queryPlayersInPortal(1)
		-- If there's at least one player standing by the portal, we want to teleport them
		if playersInPortal[1] then
			-- Clear any existing timer
			self:_clearTimer()

			-- Start a timer
			self._aboutToBegin = true
			self._startTime = os.clock()
			--teleportFailed = nil
			self:_updateTimerTexts()
			self._maid.TimerConnection = RunService.Stepped:Connect(function()
				-- Freeze the timer when a teleport just failed
				if self:_didTeleportJustFail() then
					self._startTime = os.clock()
				elseif self._teleportFailed then
					-- If a teleport failed, but the expiry period is up, reset the teleport fail state
					self._teleportFailed = nil
					self._teleporting = false
				end

				-- If there are no players standing in the portal, and players are not teleporting, clear the timer
				local playersInPortal = self:_queryPlayersInPortal(1)
				if not self._teleporting and not playersInPortal[1] then
					self:_clearTimer()
					return
				end

				if self:_updateTimerTexts() <= 0 then
					self:_commenceTeleport()
				end
			end)
		end
	end
end

return PortalTeleport