---
-- @classmod PlayerDamageService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DamageFeedback = require("DamageFeedback")
local ApplyImpulse = require("ApplyImpulse")
local ServerClassBinders = require("ServerClassBinders")
local UserDataService = require("UserDataService")
local EffectPlayerService = require("EffectPlayerService")
local SoundPlayerService = require("SoundPlayerService")

local Players = game:GetService("Players")

local PlayerDamageService = {
    _cooldownMap = {};
}

function PlayerDamageService:DamagePlayer(player, ...)
    return self:DamageCharacter(player.Character, ...)
end

function PlayerDamageService:DamageHumanoid(humanoid, ...)
    return self:DamageCharacter(humanoid.Parent, ...)
end

function PlayerDamageService:DamageCharacter(character, damage, damageTag, cooldown, attacker, launchForce, launchRadius)
    if not character then
        warn("[PlayerDamageService] - No character")
        return
    end

    if not damage then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[PlayerDamageService] - No Humanoid")
        return
    end

    local lastHit = self._cooldownMap[character] or 0
    local hitTime = os.clock()
    if hitTime - lastHit < (cooldown or 0) then
        return
    end
    self._cooldownMap[character] = hitTime

    local blockRate = humanoid:GetAttribute("BlockRate")
    local blocked = blockRate and math.random(1, blockRate) == 1

    if not blocked then
        local player = Players:FindFirstChild(character.Name)
        if attacker and launchForce and launchRadius then
            local rootPart = humanoid.RootPart
            if not rootPart then
                warn("[PlayerDamageService] - No RootPart")
                return
            end

            local argCType = typeof(attacker)
            assert(argCType == "Vector3" or argCType == "Instance", "Incorrect attacker type")

            local attackerPosition = nil
            if typeof(attacker) == "Vector3" then
                attackerPosition = attacker
            elseif attacker:IsA("BasePart") then
                attackerPosition = attacker.Position
            elseif attacker:IsA("Humanoid") then
                local attackerRootPart = attacker.RootPart
                if not attackerRootPart then
                    warn("[PlayerDamageService] - No attacker RootPart")
                    return
                end
                attackerPosition = attackerRootPart.Position
            elseif attacker:IsA("Player") then
                local attackerCharacter = attacker.Character
                if not attackerCharacter then
                    warn("[PlayerDamageService] - No attacker Character")
                    return
                end

                local attackerRootPart = attackerCharacter:FindFirstChild("HumanoidRootPart") or attackerCharacter.PrimaryPart
                if not attackerRootPart then
                    warn("[PlayerDamageService] - No attacker RootPart")
                    return
                end

                attackerPosition = attackerRootPart.Position
            end

            local difference = rootPart.Position - attackerPosition
            local blastPressure = 1 - (math.clamp(difference.Magnitude, 0, launchRadius)/launchRadius)
            local force = difference.Unit * (launchForce * blastPressure) * rootPart.AssemblyMass

            if player then
                humanoid.Sit = true
                ApplyImpulse:ApplyImpulse(player, rootPart, force)
            else
                rootPart:ApplyImpulse(force)
            end

            damage *= blastPressure
        end
    else
        damage *= 0.3
        -- TODO: block sound
        EffectPlayerService:PlayEffect("SwordBlock", humanoid.RootPart.Position)
        SoundPlayerService:PlaySoundAtPart("SwordBlock", humanoid.RootPart)
    end

    local damageTracker = ServerClassBinders.DamageTracker:Get(humanoid)
    if not damageTracker then
        if not humanoid:GetAttribute("Invincible") then
            humanoid:TakeDamage(damage)
        end
    else
        damageTracker:Damage(damage, attacker, damageTag, blocked)
    end

    DamageFeedback:SendFeedback(humanoid, damage)

    return damage
end

function PlayerDamageService:DamageHitPart(part, ...)
    local character = part
    while character and not character:FindFirstChildOfClass("Humanoid") do
        character = character.Parent
    end
    if not character then
        return
    end
    return self:DamageCharacter(character, ...)
end

return PlayerDamageService