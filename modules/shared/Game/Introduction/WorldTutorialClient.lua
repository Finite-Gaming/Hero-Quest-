---
-- @classmod WorldTutorialClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataClient = require("UserDataClient")
local CaptionShowcaseClient = require("CaptionShowcaseClient")

local WorldTutorialClient = {}

function WorldTutorialClient:Play()
    if self._played then
        return
    end

    if UserDataClient:IsFirstTimer() then
        local sortedComponents = {}
        for _, part in ipairs(workspace:WaitForChild("TutorialComponents"):GetChildren()) do
            sortedComponents[part:GetAttribute("Order")] = {
                AtPosition = part.PositionAttachment.WorldPosition;
                TargetPosition = part.TargetAttachment.WorldPosition;
                CaptionText = part:GetAttribute("CaptionText");
                DisplayTime = part:GetAttribute("DisplayTime");
                ReadSpeed = part:GetAttribute("ReadSpeed");
            }
        end

        self._played = true
        CaptionShowcaseClient:BatchShowcase(sortedComponents)
    end
end

return WorldTutorialClient