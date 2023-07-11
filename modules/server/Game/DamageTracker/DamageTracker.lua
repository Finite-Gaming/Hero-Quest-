---
-- @classmod DamageTracker
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Signal = require("Signal")

local DamageTracker = setmetatable({}, BaseObject)
DamageTracker.__index = DamageTracker

function DamageTracker.new(obj)
    local self = setmetatable(BaseObject.new(obj), DamageTracker)

    assert(typeof(self._obj) == "Instance" and self._obj:IsA("Humanoid"))
    self._playerDamage = {}
    self._damageTags = {}
    self.Damaged = Signal.new() -- :Fire(damage, player (optional))

    return self
end

function DamageTracker:Damage(amount, player, damageTag)
    amount = math.clamp(amount, 0, self._obj.Health)
    if player then
        if damageTag then
            local playerTags = self._damageTags[player]
            if not playerTags then
                playerTags = {}
                self._damageTags[player] = playerTags
            end
            playerTags[damageTag] = true
        end

        local totalDamage = self._playerDamage[player]
        if totalDamage then
            self._playerDamage[player] += amount
        else
            self._playerDamage[player] = amount
        end
    end

    self._obj:TakeDamage(amount)
    self.Damaged:Fire(amount, player, self._obj.Health/self._obj.MaxHealth, damageTag)
end

function DamageTracker:GetDamageTags()
    return self._damageTags
end

function DamageTracker:GetPlayerTags(player)
    return self._damageTags[player]
end

function DamageTracker:GetDamageMap()
    return self._playerDamage
end

function DamageTracker:GetPlayerDamage(player)
    return self._playerDamage[player]
end

return DamageTracker