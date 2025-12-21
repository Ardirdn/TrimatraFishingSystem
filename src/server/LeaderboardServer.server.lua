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
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
local RichestLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Richest)

-- Track player join times for playtime calculation
local playerJoinTimes = {}
local PLAYTIME_UPDATE_INTERVAL = 60 -- Update playtime every 60 seconds

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

-- Update a player's playtime score in the ordered datastore
local function updatePlayerPlaytimeScore(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	local totalPlaytime = data.TotalPlaytime or data.PlayTime or 0
	if totalPlaytime <= 0 then return end
	
	local success, err = pcall(function()
		PlaytimeLeaderboard:SetAsync(tostring(player.UserId), totalPlaytime)
	end)
	
	if not success then
		warn("⚠️ [LEADERBOARD] Failed to update playtime for", player.Name, ":", err)
	end
end

-- Update a player's money/richest score in the ordered datastore
local function updatePlayerRichestScore(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	local totalMoney = data.Money or 0
	if totalMoney <= 0 then return end
	
	local success, err = pcall(function()
		RichestLeaderboard:SetAsync(tostring(player.UserId), totalMoney)
	end)
	
	if not success then
		warn("⚠️ [LEADERBOARD] Failed to update richest for", player.Name, ":", err)
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

-- Helper function to find SurfaceGui recursively
local function findSurfaceGui(parent)
	-- Check if parent has SurfaceGui directly
	local surfaceGui = parent:FindFirstChildOfClass("SurfaceGui")
	if surfaceGui then
		return surfaceGui
	end
	
	-- If parent is a Model, search inside its children (Parts)
	if parent:IsA("Model") then
		for _, child in ipairs(parent:GetDescendants()) do
			if child:IsA("SurfaceGui") then
				return child
			end
		end
	end
	
	return nil
end

-- Helper function to format score based on leaderboard type
local function formatScore(score, leaderboardName)
	if leaderboardName == "PlaytimeLeaderboard" then
		-- Format as hours and minutes
		local hours = math.floor(score / 3600)
		local minutes = math.floor((score % 3600) / 60)
		return string.format("%dh %dm", hours, minutes)
	elseif leaderboardName == "DonationLeaderboard" then
		return "R$" .. tostring(score)
	elseif leaderboardName == "RichestLeaderboard" then
		-- Format with commas for large numbers
		local formatted = tostring(score)
		local k = 1
		while k ~= 0 do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		end
		return "$" .. formatted
	else
		return tostring(score)
	end
end

-- Update physical leaderboard in workspace
local function updateLeaderboardDisplay(leaderboardName, topPlayers)
	-- Find all leaderboards with this name in workspace
	local leaderboardsContainer = workspace:FindFirstChild("Leaderboards")
	if not leaderboardsContainer then 
		warn("⚠️ [LEADERBOARD] 'Leaderboards' not found in Workspace!")
		return 
	end
	
	for _, board in ipairs(leaderboardsContainer:GetChildren()) do
		if board.Name == leaderboardName then
			local surfaceGui = findSurfaceGui(board)
			if surfaceGui then
				-- Try multiple common frame names
				local scrollFrame = surfaceGui:FindFirstChild("ScrollFrame") 
					or surfaceGui:FindFirstChild("Frame")
					or surfaceGui:FindFirstChild("Content")
					or surfaceGui:FindFirstChild("ScrollingFrame")
					or surfaceGui:FindFirstChildOfClass("Frame")
					or surfaceGui:FindFirstChildOfClass("ScrollingFrame")
				
				if scrollFrame then
					print("📊 [LEADERBOARD] Updating", leaderboardName, "with", #topPlayers, "entries")
					
					-- Clear existing entries
					for _, child in ipairs(scrollFrame:GetChildren()) do
						if child:IsA("Frame") and child.Name:match("^Entry_") then
							child:Destroy()
						end
					end
					
					-- Create new entries
					local entryHeight = 55 -- Reduced size
					local entrySpacing = 7 -- Gap between entries
					local padding = 10 -- Padding inside entry
					
					for i, playerData in ipairs(topPlayers) do
						local entry = Instance.new("Frame")
						entry.Name = "Entry_" .. i
						entry.Size = UDim2.new(1, -20, 0, entryHeight)
						entry.Position = UDim2.new(0, 10, 0, (i - 1) * (entryHeight + entrySpacing) + 10)
						entry.BackgroundTransparency = 0.8 -- 80% transparent
						entry.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White background
						entry.BorderSizePixel = 0
						entry.Parent = scrollFrame
						
						-- Add corner rounding
						local corner = Instance.new("UICorner")
						corner.CornerRadius = UDim.new(0, 6)
						corner.Parent = entry
						
						-- Rank (left side) - with proper spacing
						local rankLabel = Instance.new("TextLabel")
						rankLabel.Size = UDim2.new(0.08, 0, 1, 0)
						rankLabel.Position = UDim2.new(0.01, 0, 0, 0)
						rankLabel.BackgroundTransparency = 1
						rankLabel.Text = "#" .. playerData.Rank
						rankLabel.TextScaled = true
						rankLabel.Font = Enum.Font.GothamBold
						rankLabel.TextSize = 24
						-- Gold for top 3, dark for others (since white bg)
						if playerData.Rank == 1 then
							rankLabel.TextColor3 = Color3.fromRGB(255, 180, 0) -- Gold
						elseif playerData.Rank == 2 then
							rankLabel.TextColor3 = Color3.fromRGB(140, 140, 150) -- Silver
						elseif playerData.Rank == 3 then
							rankLabel.TextColor3 = Color3.fromRGB(180, 100, 30) -- Bronze
						else
							rankLabel.TextColor3 = Color3.fromRGB(50, 50, 50) -- Dark text
						end
						rankLabel.Parent = entry
						
						-- Text size constraint for rank
						local rankConstraint = Instance.new("UITextSizeConstraint")
						rankConstraint.MaxTextSize = 28
						rankConstraint.MinTextSize = 14
						rankConstraint.Parent = rankLabel
						
						-- Avatar (after rank) - with better spacing
						local avatarSize = entryHeight - 12 -- Square, slightly smaller than entry height
						local avatarImage = Instance.new("ImageLabel")
						avatarImage.Size = UDim2.new(0, avatarSize, 0, avatarSize)
						avatarImage.Position = UDim2.new(0.10, 5, 0.5, 0) -- Added 5px gap from rank
						avatarImage.AnchorPoint = Vector2.new(0, 0.5)
						avatarImage.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
						avatarImage.BorderSizePixel = 0
						avatarImage.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", playerData.UserId)
						avatarImage.Parent = entry
						
						-- Round avatar corners
						local avatarCorner = Instance.new("UICorner")
						avatarCorner.CornerRadius = UDim.new(0.5, 0) -- Circular
						avatarCorner.Parent = avatarImage
						
						-- Name (after avatar) - with better spacing
						local nameLabel = Instance.new("TextLabel")
						nameLabel.Size = UDim2.new(0.38, 0, 1, 0)
						nameLabel.Position = UDim2.new(0.24, 0, 0, 0) -- More space after avatar
						nameLabel.BackgroundTransparency = 1
						nameLabel.Text = playerData.Name
						nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
						nameLabel.Font = Enum.Font.GothamMedium
						nameLabel.TextScaled = true
						nameLabel.TextSize = 22
						nameLabel.TextXAlignment = Enum.TextXAlignment.Left
						nameLabel.Parent = entry
						
						-- Text size constraint for name
						local nameConstraint = Instance.new("UITextSizeConstraint")
						nameConstraint.MaxTextSize = 24
						nameConstraint.MinTextSize = 12
						nameConstraint.Parent = nameLabel
						
						-- Score (right side)
						local scoreLabel = Instance.new("TextLabel")
						scoreLabel.Size = UDim2.new(0.28, -10, 1, 0)
						scoreLabel.Position = UDim2.new(0.70, 0, 0, 0)
						scoreLabel.BackgroundTransparency = 1
						scoreLabel.Text = formatScore(playerData.Score, leaderboardName)
						scoreLabel.TextColor3 = Color3.fromRGB(0, 150, 50) -- Green for score
						scoreLabel.Font = Enum.Font.GothamBold
						scoreLabel.TextScaled = true
						scoreLabel.TextSize = 24
						scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
						scoreLabel.Parent = entry
						
						-- Text size constraint for score
						local scoreConstraint = Instance.new("UITextSizeConstraint")
						scoreConstraint.MaxTextSize = 28
						scoreConstraint.MinTextSize = 14
						scoreConstraint.Parent = scoreLabel
					end
					
					-- Update canvas size for ScrollingFrame
					if scrollFrame:IsA("ScrollingFrame") then
						local totalHeight = #topPlayers * (entryHeight + entrySpacing) + 20
						scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
					end
				else
					warn("⚠️ [LEADERBOARD]", leaderboardName, "- No ScrollFrame/Frame found inside SurfaceGui!")
				end
			else
				warn("⚠️ [LEADERBOARD]", leaderboardName, "- No SurfaceGui found!")
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
	
	-- Playtime Leaderboard
	local topPlaytime = getTopPlayers(PlaytimeLeaderboard, 50)
	updateLeaderboardDisplay("PlaytimeLeaderboard", topPlaytime)
	
	-- Richest Leaderboard
	local topRichest = getTopPlayers(RichestLeaderboard, 50)
	updateLeaderboardDisplay("RichestLeaderboard", topRichest)
end

-- ==================== PLAYER EVENTS ====================

-- Update leaderboard when player data changes
Players.PlayerAdded:Connect(function(player)
	-- Track when player joined for playtime calculation
	playerJoinTimes[player.UserId] = os.time()
	
	task.delay(5, function() -- Wait for data to load
		updatePlayerFishCaughtScore(player)
		updatePlayerDonationScore(player)
		updatePlayerPlaytimeScore(player)
		updatePlayerRichestScore(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Calculate and save final session playtime
	local joinTime = playerJoinTimes[player.UserId]
	if joinTime then
		local sessionTime = os.time() - joinTime
		local data = DataHandler:GetData(player)
		if data then
			local currentPlaytime = data.TotalPlaytime or 0
			DataHandler:Set(player, "TotalPlaytime", currentPlaytime + sessionTime)
			DataHandler:SavePlayer(player)
			print(string.format("⏱️ [LEADERBOARD] Saved playtime for %s: +%d seconds (Total: %d)", 
				player.Name, sessionTime, currentPlaytime + sessionTime))
		end
		playerJoinTimes[player.UserId] = nil
	end
	
	-- Final update before player leaves
	updatePlayerFishCaughtScore(player)
	updatePlayerDonationScore(player)
	updatePlayerPlaytimeScore(player)
	updatePlayerRichestScore(player)
end)

-- ==================== PLAYTIME TRACKING ====================

-- Increment playtime for all online players every minute
task.spawn(function()
	while true do
		task.wait(PLAYTIME_UPDATE_INTERVAL)
		
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				local joinTime = playerJoinTimes[player.UserId]
				if joinTime then
					-- Increment playtime by the interval amount
					local data = DataHandler:GetData(player)
					if data then
						local currentPlaytime = data.TotalPlaytime or 0
						DataHandler:Set(player, "TotalPlaytime", currentPlaytime + PLAYTIME_UPDATE_INTERVAL)
						-- Update the join time to current time so we don't double-count
						playerJoinTimes[player.UserId] = os.time()
					end
				end
			end)
		end
	end
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
				updatePlayerPlaytimeScore(player)
				updatePlayerRichestScore(player)
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
	elseif leaderboardType == "Playtime" then
		return getTopPlayers(PlaytimeLeaderboard, 50)
	elseif leaderboardType == "Richest" then
		return getTopPlayers(RichestLeaderboard, 50)
	end
	return {}
end

print("✅ [LEADERBOARD SERVER] Initialized with FishCaught, Donation, Playtime, Richest leaderboards")
