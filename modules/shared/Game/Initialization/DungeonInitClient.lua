--- Main injection point for the client (dungeon)
-- @classmod DungeonInitClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInitClient = {}

function DungeonInitClient:Init()
    require("UserDataClient"):Init()
    warn("init 1")
    require("UserSettingsClient"):Init()
    warn("init 2")
    require("UserUpgradesClient"):Init()
    warn("init 3")

    require("ProjectileTypeProvider"):Init()
    warn("init 4")
    require("ProjectileCacher"):Init()
    warn("init 5")
    require("ProjectileService"):Init()
    warn("init 6")
    require("ProjectileEffectsClient"):Init()
    warn("init 7")

    require("ClientOverlapParams"):Init()
    warn("init 8")
    require("NPCOverlapParams"):Init()
    warn("init 9")
    require("SoundModifier"):Init()
    warn("init 10")
    require("VoicelineService"):Init()
    warn("init 11")
    require("SoundPlayer"):Init()
    warn("init 12")
    require("DamageFeedbackClient"):Init()
    warn("init 13")

    require("GuiTemplateProvider"):Init()
    warn("init 14")
    require("ClientTemplateProvider"):Init()
    warn("init 15")
    require("TotalEnemiesKilledClient"):Init()
    warn("init 16")
    require("ClientClassBinders"):Init()
    warn("init 17")
    require("CharacterServiceClient"):Init()
    warn("init 18")
    require("AttackTelegrapherClient"):Init()
    warn("init 1")

    require("ItemRewardClient"):Init()
    warn("init 19")
    require("AvatarCaptionService"):Init()
    warn("init 20")
    require("EffectPlayerClient"):Init()
    warn("init 21")
    require("ApplyImpulseClient"):Init()
    warn("init 22")
    require("BottomCaptionService"):Init()
    warn("init 23")
    require("NotificationService"):Init()
    warn("init 24")

    require("DungeonTimerClient"):Init()
    warn("init 25")
    require("DoorOpenerClient"):Init()
    warn("init 26")
    require("CleaverTossHandler"):Init()
    warn("init 27")
end

return DungeonInitClient