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
local SoundPlayer = require("SoundPlayer")

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

    self._textBox = self._subframe.Box.InputImage.TextBox

    self._currentDungeon, self._currentFloor = UserDataClient:GetNextDungeon()
    self._gui.MainFrame.ProgressLabel.Text = ("Current Progress: %s (%i)"):format(
        DungeonData[self._currentDungeon].DisplayName, self._currentFloor
    )

    self._maid:AddTask(self._subframe.Box.InviteButton.Activated:Connect(function()
        NotificationService:Notify("Processing request - InvitePlayer...")
        PartyServiceClient:InvitePlayer(self._textBox.Text)
        self._textBox.Text = ""
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
            SoundPlayer:PlaySound("CreateParty")
            NotificationService:Notify("Processing request - CreateParty...")
            PartyServiceClient:CreateParty()
            self._partyCreated = true
        else
            self._subframe.Visible = not self._subframe.Visible
        end
    end))
    self._friendsPlaying = {}
    self._maid:AddTask(task.spawn(function()
        while true do
            self._friendsPlaying = PartyServiceClient:GetFriendsOnline() or {}
            self:_insertPlayers()

            task.wait(5)
        end
    end))

    self._cachedInvitees = {}
    self._visibleInvitees = {}

    self._dropdownMenu = self._subframe.Box.MenuContainer.DropdownMenu
    self._dropdownArrow = self._subframe.Box.InputImage.DropdownArrow
    self._dropdownSFrame = self._dropdownMenu.ScrollingFrame

    self._dropdownActive = false

    self._maid:AddTask(self._subframe.Box.InputImage.DropdownButton.Activated:Connect(function()
        self:_insertPlayers()

        if self._dropdownActive then
            self._dropdownArrow.Rotation = 90
            self._dropdownMenu.Visible = false
        else
            self._dropdownArrow.Rotation = 0
            self._dropdownMenu.Visible = true
        end

        self._dropdownActive = not self._dropdownActive
    end))
    self._maid:AddTask(Players.PlayerAdded:Connect(function()
        self:_insertPlayers()
    end))
    self._maid:AddTask(Players.PlayerRemoving:Connect(function()
        self:_insertPlayers()
    end))

    ExitButtonMixin:Add(self)
    self._gui.Parent = self._screenGui

    return self
end

function PlayScreen:_insertPlayers()
    local playerNames = {}
    for playerName, _ in pairs(self._friendsPlaying) do
        table.insert(playerNames, playerName)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Players.LocalPlayer then
            continue
        end

        table.insert(playerNames, player.Name)
    end
    self:_updateDropdown(playerNames)
end

function PlayScreen:_updateDropdown(playerNames)
    local sortedNames = {}
    local nameMap = {}
    for _, playerName in ipairs(playerNames) do
        nameMap[playerName] = true
    end

    for playerName, object in pairs(self._visibleInvitees) do
        if not nameMap[playerName] then
            object.Parent = nil
            self._visibleInvitees[playerName] = nil
            self._cachedInvitees[playerName] = object
        else
            nameMap[playerName] = nil
            table.insert(sortedNames, playerName)
        end
    end

    for playerName, _ in pairs(nameMap) do
        local object = self._cachedInvitees[playerName]
        if object then
            self._cachedInvitees[playerName] = nil
        else
            object = self._maid:AddTask(GuiTemplateProvider:Get("InviteeContainerTemplate"))
            task.spawn(function()
                local name = Players:GetUserIdFromNameAsync(playerName)
                self:_updateObject(object, name)
            end)

            self._maid:AddTask(object.Button.Activated:Connect(function()
                self._textBox.Text = playerName
            end))
        end

        self._visibleInvitees[playerName] = object
        table.insert(sortedNames, playerName)
    end

    table.sort(sortedNames)
    for index, playerName in pairs(sortedNames) do
        local object = self._visibleInvitees[playerName]
        object.LayoutOrder = index
        object.Parent = self._dropdownSFrame
    end
end

function PlayScreen:_teleportSolo()
    self._remoteEvent:FireServer()
    NotificationService:Notify("Teleporting, please wait...", "Information", -1)
end

function PlayScreen:_updateObject(container, userId)
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
end

function PlayScreen:_updateList(playerList)
    for _, oldContainer in ipairs(self._oldContainers) do
        oldContainer:Destroy()
    end

    for _, userId in ipairs(playerList) do
        local container = GuiTemplateProvider:Get("MemberContainerTemplate")

        self:_updateObject(container, userId)
        self._maid:AddTask(container.KickButton.Activated:Connect(function()
            PartyServiceClient:KickPlayer(userId)
        end))
        container:SetAttribute("UserId", userId)
        table.insert(self._oldContainers, container)
        container.Parent = self._subframe.ScrollingFrame
    end
end

return PlayScreen