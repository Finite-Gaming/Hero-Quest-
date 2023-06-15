---
-- @classmod NPCSpawner
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local PhysicsService = game:GetService("PhysicsService")

local ServerTemplateProvider = require("ServerTemplateProvider")
local ServerClassBinders = require("ServerClassBinders")
local ModelUtils = require("ModelUtils")
local Raycaster = require("Raycaster")
local Signal = require("Signal")
local Maid = require("Maid")
local VoicelineService = require("VoicelineService")

local NPCSpawner = {}

function NPCSpawner:Init()
    PhysicsService:RegisterCollisionGroup("NPC")
    PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)

    self._totalDeadEnemies = 0

    self._raycastParams = RaycastParams.new()
    self._raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
    self._raycaster = Raycaster.new(self._raycastParams)
    self._raycaster:Whitelist(workspace.Map)

    self.RoomCleared = Signal.new()

    self._pointDict = {}

    for _, roomFolder in ipairs(workspace.Rooms:GetChildren()) do
        local masterPart = roomFolder:FindFirstChild("PatrolPoints")
        if not masterPart then
            continue
        end
        local npcZone = roomFolder.Name
        masterPart.Transparency = 1
        local points = {}

        for _, point in ipairs(masterPart:GetChildren()) do
            if not point:IsA("Attachment") then
                continue
            end

            table.insert(points, point)
        end

        self._pointDict[npcZone] = points
    end
end

function NPCSpawner:GetDeadEnemies()
    return self._totalDeadEnemies
end

function NPCSpawner:SetupZone(npcZoneName)
    local masterPart = assert(workspace.Rooms:FindFirstChild(npcZoneName)):FindFirstChild("PatrolPoints")
    if not masterPart then
        return
    end 
    local spawnTypes = masterPart:FindFirstChild("SpawnTypes")
    if not spawnTypes then
        warn(("[NPCSpawner] - No SpawnTypes configuration for %q zone!"):format(npcZoneName))
        return
    end

    local totalEnemies = 0
    local deadEnemies = 0
    local zoneMaid = Maid.new()
    local enemies = {}

    for _, npcName in ipairs(spawnTypes:GetChildren()) do
        local spawnAmount = npcName:GetAttribute("Amount")
        totalEnemies += spawnAmount
        for _ = 1, spawnAmount do
            local npc = self:SpawnEnemy(masterPart, npcName.Name)
            local enemy = npc:GetObject()
            local variant = enemy:GetAttribute("Variant") or "Orc"
            local rootPart = enemy.HumanoidRootPart
            local chaseChance = 2

            table.insert(enemies, npc)

            zoneMaid:AddTask(enemy.Destroying:Connect(function()
                deadEnemies += 1
                table.remove(enemies, table.find(enemies, npc))

                if deadEnemies == totalEnemies then
                    self._totalDeadEnemies += totalEnemies
                    zoneMaid:Destroy()
                    self.RoomCleared:Fire()
                end
            end))
            zoneMaid:AddTask(npc.KilledPlayer:Connect(function()
                VoicelineService:PlayRandomGroupForZone(("%s_Kill"):format(variant), npcZoneName, rootPart)
            end))
            zoneMaid:AddTask(npc.StateChanged:Connect(function(state)
                if state == "Chase" then
                    if math.random(1, chaseChance) ~= chaseChance then
                        return
                    end

                    VoicelineService:PlayRandomGroupForZone(("%s_Chase"):format(variant), npcZoneName, rootPart, true)
                    chaseChance = 10
                end
            end))
            zoneMaid:AddTask(npc.DamageTracker.Damaged:Connect(function(_, _, healthP)
                if healthP <= 0.25 then
                    if math.random(1, 10) == 1 then
                        VoicelineService:PlayRandomGroupForZone(("%s_Damaged"):format(variant), npcZoneName, rootPart)
                    end
                end
            end))

            task.wait() -- stop spam replication
        end
    end

    zoneMaid:AddTask(task.spawn(function()
        while true do
            task.wait(math.random(7, 17))
            local chosenNpc = enemies[math.random(1, #enemies)]
            local enemy = chosenNpc:GetObject()

            if chosenNpc:GetState() == "Idle" then
                local sound = VoicelineService:PlayGroup(VoicelineService:GetRandomGroup(("%s_Ambient"):format(enemy:GetAttribute("Variant") or "Orc")), enemy.HumanoidRootPart)
                if sound then
                    sound.Ended:Wait()
                end
            end
        end
    end))
end

function NPCSpawner:_getRandomPoint(masterPart)
    local points = self._pointDict[masterPart.Parent.Name]
    return points[math.random(1, #points)]
end

function NPCSpawner:SpawnEnemy(masterPart, npcName)
    local npc = ServerTemplateProvider:Get(("%sTemplate"):format(npcName))
    for _, part in ipairs(ModelUtils.getParts(npc)) do
        part.CollisionGroup = "NPC"
    end

    local tries = 0

    local spawnPoint = self:_getRandomPoint(masterPart)
    local result = self._raycaster:Cast(spawnPoint.WorldPosition, -Vector3.yAxis * 16)
    while not result do
        spawnPoint = self:_getRandomPoint(masterPart)
        result = self._raycaster:Cast(spawnPoint.WorldPosition, -Vector3.yAxis * 16)

        tries += 1

        if tries > 10 then
            warn(("[NPCSpawner] - Failed to get valid spawnPoint location for NPC %q"):format(npcName))
            return
        end
    end

    local _, npcSize = npc:GetBoundingBox()
    npc:PivotTo(CFrame.new(result.Position + (Vector3.yAxis * npc.Humanoid.HipHeight)))

    local npcFolder = masterPart.Parent:FindFirstChild("NPC")
    if not npcFolder then
        npcFolder = Instance.new("Folder")
        npcFolder.Name = "NPC"
        npcFolder.Parent = masterPart.Parent
    end

    npc.Parent = npcFolder
    return ServerClassBinders.NPC:BindAsync(npc)
end

return NPCSpawner