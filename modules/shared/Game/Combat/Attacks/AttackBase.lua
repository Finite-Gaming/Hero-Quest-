---
-- @classmod AttackBase
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local Signal = require("Signal")
local AnimationTrack = require("AnimationTrack")
local SoundPlayer = require("SoundPlayer")

local AttackBase = setmetatable({}, BaseObject)
AttackBase.__index = AttackBase

function AttackBase.new(obj, animationFolder)
    local self = setmetatable(BaseObject.new(obj), AttackBase)

    self._humanoid = obj._humanoid

    self._animationFolder = animationFolder
    self._animationTracks = {}
    self._trackMap = {}

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

        table.insert(self._animationTracks, attackTrack)
        self._trackMap[#self._animationTracks] = attackAnimation
    end

    self.StartHitscan = self._maid:AddTask(Signal.new())
    self.EndHitscan = self._maid:AddTask(Signal.new())
    self.SoundPlayed = self._maid:AddTask(Signal.new())
    self.AttackPlayed = self._maid:AddTask(Signal.new())

    return self
end

function AttackBase:GetAnimationTrack(index)
    return self._animationTracks[index]
end

function AttackBase:Play(character)
    local trackIndex = math.random(1, #self._animationTracks)
    local randomTrack = self._animationTracks[trackIndex]
    randomTrack:Play(nil, nil, self._trackMap[trackIndex]:GetAttribute("SpeedModifier") or 1)

    self.AttackPlayed:Fire(character)

    return randomTrack
end

return AttackBase