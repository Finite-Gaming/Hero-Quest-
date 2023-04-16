local function catmullRom(p0, p1, p2, p3, t)
	local t2 = t * t
	local t3 = t2 * t

	local a = -t3 + 2*t2 - t
	local b = 3*t3 - 5*t2 + 2
	local c = -3*t3 + 4*t2 + t
	local d = t3 - t2

	return 0.5 * (p0 * a + p1 * b + p2 * c + p3 * d)
end

-- Main function to create a parametric curve in 3D space
function createParametricCurve(points, numSegments)
	assert(#points >= 4, "At least 4 points are required")

	-- Duplicate the first and last points to ensure triple knots
	local paddedPoints = {points[1], points[1]}
	for i, v in ipairs(points) do
		paddedPoints[i + 2] = v
	end
	table.insert(paddedPoints, points[#points])
	table.insert(paddedPoints, points[#points])

	local curvePoints = {}
	for i = 1, #paddedPoints - 3 do
		for t = 0, 1, 1 / numSegments do
			local p = catmullRom(paddedPoints[i], paddedPoints[i + 1], paddedPoints[i + 2], paddedPoints[i + 3], t)
			table.insert(curvePoints, p)
		end
	end

	return function(t)
		local ind = math.clamp(math.round(#curvePoints * t), 1, #curvePoints)
		return curvePoints[ind]
	end
end

---
-- @classmod ParametricCurve
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DebugVisualizer = require("DebugVisualizer")

local ParametricCurve = {}
ParametricCurve.__index = ParametricCurve

function ParametricCurve.new(points, steps)
    local self = setmetatable({}, ParametricCurve)

	self._paddedPoints = {points[1]}
	for i, v in ipairs(points) do
		self._paddedPoints[i + 1] = v
	end
	table.insert(self._paddedPoints, points[#points])

	self._curvePoints = {}
	for i = 1, #self._paddedPoints - 3 do
		for t = 0, 1, 1 / steps do
			local p = catmullRom(self._paddedPoints[i], self._paddedPoints[i + 1], self._paddedPoints[i + 2], self._paddedPoints[i + 3], t)
			table.insert(self._curvePoints, p)
		end
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