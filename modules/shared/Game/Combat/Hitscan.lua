--- Takes any number of attachments and casts a ray to their next position each frame
-- @classmod Hitscan
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

local Signal = require("Signal")
local BaseObject = require("BaseObject")

local Hitscan = setmetatable({}, BaseObject)
Hitscan.__index = Hitscan

function Hitscan:GetHitscanAttachments(part)
    local hitscanAttachments = {}
    for _, hitscanAttachment in ipairs(part:GetChildren()) do
        if hitscanAttachment.Name ~= "HitscanAttachment" then
            continue
        end

        table.insert(hitscanAttachments, hitscanAttachment)
    end

    return hitscanAttachments
end

function Hitscan.new(attachments, raycaster)
    local self = setmetatable(BaseObject.new(), Hitscan)

    self._attachments = if typeof(attachments) == "Instance" then
        self:GetHitscanAttachments(attachments)
    else
        attachments

    self._raycaster = raycaster
    self._prevPositions = table.create(#self._attachments)
    self._cachedHits = {}

    self.Hit = Signal.new()

    return self
end

function Hitscan:Start()
	self._maid.HitscanUpdate = RunService.Heartbeat:Connect(function()
		for index, attachment in ipairs(self._attachments) do
			local pos = attachment.WorldPosition
			local origin = self._prevPositions[index] or pos

			self._prevPositions[index] = pos

            local diff = (pos - origin)
            local direction = diff.Unit * diff.Magnitude
			local result = self._raycaster:Cast(origin, direction)

			if result then
                local instance = result.Instance
                if self._cachedHits[instance] then
                    continue
                end

                self._cachedHits[instance] = true
                self.Hit:Fire(result)
			end
		end
	end)
end

function Hitscan:Stop()
    self._maid.HitscanUpdate = nil

    table.clear(self._prevPositions)
    table.clear(self._cachedHits)
end

return Hitscan