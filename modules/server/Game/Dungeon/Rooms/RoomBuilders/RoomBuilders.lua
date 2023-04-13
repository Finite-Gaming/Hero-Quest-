---
-- @classmod RoomBuilders
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ServerClassBinders = require("ServerClassBinders")

local RoomBuilders = {}

function RoomBuilders.a_easy_5(roomManager)
    local puzzle = ServerClassBinders.SymbolPuzzle:BindAsync(workspace.SymbolPuzzle)

    puzzle.Solved:Once(function()
        roomManager:ProgressRoom()
        ServerClassBinders.PuzzleBridge:BindAsync(workspace.PuzzleBridge):Spin(90)
        ServerClassBinders.SymbolPuzzle:Unbind(workspace.SymbolPuzzle)
    end)
end

return RoomBuilders