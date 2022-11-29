--- Template provider object
-- @classmod TemplateProvider
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local TemplateProvider = setmetatable({}, BaseObject)
TemplateProvider.__index = TemplateProvider

function TemplateProvider.new(obj)
    return setmetatable(BaseObject.new(obj), TemplateProvider)
end

function TemplateProvider:Init()
    self._templates = {}
    self:_storeTemplates(self._obj)
end

function TemplateProvider:_storeTemplates(folder)
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Folder") then
            self:_storeTemplates(obj)
        else
            self._templates[obj.Name] = obj
        end
    end
end

function TemplateProvider:Get(templateName)
    local template = assert(self._templates[templateName], "Invalid name"):Clone()
    template.Name = template.Name:gsub("Template", "")
    return template
end

return TemplateProvider