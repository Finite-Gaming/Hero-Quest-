--- Main injection point for the server (dungeon)
-- @classmod DungeonInit
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInit = {}

function DungeonInit:Init()
    require("ServerTemplateProvider"):Init()
    require("NPCSpawner"):SpawnEnemies(workspace.NPC["1"])
end

return DungeonInit