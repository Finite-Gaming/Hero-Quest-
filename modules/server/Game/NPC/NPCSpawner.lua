---
-- @classmod NPCSpawner
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local PhysicsService = game:GetService("PhysicsService")

local ServerTemplateProvider = require("ServerTemplateProvider")
local ServerClassBinders = require("ServerClassBinders")
local ModelUtils = require("ModelUtils")

local NPCSpawner = {}

function NPCSpawner:Init()
    PhysicsService:RegisterCollisionGroup("NPC")
    PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)

    for _ = 1, 3 do
        self:SpawnEnemy(workspace.NPC["1"])
    end
end

function NPCSpawner:SpawnEnemy(npcZone)
    local npc = ServerTemplateProvider:Get("EnemyTemplate")
    for _, part in ipairs(ModelUtils.getParts(npc)) do
        part.CollisionGroup = "NPC"
    end

    npc.Parent = npcZone
    ServerClassBinders.NPC:Bind(npc)
end

return NPCSpawner