--- Handles effect playing on the client
-- @classmod EffectPlayerClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectPlayerConstants = require("EffectPlayerConstants")
local Network = require("Network")
local TemplateProvider = require("TemplateProvider")

local EffectPlayerClient = {}

function EffectPlayerClient:Init()
    self._provider = TemplateProvider.new(ReplicatedStorage[EffectPlayerConstants.EFFECT_DIRECTORY_NAME])
    self._provider:Init()

    Network:GetRemoteEvent(EffectPlayerConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(action, ...)
        self[action](self, ...)
    end)
end

function EffectPlayerClient:PlayEffect(effectName, position)
    local effect = self._provider:Get(effectName)
    local maxLifetime = -math.huge
    effect.Position = position
    effect.Parent = workspace.Terrain

    for _, particle in ipairs(effect:GetDescendants()) do
        if not particle:IsA("ParticleEmitter") then
            continue
        end

        local max = particle.Lifetime.Max
        if max > maxLifetime then
            maxLifetime = max
        end

        particle:Emit(math.random(1, 3))
    end

    task.delay(maxLifetime, function()
        effect:Destroy()
    end)
end

function EffectPlayerClient:PlayCustom(effectName, param, ...)
    require(effectName)[param or "new"](...)
end

return EffectPlayerClient