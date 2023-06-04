---
-- @classmod CharacterModelViewport
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ViewportFrame = require("ViewportFrame")
local ClientTemplateProvider = require("ClientTemplateProvider")

local CharacterModelViewport = setmetatable({}, ViewportFrame)
CharacterModelViewport.__index = CharacterModelViewport

function CharacterModelViewport.new()
    local self = setmetatable(ViewportFrame.new(ClientTemplateProvider:Get("R15BlockRig"), true), CharacterModelViewport)

    

    return self
end

return CharacterModelViewport