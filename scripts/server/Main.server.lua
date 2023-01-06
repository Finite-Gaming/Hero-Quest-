--- Main injection point for the server
-- @classmod SettingsService
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

workspace.Lobby.Assets:Destroy()

require("ServerClassBinders"):Init()

require("MarketplacePurchaseHandler"):Init()
require("DamageFeedback"):Init()
require("ArmorHandler"):Init()
require("CharacterService"):Init()
require("SettingsService"):Init()
require("ItemService"):Init()
require("SpawnZoneHandler"):Init()
require("PartyEventHandler"):Init()
require("PlayerNoCollideService"):Init()
require("AlphaRewardService"):Init()

require("PartyHandler") -- TODO: Init method