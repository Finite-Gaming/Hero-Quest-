---
-- @classmod CaptionShowcaseClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BottomCaptionService = require("BottomCaptionService")

local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local INPUT_SINKER_ACTION_NAME = "__sinkInputs"

local CaptionShowcaseClient = {}

function CaptionShowcaseClient:Showcase(atPosition, targetPosition, captionText, displayTime, readSpeed, doNotReturn, finishedFunction)
    local character = Players.LocalPlayer.Character
    if not character then
        warn("[CaptionShowcaseClient] - No Character!")
        return
    end

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    self:_setControlsEnabled(false)

    local camera = workspace.CurrentCamera
    local relativeCFrame = humanoidRootPart.CFrame:ToObjectSpace(camera.CFrame)

    camera.CameraType = Enum.CameraType.Scriptable
    local changed = camera:GetPropertyChangedSignal("CameraType"):Connect(function()
        camera.CameraType = Enum.CameraType.Scriptable
    end)
    local inTween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.lookAt(atPosition, targetPosition);
    })

    BottomCaptionService:Caption(captionText, displayTime, readSpeed, function()
        changed:Disconnect()
        if doNotReturn then
            if finishedFunction then
                finishedFunction()
            end

            return
        end

        local outTween = TweenService:Create(camera, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            CFrame = humanoidRootPart.CFrame + relativeCFrame.Position;
        })

        outTween.Completed:Connect(function()
            if finishedFunction then
                finishedFunction()
            end

            camera.CameraType = Enum.CameraType.Custom
            self:_setControlsEnabled(true)
        end)

        outTween:Play()
    end)

    inTween:Play()
end

function CaptionShowcaseClient:BatchShowcase(infoTable)
    for index, data in ipairs(infoTable) do
        local thread = coroutine.running()
        task.spawn(function()
            self:Showcase(
            data.AtPosition,
            data.TargetPosition,
            data.CaptionText,
            data.DisplayTime,
            data.ReadSpeed,
            index ~= #infoTable,
            function()
                coroutine.resume(thread)
            end
            )
        end)
        coroutine.yield()
    end
end

function CaptionShowcaseClient:_setControlsEnabled(state)
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

return CaptionShowcaseClient