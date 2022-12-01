--- Moves any player that leaves spawn
-- @classmod SpawnZoneHandler
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Zones = require("Zones")

local SpawnZoneHandler = {}

-- Teleports the player back to spawn when they leave the spawn zone
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