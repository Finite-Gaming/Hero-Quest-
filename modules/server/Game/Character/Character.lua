---
-- @classmod Character
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local ServerClassBinders = require("ServerClassBinders")
local GameManager = require("GameManager")

local Players = game:GetService("Players")

local Character = setmetatable({}, BaseObject)
Character.__index = Character

function Character.new(obj)
    local self = setmetatable(BaseObject.new(obj), Character)

    self._player = Players:GetPlayerFromCharacter(self._obj)
    if GameManager:IsDungeon() then
        ServerClassBinders.PlayerAbility:Bind(self._obj)
    end

    return self
end

return Character