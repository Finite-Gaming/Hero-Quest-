--- Main injection point for the server (dungeon)
-- @classmod DungeonInit
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInit = {}

function DungeonInit:Init()
    local startTime = os.clock()
    require("PathfindingHelper"):Init()
    print(("Pathfinding initialization took %fs"):format(os.clock() - startTime))

    require("ProjectileTypeProvider"):Init()
    require("ProjectileCacher"):Init()
    require("ProjectileService"):Init()
    require("ProjectileHitHandler"):Init()

    require("NPCOverlapParams"):Init()
    require("HitscanPartService"):Init()
    require("ServerClassBinders"):Init()

    require("UserDataService"):Init()
    require("ProgressionHelper"):Init()
    require("TotalEnemiesKilled"):Init()
    require("MarketplacePurchaseHandler"):Init()

    require("DamageFeedback"):Init()
    require("PlayScreenHandler"):Init()
    require("SoundModifier"):Init()
    require("SoundPlayer"):Init()
    require("SoundPlayerService"):Init()
    require("VoicelineService"):Init()
    require("AttackTelegrapherService"):Init()

    require("PlayerNoCollideService"):Init()
    require("PetService"):Init()

    require("EffectPlayerService"):Init()
    require("ApplyImpulse"):Init()
    require("PhaseInAnimator"):Init()
    require("QuestUpdater"):Init()

    require("ServerTemplateProvider"):Init()
    require("NPCSpawner"):Init()
    require("RoomManager"):Init()
    require("CharacterOverlapParams"):Init()
    require("CharacterService"):Init()

    -- require("TeamLocker"):Init()
    require("DoorOpener"):Init()
    require("CleaverTossServer"):Init()
    -- require("StartBubble"):Init()
end

return DungeonInit