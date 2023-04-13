--- Initializes and provides class binders for the client
-- @classmod ClientClassBinders
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")
local ClassBinderProvider = require("ClassBinderProvider")

return ClassBinderProvider.new(function(self)
    -- Interface
    self:AddClassBinder(ClassBinder.new("PlayerInfoDisplay", require("PlayerInfoDisplay")))
    self:AddClassBinder(ClassBinder.new("MainButtonsInterface", require("MainButtonsInterface")))
    self:AddClassBinder(ClassBinder.new("ShopInterface", require("ShopInterface")))

    -- Puzzle
    self:AddClassBinder(ClassBinder.new("PuzzleBridge", require("PuzzleBridgeClient")))

    -- Misc
    self:AddClassBinder(ClassBinder.new("HumanoidLocker", require("HumanoidLocker")))
    self:AddClassBinder(ClassBinder.new("ClientZone", require("ClientZone")))
    self:AddClassBinder(ClassBinder.new("CameraTrigger", require("CameraTrigger")))

    -- Tools
    self:AddClassBinder(ClassBinder.new("MeleeWeapon", require("MeleeWeaponClient")))

    -- Traps
    self:AddClassBinder(ClassBinder.new("Spikes", require("SpikesClient")))
    self:AddClassBinder(ClassBinder.new("Boulder", require("BoulderClient")))
    self:AddClassBinder(ClassBinder.new("Axe", require("AxeClient")))
end)