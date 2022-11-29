--- Emulates a rigid HingeConstraint using RigidConstraint
-- @classmod RigidHinge
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local RigidHinge = setmetatable({}, BaseObject)
RigidHinge.__index = RigidHinge

RigidHinge.AXIS_INDEX = {
    Roll = {
        PointAt = function(self, point)
            error("Not implemented")
        end;
    };
    Pitch = {
        SpringInitial = 0;
        PointAt = function(self, point)
            local headTarget = (self._att0.WorldCFrame * self._aimOffset):PointToObjectSpace(point)
            local distance = (self._att0.WorldPosition - point).Magnitude

            self._att0.Orientation = Vector3.zAxis * math.clamp(math.deg(math.asin(headTarget.Y/distance)), -15, 85)
        end;
    };
    Yaw = {
        SpringInitial = Vector3.zero;
        PointAt = function(self, point)
            local baseTarget = self._att0.Parent.CFrame:PointToObjectSpace(point) * (Vector3.one - Vector3.yAxis).Unit

            local yaw = math.deg(math.atan2(baseTarget.X, baseTarget.Z))
            self._att0.Orientation = Vector3.yAxis * (yaw + 90)
        end;
    };
}

function RigidHinge.new(obj, spring)
    local self = setmetatable(BaseObject.new(obj), RigidHinge)

    self._axis = assert(self._obj:GetAttribute("Axis"), "No Axis")
    self._axisIndex = self.AXIS_INDEX[self._axis]
    self._pointAt = self._axisIndex.PointAt
    self._aimOffset = self._obj:GetAttribute("AimOffset") or CFrame.identity

    self._att0 = self._obj.Attachment0
    self._att1 = self._obj.Attachment1

    return self
end

function RigidHinge:GetConstraint()
    return self._obj
end

function RigidHinge:PointAt(point)
    self:_pointAt(point)
end

return RigidHinge