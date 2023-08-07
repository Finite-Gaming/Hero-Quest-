--- Does cool things
-- @classmod HumanoidHealing
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local HumanoidUtils = require("HumanoidUtils")
local ServerTemplateProvider = require("ServerTemplateProvider")

local HumanoidHealing = {}
HumanoidHealing.__index = HumanoidHealing

function HumanoidHealing.new(healing)
    local self = setmetatable({}, HumanoidHealing)

    self._healing = healing

    return self
end

function HumanoidHealing:Apply(raycastResult)
    local humanoid = HumanoidUtils.getHumanoid(raycastResult.Instance)
    if humanoid then
        local health = humanoid.Health
        if health <= 0 then
            return
        end

        local newHealth = math.clamp(health + self._healing, 0, humanoid.MaxHealth)
        humanoid.Health = newHealth

        local effect = ServerTemplateProvider:Get("HealEffect")
        local healEffects = effect.HealEffects
        healEffects.Parent = humanoid.RootPart
        effect:Destroy()

        task.delay(0.5, function()
            for _, particleEmitter in ipairs(healEffects:GetChildren()) do
                if not particleEmitter:IsA("ParticleEmitter") then
                    continue
                end

                particleEmitter.Enabled = false
            end

            task.delay(0.9, function()
                healEffects:Destroy()
            end)
        end)
    end
end

return HumanoidHealing