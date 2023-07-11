--- Main injection point for the client (lobby)
-- @classmod LobbyInitClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local LobbyInitClient = {}

function LobbyInitClient:Init()
    require("UserDataClient"):Init()
    require("UserSettingsClient"):Init()

    require("GuiTemplateProvider"):Init()
    require("PartyServiceClient"):Init()
    require("ClientTemplateProvider"):Init()
    require("TotalEnemiesKilledClient"):Init()
    require("ClientClassBinders"):Init()
    require("CharacterServiceClient"):Init()

    require("ContentHelper"):Init()
    require("IntroductionSceneClient"):Init()
    require("LoadingScreen"):Init()

    require("SoundModifier"):Init()
    require("VoicelineService"):Init()
    require("SoundPlayer"):Init()

    require("ItemRewardClient"):Init()
    require("DamageFeedbackClient"):Init()
    require("AvatarCaptionService"):Init()
    require("EffectPlayerClient"):Init()
    require("ApplyImpulseClient"):Init()
    require("BottomCaptionService"):Init()
    require("NotificationService"):Init()

    require("InviteClient"):Init()

    require("ClientZones"):Init()
end

return LobbyInitClient