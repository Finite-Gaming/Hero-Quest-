---
-- @classmod AttackTelegrapherClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local AttackTelegrapherConstants = require("AttackTelegrapherConstants")
local DebugVisualizer = require("DebugVisualizer")
local Maid = require("Maid")
local ParametricCurve = require("ParametricCurve")

local TweenService = game:GetService("TweenService")

local AttackTelegrapherClient = {}

function AttackTelegrapherClient:Init()
    Network:GetRemoteEvent(AttackTelegrapherConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(action, properties, lifetime)
        if action  == "TelegraphAttack" then
            self:TelegrapherPart(properties, lifetime)
        elseif action == "BulkTelegraphAttack" then
            for _, telegraphInfo in ipairs(properties) do
                self:TelegrapherPart(telegraphInfo[1], telegraphInfo[2])
            end
        elseif action == "TelegraphCurve" then
            self:TelegraphCurve(properties, lifetime)
        end
    end)
end

function AttackTelegrapherClient:TelegraphCurve(curvePoints, lifetime)
    local resolution = 50
    local curve = ParametricCurve.new(curvePoints, resolution)

    local lastPoint = curvePoints[1]
    for i = 1, resolution do
        local percent = i/resolution
        local point = curve:GetPoint(percent)
        local distance = (lastPoint - point).Magnitude

        self:TelegrapherPart({
            BrickColor = BrickColor.new("Persimmon");
            CFrame = CFrame.lookAt(lastPoint, point)  * CFrame.Angles(0, -math.pi/2, 0) * CFrame.new(-distance/2, 0, 0);
            Size = Vector3.new(distance, 0.2, 1);
        }, lifetime)

        lastPoint = point
    end
end

function AttackTelegrapherClient:TelegrapherPart(properties, lifetime)
    local maid = Maid.new()
    local part = maid:AddTask(DebugVisualizer:DebugPart(properties.CFrame, properties.Size, 1, properties.Shape))
    for property, value in pairs(properties) do
        if property == "Transparency" then
            continue
        end

        part[property] = value
    end

    local tween = maid:AddTask(TweenService:Create(part,
        TweenInfo.new(lifetime or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true),
        {Transparency = properties.Transparency or 0}
    ))
    maid:AddTask(tween.Completed:Connect(function()
        maid:Destroy()
    end))

    tween:Play()
end

return AttackTelegrapherClient