--- Handles effect playing on the client
-- @classmod EffectPlayerClient
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectPlayerConstants = require("EffectPlayerConstants")
local Network = require("Network")
local TemplateProvider = require("TemplateProvider")

local DEFAULT_EMIT_COUNT = NumberRange.new(1, 3)
local EFFECT_TYPES = {
    ["PointLight"] = true;
    ["Beam"] = true;
    ["Trail"] = true;
}

local EffectPlayerClient = {}

function EffectPlayerClient:Init()
    self._provider = TemplateProvider.new(ReplicatedStorage[EffectPlayerConstants.EFFECT_DIRECTORY_NAME])
    self._provider:Init()

    Network:GetRemoteEvent(EffectPlayerConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(action, ...)
        self[action](self, ...)
    end)
end

function EffectPlayerClient:PlayEffect(effectName, position, color)
    local effect = self._provider:Get(effectName)
    local maxLifetime = 0
    local maxDelay = 0

    effect.Anchored = true
    effect.Position = position
    effect.Parent = workspace.Terrain

    if color and typeof(color) == "Color3" then
        color = ColorSequence.new(color)
    end

    for _, particle in ipairs(effect:GetDescendants()) do
        if particle:IsA("ParticleEmitter") then
            local max = particle.Lifetime.Max
            if max > maxLifetime then
                maxLifetime = max
            end

            local emitDelay = particle:GetAttribute("EmitDelay")
            local emitCount = particle:GetAttribute("EmitCount") or DEFAULT_EMIT_COUNT
            local emitted = nil
            if typeof(emitCount) == "number" then
                emitted = emitCount
            elseif typeof(emitCount) == "NumberRange" then
                emitted = math.random(emitCount.Min, emitCount.Max)
            end

            if emitDelay and emitDelay ~= 0 then
                if emitDelay > maxDelay then
                    maxDelay = emitDelay
                end

                task.delay(emitDelay, particle.Emit, particle, emitted)
            else
                particle:Emit(emitted)
            end
        elseif EFFECT_TYPES[particle.ClassName] then
            particle.Enabled = true
        else
            continue
        end

        if color then
            particle.Color = color
        end
    end

    if not effect:GetAttribute("EffectPersist") then
        local addedDelay = effect:GetAttribute("Lifetime") or 1
        task.delay(maxLifetime + maxDelay + addedDelay, function()
            effect:Destroy()
        end)
    end

    return effect
end

function EffectPlayerClient:PlayCustom(effectName, param, ...)
    require(effectName)[param or "new"](...)
end

return EffectPlayerClient