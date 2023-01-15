---
-- @classmod NPC
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")
local BaseObject = require("BaseObject")
local Raycaster = require("Raycaster")
local Queue = require("Queue")

local NPC = setmetatable({}, BaseObject)
NPC.__index = NPC

function NPC.new(obj)
    local self = setmetatable(BaseObject.new(obj), NPC)

    self._npcZone = self._obj.Parent.Name
    self._patrolPointsFolder = workspace.PatrolPoints[self._npcZone]
    self._patrolPoints = self._patrolPointsFolder:GetChildren()

    self._humanoid = assert(self._obj:FindFirstChildOfClass("Humanoid"))
    self._humanoidRootPart = assert(self._obj:FindFirstChild("HumanoidRootPart"))

    self._oldDebugParts = {}

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(self._obj)
    self._raycaster.Visualize = true

    self._nodeSpacing = self._patrolPointsFolder:GetAttribute("Spacing")
    self._neighborOffsets = {
        Vector3.new(1, 0, 0) * self._nodeSpacing;
        Vector3.new(-1, 0, 0) * self._nodeSpacing;
        Vector3.new(0, 0, 1) * self._nodeSpacing;
        Vector3.new(0, 0, -1) * self._nodeSpacing;
    }

    self._nodeHashmap = {}
    for _, patrolPoint in ipairs(self._patrolPoints) do
        local nodePos = patrolPoint.Position

        local roundedX = math.round(nodePos.X)
        if nodePos.X ~= roundedX then
            patrolPoint.Position = Vector3.new(nodePos.X, nodePos.Y, roundedX)
        end

        local roundedZ = math.round(nodePos.Z)
        if nodePos.Z ~= roundedZ then
            patrolPoint.Position = Vector3.new(nodePos.X, nodePos.Y, roundedZ)
        end
        nodePos = patrolPoint.Position

        local row = self._nodeHashmap[nodePos.X]

        if not row then
            row = {}
            self._nodeHashmap[nodePos.X] = row
        end
        row[nodePos.Z] = patrolPoint
    end

    self._neighborMap = {}
    for _, point in ipairs(self._patrolPoints) do
        self._neighborMap[point] = self:_getNeighbors(point)
    end

    self._waypoint = self._patrolPoints[1]
    self:_startPatrol()

    return self
end

function NPC:_buildDebugPath()
    for _, oldPart in ipairs(self._oldDebugParts) do
        oldPart:Destroy()
    end
    table.clear(self._oldDebugParts)

    local lastPoint = nil
    for _, waypoint in ipairs(self._waypoints) do
        local point = waypoint.WorldPosition
        table.insert(self._oldDebugParts, DebugVisualizer:LookAtPart(lastPoint or point, point, 0.5, 0.2))
        lastPoint = point
    end
end

function NPC:_getNeighbors(node)
    local neighbors = {}
    local neighborCount = 0

    for _, offset in ipairs(self._neighborOffsets) do
        local newPos = node.Position + offset
        local row = self._nodeHashmap[newPos.X]
        if not row then
            continue
        end

        local neighbor = row[newPos.Z]
        if neighbor then
            table.insert(neighbors, neighbor)
            --DebugVisualizer:LookAtPart(node.WorldPosition, neighbor.WorldPosition, 0.95, 0.05)
            neighborCount += 1

            if neighborCount == 4 then
                break
            end
        end
    end

    return neighbors
end

function NPC:_constructPath(cameFrom, current)
    local path = {current}
    while cameFrom[current] do
        current = cameFrom[current]
        table.insert(path, 1, current)
    end
    return path
end

function NPC:_getNodeDistance(nodeA, nodeB)
    local aPos, bPos = nodeA.Position, nodeB.Position
    return math.sqrt((bPos.X - aPos.X)^2 + (bPos.Z - aPos.Z)^2)
end

function NPC:_getLowestFScore(openSet, fScore)
    local lowestNode, lowestFScore = nil, math.huge
    for node, _ in pairs(openSet) do
        if fScore[node] < lowestFScore then
            lowestNode = node
            lowestFScore = fScore[node]
        end
    end
    return lowestNode
end

function NPC:_pathfind(startPoint, goalPoint)
    local openSet = {[startPoint] = true}
    local closedSet = {}
    local gScore = {[startPoint] = 0 }
    local fScore = {[startPoint] = self:_getNodeDistance(startPoint, goalPoint)}
    local cameFrom = {}

    while next(openSet) ~= nil do
        local current = self:_getLowestFScore(openSet, fScore)
        if current == goalPoint then
            return self:_constructPath(cameFrom, current)
        end

        openSet[current] = nil
        closedSet[current] = true

        local neighbors = self:_getNeighbors(current)
        for _, neighbor in ipairs(neighbors) do
            if closedSet[neighbor] then
                continue
            end

            local tentativeGScore = gScore[current] + self:_getNodeDistance(current, neighbor)
            if not openSet[neighbor] or tentativeGScore < gScore[neighbor] then
                cameFrom[neighbor] = current
                gScore[neighbor] = tentativeGScore
                fScore[neighbor] = gScore[neighbor] + self:_getNodeDistance(neighbor, goalPoint)

                if not openSet[neighbor] then
                    openSet[neighbor] = true
                end
            end
        end
    end
end

function NPC:_startPatrol()
    local point = self:_getRandomPoint()
    if not point then
        warn("[NPC] - Failed to get pathfinding point")
        return
    end

    local oldWaypoint = self._waypoint
    self._waypoint = point
    self._waypoints = self:_pathfind(oldWaypoint, self._waypoint)
    self:_buildDebugPath()

    for _, nextPoint in ipairs(self._waypoints) do
        local humanoidPosition, pointPosition = self._humanoidRootPart.Position, nextPoint.WorldPosition
        local walkTime = math.sqrt((pointPosition.X - humanoidPosition.X)^2 + (pointPosition.Z - humanoidPosition.Z)^2)/self._humanoid.WalkSpeed

        self._humanoid:MoveTo(pointPosition)
        self._waypoint = nextPoint

        task.wait(walkTime - (1/30))
    end

    task.wait(4)
    self:_startPatrol()
end

function NPC:_getRandomPoint()
    local totalPoints = #self._patrolPoints
    if totalPoints == 0 then
        return
    elseif totalPoints == 1 then
        return self._patrolPoints[1]
    end

    local newPoint = self._patrolPoints[math.random(1, totalPoints)]
    while newPoint == self._lastPoint do
        newPoint = self._patrolPoints[math.random(1, totalPoints)]
    end
    self._lastPoint = newPoint

    return newPoint
end

return NPC