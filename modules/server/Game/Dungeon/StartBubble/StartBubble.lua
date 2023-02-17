---
-- @classmod StartBubble
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local RoomManager = require("RoomManager")

local StartBubble = {}

function StartBubble:Init()
    local bubble = workspace.StartBubble

    local connection; connection = bubble.Touched:Connect(function(part)
        for _, player in ipairs(Players:GetPlayers()) do
            if part:FindFirstAncestor(player.Name) then
                RoomManager:ProgressRoom()
                connection:Disconnect()
                bubble:Destroy()
            end
        end
    end)
end

return StartBubble