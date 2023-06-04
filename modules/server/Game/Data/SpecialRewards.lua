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
		Pets = {
			StarterPet = 1;
            OctopusPet = 1; -- will be removed pre-alpha
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

        Money = 100000;
        XP = 100000;
        Weapons = { -- these are for testing and need to be removed pre-alpha
            BasicSword = 1;
        };
        Pets = {
            OctopusPet = 1;
        };
    };
}