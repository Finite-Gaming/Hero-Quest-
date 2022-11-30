local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

workspace.Lobby.Assets:Destroy()

require("CharacterService"):Init()
require("SettingsService"):Init()
require("SkinsService"):Init()
require("SpawnZoneHandler"):Init()
require("PlayerNoCollideService"):Init()
require("AlphaRewardService"):Init()
require("ServerClassBinders"):Init()