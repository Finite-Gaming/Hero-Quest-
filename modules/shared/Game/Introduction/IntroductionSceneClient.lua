---
-- @classmod IntroductionSceneClient
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local UserDataClient = require("UserDataClient")
local ScreenGuiProvider = require("ScreenGuiProvider")
local VoicelineService = require("VoicelineService")

local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local SEQUENCE = {
    [1] = {
        Image = "rbxassetid://13577041644";
        SoundGroup = "LobbyIntroduction1";
    };
    [2] = {
        Image = "rbxassetid://13577042519";
        SoundGroup = "LobbyIntroduction2";
    };
    [3] = {
        Image = "rbxassetid://13577042958";
        SoundGroup = "LobbyIntroduction3";
    };
    [4] = {
        Image = "rbxassetid://13577043425";
        SoundGroup = "LobbyIntroduction4";
    };
}

local SCENE_TRANSITION_TIME = 2
local SCROLL_SCALE = 0.85
local RECT_SIZE = Vector2.new(1024, 620)
local RECT_SCALED = RECT_SIZE * SCROLL_SCALE
local RECT_Y_OFFSET = (RECT_SIZE.Y - RECT_SCALED.Y)/2

local IN_TWEEN_INFO = TweenInfo.new(SCENE_TRANSITION_TIME/2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local OUT_TWEEN_INFO = TweenInfo.new(SCENE_TRANSITION_TIME/2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function makeUniformGui(class)
    local obj = Instance.new(class)
    obj.Size = UDim2.fromScale(1, 1)
    obj.AnchorPoint = Vector2.new(0.5, 0.5)
    obj.Position = UDim2.fromScale(0.5, 0.5)

    return obj
end

local IntroductionSceneClient = {}

function IntroductionSceneClient:Init()
    if UserDataClient:IsFirstTimer() then
        task.spawn(function()
            self._screenGui = ScreenGuiProvider:Get("LobbyIntroduction")
            self._screenGui.IgnoreGuiInset = true
            self._screenGui.DisplayOrder = 3

            SoundService.Music.Volume = 0.45

            self._blackFrame = makeUniformGui("Frame")
            self._blackFrame.BackgroundColor3 = Color3.new()
            self._blackFrame.ZIndex = #SEQUENCE + 1
            self._blackFrame.Parent = self._screenGui

            self._frameFadeIn = TweenService:Create(self._blackFrame, IN_TWEEN_INFO, {BackgroundTransparency = 0})
            self._frameFadeOut = TweenService:Create(self._blackFrame, OUT_TWEEN_INFO, {BackgroundTransparency = 1})

            local cachedCount = 0
            local imageCache = {}
            for i, sequence in ipairs(SEQUENCE) do
                task.spawn(function()
                    local imageLabel = makeUniformGui("ImageLabel")
                    imageLabel.Image = sequence.Image
                    imageLabel.ZIndex = -i
                    imageLabel.Active = true
                    imageLabel.ImageRectSize = RECT_SCALED
                    imageLabel.ImageRectOffset = Vector2.new(0, RECT_Y_OFFSET)

                    imageLabel.Parent = self._screenGui

                    ContentProvider:PreloadAsync({imageLabel})
                    imageCache[i] = imageLabel
                    cachedCount += 1
                end)
            end

            while cachedCount ~= #SEQUENCE do
                task.wait()
            end

            for i, sequence in ipairs(SEQUENCE) do
                local sceneTime = VoicelineService:PlayGroup(sequence.SoundGroup).TimeLength

                local image = imageCache[i]
                TweenService:Create(image,
                    TweenInfo.new(sceneTime + SCENE_TRANSITION_TIME/2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                    {ImageRectOffset = Vector2.new(RECT_SIZE.X - RECT_SCALED.X, RECT_Y_OFFSET)}
                ):Play()
                image.ZIndex = i

                self._frameFadeOut:Play()
                task.wait(SCENE_TRANSITION_TIME/2)

                task.wait(sceneTime)
                self._frameFadeIn:Play()
                task.wait(SCENE_TRANSITION_TIME/1.4)
            end

            for _, image in ipairs(imageCache) do
                image:Destroy()
            end
            self._frameFadeOut:Play()
            SoundService.Music.Volume = 1
        end)
    end
end

return IntroductionSceneClient