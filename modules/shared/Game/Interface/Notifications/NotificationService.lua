---
-- @classmod NotificationService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local Maid = require("Maid")

local TweenService = game:GetService("TweenService")

local VISIBLE_POSITION = UDim2.fromScale(0.017, 0.968)
local NOT_VISIBLE_POSITION = UDim2.fromScale(0.017, 1.2)

local DEFAULT_LIFETIME = 3

local SHOW_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HIDE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- TODO: sounds (easy)
local FOREGROUNDS = {
    Success = "rbxassetid://13380132416";
    Warning = "rbxassetid://13380132168";
    Error = "rbxassetid://13380132784";

    Information = "rbxassetid://13380132597"; -- default
}

local NotificationService = {}

function NotificationService:Init()
    self._screenGui = ScreenGuiProvider:Get("NotificationBanner")
    self._zIndex = 0 -- stack new stuffs on top of old yay
end

function NotificationService:Notify(text, notificationType, lifetime)
    self._zIndex += 1
    if self._activeNotification then
        self._activeNotification:Destroy()
    end

    local maid = Maid.new()
    self._activeNotification = maid
    local gui = GuiTemplateProvider:Get("NotificationBannerTemplate")
    local active = true

    gui.ZIndex = self._zIndex
    gui.Foreground.Image = notificationType and FOREGROUNDS[notificationType] or FOREGROUNDS.Information
    gui.TextLabel.Text = text

    maid:AddTask(function()
        active = false
        if self._activeNotification == maid then
            self._activeNotification = nil
        end

        TweenService:Create(gui, HIDE_TWEEN_INFO, {Position = NOT_VISIBLE_POSITION}):Play()

        task.delay(HIDE_TWEEN_INFO.Time, function()
            gui:Destroy()
        end)
    end)

    gui.Position = NOT_VISIBLE_POSITION
    gui.Parent = self._screenGui
    TweenService:Create(gui, SHOW_TWEEN_INFO, {Position = VISIBLE_POSITION}):Play()

    if lifetime ~= -1 then
        task.delay(lifetime or DEFAULT_LIFETIME, function()
            if active then
                maid:Destroy()
            end
        end)
    end
end

return NotificationService