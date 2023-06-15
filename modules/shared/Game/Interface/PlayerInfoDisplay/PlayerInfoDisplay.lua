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
        self:_updateSlider(self._healthBar, math.clamp(self._humanoid.Health, 0, self._maxHealth), self._maxHealth)
    end))
    self._maid:AddTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        self:_updateSlider(self._healthBar, math.clamp(self._humanoid.Health, 0, self._maxHealth), self._maxHealth)
    end))
    self:_updateSlider(self._healthBar, self._humanoid.Health, self._humanoid.MaxHealth)

    self._maid:AddTask(Players.LocalPlayer:GetAttributeChangedSignal("XP"):Connect(function()
        local xp = Players.LocalPlayer:GetAttribute("XP")
        self:_updatePortrait(xp)
        local currentLevel = PlayerLevelCalculator:GetLevelFromXP(xp)
        local levelBaseXP = PlayerLevelCalculator:GetXPFromLevel(currentLevel)
        self:_updateSlider(self._experienceBar, xp, PlayerLevelCalculator:GetXPFromLevel(currentLevel + 1), levelBaseXP)
    end))
    task.spawn(function()
        local xp = UserDataClient:GetExperience()
        self:_updatePortrait(xp)
        local currentLevel = PlayerLevelCalculator:GetLevelFromXP(xp)
        local levelBaseXP = PlayerLevelCalculator:GetXPFromLevel(currentLevel)
        self:_updateSlider(self._experienceBar, xp, PlayerLevelCalculator:GetXPFromLevel(currentLevel + 1), levelBaseXP)
    end)

    self._moneyBar.AccentBar.Size = UDim2.fromScale(1, 1)
    self._maid:AddTask(Players.LocalPlayer:GetAttributeChangedSignal("Money"):Connect(function()
        self._moneyBar.Label.Text = math.round(Players.LocalPlayer:GetAttribute("Money"))
    end))
    task.spawn(function()
        self._moneyBar.Label.Text = math.round(UserDataClient:GetMoney())
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

function PlayerInfoDisplay:_updateSlider(slider, value, maxValue, offset)
    local percent = value/maxValue
    local displayPercent = percent
    if offset then
        displayPercent = (value - offset)/(maxValue - offset)
    end
    local displayText = ("%i/%i"):format(math.round(value), math.round(maxValue))

    slider.Label.Text = displayText
    slider.AccentBar.Size = UDim2.fromScale(displayPercent, 1)
end

return PlayerInfoDisplay