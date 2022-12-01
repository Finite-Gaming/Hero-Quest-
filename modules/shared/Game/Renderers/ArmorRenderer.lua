--- Renders armor effects on the client
-- @classmod ArmorRenderer
-- @author unknown, frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

--//Serivces
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")

local Network = require("Network")
local ItemServiceConstants = require("ItemServiceConstants")

local ArmorRenderer = {}

--//Vars
local MiscFolder = game.ReplicatedStorage.Misc
--local WeaponFolder = game.ReplicatedStorage.Weapons
local NeonPartSource = MiscFolder.Neon

--//Data
local BuildTime = 0.6
local LimbBuildDelay = 0.3

local DelayTable = {
	--Feet
	['LeftFoot'] = 0,
	['RightFoot'] = 0,

	--Lower leg
	['LeftLowerLeg'] = 	BuildTime * ( LimbBuildDelay * 1 ),
	['RightLowerLeg'] = BuildTime * ( LimbBuildDelay * 1 ),

	--Upper leg
	['LeftUpperLeg'] =	BuildTime * ( LimbBuildDelay * 2 ),
	['RightUpperLeg'] = BuildTime * ( LimbBuildDelay * 2 ),

	--Lower torso
	['LowerTorso'] = 	BuildTime * ( LimbBuildDelay * 3 ),

	--Upper torso
	['UpperTorso'] = 	BuildTime * ( LimbBuildDelay * 4 ),

	--Upper arms
	['LeftUpperArm'] =	BuildTime * ( LimbBuildDelay * 5 ),
	['RightUpperArm'] = BuildTime * ( LimbBuildDelay * 5 ),

	--Lower arm
	['LeftLowerArm'] = 	BuildTime * ( LimbBuildDelay * 6 ),
	['RightLowerArm'] = BuildTime * ( LimbBuildDelay * 6 ),

	--Hands
	['LeftHand'] = 		BuildTime * ( LimbBuildDelay * 7 ),
	['RightHand'] = 	BuildTime * ( LimbBuildDelay * 7 ),

	['Head'] = 			BuildTime * ( LimbBuildDelay * 5 ),

}

local soundIds = {
	8877818849, 8877820392, 8877821510, 8877822435
}

-- Initialize remote listener
function ArmorRenderer:Init()
    --Future optimisation: cframe all current parts from a table rather than creating a new thread for each
    Network:GetRemoteEvent(ItemServiceConstants.ARMOR_EVENT_REMOTE_EVENT_NAME).OnClientEvent:Connect(function(ArmorFolder)
        --//Vars
        local Chr = ArmorFolder.Parent

        --//Functions
        for _, v in pairs(Chr:GetChildren()) do
            if (v:IsA("Part") or v:IsA("BasePart")) and v.Name ~= 'HumanoidRootPart' and v.Name ~= 'Head' then
                --NeonLimbEffect(v)
                task.spawn(self._neonLimbEffect, self, v)
            end
        end

        for _,v in pairs(ArmorFolder:GetChildren()) do
            self:_perLimbModel(Chr, v)
        end
    end)
end

function ArmorRenderer:_neonLimbEffect(Limb) -- Real Limb
    wait(DelayTable[Limb.Name]*0.9)
    --local limbBottomCF = Limb.CFrame + ( -Limb.CFrame.upVector * Limb.Size.Y / 2)
    --local limbPartCF = Limb.CFrame + ( Limb.CFrame.upVector * Limb.Size.Y / 2)

    --//Making build effect
    local NeonClone = NeonPartSource:Clone()
    NeonClone.Size = Vector3.new( Limb.Size.X*1.05 , 0 , Limb.Size.Z*1.05 )
    --NeonClone.CFrame = limbBottomCF
    NeonClone.Parent = Limb

    NeonClone.Color = Color3.fromRGB(255, 255, 255)
    NeonClone.Transparency = 1

    local followerPart = NeonPartSource:Clone()
    followerPart.Parent = Limb
    followerPart.Size = Vector3.new( Limb.Size.X*1.2 , 0.4 , Limb.Size.Z*1.2 )
    followerPart.Transparency = 0
    followerPart.Color = Color3.fromRGB(255,255,255)
    followerPart.Material = Enum.Material.SmoothPlastic
    TS:Create(followerPart,TweenInfo.new(BuildTime, Enum.EasingStyle.Linear),{Size = Vector3.new(Limb.Size.X*0.9,0,Limb.Size.Z*0.9), Transparency = 1}):Play()
    game.Debris:AddItem(followerPart,5)

    --Sound
    local sound = Instance.new("Sound")
    sound.Volume = 0.5
    sound.PlaybackSpeed = 1 * (math.random()*2)
    sound.SoundId = 'rbxassetid://'..soundIds[math.random(1,#soundIds)]
    sound.Parent = Limb
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    Instance.new("ReverbSoundEffect",sound)
    TS:Create(sound,TweenInfo.new(2,Enum.EasingStyle.Quad),{Volume = 0, PlaybackSpeed = 1}):Play()
    sound:Play()
    game.Debris:AddItem(sound,10)

    --//Tween
    TS:Create(NeonClone,TweenInfo.new(BuildTime,Enum.EasingStyle.Exponential),{Size = Vector3.new(NeonClone.Size.X*1.05 , Limb.Size.Y , NeonClone.Size.Z*1.05), Transparency = 0.3, }):Play()

    delay(BuildTime,function()
        TS:Create(NeonClone,TweenInfo.new(BuildTime,Enum.EasingStyle.Quad),{Transparency = 1, }):Play()
        game.Debris:AddItem(NeonClone,5)
    end)

    local Selected = 'Bottom'

    if string.find(Limb.Name,"Arm") then Selected = 'Top' end
    if string.find(Limb.Name,"Hand") then Selected = 'Top' end

    --//Main
    local startT = os.clock()
    repeat

        local limbBottomCF = Limb.CFrame + ( -Limb.CFrame.upVector * Limb.Size.Y / 2)
        local limbTopCF = Limb.CFrame + ( Limb.CFrame.upVector * Limb.Size.Y / 2)
        if Selected  == 'Bottom' then
            --From bottom up
            NeonClone.CFrame = limbBottomCF * CFrame.new(0, NeonClone.Size.Y / 2 , 0)
            followerPart.CFrame = NeonClone.CFrame * CFrame.new(0, NeonClone.Size.Y / 2 , 0)
        else
            --From top down
            NeonClone.CFrame = limbTopCF * CFrame.new(0, -NeonClone.Size.Y / 2 , 0)
            followerPart.CFrame = NeonClone.CFrame * CFrame.new(0, -NeonClone.Size.Y / 2 , 0)
        end

        --RS.RenderStepped:Wait()
        RS.Heartbeat:Wait()
    until
        os.clock() - startT >= 5.1
end

function ArmorRenderer:_perPartInModel(Chr, Part, LimbModel) --Parts inside the model
    local RealLimb = Chr[LimbModel.Name]
    --task.spawn(NeonLimbEffect,RealLimb)
    --Original Values
    local OriginalValues = {
        Transparency = 0,
        Size = Part.Size,
        Color = Part.Color,
    }

    Part.Transparency = 1
    Part.Color = Color3.fromRGB(255, 255, 255)
    Part.Size = Vector3.new(0,0,0)

    local Multiplier = 1
    if Part.Name == 'Middle' then Multiplier = 1 OriginalValues.Transparency = 0 end

    task.wait(DelayTable[RealLimb.Name] * Multiplier)

    TS:Create(Part,TweenInfo.new(BuildTime, Enum.EasingStyle.Quad) , {Transparency = OriginalValues.Transparency, Color = OriginalValues.Color, Size = OriginalValues.Size} ):Play()

    --local clonedVariant = Part:Clone()
    --clonedVariant:FindFirstChild("WelConstraint"):Destroy()
end

function ArmorRenderer:_perLimbModel(Chr, LimbModel)
    for _,PartInModel in pairs(LimbModel:GetDescendants()) do --Each limb model
        if (PartInModel:IsA("Part") or PartInModel:IsA("BasePart")) then --Each part in limb
            task.spawn(self._perPartInModel, self, Chr, PartInModel,LimbModel)
        end
    end
end

return ArmorRenderer