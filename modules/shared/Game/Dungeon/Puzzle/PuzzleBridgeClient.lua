---
-- @classmod PuzzleBridgeClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")

local BaseObject = require("BaseObject")
local PuzzleBridgeConstants = require("PuzzleBridgeConstants")
local Maid = require("Maid")

local PuzzleBridgeClient = setmetatable({}, BaseObject)
PuzzleBridgeClient.__index = PuzzleBridgeClient

function PuzzleBridgeClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), PuzzleBridgeClient)

    self._remoteEvent = self._obj:WaitForChild(PuzzleBridgeConstants.REMOTE_EVENT_NAME)
    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(deg)
        self:_spin(deg)
    end))

    return self
end

function PuzzleBridgeClient:_spin(deg)
    local spinMaid = Maid.new()
    local floorSection = self._obj:WaitForChild("FloorSection")
    local startCFrame = floorSection.PrimaryPart.CFrame

    local cframeValue = spinMaid:AddTask(Instance.new("CFrameValue"))
    cframeValue.Value = startCFrame

    spinMaid:AddTask(cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
        floorSection:PivotTo(cframeValue.Value)
    end))

    local moveTween = spinMaid:AddTask(TweenService:Create(
        cframeValue,
        TweenInfo.new(PuzzleBridgeConstants.SPIN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Value = startCFrame * CFrame.Angles(0, deg, 0)}
    ))
    spinMaid:AddTask(moveTween.Completed:Connect(function()
        spinMaid:Destroy()
    end))

    self._obj.Handle.Sound:Play()
    moveTween:Play()
end

return PuzzleBridgeClient