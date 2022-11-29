--- Casts from camera position to mouse using Raycaster.lua
-- @classmod MouseCaster
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")
local Mouse = Players.LocalPlayer:GetMouse()

local Raycaster = require("Raycaster")

local MouseCaster = {}
MouseCaster.__index = MouseCaster

function MouseCaster.new(ignoreFunction)
	local self = setmetatable({}, MouseCaster)

    self._raycaster = Raycaster.new()
	self._raycaster.Filter = ignoreFunction

	return self
end

function MouseCaster:Ignore(obj)
    self._raycaster:Ignore(obj)
end

function MouseCaster:__newindex(index, value)
    if index == "Filter" then
        self._raycaster.Filter = value
    else
        rawset(self, index, value)
    end
end

function MouseCaster:GetFallbackPosition()
    local unitRay = Mouse.UnitRay
    return unitRay.Origin + (unitRay.Direction * 1000)
end

function MouseCaster:FallbackCast()
    local mouseResult = self:Cast()

    return mouseResult and mouseResult.Position or self:GetFallbackPosition()
end

function MouseCaster:Cast()
    local unitRay = Mouse.UnitRay
    return self._raycaster:Cast(unitRay.Origin, unitRay.Direction * 1000)
end

return MouseCaster
