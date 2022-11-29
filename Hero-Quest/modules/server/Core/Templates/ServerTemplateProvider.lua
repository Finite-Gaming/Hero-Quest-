--- Provides the server with specified templates
-- @classmod ServerTemplateProvider
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TemplateProvider = require("TemplateProvider")
local TemplateConstants = require("TemplateConstants")

return TemplateProvider.new(TemplateConstants.TEMPLATE_STORAGE)