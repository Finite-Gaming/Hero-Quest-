---
-- @classmod PuzzleBridge
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local PuzzleBridgeConstants = require("PuzzleBridgeConstants")

local PuzzleBridge = setmetatable({}, BaseObject)
PuzzleBridge.__index = PuzzleBridge

function PuzzleBridge.new(obj)
    local self = setmetatable(BaseObject.new(obj), PuzzleBridge)

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = PuzzleBridgeConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    return self
end

function PuzzleBridge:Spin(deg)
    deg = math.rad(deg)

    self._remoteEvent:FireAllClients(deg)
    task.wait(PuzzleBridgeConstants.SPIN_TIME)
    self._obj.FloorSection:PivotTo(self._obj.FloorSection.PrimaryPart.CFrame * CFrame.Angles(0, deg, 0))
end

return PuzzleBridge