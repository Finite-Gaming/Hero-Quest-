local PlayerStats = {}

function PlayerStats:GetAttackStrengthModifier(player: Player): number
	return player:GetAttribute("AttackStrength") or 1
end

function PlayerStats:GetAttackSpeedModifier(player: Player): number
	return player:GetAttribute("AttackSpeed") or 1
end

return PlayerStats