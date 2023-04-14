--- Class for MeleeWeapon binder, things like hammer and sword will be handled under this
-- @classmod MeleeWeaponClient
-- @author frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local Players = game:GetService("Players")

local AnimationTrack = require("AnimationTrack")
local BaseObject = require("BaseObject")
local Raycaster = require("Raycaster")
local MeleeWeaponConstants = require("MeleeWeaponConstants")
local Hitscan = require("Hitscan")
local ClientClassBinders = require("ClientClassBinders")
local HumanoidUtils = require("HumanoidUtils")
local AttackBase = require("AttackBase")

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

    -- All this code is required just to get the correct character because roblox has a skill issue
    self._character = self._player.Character
    if self._character then
        if not self._character:IsDescendantOf(workspace) then
            self._character = nil
        end
    end

    if not self._character then
        local currentThread = coroutine.running()

        local old; old = self._player.CharacterAdded:Connect(function(character)
            if character:IsDescendantOf(workspace) then
                self._character = character
                old:Disconnect()
                coroutine.resume(currentThread)
            end
        end)

        coroutine.yield()
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

    if self._animationType == "OneHanded" then
        self._animationFolder = ONE_HANDED_ANIMATIONS
    elseif self._animationType == "TwoHanded" then
        self._animationFolder = TWO_HANDED_ANIMATIONS
    end

    self._randomObject = Random.new()

    self._equipAnimation = AnimationTrack.new(GENERIC_ANIMATIONS:WaitForChild("Equip"), self._humanoid)

    self._attacks = {}
    self._cachedHits = {}

    self:_addAttack(AttackBase, self._animationFolder:WaitForChild("Attacks"))

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

function MeleeWeaponClient:_addAttack(class, animationFolder)
    local attackClass = self._maid:AddTask(class.new(self, animationFolder))
    local hitscan = Hitscan.new(self._handle, self._raycaster)
    self._maid:AddTask(hitscan.Hit:Connect(function(raycastResult)
        if attackClass.HandleHit then
            attackClass:HandleHit(raycastResult)
        else
            self:_handleHit(raycastResult)
        end
    end))
    self._maid:AddTask(attackClass.StartHitscan:Connect(function()
        hitscan:Start()
    end))
    self._maid:AddTask(attackClass.EndHitscan:Connect(function()
        hitscan:Stop()
        table.clear(self._cachedHits)
    end))
    table.insert(self._attacks, attackClass)
end

function MeleeWeaponClient:_handleEquipped()
    self:_playAnimation(self._equipAnimation)
end

function MeleeWeaponClient:_lockHumanoid(humanoid)
    if self._humanoidLocker then
        local lockedHumanoid = self._humanoidLocker:GetObject()
        if lockedHumanoid == humanoid then
            return
        end

        ClientClassBinders.HumanoidLocker:Unbind(lockedHumanoid)
        self._humanoidLocker = nil
    end

    if humanoid then
        self._humanoidLocker = ClientClassBinders.HumanoidLocker:BindAsync(humanoid)
        self._maid.Unlocked = self._humanoidLocker.Unlocked:Connect(function()
            self._humanoidLocker = nil
            self._maid.Unlocked = nil
        end)
    end
end

function MeleeWeaponClient:_handleUnequipped()
    if self._playingAnimation then
        self._playingAnimation:Stop()
    end

    self:_lockHumanoid()
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

    self._remoteEvent:FireServer("Attack")
    self._trail.Enabled = true
    self._attacks[1]:Play()
    self._trail.Enabled = false
end

function MeleeWeaponClient:_handleHit(raycastResult)
    local humanoid = HumanoidUtils.getHumanoid(raycastResult.Instance)
    if not humanoid then
        return
    end

    if self._cachedHits[humanoid] then
        return
    end
    self._cachedHits[humanoid] = true

    self:_lockHumanoid(humanoid)
    self._remoteEvent:FireServer("Hit", raycastResult.Instance, raycastResult.Position)
end

return MeleeWeaponClient