--- Takes any number of attachments and casts a ray to their next position each frame
-- @classmod Hitscan
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local Signal = require("Signal")

local RunService = game:GetService("RunService")

local Hitscan = {}
Hitscan.ClassName = "Hitscan"
Hitscan.__index = Hitscan

function Hitscan.new(attachments, raycaster)
    local self = setmetatable({}, Hitscan)

    self._attachments = attachments
    self._raycaster = raycaster
    self._prevPositions = table.create(#attachments)

    self.Hit = Signal.new()

    return self
end

function Hitscan:Start()
    self._prevPositions = {}
    self._scanning = true

	self._hitscanUpdate = RunService.Heartbeat:Connect(function()
		for index, attachment in ipairs(self._attachments) do
			local pos = attachment.WorldPosition
			local origin = self._prevPositions[index] or pos

			self._prevPositions[index] = pos

            local diff = (pos - origin)
            local direction = diff.Unit * diff.Magnitude
			local result = workspace:Raycast(origin, direction, self._raycastParams)

			if result then
                self.Hit:Fire(result)
			end
		end
	end)
end

return Hitscan