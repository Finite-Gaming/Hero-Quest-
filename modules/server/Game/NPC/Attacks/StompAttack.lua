---
-- @classmod StompAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")
local Raycaster = require("Raycaster")
local EffectPlayerService = require("EffectPlayerService")
local PlayerDamageService = require("PlayerDamageService")
local CameraShakeService = require("CameraShakeService")

local Players = game:GetService("Players")

local StompAttack = setmetatable({}, AttackBase)
StompAttack.__index = StompAttack

function StompAttack.new(npc)
    local self = setmetatable(AttackBase.new(npc, npc._obj.Animations.Attacks.Stomp), StompAttack)

    self._npc = npc
    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(npc._obj)

    self._radius = 48 -- change to attribute later or something yes
    self._damage = 40

    self._maid:AddTask(self.SoundPlayed:Connect(function(soundName)
        if soundName ~= "Stomp_Impact" then
            return
        end

        local raycastResult = self._raycaster:Cast(self._humanoid.RootPart.Position, -Vector3.yAxis * (self._humanoid.HipHeight + 6))
        local effectPosition = nil
        if raycastResult then
            effectPosition = raycastResult.Position
        else
            effectPosition = self._humanoid.RootPart.Position + (-Vector3.yAxis * self._humanoid.HipHeight)
        end
        EffectPlayerService:PlayEffect("AOE", effectPosition)

        task.delay(0.2, function()
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                if not character then
                    continue
                end

                local humanoid = character:FindFirstChild("Humanoid")
                if not humanoid then
                    continue
                end

                local rootPart = humanoid.RootPart
                if not rootPart then
                    continue
                end
                local rootPos = rootPart.Position
                local hDistance = math.sqrt((rootPos.X - effectPosition.X)^2 + (rootPos.Z - effectPosition.Z)^2)
                if hDistance > self._radius then
                    continue
                end

                CameraShakeService:Shake(player, 12)

                local vDistance = rootPos.Y - effectPosition.Y
                if vDistance > 3.5 then
                    continue
                end

                PlayerDamageService:DamageCharacter(
                    character,
                    self._damage,
                    self._npc._obj.Name,
                    0,
                    effectPosition,
                    512,
                    self._radius
                )
            end
        end)
    end))

    return self
end

return StompAttack