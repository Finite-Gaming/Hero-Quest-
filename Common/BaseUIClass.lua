---
-- @classmod ClassName
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ScreenGuiProvider = require("ScreenGuiProvider")
local GuiTemplateProvider = require("GuiTemplateProvider")

local ClassName = setmetatable({}, BaseObject)
ClassName.__index = ClassName

function ClassName.new(character)
    local self = setmetatable(BaseObject.new(character), ClassName)

    self._screenGui = self._maid:AddTask(ScreenGuiProvider:Get("ClassName"))
    self._screenGui.IgnoreGuiInset = true
    self._gui = GuiTemplateProvider:Get("ClassNameTemplate")

    return self
end

return ClassName