--- Loads players characters when they have finished loading the games assets
-- @classmod CharacterService
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Players = game:GetService("Players")

local Network = require("Network")
local CharacterServiceConstants = require("CharacterServiceConstants")
local GameManager = require("GameManager")
local UserData = require("UserData")
local ProgressionHelper = require("ProgressionHelper")
local ServerClassBinders = require("ServerClassBinders")
local ArmorHandler = require("ArmorHandler")
local PetHandler = require("PetHandler")
local WeaponHandler = require("WeaponHandler")

local CharacterService = {}

-- Initialize remote function
function CharacterService:Init()
    self._loadedPlayers = {}
    self._playerLoaded = Instance.new("BindableEvent")

    Players.PlayerAdded:Connect(function(player)
        self:_handlePlayerAdded(player)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(self._handlePlayerAdded, self, player)
    end

    if GameManager:IsLobby() then
        Network:GetRemoteFunction(CharacterServiceConstants.DONE_LOADING_REMOTE_FUNCTION_NAME).OnServerInvoke = function(player)
            if not self._loadedPlayers[player] then
                self._loadedPlayers[player] = true
                player:LoadCharacter()
                self._playerLoaded:Fire()
            end
        end
    end

    UserData.LoggedIn:Connect(function(player, profile)
        ProgressionHelper:HandlePlayerLoggedIn(player, profile)
    end)
end

-- Binds connections to player
function CharacterService:_handlePlayerAdded(player)
    if GameManager:IsLobby() then
        while not self._loadedPlayers[player] do
            self._playerLoaded.Event:Wait()
        end
    end

	self:_handleCharacterAdded(player, player.Character)
	player.CharacterAdded:Connect(function(character)
        self:_handleCharacterAdded(player, character)
    end)
end

-- Respawns player after they die
function CharacterService:_handleCharacterAdded(player, character)
    if not character then
        return
    end
    ArmorHandler:UpdateArmor(player, character)
    PetHandler:UpdatePet(player, character)
    WeaponHandler:UpdateWeapon(player, character)

    ServerClassBinders.Character:Bind(character)

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