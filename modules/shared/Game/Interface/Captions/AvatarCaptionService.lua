---
-- @classmod AvatarCaptionService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local ClientTemplateProvider = require("ClientTemplateProvider")
local Maid = require("Maid")

local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local FADE_TIME = 0.4
local TWEEN_INFO = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear)

local AvatarCaptionService = {}

local function decodeTranscript(str)
    local resultingArray = {}

    local function recurse(sentence)
        local start, stop = sentence:find("|%d+|")
        local rawStr, delayNum = sentence, nil

        if start then
            rawStr = sentence:sub(1, start - 1)
            delayNum = tonumber(sentence:sub(start + 1, stop - 1))
            if delayNum then
                delayNum = delayNum/1000
            end
            table.insert(resultingArray, {Text = rawStr, Delay = delayNum})
            recurse(sentence:sub(stop + 1))
        else
            table.insert(resultingArray, {Text = rawStr, Delay = delayNum})
        end
    end
    recurse(str)

    return resultingArray
end

function AvatarCaptionService:Init()
    self._screenGui = ScreenGuiProvider:Get("AvatarCaption")

    SoundService.ChildAdded:Connect(function(child)
        if not child:IsA("Sound") then
            return
        end

        self:CaptionSound(child)
    end)

    task.spawn(ContentProvider.PreloadAsync, ContentProvider, GuiTemplateProvider:Get("AvatarCaptionTemplate"):GetDescendants())
end

function AvatarCaptionService:CaptionSound(sound)
    self:Caption(sound:GetAttribute("Transcript"), sound:GetAttribute("ViewportPreset"), 3.5)
    return sound
end

function AvatarCaptionService:Caption(transcriptText, avatarPreset, lifetime)
    if not transcriptText then
        return
    end

    if self._maid then
        self._maid:Destroy()
    end

    lifetime = lifetime or 2
    if typeof(avatarPreset) == "string" then
        avatarPreset = ClientTemplateProvider:Get(("Viewport_%s"):format(avatarPreset))
    end

    self._maid = Maid.new()
    self._gui = self._maid:AddTask(GuiTemplateProvider:Get("AvatarCaptionTemplate"))
    self._avatarContainer = self._gui.AvatarBorder.AvatarContainer
    self._captionText = self._gui.CaptionText

    self._fadeInTween = self._maid:AddTask(TweenService:Create(self._captionText, TWEEN_INFO, {
        TextTransparency = 0;
        TextStrokeTransparency = 0;
    }))
    self._fadeOutTween = self._maid:AddTask(TweenService:Create(self._captionText, TWEEN_INFO, {
        TextTransparency = 1;
        TextStrokeTransparency = 1;
    }))

    self._captionText.Text = ""
    self._captionText.Transparency = 1
    self._gui.Parent = self._screenGui
    if avatarPreset then
        avatarPreset.Parent = self._avatarContainer
    end

    local texts = decodeTranscript(transcriptText)
    self._maid:AddTask(task.spawn(function()
        for _, data in ipairs(texts) do
            self:_setCaption(data.Text, data.Delay or lifetime)
        end
        TweenService:Create(self._gui, TWEEN_INFO, {GroupTransparency = 1}):Play()

        task.wait(FADE_TIME)
        self._gui:Destroy()
    end))
end

function AvatarCaptionService:_setCaption(text, fadeAfter)
    self._captionText.Text = text
    self._fadeInTween:Play()

    task.wait(fadeAfter - FADE_TIME)
    self._fadeOutTween:Play()
    task.wait(FADE_TIME)
end

return AvatarCaptionService