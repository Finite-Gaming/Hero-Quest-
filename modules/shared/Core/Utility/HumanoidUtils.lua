--- General humanoid utility code.
-- @classmod HumanoidUtils
-- @author frick

local HumanoidUtils = {}

function HumanoidUtils.getHumanoid(descendant)
	local character = descendant
	while character do
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid
		end
		character = character:FindFirstAncestorOfClass("Model")
	end

	return nil
end

return HumanoidUtils