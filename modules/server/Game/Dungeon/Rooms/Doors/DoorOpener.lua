---
-- @classmod DoorOpener
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local DoorOpenerConstants = require("DoorOpenerConstants")

local DoorOpener = {}

function DoorOpener:Init()
    self._remoteEvent = Network:GetRemoteEvent(DoorOpenerConstants.REMOTE_EVENT_NAME)
end

function DoorOpener:OpenDoor(door)
    if door:IsA("Folder") then
        for _, doorChild in ipairs(door:GetChildren()) do
            doorChild:SetAttribute("Opened", true)
        end
    else
        door:SetAttribute("Opened", true)
    end

    self._remoteEvent:FireAllClients(door)
end

return DoorOpener