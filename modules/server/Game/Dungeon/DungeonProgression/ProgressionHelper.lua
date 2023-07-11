---
-- @classmod ProgressionHelper
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local DungeonData = require("DungeonData")
local PlayerLevelCalculator = require("PlayerLevelCalculator")
local SoundPlayer = require("SoundPlayer")
local StudioDebugConstants = require("StudioDebugConstants")
local GameManager = require("GameManager")
local FunctionUtils = require("FunctionUtils")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")

local PLAYER_JOIN_TIMEOUT = 10

local TELEPORT_DATA_FORMAT = "TELEPORT_DATA_%s" -- TODO: move this to a constants file to sync with PartyService

local ProgressionHelper = {}

function ProgressionHelper:Init()
    if GameManager:IsDungeon() then
        self._dungeonTag = workspace:GetAttribute("DungeonTag")
        -- TODO: maybe change this to a repeat async call?
        self._teleportDataMap = MemoryStoreService:GetSortedMap("TeleportData_TEST_10")
        self._teleportData = FunctionUtils.rCallAPIAsync(self._teleportDataMap, "GetAsync",
            TELEPORT_DATA_FORMAT:format(game.PrivateServerId))

        if not self._teleportData then
            self._allPlayersJoined = true
        end
    else
        self._firstTimers = {}
    end
end

function ProgressionHelper:IsFirstTimer(player)
    return self._firstTimers[player] and true or false
end

function ProgressionHelper:HandlePlayerLoggedIn(player, profile)
    if GameManager:IsDungeon() then
        if not self._newPlayers then
            local playedDict = profile.Data.DungeonsPlayed
            if playedDict[self._dungeonTag] then
                if PlayerLevelCalculator:GetLevelFromXP(profile.Data.XP) >= DungeonData[self._dungeonTag].PlayIndex * 15 then
                    self._levelMaxed = true
                end
            else
                self._newPlayers = true
            end
        end

        local playedDict = profile.Data.DungeonsPlayed
        if playedDict[self._dungeonTag] then
            playedDict[self._dungeonTag] += 1
        else
            playedDict[self._dungeonTag] = 1
        end
    else
        if profile.Data.PlayCount == 1 then
            self._firstTimers[player] = true
        end
    end
end

function ProgressionHelper:WaitForAllPlayers()
    if self._allPlayersJoined then
        return
    end

    while not self._teleportData and not self._allPlayersJoined do
        task.wait()
    end

    local currentThread = coroutine.running()

    local startTime = os.clock()
    task.spawn(function()
        while not self._allPlayersJoined and
            os.clock() - startTime <= PLAYER_JOIN_TIMEOUT and
            #Players:GetPlayers() < #self._teleportData.PlayerList
        do
            task.wait()
        end

        self._allPlayersJoined = true
        coroutine.resume(currentThread)
    end)

    return coroutine.yield()
end

function ProgressionHelper:GetVoicelineForScenario(scenario)
    local voicelineDict = DungeonData[self._dungeonTag].ProgressionVoicelines[scenario]

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
    if RunService:IsStudio() and StudioDebugConstants.SimulateNewPlayer then
        return true
    end
    return self._newPlayers
end

function ProgressionHelper:IsLevelMaxed()
    if RunService:IsStudio() and StudioDebugConstants.SimulateNewPlayer then
        return false
    end
    return not self._newPlayers and self._levelMaxed
end

return ProgressionHelper