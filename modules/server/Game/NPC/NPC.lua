---
-- @classmod NPC
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local PathfindingService = game:GetService("PathfindingService")

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
        Vector2.new(1, 0) * self._nodeSpacing;
        Vector2.new(-1, 0) * self._nodeSpacing;
        Vector2.new(0, 1) * self._nodeSpacing;
        Vector2.new(0, -1) * self._nodeSpacing;
    }

    self._nodeHashmap = {}
    for _, patrolPoint in ipairs(self._patrolPoints) do
        self._nodeHashmap[self:_encodePos(patrolPoint.WorldPosition)] = patrolPoint
    end

    self._waypoint = self._patrolPoints[1]
    self._waypoints = self:_pathfind(self._waypoint, self._patrolPoints[40])
    self:_buildDebugPath()

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

function NPC:_encodePos(position)
    return Vector2.new(position.X, position.Z)
end

function NPC:_decodePos(position)
    return Vector3.new(position.X, self._humanoidRootPart.Position.Y, position.Y)
end

function NPC:_getNeighbors(node)
    local neighbors = {}
    local nodePos = self:_encodePos(node.WorldPosition)
    for pointPos, point in pairs(self._nodeHashmap) do
        if node == point then
            continue
        end

        local dist = (pointPos - nodePos).Magnitude - 0.05
        if dist > 0 and dist < self._nodeSpacing then
            table.insert(neighbors, point)
        end

        if #neighbors == 4 then
            break
        end
    end

    return neighbors
end

function NPC:_reconstructPath(previous, startPoint, goalPoint)
    local path = {goalPoint}
    local current = goalPoint

    while current ~= startPoint do
        current = previous[current]
        table.insert(path, 1, current)
    end

    return path
end

function NPC:_pathfind(startPoint, goalPoint)
    local queue = Queue.new()
    queue:Push(startPoint)

    DebugVisualizer:LookAtPart(startPoint.WorldPosition, goalPoint.WorldPosition, 0.8)

    local visited = {}
    local previous = {}

    while not queue:IsEmpty() do
        local current = queue:Pop()
        visited[current] = true

        if current == goalPoint then
            return self:_reconstructPath(previous, startPoint, goalPoint)
        end

        local neighbors = self:_getNeighbors(current)
        print(neighbors)
        for _, neighbor in pairs(neighbors) do
            if not visited[neighbor] then
                queue:Push(neighbor)
                previous[neighbor] = current
            end
        end
    end

    return nil
end

function NPC:_moveToPoint(point)
    
end

function NPC:_moveRandom()
    local point = self:_getRandomPoint()
    if not point then
        warn("[NPC] - Failed to get pathfinding point")
        return
    end

    self:_moveToPoint(point.Position)
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

    return newPoint.Position
end

return NPC