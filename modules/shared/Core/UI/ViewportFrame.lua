--- Viewport frame wrapper with spin implementation
-- @classmod ViewportFrame
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local ViewportModel = require("ViewportModel")
local ModelUtils = require("ModelUtils")

local ViewportFrame = setmetatable({}, BaseObject)
ViewportFrame.__index = ViewportFrame

function ViewportFrame.new(model, doNotClone)
    local self = setmetatable(BaseObject.new(doNotClone and model or model:Clone()), ViewportFrame)

    self._viewportFrame = self._maid:AddTask(Instance.new("ViewportFrame"))
	self._camera = Instance.new("Camera")
	self._viewportFrame.CurrentCamera = self._camera
	self._camera.Parent = self._viewportFrame

	self._modelCFrame = CFrame.identity

    ModelUtils.createBasePart(self._obj)
	self._obj:PivotTo(self._modelCFrame)
	self._obj.Parent = self._viewportFrame

	self._viewportFrame.BackgroundTransparency = 1
	self._viewportFrame.Size = UDim2.fromScale(1, 1)
	self._viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self._viewportFrame.Position = UDim2.fromScale(0.5, 0.5)
	self._viewportFrame.LightDirection = Vector3.new(1, -1, 1)

	self._viewportModel = ViewportModel.new(self._viewportFrame)
	self._viewportModel:SetModel(self._obj)

	self._distanceOffset = CFrame.new(
        0,
        0,
        self._viewportModel:GetFitDistance(self._modelCFrame.Position)
    )
	self._camera.CFrame = self._modelCFrame * self._distanceOffset

    return self
end

function ViewportFrame:SetCameraCFrame(cframe)
	self._camera.CFrame = cframe
end

function ViewportFrame:SetDistanceOffset(distance)
	self._distanceOffset = CFrame.new(0, 0, distance)
	self._camera.CFrame = self._modelCFrame * self._distanceOffset
end

function ViewportFrame:EnableSpin()
    self._spinStep = math.rad(-20)
	self._angle = self._spinStep

	self._maid:AddTask(RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))
end

function ViewportFrame:GetViewportFrame()
    return self._viewportFrame
end

function ViewportFrame:SetParent(parent)
	self._viewportFrame.Parent = parent
end

function ViewportFrame:_update(dt)
    self._angle += self._spinStep * dt
    self._camera.CFrame = self._modelCFrame * CFrame.fromOrientation(self._spinStep, self._angle, 0) * self._distanceOffset
end

return ViewportFrame