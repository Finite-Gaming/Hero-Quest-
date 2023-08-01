---
-- @classmod PathfindingHelper
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")
local Queue = require("Queue")

local PathfindingHelper = {}

function PathfindingHelper:Init()
    for _, roomFolder in ipairs(workspace.Rooms:GetChildren()) do
        if not roomFolder:FindFirstChild("Sections") then
            continue
        end

        self:InitializeSectionGrid(roomFolder.Sections)
    end
end

function PathfindingHelper:InitializeSectionGrid(sectionFolder)
    self._pointsEvery = assert(sectionFolder:GetAttribute("PointsEvery"), "No PointsEvery Attribute!")
    self._originPart = assert(sectionFolder:FindFirstChild("OriginPart"), "No OriginPart!")
    self._originPoint = assert(self._originPart:FindFirstChild("Origin"), "No Origin Attachment!")
    self._sectionFolder = sectionFolder
    self._checkedPoints = {}

    self._sections = {}
    for _, section in ipairs(self._sectionFolder:GetChildren()) do
        if not section:IsA("BasePart") then
            continue
        end

        section.Transparency = 1
        if section == self._originPart then
            continue
        end

        table.insert(self._sections, section)
    end

    self._checkerHeight = 5
    self._checkerPart = DebugVisualizer:DebugPart(nil, Vector3.new(self._pointsEvery, self._checkerHeight, self._pointsEvery), 0.8)
    self._checkerPart.Parent = nil

    self._sectionParams = OverlapParams.new()
    self._sectionParams.FilterType = Enum.RaycastFilterType.Include
    self._sectionParams.FilterDescendantsInstances = self._sections

    self._worldParams = OverlapParams.new()
    self._worldParams.FilterType = Enum.RaycastFilterType.Exclude
    self._worldParams.FilterDescendantsInstances = {self._sectionFolder}

    self._raycastParams = RaycastParams.new()
    self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    self._raycastParams.FilterDescendantsInstances = {self._sectionFolder}

    self._queue = Queue.new()

    self._neighboringOffsets = {
        Vector3.new(1, 0, 0) * self._pointsEvery;
        Vector3.new(-1, 0, 0) * self._pointsEvery;
        Vector3.new(0, 0, 1) * self._pointsEvery;
        Vector3.new(0, 0, -1) * self._pointsEvery;

        -- Vector3.new(1, 0, 1) * self._pointsEvery;
        -- Vector3.new(-1, 0, -1) * self._pointsEvery;
        -- Vector3.new(-1, 0, 1) * self._pointsEvery;
        -- Vector3.new(1, 0, -1) * self._pointsEvery;
    }

    self:GenerateNeighbors(self._originPoint)
end

function PathfindingHelper:_newPoint(position)
    local point = Instance.new("Attachment")
    point.Name = "PathfindingPoint"
    point.Parent = self._originPart
    point.WorldPosition = position
    return point
end

function PathfindingHelper:_isInSection(point)
    local sectionsIn = workspace:GetPartBoundsInBox(CFrame.new(point), Vector3.new(0.1, 32, 0.1), self._sectionParams)
    if #sectionsIn == 0 then
        return false
    end

    return sectionsIn[1].Position.Y
end

function PathfindingHelper:_validPoint(pointA, pointB)
    local result = workspace:Raycast(pointA, (pointB - pointA), self._raycastParams)

    if result then
        -- DebugVisualizer:DebugPart(result.Position, Vector3.one * 0.1)
        return false
    end

    self._checkerPart.Position = pointB + (Vector3.yAxis * (self._checkerHeight/2))
    local colliding = workspace:GetPartsInPart(self._checkerPart, self._worldParams)
    if #colliding ~= 0 then
        return false
    end

    return true
end

function PathfindingHelper:_isChecked(position)
    local roundedX, roundedZ = math.round(position.X), math.round(position.Z)
    local x = self._checkedPoints[roundedX]
    if x then
        if x[roundedZ] then
            return true
        else
            x[roundedZ] = true
            return false
        end
    else
        self._checkedPoints[roundedX] = {[roundedZ] = true}
        return false
    end
end

function PathfindingHelper:GenerateNeighbors(point)
    for _, neighborOffset in ipairs(self._neighboringOffsets) do
        local wPoint = point.WorldPosition + neighborOffset
        if self:_isChecked(wPoint) then
            continue
        end

        local yLevel = self:_isInSection(wPoint)
        if yLevel then
            wPoint = Vector3.new(wPoint.X, yLevel, wPoint.Z)
        else
            continue
        end

        if not self:_validPoint(point.WorldPosition, wPoint) then
            continue
        end
        if not self:_validPoint(wPoint, point.WorldPosition) then
            continue
        end

        self._queue:Push(self:_newPoint(wPoint))
    end

    while not self._queue:IsEmpty() do
        local currentPoint = self._queue:Pop()

        self:GenerateNeighbors(currentPoint)
    end
end

return PathfindingHelper