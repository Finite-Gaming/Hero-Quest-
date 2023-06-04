---
-- @classmod ClientTemplateProvider
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TemplateProvider = require("TemplateProvider")
local ClientTemplateConstants = require("ClientTemplateConstants")

return TemplateProvider.new(ClientTemplateConstants.TEMPLATE_STORAGE)