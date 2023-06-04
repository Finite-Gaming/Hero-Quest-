local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Armors = ReplicatedStorage:WaitForChild("ArmorSets");
    Helmets = ReplicatedStorage:WaitForChild("Helmets");
    Pets = ReplicatedStorage:WaitForChild("Pets");
    Weapons = ReplicatedStorage:WaitForChild("Weapons");
    -- we shjould probably move abilities to something similar
}