--- Main injection point for the server (dungeon)
-- @classmod DungeonInit
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInit = {}

function DungeonInit:Init()
    require("ServerTemplateProvider"):Init()
    require("NPCSpawner"):Init()
    require("TeamLocker"):Init()
end

return DungeonInit