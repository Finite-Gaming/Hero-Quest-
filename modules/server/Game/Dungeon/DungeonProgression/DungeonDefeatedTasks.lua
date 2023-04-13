---
-- @classmod DungeonDefeatedTasks
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local EffectPlayerService = require("EffectPlayerService")
local UserData = require("UserData")

local Players = game:GetService("Players")

local DungeonDefeatedTasks = {}

function DungeonDefeatedTasks:Run()
    local dungeonTag = workspace:GetAttribute("DungeonTag")
    -- edit data prior to teleporting for consistency
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = UserData:GetProfile(player.UserId) -- should realistically be cached by now, if not, funky things happened
        if not profile then
            warn(("[DungeonDefeatedTasks] - Unable to get profile for %q"):format(player.Name))
            continue
        end

        local completedDict = profile.Data.DungeonsCompleted
        if completedDict[dungeonTag] then
            completedDict[dungeonTag] += 1
        else
            completedDict[dungeonTag] = 1
        end
    end

    -- play animation, wait for few secs, teleport
    for _, player in ipairs(Players:GetPlayers()) do
        EffectPlayerService:PlayCustom("PlayerTeleportAnimation", "exit", player)
    end
end

return DungeonDefeatedTasks