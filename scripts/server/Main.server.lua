--- Main injection point for the server
-- @classmod Main
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameManager = require("GameManager")

require("CameraShakeService"):Init()

if GameManager:IsLobby() then
    require("LobbyInit"):Init()
elseif GameManager:IsDungeon() then
    require("DungeonInit"):Init()
end