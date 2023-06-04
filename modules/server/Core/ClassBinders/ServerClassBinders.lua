--- Initializes and provides server class binders
-- @classmod ServerClassBinders
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")
local ClassBinderProvider = require("ClassBinderProvider")

return ClassBinderProvider.new(function(self)
    self:AddClassBinder(ClassBinder.new("Portal", require("PortalTeleport")))
    self:AddClassBinder(ClassBinder.new("Character", require("Character")))

    -- Traps
    self:AddClassBinder(ClassBinder.new("Spikes", require("Spikes")))
    self:AddClassBinder(ClassBinder.new("Boulder", require("Boulder")))
    self:AddClassBinder(ClassBinder.new("Axe", require("Axe")))
    self:AddClassBinder(ClassBinder.new("Flamethrower", require("Flamethrower")))

    -- Puzzles
    self:AddClassBinder(ClassBinder.new("SymbolPuzzle", require("SymbolPuzzle")))
    self:AddClassBinder(ClassBinder.new("PuzzleBridge", require("PuzzleBridge")))

    -- Misc
    self:AddClassBinder(ClassBinder.new("Seat", require("Seat")))
    self:AddClassBinder(ClassBinder.new("IdleAnimation", require("IdleAnimation")))
    self:AddClassBinder(ClassBinder.new("CandleFlicker", require("CandleFlicker")))
    self:AddClassBinder(ClassBinder.new("DamageTracker", require("DamageTracker")))
    self:AddClassBinder(ClassBinder.new("InteractiveTeleporter", require("InteractiveTeleporter")))

    self:AddClassBinder(ClassBinder.new("Pet", require("Pet")))

    -- Abilities
    self:AddClassBinder(ClassBinder.new("PlayerAbility", require("PlayerAbility")))

    self:AddClassBinder(ClassBinder.new("BeamAbility", require("BeamAbility")))

    -- Tools
    self:AddClassBinder(ClassBinder.new("MeleeWeapon", require("MeleeWeapon")))

    -- NPC
    self:AddClassBinder(ClassBinder.new("NPC", require("NPC")))
end)