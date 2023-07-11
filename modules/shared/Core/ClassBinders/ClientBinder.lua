---
-- @classmod ClientBinder
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")

local RunService = game:GetService("RunService")

local ClientBinder = {}

function ClientBinder.new(name, class)
    if not RunService:IsClient() then
        warn("[ClientBinder] - ClientBinder is only meant to be used on the client, please change this.")
        return ClassBinder.new(name, class)
    end

    return ClassBinder.new(name, class, true)
end

return ClientBinder