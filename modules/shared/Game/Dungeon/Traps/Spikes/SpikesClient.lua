---
-- @classmod Spikes
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")

local BaseObject = require("BaseObject")
local SpikesConstants = require("SpikesConstants")

local OPEN_TWEEN_INFO = TweenInfo.new(1/20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Linear)

local Spikes = setmetatable({}, BaseObject)
Spikes.__index = Spikes

function Spikes.new(obj)
    local self = setmetatable(BaseObject.new(obj), Spikes)

    self._spikeVisuals = self._obj.SpikeVisuals
    self._openPart = self._obj.Open
    self._closedPart = self._obj.Closed
    self._openSound = self._obj.SpikeFloor.Open
    self._closeSound = self._obj.SpikeFloor.Close

    self._openPart.Transparency = 1
    self._closedPart.Transparency = 1

    self._cframeValue = self._maid:AddTask(Instance.new("CFrameValue"))
    self._maid:AddTask(self._cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
        self._spikeVisuals:PivotTo(self._cframeValue.Value)
    end))

    self._openTween = self._maid:AddTask(TweenService:Create(self._cframeValue, OPEN_TWEEN_INFO, {Value = self._openPart.CFrame}))
    self._closeTween = self._maid:AddTask(TweenService:Create(self._cframeValue, CLOSE_TWEEN_INFO, {Value = self._closedPart.CFrame}))

    self._remoteEvent = self._obj:WaitForChild(SpikesConstants.REMOTE_EVENT_NAME)
    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(action, ...)
        if action == "SetState" then
            self:_setState(...)
        end
    end))

    self:_setState(false)

    return self
end

function Spikes:_setState(bool)
    self._state = bool

    if bool then
        self._openTween:Play()
        self._openSound:Play()
    else
        self._closeTween:Play()
        self._closeSound:Play()
    end
end

return Spikes