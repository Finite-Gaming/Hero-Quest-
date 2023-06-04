---
-- @classmod PlayScreen
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local UserDataClient = require("UserDataClient")
local DungeonData = require("DungeonData")
local Network = require("Network")
local PlayScreenConstants = require("PlayScreenConstants")
local PartyServiceClient = require("PartyServiceClient")
local NotificationService = require("NotificationService")
local ExitButtonMixin = require("ExitButtonMixin")
local ConfirmationPrompt = require("ConfirmationPrompt")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PlayScreen = setmetatable({}, BaseObject)
PlayScreen.__index = PlayScreen

function PlayScreen.new(character)
    local self = setmetatable(BaseObject.new(character), PlayScreen)

    self._remoteEvent = Network:GetRemoteEvent(PlayScreenConstants.REMOTE_EVENT_NAME)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("PlayScreen"))
    self._screenGui.IgnoreGuiInset = true
    self._screenGui.Enabled = false

    self._gui = GuiTemplateProvider:Get("PlayScreenTemplate")

    self._oldContainers = {}
    self._subframe = GuiTemplateProvider:Get("PlayScreenSubframeTemplate")

    self._subframe.Visible = false
    self._subframe.Parent = self._gui

    self._currentDungeon, self._currentFloor = UserDataClient:GetNextDungeon()
    self._gui.MainFrame.ProgressLabel.Text = ("Current Progress: %s (%i)"):format(
        DungeonData[self._currentDungeon].DisplayName, self._currentFloor
    )

    self._maid:AddTask(self._subframe.Box.InviteButton.Activated:Connect(function()
        NotificationService:Notify("Processing request - InvitePlayer...")
        PartyServiceClient:InvitePlayer(self._subframe.Box.InputImage.TextBox.Text)
    end))
    self._maid:AddTask(self._subframe.StartButton.Activated:Connect(function()
        if RunService:IsStudio() then
            NotificationService:Notify("Can't start game in studio, silly goose")
            return
        end

        NotificationService:Notify("Processing request - StartGame...")
        PartyServiceClient:StartGame()
    end))
    self._maid:AddTask(self._subframe.ExitButton.Activated:Connect(function()
        self._subframe.Visible = false
    end))

    self._maid:AddTask(self._gui.MainFrame.StartButton.Activated:Connect(function()
        if self._partyCreated then
            if self._activePrompt then
                return
            end
            self._activePrompt = true

            local prompt = self._maid:AddTask(ConfirmationPrompt.new("Are you sure you want to start without your party?"))
            prompt.OnResponse:Connect(function(code)
                if code == 1 then
                    self:_teleportSolo()
                end

                self._activePrompt = false
            end)
        else
            self:_teleportSolo()
        end
    end))
    self._maid:AddTask(self._subframe.LeaveButton.Activated:Connect(function()
        NotificationService:Notify("Processing request - LeaveParty...")
        PartyServiceClient:LeaveParty()
    end))

    self._maid:AddTask(PartyServiceClient.ListUpdated:Connect(function(playerList)
        if #playerList == 0 then
            self._subframe.Visible = false
            self._partyCreated = false
            self:_updateList({Players.LocalPlayer.UserId})
        else
            self._subframe.Visible = true
            self:_updateList(playerList)
        end
    end))
    self._maid:AddTask(self._gui.MainFrame.InviteButton.Activated:Connect(function()
        if not self._partyCreated then
            PartyServiceClient:CreateParty()
            self._partyCreated = true
        else
            self._subframe.Visible = not self._subframe.Visible
        end
    end))

    ExitButtonMixin:Add(self)
    self._gui.Parent = self._screenGui

    return self
end

function PlayScreen:_teleportSolo()
    self._remoteEvent:FireServer()
    NotificationService:Notify("Teleporting, please wait...", "Information", -1)
end

function PlayScreen:_updateList(playerList)
    for _, oldContainer in ipairs(self._oldContainers) do
        oldContainer:Destroy()
    end

    for _, userId in ipairs(playerList) do
        local container = GuiTemplateProvider:Get("MemberContainerTemplate")
        self._maid:AddTask(task.spawn(function()
            local success, playerName = pcall(Players.GetNameFromUserIdAsync, Players, userId)
            if not success then
                warn("[PlayScreen] - Failed to get player name")
                playerName = ("NAME_ERROR (%i)"):format(userId)
            end
            container.NameLabel.Text = playerName
        end))
        self._maid:AddTask(task.spawn(function()
            local success, image = pcall(
                Players.GetUserThumbnailAsync,
                Players,
                userId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )

            if not success then
                warn("[PlayScreen] - Failed to get player thumbnail")
                image = "rbxassetid://12017700691"
            end
            container.ImageLabel.Image = image
        end))
        self._maid:AddTask(container.KickButton.Activated:Connect(function()
            PartyServiceClient:KickPlayer(userId)
        end))
        container:SetAttribute("UserId", userId)
        table.insert(self._oldContainers, container)
        container.Parent = self._subframe.ScrollingFrame
    end
end

return PlayScreen