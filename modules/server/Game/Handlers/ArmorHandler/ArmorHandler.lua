--- Rewards players for playing in alpha
-- @classmod AlphaRewardService
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ArmorService = require("ArmorService")
local ItemConstants = require("ItemConstants")
local UserDataService = require("UserDataService")
local HumanoidUtils = require("HumanoidUtils")

local ArmorHandler = {}

-- Change players armor
function ArmorHandler:UpdateArmor(player, character)
	if not character then
		return
	end

    local humanoid = character:WaitForChild("Humanoid")
    while not humanoid:IsDescendantOf(game) do
        humanoid.AncestryChanged:Wait()
    end
    HumanoidUtils.cleanDescription(humanoid)
    local equippedArmor = UserDataService:GetEquipped(player, "Armor")
    if equippedArmor then
        ArmorService:ApplyArmor(character, equippedArmor)
    end

    local equippedHelmet = UserDataService:GetEquipped(player, "Helmet")
    if equippedHelmet then
        ArmorService:ApplyHelmet(character, equippedHelmet)
    end
end

return ArmorHandler