---
-- @classmod DoorOpenerClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TweenService = game:GetService("TweenService")

local Network = require("Network")
local DoorOpenerConstants = require("DoorOpenerConstants")
local Maid = require("Maid")

local DoorOpenerClient = {}

function DoorOpenerClient:Init()
    Network:GetRemoteEvent(DoorOpenerConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(door)
        if door:IsA("Folder") then
            for _, doorChild in ipairs(door:GetChildren()) do
                self:_openDoor(doorChild)
            end
        else
            self:_openDoor(door)
        end
    end)
end

function DoorOpenerClient:_openDoor(door)
    local doorMaid = Maid.new()
    local startCFrame = door.PrimaryPart.CFrame

    local cframeValue = doorMaid:AddTask(Instance.new("CFrameValue"))
    cframeValue.Value = startCFrame

    doorMaid:AddTask(cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
        door:PivotTo(cframeValue.Value)
    end))

    local moveTween = doorMaid:AddTask(TweenService:Create(
        cframeValue,
        TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Value = startCFrame + Vector3.new(0, -(door:GetAttribute("OpenDepth") or door.PrimaryPart.Size.Y), 0)}
    ))
    doorMaid:AddTask(moveTween.Completed:Connect(function()
        doorMaid:Destroy()
    end))

    local toggleSound = door.PrimaryPart:FindFirstChild("Toggle")
    if toggleSound then
        toggleSound:Play()
    end
    moveTween:Play()
end

return DoorOpenerClient