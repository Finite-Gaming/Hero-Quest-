--!strict
-- Configuration

-- Defines a set of armor that can be equipped on a character
export type ArmorSet = {
	LeftUpperArm: PVInstance;	Head: PVInstance;		RightUpperArm: PVInstance;
	LeftLowerArm: PVInstance;	UpperTorso: PVInstance;	RightLowerArm: PVInstance;
	LeftHand: PVInstance;		LowerTorso: PVInstance; RightHand: PVInstance;
	
	LeftUpperLeg: PVInstance;							RightUpperLeg: PVInstance;
	LeftLowerLeg: PVInstance;							RightLowerLeg: PVInstance;
	LeftFoot: PVInstance;								RightFoot: PVInstance;
}
-- Defines a set of armor that has already been equipped on a character
export type EquippedArmorSet = ArmorSet -- An alias for ArmorSet to better distinguish between an equipped set of armor and a non-equipped one
-- A simple name to describe specifically a player's character Model, not a unique type
export type Character = Model -- An alias for Model (for additional context)

local ArmorService = {}

-- If you are reading this script to determine how to make armor, when creating new armor, do not use these names.
--   Instead, use the real part names you want to target. Your armor pieces can be Models containing parts, or simply can be parts themselves.
-- TODO: Replace armor mappings with true names when building armor models
--  (Implies some kind of guidelines around creating new armor)
--local legacyMappings = {
--	LUA = "LeftUpperArm";	H = "Head";			RUA = "RightUpperArm";
--	LLA = "LeftLowerArm";	CH = "UpperTorso";	RLA = "RightLowerArm";
--	LH = "LeftHand";		W = "LowerTorso";	RH = "RightHand";
	
--	LUL = "LeftUpperLeg";						RUL = "RightUpperLeg";
--	LLL = "LeftLowerLeg";						RLL = "RightLowerLeg";
--	LF = "LeftFoot";							RF = "RightFoot";
--}

-- Takes an armor model and produces an ArmorSet from it
-- Requires that the model contain named Models or parts to associate with the character's bodyparts (e.g. Head)
function ArmorService:GenerateArmorSet(armor: Model): ArmorSet
	local armorSet: ArmorSet = {} :: ArmorSet
	
	-- Search through the armor model for various pieces
	for _, piece in ipairs(armor:GetDescendants()) do
		if piece:IsA("Model") or piece.Parent == armor then
			local pieceName = piece.Name
			
			-- If there is a legacy mapping for the armor piece, use that
			--if legacyMappings[pieceName] then
			--	pieceName = legacyMappings[pieceName]
			--end
			
			-- Insert the piece into the armor set
			armorSet[pieceName] = piece
		end
	end
	
	return armorSet
end

-- Takes a folder or some other instance containing named Models containing a valid set of armor pieces
--  Returns a named list of those new ArmorSets
function ArmorService:GenerateArmorSets(armorSetFolder: Instance): {[string]: ArmorSet}
	local armorSets = {} :: {[string]: ArmorSet}
	-- Go over all the armor pieces in the folder, and produce ArmorSets from them
	for _, armor in ipairs(armorSetFolder:GetChildren()) do
		if armor:IsA("Model") then
			-- Generate an ArmorSet and store it in the map of armor sets
			armorSets[armor.Name] = self:GenerateArmorSet(armor)
		end
	end
	return armorSets
end

-- Removes player accessories (& body parts)
--  TODO: If Armor armor correctly, consider keep body parts?
function ArmorService:CleanHumanoidDescription(character: Character)
	-- Wait for a Humanoid to be added
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	while not humanoid do
		character.ChildAdded:Wait()
		humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	end
	
	local description = humanoid:GetAppliedDescription()
	
	local userAvatarDescription = humanoid:FindFirstChild("UserAvatarDescription")
	if not userAvatarDescription then
		-- Clone the user's current description
		userAvatarDescription = description:Clone()
		userAvatarDescription.Name = "UserAvatarDescription"
		userAvatarDescription.Parent = humanoid
	end
	
	-- Clear their body parts
	description.Head = 0
	description.Torso = 0
	description.LeftArm = 0
	description.RightArm = 0
	description.LeftLeg = 0
	description.RightLeg = 0

	description.HeadColor = Color3.new()
	description.TorsoColor = Color3.new()
	description.LeftArmColor = Color3.new()
	description.RightArmColor = Color3.new()
	description.LeftLegColor = Color3.new()
	description.RightLegColor = Color3.new()

	description.Pants = 0
	description.Shirt = 0
	description.GraphicTShirt = 0
	
	-- Clear their accessories
	description:SetAccessories({}, true)
	
	-- Apply the new description
	humanoid:ApplyDescription(description)
end

-- Removes any and all armor from a character
function ArmorService:ClearCharacterArmor(character: Character)
	for _, armorPiece in ipairs(character:GetDescendants()) do
		-- If this is an armor piece
		if armorPiece:GetAttribute("ArmorType") then
			-- Delete it
			armorPiece:Destroy()
		end
	end
end

-- Unequips a specific equipped armor set
function ArmorService:UnequipArmorSet(equippedArmorSet: EquippedArmorSet)
	for pieceName, piece in pairs(equippedArmorSet) do
		-- Equipped armor pieces will not be archivable
		-- If a regular ArmorSet is passed, this will avoid clearing it
		if not piece.Archivable then
			-- Delete the armor piece
			piece:Destroy()
		else
			warn(string.format("Armor piece %s is not equipped. Did you pass a regular ArmorSet by accident?", pieceName))
		end
	end
end

-- Connects two parts together
local function joinParts(part0: BasePart, part1: BasePart): Weld
	local weld = Instance.new("Weld")
	
	-- Calculate C0
	weld.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	
	-- Connect both parts
	weld.Part0 = part0
	weld.Part1 = part1
	
	-- Parent the weld to Part0
	weld.Parent = part0
	
	return weld
end

-- Animates the insertion of the armor
-- This code can delay the insertion of other armor pieces if it desires, and can spawn its own threads to animate the armor
function ArmorService:AnimateArmorEquip(armorSet: ArmorSet, character: Character, armorPiece: PVInstance)
	-- TODO: Implement an animation of some sort
	-- TODO: Consider allowing equip animations to be defined per ArmorSet
	-- 		This would require either assigning a function on the
	-- 		 ArmorSet type to handle this, or allowing animations to be defined here by name (and specifying on the ArmorSet type)
	
end

-- A map of characters to listeners that watch for changes to the character's parts
local characterChangeListeners = setmetatable({}, {
	__mode = "kv"
})

-- Gets the bounding box of the target PVInstance
local function getSize(object: PVInstance): Vector3?
	local size
	if typeof(object) == "Instance" then
		if object:IsA("Model") then
			-- Pick the second argument
			size = select(2, object:GetBoundingBox())
		elseif object:IsA("BasePart") then
			size = object.Size
		end
	end
	return size
end

-- Rescales the target's bounding box and contents to match the source's bounding box
local function rescale(target: PVInstance, source: PVInstance?, sizeOffset: Vector3?)
	local targetSize, sourceSize = getSize(target), source and getSize(source) or nil
	
	local origin = target:GetPivot()
	local function reshapeTargetPart(targetPart: BasePart, scaleFactor: Vector3)
		-- Determine the target's pivot point
		local targetPivot = targetPart:GetPivot()
		
		-- Calculate the offset, then scale it
		local targetOffset = targetPivot.Position - origin.Position
		targetOffset *= scaleFactor
		
		-- Scale the target
		targetPart.Size *= scaleFactor
		
		-- Move the target
		targetPart:PivotTo(CFrame.fromMatrix(targetOffset + origin.Position, targetPivot.XVector, targetPivot.YVector, targetPivot.ZVector))
	end
	
	if targetSize and sourceSize then
		local scaleFactor = (sourceSize + (sizeOffset or Vector3.new())) / targetSize
		
		-- If the target is a part, reshape it
		if target:IsA("BasePart") then
			reshapeTargetPart(target, scaleFactor)
		end
		-- Reshape all of the parts in the target
		for _, part in ipairs(target:GetDescendants()) do
			if part:IsA("BasePart") then
				reshapeTargetPart(part, scaleFactor)
			end
		end
	end
end

-- Applies armor to a character
function ArmorService:ApplyArmorToCharacter(armorSet: ArmorSet, character: Character): EquippedArmorSet
	-- Keep track of the equipped armor pieces
	local equippedArmorSet: EquippedArmorSet = {} :: EquippedArmorSet
	
	-- If there's an existing listener, disconnect it
	if characterChangeListeners[character] then
		characterChangeListeners[character]:Disconnect()
	end
	
	-- Clear out any equipped armor
	self:ClearCharacterArmor(character)
	
	-- A map of targeted armor piece names
	local equippedArmorPieces = {}
	
	-- Equips an armor piece
	local function equipArmorPiece(pieceName: string, armorTarget: PVInstance, equippedPiece: PVInstance)
		-- Break any connections the piece may have
		-- Note: We use an elseif here to satisfy the typechecker (It recognizes both :BreakJoints() methods as completely separate functions)
		if equippedPiece:IsA("Model") then
			equippedPiece:BreakJoints()
		elseif equippedPiece:IsA("BasePart") then
			equippedPiece:BreakJoints()
		end
		
		-- Make the piece non-archiveable, so it can't be :Clone()d and we can distinguish it from other pieces
		equippedPiece.Archivable = false
		
		-- Anchor all of the parts in the piece we're equipping while we work with it
		if equippedPiece:IsA("BasePart") then
			equippedPiece.Anchored = true
		end
		for _, part in ipairs(equippedPiece:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		-- Mark the armor target
		equippedArmorPieces[pieceName] = equippedPiece

		-- Find any part in the target we can connect things to
		local mainPart = if armorTarget:IsA("BasePart") then armorTarget else armorTarget:FindFirstChildWhichIsA("BasePart", true)
		assert(mainPart, string.format("Armor target for %s doesn't have any parts and therefore armor can't be equipped to it", pieceName))

		-- Anchor the target while we connect pieces to it
		mainPart.Anchored = true

		-- Move the piece to the target
		equippedPiece:PivotTo(armorTarget:GetPivot())
		-- TODO: Rescale the equipped piece to the armor target
		-- TODO/NOTE: This requires a reference part be defined inside the model. Consider this?
		--rescale(equippedPiece, armorTarget, armorThickness)

		local function handleArmorPiece(pieceName: string, characterPart: BasePart, armorPiece: BasePart)
			-- Join the armor part to the root
			joinParts(armorPiece, characterPart)

			-- Set the armor piece massless so it doesn't weigh down the character or cause physics issues
			armorPiece.Massless = true
			
			-- Remove collisions, queries, and touches from the armor
			armorPiece.CanCollide = false
			armorPiece.CanTouch = false
			armorPiece.CanQuery = false

			-- Unanchor the armor piece
			armorPiece.Anchored = false

			-- Set the armor type so we know this is armor
			armorPiece:SetAttribute("ArmorType", pieceName)
		end
		
		-- Set the armor type of the equipped armor piece
		equippedPiece:SetAttribute("ArmorType", pieceName)

		-- If the piece we're equipping is a part, we want to connect it to the main part we are targeting in the character
		if equippedPiece:IsA("BasePart") then
			handleArmorPiece(pieceName, mainPart, equippedPiece)
		end

		-- Connect all parts inside the equipped piece to the main part we are targeting in the character
		for _, part in ipairs(equippedPiece:GetDescendants()) do
			if part:IsA("BasePart") then
				handleArmorPiece(pieceName, mainPart, part)
			end
		end

		-- Defer and put the armor piece into the character
		task.defer(function()
			pcall(function() equippedPiece.Parent = armorTarget end)
		end)

		-- Add the piece to the set of equipped armor pieces
		equippedArmorSet[pieceName] = equippedPiece

		-- Unanchor the target now that we are done
		mainPart.Anchored = false

		-- Animate the insertion
		self:AnimateArmorEquip(armorSet, character, equippedPiece)
	end
	
	local function createEquippedPiece(pieceName: string, piece: PVInstance): PVInstance?
		assert(typeof(piece) == "Instance", string.format("Armor piece %s is not an instance so it can't be equipped", pieceName))
		assert(piece:IsA("PVInstance"), string.format("Armor piece %s is not actually a valid piece of armor. It needs to be any part or a Model (a PVInstance).", pieceName))
		
		local equippedPiece = piece:Clone()
		if equippedPiece then
			return equippedPiece
		else
			warn(string.format("Armor piece %s is not equippable. Did you pass an EquippedArmorSet by accident?", pieceName))
		end
		return nil
	end
	
	-- When something is added to the character, we may want to reconfigure armor pieces
	characterChangeListeners[character] = character.ChildAdded:Connect(function(child)
		if child:IsA("PVInstance") then
			local pieceName = child.Name
			
			-- If the piece is part of the ArmorSet, we might need to create an equipped version
			if armorSet[pieceName] then
				-- If the eqipped piece doesn't exist yet
				if not equippedArmorPieces[pieceName] then
					-- Create an equipped version of the piece
					local equippedPiece = createEquippedPiece(pieceName, armorSet[pieceName])
					if equippedPiece then
						equippedArmorPieces[pieceName] = equippedPiece
					end
				end
			end
			
			-- If there's an armor piece, re-equip to the new target
			if equippedArmorPieces[pieceName] then
				equipArmorPiece(pieceName, child, equippedArmorPieces[pieceName])
			end
		end
	end)
	
	-- For all the pieces in the armor set, create a copy for the player to wear, and attach them all.
	-- Then we can keep track of them in the equippedArmorSet.
	task.spawn(function()
		for pieceName, piece in pairs(armorSet) do
			local armorTarget = character:FindFirstChild(pieceName)
			
			-- If the character has the armor piece's target
			if armorTarget then
				assert(armorTarget:IsA("PVInstance"), string.format("%s is not a valid target for any armor pieces", pieceName))
				
				local equippedPiece = createEquippedPiece(pieceName, armorSet[pieceName])
				if equippedPiece then
					equipArmorPiece(pieceName, armorTarget, equippedPiece)
				end
			end
		end
		
		-- Wait until the character is in the DataModel
		while not character:IsDescendantOf(game) do
			character.AncestryChanged:Wait()
		end

		-- Clean up their avatar so we can apply armor without pieces intersecting or causing visual issues
		self:CleanHumanoidDescription(character)
	end)
	
	-- Return the set of equipped pieces
	return equippedArmorSet
end

return ArmorService