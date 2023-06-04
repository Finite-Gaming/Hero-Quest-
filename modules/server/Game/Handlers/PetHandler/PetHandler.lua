---
-- @classmod PetHandler
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataService = require("UserDataService")
local PetService = require("PetService")

local PetHandler = {}

function PetHandler:UpdatePet(player, character)
    if not character then
        return
    end

    local equippedPet = UserDataService:GetEquipped(player, "Pet")
    PetService:ApplyPet(character, equippedPet)
end

return PetHandler