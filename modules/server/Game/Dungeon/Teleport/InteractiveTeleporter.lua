--- Does cool things
-- @classmod InteractiveTeleporter
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local BaseObject = require("BaseObject")

local InteractiveTeleporter = setmetatable({}, BaseObject)
InteractiveTeleporter.__index = InteractiveTeleporter

function InteractiveTeleporter.new(obj)
    local self = setmetatable(BaseObject.new(obj), InteractiveTeleporter)

    self._teleported = {}

    self._placeId = self._obj:GetAttribute("TeleportPlaceId")
    self._placeName = self._obj:GetAttribute("TeleportPlaceName")
    self._teleportDistance = self._obj:GetAttribute("TeleportDistance") or 10

    self._proximityPrompt = self._maid:AddTask(Instance.new("ProximityPrompt"))
    self._proximityPrompt.MaxActivationDistance = self._teleportDistance
    self._proximityPrompt.RequiresLineOfSight = false
    self._proximityPrompt.ActionText = ("Teleport%s")
        :format(self._placeName and (" To %s"):format(self._placeName) or "")

    self._proximityPrompt.Parent = self._obj

    self._maid:AddTask(self._proximityPrompt.Triggered:Connect(function(triggerPlayer)
        local toTeleport = {triggerPlayer}
        for _, player in ipairs(Players:GetPlayers()) do
            if player == triggerPlayer or self._teleported[player] then
                continue
            end

            local character = player.Character
            if not character then
                continue
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                continue
            end

            local rootPart = humanoid.RootPart
            if not rootPart then
                continue
            end

            local distance = (rootPart.Position - self._obj.Position).Magnitude
            if distance > self._teleportDistance then
                continue
            end

            self._teleported[player] = true
            table.insert(toTeleport, player)
        end

        TeleportService:TeleportAsync(self._placeId, toTeleport)
    end))

    return self
end

return InteractiveTeleporter