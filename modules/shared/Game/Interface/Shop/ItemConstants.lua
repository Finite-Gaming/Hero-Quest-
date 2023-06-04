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

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ItemDirectory = require("ItemDirectory")

local Weapons = ItemDirectory.Weapons
local Pets = ItemDirectory.Pets
local Armor = ItemDirectory.Armor
local Helmets = ItemDirectory.Helmets

return {
    Weapons = {
        -- Basic/default sword
        BasicSword = {
            NotBuyable = true;
            DisplayName = "Basic Sword";
            Speed = 0.5;
            Rarity = "Common";
        };

        -- Alpha hammer (Steampunk diver)
        AlphaHammer = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Hammer";
            Health = 5;
            Speed = 0.5;
            Rarity = "Legendary";

            Cursed = true;
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
            ProductId = 1354616460;
            Rarity = "Common";

            ViewportData = {
                YAngle = 150;
            };
        }
    };
    Armors = {
        -- Basic/default armor
        BasicArmor = {
            NotBuyable = true;
            DisplayName = "Basic Armor";
            Health = 1.2;
            Speed = 0.5;
            Rarity = "Common";

            ViewportData = {
                YAngle = 150;
            };
        };

        -- Alpha armor (Steampunk diver)
        AlphaArmor = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Armor";
            Health = 2;
            Speed = 0.5;
            Rarity = "Legendary";

            ViewportData = {
                YAngle = 150;
            };
        };
    };
    Helmets = {
        BasicHelmet = {
            NotBuyable = true;
            DisplayName = "Basic Helmet";
            Health = 1.2;
            Speed = 0.5;
            Rarity = "Common";

            ViewportData = {
                YAngle = 150;
            };
        };

        AlphaHelmet = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Helmet";
            Health = 2;
            Speed = 0.5;
            Rarity = "Legendary";

            ViewportData = {
                YAngle = 150;
            };
        };
    };
    Abilities = {
        LightAbility = {
            NotBuyable = true;
            DisplayName = "Light Ability";
            Thumbnail = "rbxassetid://13196001375";
            Rarity = "Common";
        };
    };
}