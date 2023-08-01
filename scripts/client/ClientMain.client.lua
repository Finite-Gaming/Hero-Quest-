--- Main injection point for the client
-- @classmod ClientMain
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameManager = require("GameManager")

if GameManager:IsLobby() then
    warn("initializing lobby")
    require("LobbyInitClient"):Init()
elseif GameManager:IsDungeon() then
    warn("initializing dungeon")
    require("DungeonInitClient"):Init()
else
    warn("initializing nothing")
end