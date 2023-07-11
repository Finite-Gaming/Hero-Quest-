---
-- @classmod QuestDataUtil
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserData = require("UserData")
local PlayerLevelCalculator = require("PlayerLevelCalculator")
local DailyQuestData = require("DailyQuestData")

local QuestDataUtil = {}

function QuestDataUtil.unpackVariables(questData)
    local variables = {}

    for _, quest in pairs(questData) do
        for _, variable in ipairs(quest.Variables) do
            table.insert(variables, variable)
        end
    end
    return variables
end

local function createIFunc(tag)
    return function(player, incrementType, ...)
        local playerData = UserData:WaitForProfile(player.UserId).Data
        local questData = playerData.QuestData
        if not questData then
            return
        end
        for _, userQuest in pairs(questData) do
            local dataPath = userQuest.DataPath:split("|")
            local alignment, difficulty = unpack(dataPath)
            local quest = DailyQuestData[alignment][difficulty]
            for _, variable in ipairs(quest[((tag == "Check" and "Checks") or "Variables")] or {}) do
                if variable[("%sType"):format(tag)] == incrementType and variable[tag] then
                    variable[tag](userQuest, player, ...)
                end
            end
        end
    end
end

QuestDataUtil.increment = createIFunc("Increment")
QuestDataUtil.check = createIFunc("Check")

return QuestDataUtil