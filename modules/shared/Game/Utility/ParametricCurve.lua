---
-- @classmod ParametricCurve
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")

local ParametricCurve = {}
ParametricCurve.__index = ParametricCurve

local function catmullRom(p0, p1, p2, p3, t)
	local t2 = t * t
	local t3 = t2 * t

	local a = -t3 + 2*t2 - t
	local b = 3*t3 - 5*t2 + 2
	local c = -3*t3 + 4*t2 + t
	local d = t3 - t2

	return 0.5 * (p0 * a + p1 * b + p2 * c + p3 * d)
end

local function calculateCurveLength(points)
	local length = 0
	for i = 1, #points - 1 do
		local p0 = points[i]
		local p1 = points[i + 1]
		local segmentLength = (p1 - p0).Magnitude
		length = length + segmentLength
	end
	return length
end

function ParametricCurve.new(points, steps)
    local self = setmetatable({}, ParametricCurve)

	self._paddedPoints = {points[1]}
	for i, v in ipairs(points) do
		self._paddedPoints[i + 1] = v
	end
	table.insert(self._paddedPoints, points[#points])

	self._curvePoints = {}
	local curveLength = calculateCurveLength(self._paddedPoints)
	local stepSize = curveLength / steps

	local t = 0
	for i = 1, steps do
		local lengthPassed = stepSize * i
		while lengthPassed > curveLength do
			lengthPassed = lengthPassed - curveLength
		end

		local segmentIndex = 1
		local segmentLength = (self._paddedPoints[segmentIndex + 1] - self._paddedPoints[segmentIndex]).Magnitude
		while lengthPassed > segmentLength do
			lengthPassed = lengthPassed - segmentLength
			segmentIndex = segmentIndex + 1
			segmentLength = (self._paddedPoints[segmentIndex + 1] - self._paddedPoints[segmentIndex]).Magnitude
		end

		local tSegment = lengthPassed / segmentLength
		local p = catmullRom(self._paddedPoints[segmentIndex - 1], self._paddedPoints[segmentIndex], self._paddedPoints[segmentIndex + 1], self._paddedPoints[segmentIndex + 2], tSegment)
		table.insert(self._curvePoints, p)
	end

    self._totalPoints = #self._curvePoints

    return self
end

function ParametricCurve:GetPoint(t)
    t = math.clamp(t, 0, 1)

    local ind = math.clamp(math.round(self._totalPoints * t), 1, self._totalPoints)
    return self._curvePoints[ind]
end

function ParametricCurve:Visualize()
    local parts = {}
    for _, point in ipairs(self._paddedPoints) do
        table.insert(parts, DebugVisualizer:DebugPart(CFrame.new(point), Vector3.one))
    end
    local lastPoint = nil
    for _, point in ipairs(self._curvePoints) do
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

return ParametricCurve