--- Initializes and provides class binders for the client
-- @classmod ClientClassBinders
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")
local ClassBinderProvider = require("ClassBinderProvider")

return ClassBinderProvider.new(function(self)
    self:AddClassBinder(ClassBinder.new("MeleeWeapon", require("MeleeWeaponClient")))
end)