-- dictionary with data/progression voicelines for each dungeon

local DATA = {
    a_easy = {
        Floors = 1; -- TODO
        PlayTime = 20;
        PlayIndex = 1;

        DisplayName = "Haunted Castle";
		PlaceId = 9678777751;
		MaxPlayers = 50;

        FloorData = {
            [1] = {
                BossName = "Warden";
            };
        };

        ProgressionVoicelines = { -- keep in mind, these are sound effects, not sound groups
            Spawned = {
                first_time = "Warden_Challenge_Noobs";
                returning_def = "Warden_Return_Challenge";
                returning_max = "Warden_Return_Complaint";
            };
            MiniBossCleared = {
                first_time = "Warden_Brag";
                returning_def = "Warden_Boast";
            };
            BossFight = {
                first_time = "Warden_Welcome_Office";
                returning_def = "Warden_Challenge";
            };
            BossDeath = {
                first_time = "Warden_Beware_Sisters";
                returning_def = "Hurt_Roar";
            };
        };
    };
}

return DATA