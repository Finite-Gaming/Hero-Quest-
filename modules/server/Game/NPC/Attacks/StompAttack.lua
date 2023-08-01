---
-- @classmod StompAttack
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local AttackBase = require("AttackBase")
local Raycaster = require("Raycaster")
local EffectPlayerService = require("EffectPlayerService")
local PlayerDamageService = require("PlayerDamageService")
local CameraShakeService = require("CameraShakeService")
local HitscanPartService = require("HitscanPartService")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local StompAttack = setmetatable({}, AttackBase)
StompAttack.__index = StompAttack

function StompAttack.new(npc)
    local self = setmetatable(AttackBase.new(npc, npc._obj.Animations.Attacks.Stomp), StompAttack)

    self._npc = npc
    self._raycaster = Raycaster.new()
    self._raycaster:Ignore(npc._obj)

    self._radius = 48 -- change to attribute later or something yes
    self._damage = 40

    self._maid:AddTask(self.AttackPlayed:Connect(function()
        local raycastResult = self:_floorCast()
        if not raycastResult then
            return
        end

        local cframe = CFrame.new(raycastResult.Position)

        local pattern = nil
        local healthP = npc._humanoid.Health/npc._humanoid.MaxHealth
        if healthP <= 0.25 then
            pattern = "Snowflake"
        elseif healthP <= 0.5 then
            pattern = "Star30"
        else
            pattern = "Star45"
        end

        HitscanPartService:AddPattern(pattern, {
            BrickColor = BrickColor.new("Persimmon");
            CFrame = cframe;
            Material = Enum.Material.Neon;
        }, NumberRange.new(self._damage - 12, self._damage), 2, 0.25)
    end))

    self._maid:AddTask(self.SoundPlayed:Connect(function(soundName)
        if soundName ~= "Stomp_Impact" then
            return
        end

        local raycastResult = self:_floorCast()
        local effectPosition = nil
        if raycastResult then
            effectPosition = raycastResult.Position
        else
            effectPosition = self._humanoid.RootPart.Position + (-Vector3.yAxis * self._humanoid.HipHeight)
        end
        EffectPlayerService:PlayEffect("AOE", effectPosition)

        -- task.delay(0.2, function()
        --     for _, player in ipairs(Players:GetPlayers()) do
        --         local character = player.Character
        --         if not character then
        --             continue
        --         end

        --         local humanoid = character:FindFirstChild("Humanoid")
        --         if not humanoid then
        --             continue
        --         end

        --         local rootPart = humanoid.RootPart
        --         if not rootPart then
        --             continue
        --         end
        --         local rootPos = rootPart.Position
        --         local hDistance = math.sqrt((rootPos.X - effectPosition.X)^2 + (rootPos.Z - effectPosition.Z)^2)
        --         if hDistance > self._radius then
        --             continue
        --         end

        --         CameraShakeService:Shake(player, 12)

        --         local vDistance = rootPos.Y - effectPosition.Y
        --         if vDistance > 3.5 then
        --             continue
        --         end

        --         PlayerDamageService:DamageCharacter(
        --             character,
        --             self._damage,
        --             self._npc._obj.Name,
        --             0,
        --             effectPosition,
        --             512,
        --             self._radius
        --         )
        --     end
        -- end)
    end))

    return self
end

function StompAttack:_fadedCircleInfo(cframe, lifetime)
    local quality = 7
    local telegraphInfo = {}
    for i = 1, quality do
        local circleSize = (self._radius * 2) * (i/quality)
        telegraphInfo[i] = {
            {
                BrickColor = BrickColor.new("Persimmon");
                CFrame = cframe;
                Shape = Enum.PartType.Cylinder;
                Size = Vector3.new(1, circleSize, circleSize);
                Transparency = TweenService:GetValue(math.clamp(i/quality, 0, 0.9), Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
            },
            lifetime
        }
    end

    return telegraphInfo
end

function StompAttack:_floorCast()
    return self._raycaster:Cast(self._humanoid.RootPart.Position, -Vector3.yAxis * (self._humanoid.HipHeight + 6))
end

return StompAttack