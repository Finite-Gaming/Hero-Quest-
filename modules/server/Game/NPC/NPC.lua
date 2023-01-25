---
-- @classmod NPC
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DebugVisualizer = require("DebugVisualizer")
local BaseObject = require("BaseObject")
local Raycaster = require("Raycaster")
local AnimationTrack = require("AnimationTrack")
local WeldUtils = require("WeldUtils")
local Hitscan = require("Hitscan")
local HumanoidUtils = require("HumanoidUtils")
local DamageFeedback = require("DamageFeedback")
local ServerClassBinders = require("ServerClassBinders")

local DEBUG_ENABLED = false -- Setting this to true will show debug ray parts, and display the NPC's FOV

local ENEMY_SETTINGS = {
    WalkSpeed = 10; -- Speed the NPC will travel while patroling
    RunSpeed = 14; -- Speed the NPC will travel when pursuing a player
    PursueAngle = 105; -- The FOV of the NPC's detection range
    PursueRange = 12; -- The max distance a player can be from the NPC to be detected
    AttackRefresh = 0.3; -- The amount of time waited after an attack
    PathingCooldown = 3; -- The amount of time waited between re-pathing when patroling

    MinDamage = 10;
    MaxDamage = 20;
}

local NPC = setmetatable({}, BaseObject)
NPC.__index = NPC

function NPC.new(obj)
    local self = setmetatable(BaseObject.new(obj), NPC)

    self._npcZone = self._obj.Parent.Name
    self._patrolPointsFolder = workspace.PatrolPoints[self._npcZone]
    self._patrolPoints = self._patrolPointsFolder:GetChildren()

    self._humanoid = assert(self._obj:FindFirstChildOfClass("Humanoid"))
    self._humanoidRootPart = assert(self._obj:FindFirstChild("HumanoidRootPart"))

    -- Setup
    self._humanoid.WalkSpeed = ENEMY_SETTINGS.WalkSpeed
    self._pursueAngle = math.rad(ENEMY_SETTINGS.PursueAngle)

    self._healthBar = self._humanoidRootPart.HealthBar
    self._healthAccentBar = self._healthBar.CanvasGroup.AccentBar

    self._oldDebugParts = {}

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(workspace.NPC)
    self._raycaster.Visualize = DEBUG_ENABLED

    self._hitscan = Hitscan.new(self._obj.BasicMace, self._raycaster)
    self._cachedHits = {}
    self._maid:AddTask(self._hitscan.Hit:Connect(function(raycastResult)
        local humanoid = HumanoidUtils.getHumanoid(raycastResult.Instance)
        if humanoid then
            if self._cachedHits[humanoid] then
                return
            end
            self._cachedHits[humanoid] = true

            local damage = math.random(ENEMY_SETTINGS.MinDamage, ENEMY_SETTINGS.MaxDamage)
            if not humanoid:GetAttribute("Invincible") then
                humanoid:TakeDamage(damage)
            end

            DamageFeedback:SendFeedback(humanoid, damage, raycastResult.Position)
        end
    end))

    self._damageTracker = ServerClassBinders.DamageTracker:BindAsync(self._humanoid)
    self._maid:AddTask(self._damageTracker.Damaged:Connect(function(_, player)
        if player then
            local character = player.Character
            if not character then
                warn("[NPC] - No Character to pursue!")
                return
            end

            self:_startPursuit(character)
        end
    end))

    self:_updateHealthBar()
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        self:_updateHealthBar()
    end))
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        self:_updateHealthBar()
    end))

    if DEBUG_ENABLED then
        local rootCFrame = self._humanoidRootPart.CFrame
        local posA = (rootCFrame * CFrame.Angles(0, math.pi + self._pursueAngle/2, 0) * CFrame.new(0, 0, ENEMY_SETTINGS.PursueRange)).Position
        local posB = (rootCFrame * CFrame.Angles(0, math.pi + -self._pursueAngle/2, 0) * CFrame.new(0, 0, ENEMY_SETTINGS.PursueRange)).Position

        local partA = DebugVisualizer:LookAtPart(rootCFrame.Position, posA)
        local partB = DebugVisualizer:LookAtPart(rootCFrame.Position, posB)

        local relativeA, relativeB = rootCFrame:ToObjectSpace(partA.CFrame), rootCFrame:ToObjectSpace(partB.CFrame)

        partA.Anchored = false
        partB.Anchored = false

        WeldUtils.weld(self._humanoidRootPart, partA, relativeA)
        WeldUtils.weld(self._humanoidRootPart, partB, relativeB)
    end

    -- Pathfinding
    self._nodeSpacing = self._patrolPointsFolder:GetAttribute("Spacing")
    self._maxNodeSpace = math.sqrt(self._nodeSpacing ^ 2 * 2)

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

    -- Animation
    self._animations = {}
    self._attackAnimations = {}
    for _, animation in ipairs(self._obj.Animations:GetChildren()) do
        if animation:IsA("Folder") and animation.Name == "Attacks" then
            for _, attackAnimation in ipairs(animation:GetChildren()) do
                table.insert(self._attackAnimations, AnimationTrack.new(attackAnimation, self._humanoid))
            end

            continue
        end

        self._animations[animation.Name] = AnimationTrack.new(animation, self._humanoid)
    end

    self._maid:AddTask(self._humanoid.Died:Connect(function()
        task.wait(1)
        self._obj:Destroy()
    end))

    self._waypoint = self._patrolPoints[1]
    self:_startPatrol()

    return self
end

function NPC:_updateHealthBar()
    self._healthAccentBar.Size = UDim2.fromScale(self._humanoid.Health/self._humanoid.MaxHealth, 1)
end

function NPC:_attack()
    local attackAnim = self._attackAnimations[math.random(1, #self._attackAnimations)]
    attackAnim:Play()
    self._hitscan:Start()
    attackAnim.Stopped:Wait()
    self._hitscan:Stop()
    table.clear(self._cachedHits)
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

function NPC:_canSeeNode(pos, node)
    local nodePos = node.WorldPosition
    local origin = Vector3.new(pos.X, nodePos.Y, pos.Z)
    local rayResult = self._raycaster:Cast(origin, (nodePos - origin).Unit * self._maxNodeSpace)

    return rayResult == nil
end

function NPC:_startPatrol()
    self._maid.PatrolThread = task.spawn(function()
        while true do
            self:_randomPath()
            task.wait(ENEMY_SETTINGS.PathingCooldown)
        end
    end)

    self._maid.PatrolUpdate = RunService.Heartbeat:Connect(function()
        local lookDirection = self._humanoidRootPart.CFrame.LookVector

        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if not character then
                continue
            end

            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then
                continue
            end

            local rootPart = humanoid.RootPart
            if not rootPart then
                continue
            end
            if humanoid.Health <= 0 then
                continue
            end

            local rootPos = rootPart.Position
            local difference = rootPos - self._humanoidRootPart.Position
            if difference.Magnitude > ENEMY_SETTINGS.PursueRange then
                continue
            end

            if math.acos(lookDirection:Dot(difference.Unit)) > self._pursueAngle/2 then
                continue
            end

            local rayResult = self._raycaster:Cast(self._humanoidRootPart.Position, (rootPos - self._humanoidRootPart.Position))
            if rayResult and rayResult.Instance:IsDescendantOf(character) then
                self:_stopPatrol()
                self:_startPursuit(character)
                return
            end
        end
    end)
end

function NPC:_startPursuit(character)
    self._animations.Walk:Stop()
    self._humanoid.WalkSpeed = ENEMY_SETTINGS.RunSpeed

    self._maid.PursuitUpdate = RunService.Heartbeat:Connect(function()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then
            self:_stopPursuit()
            return
        end

        local rootPart = humanoid.RootPart
        if not rootPart then
            self:_stopPursuit()
            return
        end
        if humanoid.Health <= 0 then
            self:_stopPursuit()
            return
        end

        local rootPos = rootPart.Position
        local posDiff = (rootPos - self._humanoidRootPart.Position)
        local rayResult = self._raycaster:Cast(self._humanoidRootPart.Position, posDiff)
        if not rayResult or not rayResult.Instance:IsDescendantOf(character) then
            self:_stopPursuit()
            return
        end

        if posDiff.Magnitude < 3 then
            if self._animations.Run.IsPlaying then
                self._animations.Run:Stop()
            end

            self._humanoid:MoveTo(self._humanoidRootPart.Position)
            self._maid.PursuitUpdate = nil
            self:_attack()

            task.wait(ENEMY_SETTINGS.AttackRefresh)
            self:_startPursuit(character)
            return
        end

        if not self._animations.Run.IsPlaying then
            self._animations.Run:Play()
        end

        self._humanoid:MoveTo(rootPos)
    end)
end

function NPC:_stopPursuit()
    self._humanoid.WalkSpeed = ENEMY_SETTINGS.WalkSpeed
    self._maid.PursuitUpdate = nil
    if self._animations.Run.IsPlaying then
        self._animations.Run:Stop()
    end

    self._waypoint = self:_getClosestNode()
    self:_startPatrol()
end

function NPC:_getClosestNode()
    local rootPos = self._humanoidRootPart.Position
    local fallback, closest, closestDist = nil, nil, math.huge
    for _, node in pairs(self._patrolPoints) do
        local dist = (node.WorldPosition - rootPos).Magnitude
        if dist < closestDist then
            fallback = node

            if self:_canSeeNode(rootPos, node) then
                closestDist = dist
                closest = node
            end
        end
    end

    return closest or fallback
end

function NPC:_stopPatrol()
    self._maid.PatrolThread = nil
    self._maid.PatrolUpdate = nil
end

function NPC:_randomPath()
    local point = self:_getRandomPoint()
    if not point then
        warn("[NPC] - Failed to get pathfinding point")
        return
    end

    local oldWaypoint = self._waypoint
    self._waypoint = point
    self._waypoints = self:_pathfind(oldWaypoint, self._waypoint)

    if DEBUG_ENABLED then
        self:_buildDebugPath()
    end

    self._animations.Walk:Play()

    for _, nextPoint in ipairs(self._waypoints) do
        local humanoidPosition, pointPosition = self._humanoidRootPart.Position, nextPoint.WorldPosition
        local walkTime = math.sqrt((pointPosition.X - humanoidPosition.X)^2 + (pointPosition.Z - humanoidPosition.Z)^2)/self._humanoid.WalkSpeed

        self._humanoid:MoveTo(pointPosition)
        self._waypoint = nextPoint

        task.wait(walkTime - (1/5))
    end

    self._animations.Walk:Stop()
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