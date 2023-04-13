---
-- @classmod ClientZone
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Signal = require("Signal")

local Players = game:GetService("Players")

local ClientZone = setmetatable({}, BaseObject)
ClientZone.__index = ClientZone

function ClientZone.new(obj)
    local self = setmetatable(BaseObject.new(obj), ClientZone)

    self.Touched = Signal.new() -- TODO: OnEnter, OnLeave
    -- self._inZone = false

    self._maid:AddTask(obj.Touched:Connect(function(hitPart)
        local character = Players.LocalPlayer.Character
        if not character then
            return
        end

        if hitPart:IsDescendantOf(character) then
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then
                return
            end
            if humanoid.Health <= 0 then
                return
            end

            self.Touched:Fire(hitPart, character)
        end
    end))

    return self
end

return ClientZone