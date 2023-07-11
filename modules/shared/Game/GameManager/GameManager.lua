---
-- @classmod BaseService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local LOBBY_IDS = {
    [9323803256] = true;
}
local DUNGEON_IDS = {
    [9678777751] = true;
    [12115951613] = true;
}

local gamePlaceId = workspace:GetAttribute("SimulatedPlaceId") or game.PlaceId
if gamePlaceId == 0 then
    error("Publish this place before continuing")
end

local BaseService = {}

function BaseService:IsLobby(placeId)
    return not not LOBBY_IDS[placeId or gamePlaceId]
end

function BaseService:IsDungeon(placeId)
    return not not DUNGEON_IDS[placeId or gamePlaceId]
end

return BaseService