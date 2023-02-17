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

local NPCSpawner = {}

function NPCSpawner:Init()
    PhysicsService:RegisterCollisionGroup("NPC")
    PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)

    self._raycastParams = RaycastParams.new()
    self._raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
    self._raycaster = Raycaster.new(self._raycastParams)
    self._raycaster:Whitelist(workspace.Map)

    self.RoomCleared = Signal.new()

    self._pointDict = {}

    for _, roomFolder in ipairs(workspace.Rooms:GetChildren()) do
        local masterPart = roomFolder.PatrolPoints
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

function NPCSpawner:SetupZone(npcZoneName)
    local masterPart = assert(workspace.Rooms:FindFirstChild(npcZoneName)).PatrolPoints
    local spawnTypes = masterPart:FindFirstChild("SpawnTypes")
    if not spawnTypes then
        warn(("[NPCSpawner] - No SpawnTypes configuration for %q zone!"):format(npcZoneName))
        return
    end

    local totalEnemies = 0
    local deadEnemies = 0
    for _, npcName in ipairs(spawnTypes:GetChildren()) do
        local spawnAmount = npcName:GetAttribute("Amount")
        totalEnemies += spawnAmount
        for _ = 1, spawnAmount do

            self:SpawnEnemy(masterPart, npcName.Name).Died:Connect(function()
                deadEnemies += 1

                if deadEnemies == totalEnemies then
                    self.RoomCleared:Fire()
                end
            end)
        end
    end
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
    npc:PivotTo(CFrame.new(result.Position + (Vector3.yAxis * (npcSize.Y/2))))

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