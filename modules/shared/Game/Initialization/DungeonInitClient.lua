--- Main injection point for the client (dungeon)
-- @classmod DungeonInitClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonInitClient = {}

function DungeonInitClient:Init()
    require("DoorOpenerClient"):Init()
end

return DungeonInitClient