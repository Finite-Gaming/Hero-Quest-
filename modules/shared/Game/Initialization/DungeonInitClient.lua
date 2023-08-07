--- Main injection point for the client (dungeon)
-- @classmod DungeonInitClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInitClient = {}

function DungeonInitClient:Init()
    require("UserDataClient"):Init()
    require("UserSettingsClient"):Init()
    require("UserUpgradesClient"):Init()

    require("ProjectileTypeProvider"):Init()
    require("ProjectileCacher"):Init()
    require("ProjectileService"):Init()
    require("ProjectileEffectsClient"):Init()

    require("ClientOverlapParams"):Init()
    require("NPCOverlapParams"):Init()
    require("SoundModifier"):Init()
    require("VoicelineService"):Init()
    require("SoundPlayer"):Init()
    require("DamageFeedbackClient"):Init()

    require("GuiTemplateProvider"):Init()
    require("ClientTemplateProvider"):Init()
    require("TotalEnemiesKilledClient"):Init()
    require("ClientClassBinders"):Init()
    require("CharacterServiceClient"):Init()
    require("AttackTelegrapherClient"):Init()

    require("ItemRewardClient"):Init()
    require("AvatarCaptionService"):Init()
    require("EffectPlayerClient"):Init()
    require("ApplyImpulseClient"):Init()
    require("BottomCaptionService"):Init()
    require("NotificationService"):Init()

    require("DungeonTimerClient"):Init()
    require("DoorOpenerClient"):Init()
    require("CleaverTossHandler"):Init()
end

return DungeonInitClient