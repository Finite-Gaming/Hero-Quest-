---
-- @classmod MovementLocker
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local MovementLocker = setmetatable({}, BaseObject)
MovementLocker.__index = MovementLocker

function MovementLocker.new(obj)
    local self = setmetatable(BaseObject.new(obj), MovementLocker)

    return self
end

return MovementLocker