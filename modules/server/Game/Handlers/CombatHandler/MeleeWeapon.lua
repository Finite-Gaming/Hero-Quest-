--- Class for MeleeWeapon binder, things like hammer and sword will be handled under this
-- @classmod MeleeWeapon
-- @author frick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local require = require(ReplicatedStorage:WaitForChild("Compliance"))

local BaseObject = require("BaseObject")
local MeleeWeaponConstants = require("MeleeWeaponConstants")
local HumanoidUtils = require("HumanoidUtils")
local PlayerDamageService = require("PlayerDamageService")
local ActionHistory = require("ActionHistory")
local UserDataService = require("UserDataService")

local RunService = game:GetService("RunService")

local ANIMATIONS = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Weapon")
local GENERIC_ANIMATIONS = ANIMATIONS:WaitForChild("Generic")
local ONE_HANDED_ANIMATIONS = ANIMATIONS:WaitForChild("OneHanded")
local TWO_HANDED_ANIMATIONS = ANIMATIONS:WaitForChild("TwoHanded")

local BASE_SCALE = 1

local MeleeWeapon = setmetatable({}, BaseObject)
MeleeWeapon.__index = MeleeWeapon

function MeleeWeapon.new(obj)
    local self = setmetatable(BaseObject.new(obj), MeleeWeapon)

    self._player = self._obj:FindFirstAncestorOfClass("Player")
    while not self._player do
        task.wait()
        self._player = self._obj:FindFirstAncestorOfClass("Player")
    end

    if not self._player then
        warn("[MeleeWeapon] - Failed to get player")
        return
    end

    self._character = self._player.Character
    if not self._character then
        warn("[MeleeWeapon] - Failed to get character")
        return
    end

    self._remoteEvent = Instance.new("RemoteEvent")
    self._remoteEvent.Name = MeleeWeaponConstants.REMOTE_EVENT_NAME
    self._remoteEvent.Parent = self._obj

    self._damageRange = self._obj:GetAttribute("Damage")
    if RunService:IsStudio() then
        -- self._damageRange = NumberRange.new(51, 52)
    end

    self._lastAttack = os.clock()
    self._cachedHits = {}

    self._overriddenAnimationData = {}
    self._animateScript = self._character.Animate

    self._humanoid = self._character.Humanoid
    self._attackCooldown = 1/self._obj:GetAttribute("BaseAttackSpeed")
    self._animationType = self._obj:GetAttribute("AnimationType")

    if self._animationType == "OneHanded" then
        self._animationFolder = ONE_HANDED_ANIMATIONS
    elseif self._animationType == "TwoHanded" then
        self._animationFolder = TWO_HANDED_ANIMATIONS
    end

    self._maid:AddTask(self._obj.Equipped:Connect(function()
        self:_handleEquipped()
    end))
    self._maid:AddTask(self._obj.Unequipped:Connect(function()
        self:_handleUnequipped()
    end))
    self._maid:AddTask(self._remoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if player ~= self._player then
            warn("[MeleeWeapon] - Attempt to fire from incorrect client!")
            return
        end

        if action == "Hit" then
            self:_handleHit(...)
        elseif action == "Attack" then
            self:_handleAttack()
        end
    end))

    return self
end

function MeleeWeapon:_getDamage()
    return math.random(self._damageRange.Min, self._damageRange.Max) +
        (UserDataService:GetUpgradeLevel(self._player, "Damage") * 1.05)
end

function MeleeWeapon:_handleHit(instance, position)
    -- TODO: Validate hit
    local humanoid = HumanoidUtils.getHumanoid(instance)
    if humanoid then
        local totalHits = self._cachedHits[humanoid]
        if totalHits == 2 then
            return
        end
        if totalHits then
            self._cachedHits[humanoid] += 1
        else
            self._cachedHits[humanoid] = 1
        end
        local damage = self:_getDamage()

        ActionHistory:MarkWeaponUsed(self._player, self._obj.Name)
        PlayerDamageService:DamageCharacter(humanoid.Parent, damage, self._obj.Name, nil, self._player)
    end
end

function MeleeWeapon:_handleAttack()
    local attackTick = os.clock()
    if attackTick - self._lastAttack < self._attackCooldown then
        return
    end

    self._attacking = true
    self._lastAttack = attackTick
    task.wait(self._attackCooldown)
    self._attacking = false
    table.clear(self._cachedHits)
end

function MeleeWeapon:_handleEquipped()
    self._equipped = true

    local upgradeLevel = UserDataService:GetUpgradeLevel(self._player, "Damage")
    self._obj:ScaleTo(BASE_SCALE + (BASE_SCALE * (upgradeLevel/250))) -- TODO: change this?

    for _, animation in ipairs(self._animationFolder:GetChildren()) do
        if not animation:IsA("Animation") then
            continue
        end

        local path = self._animateScript:FindFirstChild(animation.Name) or self._animateScript:FindFirstChild(animation.Name:lower())
        if path then
            local oldAnimation = path:FindFirstChildOfClass("Animation")
            if oldAnimation then
                self._overriddenAnimationData[oldAnimation] = oldAnimation.AnimationId
                oldAnimation.AnimationId = animation.AnimationId
            end
        end
    end
    -- self._animateScript.run:FindFirstChildOfClass("Animation").AnimationId = (self._animationFolder:FindFirstChild("Run") or GENERIC_ANIMATIONS.Run).AnimationId
end

function MeleeWeapon:_handleUnequipped()
    self._equipped = false

    for animation, animationId in pairs(self._overriddenAnimationData) do
        animation.AnimationId = animationId
    end
end

return MeleeWeapon