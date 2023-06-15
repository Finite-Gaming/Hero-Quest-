---
-- @classmod PopulateItemFrame
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ViewportFrame = require("ViewportFrame")
local ItemConstants = require("ItemConstants")
local ItemDirectory = require("ItemDirectory")
local ItemRarityData = require("ItemRarityData")

local DEFAULT_THUMBNAIL = "rbxassetid://12017700691"

return function(imageFrame, itemCategory, itemKey)
    local oldViewport = imageFrame:FindFirstChildOfClass("ViewportFrame")
    if oldViewport then
        oldViewport:Destroy()
    end
    local oldRarityBackground = imageFrame.Parent:FindFirstChild("RarityBackground")
    if oldRarityBackground then
        oldRarityBackground:Destroy()
    end

    if itemCategory == "Money" then
        imageFrame.Image = "rbxassetid://13686073572"
        return
    elseif itemCategory == "XP" then
        imageFrame.Image = "rbxassetid://13689883746"
        return
    elseif not itemCategory or not itemKey then
        imageFrame.Image = ""
        return
    end

    local itemData = ItemConstants[itemCategory][itemKey]
    if not itemData then
        return
    end
    local viewportData = itemData.ViewportData

    local viewportModel = viewportData and viewportData.Model or nil
    local viewAngle = viewportData and viewportData.YAngle or nil
    if not viewportModel then
        local categoryFolder = ItemDirectory[itemCategory]

        if categoryFolder then
            viewportModel = categoryFolder:FindFirstChild(itemKey)
        end
    end

    local itemRarity = itemData.Rarity
    if itemRarity then
        local rarityBackground = Instance.new("ImageLabel")
        rarityBackground.Size = imageFrame.Size
        rarityBackground.AnchorPoint = imageFrame.AnchorPoint
        rarityBackground.Position = imageFrame.Position
        rarityBackground.BackgroundTransparency = 1
        rarityBackground.Image = ItemRarityData[itemRarity].Icon
        rarityBackground.Name = "RarityBackground"

        if imageFrame.ZIndex == 1 then
            imageFrame.ZIndex = 2
        end

        rarityBackground.Parent = imageFrame.Parent
    end

    if viewportModel then
        imageFrame.Image = ""

        local viewportFrame = ViewportFrame.new(viewportModel)
        viewportFrame:SetParent(imageFrame)
        viewportFrame:SetMinFitAngle(viewAngle or 125)

        local frame = viewportFrame:GetViewportFrame()
        frame.BackgroundColor3 = Color3.new()
        frame.ZIndex = 3

        return viewportFrame
    else
        imageFrame.Image = itemData.Thumbnail or DEFAULT_THUMBNAIL
    end
end