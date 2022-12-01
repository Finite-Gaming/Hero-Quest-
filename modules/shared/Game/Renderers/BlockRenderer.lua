---
-- @classmod BlockRenderer
-- @author unknown, frick

--//Services
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

--//Vars
local PortalFolder = workspace:WaitForChild("Lobby"):WaitForChild("Portal")
local CornerFolder = PortalFolder.Corner
local BlockCloneMain = game.ReplicatedStorage:WaitForChild("PortalBlocks").Block

local Speed = 1
local Amount = 3

local tweenTime = 0.7
local tweenWaitTime = 0.7

local BlockRenderer = {}

function BlockRenderer:Init()
    for _, v in pairs(CornerFolder:GetChildren()) do
        task.spawn(self._cornerMain, self, v)
    end
end

--//Functions
function BlockRenderer:_cornerMain(CornerPoint)
	local BaseVector = CornerPoint.Position + Vector3.new(0, 6, 0)
	local clonedPart = BlockCloneMain:Clone()

	clonedPart:SetPrimaryPartCFrame(CFrame.new(BaseVector))
	clonedPart.Parent = workspace.Debris

	local originalColor = clonedPart.PrimaryPart.Color
	local thisOffset = math.random(-99999,99999)

	local RotX = 0
	local RotY = 0
	local RotZ = 0

	local RotXMultiplier = 1 + math.random()
	local RotYMultiplier = 1 + math.random()
	local RotZMultiplier = 1 + math.random()

	local lastTween = 1 - math.random(1,9)
	local Reverse = false

	while true do
		RS.RenderStepped:Wait()

		local thisClock = os.clock() + thisOffset
		local thisClock2 = tick() + thisOffset

		RotX += RotXMultiplier
		RotY += RotYMultiplier
		RotZ += RotZMultiplier

		local X = math.cos( thisClock * Speed ) * (Amount/2)
		local Y = math.cos( thisClock * Speed ) * Amount
		local Z = math.sin( thisClock2 * Speed ) * (Amount/2)

		clonedPart:SetPrimaryPartCFrame( CFrame.new(BaseVector) * CFrame.new(X,Y,Z) )
		clonedPart:SetPrimaryPartCFrame( clonedPart.PrimaryPart.CFrame * CFrame.Angles(math.rad(RotX),math.rad(RotY),math.rad(RotZ)) )

		if os.clock() - lastTween >= tweenWaitTime then
			lastTween = os.clock()
			Reverse = not Reverse

			local Action
			local Action2
			if Reverse then
				--Random size
				local SelSize = math.random(1,5)
				Action = {Color = originalColor, Transparency = 0.5 , Size = Vector3.new(SelSize,SelSize,SelSize) }
				Action2 = {Size = Vector3.new(SelSize/2,SelSize/2,SelSize/2) }
			else
				--Back to normal
				Action = {Color = originalColor, Transparency = 0.5, Size = Vector3.new(3,3,3) }
				Action2 = {Size = Vector3.new(1.5,1.5,1.5) }
            end

			TS:Create(clonedPart.PrimaryPart,TweenInfo.new(1,Enum.EasingStyle.Linear),Action):Play()
			TS:Create(clonedPart.PrimaryPart.Part2,TweenInfo.new(1,Enum.EasingStyle.Linear),Action2):Play()
		end
	end
end

return BlockRenderer