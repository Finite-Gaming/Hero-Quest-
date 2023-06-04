---
-- @classmod NPCRaycastParams
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RaycastList = require("RaycastList")

local NPCRaycastParams = {}

function NPCRaycastParams:Init()
    self._raycastParams = RaycastParams.new()
    self._raycastParams.FilterType = Enum.RaycastFilterType.Include

    self._raycastList = RaycastList.new(workspace.Rooms, function(child)
        if child.Name == "HumanoidRootPart" then
            return true
        end
    end, self._raycastParams)
end

function NPCRaycastParams:Get()
    return self._raycastList:Get()
end

return NPCRaycastParams