---
-- @classmod IKPedalClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local IKLegClient = require("IKLegClient")

local IKPedalClient = setmetatable({}, BaseObject)
IKPedalClient.__index = IKPedalClient

function IKPedalClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), IKPedalClient)

    self._initFolder = self._obj:WaitForChild("IKPedal")
    self._ikLegs = {}
    for _, folder in ipairs(self._initFolder:GetChildren()) do
        local ikLeg = self._maid:AddTask(IKLegClient.new(self._obj, folder))
        table.insert(self._ikLegs, ikLeg)
    end

    return self
end

return IKPedalClient