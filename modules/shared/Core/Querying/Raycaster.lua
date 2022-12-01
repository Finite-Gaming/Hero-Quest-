--- Repeats raycasting attempts while ignoring items via a filter function
-- @classmod Raycaster
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")

local Raycaster = {}

Raycaster.__index = Raycaster

function Raycaster.new(raycastParams, ignoreFunction)
	local self = setmetatable({}, Raycaster)

    self.MaxCasts = 5;
    self._ignoreList = {};
    self._raycastParams = raycastParams or RaycastParams.new()
	self.Filter = ignoreFunction

	return self
end

function Raycaster:Ignore(object)
	if typeof(object) == "Instance" then
		table.insert(self._ignoreList, object)
	elseif type(object) == "table" then
		for _, instance in pairs(object) do
			table.insert(self._ignoreList, instance)
		end
	end
    self:_updateParams()
end

function Raycaster:Cast(origin, direction)
	for _ = 1, self.MaxCasts do
        local castSuccess, hitData = self:_tryCast(origin, direction)

        if castSuccess then
            return hitData
        end
    end

    warn("[Raycaster] - Ran out of casts")
end

function Raycaster:_updateParams()
    self._raycastParams.FilterDescendantsInstances = self._ignoreList
end

function Raycaster:_tryCast(origin, direction)
	local result = workspace:Raycast(origin, direction, self._raycastParams)

    if result then
        if self.Visualize then
            DebugVisualizer:LookAtPart(origin, result.Position, 0.7, 0.05)
        end

        if self.Filter and self.Filter(result) then
            self:Ignore(result.Instance)
            return
        end

        return true, result
    end

    if self.Visualize then
        DebugVisualizer:LookAtPart(origin, origin + direction, 0.7, 0.05)
    end

    return true
end

return Raycaster