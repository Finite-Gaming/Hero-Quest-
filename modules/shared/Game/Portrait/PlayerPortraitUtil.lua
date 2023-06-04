---
-- @classmod PlayerPortraitUtil
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local IMAGE_BUILD = {
    [1] = {
        ZIndex = 3;
        Size = UDim2.fromScale(1, 1);
    };
    [2] = {
        ZIndex = 7;
        Size = UDim2.fromScale(1.2, 1.25);
    };
    [3] = {
        ZIndex = 2;
        Size = UDim2.fromScale(1.4, 1.4);
        Position = UDim2.fromScale(0.51, 0.585);
    };
    [4] = {
        ZIndex = 5;
        Size = UDim2.fromScale(1.4, 1.4);
        Position = UDim2.fromScale(0.51, 0.585);
    };
    [5] = {
        ZIndex = 6;
        Size = UDim2.fromScale(1.4, 1.4);
        Position = UDim2.fromScale(0.51, 0.585);
    };
    [6] = {
        ZIndex = 8;
        Size = UDim2.fromScale(1.4, 1.4);
        Position = UDim2.fromScale(0.51, 0.585);
    };
}

local GUILD_COMPONENTS = {
    BRONZE = {
        BG_IMAGES = {
            [1] = "rbxassetid://13642072198";
            [2] = "rbxassetid://13577666341";
            [3] = "rbxassetid://13577665680";
            [4] = "rbxassetid://13577665472";
            [5] = "rbxassetid://13577665245";
        };
        BADGES = {
            [1] = "rbxassetid://13578219015";
            [2] = "rbxassetid://13578218816";
            [3] = "rbxassetid://13578218598";
            [4] = "rbxassetid://13578218424";
            [5] = "rbxassetid://13578218249";
            [6] = "rbxassetid://13578218087";
            [7] = "rbxassetid://13578217957";
            [8] = "rbxassetid://13578217723";
            [9] = "rbxassetid://13578217368";
        };
    };
    SILVER = {
        BG_IMAGES = {
            [1] = "rbxassetid://13642130296";
            [2] = "rbxassetid://13577944943";
            [3] = "rbxassetid://13577675820";
            [4] = "rbxassetid://13577675587";
            [5] = "rbxassetid://13577675364";
            [6] = "rbxassetid://13577675127";
        };
        BADGES = {
            [1] = "rbxassetid://13578228774";
            [2] = "rbxassetid://13578228481";
            [3] = "rbxassetid://13578228189";
            [4] = "rbxassetid://13578227929";
            [5] = "rbxassetid://13578227774";
            [6] = "rbxassetid://13578227620";
            [7] = "rbxassetid://13578227434";
            [8] = "rbxassetid://13578227179";
            [9] = "rbxassetid://13578226890";
        };
    };
    GOLD = {
        BG_IMAGES = {
            [1] = "rbxassetid://13642127563";
            [2] = "rbxassetid://13577940869";
            [3] = "rbxassetid://13577682216";
            [4] = "rbxassetid://13577681935";
            [5] = "rbxassetid://13577681694";
            [6] = "rbxassetid://13577681482";
        };
        BADGES = {
            [1] = "rbxassetid://13578238628";
            [2] = "rbxassetid://13578238260";
            [3] = "rbxassetid://13578237919";
            [4] = "rbxassetid://13578237725";
            [5] = "rbxassetid://13578237481";
            [6] = "rbxassetid://13578237029";
            [7] = "rbxassetid://13578236864";
            [8] = "rbxassetid://13578236676";
            [9] = "rbxassetid://13578236397";
            [10] = "rbxassetid://13578404467";
            [11] = "rbxassetid://13578404214";
        };
    };
}

local function newUniformGui(class)
    local object = Instance.new(class)
    object.Size = UDim2.fromScale(1, 1)
    object.AnchorPoint = Vector2.new(0.5, 0.5)
    object.Position = UDim2.fromScale(0.5, 0.5)
    object.BackgroundTransparency = 1
    return object
end

local PlayerPortraitUtil = {}

function PlayerPortraitUtil.update(border, level)
    local guild = "BRONZE"
    if level >= 200 then
        guild = "GOLD"
    elseif level >= 100 then
        guild = "SILVER"
    end

    local portrait = newUniformGui("Frame")
    portrait.Name = "LevelPortrait"

    local guildComponents = GUILD_COMPONENTS[guild]
    local guildCompletion = (level%100)/100
    if level >= 300 then
        guildCompletion = 1
    end

    local imageNum = #guildComponents.BG_IMAGES
    local bgDepth = math.clamp(math.round(imageNum * guildCompletion), 1, imageNum)

    for i = 1, bgDepth do
        local imageData = IMAGE_BUILD[i]
        local component = newUniformGui("ImageLabel")
        component.Image = guildComponents.BG_IMAGES[i]
        component.ZIndex = imageData.ZIndex
        if imageData.Position then
            component.Position = imageData.Position
        end
        if imageData.Size then
            component.Size = imageData.Size
        end

        component.Parent = portrait
    end

    local badgeNumber = math.round(#guildComponents.BADGES * guildCompletion)
    if badgeNumber ~= 0 then
        local badge = newUniformGui("ImageLabel")
        badge.Image = guildComponents.BADGES[badgeNumber]
        badge.ZIndex = 100
        badge.Position = UDim2.fromScale(0.515, 0.925)
        badge.Size = UDim2.fromScale(0.2, 0.2)
        badge.Parent = portrait
    end

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.5, 0)

    local playerImage = newUniformGui("ImageLabel")
    playerImage.Size = UDim2.fromScale(0.83, 0.83)
    playerImage.Name = "PlayerImage"
    playerImage.ZIndex = 4

    uiCorner.Parent = playerImage
    playerImage.Parent = portrait

    local oldPortrait = border:FindFirstChild("LevelPortrait")
    if oldPortrait then
        oldPortrait:Destroy()
    end

    portrait.Parent = border

    return portrait
end

return PlayerPortraitUtil