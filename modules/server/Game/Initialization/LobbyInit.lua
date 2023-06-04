--- Main injection point for the server (lobby)
-- @classmod LobbyInit
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local LobbyInit = {}

function LobbyInit:Init()
    workspace.Lobby.Assets:Destroy()

    require("PartyService"):Init()
    require("ContentHelper"):Init()
    require("SpawnZoneHandler"):Init()
    require("AlphaRewardService"):Init()
    -- require("PartyEventHandler"):Init()
    -- require("PartyHandler") -- TODO: Init method
end

return LobbyInit