--- Does cool things
-- @classmod ClassName
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local ClassName = setmetatable({}, BaseObject)
ClassName.__index = ClassName

function ClassName.new(obj)
    local self = setmetatable(BaseObject.new(obj), ClassName)

    return self
end

return ClassName