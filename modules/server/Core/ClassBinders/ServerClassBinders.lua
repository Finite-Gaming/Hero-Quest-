--- Initializes and provides server class binders
-- @classmod ServerClassBinders
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClassBinder = require("ClassBinder")
local ClassBinderProvider = require("ClassBinderProvider")

return ClassBinderProvider.new(function(self)
    self:AddClassBinder(ClassBinder.new("Seat", require("Seat"))) -- Binder name, class
    self:AddClassBinder(ClassBinder.new("IdleAnimation", require("IdleAnimation")))
end)