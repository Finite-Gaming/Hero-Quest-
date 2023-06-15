---
-- @classmod PartyService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local PartyServiceConstants = require("PartyServiceConstants")
local UserDataService = require("UserDataService")
local DungeonData = require("DungeonData")
local FunctionUtils = require("FunctionUtils")

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

local SEVEN_DAYS_IN_SECONDS = 7 * 60 * 60 * 24

local USER_ID_FORMAT = "USER_%i"
local SERVER_SUBSCRIPTION_FORMAT = "PARTIES_SERVER_%s"
local PARTY_ID_FORMAT = "PARTY_%s"
local TELEPORT_DATA_FORMAT = "TELEPORT_DATA_%s"

local INVITE_COOLDOWN = 3

local PartyService = {}

function PartyService:Init()
    self._playerMap = MemoryStoreService:GetSortedMap("ActivePlayers_TEST_10")
    self._partyMap = MemoryStoreService:GetSortedMap("ActiveParties_TEST_10")
    self._teleportDataMap = MemoryStoreService:GetSortedMap("TeleportData_TEST_10")

    self._remoteEvent = Network:GetRemoteEvent(PartyServiceConstants.REMOTE_EVENT_NAME)
    self._remoteFunction = Network:GetRemoteFunction(PartyServiceConstants.REMOTE_FUNCTION_NAME)

    self._partyOwners = {}
    self._partyMembers = {}
    self._activeInvites = {}

    self._inviteCooldownMap = {}

    FunctionUtils.rCallAPIAsync(MessagingService, "SubscribeAsync", SERVER_SUBSCRIPTION_FORMAT:format(game.JobId), function(data)
        print(("[PartyService] - Inbound message from MessagingService Latency: %f | Action: %s | Full table contents:")
            :format(data.Sent - os.time(), data.Data.Action))
        for key, value in pairs(data.Data) do
            print(key, "=", value)
        end

        data = data.Data
        local action, fromServer = data.Action, data.ServerId

        if action == "Invite" then
            print("[PartyService] - MessagingService: Handling Invite action:")

            local player = Players:GetPlayerByUserId(data.ToPlayer)
            if not player then
                warn("[PartyService] - MessagingService: Invite action  error, no player in-game")

                MessagingService:PublishAsync(fromServer, {
                    Action = "Notification";
                    Type = "Error";
                    ServerId = game.JobId;
                    FromPlayer = data.FromPlayer;
                })
            else
                print("[PartyService] - MessagingService: Found player in-game successfully")

                local inviteGUID = HttpService:GenerateGUID(false)
                local inviteTable = {
                    ExpiresAt = workspace:GetServerTimeNow() + PartyServiceConstants.INVITE_EXPIRATION_TIME;
                    GUID = inviteGUID;
                    PartyGUID = data.PartyGUID;
                    FromPlayer = data.FromPlayer;
                    ToPlayer = data.ToPlayer
                }
                self._activeInvites[inviteGUID] = inviteTable
                self._remoteEvent:FireClient(player, "Invite", inviteTable)
            end
        elseif action == "Notification" then
            self:_fireClientByUserId(data.ToPlayer, "Notification", data.Reason, data.Type, data.Lifetime)
        elseif action == "UpdateList" then
            self:_fireClientByUserId(data.ToPlayer, "UpdateList", data.PlayerList)
        elseif action == "Teleport" then
            local player = Players:GetPlayerByUserId(data.ToPlayer)
            self._remoteEvent:FireClient(player, "Notification", "Starting game, please wait...", "Information", -1)

            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ReservedServerAccessCode = data.AccessCode
            TeleportService:TeleportAsync(data.DungeonId,
                {player},
            teleportOptions)
        end
    end)

    self._remoteEvent.OnServerEvent:Connect(function(player, action, data)
        if action == "Invite" then
            local lastSendTime = self._inviteCooldownMap[player] or 0
            local currentSendTime = os.clock()
            local timeDiff = currentSendTime - lastSendTime
            if timeDiff < INVITE_COOLDOWN then
                local displayTime = math.ceil(INVITE_COOLDOWN - timeDiff)
                self._remoteEvent:FireClient(player, "Notification", ("Inviting too fast, please wait %i second%s")
                    :format(displayTime, displayTime == 1 and "" or "s"), "Error")
                return
            end
            self._inviteCooldownMap[player] = currentSendTime
        end

        print(("[PartyService] - Inbound event from RemoteEvent | Action: %s")
            :format(action))
        if data then
            print("Data: ", data)
        end

        local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(player.UserId))
        if not playerData then
            warn("[PartyService] - Failed to get playerData")
            self._remoteEvent:FireClient(player, "Notification", "Failed to get playerData", "Error")
            return
        end

        if action == "CreateParty" then
            if playerData.PartyGUID then
                warn("[PartyService] - Did not create party, player is already in a party")
                self._remoteEvent:FireClient(player, "Notification", "Failed to create party, index found in partyMembers", "Error")
                return
            end
            local partyGUID = HttpService:GenerateGUID(false)

            FunctionUtils.rCallAPI(self._partyMap, "SetAsync", PARTY_ID_FORMAT:format(partyGUID), {
                ServerId = game.JobId;
                Owner = player.UserId;
                Players = {player.UserId};
            }, SEVEN_DAYS_IN_SECONDS)
            warn("[PartyService] - Updating playerData...")
            FunctionUtils.rCallAPI(self._playerMap, "UpdateAsync", USER_ID_FORMAT:format(player.UserId), function(playerData)
                playerData.PartyGUID = partyGUID
                return playerData
            end, SEVEN_DAYS_IN_SECONDS)

            self._remoteEvent:FireClient(player, "UpdateList", {player.UserId})
        elseif action == "Invite" then
            local partyGUID = playerData.PartyGUID
            if not partyGUID then
                warn("[PartyService] - Failed to invite to party, no partyGUID")
                self._remoteEvent:FireClient(player, "Notification", "Failed to invite to party, no partyGUID", "Error")
                return
            end

            if data.ToPlayer == player.UserId then
                self._remoteEvent:FireClient(player, "Notification", "Can't invite yourself", "Error")
                return
            end

            local activePlayer = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(data.ToPlayer))
            if not activePlayer then
                self._remoteEvent:FireClient(player, "Notification", "Player not in-game", "Error")
                return
            end

            local partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(partyGUID))
            if not partyData then
                warn(("[PartyService] - No party data for party %q | Member requester: %s")
                    :format(partyGUID, player.Name))
                return
            end

            local players = partyData.Players
            if table.find(players, data.ToPlayer) then
                warn(("[PartyService] - Failed to invite player %q, player is already in party")
                    :format(data.ToPlayer))
                self._remoteEvent:FireClient(player, "Notification", "Player already in party", "Error")
            else
                print("[PartyService] - Publishing invite message...")
                self._remoteEvent:FireClient(player, "Notification", "Player invited successfully", "Success")

                MessagingService:PublishAsync(SERVER_SUBSCRIPTION_FORMAT:format(activePlayer.ServerId), {
                    Action = "Invite";
                    ServerId = game.JobId;
                    PartyGUID = partyGUID;
                    FromPlayer = player.UserId;
                    ToPlayer = data.ToPlayer;
                })
            end
        elseif action == "AcceptInvite" then
            local activeTable = self._activeInvites[data.GUID]
            local serverTime = workspace:GetServerTimeNow()
            if not activeTable or activeTable and serverTime > activeTable.ExpiresAt then
                warn("[PartyService] - Failed to process invite, expired or invalid")

                self._activeInvites[activeTable.GUID] = nil
                self._remoteEvent:FireClient(player, "Notification", "Invite expired", "Error")
                return
            end

            if playerData.PartyGUID then
                local oldPartyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(playerData.PartyGUID))
                if not oldPartyData then
                    warn(("[PartyService] - Failed to get party data | Party GUID: %q")
                        :format(playerData.PartyGUID))
                    return
                end
                
                if oldPartyData.Owner == player.UserId then
                    self:_disbandParty(player)
                else
                    self:_removePlayerFromParty(player.UserId)
                end
            end

            local partyGUID = activeTable.PartyGUID
            local partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(partyGUID))
            if not partyData then
                warn(("[PartyService] - Failed to get party data | Party GUID: %q")
                    :format(partyGUID))
                return
            end

            print("[PartyService] - Updating player list for party...")
            local playerList = partyData.Players
            table.insert(playerList, player.UserId)
            FunctionUtils.rCallAPI(self._partyMap, "UpdateAsync", PARTY_ID_FORMAT:format(partyGUID), function(partyData)
                partyData.Players = playerList
                return partyData
            end, SEVEN_DAYS_IN_SECONDS)
            print("[PartyService] - Party data updated, updating player data...")
            FunctionUtils.rCallAPI(self._playerMap, "UpdateAsync", USER_ID_FORMAT:format(player.UserId), function(playerData)
                playerData.PartyGUID = partyGUID
                return playerData
            end, SEVEN_DAYS_IN_SECONDS)

            print("[PartyService] - Player data updated, updating clients...")

            self._remoteEvent:FireClient(player, "UpdateList", playerList)
            for _, userId in ipairs(playerList) do
                if userId == player.UserId then
                    continue
                end
                task.spawn(function()
                    local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(userId))
                    if not playerData then
                        warn(("[PartyService] - RemoteEvent handle (AcceptInvite) failed, no player data for player %q")
                            :format(userId))
                        return
                    end

                    print("[PartyService] - Publishing UpdateList message...")

                    MessagingService:PublishAsync(SERVER_SUBSCRIPTION_FORMAT:format(playerData.ServerId), {
                        Action = "UpdateList";
                        PlayerList = playerList;
                        ToPlayer = userId;
                        ServerId = game.JobId;
                    })
                end)
            end
        elseif action == "LeaveParty" then
            print(("[PartyService] - LeaveParty requested by %q, handling...")
                :format(player.Name))
            self:_removePlayer(player, true)
            self._remoteEvent:FireClient(player, "Notification", "Successfully left party", "Success")
        elseif action == "StartGame" then
            local partyGUID = playerData.PartyGUID
            if not partyGUID then
                warn("[PartyService] - Failed to start game, no partyGUID")
                self._remoteEvent:FireClient(player, "Notification", "Failed to start game, no partyGUID", "Error")
                return
            end

            local partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(partyGUID))
            if not partyData then
                warn(("[PartyService] - Failed to get party data | Party GUID: %q")
                    :format(partyGUID))
                self._remoteEvent:FireClient(player, "Notification", "Internal Error: No partyData", "Error")
                return
            end

            if partyData.Owner ~= player.UserId then
                warn(("[PartyService] - Failed to start game, %q is not the party owner")
                    :format(player.Name))
                self._remoteEvent:FireClient(player, "Notification", "Only the party owner can start a game", "Error")
                return
            end

            local nextDungeon = UserDataService:GetNextDungeon(player)
            local dungeonInfo = DungeonData[nextDungeon]

            if not dungeonInfo then
                warn(("[PartyService] - Failed to get dungeon info for %q")
                    :format(nextDungeon))
                self._remoteEvent:FireClient(player, "Notification", "Internal Error: No dungeonInfo", "Error")
                return
            end

            local accessCode, privateServerId = TeleportService:ReserveServer(dungeonInfo.PlaceId)
            print(("[PartyService] - Reserved server | Access code: %q")
                :format(accessCode))
            local playerList = {player}

            self._remoteEvent:FireClient(player, "Notification", "Starting game, please wait...", "Information", -1)

            FunctionUtils.rCallAPIAsync(self._teleportDataMap, "SetAsync",
                TELEPORT_DATA_FORMAT:format(privateServerId), {
                    PlayerList = partyData.Players;
                }, 5 * 60)

            local playersToProcess = #partyData.Players
            local playersProcessed = 1

            for _, userId in ipairs(partyData.Players) do
                if userId == player.UserId then
                    continue
                end

                task.spawn(function()
                    local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(userId))
                    if not playerData then
                        warn(("[PartyService] - (Teleport sequence) Failed to get player data for player %q")
                            :format(Players:GetNameFromUserIdAsync(userId)))
                        return
                    end

                    if playerData.ServerId == game.JobId then
                        local player = Players:GetPlayerByUserId(userId)
                        self._remoteEvent:FireClient(player, "Notification", "Starting game, please wait...", "Information", -1)
                        table.insert(playerList, player)
                    else
                        MessagingService:PublishAsync(SERVER_SUBSCRIPTION_FORMAT:format(playerData.ServerId), {
                            Action = "Teleport";
                            ToPlayer = userId;
                            AccessCode = accessCode;
                            DungeonId = dungeonInfo.PlaceId;
                        })
                    end

                    playersProcessed += 1
                end)
            end

            while playersToProcess ~= playersProcessed do
                task.wait()
            end
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ReservedServerAccessCode = accessCode
            TeleportService:TeleportAsync(dungeonInfo.PlaceId, playerList, teleportOptions)
        elseif action == "Kick" then
            local partyGUID = playerData.PartyGUID
            if not partyGUID then
                warn("[PartyService] - Failed to kick player, no partyGUID")
                self._remoteEvent:FireClient(player, "Notification", "Failed to kick player, no partyGUID", "Error")
                return
            end

            local partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(partyGUID))
            if not partyData then
                warn(("[PartyService] - Failed to get party data | Party GUID: %q")
                    :format(partyGUID))
                self._remoteEvent:FireClient(player, "Notification", "Internal Error: No partyData", "Error")
                return
            end

            if partyData.Owner ~= player.UserId then
                self._remoteEvent:FireClient(player, "Notification", "You are not the party owner", "Error")
                return
            end

            if player.UserId == data.ToPlayer then
                self._remoteEvent:FireClient(player, "Notification", "Can't kick party owner", "Error")
                return
            end

            local success, err = self:_removePlayerFromParty(data.ToPlayer)
            if not success and err then
                self._remoteEvent:FireClient(player, "Notification", err, "Error")
                return
            end
        end
    end)

    function self._remoteFunction:OnServerInvoke(player, action)
        local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(player.UserId))
        if not playerData then
            warn("[PartyService] - Failed to get playerData")
            self._remoteEvent:FireClient(player, "Notification", "Failed to get playerData", "Error")
            return
        end

        local partyData = nil
        if playerData.PartyGUID then
            partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(playerData.PartyGUID))
        end

        if action == "IsPartyMember" then
            return partyData and true or false
        elseif action == "IsPartyOwner" then
            return partyData and partyData.Owner == player.UserId
        elseif action == "GetPartyMembers" then
            if partyData then
                return partyData.Players
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        self:_addPlayer(player)
    end
    Players.PlayerAdded:Connect(function(player)
        self:_addPlayer(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self:_removePlayer(player)
    end)

    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do
            self:_removePlayer(player)
        end
    end)
end

function PartyService:_fireClientByUserId(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if not player then
        return
    end

    self._remoteEvent:FireClient(player, ...)
end

function PartyService:_addPlayer(player)
    print("[PartyService] - Added player to playerMap")
    FunctionUtils.rCallAPI(self._playerMap, "SetAsync",
        USER_ID_FORMAT:format(player.UserId), {
            ServerId = game.JobId;
            PartyGUID = nil;
        }, SEVEN_DAYS_IN_SECONDS
    )
end

function PartyService:_removePlayerFromParty(playerId)
    local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(playerId))
    if not playerData then
        warn("[PartyService] - No playerData")
        return false, "Internal error: No playerData"
    end

    print("[_removePlayerFromParty] - Total playerData contents:")
    for i, v in pairs(playerData) do
        warn(i, "=", v)
    end

    local partyGUID = playerData.PartyGUID
    if not partyGUID then
        warn("[PartyService] - No partyGUID")
        return false, "Internal error: No partyGUID"
    end

    FunctionUtils.rCallAPI(self._playerMap, "UpdateAsync", USER_ID_FORMAT:format(playerId), function(playerData)
        playerData.PartyGUID = nil
        return playerData
    end, SEVEN_DAYS_IN_SECONDS)

    MessagingService:PublishAsync(
        SERVER_SUBSCRIPTION_FORMAT:format(playerData.ServerId), {
            Action = "UpdateList";
            ToPlayer = playerId;
            PlayerList = {};
    })

    local partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(partyGUID))
    if partyData then
        local playerList = partyData.Players
        table.remove(playerList, table.find(playerList, playerId))

        for _, userId in ipairs(partyData.Players) do
            if userId == playerId then
                continue
            end

            task.spawn(function()
                local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(userId))
                if not playerData then
                    return
                end

                MessagingService:PublishAsync(
                    SERVER_SUBSCRIPTION_FORMAT:format(playerData.ServerId), {
                        Action = "UpdateList";
                        ToPlayer = userId;
                        PlayerList = playerList;
                })
            end)
        end

        FunctionUtils.rCallAPI(self._partyMap, "UpdateAsync", PARTY_ID_FORMAT:format(partyGUID), function(data)
            data.Players = playerList
            return data
        end, SEVEN_DAYS_IN_SECONDS)
    else
        warn(("[PartyService] - Failed to get party data | Party GUID: %q")
            :format(partyGUID))
        return false
    end

    return true
end

function PartyService:_removePlayer(player, doNotPurgeData)
    local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(player.UserId))
    if not playerData then
        warn("[PartyService] - Failed to remove player, no playerData")
        self._remoteEvent:FireClient(player, "Notification", "Failed to remove player, no playerData", "Error")
        return
    end

    if playerData.PartyGUID then
        local oldPartyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(playerData.PartyGUID))
        if not oldPartyData then
            warn(("[PartyService] - Failed to remove player, no party data | Party GUID: %q")
                :format(playerData.PartyGUID))
            return
        end

        if oldPartyData.Owner == player.UserId then
            self:_disbandParty(player)
        else
            self:_removePlayerFromParty(player.UserId)
        end
    end

    if not doNotPurgeData then
        FunctionUtils.rCallAPIAsync(self._playerMap, "RemoveAsync",
            USER_ID_FORMAT:format(player.UserId)
        )
    end

    return true
end

function PartyService:_disbandParty(player)
    local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(player.UserId))
    if not playerData then
        warn(("[PartyService] - Failed to disband party, no player data for player %q")
            :format(player.UserId))
        return
    end

    local partyGUID = playerData.PartyGUID
    if not partyGUID then
        warn("[PartyService] - Failed to disband party, no partyGUID")
        self._remoteEvent:FireClient(player, "Notification", "Failed to disband party, no partyGUID", "Error")
        return
    end

    local partyData = FunctionUtils.rCallAPIAsync(self._partyMap, "GetAsync", PARTY_ID_FORMAT:format(partyGUID))
    if not partyData then
        warn(("[PartyService] - Failed to get party data | Party GUID: %q")
            :format(partyGUID))
        self._remoteEvent:FireClient(player, "Notification", "Internal Error: No partyData", "Error")
        return
    end

    self._remoteEvent:FireClient(player, "UpdateList", {})

    for _, userId in ipairs(partyData.Players) do
        task.spawn(function()
            local playerData = FunctionUtils.rCallAPIAsync(self._playerMap, "GetAsync", USER_ID_FORMAT:format(userId))
            if not playerData then
                return
            end

            FunctionUtils.rCallAPI(self._playerMap, "UpdateAsync", USER_ID_FORMAT:format(userId), function(playerData)
                if not playerData then
                    return playerData
                end

                playerData.PartyGUID = nil
                return playerData
            end, SEVEN_DAYS_IN_SECONDS)

            if userId ~= player.UserId then
                MessagingService:PublishAsync(
                    SERVER_SUBSCRIPTION_FORMAT:format(playerData.ServerId), {
                        Action = "UpdateList";
                        ToPlayer = userId;
                        PlayerList = {};
                })
            end
        end)
    end

    FunctionUtils.rCallAPIAsync(self._partyMap, "RemoveAsync", PARTY_ID_FORMAT:format(partyGUID))

    return true
end

return PartyService