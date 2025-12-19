--[[
    DATASTORE CONFIG
    Place in ReplicatedStorage/Modules/DataStoreConfig.lua
    
    Centralized configuration for all DataStores used in the game
]]

local DataStoreConfig = {}

-- ==================== DATASTORE NAMES ====================
DataStoreConfig.PlayerData = "PlayerData_v3"

-- ==================== LEADERBOARD DATASTORES ====================
DataStoreConfig.Leaderboards = {
	FishCaught = "Leaderboard_FishCaught_v1",  -- Total fish caught
	Donation = "Leaderboard_Donation_v1",       -- Total donation amount
}

-- ==================== LEADERBOARD UPDATE SETTINGS ====================
DataStoreConfig.LeaderboardUpdateInterval = 60 -- seconds
DataStoreConfig.LeaderboardDisplayCount = 100 -- how many players to show on leaderboard

return DataStoreConfig
