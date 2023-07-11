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
local ProgressionHelper = require("ProgressionHelper")
local ServerClassBinders = require("ServerClassBinders")
local Signal = require("Signal")
local Maid = require("Maid")
local GenericAttack = require("GenericAttack")
local StompAttack = require("StompAttack")
local ChargeAttack = require("ChargeAttack")
local VoicelineService = require("VoicelineService")
local UserData = require("UserData")
local EffectPlayerService = require("EffectPlayerService")
local CleaverTossAttack = require("CleaverTossAttack")
local PlayerDamageService = require("PlayerDamageService")
local RandomRange = require("RandomRange")
local CharacterOverlapParams = require("CharacterOverlapParams")
local CameraShakeService = require("CameraShakeService")
local QuestDataUtil = require("QuestDataUtil")
local UserDataService = require("UserDataService")
local ModelUtils = require("ModelUtils")

local DEBUG_ENABLED = false -- Setting this to true will show debug ray parts, and display the NPC's FOV

local ENEMY_SETTINGS = {
    Orc = {
        WalkSpeed = 10; -- Speed the NPC will travel while patroling
        RunSpeed = 14; -- Speed the NPC will travel when pursuing a player
        PursueAngle = 105; -- The FOV of the NPC's detection range
        PursueRange = 12; -- The max distance a player can be from the NPC to be detected
        AttackRefresh = 0.3; -- The amount of time waited after an attack
        PathingCooldown = 3; -- The amount of time waited between re-pathing when patroling

        MinDamage = 10;
        MaxDamage = 20;

        Attacks = {
            {
                Class = GenericAttack;
                Range = 5; -- The distance the npc will attack at
                WeaponName = "Mace";
                SignalAttack = true;
            };
        };
    };
    Orc_Large = {
        WalkSpeed = 8;
        RunSpeed = 16;
        PursueAngle = 160;
        PursueRange = 64;
        AttackRefresh = 0.15;
        PathingCooldown = 2;

        MinDamage = 14;
        MaxDamage = 30;

        Attacks = {
            {
                Class = GenericAttack;
                Range = 7;
                WeaponName = "Mace";
                SignalAttack = true;
            };
        };
    };
    Warden = {
        WalkSpeed = 12;
        RunSpeed = 17;
        PursueAngle = 160;
        PursueRange = 64;
        AttackRefresh = 0.3;
        PathingCooldown = 5;

        MinDamage = 18;
        MaxDamage = 42;

        IsBoss = true;

        Attacks = {
            {
                Class = GenericAttack;
                Range = 9;
                WeaponName = "Axe";
                SignalAttack = true;
            };
            {
                Class = StompAttack;
                Range = 30;
            };
            {
                Class = ChargeAttack;
                Range = 64;
                WeaponName = "Hitbox";
            };
            {
                Class = CleaverTossAttack;
                Range = 76;
                WeaponName = "Axe";
                SignalAttack = true;
            };
        };

        SpecialReward = "WardenBoss";
    };
}

local NPC = setmetatable({}, BaseObject)
NPC.__index = NPC

function NPC.new(obj)
    local self = setmetatable(BaseObject.new(obj), NPC)

    self._npcZone = self._obj.Parent.Parent.Name
    self._patrolPointsFolder = workspace.Rooms[self._npcZone].PatrolPoints
    self._patrolPoints = {}

    for _, patrolPoint in ipairs(self._patrolPointsFolder:GetChildren()) do
        if not patrolPoint:IsA("Attachment") then
            continue
        end

        table.insert(self._patrolPoints, patrolPoint)
    end

    self._humanoid = assert(self._obj:FindFirstChildOfClass("Humanoid"))
    self._humanoidRootPart = assert(self._obj:FindFirstChild("HumanoidRootPart"))

    self._totalHits = 0

    -- Setup
    self._variant = self._obj:GetAttribute("Variant") or "Orc"
    self._settings = ENEMY_SETTINGS[self._variant]

    self._humanoid.WalkSpeed = self._settings.WalkSpeed
    self._pursueAngle = math.rad(self._settings.PursueAngle)

    self.Died = self._maid:AddTask(Signal.new())
    self.KilledPlayer = self._maid:AddTask(Signal.new())
    self.StateChanged = self._maid:AddTask(Signal.new())

    self._maid:AddTask(self.StateChanged:Connect(function(state)
        self._state = state
    end))

    self._healthBar = self._humanoidRootPart:FindFirstChild("HealthBar")
    if self._healthBar then
        self._healthAccentBar = self._healthBar.CanvasGroup.AccentBar
    end

    local _, npcSize = self._obj:GetBoundingBox()
    self._npcWidth = math.floor(npcSize.X)

    self._rootAttachment = self._humanoidRootPart:FindFirstChild("RootRigAttachment")
    if not self._rootAttachment then
        self._rootAttachment = Instance.new("Attachment")
        self._rootAttachment.Name = "RootRigAttachment"
        self._rootAttachment.Parent = self._humanoidRootPart
    end

    self._alignOrientation = self._maid:AddTask(Instance.new("AlignOrientation"))

    self._alignOrientation.Enabled = false
    self._alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    self._alignOrientation.PrimaryAxis = Vector3.zAxis
    self._alignOrientation.PrimaryAxisOnly = true
    self._alignOrientation.Attachment0 = self._humanoidRootPart.RootRigAttachment
    self._alignOrientation.RigidityEnabled = true

    self._alignOrientation.Parent = self._humanoidRootPart

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore({self._patrolPointsFolder.Parent.NPC, workspace.Terrain})
    self._raycaster.Visualize = DEBUG_ENABLED

    self._attacks = {}
    self._cachedHits = {}
    for _, attackData in ipairs(self._settings.Attacks) do
        local attackClass = self._maid:AddTask(attackData.Class.new(self))
        if attackData.WeaponName then
            local weapon = self._obj[attackData.WeaponName]
            local hitscan = Hitscan.new(weapon, self._raycaster)
            self._maid:AddTask(hitscan.Hit:Connect(function(raycastResult)
                if attackClass.HandleHit then
                    attackClass:HandleHit(raycastResult)
                else
                    self:_handleHit(raycastResult)
                end
            end))
            local trail = weapon:FindFirstChild("Trail")
            self._maid:AddTask(attackClass.StartHitscan:Connect(function()
                hitscan:Start()
                if trail then
                    trail.Enabled = true
                end
            end))
            self._maid:AddTask(attackClass.EndHitscan:Connect(function()
                hitscan:Stop()
                table.clear(self._cachedHits)
                if trail then
                    trail.Enabled = false
                end
            end))
            self._maid:AddTask(attackClass.ShakeCamera:Connect(function(intensity)
                local maxDist = 16
                local weaponPos = weapon.Position
                for _, rootPart in ipairs(workspace:GetPartBoundsInRadius(
                    weaponPos,
                    maxDist,
                    CharacterOverlapParams:Get()
                )) do
                    local player = Players:GetPlayerFromCharacter(rootPart.Parent)
                    if not player then
                        print("no player LOL!")
                        continue
                    end
                    local distance = (rootPart.Position - weaponPos).Magnitude
                    local shakeStrength = intensity * (1 - ((math.clamp(distance, 0.1, maxDist)/maxDist))) * 2
                    CameraShakeService:Shake(player, shakeStrength)
                end
            end))
            if attackData.SignalAttack then
                self._maid:AddTask(attackClass.AttackPlayed:Connect(function()
                    EffectPlayerService:PlayCustom("LensFlareEffect", "new", weapon, 0.7, Color3.new(1, 0, 0), 0.4)
                end))
            end
        end

        table.insert(self._attacks, {Class = attackClass, Data = attackData})
    end
    self._attackRandomRange = RandomRange.new(1, #self._attacks)
    self:_pickRandomAttack()

    self.DamageTracker = ServerClassBinders.DamageTracker:BindAsync(self._humanoid)
    self._maid:AddTask(self.DamageTracker.Damaged:Connect(function(_, player)
        self._totalHits += 1
        if self._totalHits % 3 == 0 then
            local hitReaction = self._animations.GotHit
            if hitReaction then
                if self._playingAttack then
                    self._playingAttack:Cancel()
                end
                self._hitReacting = true
                hitReaction.TimePosition = math.random(1, 10)/10
                hitReaction:Play(0.2)
                hitReaction:AdjustSpeed(0.2)

                task.delay(0.5, function()
                    self._hitReacting = false
                    hitReaction:Stop(0.2)
                end)
            end
        end

        if not self._pursuing then
            if player then
                local character = player.Character
                if not character then
                    warn("[NPC] - No Character to pursue!")
                    return
                end

                self:_startPursuit(character)
            end
        end
    end))

    if self._healthBar then
        self:_updateHealthBar()
        self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:_updateHealthBar()
        end))
        self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
            self:_updateHealthBar()
        end))
    end

    if DEBUG_ENABLED then
        local rootCFrame = self._humanoidRootPart.CFrame
        local posA = (rootCFrame * CFrame.Angles(0, math.pi + self._pursueAngle/2, 0) * CFrame.new(0, 0, self._settings.PursueRange)).Position
        local posB = (rootCFrame * CFrame.Angles(0, math.pi + -self._pursueAngle/2, 0) * CFrame.new(0, 0, self._settings.PursueRange)).Position

        local partA = self._maid:AddTask(DebugVisualizer:LookAtPart(rootCFrame.Position, posA))
        local partB = self._maid:AddTask(DebugVisualizer:LookAtPart(rootCFrame.Position, posB))

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

        Vector3.new(1, 0, 1) * self._nodeSpacing;
        Vector3.new(-1, 0, -1) * self._nodeSpacing;
        Vector3.new(-1, 0, 1) * self._nodeSpacing;
        Vector3.new(1, 0, -1) * self._nodeSpacing;
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
    for _, animation in ipairs(self._obj.Animations:GetChildren()) do
        if not animation:IsA("Animation") then
            continue
        end

        self._animations[animation.Name] = AnimationTrack.new(animation, self._humanoid)
    end

    self._maid:AddTask(self._humanoid.Died:Connect(function()
        EffectPlayerService:PlayCustom("EnemyDeathEffect", "new", self._humanoidRootPart.Position)

        local deathData = self:_exportDeathData()
        for player, _ in pairs(self.DamageTracker:GetDamageTags()) do
            QuestDataUtil.increment(player, "NPCDeath", deathData)
        end
        self.Died:Fire()
        self._obj:Destroy()
    end))

    self._maid:AddTask(self.Died:Connect(function()
        local BASE_REWARD = 50
        for _, player in pairs(Players:GetPlayers()) do
            local playerLevel = UserDataService:GetLevel(player)
            UserData:AwardCurrency(player.UserId, "XP", BASE_REWARD * (1.015 ^ playerLevel))
            UserData:AwardCurrency(player.UserId, "Money", BASE_REWARD * (1.01 ^ playerLevel))
        end
        if self._settings.SpecialReward then
            for _, player in ipairs(Players:GetPlayers()) do
                UserData:GiveSpecialReward(player.UserId, self._settings.SpecialReward)
            end
        end
    end))

    if self._settings.IsBoss then
        if ProgressionHelper:IsBeaten() then
            for _, part in ipairs(self._obj:GetDescendants()) do
                if part:IsA("SurfaceAppearance") or part:IsA("Decal") then
                    part:Destroy()
                elseif part:IsA("BasePart") then
                    part.Color = Color3.new(1, 1, 1)
                    part.Material = Enum.Material.ForceField
                end
            end
        end
    end

    -- if self._animations.Idle then
    --     self._animations.Idle:Play()
    -- end

    for _, part in ipairs(self._obj:GetChildren()) do
        if not part:IsA("BasePart") then
            continue
        end

        part:SetNetworkOwner(nil)
    end
    self._waypoint = self:_getClosestNode()
    self:_startPatrol()

    return self
end

function NPC:_exportDeathData()
    return {
        Name = self._obj.Name;
        DamageTags = self.DamageTracker:GetDamageTags();
        DamageMap = self.DamageTracker:GetDamageMap();
    }
end

function NPC:GetTarget()
    return self._target
end

function NPC:GetState()
    return self._state or "Idle"
end

function NPC:_pickRandomAttack()
    self._nextAttack = self._attacks[self._attackRandomRange:Get()]
end

function NPC:_handleHit(raycastResult)
    local humanoid = HumanoidUtils.getHumanoid(raycastResult.Instance)
    if humanoid then
        if self._cachedHits[humanoid] then
            return
        end
        self._cachedHits[humanoid] = true

        local character = humanoid.Parent
        local damage = math.random(self._settings.MinDamage, self._settings.MaxDamage)
        PlayerDamageService:DamageCharacter(character, damage, self._obj.Name)

        local player = Players[character.Name]
        if player and humanoid.Health <= 0 then
            self.KilledPlayer:Fire(player)
        end
    end
end

function NPC:_lockHumanoid(humanoid)
    if humanoid then
        self._alignOrientation.Enabled = true
    else
        self._alignOrientation.Enabled = false
    end
end

function NPC:_updateHealthBar()
    self._healthAccentBar.Size = UDim2.fromScale(self._humanoid.Health/self._humanoid.MaxHealth, 1)
end

function NPC:_attack(character)
    local attack = self._nextAttack.Class
    self._playingAttack = attack
    self:_pickRandomAttack()
    attack:Play(character).Stopped:Wait()
    return attack.GetHitDebounce and attack:GetHitDebounce() or 0
end

function NPC:_buildDebugPath()
    local partMaid = Maid.new()
    self._maid.DebugPartMaid = nil

    local lastPoint = nil
    for _, waypoint in ipairs(self._waypoints) do
        local point = waypoint.WorldPosition
        partMaid:AddTask(DebugVisualizer:LookAtPart(lastPoint or point, point, 0.5, 0.2))
        lastPoint = point
    end
    self._maid.DebugPartMaid = partMaid
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

            if neighborCount == 8 then
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
            task.wait(self._settings.PathingCooldown)
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
            if difference.Magnitude > self._settings.PursueRange then
                continue
            end

            if math.acos(lookDirection:Dot(difference.Unit)) > self._pursueAngle/2 then
                continue
            end

            local rayResult = self._raycaster:Cast(self._humanoidRootPart.Position, (rootPos - self._humanoidRootPart.Position))
            if rayResult and rayResult.Instance:IsDescendantOf(character) then
                self:_stopPatrol()
                if self._pursuing then
                    return
                end
                self:_startPursuit(character)
                return
            end
        end
    end)
end

function NPC:_updateAlignment(rootPart)
    local posA, posB = self._humanoidRootPart.Position, rootPart.Position
    self._alignOrientation.CFrame = CFrame.lookAt(posA, posB)
end

function NPC:_getAdjacentPoint(position)
    local rootPos = self._humanoidRootPart.Position
    local nDir = (position - rootPos).Unit
    nDir = Vector3.new(nDir.X, 0, nDir.Z)

    local sortedParts = {}
    for i, point in ipairs(self._patrolPoints) do
        local pointPos = point.WorldPosition
        local dist = math.sqrt((pointPos.X - rootPos.X)^2 + (pointPos.Z - rootPos.Z)^2)
        local aNDir = (position - pointPos).Unit
        sortedParts[i] = {dist, nDir:Dot(Vector3.new(aNDir.X, 0, aNDir.Z)), point}
    end

    table.sort(sortedParts, function(a, b)
        return a[1] > b[1] and a[2] > b[2]
    end)

    local chosen = sortedParts[1][3]
    sortedParts = nil
    return chosen
end

function NPC:_startPursuit(character)
    self._target = character
    self._pursuing = true
    self._animations.Walk:Stop()
    self:StopWalkEffects()
    self._humanoid.WalkSpeed = self._settings.RunSpeed
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        self:_stopPursuit()
        return
    end

    if self._animations.Scared then
        if ProgressionHelper:IsLevelMaxed() then
            self.StateChanged:Fire("Scared")
            local rootPart = humanoid.RootPart
            if not rootPart then
                self:_stopPursuit()
                return
            end

            local walkToPoint = self:_getAdjacentPoint(rootPart.Position)
            self:_createWalkPath(self:_getClosestNode(), walkToPoint, self._animations.Run)
            self._animations.Scared:Play()
            return
        end
    end

    self.StateChanged:Fire("Chase")
    self:_updateAlignment(humanoid.RootPart)
    self._alignOrientation.Enabled = true

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
        local localRootPos = self._humanoidRootPart.Position
        local posDiff = rootPos - localRootPos
        local rayResult = self._raycaster:Cast(localRootPos, posDiff)
        if not rayResult or not rayResult.Instance:IsDescendantOf(character) then
            self:_stopPursuit()
            return
        end

        self:_updateAlignment(rootPart)

        local hDistance = math.sqrt((rootPos.X - localRootPos.X)^2 + (rootPos.Z - localRootPos.Z)^2)
        if hDistance < (self._nextAttack.Data.Range or 4) then
            if self._animations.Run.IsPlaying then
                self:StopWalkEffects()
                self._animations.Run:Stop()
            end

            self._humanoid:MoveTo(self._humanoidRootPart.Position)
            self._maid.PursuitUpdate = nil

            if not self._hitReacting then
                self._maid:AddTask(task.delay(self:_attack(character) + self._settings.AttackRefresh, function()
                    self:_startPursuit(character)
                end))
            else
                self._maid:AddTask(task.delay(0.5, function()
                    self:_startPursuit(character)
                end))
            end
            return
        end

        if not self._animations.Run.IsPlaying then
            self:StartWalkEffects()
            self._animations.Run:Play()
        end

        self._humanoid:MoveTo(rootPos)
    end)
end

function NPC:_stopPursuit()
    self.StateChanged:Fire("Idle")
    self._target = nil
    self._pursuing = false

    self._humanoid.WalkSpeed = self._settings.WalkSpeed
    self._alignOrientation.Enabled = false
    self._maid.PursuitUpdate = nil
    if self._animations.Run.IsPlaying then
        self:StopWalkEffects()
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

function NPC:_createWalkPath(from, to, animationOverride)
    self._waypoints = self:_pathfind(from, to)
    local tries = 0
    while not self._waypoints do
        if tries == 10 then
            warn("[NPC] - Failed to pathfind.")
            return
        end
        self._waypoints = self:_pathfind(from, to)

        tries += 1
    end

    if DEBUG_ENABLED then
        self:_buildDebugPath()
    end

    (animationOverride or self._animations.Walk):Play()
    self:StartWalkEffects()

    for _, nextPoint in ipairs(self._waypoints) do
        local humanoidPosition, pointPosition = self._humanoidRootPart.Position, nextPoint.WorldPosition
        local walkTime = math.sqrt((pointPosition.X - humanoidPosition.X)^2 + (pointPosition.Z - humanoidPosition.Z)^2)/self._humanoid.WalkSpeed

        self._humanoid:MoveTo(pointPosition)
        self._waypoint = nextPoint

        task.wait(walkTime - (1/5))
    end

    (animationOverride or self._animations.Walk):Stop()
end

function NPC:_randomPath()
    local point = self:_getRandomPoint()
    if not point then
        warn("[NPC] - Failed to get pathfinding point")
        return
    end

    local oldWaypoint = self._waypoint
    self._waypoint = point
    self:_createWalkPath(oldWaypoint, self._waypoint)
end

function NPC:StartWalkEffects()
    if self._footstepsPlaying then
        return
    end
    self._footstepsPlaying = true

    local FOOTSTEP_CATEGORY = ("%s_Footstep"):format(self._variant)
    self._maid.WalkUpdate = task.spawn(function()
        while true do
            task.wait(7/self._humanoid.WalkSpeed)
            VoicelineService:PlayRandomGroup(FOOTSTEP_CATEGORY, self._humanoidRootPart)
        end
    end)
end

function NPC:StopWalkEffects()
    self._footstepsPlaying = false
    self._maid.WalkUpdate = nil
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