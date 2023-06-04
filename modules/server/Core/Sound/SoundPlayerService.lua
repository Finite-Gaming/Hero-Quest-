--- Handles sound playing on the server
-- @classmod SoundPlayerService
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local SoundConstants = require("SoundConstants")
local Network = require("Network")

local SoundPlayerService = {}

function SoundPlayerService:Init()
    self._remoteEvent = Network:GetRemoteEvent(SoundConstants.REMOTE_EVENT_NAME)
end

function SoundPlayerService:PlaySound(soundName)
    self._remoteEvent:FireAllClients("PlaySound", soundName)
end

function SoundPlayerService:PlaySoundAtPart(soundName, part)
    self._remoteEvent:FireAllClients("PlaySoundAtPart", part, soundName)
end

return SoundPlayerService