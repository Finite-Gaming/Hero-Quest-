---
-- @classmod RandomRange
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RandomRange = {}
RandomRange.__index = RandomRange

function RandomRange.new(min, max)
    local self = setmetatable({}, RandomRange)

    self._min = min
    self._max = max

    self._randomObject = Random.new()
    if min % 1 == 0 and max % 1 == 0 then
        self._getRandomNumber = self._randomObject.NextInteger
    else
        self._getRandomNumber = self._randomObject.NextNumber
    end

    return self
end

function RandomRange:Get()
    if self._min == self._max then
        return self._min
    end

    local number = self._getRandomNumber(self._randomObject, self._min, self._max)
    local repeats = 0
    while number == self._lastNumber do
        if repeats == 5 then
            number = math.clamp(number - 1, self._min, self._max)

            if number == self._lastNumber then
                number = math.clamp(number + 1, self._min, self._max)
            end
            break
        end
        number = self._getRandomNumber(self._randomObject, self._min, self._max)
        repeats += 1
    end

    self._lastNumber = number
    return number
end

return RandomRange