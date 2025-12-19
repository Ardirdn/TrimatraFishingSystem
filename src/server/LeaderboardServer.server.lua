--[[
    LEADERBOARD SERVER
    Place in ServerScriptService/LeaderboardServer
    
    Handles:
    - OrderedDataStore for Fish Caught leaderboard
    - Periodic updates to leaderboard displays
    - Player data synchronization
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DataHandler = require(script.Parent.DataHandler)
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

-- OrderedDataStores for leaderboards
local FishCaughtLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.FishCaught)
local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

-- ==================== LEADERBOARD UPDATE FUNCTIONS ====================

-- Update a player's fish caught score in the ordered datastore
local function updatePlayerFishCaughtScore(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	local totalFishCaught = data.TotalFishCaught or 0
	if totalFishCaught <= 0 then return end
	
	local success, err = pcall(function()
		FishCaughtLeaderboard:SetAsync(tostring(player.UserId), totalFishCaught)
	end)
	
	if not success then
		warn("⚠️ [LEADERBOARD] Failed to update fish caught for", player.Name, ":", err)
	end
end

-- Update a player's donation score in the ordered datastore
local function updatePlayerDonationScore(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	local totalDonations = data.TotalDonations or 0
	if totalDonations <= 0 then return end
	
	local success, err = pcall(function()
		DonationLeaderboard:SetAsync(tostring(player.UserId), totalDonations)
	end)
	
	if not success then
		warn("⚠️ [LEADERBOARD] Failed to update donation for", player.Name, ":", err)
	end
end

-- Get top players from ordered datastore
local function getTopPlayers(orderedDataStore, count)
	count = count or DataStoreConfig.LeaderboardDisplayCount
	local topPlayers = {}
	
	local success, pages = pcall(function()
		return orderedDataStore:GetSortedAsync(false, count)
	end)
	
	if success and pages then
		local data = pages:GetCurrentPage()
		for rank, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local score = entry.value
			
			-- Get player name
			local playerName = "Unknown"
			local success2, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if success2 then
				playerName = name
			end
			
			table.insert(topPlayers, {
				Rank = rank,
				UserId = userId,
				Name = playerName,
				Score = score
			})
		end
	end
	
	return topPlayers
end

-- ==================== LEADERBOARD DISPLAY UPDATE ====================

-- Update physical leaderboard in workspace
local function updateLeaderboardDisplay(leaderboardName, topPlayers)
	-- Find all leaderboards with this name in workspace
	local leaderboardsFolder = workspace:FindFirstChild("Leaderboards")
	if not leaderboardsFolder then return end
	
	for _, board in ipairs(leaderboardsFolder:GetChildren()) do
		if board.Name == leaderboardName then
			local surfaceGui = board:FindFirstChildOfClass("SurfaceGui")
			if surfaceGui then
				local scrollFrame = surfaceGui:FindFirstChild("ScrollFrame") or surfaceGui:FindFirstChild("Frame")
				if scrollFrame then
					-- Clear existing entries
					for _, child in ipairs(scrollFrame:GetChildren()) do
						if child:IsA("Frame") and child.Name:match("^Entry_") then
							child:Destroy()
						end
					end
					
					-- Create new entries
					for i, playerData in ipairs(topPlayers) do
						local entry = Instance.new("Frame")
						entry.Name = "Entry_" .. i
						entry.Size = UDim2.new(1, -10, 0, 30)
						entry.Position = UDim2.new(0, 5, 0, (i - 1) * 32)
						entry.BackgroundTransparency = i % 2 == 0 and 0.9 or 0.95
						entry.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						entry.Parent = scrollFrame
						
						-- Rank
						local rankLabel = Instance.new("TextLabel")
						rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
						rankLabel.BackgroundTransparency = 1
						rankLabel.Text = "#" .. playerData.Rank
						rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
						rankLabel.Font = Enum.Font.GothamBold
						rankLabel.TextSize = 14
						rankLabel.Parent = entry
						
						-- Name
						local nameLabel = Instance.new("TextLabel")
						nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
						nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
						nameLabel.BackgroundTransparency = 1
						nameLabel.Text = playerData.Name
						nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
						nameLabel.Font = Enum.Font.Gotham
						nameLabel.TextSize = 12
						nameLabel.TextXAlignment = Enum.TextXAlignment.Left
						nameLabel.Parent = entry
						
						-- Score
						local scoreLabel = Instance.new("TextLabel")
						scoreLabel.Size = UDim2.new(0.3, 0, 1, 0)
						scoreLabel.Position = UDim2.new(0.7, 0, 0, 0)
						scoreLabel.BackgroundTransparency = 1
						scoreLabel.Text = tostring(playerData.Score)
						scoreLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
						scoreLabel.Font = Enum.Font.GothamBold
						scoreLabel.TextSize = 14
						scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
						scoreLabel.Parent = entry
					end
				end
			end
		end
	end
end

-- Update all leaderboards
local function updateAllLeaderboards()
	-- Fish Caught Leaderboard
	local topFishCatchers = getTopPlayers(FishCaughtLeaderboard, 50)
	updateLeaderboardDisplay("FishCaughtLeaderboard", topFishCatchers)
	
	-- Donation Leaderboard
	local topDonators = getTopPlayers(DonationLeaderboard, 50)
	updateLeaderboardDisplay("DonationLeaderboard", topDonators)
end

-- ==================== PLAYER EVENTS ====================

-- Update leaderboard when player data changes
Players.PlayerAdded:Connect(function(player)
	task.delay(5, function() -- Wait for data to load
		updatePlayerFishCaughtScore(player)
		updatePlayerDonationScore(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Final update before player leaves
	updatePlayerFishCaughtScore(player)
	updatePlayerDonationScore(player)
end)

-- ==================== PERIODIC UPDATE ====================

task.spawn(function()
	while true do
		task.wait(DataStoreConfig.LeaderboardUpdateInterval)
		
		-- Update all current players' scores
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				updatePlayerFishCaughtScore(player)
				updatePlayerDonationScore(player)
			end)
		end
		
		-- Update leaderboard displays
		task.wait(2) -- Small delay to let datastores update
		updateAllLeaderboards()
	end
end)

-- Initial leaderboard display update
task.delay(10, updateAllLeaderboards)

-- ==================== REMOTE FUNCTION FOR GETTING LEADERBOARD DATA ====================

local GetLeaderboardFunc = ReplicatedStorage:FindFirstChild("GetLeaderboard")
if not GetLeaderboardFunc then
	GetLeaderboardFunc = Instance.new("RemoteFunction")
	GetLeaderboardFunc.Name = "GetLeaderboard"
	GetLeaderboardFunc.Parent = ReplicatedStorage
end

GetLeaderboardFunc.OnServerInvoke = function(player, leaderboardType)
	if leaderboardType == "FishCaught" then
		return getTopPlayers(FishCaughtLeaderboard, 50)
	elseif leaderboardType == "Donation" then
		return getTopPlayers(DonationLeaderboard, 50)
	end
	return {}
end

print("✅ [LEADERBOARD SERVER] Initialized with Fish Caught and Donation leaderboards")
