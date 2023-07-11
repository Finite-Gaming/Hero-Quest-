--- Initializes and provides class binders for the client
-- @classmod ClientClassBinders
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")
local ClientBinder = require("ClientBinder")
local ClassBinderProvider = require("ClassBinderProvider")

return ClassBinderProvider.new(function(self)
    -- Interface
    self:AddClassBinder(ClientBinder.new("PlayerInfoDisplay", require("PlayerInfoDisplay")))
    self:AddClassBinder(ClientBinder.new("ShopInterface", require("ShopInterface")))
    self:AddClassBinder(ClientBinder.new("InventoryUI", require("InventoryUI")))
    self:AddClassBinder(ClientBinder.new("UpgradeUI", require("UpgradeUI")))
    self:AddClassBinder(ClientBinder.new("RedeemCodeUI", require("RedeemCodeUI")))
    self:AddClassBinder(ClientBinder.new("QuestUI", require("QuestUI")))
    self:AddClassBinder(ClientBinder.new("SettingsUI", require("SettingsUI")))
    self:AddClassBinder(ClientBinder.new("PlayerAbilityUI", require("PlayerAbilityUI")))
    self:AddClassBinder(ClientBinder.new("PlayScreen", require("PlayScreen")))
    self:AddClassBinder(ClientBinder.new("MainButtonsInterface", require("MainButtonsInterface")))

    -- character
    self:AddClassBinder(ClassBinder.new("MovementLocker", require("MovementLockerClient")))
    self:AddClassBinder(ClassBinder.new("CharacterClient", require("CharacterClient")))

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