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

if game.PlaceId == 0 then
    error("Publish this place before continuing")
end

local BaseService = {}

function BaseService:IsLobby()
    return not not LOBBY_IDS[game.PlaceId]
end

function BaseService:IsDungeon()
    return not not DUNGEON_IDS[game.PlaceId]
end

return BaseService