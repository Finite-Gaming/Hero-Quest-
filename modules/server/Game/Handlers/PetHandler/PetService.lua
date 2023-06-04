---
-- @classmod PetService
-- @author frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local ServerClassBinders = require("ServerClassBinders")
local ItemDirectory = require("ItemDirectory")
local PetConstants = require("PetConstants")

local Players = game:GetService("Players")

local PetService = {}

function PetService:Init()
    self._petFolder = Instance.new("Folder")
    self._petFolder.Name = "Pets"
    self._petFolder.Parent = workspace.Terrain
end

-- Applies pet to a character
function PetService:ApplyPet(character, petName)
    if not character then
        return
    end

    local petValue = character:FindFirstChild(PetConstants.PET_VALUE_NAME)
    if petValue then
        ServerClassBinders.Pet:Unbind(petValue.Value) -- will destroy pet as well (yoy)
        petValue.Value = nil
    else
        petValue = Instance.new("ObjectValue")
        petValue.Name = PetConstants.PET_VALUE_NAME
    end

    if not petName then
        return
    end

    local newPet = assert(ItemDirectory.Pets:FindFirstChild(petName)):Clone()
    local ownerValue = Instance.new("ObjectValue")
    ownerValue.Name = PetConstants.OWNER_VALUE_NAME
    ownerValue.Value = Players:FindFirstChild(character.Name)

    petValue.Value = newPet
    petValue.Parent = character
    ownerValue.Parent = newPet

    newPet.Parent = self._petFolder
    ServerClassBinders.Pet:Bind(newPet)
end

return PetService