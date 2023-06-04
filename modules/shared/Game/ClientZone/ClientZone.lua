---
-- @classmod ClientZone
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Signal = require("Signal")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ClientZone = setmetatable({}, BaseObject)
ClientZone.__index = ClientZone

function ClientZone.new(obj)
    local self = setmetatable(BaseObject.new(obj), ClientZone)

    self.Touched = Signal.new()
    self.OnEnter = Signal.new()
    self.OnLeave = Signal.new()
    self._inZone = false

    self._maid:AddTask(obj.Touched:Connect(function(hitPart)
        if self._inZone then
            return
        end

        local character = Players.LocalPlayer.Character
        if not character then
            return
        end

        if hitPart:IsDescendantOf(character) and hitPart.Name == "HumanoidRootPart" then
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then
                return
            end
            if humanoid.Health <= 0 then
                return
            end
            local rootPart = humanoid.RootPart
            if not rootPart then
                return
            end

            self._inZone = true
            self.OnEnter:Fire(rootPart, character)
            self.Touched:Fire(rootPart, character)

            local overlapParams = OverlapParams.new()
            overlapParams.FilterType = Enum.RaycastFilterType.Include
            overlapParams.FilterDescendantsInstances = {rootPart}
            overlapParams.MaxParts = 1

            self._maid.TouchUpdate = RunService.Heartbeat:Connect(function()
                if #workspace:GetPartsInPart(self._obj, overlapParams) == 0 then
                    self._maid.TouchUpdate = nil
                    self._inZone = false

                    self.OnLeave:Fire(rootPart, character)
                    return
                end
            end)
        end
    end))

    return self
end

return ClientZone