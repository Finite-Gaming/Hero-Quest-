---
-- @classmod AlignCFrame
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local AlignPosition = require("AlignPosition")
local AlignOrientation = require("AlignOrientation")

--[[
    0 = both
    1 = align position
    2 = align orientation
]]

local PROPERTY_MAP = {
    Parent = 0;

    RigidityEnabled = 0;
    Responsiveness = 0;

    Attachment0 = 0;
    Attachment1 = 0;
    Enabled = 0;
    Mode = 0;

    MaxForce = 1;
    MaxVelocity = 1;

    ReactionForceEnabled = 1;
    ApplyAtCenterOfMass = 1;

    PrimaryAxisOnly = 2;
    ReactionTorqueEnabled = 2;

    MaxAngularVelocity = 2;
    MaxTorque = 2;
}

local AlignCFrame = setmetatable({}, BaseObject)
AlignCFrame.__index = AlignCFrame

function AlignCFrame.new(att0, att1)
    local self = setmetatable(BaseObject.new(), AlignCFrame)

    self._alignPosition = self._maid:AddTask(AlignPosition.new(att0, att1))
    self._alignOrientation = self._maid:AddTask(AlignOrientation.new(att0, att1))

    self._movers = {self._alignPosition, self._alignOrientation}

    return self
end

function AlignCFrame:_setDouble(property, value)
    for _, mover in ipairs(self._movers) do
        mover[property] = value
    end
end

function AlignCFrame:__newindex(index, value)
    local indexType = PROPERTY_MAP[index]
    if indexType then
        if indexType == 0 then
            self:_setDouble(index, value)
        else
            self._movers[indexType][index] = value
        end
    else
        rawset(self, index, value)
    end
end

return AlignCFrame