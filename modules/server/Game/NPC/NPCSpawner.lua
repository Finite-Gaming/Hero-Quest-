---
-- @classmod NPCSpawner
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerTemplateProvider = require("ServerTemplateProvider")
local ServerClassBinders = require("ServerClassBinders")

local NPCSpawner = {}

function NPCSpawner:SpawnEnemies(npcZone)
    local npc = ServerTemplateProvider:Get("EnemyTemplate")
    npc.Parent = npcZone
    ServerClassBinders.NPC:Bind(npc)
end

return NPCSpawner