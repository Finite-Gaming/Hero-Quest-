--- Class for MeleeWeapon binder, things like hammer and sword will be handled under this
-- @classmod MeleeWeaponClient
-- @author frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local AnimationTrack = require("AnimationTrack")
local BaseObject = require("BaseObject")
local Raycaster = require("Raycaster")
local MeleeWeaponConstants = require("MeleeWeaponConstants")

local ANIMATIONS = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Weapon")
local GENERIC_ANIMATIONS = ANIMATIONS:WaitForChild("Generic")
local ONE_HANDED_ANIMATIONS = ANIMATIONS:WaitForChild("OneHanded")
local TWO_HANDED_ANIMATIONS = ANIMATIONS:WaitForChild("TwoHanded")

local MeleeWeaponClient = setmetatable({}, BaseObject)
MeleeWeaponClient.__index = MeleeWeaponClient

function MeleeWeaponClient.new(obj)
    local self = setmetatable(BaseObject.new(obj), MeleeWeaponClient)

    self._player = self._obj.Parent.Parent
    if not self._player then
        warn("[MeleeWeaponClient] - Failed to get player")
        return
    end

    if self._player ~= Players.LocalPlayer then
        return
    end

    self._character = self._player.Character
    if not self._character then
        warn("[MeleeWeaponClient] - Failed to get character")
        return
    end

    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(self._character)
    self._raycaster:Ignore(workspace.Terrain)
    self._raycaster.Visualize = true

    self._humanoid = self._character:WaitForChild("Humanoid")

    self._attackCooldown = 1/self._obj:GetAttribute("BaseAttackSpeed")
    self._animationType = self._obj:GetAttribute("AnimationType")

    self._handle = self._obj:WaitForChild("Handle")
    self._trail = self._handle:WaitForChild("Trail")

    self._remoteEvent = self._obj:WaitForChild(MeleeWeaponConstants.REMOTE_EVENT_NAME)

    self._hitscanAttachments = {}
    for _, hitscanAttachment in ipairs(self._handle:GetChildren()) do
        if hitscanAttachment.Name ~= "HitscanAttachment" then
            continue
        end

        table.insert(self._hitscanAttachments, hitscanAttachment)
    end
    self._prevPositions = table.create(#self._hitscanAttachments)
    self._cachedHits = {}

    if self._animationType == "OneHanded" then
        self._animationFolder = ONE_HANDED_ANIMATIONS
    elseif self._animationType == "TwoHanded" then
        self._animationFolder = TWO_HANDED_ANIMATIONS
    end

    self._randomObject = Random.new()

    self._equipAnimation = AnimationTrack.new(GENERIC_ANIMATIONS:WaitForChild("Equip"), self._humanoid)
    self._attackAnimations = {}

    for _, attackAnimation in ipairs(self._animationFolder:WaitForChild("Attacks"):GetChildren()) do
        local attackTrack = AnimationTrack.new(attackAnimation, self._humanoid)
        attackTrack.Priority = Enum.AnimationPriority.Action2
        table.insert(self._attackAnimations, attackTrack)
    end

    self._maid:AddTask(self._obj.Equipped:Connect(function()
        self:_handleEquipped()
    end))
    self._maid:AddTask(self._obj.Unequipped:Connect(function()
        self:_handleUnequipped()
    end))

    self._lastHit = os.clock()
    self._maid:AddTask(self._obj.Activated:Connect(function()
        self:_tryAttack()
    end))

    return self
end

function MeleeWeaponClient:_handleEquipped()
    self:_playAnimation(self._equipAnimation)
end

function MeleeWeaponClient:_handleUnequipped()
    if self._playingAnimation then
        self._playingAnimation:Stop()
    end

    self:_stopHitscan()
end

function MeleeWeaponClient:_playAnimation(animationTrack)
    self._playingAnimation = animationTrack
    animationTrack:Play()
    animationTrack.Stopped:Wait()
    self._playingAnimation = nil
end

function MeleeWeaponClient:_tryAttack()
    if self._playingAnimation then
        return
    end

    local attackTick = os.clock()
    if attackTick - self._lastHit < self._attackCooldown then
        return
    end
    self._lastHit = attackTick

    local attackAnimation = self._attackAnimations[self._randomObject:NextInteger(1, #self._attackAnimations)]

    self._remoteEvent:FireServer("Attack")
    self._trail.Enabled = true
    self:_startHitscan()
    self:_playAnimation(attackAnimation)
    self:_stopHitscan()
    self._trail.Enabled = false
end

function MeleeWeaponClient:_startHitscan()
    table.clear(self._prevPositions)
    table.clear(self._cachedHits)

    self._maid.HitscanUpdate = RunService.Heartbeat:Connect(function()
		for index, attachment in ipairs(self._hitscanAttachments) do
			local worldPos = attachment.WorldPosition
			local origin = self._prevPositions[index] or worldPos

			self._prevPositions[index] = worldPos

            local direction = (worldPos - origin)
			local raycastResult = self._raycaster:Cast(origin, direction)

			if raycastResult then
                local instance = raycastResult.Instance
                if self._cachedHits[instance] then
                    return
                end
                self._cachedHits[instance] = true

                self:_handleHit(raycastResult)
			end
		end
	end)
end

function MeleeWeaponClient:_stopHitscan()
    self._maid.HitscanUpdate = nil
end

function  MeleeWeaponClient:_handleHit(raycastResult)
    self._remoteEvent:FireServer("Hit", raycastResult.Instance, raycastResult.Position)
end

return MeleeWeaponClient