---
-- @classmod CharacterServiceClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ClientClassBinders = require("ClientClassBinders")

local Players = game:GetService("Players")

local CharacterServiceClient = {}

function CharacterServiceClient:Init()
    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        self:_handleCharacterAdded(character)
    end)
    self:_handleCharacterAdded(Players.LocalPlayer.Character)
end

function CharacterServiceClient:_handleCharacterAdded(character)
    if not character then
        return
    end

    ClientClassBinders.CharacterClient:Bind(character)
end

return CharacterServiceClient