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
		Pets = {
			StarterPet = 1;
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
	};
    -- Warden drops
    WardenBoss = {
        RewardMultiple = true;
        PromptReward = true;

        Weapons = {
            BasicSword = 1;
        };
        Pets = {
            OctopusPet = 1;
        };
    };
}