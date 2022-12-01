--- Makes candles flicker, lol
-- @classmod CandleFlicker
-- @author blox#2011, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local CandleFlicker = setmetatable({}, BaseObject)
CandleFlicker.__index = CandleFlicker

function CandleFlicker.new(obj)
    local self = setmetatable(BaseObject.new(obj), CandleFlicker)

    self._candleFlame = self._obj.CandleFlame
    self._candleSmoke = self._candleFlame.CandleSmoke
    self._candleFire = self._candleFlame.ParticleEmitter

    self._maid:AddTask(task.spawn(function()
        while task.wait(5) do
            if math.random(1, 2) == 2 then
                self:_setEffectsEnabled(false)
                task.wait(3)
                self:_setEffectsEnabled(true)
            end
        end
    end))

    return self
end

function CandleFlicker:_setEffectsEnabled(bool)
    self._candleSmoke.Enabled = bool
    self._candleFire.Enabled = bool
end

return CandleFlicker