---
-- @classmod InviteClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GuiTemplateProvider = require("GuiTemplateProvider")
local ScreenGuiProvider = require("ScreenGuiProvider")
local Network = require("Network")
local PartyServiceConstants = require("PartyServiceConstants")
local Maid = require("Maid")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local VISIBLE_POSITION = UDim2.new(0, 40, 0.6, 0)
local NOT_VISIBLE_POSITION = UDim2.new(-0.4, 0, 0.6, 0)

local SHOW_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HIDE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local InviteClient = {}

function InviteClient:Init()
    self._remoteEvent = Network:GetRemoteEvent(PartyServiceConstants.REMOTE_EVENT_NAME)
    self._screenGui = ScreenGuiProvider:Get("Invites")
end

function InviteClient:DisplayInvite(inviteData)
    local maid = Maid.new()
    local inviteFrame = GuiTemplateProvider:Get("InviteFrameTemplate")
    local showTween = maid:AddTask(
        TweenService:Create(inviteFrame, SHOW_TWEEN_INFO, {Position = VISIBLE_POSITION})
    )
    local hideTween = maid:AddTask(
        TweenService:Create(inviteFrame, HIDE_TWEEN_INFO, {Position = NOT_VISIBLE_POSITION})
    )

    inviteFrame.Position = NOT_VISIBLE_POSITION

    maid:AddTask(task.spawn(function()
        inviteFrame.HeadShot.Image = Players:GetUserThumbnailAsync(
            inviteData.FromPlayer,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end))
    maid:AddTask(task.spawn(function()
        local success, playerName = pcall(Players.GetNameFromUserIdAsync, Players, inviteData.FromPlayer)
        if not success then
            warn("[InviteClient] - Failed to get player name")
            playerName = ("NAME_ERROR (%i)"):format(inviteData.FromPlayer)
        end

        inviteFrame.TextLabel.Text = ("%s has invited you to their party.")
            :format(playerName)
    end))
    maid:AddTask(RunService.Heartbeat:Connect(function()
        local timeRemaining = inviteData.ExpiresAt - workspace:GetServerTimeNow()
        local percent = math.clamp(timeRemaining/PartyServiceConstants.INVITE_EXPIRATION_TIME, 0, 1)
        inviteFrame.ProgressBar.AccentBar.Size = UDim2.fromScale(percent, 1)
    end))
    maid:AddTask(hideTween.Completed:Connect(function()
        inviteFrame:Destroy()
    end))
    maid:AddTask(function()
        hideTween:Play()
    end)

    maid:AddTask(inviteFrame.AcceptButton.Activated:Connect(function()
        self._remoteEvent:FireServer("AcceptInvite", {GUID = inviteData.GUID})
        maid:Destroy()
    end))
    maid:AddTask(inviteFrame.DenyButton.Activated:Connect(function()
        maid:Destroy()
    end))
    maid:AddTask(inviteFrame.ExitButton.Activated:Connect(function()
        maid:Destroy()
    end))

    inviteFrame.Parent = self._screenGui
    showTween:Play()
end

return InviteClient