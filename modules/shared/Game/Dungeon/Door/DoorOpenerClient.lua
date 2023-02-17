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
        self:_openDoor(door)
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
        TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Value = startCFrame * CFrame.new(0, 10, 0)}
    ))
    doorMaid:AddTask(moveTween.Completed:Connect(function()
        doorMaid:Destroy()
    end))

    moveTween:Play()
end

return DoorOpenerClient