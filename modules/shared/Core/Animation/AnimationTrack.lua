--- Creates an animation track for a humanoid, basically just a small :LoadAnimation wrapper
-- @classmod AnimationTrack
-- @author frick

local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

function AnimationTrack.new(humanoid, id)
    local animation = Instance.new("Animation")
    animation.AnimationId = id
    --animation.Parent = humanoid

    return humanoid:LoadAnimation(animation)
end

return AnimationTrack