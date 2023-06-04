--- Does cool things
-- @classmod PlayerInterface
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

return
    RunService:IsClient() and
        require("ClientClassBinders")
    or
        require("ServerClassBinders")
