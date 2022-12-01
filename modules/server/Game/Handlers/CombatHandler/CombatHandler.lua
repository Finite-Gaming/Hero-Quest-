--- Handles combat for the server, hit events, validation, etc.
-- @classmod BaseService
-- @author

local cRequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local CombatHandlerConstants = cRequire("CombatHandlerConstants")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combat = remotes:WaitForChild("Combat")
local useWeapon = combat:WaitForChild("UseWeapon")
local equip = combat:WaitForChild("Equip")
--local attack = combat:WaitForChild("Attack")
local onDummyHit = combat:WaitForChild("DummyAttack")
local onTargetDamaged = combat:WaitForChild("TargetDamaged")
local onTargetHealed = combat:WaitForChild("TargetHealed")

local animations = ReplicatedStorage:WaitForChild("Animations")
local weaponAnimations = animations:WaitForChild("Weapon")
local genericWeaponAnimations = weaponAnimations:WaitForChild("Generic")

local CombatClient = require(ReplicatedStorage:WaitForChild("CombatClient"))
local PlayerStats = require(ReplicatedStorage:WaitForChild("PlayerStats"))

-- TODO: Generalize for dungeons as well
local lobby = workspace:WaitForChild("Lobby")
local testDummies = lobby:WaitForChild("TestDummies")

-- Calculate a seed for the server
local jobId = game.JobId
local SERVER_SEED = 0
for i=1, 32 do
	SERVER_SEED = (SERVER_SEED + (string.byte(jobId, i) or 0)) % (256 * 8 - 1)
end

export type NPCAttacker = {
	DisplayName: string;
	Character: Model?;
	AttackStrengthModifier: number;
}

local Combat = {}

local onHit = Instance.new("BindableEvent")
Combat.OnAttacked = onHit.Event

function Combat:Equip(player: Player, weaponType: string?)
	print("Equip", weaponType)

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
end

function equip.OnServerInvoke(player: Player, weaponType: string?)
	Combat:Equip(player, weaponType)
end

local randomObjects = {}

local attackTimers = {}
function useWeapon.OnServerInvoke(player: Player, tool: Tool)
	-- Make sure the player does not attack too quickly
	if attackTimers[player.UserId] then
		-- If player is in the middle of an attack, reject
		if (os.clock() - attackTimers[player.UserId]) < 0 then
			return
		end
	end
	
	-- Grab the character
	local character = player.Character
	if not character then
		return
	end

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

	-- Grab the animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	
	-- Grab Random object
	local random = randomObjects[player]
	if not random then
		random = Random.new(SERVER_SEED + player.UserId)
		randomObjects[player] = random
	end
	
	-- Grab the animations for the tool in use
	CombatClient.AnimationType = CombatClient:GetAnimationType(tool)
	local attackAnimations = CombatClient:GetAttackAnimations()
	if not attackAnimations or not attackAnimations[1] then
		warn("No attacks.")
		return
	end
	
	-- Load all of the animations
	if animator then
		for _, attackAnimation in ipairs(attackAnimations) do
			animator:LoadAnimation(attackAnimation)
		end
	end
	
	-- Select the next attack
	local nextAttack = random:NextInteger(1, #attackAnimations)
	local attackAnimation = attackAnimations[nextAttack]
	if not attackAnimation then
		warn("No attacks.", attackAnimations, nextAttack, attackAnimation)
		return
	end
	
	-- Grab the animation length
	if animator then
		local animationTrack = animator:LoadAnimation(attackAnimation)
		local length = animationTrack.Length
		
		-- Calculate the overall attack speed
		local attackSpeed = (tool:GetAttribute("BaseAttackSpeed") or 1) * PlayerStats:GetAttackSpeedModifier(player)
		
		-- Mark the next attack time for the player after the end of the animation
		attackTimers[player.UserId] = os.clock() + math.max(length / attackSpeed, 0.1)

		-- Hit tracker
		local overlapParams = OverlapParams.new()
		overlapParams.CollisionGroup = tool:GetAttribute("Doita") and "Default" or "Attacks"
		overlapParams.FilterDescendantsInstances = {character}
		overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
		overlapParams.MaxParts = 4

		-- Handle hits
		local hitDuringAttack = {}

		local random = Random.new()

		local activeConnection = onHit.Event:Connect(function(attacker: Player, target: Model)
			if target:IsDescendantOf(testDummies) then
				onDummyHit:FireClient(attacker, target)
			--else
				--attack:InvokeServer(tool, character)
			end
			Combat:HandleAttack(player, tool, target)
		end)

		-- Begin tracking weapon hits
		local handle = tool:WaitForChild("Handle")
		local hitTracker = RunService.Heartbeat:Connect(function()
			local parts: {[number]: BasePart} = workspace:GetPartsInPart(handle, overlapParams)
			for _, part in ipairs(parts) do
				if part:IsDescendantOf(testDummies) or (part.Parent :: BasePart):FindFirstChildWhichIsA("Humanoid") then
					local character = part.Parent
					if not hitDuringAttack[character] then
						hitDuringAttack[character] = true

						onHit:Fire(player, character)
					end
				end
			end
		end)

		-- After the length of the animation stop tracking hits
		task.delay(length - 0.1, function()
			activeConnection:Disconnect()
			hitTracker:Disconnect()
		end)
	end
	
	return nextAttack
end

function Combat:HandleAttack(attacker: Player | NPCAttacker, tool: Tool, target: Model)
	-- Sanity checks
	assert(target and typeof(target) == "Instance" and target:IsA("Model"), "Hit target must be a Model.")
	assert(tool and typeof(tool) == "Instance" and tool:IsA("Tool"), "Tool must be a Tool.")
	if not tool:GetAttribute("Doita") then
		print(tool)
		assert(CollectionService:HasTag(target, "Enemy"), "Target is not an enemy.")
	end

	-- Check that the tool is equipped, and the player has a character
	local character = attacker.Character
	assert(character and tool.Parent == character, "Tool must be equipped.")

	-- Find the attacker's humanoid
	local attackerHumanoid = assert(character:FindFirstChildWhichIsA("Humanoid"), "You cannot attack.")

	-- Find the target's humanoid
	local humanoid = assert(target:FindFirstChildWhichIsA("Humanoid"), "The target is not valid.")
	
	if attacker then
		print(string.format("%s attack %s", attacker.DisplayName, target:GetFullName()))
	end

	-- Check the distance to the root part of the target
	local rootPart = assert(humanoid.RootPart, "The target is not valid.")
	local attackerRootPart = assert(attackerHumanoid.RootPart, "You cannot attack.")
	local targetPosition = rootPart.Position
	local attackerPosition = attackerRootPart.Position

	local distance = (targetPosition - attackerPosition).Magnitude
	assert(distance < CombatHandlerConstants.MAX_ATTACK_DISTANCE, "The target is too far away.")

	-- Calculate base damage, and apply it
	local baseDamage = CombatHandlerConstants.BASE_ATTACK_DAMAGE
	local health = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
	local attackModifier = tool:GetAttribute("BaseAttackModifier") or 1
	if typeof(attacker) == "Instance" and attacker:IsA("Player") then
		attackModifier *= PlayerStats:GetAttackStrengthModifier(attacker)
	else
		attackModifier *= attacker.AttackStrengthModifier
	end
	
	local damageToDeal = baseDamage * attackModifier
	local damageDealt = 0
	if humanoid:GetAttribute("IsDummy") then
		damageDealt = damageToDeal
	else
		if humanoid.Health >= 0 then
			humanoid:TakeDamage(damageToDeal)
		end
		damageDealt = health - math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
		humanoid.Health = humanoid.MaxHealth
	end

	-- If the target has a custom hit callback, trigger it
	local hitCallback = target:FindFirstChild("OnAttacked")
	if hitCallback and hitCallback:IsA("BindableFunction") then
		-- Pass the attacker and the amount of damage dealt
		hitCallback:Invoke(attacker, damageDealt)
	end
	
	if damageDealt > 0 then
		-- Notify players that the attacker dealt damage
		onTargetDamaged:FireAllClients(attacker, target, damageDealt)
	elseif damageDealt < 0 then
		-- Notify that healing has been done
		onTargetHealed:FireAllClients(attacker, target, -damageDealt)
	end
end

--function attack.OnServerInvoke(player: Player, tool: Tool, target: Model)
	
--end

return Combat