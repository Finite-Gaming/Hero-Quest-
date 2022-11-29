--- Utility functions for assemblies/models
-- @classmod AssemblyUtils
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local WeldUtils = require("WeldUtils")

local AssemblyUtils = {}

function AssemblyUtils.assemble(model, primaryPart)
    primaryPart = primaryPart or assert(model.PrimaryPart, "No PrimaryPart")
    for _, object in ipairs(model:GetChildren()) do
        if object:IsA("BasePart") then
            WeldUtils.weld(primaryPart, object)
        elseif object:IsA("Folder") then
            AssemblyUtils.assemble(object, primaryPart)
        elseif object:IsA("Model") then
            AssemblyUtils.assemble(object)
        end
    end
end

function AssemblyUtils.rigidAssemble(model)
    local primaryPart = assert(model:FindFirstChild("Handle") or model.PrimaryPart, "No PrimaryPart")
    -- Accessory/tool compatible :DD
    for _, part in ipairs(model:GetDescendants()) do
        if part == primaryPart or not part:IsA("BasePart") then
            continue
        end

        WeldUtils.weld(primaryPart, part)
        part.Anchored = false
    end

    return model
end

function AssemblyUtils.setAnchored(model, bool)
    AssemblyUtils._setProperties(model, "Anchored", bool)
end

function AssemblyUtils.setCanQuery(model, bool)
    AssemblyUtils._setProperties(model, "CanQuery", bool)
end

function AssemblyUtils.setCanCollide(model, bool)
    AssemblyUtils._setProperties(model, "CanCollide", bool)
end

function AssemblyUtils._setProperties(model, property, value)
    for _, part in ipairs(model:GetDescendants()) do
        if not part:IsA("BasePart") then
            continue
        end

        part[property] = value
    end
end

return AssemblyUtils