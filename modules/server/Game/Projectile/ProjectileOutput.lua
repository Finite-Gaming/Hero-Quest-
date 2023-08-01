--- Provides an output for projectiles given a projectile type
-- @classmod ProjectileOutput
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ProjectileOutputBase = require("ProjectileOutputBase")
local ProjectileOutputConstants = require("ProjectileOutputConstants")

local ProjectileOutput = setmetatable({}, ProjectileOutputBase)
ProjectileOutput.__index = ProjectileOutput

function ProjectileOutput.new(obj)
    local self = setmetatable(ProjectileOutputBase.new(obj), ProjectileOutput)

    self._remoteEvent = self._maid:AddTask(Instance.new("RemoteEvent"))
    self._remoteEvent.Name = ProjectileOutputConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player, startTick, position, direction)
        -- self._remoteEvent:FireAllClients(player, startTick, position, direction)
        -- self:Fire(startTick, position, direction)
    end))

    return self
end

function ProjectileOutput:FireGlobal(direction)
    local startTick = workspace:GetServerTimeNow()
    self._remoteEvent:FireAllClients(nil, startTick, nil, direction)
    self:Fire(startTick, nil, direction)
end

return ProjectileOutput