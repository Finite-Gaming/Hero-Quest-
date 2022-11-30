---
-- @classmod CharacterService
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local Network = require("Network")
local CharacterServiceConstants = require("CharacterServiceConstants")

local CharacterService = {}

function CharacterService:Init()
    self._loadedPlayers = {}
    self._playerLoaded = Instance.new("BindableEvent")

    Network:GetRemoteFunction(CharacterServiceConstants.DONE_LOADING_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player)
        if not self._loadedPlayers[player] then
            self._loadedPlayers[player] = true
            player:LoadCharacter()
            self._playerLoaded:Fire()
        end
    end
end

function CharacterService:_handlePlayerAdded(player)
	while not self._loadedPlayers[player] do
		self._playerLoaded.Event:Wait()
	end

	self:_handleCharacterAdded(player, player.Character)
	player.CharacterAdded:Connect(function(character)
        self:_handleCharacterAdded(player, character)
    end)
end

function CharacterService:_handleCharacterAdded(player, character)
    if not character then
        return
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    while not humanoid do
        character.ChildAdded:Wait()
        humanoid = character:FindFirstChildWhichIsA("Humanoid")
    end

    humanoid.Died:Connect(function()
        task.wait(Players.RespawnTime)
        player:LoadCharacter()
    end)
end

return CharacterService