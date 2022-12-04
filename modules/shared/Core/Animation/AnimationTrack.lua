--- Creates an animation track for a humanoid, basically just a small :LoadAnimation wrapper
-- @classmod AnimationTrack
-- @author frick

local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

function AnimationTrack.new(animationOrId, humanoid)
    local animation = nil
    if typeof(animationOrId) == "Instance" then
        animation = animationOrId
    else
        animation = Instance.new("Animation")
        animation.AnimationId = animationOrId
    end

    return humanoid:LoadAnimation(animation)
end

return AnimationTrack