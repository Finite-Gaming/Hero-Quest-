--- Provides class binders
-- @classmod ClassBinderProvider
-- @author frick

local ClassBinderProvider = {}
ClassBinderProvider.__index = ClassBinderProvider

function ClassBinderProvider.new(initFunction)
    local self = setmetatable({}, ClassBinderProvider)

    self._initFunction = assert(initFunction, "No initFunction")
    self._classBinderHolder = {}

    return self
end

function ClassBinderProvider:Init()
    self:_initFunction()
end

function ClassBinderProvider:AddClassBinder(classBinder)
    self[classBinder:GetName()] = classBinder
    table.insert(self._classBinderHolder, classBinder)
end

function ClassBinderProvider:GetAll()
    return self._classBinderHolder
end

return ClassBinderProvider