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
		Weapon = "BasicSword"; -- itemKey
		Armor = "BasicArmor";
        Helmet = "BasicHelmet";
		Pet = nil;
        Ability = "LightAbility";
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
		MusicVolume = 80; -- Volume of music
		VoicelineVolume = 100; -- Volume of voicelines
		SFXVolume = 80; -- Volume of SFX
		AmbientVolume = 50; -- Volume of ambient noises (birds chriping, etc.)

		DisableCameraShake = false; -- Enables/disables screen shake
		AutoTarget = true; -- Auto targets enemies with weapons
		ReducedShadows = false; -- Whether or not to disable shadows
		DisableTeamatesDamageHints = false; -- Indicates whether or not other player's damage numbers should be displayed
	};
}