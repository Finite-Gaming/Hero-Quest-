---
-- @classmod PortalRenderer
-- @author

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

--//Services
local RS = game:GetService("RunService")

local StartCF = workspace:WaitForChild("Lobby")
	:WaitForChild("Portal")
	:WaitForChild("Main")
	:WaitForChild("PortalModel")
	:WaitForChild("Prim").CFrame

local LeftStartCF = StartCF * CFrame.new(-17.5,0,0)
local RightStartCF = StartCF * CFrame.new(17.5,0,0)

--//Settings
local Speed = 1
local Radius = 8
local UpRate = 0.07
local UpLimit = 11

local SpeedChangeRate = 2
local lastSpeedChange = 0

math.randomseed(os.clock() * tick())

local PortalRenderer = {}

function PortalRenderer:Init()
    for i = 1,3 do
        self:_start(LeftStartCF, i)
        self:_start(RightStartCF, i)
    end
end

--//Functions
function PortalRenderer:_posHook(OriginCF, Ball, i)
	local thisOffset = math.random(-999999, 999999)
	--local thisOffset = i*3
	local offsetY = math.random(-UpLimit,UpLimit)
	--local offsetY = (i*3)
	--local offsetY = 0
	local Up = true

	local WaveX = math.sin
	local WaveZ = math.cos
	if OriginCF == RightStartCF then
		WaveX = math.cos
		WaveZ = math.sin
	end

	--Radius = Radius + math.random(1,4)
	--Speed = Speed + math.random(1,3)

	local thisRadius = Radius + (math.random(20,200))/30
	local thisSpeed = Speed + (math.random(100,150))/80

	while true do
		--Step
		RS.RenderStepped:Wait()

		--Clock
		local thisClock = os.clock() + thisOffset
		local thisClock2 = tick() + thisOffset

		--Base values
		local X = WaveX( thisClock * thisSpeed ) * thisRadius
		local Y = offsetY + WaveX( thisClock2 * (thisSpeed*2) ) * (thisRadius/4)
		local Z = WaveZ( thisClock * thisSpeed ) * thisRadius

		if Up then
			offsetY = offsetY + (UpRate) 
		else
			offsetY = offsetY - (UpRate)
		end

		if (Up) and (offsetY >= UpLimit) then
			Up = false
		end

		if (not Up) and (offsetY <= (UpLimit*-1) ) then
			Up = true
		end

		if os.clock() - lastSpeedChange >= SpeedChangeRate then
			lastSpeedChange = os.clock()
			--UpRate = UpRate + (math.random(-100,100)/1000)
		end

		--Final position
		--Ball.CFrame = OriginCF + Vector3.new(X,Y,Z)
		Ball.CFrame = OriginCF * CFrame.new(X,Y,Z)

	end
end

function PortalRenderer:_start(OriginCF, i)
	local p = game.ReplicatedStorage.PortalBall.Ball:Clone()
	p.Parent = workspace.Debris

	task.spawn(self._posHook, self, OriginCF, p, i)
end

return PortalRenderer