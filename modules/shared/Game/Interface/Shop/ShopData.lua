--- Holds data pertaining to the shop
-- @classmod PlayerInfoDisplay
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ItemConstants = require("ItemConstants")

local function Category(displayName, categoryKey)
    return {
        DisplayName = displayName;
        Key = categoryKey;
        Items = ItemConstants[categoryKey];
    }
end

return {
    Category("Armor", "Armor"); -- Display name, ItemConstants key
    Category("Weapons", "Weapons");
    Category("Pets", "Pets");
    Category("Armor Effects", "ArmorEffects");
    Category("Abilities", "Abilities")
}