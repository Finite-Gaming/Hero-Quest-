---
-- @classmod MainButtonsInterface
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")

local MainButtonsInterface = setmetatable({}, BaseObject)
MainButtonsInterface.__index = MainButtonsInterface

function MainButtonsInterface.new(character)
    local self = setmetatable(BaseObject.new(character), MainButtonsInterface)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("PlayerInfoDisplay"))
    self._gui = GuiTemplateProvider:Get("MainButtonsTemplate")

    self:_setupGui()
    self._gui.Parent = self._screenGui

    return self
end

function MainButtonsInterface:_setupGui()

end

return MainButtonsInterface