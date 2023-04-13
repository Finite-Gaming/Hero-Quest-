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

local RoomManager = {}

function RoomManager:Init()
    self._dungeonTag = assert(workspace:GetAttribute("DungeonTag"), "No DungeonTag attribute under workspace!")
    self._totalRooms = #workspace.Rooms:GetChildren()
    self._currentRoom = 0

    self._progressionData = DungeonData.ProgressionVoicelines

    self:_setupRoom("1")

    task.delay(3, function() -- replace this with a party joined yield later on
        if ProgressionHelper:IsNewPlayers() then
            ProgressionHelper:PlaySoundForScenario("Spawned", function()
                self:ProgressRoom()
            end)
        else
            ProgressionHelper:PlaySoundForScenario("Spawned")
            self:ProgressRoom()
        end
    end)

    NPCSpawner.RoomCleared:Connect(function()
        self:ProgressRoom()
    end)
end

function RoomManager:GetActiveRoom()
    return self._currentRoom
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
    NPCSpawner:SetupZone(roomName)

    local buildName = ("%s_%s"):format(self._dungeonTag, roomName)
    local initFunction = RoomBuilders[buildName]

    if initFunction then
        initFunction(self)
    end
end

return RoomManager