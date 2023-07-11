---
-- @classmod StoryQuestData
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataService = require("UserDataService")
local ActionHistory = require("ActionHistory")
local PlayerLevelCalculator = require("PlayerLevelCalculator")
local TableUtils = require("TableUtils")
local QuestUpdater = require("QuestUpdater")
local GameUUID = require("GameUUID")

local difficultyBases = {
    easy = 50;
    medium = 150;
    hard = 300;
}

local function reward(player, difficulty)
    local baseValue = difficultyBases[difficulty]
    local playerLevel = PlayerLevelCalculator:GetLevelFromXP(UserDataService:GetExperience(player))
    local rewardValue = math.round(baseValue * math.clamp(playerLevel/10, 1, 10))
    require("UserData"):GiveSpecialReward(player.UserId, {
        PromptReward = true;
        RewardHeader = ("%s%s quest completed"):format(difficulty:sub(1, 1):upper(), difficulty:sub(2));

        Money = rewardValue;
        XP = math.round(rewardValue * 1.3);
    })
end

local function incrementFunction(func)
    return function(self, player, ...)
        if self.InvalidationId == GameUUID:Get() then
            return
        end
        if self.CompletedTime then
            return
        end

        func(self, player, ...)
        QuestUpdater:Update(player)
    end
end

local function verifyTags(player, deathData, ...)
    local playerTags = deathData.DamageTags[player]
    if not playerTags then
        return
    end

    for _, damageTag in ipairs({...}) do
        if not playerTags[damageTag] then
            return false
        end
    end

    return true
end

local questData = {
    ["Warrior"] = {
        easy = {
            DisplayText = "Defeat %i mobs with %s.";
            Variables = {
                [1] = {
                    Goal = 15;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player)
                        local data = self.Variables[1].Data
                        local equippedWeapon = UserDataService:GetEquipped(player, "Weapon")
                        if equippedWeapon ~= self.Variables[2].Data then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal then
                            reward(player, "easy")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "RANDOM_WEAPON";
                };
            };
        };
        medium = {
            DisplayText = "Defeat %s %i times with %s, and use %s at least once without dying more than %i times.";
            Variables = {
                [1] = {
                    Data = "FLOOR_BOSS";
                };
                [2] = {
                    Goal = 2;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[2].Data
                        if deathData.Name ~= self.Variables[1].Data then
                            return
                        end

                        local equippedWeapon = UserDataService:GetEquipped(player, "Weapon")
                        if equippedWeapon ~= self.Variables[3].Data then
                            return
                        end
                        verifyTags(player, deathData, self.Variables[3].Data)

                        local newData = data + 1
                        if newData == self.Variables[2].Goal then
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
                [3] = {
                    Data = "RANDOM_WEAPON";
                };
                [4] = {
                    Data = "RANDOM_ABILITY";
                };
                [5] = {
                    Data = 5;
                };
            };
        };
        hard = {
            DisplayText = "Clear %s in under %i minutes using only %s and no abilities solo and under %i deaths.";
            Variables = {
                [1] = {
                    Data = "CURRENT_DUNGEON";
                };
                [2] = {
                    Data = "QUARTER_DUNGEON_TIME";
                };
                [3] = {
                    Data = "RANDOM_WEAPON";
                };
                [4] = {
                    Data = 3;
                    IgnoreNum = true;
                };
                [5] = {
                    Goal = 1;
                    Data = 0;
                }
            };
            Checks = {
                [1] = {
                    CheckType = "DungeonBeaten";
                    Check = incrementFunction(function(self, player, finalData)
                        if finalData.TimeTaken < self.Variables[2].Data * 60 then
                            return
                        end
                        if not ActionHistory:IsSoloWeapon(player, self.Variables[3]) then
                            return
                        end
                        if player:GetAttribute("AbilityUsed") then
                            return
                        end
                        if player:GetAttribute("Deaths") > self.Variables[4].Data then
                            return
                        end

                        reward(player, "hard")
                        self.CompletedTime = os.time()
                    end);
                };
            };
        };
    };
    ["Tank"] = {
        easy = {
            DisplayText = "Take a total of %i damage from %s using %s.";
            Variables = {
                [1] = {
                    Goal = 250;
                    Data = 0;
                    IncrementType = "DamageTaken";
                    Increment = incrementFunction(function(self, player, damage, damageTag)
                        local data = self.Variables[1].Data
                        if damageTag ~= self.Variables[2].Data then
                            return
                        end

                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[3].Data then
                            return
                        end

                        local goal = self.Variables[1].Goal
                        local newData = math.clamp(data + damage, 0, goal)
                        if newData == goal then
                            reward(player, "easy")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "FLOOR_BOSS";
                };
                [3] = {
                    Data = "RANDOM_HELMET";
                };
            };
        };
        medium = {
            DisplayText = "Take a total of %i damage from %s using %s and %s without using abilities or dying more than %i times.";
            Variables = {
                [1] = {
                    Goal = 500;
                    Data = 0;
                    IncrementType = "DamageTaken";
                    Increment = incrementFunction(function(self, player, damage, damageTag)
                        local data = self.Variables[1].Data
                        if damageTag ~= self.Variables[2].Data then
                            warn("tank|m|1| not incrementing, damage tag does not match")
                            return
                        end

                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[3].Data then
                            warn("tank|m|1| not incrementing, armor does not match")
                            return
                        end

                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[4].Data then
                            warn("tank|m|1| not incrementing, helmet does not match")
                            return
                        end

                        local goal = self.Variables[1].Goal
                        local newData = math.clamp(data + damage, 0, goal)
                        if newData == goal then
                            warn("tank|m|1| incremented!")
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "FLOOR_BOSS";
                };
                [3] = {
                    Data = "RANDOM_ARMOR";
                };
                [4] = {
                    Data = "RANDOM_HELMET";
                };
                [5] = {
                    Data = 5;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerLeaving";
                    Check = incrementFunction(function(self)
                        warn("tank|m|c| invalidated, player left")
                        self.Variables[1].Data = 0
                    end)
                };
                [2] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[5].Data then
                            warn("tank|m|c| invalidated, deaths over 5")
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end)
                };
                [3] = {
                    CheckType = "AbilityUsed";
                    Check = incrementFunction(function(self)
                        warn("tank|m|c| invalidated, ability used")
                        self.InvalidationId = GameUUID:Get()
                        self.Variables[1].Data = 0
                    end)
                };
            };
        };
        hard = {
            DisplayText = "Take a total of %i damage from enemies using %s and %s without using abilities or dying more than %i times.";
            Variables = {
                [1] = {
                    Goal = 1000;
                    Data = 0;
                    IncrementType = "DamageTaken";
                    Increment = incrementFunction(function(self, player, damage)
                        local data = self.Variables[1].Data

                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[3].Data then
                            return
                        end

                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[4].Data then
                            return
                        end

                        local goal = self.Variables[1].Goal
                        local newData = math.clamp(data + damage, 0, goal)
                        if newData == goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "RANDOM_ARMOR";
                };
                [3] = {
                    Data = "RANDOM_HELMET";
                };
                [4] = {
                    Data = 5;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerLeaving";
                    Check = incrementFunction(function(self)
                        self.Variables[1].Data = 0
                    end)
                };
                [2] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self)
                        self.InvalidationId = GameUUID:Get()
                        self.Variables[1].Data = 0
                    end)
                };
                [3] = {
                    CheckType = "AbilityUsed";
                    Check = incrementFunction(function(self)
                        self.InvalidationId = GameUUID:Get()
                        self.Variables[1].Data = 0
                    end)
                };
            };
        };
    };
    ["Wizard"] = {
        easy = {
            DisplayText = "Use %s %i times.";
            Variables = {
                [1] = {
                    Data = "RANDOM_ABILITY";
                };
                [2] = {
                    Goal = 5;
                    Data = 0;
                    IncrementType = "AbilityUsed";
                    Increment = incrementFunction(function(self, player, abilityName)
                        local data = self.Variables[2].Data
                        if abilityName ~= self.Variables[1].Data then
                            warn("not incrementing: 1:1")
                            return
                        end

                        warn("incrementing 1")
                        local newData = data + 1
                        if newData == self.Variables[2].Goal then
                            reward(player, "easy")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
            };
        };
        medium = {
            DisplayText = "Defeat %i mobs and %i %s with %s without using other weapons or dying %i times.";
            Variables = {
                [1] = {
                    Goal = 7;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        if data == self.Variables[1].Goal then
                            return
                        end

                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if abilityUsed and TableUtils.count(playerTags) ~= 1 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal and self.Variables[2].Data == self.Variables[2].Goal then
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Goal = 1;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[2].Data
                        if data == self.Variables[2].Goal then
                            return
                        end

                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if abilityUsed and TableUtils.count(playerTags) ~= 1 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[2].Goal and self.Variables[1].Data == self.Variables[1].Goal then
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
                [3] = {
                    Data = "FLOOR_BOSS";
                };
                [4] = {
                    Data = "RANDOM_ABILITY";
                };
                [5] = {
                    Data = 5;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[3].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end)
                };
            };
        };
        hard = {
            DisplayText = "Defeat %i mobs and %i %s's with %s without using other weapons or dying %i times.";
            Variables = {
                [1] = {
                    Goal = 7;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        if data == self.Variables[1].Goal then
                            return
                        end

                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if TableUtils.count(playerTags) ~= 1 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal and self.Variables[2].Data == self.Variables[2].Goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Goal = 2;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[2].Data
                        if data == self.Variables[2].Goal then
                            return
                        end

                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if TableUtils.count(playerTags) ~= 1 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[2].Goal and self.Variables[1].Data == self.Variables[1].Goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
                [3] = {
                    Data = "FLOOR_BOSS";
                };
                [4] = {
                    Data = "RANDOM_ABILITY";
                };
                [5] = {
                    Data = 3;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[3].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end)
                };
            };
        };
    };
    ["Battle Wizard"] = {
        easy = {
            DisplayText = "Defeat %i mobs using %s and %s.";
            Variables = {
                [1] = {
                    Goal = 5;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        local playerTags = deathData.DamageTags[player]
                        print(playerTags)
                        if not playerTags then
                            warn("not incrementing, no player tag")
                            return
                        end

                        local weaponUsed = playerTags[self.Variables[2].Data]
                        if not weaponUsed then
                            warn("not incrementing, weapon not used")
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[3].Data]
                        if not abilityUsed then
                            warn("not incrementing, ability not used")
                            return
                        end

                        local newData = data + 1
                        warn("incrementing, new data:", newData)
                        if newData == self.Variables[1].Goal then
                            reward(player, "easy")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "RANDOM_WEAPON";
                };
                [3] = {
                    Data = "RANDOM_ABILITY";
                };
            };
        };
        medium = {
            DisplayText = "Defeat %i %s's only using %s and %s without dying more than %i times.";
            Variables = {
                [1] = {
                    Goal = 2;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end

                        if deathData.Name ~= self.Variables[2].Data then
                            return
                        end

                        local weaponUsed = playerTags[self.Variables[3].Data]
                        if not weaponUsed then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if TableUtils.count(playerTags) ~= 2 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal then
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "FLOOR_BOSS";
                };
                [3] = {
                    Data = "RANDOM_WEAPON";
                };
                [4] = {
                    Data = "RANDOM_ABILITY";
                };
                [5] = {
                    Data = 3;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[5].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end);
                };
            };
        };
        hard = {
            DisplayText = "Defeat %i mobs and %i %s's only using %s and %s without dying more than %i time.";
            Variables = {
                [1] = {
                    Goal = 5;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        if data == self.Variables[1].Goal then
                            return
                        end

                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end

                        if deathData.Name == self.Variables[2].Data then
                            return
                        end

                        local weaponUsed = playerTags[self.Variables[3].Data]
                        if not weaponUsed then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if TableUtils.count(playerTags) ~= 2 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal and self.Variables[2].Data == self.Variables[2].Goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Goal = 3;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[2].Data
                        if data == self.Variables[2].Goal then
                            return
                        end

                        local playerTags = deathData.DamageTags[player]
                        if not playerTags then
                            return
                        end

                        if deathData.Name ~= self.Variables[2].Data then
                            return
                        end

                        local weaponUsed = playerTags[self.Variables[3].Data]
                        if not weaponUsed then
                            return
                        end
                        local abilityUsed = playerTags[self.Variables[4].Data]
                        if not abilityUsed then
                            return
                        end
                        if TableUtils.count(playerTags) ~= 2 then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[2].Goal and self.Variables[1].Data == self.Variables[1].Goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
                [3] = {
                    Data = "FLOOR_BOSS";
                };
                [4] = {
                    Data = "RANDOM_WEAPON";
                };
                [5] = {
                    Data = "RANDOM_ABILITY";
                };
                [6] = {
                    Data = 1;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[6].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end);
                };
            };
        };
    };
    ["Juggernaut"] = {
        easy = {
            DisplayText = "Defeat %i mobs using %s and %s.";
            Variables = {
                [1] = {
                    Goal = 5;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data

                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[2].Data then
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[3].Data then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal then
                            reward(player, "easy")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "RANDOM_ARMOR";
                };
                [3] = {
                    Data = "RANDOM_HELMET";
                };
            };
        };
        medium = {
            DisplayText = "Defeat %i %s using %s and %s without dying more than %i times.";
            Variables = {
                [1] = {
                    Goal = 1;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data

                        if deathData.Name ~= self.Variables[2].Data then
                            return
                        end

                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[3].Data then
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[4].Data then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal then
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "FLOOR_BOSS";
                };
                [3] = {
                    Data = "RANDOM_ARMOR";
                };
                [4] = {
                    Data = "RANDOM_HELMET";
                };
                [5] = {
                    Data = 3;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[5].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end);
                };
            };
        };
        hard = {
            DisplayText = "Defeat %i mobs and %i %s's using %s and %s without dying more than %i time.";
            Variables = {
                [1] = {
                    Goal = 5;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        if data == self.Variables[1].Goal then
                            return
                        end

                        if deathData.Name == self.Variables[3].Data then
                            warn("juggernaut|h|1| not incrementing, is warden")
                            return
                        end

                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[4].Data then
                            warn("juggernaut|h|1| not incrementing, armor doesnt match")
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[5].Data then
                            warn("juggernaut|h|1| not incrementing, helmet doesnt match")
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal and self.Variables[2].Data == self.Variables[2].Goal then
                            warn("juggernaut|h|1| quest complete")
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Goal = 2;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[2].Data
                        if data == self.Variables[2].Goal then
                            return
                        end

                        if deathData.Name ~= self.Variables[3].Data then
                            warn("juggernaut|h|2| not incrementing, isnt warden")
                            return
                        end

                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[4].Data then
                            warn("juggernaut|h|2| not incrementing, armor doesnt match")
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[5].Data then
                            warn("juggernaut|h|2| not incrementing, helmet doesnt match")
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[2].Goal and self.Variables[1].Data == self.Variables[1].Goal then
                            warn("juggernaut|h|2| quest complete")
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
                [3] = {
                    Data = "FLOOR_BOSS";
                };
                [4] = {
                    Data = "RANDOM_ARMOR";
                };
                [5] = {
                    Data = "RANDOM_HELMET";
                };
                [6] = {
                    Data = 1;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[6].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end);
                };
            };
        };
    };
    ["Hefty Wizard"] = {
        easy = {
            DisplayText = "Defeat %i mobs using %s and %s.";
            Variables = {
                [1] = {
                    Goal = 3;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data

                        local equippedAbility = UserDataService:GetEquipped(player, "Ability")
                        if equippedAbility ~= self.Variables[2].Data then
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[3].Data then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal then
                            reward(player, "easy")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "RANDOM_ABILITY";
                };
                [3] = {
                    Data = "RANDOM_HELMET";
                };
            };
        };
        medium = {
            DisplayText = "Defeat %i %s's using %s, %s and %s without dying more than %i times.";
            Variables = {
                [1] = {
                    Goal = 2;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data

                        if deathData.Name ~= self.Variables[2].Data then
                            return
                        end

                        local equippedAbility = UserDataService:GetEquipped(player, "Ability")
                        if equippedAbility ~= self.Variables[3].Data then
                            return
                        end
                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[4].Data then
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[5].Data then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[1].Goal then
                            reward(player, "medium")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Data = "FLOOR_BOSS";
                };
                [3] = {
                    Data = "RANDOM_ABILITY";
                };
                [4] = {
                    Data = "RANDOM_ARMOR";
                };
                [5] = {
                    Data = "RANDOM_HELMET";
                };
                [6] = {
                    Data = 3;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[6].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end);
                };
            };
        };
        hard = {
            DisplayText = "Defeat %i mobs and %i %s's using %s, %s and %s without dying more than %i time.";
            Variables = {
                [1] = {
                    Goal = 5;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[1].Data
                        if data == self.Variables[1].Goal then
                            return
                        end

                        if deathData.Name == self.Variables[3].Data then
                            print("is warden, not incrementing")
                            return
                        end

                        local equippedAbility = UserDataService:GetEquipped(player, "Ability")
                        if equippedAbility ~= self.Variables[4].Data then
                            print("ability doesnt match")
                            return
                        end
                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[5].Data then
                            print("armor doesnt match")
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[6].Data then
                            print("helmet doesnt match")
                            return
                        end

                        local newData = data + 1
                        print("incrementing, new data:", newData)
                        if newData == self.Variables[1].Goal and self.Variables[2].Data == self.Variables[2].Goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[1].Data = newData
                    end);
                };
                [2] = {
                    Goal = 2;
                    Data = 0;
                    IncrementType = "NPCDeath";
                    Increment = incrementFunction(function(self, player, deathData)
                        local data = self.Variables[2].Data
                        if data == self.Variables[2].Goal then
                            return
                        end

                        if deathData.Name ~= self.Variables[3].Data then
                            return
                        end

                        local equippedAbility = UserDataService:GetEquipped(player, "Ability")
                        if equippedAbility ~= self.Variables[4].Data then
                            return
                        end
                        local equippedArmor = UserDataService:GetEquipped(player, "Armor")
                        if equippedArmor ~= self.Variables[5].Data then
                            return
                        end
                        local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
                        if equippedHelmet ~= self.Variables[6].Data then
                            return
                        end

                        local newData = data + 1
                        if newData == self.Variables[2].Goal and self.Variables[1].Data == self.Variables[1].Goal then
                            reward(player, "hard")
                            self.CompletedTime = os.time()
                        end

                        self.Variables[2].Data = newData
                    end);
                };
                [3] = {
                    Data = "FLOOR_BOSS";
                };
                [4] = {
                    Data = "RANDOM_ABILITY";
                };
                [5] = {
                    Data = "RANDOM_ARMOR";
                };
                [6] = {
                    Data = "RANDOM_HELMET";
                };
                [7] = {
                    Data = 1;
                };
            };
            Checks = {
                [1] = {
                    CheckType = "PlayerDeath";
                    Check = incrementFunction(function(self, player)
                        if player:GetAttribute("Deaths") > self.Variables[6].Data then
                            self.InvalidationId = GameUUID:Get()
                            self.Variables[1].Data = 0
                        end
                    end);
                };
            };
        };
    };
}

for classAlignment, quests in pairs(questData) do
    for difficulty, quest in pairs(quests) do
        quest.DataPath = ("%s|%s"):format(classAlignment, difficulty)
        quest.Difficulty = difficulty
    end
end

return questData