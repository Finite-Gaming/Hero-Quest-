---
-- @classmod SymbolPuzzle
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local BaseObject = require("BaseObject")
local Signal = require("Signal")
local HumanoidUtils = require("HumanoidUtils")

local SymbolPuzzle = setmetatable({}, BaseObject)
SymbolPuzzle.__index = SymbolPuzzle

function SymbolPuzzle.new(obj)
    local self = setmetatable(BaseObject.new(obj), SymbolPuzzle)

    self.Solved = Signal.new() -- :Fire()

    self._currentStep = 1
    warn("yo")
    self._orderedSymbols = {}
    self._originalColors = {}
    for _, symbol in ipairs(self._obj:GetChildren()) do
        local symbolOrder = tonumber(symbol.Name)
        local originalColor = symbol.Color

        self._orderedSymbols[symbolOrder] = symbol
        self._originalColors[symbolOrder] = originalColor

        self._maid:AddTask(symbol.Touched:Connect(function(part)
            local humanoid = HumanoidUtils.getHumanoid(part)
            if not humanoid then
                return
            end

            local character = humanoid.Parent
            if not Players[character.Name] then
                return
            end
            if humanoid.Health <= 0 then
                return
            end

            if symbolOrder ~= self._currentStep then
                if self._currentStep ~= 1 and symbolOrder > self._currentStep then
                    self:_reset()
                    return
                end
            else
                self._currentStep += 1
                symbol.Color = originalColor:Lerp(Color3.new(), 0.5)
                symbol.Activate:Play()
            end

            if self._currentStep == #self._orderedSymbols + 1 then
                self.Solved:Fire()
                self:_setTint(0.8)
            end
        end))
    end

    return self
end

function SymbolPuzzle:_reset()
    self:_setTint(0)
    self._orderedSymbols[1].Deactivate:Play()
    self._currentStep = 1
end

function SymbolPuzzle:_setTint(tint)
    for symbolOrder, symbol in ipairs(self._orderedSymbols) do
        symbol.Color = self._originalColors[symbolOrder]:Lerp(Color3.new(), tint)
    end
end

return SymbolPuzzle