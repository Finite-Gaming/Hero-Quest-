---
-- @classmod GenericAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")

local GenericAttack = setmetatable({}, AttackBase)
GenericAttack.__index = GenericAttack

function GenericAttack.new(npc)
    return setmetatable(AttackBase.new(npc, npc._obj.Animations.Attacks.Generic), GenericAttack)
end

return GenericAttack