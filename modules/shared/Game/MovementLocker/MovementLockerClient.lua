---
-- @classmod MovementLockerClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local Players = game:GetService("Players")

local MovementLockerClient = setmetatable({}, BaseObject)
MovementLockerClient.__index = MovementLockerClient

function MovementLockerClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), MovementLockerClient)

    if self._obj ~= Players.LocalPlayer.Character then
        return self
    end

    self._maid:BindAction(
        "__movementLocker",
        function()
            return Enum.ContextActionResult.Sink
        end,
        false,
        unpack(Enum.PlayerActions:GetEnumItems())
    )

    return self
end

return MovementLockerClient