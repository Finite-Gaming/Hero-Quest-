---
-- @classmod RoomManager
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RoomBuilders = require("RoomBuilders")
local NPCSpawner = require("NPCSpawner")
local DoorOpener = require("DoorOpener")
local DungeonDefeatedTasks = require("DungeonDefeatedTasks")
local ProgressionHelper = require("ProgressionHelper")
local DungeonData = require("DungeonData")
local StudioDebugConstants = require("StudioDebugConstants")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local RoomManager = {}

function RoomManager:Init()
    self._dungeonTag = assert(workspace:GetAttribute("DungeonTag"), "No DungeonTag attribute under workspace!")
    self._totalRooms = #workspace.Rooms:GetChildren()

    self._progressionData = DungeonData[self._dungeonTag].ProgressionVoicelines

    local starterRoom = "1"
    if RunService:IsStudio() then
        starterRoom = StudioDebugConstants.DungeonSpawnRoom or starterRoom
    end

    self._currentRoom = tonumber(starterRoom) - 1
    self:_setupRoom(starterRoom)
    self:SetSpawn(starterRoom)

    for _, room in ipairs(workspace.Rooms:GetChildren()) do
        local spawnPart = room:FindFirstChild("SpawnPart")
        if spawnPart then
            spawnPart.Transparency = 1
        end
    end

    if starterRoom == "1" then
        task.spawn(function()
            local startTime = os.clock()
            ProgressionHelper:WaitForAllPlayers()
            local waitTime = task.wait(3)
            local playTime = DungeonData[self._dungeonTag].PlayTime * 60
            workspace:SetAttribute("DungeonEndTime", workspace:GetServerTimeNow() + playTime)
            task.delay(playTime, function()
                TeleportService:TeleportAsync(9323803256, Players:GetPlayers())
            end)
            local timeDiff = os.clock() - startTime

            print(("[RoomManager] - Waited for all players to join, elapsed time: %f (Yield time: %f)")
                :format(timeDiff, timeDiff - waitTime))

            if ProgressionHelper:IsNewPlayers() then
                ProgressionHelper:PlaySoundForScenario("Spawned", function()
                    self:ProgressRoom()
                end)
            else
                ProgressionHelper:PlaySoundForScenario("Spawned")
                self:ProgressRoom()
            end
        end)
    else
        self:_setupRoom(tostring(tonumber(starterRoom + 1)))
    end

    NPCSpawner.RoomCleared:Connect(function()
        self:ProgressRoom()
    end)
end

function RoomManager:GetActiveRoom()
    return self._currentRoom
end

function RoomManager:SetSpawn(room)
    self._spawn = workspace.Rooms:FindFirstChild(tostring(room)).SpawnPart
end

function RoomManager:GetSpawn()
    return self._spawn
end

function RoomManager:OpenDoor(room)
    local door = workspace.Rooms[room]:FindFirstChild("Doors")

    if door then
        DoorOpener:OpenDoor(door)
    end
end

function RoomManager:ProgressRoom()
    local lastRoom = self._currentRoom
    local newRoom = math.clamp(lastRoom + 1, 0, self._totalRooms)
    local nextRoom = math.clamp(newRoom + 1, 0, self._totalRooms)
    if lastRoom == newRoom then
        return
    end

    local lastRoomFolder = workspace.Rooms:FindFirstChild(tostring(lastRoom))
    if lastRoomFolder and lastRoomFolder:GetAttribute("MiniBossRoom") then
        ProgressionHelper:PlaySoundForScenario("MiniBossCleared")
    end

    if nextRoom ~= newRoom then
        local nextRoomFolder = workspace.Rooms:FindFirstChild(tostring(nextRoom))
        if nextRoomFolder and nextRoomFolder:GetAttribute("BossRoom") then
            ProgressionHelper:PlaySoundForScenario("BossFight")
        end
    end

    self:SetSpawn(newRoom)
    self:OpenDoor(tostring(newRoom))

    self._currentRoom = newRoom
    if newRoom == self._totalRooms then
        ProgressionHelper:PlaySoundForScenario("BossDeath", function()
            DungeonDefeatedTasks:Run()
        end)
    end
    if newRoom + 1 > self._totalRooms then
        return
    end
    self:_setupRoom(tostring(nextRoom))
end

function RoomManager:_setupRoom(roomName)
    roomName = tostring(math.clamp(tonumber(roomName), 0, self._totalRooms))
    NPCSpawner:SetupZone(roomName)

    local buildName = ("%s_%s"):format(self._dungeonTag, roomName)
    local initFunction = RoomBuilders[buildName]

    if initFunction then
        initFunction(self)
    end
end

return RoomManager