---
-- @classmod RaycastList
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")

local RaycastList = setmetatable({}, BaseObject)
RaycastList.__index = RaycastList

function RaycastList.new(folders, includeFunction, raycastParams)
    local self = setmetatable(BaseObject.new(), RaycastList)

    self._raycastParams = raycastParams or RaycastParams.new()
    self._includeFunction = includeFunction
    self._ignoreList = {}

    if typeof(folders) == "table" then
        for _, folder in ipairs(folders) do
            self:_processFolder(folder)
        end
    elseif typeof(folders) == "Instance" then
        self:_processFolder(folders)
    end

    self._raycastParams.FilterDescendantsInstances = self._ignoreList

    return self
end

function RaycastList:Get()
    return self._raycastParams
end

function RaycastList:_processFolder(folder)
    for _, child in ipairs(folder:GetDescendants()) do
        self:_processChild(child)
    end

    self._maid:AddTask(folder.DescendantAdded:Connect(function(child)
        if self:_processChild(child) then
            self._raycastParams.FilterDescendantsInstances = self._ignoreList
        end
    end))
end

function RaycastList:_processChild(child)
    if self._includeFunction(child) then
        table.insert(self._ignoreList, child)
        return true
    end
end

return RaycastList