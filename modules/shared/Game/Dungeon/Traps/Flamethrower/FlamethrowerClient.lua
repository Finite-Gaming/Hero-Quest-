---
-- @classmod FlamethrowerClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local FlamethrowerConstants = require("FlamethrowerConstants")

local FlamethrowerClient = setmetatable({}, BaseObject)
FlamethrowerClient.__index = FlamethrowerClient

function FlamethrowerClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), FlamethrowerClient)

    
    return self
end

return FlamethrowerClient