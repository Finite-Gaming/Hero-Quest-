---
-- @classmod SpawnZoneHandler
-- @author unknown, frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zones = require(ReplicatedStorage:WaitForChild("Zones"))

local SpawnZoneHandler = {}

function SpawnZoneHandler:Init()
    local lobbySpawn = workspace.Lobby.Spawn

    Zones.ZoneChanged:Connect(function(player: Player, zone: string)
        if zone == "Spawn" then
            local character = player.Character
            if character then
                local _, size = character:GetBoundingBox()
                local newPosition = lobbySpawn:GetPivot().Position + Vector3.new(0, size.Y / 2 + 1, 0)
                local charPivot = character:GetPivot()
                character:PivotTo(CFrame.fromMatrix(newPosition, charPivot.XVector, charPivot.YVector, charPivot.ZVector))
            end
        end
    end)
end

return SpawnZoneHandler