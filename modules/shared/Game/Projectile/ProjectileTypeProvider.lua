--- Holds/provides projectile types
-- @classmod ProjectileTypeProvider
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ProjectileType = require("ProjectileType")
local SparkHitEffect = require("SparkHitEffect")
local DebugVisualizer = require("DebugVisualizer")
local ClientTemplateProvider = require("ClientTemplateProvider")

local RunService = game:GetService("RunService")

local HumanoidDamage = if RunService:IsClient() then require("BaseObject") else require("HumanoidDamage")

local function makeTrail(part, xScale, zScale)
    xScale = xScale or 1
    zScale = zScale or 1

    local trail = Instance.new("Trail")
    local att0, att1 = Instance.new("Attachment"), Instance.new("Attachment")
    local shape = part:IsA("Part") and part.Shape
    local offsetX, offsetZ = (part.Size.X/2) * xScale, (shape == Enum.PartType.Ball and 0 or part.Size.Z/2) * zScale

    att0.Position = Vector3.new(offsetX, 0, offsetZ)
    att1.Position = Vector3.new(-offsetX, 0, offsetZ)

    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
    trail.FaceCamera = true

    att0.Parent = part
    att1.Parent = part
    trail.Parent = part

    return trail
end

local ProjectileTypeProvider = {}

function ProjectileTypeProvider:Init()
    self._types = {}
    self._randomObject = Random.new()

    self:BulkAdd({
        ProjectileType.new({
            Name = "BouncyNeonBullet";
            Speed = 90;
            Lifetime = 20;
            BounceData = {
                Bounces = 1000000;
                VelocityPreserved = 1;
            };
            Builder = function()
                local part = DebugVisualizer:GhostPart()

                part.Size = Vector3.new(0.2, 0.2, 1)
                part.BrickColor = BrickColor.new("Pink")
                part.Material = Enum.Material.Neon

                local trail = makeTrail(part)
                trail.Color = ColorSequence.new(BrickColor.new("Pink").Color)
                trail.Lifetime = 0.4

                return part
            end;
            HitEffects = {SparkHitEffect};
        });
        ProjectileType.new({
            Name = "SpikyBall";
            Speed = 40;
            Lifetime = 4;
            BounceData = {
                Bounces = 7;
                VelocityPreserved = 0.8;
            };
            Builder = function()
                local part = ClientTemplateProvider:Get("SpikyBallTemplate")
                local trail = makeTrail(part, 0.6, 0)

                trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
                trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                trail.Color = ColorSequence.new(Color3.new(0.4, 0.4, 0.4))
                trail.LightInfluence = 1
                trail.LightEmission = 0.5
                trail.Lifetime = 0.2

                return part
            end;
            HitEffects = {SparkHitEffect};
            DamageEffects = {HumanoidDamage.new(32, "SpikyBall")};
        });
        ProjectileType.new({
            Name = "Spark";
            Speed = 18;
            Lifetime = 0.5;
            BounceData = {
                Bounces = 4;
                VelocityPreserved = 0.7;
            };
            Builder = function()
                local part = DebugVisualizer:GhostPart()

                part.Size = Vector3.one * 0.1
                part.Transparency = 1

                local trail = makeTrail(part)
                trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
                trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                trail.Color = ColorSequence.new(Color3.new(1, 0.4, 0):Lerp(Color3.new(1, 1, 0), math.random()))
                trail.Lifetime = 0.1

                return part
            end;
        });
        ProjectileType.new({
            Name = "Debris";
            Speed = 38;
            Lifetime = 2;
            BounceData = {
                Bounces = 2;
                VelocityPreserved = 0.4;
            };
            Builder = function()
                local part = ClientTemplateProvider:Get("DebrisTemplate")
                local trail = makeTrail(part, 0.5, 0)

                trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
                trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                trail.Color = ColorSequence.new(Color3.new(1, 0.4, 0))
                trail.LightInfluence = 1
                trail.LightEmission = 0.5
                trail.Lifetime = 0.2

                part.Size *= 1 + self._randomObject:NextNumber(-0.4, 0.2)

                return part
            end;
        });
    })
end

function ProjectileTypeProvider:Add(projectileType)
    self._types[projectileType:GetName()] = projectileType
end

function ProjectileTypeProvider:BulkAdd(projectileTypes)
    for _, projectileType in ipairs(projectileTypes) do
        self:Add(projectileType)
    end
end

function ProjectileTypeProvider:Get(projectileTypeName)
    return self._types[projectileTypeName]
end

function ProjectileTypeProvider:GetTypes()
    return self._types
end

return ProjectileTypeProvider