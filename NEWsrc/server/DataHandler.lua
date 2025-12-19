--[[
    DATA HANDLER SYSTEM
    Place in ServerScriptService/DataHandler
    
    Centralized data management system
    - All DataStore operations go through here
    - Automatic save & backup
    - Session locking
    - Data validation
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = {}
DataHandler.__index = DataHandler

-- ✅ USE CENTRALIZED CONFIG
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

-- Configuration (from centralized config)
local CONFIG = {
	DataStoreName = DataStoreConfig.PlayerData,
	AutoSaveInterval = DataStoreConfig.AutoSaveInterval,
	MaxRetries = DataStoreConfig.MaxRetries,
	RetryDelay = DataStoreConfig.RetryDelay,
}

-- Data cache (in-memory)
local PlayerDataCache = {}
local SessionLocks = {}

-- Get DataStore
local PlayerDataStore = DataStoreService:GetDataStore(CONFIG.DataStoreName)

-- ✅ Get OrderedDataStores for leaderboard updates (using centralized config)
local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

print(string.format("📦 [DATA HANDLER] Using DataStore: %s", CONFIG.DataStoreName))

-- Default data template
-- Default data template
local function getDefaultData(userId)
	return {
		UserId = userId,

		-- Money
		Money = 0,
		TotalDonations = 0,

		-- Inventory
		OwnedAuras = {},
		OwnedTools = {},
		OwnedGamepasses = {},
		EquippedAura = nil,
		EquippedTool = nil, -- ✅ ADDED: Currently equipped tool from inventory
		
		UnlockedTitles = {"Pendaki"}, -- Array of unlocked title names
		EquippedTitle = nil, -- Currently equipped title (nil = no title)

		-- Title System (UPDATED)
		Title = "Pendaki",
		TitleSource = "summit", -- "summit", "special", "admin"
		SpecialTitle = nil, -- Untuk VIP, VVIP, Donatur, Admin, dll

		-- Summit & Checkpoint (NEW - dipindahkan dari checkpoint script)
		TotalSummits = 0,
		LastCheckpoint = 0,
		BestSpeedrun = nil,
		TotalPlaytime = 0,

		-- Clan (future feature)
		Clan = nil,
		
		--Dance
		FavoriteDances = {},
		
		--Music
		FavoriteMusic = {},
		
		-- Vibe System (Lighting Theme)
		VibeTheme = nil, -- Selected lighting theme (nil = default)

		-- Redeem System
		RedeemedCodes = {}, -- Array of redeemed code IDs

		-- ==========================================
		-- FISHING SYSTEM (NEW)
		-- ==========================================
		FishInventory = {}, -- Dictionary: {fishId = count}
		TotalFishCaught = 0, -- Total fish caught lifetime
		DiscoveredFish = {}, -- Dictionary: {fishId = true} for fish index
		OwnedRods = {"WoodRod"}, -- Array of owned rod IDs (default starter rod)
		OwnedFloaters = {}, -- Array of owned floater IDs
		EquippedRod = "WoodRod", -- Currently equipped rod ID
		EquippedFloater = nil, -- Currently equipped floater ID (nil = default)

		-- Legacy Migration (NEW)
		LegacyDataMigrated = false, -- Set to true after one-time migration from old system
		MigrationDate = nil, -- Timestamp when migration occurred

		-- Metadata
		FirstJoin = os.time(),
		LastJoin = os.time(),
		PlayTime = 0,
		DataVersion = 5, -- ⚠️ JANGAN UBAH - Data player akan hilang jika diubah
	}
end


--[[
    Validate and migrate data structure
]]
local function validateData(data, userId)
	if not data then
		return getDefaultData(userId)
	end

	-- Ensure all fields exist
	local template = getDefaultData(userId)
	for key, defaultValue in pairs(template) do
		if data[key] == nil then
			data[key] = defaultValue
		end
	end

	-- Type validation
	if type(data.Money) ~= "number" then data.Money = 0 end
	if type(data.TotalDonations) ~= "number" then data.TotalDonations = 0 end
	if type(data.OwnedAuras) ~= "table" then data.OwnedAuras = {} end
	if type(data.OwnedTools) ~= "table" then data.OwnedTools = {} end
	if type(data.OwnedGamepasses) ~= "table" then data.OwnedGamepasses = {} end
	if type(data.FavoriteDances) ~= "table" then 
		data.FavoriteDances = {} 
	end
	if type(data.FavoriteMusic) ~= "table" then 
		data.FavoriteMusic = {} 
	end
	if type(data.RedeemedCodes) ~= "table" then 
		data.RedeemedCodes = {} 
	end
	
	-- Fishing System validation
	if type(data.FishInventory) ~= "table" then data.FishInventory = {} end
	if type(data.TotalFishCaught) ~= "number" then data.TotalFishCaught = 0 end
	if type(data.DiscoveredFish) ~= "table" then data.DiscoveredFish = {} end
	if type(data.OwnedRods) ~= "table" then data.OwnedRods = {"WoodRod"} end
	if type(data.OwnedFloaters) ~= "table" then data.OwnedFloaters = {} end
	if data.EquippedRod == nil or data.EquippedRod == "" then data.EquippedRod = "WoodRod" end
	-- EquippedFloater can be nil (no floater equipped)



	-- Update last join
	data.LastJoin = os.time()

	return data
end

--[[
    Load player data from DataStore
]]
function DataHandler:LoadPlayer(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	-- Check session lock
	if SessionLocks[userId] then
		warn(string.format("⚠️ [DATA HANDLER] Session lock active for %s", player.Name))
		player:Kick("Data session conflict. Please rejoin.")
		return false
	end

	print(string.format("📂 [DATA HANDLER] Loading data for %s...", player.Name))

	-- Try to load data with retry
	local data = nil
	local success = false

	for attempt = 1, CONFIG.MaxRetries do
		success, data = pcall(function()
			return PlayerDataStore:GetAsync(key)
		end)

		if success then
			break
		else
			warn(string.format("⚠️ [DATA HANDLER] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(data)))
			if attempt < CONFIG.MaxRetries then
				task.wait(CONFIG.RetryDelay * attempt)
			end
		end
	end

	if not success then
		warn(string.format("❌ [DATA HANDLER] Failed to load data for %s after %d attempts", player.Name, CONFIG.MaxRetries))
		-- Use default data
		data = nil
	end

	-- Validate and cache
	data = validateData(data, userId)
	PlayerDataCache[player] = data
	SessionLocks[userId] = true

	-- Create Money IntValue for easy access
	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = data.Money
	moneyValue.Parent = player

	print(string.format("✅ [DATA HANDLER] Loaded data for %s (Money: $%d, Title: %s)", player.Name, data.Money, data.Title))

	-- ==========================================
	-- LEGACY DATA MIGRATION (One-time, runs in BACKGROUND after player spawns)
	-- ==========================================
	local SKIP_LEGACY_MIGRATION = false  -- Set to true only if ALL players already migrated
	
	if SKIP_LEGACY_MIGRATION then
		-- Skip migration entirely
		if data.LegacyDataMigrated ~= true then
			data.LegacyDataMigrated = true
			print(string.format("⏭️ [DATA HANDLER] Legacy migration SKIPPED for %s", player.Name))
		end
	elseif data.LegacyDataMigrated ~= true then
		-- ✅ FIX: Run migration in BACKGROUND after 10 seconds (player already in game)
		task.spawn(function()
			-- Wait 10 seconds AFTER player joins so they can play first
			-- This ensures loading screen is gone before migration starts
			task.wait(10)
			
			-- Check if player still in game
			if not player or not player.Parent then return end
			
			-- Load DataMigration module
			local DataMigration = require(script.Parent:FindFirstChild("DataMigration"))
			if DataMigration then
				print(string.format("🔄 [DATA HANDLER] Running background migration for %s...", player.Name))
				local migrationSuccess = DataMigration:MigratePlayer(player, DataHandler)
				if migrationSuccess then
					print(string.format("✅ [DATA HANDLER] Migration complete for %s", player.Name))
					
					local migratedData = PlayerDataCache[player]
					if migratedData then
						-- ==========================================
						-- ✅ UPDATE LEADERBOARD ORDEREDATASTORES
						-- ==========================================
						DataHandler:UpdateLeaderboards(player)
						
						-- ==========================================
						-- ✅ UPDATE PLAYERSTATS (UI VALUES)
						-- ==========================================
						local playerStats = player:FindFirstChild("PlayerStats")
						if playerStats then
							local summitValue = playerStats:FindFirstChild("Summit")
							if summitValue then
								summitValue.Value = migratedData.TotalSummits or 0
								print(string.format("📊 [DATA HANDLER] PlayerStats.Summit updated to %d", migratedData.TotalSummits or 0))
							end
							
							-- Also update Playtime display
							local playtimeValue = playerStats:FindFirstChild("Playtime")
							if playtimeValue and migratedData.TotalPlaytime then
								local minutes = math.floor(migratedData.TotalPlaytime / 60)
								local hours = math.floor(minutes / 60)
								if hours > 0 then
									playtimeValue.Value = string.format("%dh %dm", hours, minutes % 60)
								else
									playtimeValue.Value = string.format("%dm", minutes)
								end
							end
						end
						
						-- ==========================================
						-- ✅ FIRE SYNC EVENT TO UPDATE CHECKPOINTSYSTEM CACHE
						-- ==========================================
						task.wait(0.5)
						
						local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")
						if syncEvent then
							print(string.format("🔄 [DATA HANDLER] Firing sync event for %s (TotalSummits: %d)", 
								player.Name, migratedData.TotalSummits or 0))
							syncEvent:Fire(player, {
								TotalSummits = migratedData.TotalSummits,
								TotalDonations = migratedData.TotalDonations,
								LastCheckpoint = migratedData.LastCheckpoint,
								BestSpeedrun = migratedData.BestSpeedrun,
								TotalPlaytime = migratedData.TotalPlaytime,
							})
							print("🔄 [DATA HANDLER] Sync event fired successfully!")
						end
					else
						warn("[DATA HANDLER] PlayerDataCache[player] is nil!")
					end
					
					-- ==========================================
					-- ✅ RE-INITIALIZE TITLE SYSTEM
					-- ==========================================
					local TitleServerSuccess, TitleServerModule = pcall(function()
						return require(script.Parent:FindFirstChild("TitleServer"))
					end)
					if TitleServerSuccess and TitleServerModule and TitleServerModule.InitializePlayerPostMigration then
						TitleServerModule:InitializePlayerPostMigration(player)
						print(string.format("🎯 [DATA HANDLER] TitleServer post-migration initialized for %s", player.Name))
					end
				else
					warn(string.format("⚠️ [DATA HANDLER] Migration failed for %s", player.Name))
				end
			else
				warn("[DATA HANDLER] DataMigration module not found!")
			end
		end)
	else
		print(string.format("✅ [DATA HANDLER] %s already migrated (skipping)", player.Name))
	end

	return true
end

--[[
    Save player data to DataStore
]]
function DataHandler:SavePlayer(player)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local userId = player.UserId
	local key = "Player_" .. userId
	local data = PlayerDataCache[player]

	print(string.format("💾 [DATA HANDLER] Saving data for %s...", player.Name))

	-- Try to save with retry
	local success = false
	local errorMsg = nil

	for attempt = 1, CONFIG.MaxRetries do
		success, errorMsg = pcall(function()
			PlayerDataStore:SetAsync(key, data)
		end)

		if success then
			break
		else
			warn(string.format("⚠️ [DATA HANDLER] Save attempt %d failed for %s: %s", attempt, player.Name, tostring(errorMsg)))
			if attempt < CONFIG.MaxRetries then
				task.wait(CONFIG.RetryDelay * attempt)
			end
		end
	end

	if success then
		print(string.format("✅ [DATA HANDLER] Saved data for %s", player.Name))
		return true
	else
		warn(string.format("❌ [DATA HANDLER] Failed to save data for %s after %d attempts", player.Name, CONFIG.MaxRetries))
		return false
	end
end

--[[
    Get cached player data
]]
function DataHandler:GetData(player)
	return PlayerDataCache[player]
end

--[[
    Set a specific field
]]
function DataHandler:Set(player, field, value)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	PlayerDataCache[player][field] = value

	-- Update IntValue if it's Money
	if field == "Money" then
		local moneyValue = player:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = value
		end
	end

	print(string.format("📝 [DATA HANDLER] Set %s.%s = %s", player.Name, field, tostring(value)))
	return true
end

--[[
    Get a specific field
]]
function DataHandler:Get(player, field)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return nil
	end

	return PlayerDataCache[player][field]
end

--[[
    Increment a numeric field
]]
function DataHandler:Increment(player, field, amount)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local currentValue = PlayerDataCache[player][field] or 0
	if type(currentValue) ~= "number" then
		warn(string.format("⚠️ [DATA HANDLER] Field %s is not a number", field))
		return false
	end

	local newValue = currentValue + amount
	PlayerDataCache[player][field] = newValue

	-- Update IntValue if it's Money
	if field == "Money" then
		local moneyValue = player:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = newValue
		end
	end
	return true
end

--[[
    Add item to array field
]]
function DataHandler:AddToArray(player, field, value)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local array = PlayerDataCache[player][field]
	if type(array) ~= "table" then
		warn(string.format("⚠️ [DATA HANDLER] Field %s is not an array", field))
		return false
	end

	-- Check if already exists
	if table.find(array, value) then
		warn(string.format("⚠️ [DATA HANDLER] Value already exists in %s.%s", player.Name, field))
		return false
	end

	table.insert(array, value)
	print(string.format("📝 [DATA HANDLER] Added %s to %s.%s", tostring(value), player.Name, field))
	return true
end

--[[
    Remove item from array field
]]
function DataHandler:RemoveFromArray(player, field, value)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local array = PlayerDataCache[player][field]
	if type(array) ~= "table" then
		warn(string.format("⚠️ [DATA HANDLER] Field %s is not an array", field))
		return false
	end

	local index = table.find(array, value)
	if not index then
		warn(string.format("⚠️ [DATA HANDLER] Value not found in %s.%s", player.Name, field))
		return false
	end

	table.remove(array, index)
	print(string.format("📝 [DATA HANDLER] Removed %s from %s.%s", tostring(value), player.Name, field))
	return true
end

--[[
    Check if array contains value
]]
function DataHandler:ArrayContains(player, field, value)
	if not PlayerDataCache[player] then
		return false
	end

	local array = PlayerDataCache[player][field]
	if type(array) ~= "table" then
		return false
	end

	return table.find(array, value) ~= nil
end

--[[
    Update leaderboard OrderedDataStores for a player
    Called after migration and whenever stats change
]]
function DataHandler:UpdateLeaderboards(player)
	local data = PlayerDataCache[player]
	if not data then return false end
	
	local userId = player.UserId
	local updated = {}
	
	-- Update Summit Leaderboard
	if data.TotalSummits and data.TotalSummits > 0 then
		pcall(function()
			SummitLeaderboard:SetAsync(tostring(userId), data.TotalSummits)
			table.insert(updated, "Summit:" .. data.TotalSummits)
		end)
	end
	
	-- Update Donation Leaderboard
	if data.TotalDonations and data.TotalDonations > 0 then
		pcall(function()
			DonationLeaderboard:SetAsync(tostring(userId), data.TotalDonations)
			table.insert(updated, "Donation:" .. data.TotalDonations)
		end)
	end
	
	-- Update Playtime Leaderboard
	if data.TotalPlaytime and data.TotalPlaytime > 0 then
		pcall(function()
			local playtimeInt = math.floor(data.TotalPlaytime)
			PlaytimeLeaderboard:SetAsync(tostring(userId), playtimeInt)
			table.insert(updated, "Playtime:" .. playtimeInt)
		end)
	end
	
	-- Update Speedrun Leaderboard (stored as negative for ascending order)
	if data.BestSpeedrun and data.BestSpeedrun > 0 then
		pcall(function()
			local speedrunInt = -math.floor(data.BestSpeedrun)
			SpeedrunLeaderboard:SetAsync(tostring(userId), speedrunInt)
			table.insert(updated, "Speedrun:" .. data.BestSpeedrun)
		end)
	end
	
	if #updated > 0 then
		print(string.format("📊 [DATA HANDLER] Leaderboards updated for %s: %s", 
			player.Name, table.concat(updated, ", ")))
	end
	
	return true
end

--[[
    Get the DataStoreConfig module (for external access)
]]
function DataHandler:GetConfig()
	return DataStoreConfig
end

--[[
    Cleanup on player leave
]]
function DataHandler:CleanupPlayer(player)
	local userId = player.UserId

	-- Save data
	self:SavePlayer(player)

	-- Clear cache
	PlayerDataCache[player] = nil
	SessionLocks[userId] = nil

	print(string.format("🧹 [DATA HANDLER] Cleaned up data for %s", player.Name))
end

-- Auto-save loop
task.spawn(function()
	while true do
		task.wait(CONFIG.AutoSaveInterval)

		print("💾 [DATA HANDLER] Auto-save started...")
		local count = 0

		for player, _ in pairs(PlayerDataCache) do
			if player and player.Parent then
				DataHandler:SavePlayer(player)
				count = count + 1
			end
		end

		print(string.format("✅ [DATA HANDLER] Auto-saved %d players", count))
	end
end)

-- Save on server shutdown
game:BindToClose(function()
	print("🛑 [DATA HANDLER] Server shutting down, saving all data...")

	for player, _ in pairs(PlayerDataCache) do
		if player and player.Parent then
			DataHandler:SavePlayer(player)
		end
	end

	print("✅ [DATA HANDLER] All data saved on shutdown")

	-- Wait a bit to ensure saves complete
	if RunService:IsStudio() then
		task.wait(1)
	else
		task.wait(5)
	end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
	DataHandler:LoadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataHandler:CleanupPlayer(player)
end)

print("✅ [DATA HANDLER] System initialized")

return DataHandler