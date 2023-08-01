---
-- @classmod HitscanPartClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local HitscanPartConstants = require("HitscanPartConstants")
local ClientOverlapParams = require("ClientOverlapParams")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HitscanPartClient = setmetatable({}, BaseObject)
HitscanPartClient.__index = HitscanPartClient

function HitscanPartClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), HitscanPartClient)

    self._remoteEvent = self._obj:WaitForChild(HitscanPartConstants.REMOTE_EVENT_NAME)

    self._targetTransparency = self._obj:GetAttribute("TargetTransparency")
    self._lifetime = self._obj:GetAttribute("Lifetime")
    self._hitWindow = self._obj:GetAttribute("HitWindow")

    self._overlapParams = ClientOverlapParams:Get()
    self._startTime = workspace:GetServerTimeNow()

    if self._lifetime < self._startTime then
        self:Destroy()
        return
    end

    self._timeDiff = self._lifetime - self._startTime
    self._totalWindow = self._timeDiff * self._hitWindow
    self._startScan = self._startTime + ((self._timeDiff/2) - (self._totalWindow/2))
    self._endScan = self._startTime + ((self._timeDiff/2) + (self._totalWindow/2))

    self._maid.Update = RunService.Heartbeat:Connect(function()
        self:_update()
    end)

    self._maid:AddTask(TweenService:Create(self._obj,
        TweenInfo.new(self._timeDiff/2, Enum.EasingStyle.Circular, Enum.EasingDirection.In, 0, true),
        {Transparency = self._targetTransparency}
    )):Play()

    return self
end

function HitscanPartClient:_update()
    local frameTime = workspace:GetServerTimeNow()
    if frameTime < self._startScan then
        return
    end

    if frameTime > self._endScan then
        self._maid.Update = nil
        return
    end

    if #workspace:GetPartsInPart(self._obj, self._overlapParams) ~= 0 then
        self._remoteEvent:FireServer()
        self._maid.Update = nil
        return
    end
end

return HitscanPartClient