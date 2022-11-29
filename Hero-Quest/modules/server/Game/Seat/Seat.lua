--- Class meant to be bound to a Seat instance that plays an animation parented to it when seated
-- @classmod Seat
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local Seat = setmetatable({}, BaseObject)
Seat.__index = Seat

function Seat.new(obj)
    local self = setmetatable(BaseObject.new(obj), Seat)

    self._sitAnimation = self._obj.SitAnimation
    self._maid:AddTask(self._obj:GetPropertyChangedSignal("Occupant"):Connect(function()
        self:_handleOccupantChanged()
    end))

    return self
end

function Seat:_handleOccupantChanged()
    local occupant = self._obj.Occupant

    if occupant then
        local animationTrack = occupant:LoadAnimation(self._sitAnimation)
        animationTrack:Play()

        self._maid.AnimationTrack = animationTrack
    else
        self._maid.AnimationTrack:Stop()
        self._maid.AnimationTrack = nil
    end
end

return Seat