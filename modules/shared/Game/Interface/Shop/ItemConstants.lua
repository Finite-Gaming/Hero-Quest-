--- Holds all relevant data pertaining to items
-- @classmod ItemConstants
-- @author

--[[ item data meta:

[itemKey] = {
    LayoutOrder = int: what order the item will be in the shop
    Buyable = bool (optional): should the item be included in the shop
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
            DisplayName = "Basic Sword";
            Rarity = "Common";
        };

        -- Alpha hammer (Steampunk diver)
        AlphaHammer = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Hammer";
            Rarity = "Legendary";

            Cursed = true;
        };
    };
    Pets = {
        StarterPet = {
            DisplayName = "Starter Pet";
        };
        OctopusPet = {
            Buyable = true;
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
            DisplayName = "Basic Armor";
            Health = 40;
            Speed = -1;
            Rarity = "Common";

            ViewportData = {
                YAngle = 150;
            };
        };

        -- Alpha armor (Steampunk diver)
        AlphaArmor = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Armor";
            Health = 50;
            Speed = -1;
            Rarity = "Legendary";

            ViewportData = {
                YAngle = 150;
            };
        };
    };
    Helmets = {
        BasicHelmet = {
            DisplayName = "Basic Helmet";
            Health = 20;
            Speed = -0.5;
            Rarity = "Common";

            ViewportData = {
                YAngle = 150;
            };
        };

        AlphaHelmet = {
            LayoutOrder = 1;
            DisplayName = "Steampunk Helmet";
            Health = 30;
            Speed = -0.5;
            Rarity = "Legendary";

            ViewportData = {
                YAngle = 150;
            };
        };
    };
    Abilities = {
        LightAbility = {
            DisplayName = "Light Ability";
            Thumbnail = "rbxassetid://13196001375";
            Rarity = "Common";
        };
    };
}