---
-- @classmod ConfirmationPromptService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GuiTemplateProvider = require("GuiTemplateProvider")
local Maid = require("Maid")
local Signal = require("Signal")

local ConfirmationPromptService = {}

function ConfirmationPromptService:Prompt(message)
    return -- bruhg maybe todo for future
end

return ConfirmationPromptService