--- General humanoid utility code.
-- @classmod HumanoidUtils
-- @author frick

local HumanoidUtils = {}

function HumanoidUtils.getHumanoid(descendant)
	local character = descendant
	while character do
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			return humanoid
		end

		character = character:FindFirstAncestorOfClass("Model")
    end

	return nil
end

local function cleanDesc(humanoid)
    local description = humanoid:GetAppliedDescription()

	local userAvatarDescription = humanoid:FindFirstChild("UserAvatarDescription")
	if not userAvatarDescription then
		userAvatarDescription = description:Clone()
		userAvatarDescription.Name = "UserAvatarDescription"
		userAvatarDescription.Parent = humanoid
	end

	description.Head = 0
	description.Torso = 0
	description.LeftArm = 0
	description.RightArm = 0
	description.LeftLeg = 0
	description.RightLeg = 0

	description.HeadColor = Color3.new()
	description.TorsoColor = Color3.new()
	description.LeftArmColor = Color3.new()
	description.RightArmColor = Color3.new()
	description.LeftLegColor = Color3.new()
	description.RightLegColor = Color3.new()

	description.Pants = 0
	description.Shirt = 0
	description.GraphicTShirt = 0

	description:SetAccessories({}, true)
	humanoid:ApplyDescription(description)
end

-- stolen from Hexcede!!
function HumanoidUtils.cleanDescription(humanoid)
    if not humanoid:IsDescendantOf(game) then
        local event; event = humanoid.AncestryChanged:Connect(function()
            if humanoid:IsDescendantOf(game) then
                cleanDesc(humanoid)
                event:Disconnect()
            end
        end)
    else
        cleanDesc(humanoid)
    end
end

return HumanoidUtils