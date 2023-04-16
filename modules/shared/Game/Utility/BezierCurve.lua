---
-- @classmod BezierCurve
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")

local BezierCurve = {}
BezierCurve.__index = BezierCurve

function BezierCurve.new(points, steps)
    local self = setmetatable({}, BezierCurve)

    self._curvePoints = {}
	for i, point in ipairs(points) do
		self._curvePoints[i] = point
	end

	self._step = 1 / steps
	self._segments = {}
	for t = 0, 1, self._step do
		local segmentPoints = {}
		for i = 1, #self._curvePoints do
			segmentPoints[i] = self._curvePoints[i]
		end
		for j = #self._curvePoints - 1, 1, -1 do
			for i = 1, j do
				segmentPoints[i] = segmentPoints[i] * (1 - t) + segmentPoints[i + 1] * t
			end
		end
		table.insert(self._segments, segmentPoints[1])
	end

    return self
end

function BezierCurve:GetPoint(t)
    t = math.clamp(t, 0, 1)

    local segmentIndex = math.floor(t / self._step) + 1
    local segmentStart = self._segments[segmentIndex]
    local segmentEnd = self._segments[segmentIndex + 1] or self._curvePoints[#self._curvePoints]

    local segmentT = (t - (segmentIndex - 1) * self._step) / self._step
    return segmentStart * (1 - segmentT) + segmentEnd * segmentT
end

function BezierCurve:Visualize(step)
    local parts = {}
    for _, point in ipairs(self._curvePoints) do
        table.insert(parts, DebugVisualizer:DebugPart(CFrame.new(point), Vector3.one))
    end
    local lastPoint = nil
    for t = 0, 1, step do
        local point = self:GetPoint(t)
        if not lastPoint then
            lastPoint = point
            continue
        end
        table.insert(parts, DebugVisualizer:LookAtPart(lastPoint, point, 0.5, 0.2))
        lastPoint = point
    end

    task.delay(5, function()
        for _, part in ipairs(parts) do
            part:Destroy()
        end
        table.clear(parts)
    end)
end

return BezierCurve