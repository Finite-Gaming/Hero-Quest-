---
-- @classmod ActionHistory
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ActionHistory = {
    _playerMap = {}
}

function ActionHistory:MarkWeaponUsed(player, weaponName)
    local history = self._playerMap[player]
    if not history then
        history = {}
        self._playerMap[player] = history
    end

    history[weaponName] = true
end

function ActionHistory:IsSoloWeapon(player, weaponName)
    local history = self._playerMap[player]
    if not history then
        return false
    end

    return history[weaponName] and #history == 1
end

return ActionHistory