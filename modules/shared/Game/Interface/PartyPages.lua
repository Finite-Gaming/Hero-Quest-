local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UIButton = require("UIButton")
local DUNGEONS = require("DungeonEntries")
local ColorSequenceUtil = require("ColorSequenceUtil")

export type PartyParameters = {
	MapId: string;
	Difficulty: number;
	MaxPlayers: number;
}
export type Party = {
	OwnerId: number, -- The UserID of the party's owner
	UUID: string, -- A unique ID for the party
	Members: {[number]: boolean}, -- A map of user IDs in the party

	Disbanded: boolean?, -- Whether or not the party has been disbanded

	Parameters: PartyParameters
}

local PartyPages = {}
PartyPages.PartyList = {} :: {
	[number]: Party
}
PartyPages.PartiesByUUID = setmetatable({} :: {
	[string]: Party
}, {
	__mode = "v"
})

PartyPages.PageList = {} :: {
	[number]: Instance
}
--PartyPages.UIList = {} :: {
--	[number]: Instance
--}

PartyPages.PartyUIByUUID = {} :: {
	[string]: Instance
}

function PartyPages:Init(initScript)
    -- Configuration
    self._partiesPerPage = initScript:GetAttribute("PartiesPerPage")
    self._difficultyColor = initScript:GetAttribute("DifficultyColor")

    -- GUI
    local gui = initScript.Parent
    self._viewport = gui:WaitForChild("Viewport")
    self._container = self._viewport:WaitForChild("Container")

    -- Get the party list
    self._scroll = self._container:WaitForChild("Scroll")
    self._partyList = self._scroll:WaitForChild("PartyList")

    -- Grab the page template
    self._pageTemplate = self._partyList:WaitForChild("Page")
    self._pageTemplate.Parent = nil

    -- Grab the parties list inside the page template
    self._pageParties = self._pageTemplate:WaitForChild("Parties")

    -- Generate the background
    self._background = self._pageTemplate:WaitForChild("Background")
    self._backgroundItemTemplate = self._background:WaitForChild("PartyBackground")
    self._backgroundItemTemplate.Parent = nil

    for _ = 1, self._partiesPerPage do
        local backgroundItem = self._backgroundItemTemplate:Clone()
        backgroundItem.Parent = self._background
    end

    -- Adjust the grid layout based on the parties per page setting
    local pageBGGridLayout = self._background:WaitForChild("UIGridLayout")
    local pageGridLayout = self._pageParties:WaitForChild("UIGridLayout")
    pageGridLayout.CellSize = UDim2.new(pageGridLayout.CellSize.X, UDim.new(1 / self._partiesPerPage - pageGridLayout.CellPadding.Y.Scale, pageGridLayout.CellSize.Y.Offset))
    pageBGGridLayout.CellSize = pageGridLayout.CellSize

    -- Grab the party partyUI template
    local partyUITemplate = self._pageParties:WaitForChild("Party")
    partyUITemplate.Parent = nil

    -- Grab the page layout for the party list so we can implement switching pages
    local partyPageLayout = self._partyList:WaitForChild("UIPageLayout")

    local partyJoin = Instance.new("BindableEvent")
    local partyStart = Instance.new("BindableEvent")

    PartyPages.PartyJoined = partyJoin.Event
    PartyPages.PartyStarted = partyStart.Event

    self._isUpdating = false
    self._finishedUpdating = Instance.new("BindableEvent")

    -- Create first page
    self:NewPage()
end


function PartyPages:_updateLock(locked)
    if locked then
        while self._isUpdating do
            self._finishedUpdating.Event:Wait()
        end
        self._isUpdating = true
    else
        self._isUpdating = false
        self._finishedUpdating:Fire()
    end
end

function PartyPages:SetParties(parties: {[number]: Party})
	-- Create a map of new party UUIDs to parties
	--local newPartiesByUUID = {}
	--print("Updating parties list.")
	--for _, party in ipairs(parties) do
	--	print(" ", party.UUID)
	--	newPartiesByUUID[party.UUID] = party
	--end
	
	--print("Collecting removed parties.")
	-- Collect all parties not in the new list
	--local partiesToRemove = {}
	--for _, party in ipairs(self.PartyList) do
	--	if not newPartiesByUUID[party.UUID] then
	--		print(" ", party.UUID)
	--		table.insert(partiesToRemove, party)
	--	end
	--end

	--print("Collecting new parties.")
	-- Collect all new parties
	--local partiesToAdd = {}
	--for _, party in ipairs(parties) do
	--	if not self.PartyUIByUUID[party.UUID] then
	--		print(" ", party.UUID)
	--		table.insert(partiesToAdd, party)
	--	end
	--end
	
	--print("Updating parties")
	
	-- Remove all parties
	self:RemoveParties(self.PartyList, true)
	
	-- Remove all party UIs
	for uuid, partyUI in pairs(self.PartyUIByUUID) do
		partyUI:Destroy()
		self.PartyUIByUUID[uuid] = nil
	end
	--self.UIList = {}
	
	-- Add the new parties
	self:AddParties(parties, true)
	
	-- Update party list
	self.PartyList = parties

	--print("Re-rendering...")

	-- Re-render the parties list
	PartyPages:Render()
	
	--print("Finished.")
end

function PartyPages:AddParties(parties: {[number]: Party}, noRender: boolean?)
	if #parties <= 0 then
		return
	end
	
	self:_updateLock(true)
	-- Copy the parties into PartyList
	--table.move(parties, 1, #parties, #self.PartyList + 1, self.PartyList)
	--print(string.format("Adding %d parties.", #parties))
	for _, party in ipairs(parties) do
		if not self.PartiesByUUID[party.UUID] then
			self.PartiesByUUID[party.UUID] = party
			
			if not table.find(self.PartyList, party) then
				table.insert(self.PartyList, party)
			end
		end

		-- Create party partyUI
		PartyPages:GetPartyUI(party)
	end
	self:_updateLock(false)
	
	if not noRender then
		-- Re-render the parties list
		PartyPages:Render()
	end
end
function PartyPages:RemoveParties(parties: {[number]: Party}, noRender: boolean?)
	if #parties <= 0 then
		return
	end
	
	self:_updateLock(true)
	--print(string.format("Removing %d parties.", #parties))
	for _, party in ipairs(parties) do
		self.PartiesByUUID[party.UUID] = nil
		
		local partyUI = self.PartyUIByUUID[party.UUID]
		if partyUI then
			--print("Removing partyUI", party.UUID, partyUI:GetFullName())
			--local uiIndex = table.find(self.UIList, partyUI)
			--if uiIndex then
			--	table.remove(self.UIList, uiIndex)
			--end
			partyUI:Destroy()
		end
		self.PartyUIByUUID[party.UUID] = nil
		
		local partyIndex = table.find(self.PartyList, party)
		if partyIndex then
			table.remove(self.PartyList, partyIndex)
		end
	end
	self:_updateLock(false)
	
	if not noRender then
		-- Re-render the parties list
		PartyPages:Render()
	end
end

function PartyPages:AddParty(party: Party)
	self:AddParties({party})
end
function PartyPages:RemoveParty(party: Party)
	self:RemoveParties({party})
end

function PartyPages:Next()
	self._partyPageLayout:Next()
end
function PartyPages:Previous()
	self._partyPageLayout:Previous()
end
function PartyPages:JumpTo(page: number)
	self._partyPageLayout:JumpToIndex(page)
end

function PartyPages:NewPage(): Instance
	local page = self._pageTemplate:Clone()
	page.Parent = self._partyList
	table.insert(self.PageList, page)
	return page
end

function PartyPages:GetDifficultyDisplay(difficulty: number): (string, Color3)
	-- Easy = 0
	-- Medium = 1
	-- Hard = 2
	-- Extreme = 3
	-- Extreme+ = 4+
	
	local difficulties = {
		"Easy",
		"Medium",
		"Hard",
		"Extreme",
		"Extreme+"
	}
	
	local difficultyName = difficulties[difficulty + 1] or difficulties[#difficulties]
	local color = ColorSequenceUtil:ValueAt(self._difficultyColor, difficulty / #difficulties)
	
	return string.format("%s (Lvl %d)", difficultyName, difficulty), color
end

PartyPages.JoinsEnabled = true

local joinButtons = {}

function PartyPages:EnableJoins()
	self.JoinsEnabled = true
	for _, button in ipairs(joinButtons) do
		UIButton:Enable(button)
	end
end
function PartyPages:DisableJoins()
	self.JoinsEnabled = false
	for _, button in ipairs(joinButtons) do
		UIButton:Disable(button)
	end
end

function PartyPages:GetPartyUI(party: Party): Instance
	local partyUI = self.PartyUIByUUID[party.UUID]
	if partyUI then
		-- Delete existing UI
		partyUI:Destroy()
	end
	
	-- Clone from the template
	partyUI = self._partyUITemplate:Clone()

	-- Add the partyUI
	self.PartyUIByUUID[party.UUID] = partyUI

	local joinButton = partyUI:WaitForChild("Join")
	joinButton.Activated:Connect(function()
		if party.OwnerId ~= Players.LocalPlayer.UserId then
			self._partyJoin:Fire(party)
		else
			self._partyStart:Fire()
		end
	end)
	
	local index = table.find(joinButtons, joinButton)
	if party.OwnerId ~= Players.LocalPlayer.UserId then
		if not index then
			table.insert(joinButtons, joinButton)
		end
	elseif index then
		table.remove(joinButtons, index)
	end
	
	local partyParameters = party.Parameters
	
	local dungeonId = partyParameters.MapId
	local DUNGEON = DUNGEONS[dungeonId]
	
	local mapName = DUNGEON and DUNGEON.Name or "???" -- "Haunted Castle"
	local difficultyLevel = partyParameters.Difficulty or 0
	local maxPlayers = math.min(partyParameters.MaxPlayers or math.huge, DUNGEON and DUNGEON.maxPlayers or -1) --10

	-- Count members
	local memberCount = 0
	for userId, _ in pairs(party.Members) do
		memberCount += 1
	end
	
	-- Update the user icon
	local userIcon = partyUI:WaitForChild("UserIcon")
	local icon = userIcon:WaitForChild("Icon")
	icon.Image = Players:GetUserThumbnailAsync(party.OwnerId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)

	-- Update the title
	local title = partyUI:WaitForChild("Title")
	title.Text = string.format("%s's Party", Players:GetNameFromUserIdAsync(party.OwnerId) or "???")
	
	-- Update the map
	local map = partyUI:WaitForChild("Map")
	map.Text = string.format("%s", mapName)

	-- Update the difficulty
	local difficulty = partyUI:WaitForChild("Difficulty")
	local difficultyText, difficultyColor = self:GetDifficultyDisplay(difficultyLevel)

	difficulty.Text = difficultyText
	difficulty.TextColor3 = difficultyColor
	
	-- Update the join button
	local joinButton = partyUI:WaitForChild("Join")
	local label = joinButton:WaitForChild("Label")
	
	if party.OwnerId ~= Players.LocalPlayer.UserId then
		label.Text = string.format("Join (%d/%d)", memberCount, maxPlayers)
		
		if self.JoinsEnabled then
			UIButton:Enable(joinButton)
		else
			UIButton:Disable(joinButton)
		end
	else
		label.Text = string.format("Start dungeon (%d/%d)", memberCount, maxPlayers)
	end
	return partyUI
end

-- Renders the entire party list
function PartyPages:Render()
	self:_updateLock(true)
	-- Remove each party partyUI
	for _, partyUI in pairs(self.PartyUIByUUID) do
		partyUI.Parent = nil
	end
	
	-- Populate all pages with parties
	local pageCount = 0
	local uiCounter = 0
	for _, partyUI in pairs(self.PartyUIByUUID) do
		-- Grab the next page
		local page = self.PageList[pageCount + 1] or self:NewPage()
		
		-- Add partyUI to page & increment counter
		partyUI.Parent = page:WaitForChild("Parties")
		uiCounter += 1
		
		-- If enough UIs were added to fill the page, go to the next one
		if uiCounter >= self._partiesPerPage then
			-- Reset counter
			uiCounter = 0
			
			-- Next page
			pageCount += 1
		end
	end
	if uiCounter > 0 then
		pageCount += 1
	end
	
	-- If there are more pages than needed, remove the extras
	if #self.PageList > pageCount then
		-- Next page
		pageCount += 1
		
		-- Delete extra pages
		while self.PageList[pageCount] do
			-- Only page left, stop deleting
			if not self.PageList[2] then
				break
			end
			
			-- Remove & delete the page
			local page = table.remove(self.PageList, pageCount)
			page:Destroy()
		end
	end
	self:_updateLock(false)
end

--partiesAdded.Event:Connect(function(parties, noRender)
--	if not noRender then
--		-- Re-render the parties list
--		PartyPages:Render()
--	end
--end)
--partiesRemoved.Event:Connect(function(parties, noRender)
--	--for _, party in ipairs(parties) do
--	--	-- Find the relevant party partyUI & delete it
--	--	local partyUI = PartyPages.PartyUIByUUID[party.UUID]
--	--	if partyUI then
--	--		-- Grab the button and remove it from the buttons list
--	--		local button = partyUI:FindFirstChild("Join")
--	--		if button then
--	--			local buttonIndex = table.find(joinButtons, button)
--	--			if buttonIndex then
--	--				table.remove(joinButtons, buttonIndex)
--	--			end
--	--		end
			
--	--		-- Destroy the partyUI
--	--		partyUI:Destroy()
			
--	--		-- Delete the party partyUI entry in the UUID -> party partyUI map
--	--		PartyPages.PartyUIByUUID[party.UUID] = nil

--	--		-- Remove the partyUI from the partyUI list, if it exists
--	--		local uiIndex = table.find(PartyPages.UIList, partyUI)
--	--		if uiIndex then
--	--			table.remove(PartyPages.UIList, uiIndex)
--	--		end
--	--	end
--	--end

--	if not noRender then
--		-- Re-render the parties list
--		PartyPages:Render()
--	end
--end)

return PartyPages