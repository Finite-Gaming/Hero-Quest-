--- Main injection point for the server
-- @classmod Main
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameManager = require("GameManager")

require("ServerClassBinders"):Init()

require("UserDataService"):Init()
require("ProgressionHelper"):Init()
require("MarketplacePurchaseHandler"):Init()

require("DamageFeedback"):Init()
require("PlayScreenHandler"):Init()
require("CharacterService"):Init()
require("SoundModifier"):Init()
require("SoundPlayer"):Init()
require("SoundPlayerService"):Init()
require("EffectPlayerService"):Init()
require("ApplyImpulse"):Init()
require("VoicelineService"):Init()
require("PlayerNoCollideService"):Init()
require("PetService"):Init()

if GameManager:IsLobby() then
    require("LobbyInit"):Init()
elseif GameManager:IsDungeon() then
    require("DungeonInit"):Init()
end