---
-- @classmod CameraTrigger
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ClientClassBinders = require("ClientClassBinders")
local BottomCaptionService = require("BottomCaptionService")
local UserDataClient = require("UserDataClient")

local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local INPUT_SINKER_ACTION_NAME = "__sinkInputs"
local IS_NEW_PLAYER = not UserDataClient:HasBeatenDungeon()

local CameraTrigger = setmetatable({}, BaseObject)
CameraTrigger.__index = CameraTrigger

function CameraTrigger.new(obj)
    local self = setmetatable(BaseObject.new(obj), CameraTrigger)

    self._triggerPart = self._obj:WaitForChild("Trigger")
    self._posAttachment = self._triggerPart:WaitForChild("CameraPosition")
    self._targetValue = self._obj:WaitForChild("Target")

    self._triggerPart.Transparency = 1

    if IS_NEW_PLAYER then
        self._clientZone = ClientClassBinders.ClientZone:BindAsync(self._triggerPart)
        self._maid:AddTask(self._clientZone.Touched:Connect(function(hitPart, character)
            if self._touched then
                ClientClassBinders.ClientZone:Unbind(self._triggerPart)
                return
            end

            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then
                return
            end

            self._touched = true
            self:_setControlsEnabled(false)

            local camera = workspace.CurrentCamera
            local relativeCFrame = humanoidRootPart.CFrame:ToObjectSpace(camera.CFrame)

            camera.CameraType = Enum.CameraType.Scriptable
            local inTween = self._maid:AddTask(TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = CFrame.lookAt(self._posAttachment.WorldPosition, self._targetValue.Value.Position);
            }))

            BottomCaptionService:Caption(self._obj:GetAttribute("CaptionText"), self._obj:GetAttribute("DisplayTime"), self._obj:GetAttribute("ReadSpeed"), function()
                local outTween = self._maid:AddTask(TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    CFrame = humanoidRootPart.CFrame * relativeCFrame;
                }))

                self._maid:AddTask(outTween.Completed:Connect(function()
                    camera.CameraType = Enum.CameraType.Custom
                    self:_setControlsEnabled(true)

                    ClientClassBinders.CameraTrigger:Unbind(self._obj)
                end))

                outTween:Play()
            end)

            inTween:Play()
        end))
    end

    return self
end

function CameraTrigger:_setControlsEnabled(state)
    if state then
        ContextActionService:UnbindAction(INPUT_SINKER_ACTION_NAME)
    else
        ContextActionService:BindAction(
            INPUT_SINKER_ACTION_NAME,
            function()
                return Enum.ContextActionResult.Sink
            end,
            false,
            unpack(Enum.PlayerActions:GetEnumItems())
        )
    end
end

return CameraTrigger