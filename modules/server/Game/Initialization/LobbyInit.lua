--- Main injection point for the server (lobby)
-- @classmod LobbyInit
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local LobbyInit = {}

function LobbyInit:Init()
    workspace.Lobby.Assets:Destroy()

    require("ServerClassBinders"):Init()

    require("UserDataService"):Init()
    require("ProgressionHelper"):Init()
    require("TotalEnemiesKilled"):Init()
    require("MarketplacePurchaseHandler"):Init()

    require("ContentHelper"):Init()
    require("CharacterService"):Init()
    require("PlayScreenHandler"):Init()

    require("DamageFeedback"):Init()
    require("SoundModifier"):Init()
    require("SoundPlayer"):Init()
    require("SoundPlayerService"):Init()
    require("VoicelineService"):Init()
    require("EffectPlayerService"):Init()
    require("ApplyImpulse"):Init()

    require("PlayerNoCollideService"):Init()
    require("PetService"):Init()

    require("PartyService"):Init()
    require("SpawnZoneHandler"):Init()
    require("AlphaRewardService"):Init()
end

return LobbyInit