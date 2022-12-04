--- Main injection point for the client
-- @classmod ClientMain
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

require("GuiTemplateProvider"):Init()

require("ClientClassBinders"):Init()

require("LoadingScreen"):Init()

require("DamageFeedbackClient"):Init()
require("ArmorRenderer"):Init()
require("BlockRenderer"):Init()
require("PortalRenderer"):Init()