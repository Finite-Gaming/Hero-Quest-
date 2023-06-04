--- Default data that will be given to first-time players
-- @classmod DefaultData
-- @author

return {
	Money = 0; -- int
	XP = 0; -- int

	-- Owned stuffs
	Weapons = {}; -- {[itemKey] = {Quantity = int}}
	Armors = {}; -- {[itemKey] = {Quantity = int}}
    Helmets = {}; -- {[itemKey] = {Quantity = int}}
	Pets = {}; -- {[itemKey] = {Quantity = int, Nickname = str, Level = int}}
    Abilities = {}; --{[itemKey] = {Quantity = int}}

	-- Special rewards
	SpecialRewards = {}; -- {[rewardName] = bool}
    RedeemedRewardCodes = {}; -- {[rewardCode] = bool}

    -- Upgrades
    UpgradeData = {
        Damage = 1;
        Health = 1;
        MagicDamage = 1;
    };

    -- Equipped items
	EquippedItems = {
		Weapon = nil; -- itemKey
		Armor = nil;
        Helmet = nil;
		Pet = nil;
        Ability = nil;
	};

	-- Login date
	LastLogin = 0; -- float

    -- Dungeon completion
    DungeonsCompleted = {}; -- {[dungeonTag] = int} (count)
    DungeonsPlayed = {}; -- {[dungeonTag] = int} (count)
    CurrentDungeon = nil; -- {Tag = [dungeonTag], Floor = [int]}

	-- Successive login days
	SuccessiveDailyLogins = 0; -- int

    -- Play data
    PlayCount = 0;

	-- Settings
	Settings = {
		MusicVolume = 1; -- Volume of music
		SFXVolume = 1; -- Volume of SFX
		AmbienceVolume = 1; -- Volume of ambient/background noise

		CameraShake = true; -- Enables/disables screen shake
		PitchCorrection = true; -- Pitch correction for various SFX (Slow)
		ReducedParticles = false; -- Reduces particles for low-end devices
		ReducedShadows = false; -- Whether or not to disable shadows
		ShowOtherPlayerDamage = true; -- Indicates whether or not other player's damage numbers should be displayed
	};
}