--- Main injection point for the client
-- @classmod ClientMain
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameManager = require("GameManager")

require("UserDataClient"):Init()

require("GuiTemplateProvider"):Init()
require("ClientClassBinders"):Init()

require("ItemRewardClient"):Init()
require("DamageFeedbackClient"):Init()
require("ArmorRenderer"):Init()
require("SoundPlayer"):Init()
require("EffectPlayerClient"):Init()
require("ApplyImpulseClient"):Init()
require("BottomCaptionService"):Init()

if GameManager:IsLobby() then
    require("LobbyInitClient"):Init()
elseif GameManager:IsDungeon() then
    require("DungeonInitClient"):Init()
end