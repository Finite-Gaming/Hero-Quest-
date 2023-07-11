---
-- @classmod QuestUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ExitButtonMixin = require("ExitButtonMixin")
local UserDataClient = require("UserDataClient")
local Network = require("Network")
local QuestUpdaterConstants = require("QuestUpdaterConstants")

local DIFFICULTY_MAP = { -- TODO: constants file
    "easy";
    "medium";
    "hard";
}
local REWARD_MAP = {
    easy = 50;
    medium = 150;
    hard = 300;
}

local QuestUI = setmetatable({}, BaseObject)
QuestUI.__index = QuestUI

function QuestUI.new(character)
    local self = setmetatable(BaseObject.new(character), QuestUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("QuestUI"))
    self._gui = GuiTemplateProvider:Get("QuestUITemplate")

    ExitButtonMixin:Add(self)
    self._maid:AddTask(self.EnabledChanged:Connect(function(enabled)
        if enabled then
            self:_updateEntries(self._questData)
        end
    end))

    self._screenGui.Enabled = false

    self._entries = {}
    self:_initEntries()

    self._questData = UserDataClient:GetQuestData()
    self:_updateEntries(self._questData)

    self._maid:AddTask(Network:GetRemoteEvent(QuestUpdaterConstants.REMOTE_EVENT_NAME).OnClientEvent:Connect(function(questData)
        self._questData = questData

        if not self:IsEnabled() then
            return
        end

        self:_updateEntries(questData)
    end))

    self._gui.Parent = self._screenGui

    return self
end

function QuestUI:_initEntries()
    for index, difficulty in ipairs(DIFFICULTY_MAP) do
        local questEntry = GuiTemplateProvider:Get("QuestEntryTemplate")

        questEntry.DifficultyBacking.DifficultyLabel.Text =
            ("%s%s"):format(difficulty:sub(1, 1):upper(), difficulty:sub(2))
        questEntry.LayoutOrder = index
        questEntry.Parent = self._gui.MainFrame.ScrollingFrame
        self._entries[difficulty] = questEntry
    end
end

function QuestUI:_updateEntries(questData)
    for difficulty, quest in pairs(questData) do
        local questEntry = self._entries[difficulty]
        local totalGoal = 0
        local totalData = 0
        local varTable = {}

        for index, variable in ipairs(quest.Variables) do
            local data, goal = variable.Data, variable.Goal
            if data and goal and not variable.IgnoreNum then
                if type(data) == "number" then
                    totalData += data
                end
                if type(goal) == "number" then
                    totalGoal += goal
                end
            end

            varTable[index] = goal or data
        end

        questEntry.RewardBacking.RewardLabel.Text = ("%i gold"):format(REWARD_MAP[difficulty])
        questEntry.TaskBacking.TextLabel.Text = ("%s (DEBUG CODE: %s)"):format(
            quest.DisplayText:format(unpack(varTable)),
            quest.DataPath
        )

        local percentComplete = math.clamp(totalData/totalGoal, 0, 1)
        questEntry.ProgressBar.TextLabel.Text = ("%s%%"):format(math.round(100 * percentComplete))
        questEntry.ProgressBar.AccentBar.Size = UDim2.fromScale(percentComplete, 1)
    end
end

return QuestUI