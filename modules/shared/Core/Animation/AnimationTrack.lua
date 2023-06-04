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

    if not humanoid:IsDescendantOf(game) then
        print(humanoid:GetFullName())
        local currentThread = coroutine.running()

        local old; old = humanoid.Parent:GetPropertyChangedSignal("Parent"):Connect(function()
            if humanoid:IsDescendantOf(game) then
                old:Disconnect()
                coroutine.resume(currentThread, humanoid:LoadAnimation(animation))
            end
        end)

        return coroutine.yield()
    end

    return humanoid:LoadAnimation(animation)
end

return AnimationTrack