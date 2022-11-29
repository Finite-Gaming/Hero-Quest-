--- Uses spatial query to query in a capsule shape then raycasts
-- in the same shape to return proper intersection data
-- @classmod CapsuleCaster
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")

local DEBUG_ENABLED = false

local function easeCirc(x)
    return 1 - math.sqrt(1 - (x^2))
end

local CapsuleCaster = {}
CapsuleCaster.__index = CapsuleCaster

function CapsuleCaster.new(raycastParams)
    local self = setmetatable({}, CapsuleCaster)

    self._raycastParams = raycastParams or RaycastParams.new()
    self.Resolution = 3
    self.Fill = 2

    self._overlapParams = OverlapParams.new()
    self._overlapParams.CollisionGroup = self._raycastParams.CollisionGroup
    self._overlapParams.FilterDescendantsInstances = self._raycastParams.FilterDescendantsInstances
    self._overlapParams.FilterType = self._raycastParams.FilterType
    self._overlapParams.MaxParts = 1

    self._queryParts = {}
    for i = 1, 3 do
        local part = DebugVisualizer:GhostPart()
        part.Shape = i % 2 == 0 and Enum.PartType.Cylinder or Enum.PartType.Ball
        self._queryParts[i] = part
    end

    self._cylinderOffset = CFrame.Angles(0, -math.rad(90), 0)

    return self
end

function CapsuleCaster:Cast(pointA, pointB, radius)
    local baseDifference = (pointA - pointB)
    local baseDistance = baseDifference.Magnitude
    local diameter = radius*2
    local ballSize = Vector3.new(diameter, diameter, diameter)

    for i, part in pairs(self._queryParts) do
        if part.Shape == Enum.PartType.Ball then
            part.Size = ballSize
            part.Position = i == 1 and pointA or pointB
        else
            part.CFrame = CFrame.lookAt(pointA, pointB) * CFrame.new(0, 0, -baseDistance/2) * self._cylinderOffset
            part.Size = Vector3.new(baseDistance, diameter, diameter)
        end

        if #workspace:GetPartsInPart(part, self._overlapParams) == 1 then
            return self:_finalCast(pointA, pointB, radius, baseDistance)
        end
    end
end

function CapsuleCaster:_finalCast(pointA, pointB, radius, distance) -- pill shaped ray formation
    local unitDifference = (pointA - pointB).Unit
    local diameter = radius*2
    local baseOrigin = pointA + (unitDifference * radius)
    local direction = -unitDifference * (distance + diameter)

    local visualizeDistance = (baseOrigin - (baseOrigin + direction)).Magnitude

    local cframe = CFrame.lookAt(baseOrigin, baseOrigin + direction)
    local size = Vector3.new(0.05, 0.05, visualizeDistance)

    if DEBUG_ENABLED then
        DebugVisualizer:DebugPart(cframe * CFrame.new(0, 0, -visualizeDistance/2), size, 0)
    end

    local baseRaycast = workspace:Raycast(baseOrigin, direction, self._raycastParams) -- do a middle raycast first as its the most common hit
    if baseRaycast then
        return baseRaycast
    end

    local mDis = distance + diameter
    local t = radius/self.Fill
    for fill = 1, self.Fill do
        local fDiff = t * fill
        for cir = 1, self.Resolution do
            local cDiff = radius * easeCirc(fDiff/radius)
            local origin = cframe * CFrame.Angles(0, 0, math.rad(360/self.Resolution) * cir) * CFrame.new(0, fDiff, -cDiff)
            local mDir = direction.Unit * (mDis - (cDiff * 2))
            if DEBUG_ENABLED then
                DebugVisualizer:DebugPart(origin * CFrame.new(0, 0, -mDir.Magnitude/2), Vector3.new(0.05, 0.05, mDir.Magnitude), 0)
            end

            local raycastResult = workspace:Raycast(origin.Position, mDir, self._raycastParams)
            if raycastResult then
                return raycastResult
            end
        end
    end
end

return CapsuleCaster