---
-- @classmod HumanoidLocker
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local Signal = require("Signal")

local DEFAULT_UNLOCK_DISTANCE = 20

local HumanoidLocker = setmetatable({}, BaseObject)
HumanoidLocker.__index = HumanoidLocker

function HumanoidLocker.new(obj)
    local self = setmetatable(BaseObject.new(obj), HumanoidLocker)

    self._rootPart = assert(self._obj.RootPart)

    self.Unlocked = Signal.new() -- :Fire()

    if self._obj.Health <= 0 then
        self:Destroy()
        return
    end
    self._localCharacter = Players.LocalPlayer.Character
    if not self._localCharacter then
        return
    end

    self._localHumanoid = self._localCharacter:FindFirstChildOfClass("Humanoid")
    if not self._localHumanoid then
        return
    end

    self._localRootPart = self._localHumanoid.RootPart
    if not self._localRootPart then
        return
    end

    self._highlight = self._maid:AddTask(Instance.new("Highlight"))

    local RED = Color3.new(1, 0, 0)
    self._highlight.OutlineTransparency = 0.5
    self._highlight.OutlineColor = RED
    self._highlight.FillTransparency = 0.75
    self._highlight.FillColor = RED
    self._highlight.DepthMode = Enum.HighlightDepthMode.Occluded

    self._highlight.Name = "HumanoidLockHighlight"
    self._highlight.Adornee = self._rootPart.Parent

    self._highlight.Parent = Players.LocalPlayer.PlayerGui

    self._alignOrientation = self._maid:AddTask(Instance.new("AlignOrientation"))

    self._alignOrientation.Enabled = false
    self._alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    self._alignOrientation.PrimaryAxisOnly = Vector3.zAxis
    self._alignOrientation.PrimaryAxisOnly = true
    self._alignOrientation.Attachment0 = self._localRootPart.RootRigAttachment
    self._alignOrientation.MaxTorque = 9e9
    self._alignOrientation.Responsiveness = 45

    self._alignOrientation.Parent = self._localRootPart

    self._maid:AddTask(self._localHumanoid.Died:Connect(function()
        self:Destroy()
    end))
    self._maid:AddTask(self._obj.Died:Connect(function()
        self:Destroy()
    end))

    self._maid:AddTask(function()
        self.Unlocked:Fire()
    end)

    self:_update()
    self._alignOrientation.Enabled = true
    self._maid:AddTask(RunService.Heartbeat:Connect(function()
        self:_update()
    end))

    return self
end

function HumanoidLocker:_update()
    if not self:_validObj() then
        self:Destroy()
        return
    end

    local posA, posB = self._localRootPart.Position, self._rootPart.Position
    local dist = (posA - posB).Magnitude
    if dist >= DEFAULT_UNLOCK_DISTANCE then
        self:Destroy()
        return
    end

    self._alignOrientation.CFrame = CFrame.lookAt(posA, posB)
end

function HumanoidLocker:_validObj()
    return
        self._obj and
        self._obj.Health > 0
end

return HumanoidLocker