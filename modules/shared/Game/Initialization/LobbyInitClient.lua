--- Main injection point for the client (lobby)
-- @classmod LobbyInitClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local LobbyInitClient = {}

function LobbyInitClient:Init()
    require("ContentHelper"):Init()
    require("IntroductionSceneClient"):Init()
    require("LoadingScreen"):Init()

    require("PartyServiceClient"):Init()
    require("InviteClient"):Init()
    -- require("BlockRenderer"):Init()
    -- require("PortalRenderer"):Init()
    require("ClientZones"):Init()
end

return LobbyInitClient