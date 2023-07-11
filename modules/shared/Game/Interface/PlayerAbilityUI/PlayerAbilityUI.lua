---
-- @classmod PlayerAbilityUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")

local RunService = game:GetService("RunService")

local PlayerAbilityUI = setmetatable({}, BaseObject)
PlayerAbilityUI.__index = PlayerAbilityUI

function PlayerAbilityUI.new(character)
    local self = setmetatable(BaseObject.new(character), PlayerAbilityUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("PlayerAbilityUI"))
    self._screenGui.IgnoreGuiInset = true
    self._gui = GuiTemplateProvider:Get("PlayerAbilityUITemplate")

    self._mainFrame = self._gui.MainFrame
    self._imageButton = self._mainFrame.ImageButton
    self._cooldownOverlay = self._imageButton.CooldownOverlay
    self._cooldownLabel = self._imageButton.CooldownLabel

    self:SetEnabled(false)
    self._gui.Parent = self._screenGui

    return self
end

function PlayerAbilityUI:Cooldown(time)
    local startTime = os.clock()
    local finishTime = startTime + time
    self._maid.UpdateOverlay = RunService.RenderStepped:Connect(function()
        local timeDelta = math.clamp((finishTime - os.clock())/time, 0, 1)
        if timeDelta == 0 then
            self._maid.UpdateOverlay = nil
            self._cooldownLabel.Visible = false
            self._cooldownOverlay.Visible = false
            return
        end

        self._cooldownLabel.Text = ("%i"):format(math.ceil(time * timeDelta))
        self._cooldownOverlay.Size = UDim2.fromScale(1, timeDelta)
        self._cooldownLabel.Visible = true
        self._cooldownOverlay.Visible = true
    end)
end

function PlayerAbilityUI:SetEnabled(bool)
    self._screenGui.Enabled = bool
end

function PlayerAbilityUI:UpdateThumbnail(thumbnailId)
    self._gui.MainFrame.ImageButton.Image = thumbnailId
end

function PlayerAbilityUI:GetButton()
    return self._gui.MainFrame.ImageButton
end

return PlayerAbilityUI