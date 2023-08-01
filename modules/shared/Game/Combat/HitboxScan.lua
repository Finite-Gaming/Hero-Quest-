---
-- @classmod HitboxScan
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local HitboxScan = setmetatable({}, BaseObject)
HitboxScan.__index = HitboxScan

function HitboxScan.new(obj)
    local self = setmetatable(BaseObject.new(obj), HitboxScan)

    return self
end

return HitboxScan