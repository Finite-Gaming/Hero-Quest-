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
    self.Damaged = Signal.new() -- :Fire(damage, player (optional))

    return self
end

function DamageTracker:Damage(amount, player)
    if player then
        local totalDamage = self._playerDamage[player]
        if totalDamage then
            self._playerDamage = totalDamage + amount
        end
    end

    self._obj:TakeDamage(amount)
    self.Damaged:Fire(amount, player)
end

function DamageTracker:GetPlayerDamage(player)
    return self._playerDamage[player]
end

return DamageTracker