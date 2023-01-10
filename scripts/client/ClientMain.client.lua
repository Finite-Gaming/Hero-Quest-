--- Main injection point for the client
-- @classmod ClientMain
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local GameManager = require("GameManager")

require("GuiTemplateProvider"):Init()
require("ClientClassBinders"):Init()

require("DamageFeedbackClient"):Init()
require("ArmorRenderer"):Init()

if GameManager:IsLobby() then
    require("LobbyInitClient"):Init()
elseif GameManager:IsDungeon() then
    require("DungeonInitClient"):Init()
end