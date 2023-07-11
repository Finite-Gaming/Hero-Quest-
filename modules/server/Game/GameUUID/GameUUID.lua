---
-- @classmod GameUUID
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local GameUUID = {}

function GameUUID:Init()
    if RunService:IsStudio() then
        self._uuid = HttpService:GenerateGUID(false)
    else
        self._uuid = game.JobId
    end
end

function GameUUID:Get()
    return self._uuid
end

return GameUUID