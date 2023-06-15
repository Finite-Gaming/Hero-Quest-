--- Initializes and provides class binders for the client
-- @classmod ClientClassBinders
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")
local ClassBinderProvider = require("ClassBinderProvider")

return ClassBinderProvider.new(function(self)
    -- Interface
    self:AddClassBinder(ClassBinder.new("PlayerInfoDisplay", require("PlayerInfoDisplay")))
    self:AddClassBinder(ClassBinder.new("ShopInterface", require("ShopInterface")))
    self:AddClassBinder(ClassBinder.new("InventoryUI", require("InventoryUI")))
    self:AddClassBinder(ClassBinder.new("UpgradeUI", require("UpgradeUI")))
    self:AddClassBinder(ClassBinder.new("RedeemCodeUI", require("RedeemCodeUI")))
    self:AddClassBinder(ClassBinder.new("MainButtonsInterface", require("MainButtonsInterface")))
    self:AddClassBinder(ClassBinder.new("PlayerAbilityUI", require("PlayerAbilityUI")))
    self:AddClassBinder(ClassBinder.new("PlayScreen", require("PlayScreen")))

    -- character
    self:AddClassBinder(ClassBinder.new("Character", require("CharacterClient")))

    -- Puzzle
    self:AddClassBinder(ClassBinder.new("PuzzleBridge", require("PuzzleBridgeClient")))

    -- Misc
    self:AddClassBinder(ClassBinder.new("HumanoidLocker", require("HumanoidLocker")))
    self:AddClassBinder(ClassBinder.new("ClientZone", require("ClientZone")))
    self:AddClassBinder(ClassBinder.new("CameraTrigger", require("CameraTrigger")))

    self:AddClassBinder(ClassBinder.new("Pet", require("PetClient")))
    self:AddClassBinder(ClassBinder.new("IKPedal", require("IKPedalClient")))

    -- Tools
    self:AddClassBinder(ClassBinder.new("MeleeWeapon", require("MeleeWeaponClient")))

    -- Abilities
    self:AddClassBinder(ClassBinder.new("BeamAbility", require("BeamAbilityClient")))

    self:AddClassBinder(ClassBinder.new("PlayerAbility", require("PlayerAbilityClient")))

    -- Traps
    self:AddClassBinder(ClassBinder.new("Spikes", require("SpikesClient")))
    self:AddClassBinder(ClassBinder.new("Boulder", require("BoulderClient")))
    self:AddClassBinder(ClassBinder.new("Axe", require("AxeClient")))
end)