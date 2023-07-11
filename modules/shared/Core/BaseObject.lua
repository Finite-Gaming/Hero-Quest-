--- Base class with maid and destroy/destroying event
-- @classmod BaseObject
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Maid = require("Maid")
local Signal = require("Signal")

local BaseObject = {}
BaseObject.__index = BaseObject

function BaseObject.new(obj)
    local self = setmetatable({}, BaseObject)

    self._maid = Maid.new()
    self._obj = obj
    self.Destroying = self._maid:AddTask(Signal.new())

    return self
end

function BaseObject:GetObject()
    return self._obj
end

function BaseObject:Destroy()
    self.Destroying:Fire()
    self._maid:Destroy()
    self._maid = nil
    setmetatable(self, nil)
end

return BaseObject