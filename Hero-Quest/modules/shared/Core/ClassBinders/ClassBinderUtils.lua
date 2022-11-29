--- Various utility functions for class binders
-- @classmod ClassBinderUtils
-- @author frick

local ClassBinderUtils = {}

function ClassBinderUtils.getChildren(object, binder, recurse)
    local classes = {}

    for _, child in ipairs(recurse and object:GetDescendants() or object:GetChildren()) do
        local class = binder:Get(child)
        if class then
            table.insert(classes, class)
        end
    end
    return classes
end

function ClassBinderUtils.getDescendants(object, binder)
    return ClassBinderUtils.getChildren(object, binder, true)
end

function ClassBinderUtils.findFirstAncestor(object, binder)
    local parent = object

    while parent do
        local class = binder:Get(parent)

        if class then
            return class
        end

        parent = parent.Parent
    end
end

return ClassBinderUtils