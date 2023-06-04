---
-- @classmod SoundModifier
-- @author

local SoundModifier = {}

function SoundModifier:Init()
    self._methodMap = {}

    self:_addMethod("RandomPitchEffect", nil, "PitchShiftSoundEffect", "Octave")
end

function SoundModifier:ProcessSound(sound)
    for methodName, _ in pairs(self._methodMap) do
        local range = sound:GetAttribute(methodName)
        if range then
            self[methodName]:Apply(sound, range)
        end
    end
end

function SoundModifier:_addMethod(methodName, modFunc, baseInstName, ...)
    local properties = {...}
    local baseObject = {}

    if baseInstName then
        function baseObject:Apply(sound, ...)
            local ranges = {...}
            local soundEffect = sound:FindFirstChild(methodName)
            if not soundEffect then
                soundEffect = Instance.new(baseInstName)
                soundEffect.Name = methodName
                soundEffect.Parent = sound
            end

            for i, property in ipairs(properties) do
                local range = ranges[i]
                soundEffect[property] = Random.new():NextNumber(range.Min, range.Max)
            end
        end
    else
        baseObject.Apply = modFunc
    end

    self._methodMap[methodName] = true
    self[methodName] = baseObject
end

return SoundModifier