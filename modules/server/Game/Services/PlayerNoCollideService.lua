--- Disallows players colliding with eachother
-- @classmod SettingsService
-- @author unknown, frick

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PlayerNoCollideService = {}

-- Make connections for player join/character spawn
function PlayerNoCollideService:Init()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            for _, child in ipairs(character:GetChildren()) do
                self:_handlePart(child)
            end
            character.ChildAdded:Connect(function(child) -- GC will handle this connection
                self:_handlePart(child)
            end)
        end)
    end)
end

-- Add the part to the "Player" collision group so they cant collide with eachother
function PlayerNoCollideService:_handlePart(part)
    if part:IsA("BasePart") then
        part.CollisionGroup = "Player"
    end
end

return PlayerNoCollideService