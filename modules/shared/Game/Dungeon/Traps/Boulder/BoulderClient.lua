---
-- @classmod BoulderClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local BoulderConstants = require("BoulderConstants")

local Players = game:GetService("Players")

local BoulderClient = setmetatable({}, BaseObject)
BoulderClient.__index = BoulderClient

function BoulderClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), BoulderClient)

    self._remoteEvent = self._obj:WaitForChild(BoulderConstants.REMOTE_EVENT_NAME)

    self._boulder = self._obj.Boulder
    self._trigger = self._obj.Trigger

    for _, part in ipairs({self._boulder, self._trigger}) do
        local lastFire = 0

        self._maid:AddTask(part.Touched:Connect(function(hitPart)
            local character = Players.LocalPlayer.Character
            if not character then
                return
            end

            if hitPart:IsDescendantOf(character) then
                local fireTime = os.clock()
                if fireTime - lastFire > 0.1 then
                    lastFire = fireTime
                    self._remoteEvent:FireServer(part == self._boulder and "Hit" or "Trigger")
                end
            end
        end))
    end

    return self
end

return BoulderClient