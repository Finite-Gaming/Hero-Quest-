--- do not use this, not finished
-- @classmod CameraShake
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Spring = require("Spring")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraShake = setmetatable({}, BaseObject)
CameraShake.__index = CameraShake

function CameraShake.new(intensity)
    local self = setmetatable(BaseObject.new(), CameraShake)

    self._camera = workspace.CurrentCamera

    self._posSpring = Spring.new(Vector3.zero)
    self._posSpring.Speed = 100
    self._posSpring.Damper = 2

    self._rotSpring = Spring.new(Vector3.zero)
    self._rotSpring.Speed = 100
    self._rotSpring.Damper = 2

    self._randomObject = Random.new()

    local posOffset = Vector3.new(
        self._randomObject:NextInteger(0.25 * intensity, 1.5 * intensity),
        self._randomObject:NextInteger(0.25 * intensity, 1.5 * intensity),
        self._randomObject:NextInteger(0.25 * intensity, 1.5 * intensity)
    )
    local rotOffset = Vector3.new(
        self._randomObject:NextInteger(1 * intensity, 5 * intensity),
        self._randomObject:NextInteger(1 * intensity, 5 * intensity),
        self._randomObject:NextInteger(1 * intensity, 5 * intensity)
    )

    self._swapTime = 0.5 * intensity
    self._endTime = 1 * intensity
    self._bindName = "__cameraShake"
    self._startTime = os.clock()
    RunService:BindToRenderStep(self._bindName, Enum.RenderPriority.Camera.Value, function(dt)
        local timeDiff = os.clock() - self._startTime
        if timeDiff >= self._swapTime then
            if timeDiff >= self._endTime then
                RunService:UnbindFromRenderStep(self._bindName)
                self._maid:Destroy()
            else
                self._posSpring.Target = Vector3.zero
                self._rotSpring.Target = Vector3.zero
            end
        else
            self._posSpring.Target = posOffset
            self._rotSpring.Target = rotOffset
        end

        local position = self._posSpring.Position
        local orientation = self._posSpring.Position

        self._camera.CFrame *= CFrame.new(position.X, position.Y, position.Z) *
            CFrame.fromOrientation(orientation.X, orientation.Y, orientation.Z)
    end)

    return self
end

return CameraShake