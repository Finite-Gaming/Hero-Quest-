local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

return {
    LightAbility = {
        Thumbnail = "rbxassetid://13196001375"; -- probably use ItemConstants for this instead
        Class = "BeamAbility";

        BaseStats = {
            Cooldown = 20;
            Damage = 2;
            DamageCooldown = 0.1;
            AbilityLength = 5;
            Range = 10;
        };
    }
}