
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ModelUtils = require("ModelUtils")

local Selection = game:GetService("Selection")
-- [[change this to your model path VV]]
local model = game.ServerStorage.Templates.WardenTemplate

local selected = assert(Selection:Get()[1], "select something")

local obj = model:Clone()
local viewportFrame = Instance.new("ViewportFrame")
local camera = Instance.new("Camera")
viewportFrame.CurrentCamera = camera
camera.Parent = viewportFrame

local modelCFrame = CFrame.identity

ModelUtils.createBasePart(obj)
obj:PivotTo(modelCFrame)
obj.Parent = viewportFrame

viewportFrame.BackgroundTransparency = 1
viewportFrame.Size = UDim2.fromScale(1, 1)
viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
viewportFrame.Position = UDim2.fromScale(0.5, 0.5)
viewportFrame.LightDirection = Vector3.new(1, -1, 1)

local distanceOffset = CFrame.new(
    0,
    6,
    7
)
camera.CFrame = modelCFrame * CFrame.Angles(0, math.pi, 0) * distanceOffset

viewportFrame.Parent = selected