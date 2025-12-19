--[[
    DATASTORE CONFIG - CENTRALIZED
    Place in ReplicatedStorage/Modules/DataStoreConfig
    
    ============================================
    🎯 ONE PLACE TO CHANGE ALL DATASTORE NAMES
    ============================================
    
    Ketika mau reset data (fresh start):
    1. Ganti VERSION di bawah ini (misal "v11" → "v12")
    2. Semua DataStore akan pakai version baru
    3. Semua player akan auto-migrasi dari Firebase/legacy
    
    CATATAN:
    - Leaderboard OrderedDataStore juga akan reset
    - Data lama tetap aman di version lama
    - Migration hanya jalan sekali per player per version
]]

local DataStoreConfig = {}

-- ============================================
-- 🔧 MAIN VERSION - CHANGE THIS TO RESET ALL DATA
-- ============================================
DataStoreConfig.VERSION = "v16"

-- ============================================
-- 📦 DATASTORE NAMES (AUTO-GENERATED)
-- ============================================

-- Main player data
DataStoreConfig.PlayerData = "PlayerData_" .. DataStoreConfig.VERSION

-- Leaderboard OrderedDataStores
DataStoreConfig.Leaderboards = {
    Summit = "SummitLeaderboard_" .. DataStoreConfig.VERSION,
    Speedrun = "SpeedrunLeaderboard_" .. DataStoreConfig.VERSION,
    Playtime = "PlaytimeLeaderboard_" .. DataStoreConfig.VERSION,
    Donation = "DonationLeaderboard_" .. DataStoreConfig.VERSION,
}

-- ============================================
-- 📦 LEGACY DATASTORES (FOR MIGRATION ONLY)
-- ============================================
-- These are the OLD datastore names to migrate FROM
-- DO NOT CHANGE THESE - they need to match the old system
DataStoreConfig.Legacy = {
    -- Old leaderboards (before versioning)
    SummitLeaderboard = "Summits",
    DonationLeaderboard = "Donations", 
    PlaytimeLeaderboard = "TopTimePlayed",
    
    -- Old data stores
    Wings = "FlyTogetherWingsStatus_V2",
    CrystalAura = "AuraExchangeData_V2",
}

-- ============================================
-- ⚙️ OTHER CONFIG
-- ============================================
DataStoreConfig.AutoSaveInterval = 300 -- 5 minutes
DataStoreConfig.MaxRetries = 3
DataStoreConfig.RetryDelay = 1

-- ============================================
-- 🔍 HELPER FUNCTIONS
-- ============================================

-- Get current version string
function DataStoreConfig:GetVersion()
    return self.VERSION
end

-- Get all current datastore names (for debugging)
function DataStoreConfig:GetAllNames()
    return {
        PlayerData = self.PlayerData,
        SummitLeaderboard = self.Leaderboards.Summit,
        SpeedrunLeaderboard = self.Leaderboards.Speedrun,
        PlaytimeLeaderboard = self.Leaderboards.Playtime,
        DonationLeaderboard = self.Leaderboards.Donation,
    }
end

-- Print config info (for debugging)
function DataStoreConfig:PrintInfo()
    print("============================================")
    print("📦 DATASTORE CONFIG")
    print("============================================")
    print("VERSION:", self.VERSION)
    print("")
    print("Current DataStores:")
    print("  - PlayerData:", self.PlayerData)
    print("  - Summit:", self.Leaderboards.Summit)
    print("  - Speedrun:", self.Leaderboards.Speedrun)
    print("  - Playtime:", self.Leaderboards.Playtime)
    print("  - Donation:", self.Leaderboards.Donation)
    print("============================================")
end

return DataStoreConfig
