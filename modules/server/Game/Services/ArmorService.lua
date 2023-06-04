---
-- @classmod ArmorService
-- @author Hexcede, frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local Maid = require("Maid")
local EffectPlayerService = require("EffectPlayerService")
local ArmorApplier = require("ArmorApplier")
local SoundPlayerService = require("SoundPlayerService")

local ArmorService = {
    _runningArmorTasks = {};
    _runningHelmetTasks = {};
}

-- Applies armor to a character
function ArmorService:ApplyArmor(character, armorSet)
    local oldMaid = self._runningArmorTasks[character]
    if oldMaid then
        oldMaid:Destroy()
        EffectPlayerService:PlayCustom("ArmorEquipEffect", "cancel", character, "Armor")
        self._runningArmorTasks[character] = nil
    end

    local maid = Maid.new()
    local endTime = workspace:GetServerTimeNow() + 4
    ArmorApplier:ClearArmor(character)

    if armorSet then
        maid:AddTask(task.delay(4, function()
            SoundPlayerService:PlaySoundAtPart("Metal_Kick_Deep", character:FindFirstChild("HumanoidRootPart"))
            ArmorApplier:ApplyArmor(character, armorSet, endTime)
            self._runningArmorTasks[character] = nil
        end))
        maid:AddTask(SoundPlayerService:PlaySoundAtPart("Whoosh_Long", character:FindFirstChild("HumanoidRootPart")))

        self._runningArmorTasks[character] = maid
        EffectPlayerService:PlayCustom("ArmorEquipEffect", "new", character, armorSet, endTime)
    end
end

function ArmorService:ApplyHelmet(character, helmetName)
    local oldMaid = self._runningHelmetTasks[character]
    if oldMaid then
        oldMaid:Destroy()
        EffectPlayerService:PlayCustom("ArmorEquipEffect", "cancel", character, "Helmet")
        self._runningHelmetTasks[character] = nil
    end

    local maid = Maid.new()
    local endTime = workspace:GetServerTimeNow() + 3
    ArmorApplier:ClearHelmet(character)

    if helmetName then
        maid:AddTask(task.delay(3, function()
            SoundPlayerService:PlaySoundAtPart("Metal_Kick_Deep", character:FindFirstChild("HumanoidRootPart"))
            ArmorApplier:ApplyHelmet(character, helmetName, endTime)
            self._runningHelmetTasks[character] = nil
        end))
        maid:AddTask(SoundPlayerService:PlaySoundAtPart("Whoosh_Med_Length", character:FindFirstChild("HumanoidRootPart")))

        self._runningHelmetTasks[character] = maid
        EffectPlayerService:PlayCustom("ArmorEquipEffect", "new", character, helmetName, endTime)
    end
end

return ArmorService