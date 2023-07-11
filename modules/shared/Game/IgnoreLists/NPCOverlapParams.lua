---
-- @classmod NPCOverlapParams
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RaycastList = require("RaycastList")
local GameManager = require("GameManager")

local NPCOverlapParams = {}

function NPCOverlapParams:Init()
    if self._initialized then
        return
    end
    self._initialized = true

    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterType = Enum.RaycastFilterType.Include

    if GameManager:IsLobby() then
        self._folder = workspace:WaitForChild("Lobby"):WaitForChild("TestDummies")
    elseif GameManager:IsDungeon() then
        self._folder = workspace:WaitForChild("Rooms")
    end

    self._raycastList = RaycastList.new(self._folder, function(child)
        if child.Name == "HumanoidRootPart" then
            return true
        end
    end, self._overlapParams)
end

function NPCOverlapParams:Get()
    if not self._initialized then
        self:Init()
    end

    return self._raycastList:Get()
end

return NPCOverlapParams