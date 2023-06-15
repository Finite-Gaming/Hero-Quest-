---
-- @classmod CleaverTossHandler
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local CleaverTossConstants = require("CleaverTossConstants")
local Raycaster = require("Raycaster")
local Hitscan = require("Hitscan")
local ParametricCurve = require("ParametricCurve")
local Maid = require("Maid")
local HumanoidUtils = require("HumanoidUtils")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CleaverTossHandler = {}

function CleaverTossHandler:Init()
    self._raycaster = Raycaster.new()
    self._raycaster:Ignore({workspace.Rooms, workspace.Terrain})

    self._remoteEvent = Network:GetRemoteEvent(CleaverTossConstants.REMOTE_EVENT_NAME)
    self._remoteEvent.OnClientEvent:Connect(function(...)
        self:_handleRequest(...)
    end)
end

function CleaverTossHandler:_handleRequest(npc, throwTime, curvePoints, serverTime)
    local localTime = workspace:GetServerTimeNow()
    local latency = localTime - serverTime

    local weapon = npc.Axe
    local startPos = weapon.Position

    local postHit = false

    local maid = Maid.new()
    local hitscan = Hitscan.new(weapon, self._raycaster)
    maid:AddTask(hitscan.Hit:Connect(function(raycastResult)
        if postHit then
            return
        end
        local humanoid = HumanoidUtils.getHumanoid(raycastResult.Instance)
        if not humanoid then
            return
        end

        if humanoid.Parent ~= Players.LocalPlayer.Character then
            return
        end
        postHit = true

        self._remoteEvent:FireServer()
    end))

    local plottedPoints = table.create(#curvePoints + 2)
    plottedPoints[1] = startPos
    for _, point in ipairs(curvePoints) do
        table.insert(plottedPoints, point)
    end
    table.insert(plottedPoints, startPos)

    local curve = ParametricCurve.new(plottedPoints, 100)

    local function update()
        local updateTime = workspace:GetServerTimeNow()
        local timeDiff = updateTime - serverTime
        local delta = math.clamp(timeDiff, 0, throwTime)/throwTime

        local curvePoint = curve:GetPoint(delta)
        weapon.CFrame = CFrame.lookAt(curvePoint, curve:GetPoint(math.clamp(delta + 0.1, 0, 1)))
            * CFrame.fromOrientation(0, -math.pi/2 + ((math.pi*4) * delta), -math.pi/2)

        if delta == 1 then
            maid:Destroy()
            return
        end
    end

    maid:AddTask(function()
        hitscan:Stop()
        weapon.Trail.Enabled = false
    end)
    maid:AddTask(weapon:GetPropertyChangedSignal("Anchored"):Connect(function()
        maid:Destroy() -- contingency
    end))
    maid:AddTask(RunService.Heartbeat:Connect(update))
    weapon.Trail.Enabled = true
    hitscan:Start()
end

return CleaverTossHandler