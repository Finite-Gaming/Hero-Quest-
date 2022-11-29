--- Class meant to be bound to a character/npc that plays its idle animation
-- @classmod IdleAnimation
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local IdleAnimation = setmetatable({}, BaseObject)
IdleAnimation.__index = IdleAnimation

function IdleAnimation.new(obj)
    local self = setmetatable(BaseObject.new(obj), IdleAnimation)

    self._idleAnimation = self._obj.IdleAnimation
    self._humanoid = self._obj.Humanoid
    self._animationTrack = self._maid:AddTask(self._humanoid:LoadAnimation(self._idleAnimation))
    self._maid:AddTask(function()
        self._animationTrack:Stop()
    end)

    self._animationTrack:Play()

    return self
end

return IdleAnimation