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
    Category("Armor", "Armors");
    Category("Helmets", "Helmets"); -- Display name, ItemConstants key
    Category("Weapons", "Weapons");
    Category("Pets", "Pets");
    Category("Abilities", "Abilities")
}