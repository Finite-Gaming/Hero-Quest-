return {
    -- Special rewards are like "bundles" in a way, they are just a way to award a set of items at once
	-- Default
	Starter = {
		Weapons = {
			BasicSword = 1;
		};
		Armors = {
			BasicArmor = 1;
		};
        Helmets = {
            BasicHelmet = 1;
        };

        Abilities = { -- may need to be removed pre-alpha? not sure
            LightAbility = 1;
        };
	};
	-- Alpha tester gear
	ItCameFromTheDeep = {
		Weapons = {
			AlphaHammer = 1;
		};
		Armors = {
			AlphaArmor = 1;
		};
        Helmets = {
            AlphaHelmet = 1;
        };
	};
    -- Warden drops
    WardenBoss = {
        RewardMultiple = true;
        PromptReward = true;

        Money = 1000;
        XP = 1000;
        Weapons = { -- these are for testing and need to be removed pre-alpha
            BasicSword = 1;
        };
        Pets = {
            OctopusPet = 1;
        };
    };

    Developer = {
        RewardMultiple = true;
        PromptReward = true;

        Money = 10000000;
        XP = 10000000;
        Pets = {
            OctopusPet = 1;
        };
    };
}