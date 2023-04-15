---
-- @classmod LevelUpEffect
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local EffectPlayerClient = require("EffectPlayerClient")
local AnimationTrack = require("AnimationTrack")

local LevelUpEffect = setmetatable({}, BaseObject)
LevelUpEffect.__index = LevelUpEffect

function LevelUpEffect.new(character)
    local self = setmetatable(BaseObject.new(), LevelUpEffect)

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    if humanoid.Health <= 0 then
        return
    end

    local rootPart = humanoid.RootPart
    if not rootPart then
        return
    end

    local effectPos = rootPart.Position + Vector3.new(0, (-rootPart.Size.Y/2) - humanoid.HipHeight + 0.3)
    EffectPlayerClient:PlayEffect("LevelUp", effectPos)

    local animationTrack = self._maid:AddTask(AnimationTrack.new("rbxassetid://13138845615", humanoid))
    animationTrack.Priority = Enum.AnimationPriority.Action
    self._maid:AddTask(animationTrack.Stopped:Connect(function()
        self:Destroy()
    end))
    animationTrack:Play()

    return self
end

return LevelUpEffect