--- Allows for setting/resetting a models appearance related properties
-- @classmod ModelAppearance
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ModelUtils = require("ModelUtils")

local ModelAppearance = setmetatable({}, BaseObject)
ModelAppearance.__index = ModelAppearance

function ModelAppearance.new(obj)
    local self = setmetatable(BaseObject.new(obj), ModelAppearance)

    self._parts = ModelUtils.getParts(self._obj)
    self._originalProperties = {}
    for _, part in ipairs(self._parts) do
        self._originalProperties[part] = {
            Color = part.Color;
            Transparency = part.Transparency;
        }

        if part:IsA("UnionOperation") then
            part.UsePartColor = true
        end
    end

    return self
end

function ModelAppearance:Strip()
    for _, obj in ipairs(self._obj:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Mesh") or obj:IsA("Folder") then
            continue
        end

        obj:Destroy()
    end
end

function ModelAppearance:SetColor(color)
    self:_setProperty("Color", color)
end

function ModelAppearance:ResetColor()
    self:_setProperty("Color")
end

function ModelAppearance:SetTransparency(transparency)
    self:_setProperty("Transparency", transparency)
end

function ModelAppearance:ResetTransparency()
    self:_setProperty("Transparency")
end

function ModelAppearance:SetMaterial(material)
    self:_setProperty("Material", material)
end

function ModelAppearance:ResetMaterial()
    self:_setProperty("Material")
end


function ModelAppearance:_setProperty(property, value)
    for _, part in ipairs(self._parts) do
        if part.Transparency == 1 then
            continue
        end

        part[property] = value or self._originalProperties[part][property]
    end
end

return ModelAppearance