--!strict

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local GuiTemplateProvider = require("GuiTemplateProvider")
local CombatConstants = require("CombatConstants")
local Network = require("Network")
local PlayerStats = require("PlayerStats")
local ColorSequenceUtil = require("ColorSequenceUtil")
local Settings = RunService:IsClient() and require("Settings")

-- Remotes
local combat = Network:GetRemoteEvent(CombatConstants.COMBAT_CLIENT_REMOTE_EVENT_NAME)
local equip = Network:GetRemoteFunction(CombatConstants.EQUIP_REMOTE_FUNCTION_NAME)
local useWeapon = Network:GetRemoteFunction(CombatConstants.USE_WEAPON_REMOTE_FUNCTION_NAME)
--local attack = Network:GetRemoteFunction(CombatConstants.ATTACK_REMOTE_FUNCTION_NAME)
local onDummyHit = Network:GetRemoteEvent(CombatConstants.DUMMY_ATTACK_REMOTE_EVENT_NAME)

-- Animationns
local animations = ReplicatedStorage:WaitForChild("Animations")
local weaponAnimations = animations:WaitForChild("Weapon")
local genericWeaponAnimations = weaponAnimations:WaitForChild("Generic")

local SWING_SOUNDS = {
	Sword = {
		{
			SoundId = "rbxassetid://9119749145";
			Volume = 1;
			Pitch = 0.9;
		}
	};
	Hammer = {
		{
			SoundId = "rbxassetid://858508159";
			Volume = 0.35;
			Pitch = 2;
		}
	};
}
local HIT_SOUNDS = {
	"rbxassetid://4988622242";
	"rbxassetid://4988621662";
}
local DUMMY_HIT_SOUNDS = {
	"rbxassetid://4988625180";
	"rbxassetid://9120858323";
	--"rbxassetid://6629890936";
}

local MAX_PITCH_SHIFTS = 4
local function pitchShift(sound, targetPitch)
	local function newPitch(sound, pitch)
		if Settings:Get("PitchCorrection") then
			local pitchShift = Instance.new("PitchShiftSoundEffect")
			pitchShift.Octave = pitch
			pitchShift.Parent = sound
		end
	end
	local function scaleDown(sound, targetPitch, base: number)
		local shifts = math.clamp(math.floor(math.log(targetPitch, base)), 0, MAX_PITCH_SHIFTS or 0)
		for i=1, shifts do
			newPitch(sound, base)
		end
		newPitch(sound, targetPitch/base^shifts)
	end

	if targetPitch < 0.5 then
		scaleDown(sound, targetPitch, 0.5)
	elseif targetPitch > 2 then
		scaleDown(sound, targetPitch, 2)
	else
		newPitch(sound, targetPitch)
	end
end

local CombatClient = {}
CombatClient.AnimationType = nil :: string?
CombatClient.Tool = nil :: Tool?

local ready = true
local readyEvent = Instance.new("BindableEvent")
function CombatClient:WaitUntilReady()
	while not ready do
		readyEvent.Event:Wait()
	end
end

local function findByPath(root: Instance, path: {[number]: string}): Instance?
	for _, segment in ipairs(path) do
		if not root then
			return nil
		end
		root = root:FindFirstChild(segment)
		--print("Path", root)
	end
	return root
end

function CombatClient:FindInAnimations(animationName: string): Instance?
	local animationPath = string.split(animationName, ".")
	
	local animationBase = self.AnimationType and weaponAnimations:FindFirstChild(self.AnimationType)
	--print("Get animation", animationBase, animationPath)
	
	return findByPath(animationBase, animationPath) or findByPath(genericWeaponAnimations, animationPath)
end

local function getAnimationId(animation: Animation?): number?
	if animation then
		local idString = string.split(animation.AnimationId, "rbxassetid://")[2]
		if idString then
			return tonumber(idString)
		end
	end
	return nil
end

function CombatClient:FindAnimationId(animationName: string): number?
	return getAnimationId(self:FindInAnimations(animationName) :: Animation?)
end

function CombatClient:BindTool(tool: Tool)
	print("Bound weapon", tool)
	
	tool.Equipped:Connect(function()
		self:Equip(tool)
	end)
	tool.Unequipped:Connect(function()
		local x = nil
		self:Equip(x)
	end)
	
	tool.Activated:Connect(function()
		self:UseWeapon(tool)
	end)
end

function CombatClient:GetAnimationType(tool: Tool | nil)
	return if tool then tool:GetAttribute("AnimationType") else nil
end

-- Equips the specified type of weapon
function CombatClient:Equip(tool: Tool | nil)
	local animationType = self:GetAnimationType(tool)
	local character = player.Character or player.CharacterAdded:Wait()
	
	-- Wait for the Humanoid
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	while not humanoid do
		character.ChildAdded:Wait()
		humanoid = character:FindFirstChildWhichIsA("Humanoid")
	end
	
	-- Wait for the Humanoid to enter the workspace
	while not humanoid:IsDescendantOf(game) do
		humanoid.AncestryChanged:Wait()
	end
	
	-- Equip on the server
	equip:InvokeServer(animationType)

	-- Set the weapon type locally
	self.AnimationType = animationType
	self.Tool = tool
	
	-- Play equip animation
	if tool then
		local equipAnimation = self:FindInAnimations("Equip")
		
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local equipTrack = animator:LoadAnimation(equipAnimation)
			equipTrack.Priority = Enum.AnimationPriority.Action2

			ready = false
			
			-- Play the animation
			equipTrack:Play()
			task.wait(equipTrack.Length * 0.4)
			equipTrack:AdjustWeight(0, equipTrack.Length * (1 - 0.4))
			
			-- Wait for the equip animation to complete
			equipTrack.Stopped:Wait()
			ready = true
			readyEvent:Fire()
		end
	end
end

function CombatClient:GetAttackAnimations()
	local attackAnimations = self:FindInAnimations("Attacks")
	return if attackAnimations then attackAnimations:GetChildren() else nil
end

local soundRandom = Random.new()
function CombatClient:UseWeapon(tool: Tool)
	local character = player.Character or player.CharacterAdded:Wait()

	-- Wait for the Humanoid
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	while not humanoid do
		character.ChildAdded:Wait()
		humanoid = character:FindFirstChildWhichIsA("Humanoid")
	end

	-- Wait for the Humanoid to enter the workspace
	while not humanoid:IsDescendantOf(game) do
		humanoid.AncestryChanged:Wait()
	end
	
	-- Invoke the server
	local nextAttack = useWeapon:InvokeServer(tool)
	if not nextAttack then
		warn("Server rejected request to use weapon.")
		return
	end
	
	-- Get the list of attack animations
	local attacks = self:GetAttackAnimations()
	if not attacks or not attacks[1] then
		warn("No attacks.")
		return
	end
	
	-- Pick the next attack
	local attackAnimation = attacks[nextAttack]
	local animator = humanoid:FindFirstChildOfClass("Animator")
	
	if animator then
		local attackTrack = animator:LoadAnimation(attackAnimation)
		attackTrack.Priority = Enum.AnimationPriority.Action
		
		if not ready then
			return
		end
		ready = false

		-- Play the animation
		local attackSpeed = (tool:GetAttribute("BaseAttackSpeed") or 1) * PlayerStats:GetAttackSpeedModifier(player)
		local weight = 0.9
		local buildDuration = 0.25
		
		local attackDuration = attackTrack.Length / attackSpeed
		
		local handle = tool:FindFirstChild("Handle")
		if handle then
			local trail = handle:FindFirstChildWhichIsA("Trail")
			if trail then
				trail.Enabled = true
			end
			
			local sounds = SWING_SOUNDS[tool:GetAttribute("CombatClientType")] or SWING_SOUNDS.Hammer
			local soundInfo = sounds[math.random(1, #sounds)]

			local swingSound = Instance.new("Sound")
			
			swingSound.SoundGroup = SoundService:WaitForChild("SFX")
			swingSound.SoundId = soundInfo.SoundId
			swingSound.Volume = soundInfo.Volume or 1
			swingSound.Looped = false
			swingSound.PlaybackSpeed = 1 / attackDuration
			swingSound.Parent = handle
			
			swingSound:Play()
			if not swingSound.IsLoaded then
				swingSound.Loaded:Wait()
			end
			swingSound.PlaybackSpeed = swingSound.TimeLength / attackDuration
			--print("Playback speed", swingSound.PlaybackSpeed)
			--print("Length", swingSound.TimeLength)
			
			pitchShift(swingSound, (soundInfo.Pitch or 1) / swingSound.PlaybackSpeed)
			
			task.delay(swingSound.TimeLength / swingSound.PlaybackSpeed, function(sound)
				sound:Destroy()
			end, swingSound)
		end
		
		attackTrack:Play(attackTrack.Length * buildDuration, 0.35, 2 * attackSpeed)
		attackTrack:AdjustWeight(weight, attackTrack.Length * buildDuration)
		attackTrack:AdjustSpeed((1/weight) * attackSpeed, attackTrack.Length * buildDuration)

		-- Wait for the attack animation to complete
		local startTime = os.clock()
		attackTrack.Stopped:Wait()
		task.wait(attackTrack.Length / attackSpeed - (os.clock() - startTime))

		local handle = tool:FindFirstChild("Handle")
		if handle then
			local trail = handle:FindFirstChildWhichIsA("Trail")
			if trail then
				trail.Enabled = false
			end
		end
		
		--hitTracker:Disconnect()
		ready = true
		readyEvent:Fire()
	else
		warn("No animator.")
	end
end

if RunService:IsClient() then
	local random = Random.new()

	local playingAnimations = {}
	onDummyHit.OnClientEvent:Connect(function(character: Model)
		local defaultPivotValue = character:FindFirstChild("DefaultPivot") :: CFrameValue
		if not defaultPivotValue then
			defaultPivotValue = Instance.new("CFrameValue")
			defaultPivotValue.Name = "DefaultPivot" 
			defaultPivotValue.Value = character:GetPivot()
			defaultPivotValue.Parent = character
		end

		-- Test dummy animation
		local defaultPivot = defaultPivotValue.Value
		local currentPivot = character:GetPivot()

		-- Produce a random angle
		local xRot = math.rad(random:NextNumber(-character:GetAttribute("HitAngle"), character:GetAttribute("HitAngle")))
		local yRot = math.rad(random:NextNumber(-character:GetAttribute("HitAngle"), character:GetAttribute("HitAngle")))
		local angle = CFrame.Angles(xRot, 0, yRot)

		-- Move the dummy by the angle & average this with the current pivot
		character:PivotTo((defaultPivot * angle):Lerp(currentPivot, 0.5))

		-- Wobble back to default
		task.spawn(function()
			-- Add 1 to the number of active animations on the dummy so we can weight all the animations
			if not playingAnimations[character] then
				playingAnimations[character] = 0
			end
			playingAnimations[character] += 1

			-- Wobble the dummy
			--print("Start wobble", playingAnimations[character])
			local tweenTime = character:GetAttribute("WobbleTime")
			local startTime = os.clock()
			local startPivot = character:GetPivot()
			while (os.clock() - startTime) < tweenTime do
				local alpha = math.clamp((os.clock() - startTime) / tweenTime, 0, 1)
				alpha = TweenService:GetValue(alpha, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)

				character:PivotTo(startPivot:Lerp(character:GetPivot(), 0.1):Lerp(defaultPivot, alpha))-- * 1/playingAnimations[character]))
				task.wait()
			end
			--print("End wobble", playingAnimations[character])

			-- Animation is done, subtract the number of active animations
			playingAnimations[character] -= 1
			if playingAnimations[character] <= 0 then
				playingAnimations[character] = nil

				-- Reset the dummy to its default position
				character:PivotTo(defaultPivot)
			end
		end)
	end)

	-- Damage/heal indicators
	local function shouldShowIndicator(invoker: Player, target: Model, damage: number)
		local humanoid = target:FindFirstChildWhichIsA("Humanoid")
		
		if humanoid then
			-- If a dummy is attacked, only show hit indicators for the attacker (local player)
			if humanoid:GetAttribute("IsDummy") then
				-- If the invoker is not the local player, do not show the indicator
				if invoker ~= player then
					return false
				end
			end
		end
		
		-- If the player has disabled other player damage indicators, we do not show unless they initiated the indicator
		local showOtherPlayerDamage = Settings:Get("ShowOtherPlayerDamage")
		if not showOtherPlayerDamage then
			if invoker ~= player then
				return false
			end
		end
		
		return true
	end
	
	local function createIndicator(invoker: Player, target: Model, damage: number)
		-- Find the humanoid
		local humanoid = target:FindFirstChildWhichIsA("Humanoid")
		
		local soundId = (humanoid and humanoid:GetAttribute("IsDummy")) and DUMMY_HIT_SOUNDS[math.random(1, #DUMMY_HIT_SOUNDS)] or HIT_SOUNDS[math.random(1, #HIT_SOUNDS)]
		
		local hitSound = Instance.new("Sound")

		local pitchShift = Instance.new("PitchShiftSoundEffect")
		pitchShift.Octave = 1 + soundRandom:NextNumber(-0.25, 0.25)
		pitchShift.Parent = hitSound
		
		hitSound.SoundGroup = SoundService:WaitForChild("SFX")
		hitSound.SoundId = soundId
		hitSound.Volume = (humanoid and humanoid:GetAttribute("IsDummy")) and 0.05 or 0.2
		hitSound.Looped = false
		hitSound.PlaybackSpeed = soundRandom:NextNumber(0.8, 1.2)
		hitSound.Parent = target

		hitSound:Play()
		if not hitSound.IsLoaded then
			hitSound.Loaded:Wait()
		end
		task.delay(hitSound.TimeLength / hitSound.PlaybackSpeed, function(sound)
			sound:Destroy()
		end, hitSound)
		
		-- Ensure we want to show this indicator based on the local player's settings
		if not shouldShowIndicator(invoker, target, damage) then
			return
		end
		
		if humanoid then
			-- Create a new indicator
			local indicator = GuiTemplateProvider:Get("CombatIndicatorTemplate")
			
			-- Grab all of the indicator settings
			local colors = indicator:GetAttribute("Colors")
			local displayTime = indicator:GetAttribute("DisplayTime")
			local fadeDelay = indicator:GetAttribute("FadeDelay")
			local verticalOffset = indicator:GetAttribute("VerticalOffset")
			local endScale = indicator:GetAttribute("EndScale")
			local randomOffsetMax = indicator:GetAttribute("RandomOffset")
			
			-- Grab the indicator canvas
			local canvas = indicator:WaitForChild("CanvasGroup")

			local label = canvas:WaitForChild("Label")
			local percentage = math.clamp(damage / humanoid.MaxHealth, -1, 1)
			if humanoid.Health <= 0 then
				-- If killed
				label.Text = string.format("KO! (%d)", damage)
			else
				label.Text = string.format("%d", damage)
			end
			label.TextColor3 = ColorSequenceUtil:ValueAt(colors, (percentage + 1) / 2)

			local randomOffset = Vector3.new(
				random:NextNumber(-randomOffsetMax.X, randomOffsetMax.X),
				random:NextNumber(-randomOffsetMax.Y, randomOffsetMax.Y),
				random:NextNumber(-randomOffsetMax.Z, randomOffsetMax.Z)
			)
			indicator.StudsOffset += randomOffset

			local tween = TweenService:Create(indicator, TweenInfo.new(displayTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
				StudsOffset = indicator.StudsOffset + randomOffset + Vector3.new(0, verticalOffset, 0);
				Size = UDim2.new(indicator.Size.X.Scale * endScale, 0, indicator.Size.Y.Scale * endScale, 0);
			})
			local groupTween = TweenService:Create(canvas, TweenInfo.new(displayTime - fadeDelay, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
				GroupTransparency = 1;
			})

			task.delay(fadeDelay, function()
				groupTween:Play()
			end)
			tween:Play()

			tween.Completed:Connect(function()
				indicator:Destroy()
				groupTween:Destroy()
				tween:Destroy()
			end)

			indicator.Parent = target
		end
	end

	local onTargetDamaged = Network:GetRemoteEvent(CombatConstants.TARGET_DAMAGED_REMOTE_EVENT_NAME)
	local onTargetHealed = Network:GetRemoteEvent(CombatConstants.TARGET_HEALED_REMOTE_EVENT_NAME)
	
	onTargetDamaged.OnClientEvent:Connect(function(invoker, target, damage)
		createIndicator(invoker, target, damage)
	end)
	onTargetHealed.OnClientEvent:Connect(function(invoker, target, health)
		createIndicator(invoker, target, -health)
	end)
end

return CombatClient