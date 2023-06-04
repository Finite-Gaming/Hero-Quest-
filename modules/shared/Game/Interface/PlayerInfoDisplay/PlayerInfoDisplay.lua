---
-- @classmod PlayerInfoDisplay
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")
local UserDataClient = require("UserDataClient")
local PlayerPortraitUtil = require("PlayerPortraitUtil")
local PlayerLevelCalculator = require("PlayerLevelCalculator")

local Players = game:GetService("Players")

local PlayerInfoDisplay = setmetatable({}, BaseObject)
PlayerInfoDisplay.__index = PlayerInfoDisplay

function PlayerInfoDisplay.new(character)
    local self = setmetatable(BaseObject.new(character), PlayerInfoDisplay)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("PlayerInfoDisplay"))
    self._screenGui.IgnoreGuiInset = true
    self._gui = GuiTemplateProvider:Get("PlayerInfoDisplayTemplate")

    self._userThumbnail = Players:GetUserThumbnailAsync(
        Players.LocalPlayer.UserId,
        Enum.ThumbnailType.AvatarBust,
        Enum.ThumbnailSize.Size420x420
    )

    self:_setupGui()
    self._gui.Parent = self._screenGui

    self._humanoid = self._obj:WaitForChild("Humanoid")
    self._maxHealth = self._humanoid.MaxHealth

    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        self._maxHealth = self._humanoid.MaxHealth
    end))
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        self:_updateSlider(self._healthBar, math.clamp(self._humanoid.Health, 0, self._maxHealth), self._maxHealth)
    end))
    self:_updateSlider(self._healthBar, self._humanoid.Health, self._humanoid.MaxHealth)

    self._maid:AddTask(Players.LocalPlayer:GetAttributeChangedSignal("XP"):Connect(function()
        local xp = Players.LocalPlayer:GetAttribute("XP")
        self:_updatePortrait(xp)
        self:_updateSlider(self._experienceBar, xp, 1000000)
    end))
    task.spawn(function()
        local xp = UserDataClient:GetExperience()
        self:_updatePortrait(xp)
        self:_updateSlider(self._experienceBar, xp, 1000000)
    end)

    self._maid:AddTask(Players.LocalPlayer:GetAttributeChangedSignal("Money"):Connect(function()
        self:_updateSlider(self._moneyBar, Players.LocalPlayer:GetAttribute("Money"), 1000000)
    end))
    task.spawn(function()
        self:_updateSlider(self._moneyBar, UserDataClient:GetMoney(), 1000000)
    end)

    return self
end

function PlayerInfoDisplay:_updatePortrait(xp)
    local portrait = PlayerPortraitUtil.update(self._gui.MainFrame.Portrait, PlayerLevelCalculator:GetLevelFromXP(xp))
    portrait.PlayerImage.Image = self._userThumbnail
end

function PlayerInfoDisplay:_setupGui()
    self._mainFrame = self._gui.MainFrame
    self._portraitImage = self._mainFrame.Portrait
    self._sliders = self._mainFrame.Sliders
    self._playerLabel = self._mainFrame.NameLabel

    self._healthBar = self._sliders.HealthBar
    self._experienceBar = self._sliders.ExperienceBar
    self._moneyBar = self._sliders.CurrencyBar

    self._nameLabel = self._mainFrame.NameLabel

    self._nameLabel.Text = Players.LocalPlayer.Name
end

function PlayerInfoDisplay:_updateSlider(slider, value, maxValue)
    local percent = value/maxValue
    local displayText = ("%i/%i"):format(math.round(value), math.round(maxValue))

    slider.Label.Text = displayText
    slider.AccentBar.Size = UDim2.fromScale(percent, 1)
end

return PlayerInfoDisplay