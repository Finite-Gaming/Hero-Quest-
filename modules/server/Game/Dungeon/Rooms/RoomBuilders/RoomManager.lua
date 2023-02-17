---
-- @classmod RoomManager
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RoomBuilders = require("RoomBuilders")
local NPCSpawner = require("NPCSpawner")
local DoorOpener = require("DoorOpener")

local RoomManager = {}

function RoomManager:Init()
    self._dungeonTag = assert(workspace:GetAttribute("DungeonTag"), "No DungeonTag attribute under workspace!")
    self._totalRooms = #workspace.Rooms:GetChildren()
    self._currentRoom = 0

    self:_setupRoom("1")

    NPCSpawner.RoomCleared:Connect(function()
        self:ProgressRoom()
    end)
end

function RoomManager:GetActiveRoom()
    return self._currentRoom
end

function RoomManager:OpenDoor(room)
    local door = workspace.Rooms[room].SpikeWall

    DoorOpener:OpenDoor(door)
end

function RoomManager:ProgressRoom()
    local lastRoom = self._currentRoom
    local newRoom = math.clamp(lastRoom + 1, 0, self._totalRooms)
    if lastRoom == newRoom then
        return
    end

    self:OpenDoor(tostring(newRoom))

    self._currentRoom = newRoom
    if newRoom + 1 > self._totalRooms then
        return
    end
    self:_setupRoom(tostring(newRoom + 1))
end

function RoomManager:_setupRoom(roomName)
    NPCSpawner:SetupZone(roomName)

    local initFunction = RoomBuilders[("%s%s"):format(self._dungeonTag, roomName)]
    if initFunction then
        initFunction()
    end
end

return RoomManager