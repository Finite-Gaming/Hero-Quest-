--- Provides an output for projectiles given a projectile type
-- @classmod ProjectileOutputClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local ProjectileOutputBase = require("ProjectileOutputBase")
local ProjectileOutputConstants = require("ProjectileOutputConstants")

local ProjectileOutputClient = setmetatable({}, ProjectileOutputBase)
ProjectileOutputClient.__index = ProjectileOutputClient

function ProjectileOutputClient.new(obj)
    local self = setmetatable(ProjectileOutputBase.new(obj), ProjectileOutputClient)

    self._remoteEvent = self._obj:WaitForChild(ProjectileOutputConstants.REMOTE_EVENT_NAME)
    if self._remoteEvent then
        self._maid:AddTask(self._remoteEvent.OnClientEvent:Connect(function(player, startTick, firePos, direction)
            if player == Players.LocalPlayer then
                return
            end

            self:FireLocal(startTick, firePos, direction)
        end))
    end

    return self
end

function ProjectileOutputClient:FireGlobal(startTick, firePos, direction)
    startTick = startTick or workspace:GetServerTimeNow()
    firePos = firePos or self._obj.WorldPosition
    direction = direction or -self._obj.WorldCFrame.RightVector

    self._remoteEvent:FireServer(startTick, firePos, direction)
    self:FireLocal(startTick, firePos, direction)
end

return ProjectileOutputClient