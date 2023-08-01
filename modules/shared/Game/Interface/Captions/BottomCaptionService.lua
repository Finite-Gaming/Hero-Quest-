---
-- @classmod BottomCaptionService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local Maid = require("Maid")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local VISIBLE_POSITION = UDim2.new(0.5, 0, 1, -90)
local NOT_VISIBLE_POSITION = UDim2.new(0.5, 0, 1, 90)

local BottomCaptionService = {}

function BottomCaptionService:Init()
    self._screenGui = ScreenGuiProvider:Get("Captions")
end

function BottomCaptionService:Caption(text, displayTime, readSpeed, endedFunc)
    if self._activeMaid and self._activeMaid.Destroy then
        self._activeMaid:Destroy()
    end

    self._activeMaid = Maid.new()

    local startTime = os.clock()
    local caption = GuiTemplateProvider:Get("BottomCaptionTemplate")

    caption.Position = NOT_VISIBLE_POSITION

    self._activeMaid:AddTask(function()
        if endedFunc then
            task.spawn(endedFunc)
        end

        self:_transitionCaption(caption, false, function()
            caption:Destroy()
        end)
    end)

    if readSpeed then
        local totalChars = #text

        self._activeMaid.TextUpdate = RunService.RenderStepped:Connect(function()
            local charsToDisplay = math.clamp((os.clock() - startTime) * readSpeed, 0, totalChars)

            if charsToDisplay == totalChars then
                self._activeMaid.TextUpdate = nil
                self:_addCleanup(displayTime)
            end

            caption.Text = text:sub(1, charsToDisplay)
        end)
    else
        caption.Text = text
        self:_addCleanup(displayTime)
    end

    self:_transitionCaption(caption, true)
    caption.Parent = self._screenGui
end

function BottomCaptionService:_transitionCaption(caption, visible, endedFunc)
    local tween = nil

    if visible then
        tween = self._activeMaid:AddTask(TweenService:Create(caption, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0;
            Position = VISIBLE_POSITION;
        }))
    else
        tween = self._activeMaid:AddTask(TweenService:Create(caption, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1;
            Position = NOT_VISIBLE_POSITION;
        }))
    end

    if endedFunc then
        self._activeMaid:AddTask(tween.Completed:Connect(function()
            endedFunc()
        end))
    end

    tween:Play()
end

function BottomCaptionService:_addCleanup(displayTime)
    if not self._activeMaid then
        return
    end
    displayTime = displayTime or 1

    task.delay(displayTime, function()
        if self._activeMaid and self._activeMaid.Destroy then
            self._activeMaid:Destroy()
        end
    end)
end

return BottomCaptionService