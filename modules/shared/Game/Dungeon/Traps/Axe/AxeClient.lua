---
-- @classmod AxeClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local BaseObject = require("BaseObject")
local AxeConstants = require("AxeConstants")
-- local Raycaster = require("Raycaster")
-- local Hitscan = require("Hitscan")
local HumanoidUtils = require("HumanoidUtils")

-- local DEBUG_ENABLED = true
-- This class has been refactored to use touch events as the axe swing is simulated on the client making this hitreg method viable

local AxeClient = setmetatable({}, BaseObject)
AxeClient.__index = AxeClient

function AxeClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), AxeClient)

    -- self._raycaster = Raycaster.new()
    -- self._raycaster:Ignore(self._obj)
    -- self._raycaster.Visualize = DEBUG_ENABLED
    -- self._hitscan = Hitscan.new(self._obj, self._raycaster)

    self._hitCache = {}

    self._remoteEvent = self._obj:WaitForChild(AxeConstants.REMOTE_EVENT_NAME)
    self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function()
        table.clear(self._hitCache)
    end))

    -- self._maid:AddTask(self._hitscan.Hit:Connect(function(raycastResult)
    --     self:_handleHit(raycastResult.Instance)
    -- end))
    self._maid:AddTask(self._obj.Touched:Connect(function(part)
        self:_handleHit(part)
    end))

    -- self._hitscan:Start()

    return self
end

function AxeClient:_handleHit(part)
    local humanoid = HumanoidUtils.getHumanoid(part)
    if humanoid then
        if self._hitCache[humanoid] then
            return
        end
        if humanoid.Parent.Name ~= Players.LocalPlayer.Name then
            return
        end

        self._hitCache[humanoid] = true
        self._remoteEvent:FireServer()
    end
end

return AxeClient