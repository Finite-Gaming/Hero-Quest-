-- small dictionary with progression voicelines for each dungeon

local DATA = {
    a_easy = {
        MaxLevel = 15; -- placeholder?

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
                returning_def = "RAHHHHHHHHHHHHHHHHHHH"; -- replace with animal dying lol noob
            };
        };
    };
}

return DATA[workspace:GetAttribute("DungeonTag")]