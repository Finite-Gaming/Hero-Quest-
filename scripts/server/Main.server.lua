--- Main injection point for the server
-- @classmod Main
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameManager = require("GameManager")

require("ServerClassBinders"):Init()

require("MarketplacePurchaseHandler"):Init()
require("DamageFeedback"):Init()
require("ArmorHandler"):Init()
require("CharacterService"):Init()
require("UserDataService"):Init()
require("SoundPlayer"):Init()
require("SoundPlayerService"):Init()
require("EffectPlayerService"):Init()
require("ApplyImpulse"):Init()
require("VoicelineService"):Init()
require("PlayerNoCollideService"):Init()

if GameManager:IsLobby() then
    require("LobbyInit"):Init()
elseif GameManager:IsDungeon() then
    require("DungeonInit"):Init()
end