--- Holds all relevant data pertaining to items
-- @classmod ItemConstants
-- @author

--[[ item data meta:

[itemKey] = {
    LayoutOrder = int: what order the item will be in the shop
    NotBuyable = bool (optional): should the item be excluded from the shop
    DisplayName = string: the name that the item will be displayed as in-game
    Thumbnail = string (optional): thumbnail the item will be displayed with in-game
    ProductId = int: the developer product the player will be purchasing when buying this item
}
]]

return {
    Weapons = {
        -- Basic/default sword
        BasicSword = {
            NotBuyable = true;
            DisplayName = "Basic Sword";
            Speed = 0.5;
        };

        -- Alpha hammer (Steampunk diver)
        AlphaHammer = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Hammer";
            Thumbnail = "rbxassetid://12017671878";
            Health = 5;
            Speed = 0.5;
        };
    };
    Pets = {
        StarterPet = {
            NotBuyable = true;
            DisplayName = "Starter Pet";
        };
        OctopusPet = {
            LayoutOrder = 1;
            DisplayName = "Octy";
            Thumbnail = "rbxassetid://12017671439";
            ProductId = 1354616460;
        }
    };
    Armors = {
        -- Basic/default armor
        BasicArmor = {
            NotBuyable = true;
            DisplayName = "Basic Armor";
            Thumbnail = "rbxassetid://12017671651";
            Health = 1.2;
            Speed = 0.5;
        };

        -- Alpha armor (Steampunk diver)
        AlphaArmor = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Armor";
            Health = 2;
            Speed = 0.5;
        };
    };
    ArmorEffects = {};
    Abilities = {};
}