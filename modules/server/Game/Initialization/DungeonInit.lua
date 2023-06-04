--- Main injection point for the server (dungeon)
-- @classmod DungeonInit
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInit = {}

function DungeonInit:Init()
    require("ServerTemplateProvider"):Init()
    require("NPCOverlapParams"):Init()
    require("NPCSpawner"):Init()
    require("TeamLocker"):Init()
    require("DoorOpener"):Init()
    require("RoomManager"):Init()
    require("CleaverTossServer"):Init()
    -- require("StartBubble"):Init()
end

return DungeonInit