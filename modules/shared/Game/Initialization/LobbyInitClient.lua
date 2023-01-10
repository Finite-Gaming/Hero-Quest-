--- Main injection point for the client (lobby)
-- @classmod LobbyInitClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local LobbyInitClient = {}

function LobbyInitClient:Init()
    require("LoadingScreen"):Init()

    require("BlockRenderer"):Init()
    require("PortalRenderer"):Init()
end

return LobbyInitClient