local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local settingsRemotes = remotes:WaitForChild("Settings")

local setSetting = settingsRemotes:WaitForChild("SetSetting")
local getSetting = settingsRemotes:WaitForChild("GetSetting")
local getSettings = settingsRemotes:WaitForChild("GetSettings")
local Settings = {
	Settings = getSettings:InvokeServer() or {}
}

local settingChanged = Instance.new("BindableEvent")
Settings.SettingChanged = settingChanged.Event

function Settings:Set<T>(setting: string, value: T)
	-- Set the setting server-sided
	setSetting:InvokeServer(setting, value)

	-- Update locally, and fire change event
	self.Settings[setting] = value
	settingChanged:Fire(setting, value)
end
function Settings:Get<T>(setting: string): T
	-- Get the local setting
	local value = self.Settings[setting]
	if value == nil then
		-- If there is none, update it
		value = getSetting:InvokeServer(setting)
		self.Settings[setting] = value
	end
	return value
end

function Settings:Bind<T>(setting: string, callback: (T) -> ())
	-- Bind to when the setting is changed
	local connection = self.SettingChanged:Connect(function(settingName: string, value: T)
		-- If the changed setting matches this one, trigger the callback
		if settingName == setting then
			callback(value)
		end
	end)

	-- Get the current value of the setting
	local value = self:Get(setting)
	if value ~= nil then
		-- If it is set, trigger the callback
		task.spawn(callback, value)
	end
	return connection
end

-- Bind to basic settings
local musicGroup = SoundService:WaitForChild("Music")
local sfxGroup = SoundService:WaitForChild("SFX")
local ambientGroup = SoundService:WaitForChild("Ambient")
Settings:Bind("MusicVolume", function(volume: number)
	musicGroup.Volume = volume
end)
Settings:Bind("SFXVolume", function(volume: number)
	sfxGroup.Volume = volume
end)
Settings:Bind("AmbienceVolume", function(volume: number)
	ambientGroup.Volume = volume
end)

Settings:Bind("CameraShake", function(state: boolean)

end)
Settings:Bind("ShowOtherPlayerDamage", function(state: boolean)

end)

local function setParticle(particle: ParticleEmitter, state: boolean)
	local enableParticles = not state
	if enableParticles then
		if particle:GetAttribute("EmissionEnabled") then
			particle.Enabled = true
		end
	else
		if particle.Enabled then
			particle:SetAttribute("EmissionEnabled", true)
			particle.Enabled = false
		end
	end
end
CollectionService:GetInstanceAddedSignal("Particle"):Connect(function(particle: ParticleEmitter)
	setParticle(particle, Settings:Get("ReducedParticles"))
end)
Settings:Bind("ReducedParticles", function(state: boolean)
	local particles = CollectionService:GetTagged("Particle")
	for _, particle in ipairs(particles) do
		setParticle(particle, state)
	end
end)

local function setShadows(light: Light, state: boolean)
	local enableShadows = not state
	if enableShadows then
		if light:GetAttribute("HasShadows") then
			light.Shadows = true
		end
	else
		if light.Shadows then
			light:SetAttribute("HasShadows", true)
			light.Shadows = false
		end
	end
end
CollectionService:GetInstanceAddedSignal("Light"):Connect(function(light: Light)
	setShadows(light, Settings:Get("ReducedShadows"))
end)
Settings:Bind("ReducedShadows", function(state: boolean)
	local lights = CollectionService:GetTagged("Light")
	for _, light in ipairs(lights) do
		setShadows(light, state)
	end
end)

return Settings