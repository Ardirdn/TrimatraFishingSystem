--[[
    PLAYER STATS SERVER
    Place in ServerScriptService/PlayerStatsServer
    
    Handles:
    - Creating leaderstats folder with player stats
    - Displaying Total Fish Caught in player list
    - Updating stats when player catches fish
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- ==================== LEADERSTATS CREATION ====================

local function createLeaderstats(player)
	-- Wait for player data to be ready
	task.wait(2)
	
	local data = DataHandler:GetData(player)
	if not data then
		warn("⚠️ [PLAYER STATS] No data for", player.Name)
		return
	end
	
	-- Check if leaderstats already exists
	local existingLeaderstats = player:FindFirstChild("leaderstats")
	if existingLeaderstats then
		-- Just update values
		local fishCaughtValue = existingLeaderstats:FindFirstChild("Fish")
		if fishCaughtValue then
			fishCaughtValue.Value = data.TotalFishCaught or 0
		end
		return
	end
	
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Total Fish Caught stat (displayed in player list)
	local fishCaughtStat = Instance.new("IntValue")
	fishCaughtStat.Name = "Fish"
	fishCaughtStat.Value = data.TotalFishCaught or 0
	fishCaughtStat.Parent = leaderstats
	
	print(string.format("✅ [PLAYER STATS] Leaderstats created for %s - Fish: %d", 
		player.Name, fishCaughtStat.Value))
end

-- ==================== STAT UPDATE FUNCTIONS ====================

-- Update the fish caught stat in leaderstats
local function updateFishCaughtStat(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local fishCaughtStat = leaderstats:FindFirstChild("Fish")
	if fishCaughtStat then
		fishCaughtStat.Value = data.TotalFishCaught or 0
	end
end

-- ==================== TITLE UPDATE BASED ON FISH CAUGHT ====================

-- Check and update fisherman title based on fish caught
local function checkFishermanTitleUpgrade(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	local totalFishCaught = data.TotalFishCaught or 0
	
	-- Get the appropriate fisherman title
	local newTitle = TitleConfig.GetFishermanTitle(totalFishCaught)
	
	if newTitle then
		-- Check if player has a special title (those override fisherman titles)
		local currentTitle = data.EquippedTitle
		local isSpecialTitle = false
		
		if currentTitle and TitleConfig.SpecialTitles[currentTitle] then
			isSpecialTitle = true
		end
		
		-- Only update if player doesn't have a special title
		if not isSpecialTitle then
			-- Check if this is actually an upgrade
			local currentTitleData = nil
			for _, title in ipairs(TitleConfig.FishermanTitles) do
				if title.Name == currentTitle then
					currentTitleData = title
					break
				end
			end
			
			-- Upgrade if new title has higher requirement
			local shouldUpgrade = false
			if not currentTitleData then
				shouldUpgrade = true
			elseif newTitle.MinFishCaught > currentTitleData.MinFishCaught then
				shouldUpgrade = true
			end
			
			if shouldUpgrade and newTitle.Name ~= currentTitle then
				DataHandler:Set(player, "EquippedTitle", newTitle.Name)
				DataHandler:SavePlayer(player)
				
				-- Notify TitleServer to broadcast the new title
				local TitleUpdateEvent = ReplicatedStorage:FindFirstChild("TitleUpdate")
				if TitleUpdateEvent then
					TitleUpdateEvent:FireAllClients(player.UserId, newTitle.Name)
				end
				
				-- Send notification to player
				local NotificationServer = require(script.Parent.NotificationServer)
				NotificationServer:Send(player, {
					Title = "🎣 New Title!",
					Message = string.format("You earned the title: %s", newTitle.DisplayName),
					Type = "success",
					Duration = 5,
					Icon = newTitle.Icon
				})
				
				print(string.format("🎣 [TITLE] %s earned fisherman title: %s (%d fish)", 
					player.Name, newTitle.DisplayName, totalFishCaught))
			end
		end
	end
end

-- ==================== EVENT CONNECTIONS ====================

-- Player joins
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		createLeaderstats(player)
	end)
end)

-- Handle players who are already in the game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		createLeaderstats(player)
	end)
end

-- ==================== PUBLIC UPDATE FUNCTION ====================

-- This can be called by FishingRewardServer after giving fish
local PlayerStats = {}

function PlayerStats.UpdateFishCaught(player)
	updateFishCaughtStat(player)
	checkFishermanTitleUpgrade(player)
end

function PlayerStats.GetStats(player)
	local data = DataHandler:GetData(player)
	if not data then return nil end
	
	return {
		TotalFishCaught = data.TotalFishCaught or 0,
		DiscoveredFish = data.DiscoveredFish or {},
		FishInventory = data.FishInventory or {}
	}
end

-- ==================== LISTEN FOR FISH CAUGHT ====================

-- Listen for FishCaughtEvent to update stats
local FishCaughtEvent = ReplicatedStorage:WaitForChild("FishCaughtEvent", 10)
if FishCaughtEvent then
	-- Since FishCaughtEvent fires to client, we need a different approach
	-- The FishingRewardServer should call PlayerStats.UpdateFishCaught
end

-- Create a remote for other scripts to trigger stat updates
local UpdateStatsEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerStats")
if not UpdateStatsEvent then
	UpdateStatsEvent = Instance.new("BindableEvent")
	UpdateStatsEvent.Name = "UpdatePlayerStats"
	UpdateStatsEvent.Parent = ReplicatedStorage
end

UpdateStatsEvent.Event:Connect(function(player)
	if player and player.Parent then
		PlayerStats.UpdateFishCaught(player)
	end
end)

print("✅ [PLAYER STATS] Server initialized")

return PlayerStats
