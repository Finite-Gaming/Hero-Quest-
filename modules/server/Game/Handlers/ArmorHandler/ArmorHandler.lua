--- Rewards players for playing in alpha
-- @classmod AlphaRewardService
-- @author unknown, frick
-- TODO: Refactor for Compliance

local cRequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local armorSetsFolder = ReplicatedStorage:WaitForChild("ArmorSets")

local ArmorHandlerConstants = cRequire("ArmorHandlerConstants")

local ArmorSkins = require(game.ServerScriptService.Skins.Armor)
-- Configuration
local defaultArmorSet = ArmorHandlerConstants.DEFAULT_ARMOR_SET

-- Require armor module
local ArmorService = cRequire("ArmorService")
local armorSets = ArmorService:GenerateArmorSets(armorSetsFolder)

local ArmorHandler = {}

-- Initialize connections
function ArmorHandler:Init()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(self._handlePlayerAdded, self, player)
	end
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerAdded(player)
	end)
end

-- Connect updater functions to respective events
function ArmorHandler:_handlePlayerAdded(player)
	--if player.UserId == 35904028 then
	--	defaultArmorSet = "Doita"
	--end

	player:GetAttributeChangedSignal("ArmorSet"):Connect(function()
		self:_updateCharacter(player, player.Character)
	end)

	self:_updateCharacter(player.Character)
	player.CharacterAdded:Connect(function(character)
		self:_updateCharacter(player, character)
	end)
end

-- Change players armor and update their health
function ArmorHandler:_updateCharacter(player, character)
	if not character then
		return
	end

	local targetSet = player:GetAttribute("ArmorSet")
	if not targetSet then
		-- Set the player's ArmorSet to the default one
		player:SetAttribute("ArmorSet", defaultArmorSet)
		local selected = player:GetAttribute("ArmorSet")
		print(selected)
		local ArmorData
		for _, Data in next, ArmorSkins do
			if Data.Name == selected then
				ArmorData = Data
				break
			end
		end

		if ArmorData.Health then -- TODO: Possibly move this to ArmorService.lua
			character.Humanoid.MaxHealth = math.floor(100 * ArmorData.Health)
			character.Humanoid.Health = character.Humanoid.MaxHealth
		end
		return
	end

	local armorSet = armorSets[targetSet]
	assert(armorSet, string.format("%s is not an armor set.", targetSet))
	ArmorService:ApplyArmorToCharacter(armorSet, character)
end

return ArmorHandler