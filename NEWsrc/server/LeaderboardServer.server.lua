--[[
    LEADERBOARD SERVER (MODULAR)
    Place in ServerScriptService/LeaderboardServer
    
    Handles ALL leaderboards from workspace.Leaderboards folder:
    - SummitLeaderboard
    - SpeedrunLeaderboard  
    - PlaytimeLeaderboard
    - DonationLeaderboard
    
    Features:
    - Supports multiple copies of the same leaderboard type
    - Auto-updates all copies when data changes
    - Structure: Leaderboards > [Type]Leaderboard > Screen > SurfaceGui > ScrollingFrame > Sample
    - Uses centralized DataStoreConfig for consistent datastore names
    
    NAMING CONVENTION:
    - SummitLeaderboard, SummitLeaderboard (1), SummitLeaderboard (2), etc.
    - Or any name starting with "Summit", "Speedrun", "Playtime", "Donation"
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ✅ USE CENTRALIZED CONFIG
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

-- DataStores (from centralized config)
local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

print(string.format("📊 [LEADERBOARD SERVER] Using DataStores: Summit=%s", DataStoreConfig.Leaderboards.Summit))

-- Config
local CONFIG = {
	UPDATE_INTERVAL = 60,       -- Seconds between auto-updates
	MAX_ENTRIES = 10,           -- Top 10 players
	INITIAL_DELAY = 5,          -- Delay before first update
}

-- Wait for Leaderboards folder
local leaderboardsFolder = workspace:WaitForChild("Leaderboards", 10)
if not leaderboardsFolder then
	warn("[LEADERBOARD SERVER] ❌ Leaderboards folder not found in Workspace!")
	return
end

print("[LEADERBOARD SERVER] ✅ Leaderboards folder found")

--===========================================
-- UTILITY FUNCTIONS
--===========================================

-- Format time for speedrun (HH:MM:SS.mmm)
local function formatSpeedrunTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)
	return string.format("%02d:%02d:%02d.%03d", hours, minutes, secs, ms)
end

-- Format playtime (1d 2h 3m or 2h 3m 4s)
local function formatPlaytime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if days > 0 then
		return string.format("%dd %dh %dm", days, hours, minutes)
	elseif hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

-- Get player name from UserId with caching
local playerNameCache = {}
local function getPlayerName(userId)
	if playerNameCache[userId] then
		return playerNameCache[userId]
	end
	
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	
	if success and name then
		playerNameCache[userId] = name
		return name
	end
	
	return "Player"
end

-- Detect leaderboard type from name
local function getLeaderboardType(name)
	local lowerName = name:lower()
	
	if lowerName:match("summit") then
		return "Summit"
	elseif lowerName:match("speedrun") then
		return "Speedrun"
	elseif lowerName:match("playtime") then
		return "Playtime"
	elseif lowerName:match("donation") or lowerName:match("donate") then
		return "Donation"
	end
	
	return nil
end

-- Find all leaderboards of a specific type
local function findAllLeaderboardsOfType(leaderboardType)
	local found = {}
	
	for _, child in pairs(leaderboardsFolder:GetDescendants()) do
		-- Check if this is a container with a Screen child
		if child:IsA("BasePart") or child:IsA("Model") then
			local detectedType = getLeaderboardType(child.Name)
			
			if detectedType == leaderboardType then
				local screen = child:FindFirstChild("Screen")
				if screen then
					local surfaceGui = screen:FindFirstChild("SurfaceGui")
					if surfaceGui then
						local scrollingFrame = surfaceGui:FindFirstChild("ScrollingFrame")
						if scrollingFrame then
							local sample = scrollingFrame:FindFirstChild("Sample")
							if sample then
								table.insert(found, {
									Container = child,
									Screen = screen,
									SurfaceGui = surfaceGui,
									ScrollingFrame = scrollingFrame,
									Sample = sample
								})
							end
						end
					end
				end
			end
		end
	end
	
	return found
end

-- Clear existing entries in a scrolling frame
local function clearEntries(scrollingFrame)
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Sample" then
			child:Destroy()
		end
	end
end

-- Populate a single leaderboard with entries
local function populateLeaderboard(leaderboardData, entries, leaderboardType)
	local scrollingFrame = leaderboardData.ScrollingFrame
	local sample = leaderboardData.Sample
	
	-- Ensure sample is hidden
	sample.Visible = false
	
	-- Clear old entries
	clearEntries(scrollingFrame)
	
	-- Create new entries
	for rank, entry in ipairs(entries) do
		local newFrame = sample:Clone()
		newFrame.Name = "Entry" .. rank
		newFrame.Visible = true
		newFrame.LayoutOrder = rank
		
		-- Set Rank
		local rankLabel = newFrame:FindFirstChild("Rank")
		if rankLabel then
			rankLabel.Text = "#" .. rank
		end
		
		-- Set Player Name
		local nameLabel = newFrame:FindFirstChild("PlayerName")
		if nameLabel then
			nameLabel.Text = entry.displayName
		end
		
		-- Set Value based on type
		if leaderboardType == "Summit" then
			local valueLabel = newFrame:FindFirstChild("Summits") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = tostring(entry.value)
			end
			
		elseif leaderboardType == "Speedrun" then
			local valueLabel = newFrame:FindFirstChild("Time") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = entry.formattedValue
			end
			
		elseif leaderboardType == "Playtime" then
			local valueLabel = newFrame:FindFirstChild("Playtime") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = entry.formattedValue
			end
			
		elseif leaderboardType == "Donation" then
			local valueLabel = newFrame:FindFirstChild("Amount") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = "R$" .. tostring(entry.value)
			end
		end
		
		newFrame.Parent = scrollingFrame
	end
end

--===========================================
-- UPDATE FUNCTIONS
--===========================================

local function updateSummitLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Summit")
	if #leaderboards == 0 then return end
	
	-- Fetch data once
	local success, data = pcall(function()
		return SummitLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)
	
	if not success then
		warn("[LEADERBOARD] Failed to fetch Summit data")
		return
	end
	
	local page = data:GetCurrentPage()
	local entries = {}
	
	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		
		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = entry.value
		})
	end
	
	-- Update all copies
	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Summit")
	end
	
	print(string.format("[LEADERBOARD] Summit updated - %d entries to %d boards", #entries, #leaderboards))
end

local function updateSpeedrunLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Speedrun")
	if #leaderboards == 0 then return end
	
	-- Fetch data once (stored as negative for ascending order)
	local success, data = pcall(function()
		return SpeedrunLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)
	
	if not success then
		warn("[LEADERBOARD] Failed to fetch Speedrun data")
		return
	end
	
	local page = data:GetCurrentPage()
	local entries = {}
	
	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		local timeMs = math.abs(entry.value)
		local timeSeconds = timeMs / 1000
		
		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = timeMs,
			formattedValue = formatSpeedrunTime(timeSeconds)
		})
	end
	
	-- Update all copies
	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Speedrun")
	end
	
	print(string.format("[LEADERBOARD] Speedrun updated - %d entries to %d boards", #entries, #leaderboards))
end

local function updatePlaytimeLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Playtime")
	if #leaderboards == 0 then return end
	
	-- Fetch data once
	local success, data = pcall(function()
		return PlaytimeLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)
	
	if not success then
		warn("[LEADERBOARD] Failed to fetch Playtime data")
		return
	end
	
	local page = data:GetCurrentPage()
	local entries = {}
	
	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		local playtime = entry.value
		
		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = playtime,
			formattedValue = formatPlaytime(playtime)
		})
	end
	
	-- Update all copies
	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Playtime")
	end
	
	print(string.format("[LEADERBOARD] Playtime updated - %d entries to %d boards", #entries, #leaderboards))
end

local function updateDonationLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Donation")
	if #leaderboards == 0 then return end
	
	-- Fetch data once
	local success, data = pcall(function()
		return DonationLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)
	
	if not success then
		warn("[LEADERBOARD] Failed to fetch Donation data")
		return
	end
	
	local page = data:GetCurrentPage()
	local entries = {}
	
	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		
		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = entry.value
		})
	end
	
	-- Update all copies
	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Donation")
	end
	
	print(string.format("[LEADERBOARD] Donation updated - %d entries to %d boards", #entries, #leaderboards))
end

-- Update ALL leaderboards
local function updateAllLeaderboards()
	print("[LEADERBOARD] Starting full leaderboard update...")
	
	updateSummitLeaderboards()
	updateSpeedrunLeaderboards()
	updatePlaytimeLeaderboards()
	updateDonationLeaderboards()
	
	print("[LEADERBOARD] ✅ Full leaderboard update complete")
end

--===========================================
-- DYNAMIC DETECTION
--===========================================

-- Watch for new leaderboards being added to the folder
leaderboardsFolder.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "Sample" and descendant:IsA("Frame") then
		task.wait(0.5) -- Wait for structure to be complete
		print("[LEADERBOARD] New leaderboard detected, triggering update...")
		updateAllLeaderboards()
	end
end)

--===========================================
-- AUTO UPDATE LOOP
--===========================================

task.spawn(function()
	-- Initial delay
	task.wait(CONFIG.INITIAL_DELAY)
	
	-- Initial update
	updateAllLeaderboards()
	
	-- Periodic updates
	while true do
		task.wait(CONFIG.UPDATE_INTERVAL)
		updateAllLeaderboards()
	end
end)

--===========================================
-- LOG DISCOVERED LEADERBOARDS
--===========================================

task.defer(function()
	task.wait(1)
	
	local types = {"Summit", "Speedrun", "Playtime", "Donation"}
	
	print("[LEADERBOARD] === Discovered Leaderboards ===")
	for _, leaderboardType in ipairs(types) do
		local found = findAllLeaderboardsOfType(leaderboardType)
		if #found > 0 then
			print(string.format("  • %s: %d board(s)", leaderboardType, #found))
			for i, data in ipairs(found) do
				print(string.format("      %d. %s", i, data.Container:GetFullName()))
			end
		else
			print(string.format("  • %s: None found", leaderboardType))
		end
	end
	print("[LEADERBOARD] ================================")
end)

--===========================================
-- EXTERNAL REFRESH TRIGGER (BindableEvent)
--===========================================
local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
if not refreshEvent then
	refreshEvent = Instance.new("BindableEvent")
	refreshEvent.Name = "RefreshLeaderboardsEvent"
	refreshEvent.Parent = game.ServerScriptService
end

-- Listen for external refresh requests
refreshEvent.Event:Connect(function(leaderboardType)
	if leaderboardType == "Summit" then
		print("[LEADERBOARD] 📊 External refresh triggered: Summit")
		updateSummitLeaderboards()
	elseif leaderboardType == "Donation" then
		print("[LEADERBOARD] 📊 External refresh triggered: Donation")
		updateDonationLeaderboards()
	elseif leaderboardType == "Playtime" then
		print("[LEADERBOARD] 📊 External refresh triggered: Playtime")
		updatePlaytimeLeaderboards()
	elseif leaderboardType == "Speedrun" then
		print("[LEADERBOARD] 📊 External refresh triggered: Speedrun")
		updateSpeedrunLeaderboards()
	elseif leaderboardType == "All" or leaderboardType == nil then
		print("[LEADERBOARD] 📊 External refresh triggered: All leaderboards")
		updateAllLeaderboards()
	end
end)

print("[LEADERBOARD SERVER] ✅ Initialized - Waiting for leaderboards folder...")
print("[LEADERBOARD SERVER] ✅ RefreshLeaderboardsEvent created for external triggers")
