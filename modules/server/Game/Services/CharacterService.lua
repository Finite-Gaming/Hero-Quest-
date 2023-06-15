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
local EffectPlayerService = require("EffectPlayerService")
local UserDataService = require("UserDataService")
local PlayerLevelCalculator = require("PlayerLevelCalculator")
local CharacterOverlapParams = require("CharacterOverlapParams")

local RoomManager
if GameManager:IsDungeon() then
    RoomManager = require("RoomManager")
end

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
    elseif GameManager:IsDungeon() then
        self:SpawnPlayer(player)
    end

	self:_handleCharacterAdded(player, player.Character)
	player.CharacterAdded:Connect(function(character)
        self:_handleCharacterAdded(player, character)
    end)

    -- TODO: make player binder for this lol
    self._xpValue = UserDataService:GetExperience(player)
    self._level = PlayerLevelCalculator:GetLevelFromXP(self._xpValue)
    player:GetAttributeChangedSignal("XP"):Connect(function()
        self._xpValue = player:GetAttribute("XP")
        local oldLevel = self._level
        self._level = PlayerLevelCalculator:GetLevelFromXP(self._xpValue)

        local character = player.Character
        if character then
            if self._level > oldLevel then
                EffectPlayerService:PlayCustom("LevelUpEffect", "new", character)
            end
        end
    end)
end

-- Respawns player after they die
function CharacterService:_handleCharacterAdded(player, character)
    if not character then
        return
    end
    character:SetAttribute("SpawnTime", os.clock())
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
        self:SpawnPlayer(player)
    end)
end

function CharacterService:SpawnPlayer(player)
    player:LoadCharacter()

    if GameManager:IsDungeon() then
        local character = player.Character
        character:PivotTo(RoomManager:GetSpawn().CFrame * CFrame.new(0, 2, 0))
        CharacterOverlapParams:Add(character)
    end
end

return CharacterService