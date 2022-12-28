return {
	Money = 0; -- int
	XP = 0; -- int

	-- Owned skins
	Weapons = {}; -- {[itemKey] = {Quantity = int}}
	Armors = {}; -- {[itemKey] = {Quantity = int}}
	Pets = {}; -- {[itemKey] = {Quantity = int, Nickname = str, Level = int}}

	-- Special rewards
	SpecialRewards = {}; -- {[rewardName] = bool}

    -- Equipped items
	EquippedItems = {
		Weapon = nil; -- itemKey
		Armor = nil; -- itemKey
		Pet = nil; -- itemKey
	};

	-- Login date
	LastLogin = 0; -- float

	-- Successive login days
	SuccessiveDailyLogins = 0; -- int

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