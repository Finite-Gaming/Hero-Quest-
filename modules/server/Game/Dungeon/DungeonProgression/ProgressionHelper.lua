---
-- @classmod ProgressionHelper
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonData = require("DungeonData")
local PlayerLevelCalculator = require("PlayerLevelCalculator")
local SoundPlayer = require("SoundPlayer")
local StudioDebugConstants = require("StudioDebugConstants")

local RunService = game:GetService("RunService")

local ProgressionHelper = {}

function ProgressionHelper:HandlePlayerLoggedIn(player, profile)
    local dungeonTag = workspace:GetAttribute("DungeonTag")

    if not self._newPlayers then
        local playedDict = profile.Data.DungeonsPlayed
        if playedDict[dungeonTag] then
            if PlayerLevelCalculator:GetLevelFromXP(profile.XP) >= DungeonData.MaxLevel then
                self._levelMaxed = true
            end
        else
            self._newPlayers = true
        end
    end
end

function ProgressionHelper:GetVoicelineForScenario(scenario)
    local voicelineDict = DungeonData.ProgressionVoicelines[scenario]

    if self:IsNewPlayers() then
        return voicelineDict.first_time or voicelineDict.returning_def
    elseif self:IsLevelMaxed() then
        return voicelineDict.returning_max or voicelineDict.returning_def
    else
        return voicelineDict.returning_def
    end
end

function ProgressionHelper:PlaySoundForScenario(scenario, ...)
    return SoundPlayer:PlaySound(self:GetVoicelineForScenario(scenario), ...)
end

function ProgressionHelper:IsNewPlayers()
    if RunService:IsStudio() and StudioDebugConstants.SimulateRecurringPlayer then
        return false
    end
    return self._newPlayers
end

function ProgressionHelper:IsLevelMaxed()
    if RunService:IsStudio() and StudioDebugConstants.SimulateRecurringPlayer then
        return false
    end
    return not self._newPlayers and self._levelMaxed
end

return ProgressionHelper