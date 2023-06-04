---
-- @classmod PlayerAbilityUI
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")

local PlayerAbilityUI = setmetatable({}, BaseObject)
PlayerAbilityUI.__index = PlayerAbilityUI

function PlayerAbilityUI.new(character)
    local self = setmetatable(BaseObject.new(character), PlayerAbilityUI)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("PlayerAbilityUI"))
    self._screenGui.IgnoreGuiInset = true
    self._gui = GuiTemplateProvider:Get("PlayerAbilityUITemplate")

    self._gui.Parent = self._screenGui

    return self
end

function PlayerAbilityUI:UpdateThumbnail(thumbnailId)
    self._gui.MainFrame.AbilityIcon.Image = thumbnailId
end

return PlayerAbilityUI