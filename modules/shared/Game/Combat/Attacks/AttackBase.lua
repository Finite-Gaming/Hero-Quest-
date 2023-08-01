---
-- @classmod AttackBase
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Signal = require("Signal")
local AnimationTrack = require("AnimationTrack")
local SoundPlayer = require("SoundPlayer")
local RandomRange = require("RandomRange")

local AttackBase = setmetatable({}, BaseObject)
AttackBase.__index = AttackBase

function AttackBase.new(obj, animationFolder)
    local self = setmetatable(BaseObject.new(obj), AttackBase)

    self._humanoid = obj._humanoid
    self._playing = false

    self._animationFolder = animationFolder
    self._animationTracks = {}
    self._trackMap = {}

    self._baseSpeed = 1
    self._cooldownGive = 1
    if obj._obj then
        self._baseSpeed = obj._obj:GetAttribute("BaseAttackSpeed") or 1
        self._cooldownGive = obj._obj:GetAttribute("CooldownGive") or 1
    end

    for _, attackAnimation in ipairs(self._animationFolder:GetChildren()) do
        local attackTrack = AnimationTrack.new(attackAnimation, self._humanoid)
        attackTrack.Priority = Enum.AnimationPriority.Action3

        self._maid:AddTask(attackTrack:GetMarkerReachedSignal("AttackUpdate"):Connect(function(attackParam)
            if attackParam == "Start" then
                self.StartHitscan:Fire()
            elseif attackParam == "End" then
                self.EndHitscan:Fire()
            else
                warn(("[Attack] - Incorrect attack parameter string in AttackUpdate %q"):format(attackParam))
            end
        end))

        self._maid:AddTask(attackTrack:GetMarkerReachedSignal("PlaySound"):Connect(function(soundName)
            SoundPlayer:PlaySoundAtPart(self._humanoid.RootPart, soundName)
            self.SoundPlayed:Fire(soundName)
        end))

        self._maid:AddTask(attackTrack:GetMarkerReachedSignal("CameraShake"):Connect(function(intensity)
            self.ShakeCamera:Fire(intensity)
        end))

        self._maid:AddTask(attackTrack.Stopped:Connect(function()
            self.EndHitscan:Fire()
            self._playing = false
        end))

        table.insert(self._animationTracks, attackTrack)
        self._trackMap[#self._animationTracks] = attackAnimation
    end

    self._randomRange = RandomRange.new(1, #self._animationTracks)

    self.StartHitscan = self._maid:AddTask(Signal.new())
    self.EndHitscan = self._maid:AddTask(Signal.new())
    self.SoundPlayed = self._maid:AddTask(Signal.new())
    self.AttackPlayed = self._maid:AddTask(Signal.new())
    self.ShakeCamera = self._maid:AddTask(Signal.new())

    return self
end

function AttackBase:Cancel()
    self._playing = false
    if self._playingTrack then
        self._playingTrack:Stop(0)
    end
    self.EndHitscan:Fire()
end

function AttackBase:IsPlaying()
    return self._playing
end

function AttackBase:GetAnimationTrack(index)
    return self._animationTracks[index]
end

function AttackBase:Play(character, speed)
    speed = speed or 1
    if self._playing then
        if math.clamp(self._playingTrack.TimePosition/self._playingTrack.Length, 0, math.huge) >= self._cooldownGive then
            self:Cancel()
        else
            return self._playingTrack
        end
    end

    self._playing = true

    local trackIndex = self._randomRange:Get()
    local randomTrack = self._animationTracks[trackIndex]
    self._playingTrack = randomTrack

    randomTrack:Play(nil, nil, (1 * (self._trackMap[trackIndex]:GetAttribute("SpeedModifier") or 1)) * (self._baseSpeed) * (speed))
    -- self.StartHitscan:Fire()

    self.AttackPlayed:Fire(character)

    return randomTrack
end

return AttackBase