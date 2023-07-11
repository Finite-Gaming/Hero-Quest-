local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BezierCurve = require("BezierCurve");

local folder = workspace.BoulderTrap.TravelPoints

local sortedPoints = folder:GetChildren()
table.sort(sortedPoints, function(a, b)
    return tonumber(a.Name) < tonumber(b.Name)
end)
for index, part in ipairs(sortedPoints) do
    sortedPoints[index] = part.Position
end
print(sortedPoints)
local b = BezierCurve.new(sortedPoints, 100)
b:Visualize()