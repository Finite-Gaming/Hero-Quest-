---
-- @classmod AttackTelegrapherService
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local Network = require("Network")
local AttackTelegrapherConstants = require("AttackTelegrapherConstants")

local AttackTelegrapherService = {}

function AttackTelegrapherService:Init()
    self._remoteEvent = Network:GetRemoteEvent(AttackTelegrapherConstants.REMOTE_EVENT_NAME)
end

function AttackTelegrapherService:TelegraphAttack(properties, lifetime)
    self._remoteEvent:FireAllClients("TelegraphAttack", properties, lifetime)
end

function AttackTelegrapherService:BulkTelegraphAttack(telegraphInfo)
    self._remoteEvent:FireAllClients("BulkTelegraphAttack", telegraphInfo)
end

function AttackTelegrapherService:TelegraphCurve(curvePoints, lifetime)
    self._remoteEvent:FireAllClients("TelegraphCurve", curvePoints, lifetime)
end

return AttackTelegrapherService