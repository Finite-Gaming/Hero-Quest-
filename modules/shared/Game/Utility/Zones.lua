--!strict
local Players = game:GetService("Players")

-- Get zones
local zones = workspace:WaitForChild("Zones")

-- Create overlap parameters
local overlapParams = OverlapParams.new()
overlapParams.MaxParts = 1
overlapParams.FilterDescendantsInstances = {zones}
overlapParams.FilterType = Enum.RaycastFilterType.Whitelist

-- Zone manager
local Zones = {}

local zoneChanged = Instance.new("BindableEvent")
Zones.ZoneChanged = zoneChanged.Event

function Zones:GetZone(player: Player): string?
	local character = player.Character
	if character then
		-- Find the zone the player is standing in
		local rootPart = character.PrimaryPart or character:WaitForChild("HumanoidRootPart")
		local zones = workspace:GetPartsInPart(rootPart, overlapParams)
		
		-- Return the first zone's name
		return zones[1] and zones[1].Name
	end
	return nil
end

-- Watch for changing zones
task.spawn(function()
	-- A map of player's zones by their UserId
	local currentZones = {}
	
	-- When a player leaves, we want to clear out their current zone
	Players.PlayerRemoving:Connect(function(player)
		-- Remove the player's zone
		currentZones[player.UserId] = nil
	end)

	while true do
		-- Wait one frame
		task.wait()

		-- For each player
		for _, player in ipairs(Players:GetPlayers()) do
			-- Find the player's current zone
			local zone = Zones:GetZone(player)
			
			-- If their zone changed, fire the zoneChanged event
			if currentZones[player.UserId] ~= zone then
				zoneChanged:Fire(player, zone)
			end
			
			-- Update their zone
			currentZones[player.UserId] = zone
		end
	end
end)

zoneChanged.Event:Connect(print)

return Zones