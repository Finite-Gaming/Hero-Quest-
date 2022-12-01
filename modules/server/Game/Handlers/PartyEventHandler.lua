--- Handles party events
-- @classmod PartyHandler
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local PartyHandlerConstants = require("PartyHandlerConstants")

--//Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

--//Vars
local PartyFolder = game.ReplicatedStorage:WaitForChild("Parties")
local TARGET_PLACE_ID = 9082565132 -- replace with your own place ID

local PartyHandler = {}

-- Initialize remote connections
function PartyHandler:Init()
    Network:GetRemoteEvent(PartyHandlerConstants.CREATE_PARTY_REMOTE_EVENT_NAME).OnServerEvent:Connect(function(Plr)
        local playerIsInAnotherParty = PartyFolder:FindFirstChild(Plr.Name,true)
        local check = PartyFolder:FindFirstChild(Plr.Name)

        if check or playerIsInAnotherParty then return end
        self:_createParty(Plr)
    end)

    Network:GetRemoteEvent(PartyHandlerConstants.JOIN_PARTY_REMOTE_EVENT_NAME).OnServerEvent:Connect(function(Plr,StrParty)
        local checkPartyExistsFolder = PartyFolder:FindFirstChild(StrParty)
        local playerOwnsThisParty = StrParty == Plr.Name
        local playerIsInAnotherParty = PartyFolder:FindFirstChild(Plr.Name,true)

        if (checkPartyExistsFolder) and (not playerOwnsThisParty) and (not playerIsInAnotherParty) then
            local plrObj = Instance.new("ObjectValue")
            plrObj.Name = Plr.Name
            plrObj.Value = Plr
            plrObj.Parent = checkPartyExistsFolder.Players
        end
    end)

    Network:GetRemoteEvent(PartyHandlerConstants.LEAVE_PARTY_REMOTE_EVENT_NAME).OnServerEvent:Connect(function(Plr)
        for _, v in pairs(PartyFolder:GetDescendants()) do
            if v.Name == Plr.Name then
                v:Destroy()
            end
        end
    end)

    Network:GetRemoteEvent(PartyHandlerConstants.START_PARTY_REMOTE_EVENT_NAME).OnServerEvent:Connect(function(Plr)
        local selectedBaseFolder = PartyFolder[Plr.Name]
        local playersToTPFolder = selectedBaseFolder.Players

        local TP_Array = {}

        for _, v in pairs(playersToTPFolder:GetChildren()) do
            table.insert(TP_Array,v.Value)
        end

        --TeleportService:TeleportAsync(TARGET_PLACE_ID,TP_Array)
        local access = TeleportService:ReserveServer(TARGET_PLACE_ID)
        TeleportService:TeleportToPrivateServer(TARGET_PLACE_ID,access,TP_Array)
    end)

    Players.PlayerRemoving:Connect(function(Plr)
        local PartyLeaderFolder = PartyFolder:FindFirstChild(Plr.Name)
        if PartyLeaderFolder then
            PartyLeaderFolder:Destroy()
        end
        --if PartyFolder[Plr.Name] then PartyFolder[Plr.Name]:Destroy() return end
    end)
end

-- Make a new party folder
function PartyHandler:_createParty(ownerPlr)
	--Creating base folder
	local baseFolder = Instance.new("Folder")
	baseFolder.Name = ownerPlr.Name
	--baseFolder.Parent = PartyFolder

	--Creating players inside folder
	local plrFolder = Instance.new("Folder")
	plrFolder.Name = 'Players'
	plrFolder.Parent = baseFolder

	baseFolder.Parent = PartyFolder

	task.delay(0.1,function()
		local val = Instance.new("ObjectValue")
		val.Value = ownerPlr
		val.Name = ownerPlr.Name
		val.Parent = plrFolder
	end)
end

return PartyHandler