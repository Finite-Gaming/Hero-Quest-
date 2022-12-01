--- Main injection point for the server
-- @classmod SettingsService
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

workspace.Lobby.Assets:Destroy()

require("ArmorHandler"):Init()
require("CharacterService"):Init()
require("SettingsService"):Init()
require("ItemService"):Init()
require("SpawnZoneHandler"):Init()
require("PartyEventHandler"):Init()
require("PlayerNoCollideService"):Init()
require("AlphaRewardService"):Init()
require("ServerClassBinders"):Init()

require("CombatHandler") -- TODO: Init method
require("PartyHandler")