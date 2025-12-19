--[[
    DATA MIGRATION SYSTEM
    Place in ServerScriptService
    
    One-time migration from legacy systems (Firebase, old DataStores) to new PlayerData_v5
    
    IMPORTANT:
    - This runs ONLY ONCE per player (checks LegacyDataMigrated flag)
    - After successful migration, player data uses new system only
    - 100% safe to delete old system scripts after all players migrated
    
    DATA SOURCES (OLD):
    1. Firebase Firestore (mounthikers-985ea/jurnal/{userId}):
       - TotalSummits
       - Mountains.Nirwana.VIP (boolean)
       - Mountains.Nirwana.Akamsi (boolean)  
       - Mountains.Nirwana.SahabatAdmin (boolean)
       
    2. OrderedDataStore "Summits" - TotalSummits (legacy)
    3. OrderedDataStore "Donations" - Total donations
    4. DataStore "FlyTogetherWingsStatus_V2" - Wings owned {FlyingSpeed1: true, ...}
    
    DATA TARGET (NEW):
    PlayerData_v5 via DataHandler.lua
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataMigration = {}

-- ==========================================
-- CONFIGURATION
-- ==========================================
local CONFIG = {
    FirebaseProjectId = "mounthikers-985ea", -- Production Firebase
    MountainName = "Nirwana", -- Current mountain
    Debug = false, -- Set to false in production (reduces console spam)
    SkipFirebase = false, -- Firebase will run in background, won't block loading
}

-- Firebase URLs
local FIREBASE_BASE_URL = "https://firestore.googleapis.com/v1/projects/" .. CONFIG.FirebaseProjectId .. "/databases/(default)/documents/"
local JOURNAL_URL = FIREBASE_BASE_URL .. "jurnal/"

-- Legacy DataStores
local LegacySummitsStore = DataStoreService:GetOrderedDataStore("Summits")
local LegacyDonationsStore = DataStoreService:GetOrderedDataStore("Donations")
local LegacyPlaytimeStore = DataStoreService:GetOrderedDataStore("TopTimePlayed") -- Playtime leaderboard
local LegacyWingsStore = DataStoreService:GetDataStore("FlyTogetherWingsStatus_V2")
local LegacyCrystalAuraStore = DataStoreService:GetDataStore("AuraExchangeData_V2") -- Crystal Event Auras

-- Constants for playtime migration
local PLAYTIME_STAT_PREFIX = "TimePlayed" -- Key format: "TimePlayed" + UserId

-- ==========================================
-- HELPER: Debug logging
-- ==========================================
local function Log(...)
    if CONFIG.Debug then
        print("[MIGRATION]", ...)
    end
end

local function LogWarn(...)
    warn("[MIGRATION]", ...)
end

-- ==========================================
-- HELPER: Parse Firestore data to Lua table
-- ==========================================
local function parseFirestoreData(fields)
    if not fields then return nil end
    local luaTable = {}
    
    for key, valueContainer in pairs(fields) do
        local valueType, valueData = next(valueContainer)
        
        if valueType == "integerValue" then
            luaTable[key] = tonumber(valueData)
        elseif valueType == "stringValue" then
            luaTable[key] = valueData
        elseif valueType == "booleanValue" then
            luaTable[key] = valueData
        elseif valueType == "mapValue" then
            luaTable[key] = parseFirestoreData(valueData.fields)
        elseif valueType == "arrayValue" then
            luaTable[key] = {}
            if valueData.values then
                for _, item in ipairs(valueData.values) do
                    local itemType, itemData = next(item)
                    if itemType == "stringValue" then
                        table.insert(luaTable[key], itemData)
                    elseif itemType == "integerValue" then
                        table.insert(luaTable[key], tonumber(itemData))
                    end
                end
            end
        end
    end
    return luaTable
end

-- ==========================================
-- FETCH: Get Firebase Journal data
-- ==========================================
local function fetchFirebaseJournal(userId)
    -- ✅ FIX: Skip Firebase if disabled (faster loading)
    if CONFIG.SkipFirebase then
        Log("⏭️ Firebase fetch SKIPPED (CONFIG.SkipFirebase = true)")
        return nil
    end
    
    local url = JOURNAL_URL .. tostring(userId)
    
    Log("========================================")
    Log("🔥 FIREBASE FETCH DEBUG")
    Log("========================================")
    Log("URL:", url)
    
    -- ✅ FIX: Add timeout wrapper to prevent long hangs
    local result = nil
    local fetchComplete = false
    local fetchError = nil
    
    task.spawn(function()
        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)
        
        if success then
            result = response
        else
            fetchError = response
        end
        fetchComplete = true
    end)
    
    -- Wait with timeout (5 seconds max)
    local TIMEOUT = 5
    local waited = 0
    while not fetchComplete and waited < TIMEOUT do
        task.wait(0.1)
        waited = waited + 0.1
    end
    
    if not fetchComplete then
        LogWarn("❌ Firebase TIMEOUT after", TIMEOUT, "seconds for userId:", userId)
        return nil
    end
    
    if fetchError then
        LogWarn("❌ HTTP Request FAILED for", userId)
        LogWarn("   Error:", fetchError)
        return nil
    end
    
    -- Print raw response (truncated if too long)
    Log("✅ HTTP Request SUCCESS")
    local rawPreview = string.sub(result, 1, 500)
    Log("📄 Raw Response (first 500 chars):")
    Log(rawPreview)
    if #result > 500 then
        Log("   ... (truncated, total length:", #result, "chars)")
    end
    
    local decodeSuccess, decoded = pcall(function()
        return HttpService:JSONDecode(result)
    end)
    
    if not decodeSuccess then
        LogWarn("❌ JSON Decode FAILED:", decoded)
        return nil
    end
    
    if decoded.error then
        Log("⚠️ Firebase returned error:")
        Log("   Code:", decoded.error.code)
        Log("   Message:", decoded.error.message)
        Log("   (This means no document exists for this user - new player)")
        return nil
    end
    
    -- Log the structure before parsing
    Log("✅ JSON Decode SUCCESS")
    Log("📊 Firebase document found!")
    
    if decoded.fields then
        Log("📋 Available fields in document:")
        for key, _ in pairs(decoded.fields) do
            Log("   -", key)
        end
    else
        Log("⚠️ No 'fields' in response!")
    end
    
    -- Parse the data
    local parsedData = parseFirestoreData(decoded.fields)
    
    -- Log parsed data in detail
    Log("========================================")
    Log("📊 PARSED FIREBASE DATA:")
    Log("========================================")
    if parsedData then
        for key, value in pairs(parsedData) do
            if type(value) == "table" then
                Log("   ", key, "= (table)")
                for subKey, subValue in pairs(value) do
                    if type(subValue) == "table" then
                        Log("      ", subKey, "= (nested table)")
                        for subSubKey, subSubValue in pairs(subValue) do
                            Log("         ", subSubKey, "=", tostring(subSubValue))
                        end
                    else
                        Log("      ", subKey, "=", tostring(subValue))
                    end
                end
            else
                Log("   ", key, "=", tostring(value))
            end
        end
    else
        Log("   (nil - parsing failed)")
    end
    Log("========================================")
    
    return parsedData
end

-- ==========================================
-- FETCH: Get OrderedDataStore value
-- ==========================================
local function fetchOrderedDataStore(store, userId, storeName)
    storeName = storeName or "UnknownStore"
    
    Log("📦 Fetching OrderedDataStore:", storeName, "for userId:", userId)
    
    local success, result = pcall(function()
        return store:GetAsync(tostring(userId))
    end)
    
    if success then
        if result then
            Log("   ✅ SUCCESS - Value:", tostring(result))
        else
            Log("   ⚠️ SUCCESS but nil/empty (no data found)")
        end
        return result
    else
        LogWarn("   ❌ FAILED to fetch", storeName, ":", result)
        return nil
    end
end

-- ==========================================
-- FETCH: Get regular DataStore value
-- ==========================================
local function fetchDataStore(store, userId, storeName)
    storeName = storeName or "UnknownStore"
    
    Log("📦 Fetching DataStore:", storeName, "for userId:", userId)
    
    local success, result = pcall(function()
        return store:GetAsync(tostring(userId))
    end)
    
    if success then
        if result then
            if type(result) == "table" then
                Log("   ✅ SUCCESS - Table with", #result, "entries")
                for k, v in pairs(result) do
                    Log("      ", k, "=", tostring(v))
                end
            else
                Log("   ✅ SUCCESS - Value:", tostring(result))
            end
        else
            Log("   ⚠️ SUCCESS but nil/empty (no data found)")
        end
        return result
    else
        LogWarn("   ❌ FAILED to fetch", storeName, ":", result)
        return nil
    end
end

-- ==========================================
-- MAIN: Collect all legacy data for player
-- ==========================================
function DataMigration:CollectLegacyData(player)
    local userId = player.UserId
    local legacyData = {
        TotalSummits = 0,
        TotalDonations = 0,
        TotalPlaytime = 0, -- In SECONDS (converted from minutes)
        OwnedTools = {},
        OwnedAuras = {}, -- Crystal Event Auras (Aura1-Aura8)
        SpecialTitles = {}, -- VIP, Akamsi, SahabatAdmin
        IsVIP = false,
        IsAkamsi = false,
        IsSahabatAdmin = false,
    }
    
    Log("========================================")
    Log("Collecting legacy data for:", player.Name, "(", userId, ")")
    Log("========================================")
    
    -- 1. Fetch Firebase Journal
    local firebaseData = fetchFirebaseJournal(userId)
    if firebaseData then
        Log("✅ Firebase data found")
        
        -- Get TotalSummits from Firebase
        if firebaseData.TotalSummits then
            legacyData.TotalSummits = firebaseData.TotalSummits
            Log("   - TotalSummits:", legacyData.TotalSummits)
        end
        
        -- Get special statuses from Mountains.Nirwana
        local mountainData = firebaseData.Mountains and firebaseData.Mountains[CONFIG.MountainName]
        if mountainData then
            Log("   - Mountain data found for:", CONFIG.MountainName)
            
            if mountainData.VIP == true then
                legacyData.IsVIP = true
                table.insert(legacyData.SpecialTitles, "VIP")
                Log("   - VIP: true")
            end
            
            if mountainData.Akamsi == true then
                legacyData.IsAkamsi = true
                table.insert(legacyData.SpecialTitles, "Akamsi")
                Log("   - Akamsi: true")
            end
            
            if mountainData.SahabatAdmin == true then
                legacyData.IsSahabatAdmin = true
                table.insert(legacyData.SpecialTitles, "SahabatAdmin")
                Log("   - SahabatAdmin: true")
            end
            
            -- Also get summit count from mountain if higher
            if mountainData.Summits and mountainData.Summits > legacyData.TotalSummits then
                Log("   - Using mountain summit count:", mountainData.Summits)
                legacyData.TotalSummits = mountainData.Summits
            end
        end
    else
        Log("⚠️ No Firebase data found - this player may be new or not in Firebase")
    end
    
    Log("")
    Log("========================================")
    Log("📦 ROBLOX DATASTORE FETCH")
    Log("========================================")
    
    -- 2. Fetch OrderedDataStore Summits (use higher value)
    local orderedSummits = fetchOrderedDataStore(LegacySummitsStore, userId, "Summits")
    if orderedSummits and orderedSummits > 0 then
        Log("   Comparing: Firebase TotalSummits =", legacyData.TotalSummits, "vs OrderedDataStore =", orderedSummits)
        if orderedSummits > legacyData.TotalSummits then
            Log("   → Using OrderedDataStore value (higher)")
            legacyData.TotalSummits = orderedSummits
        else
            Log("   → Keeping Firebase value (higher or equal)")
        end
    else
        Log("   No Summits data in OrderedDataStore")
    end
    
    -- 3. Fetch OrderedDataStore Donations
    local donations = fetchOrderedDataStore(LegacyDonationsStore, userId, "Donations")
    if donations and donations > 0 then
        legacyData.TotalDonations = donations
        table.insert(legacyData.SpecialTitles, "Donatur")
        Log("   Added 'Donatur' title for donation")
    else
        Log("   No Donations data in OrderedDataStore")
    end
    
    -- 3.5 Fetch OrderedDataStore TopTimePlayed (Playtime in MINUTES)
    -- Key format: "TimePlayed" + userId (e.g., "TimePlayed8714136305")
    local playtimeKey = PLAYTIME_STAT_PREFIX .. tostring(userId)
    local playtimeMinutes = nil
    local playtimeSuccess, playtimeResult = pcall(function()
        return LegacyPlaytimeStore:GetAsync(playtimeKey)
    end)
    
    if playtimeSuccess and playtimeResult then
        playtimeMinutes = playtimeResult
        -- Convert minutes to seconds (new system uses seconds)
        legacyData.TotalPlaytime = playtimeMinutes * 60
        Log("   ✅ Playtime found:", playtimeMinutes, "minutes (", legacyData.TotalPlaytime, "seconds)")
    else
        Log("   No Playtime data in TopTimePlayed OrderedDataStore")
        if not playtimeSuccess then
            Log("   Error:", playtimeResult)
        end
    end
    
    -- 4. Fetch Wings from FlyTogetherWingsStatus_V2
    local wingsData = fetchDataStore(LegacyWingsStore, userId, "FlyTogetherWingsStatus_V2")
    if wingsData and type(wingsData) == "table" then
        for wingName, owned in pairs(wingsData) do
            if owned == true then
                table.insert(legacyData.OwnedTools, wingName)
            end
        end
    end
    
    -- 5. Fetch Crystal Auras from AuraExchangeData_V2
    -- Format: { OwnedAuras = "Aura1,Aura2,Aura3", ... }
    local crystalData = fetchDataStore(LegacyCrystalAuraStore, "Player_" .. userId, "AuraExchangeData_V2")
    if crystalData and type(crystalData) == "table" then
        local ownedAurasCSV = crystalData.OwnedAuras
        if ownedAurasCSV and ownedAurasCSV ~= "" then
            -- Parse CSV string to array
            local aurasList = string.split(ownedAurasCSV, ",")
            for _, auraName in ipairs(aurasList) do
                -- Trim whitespace
                auraName = string.gsub(auraName, "^%s*(.-)%s*$", "%1")
                if auraName ~= "" then
                    table.insert(legacyData.OwnedAuras, auraName)
                    Log("   - Crystal Aura found:", auraName)
                end
            end
        end
    end
    
    -- ==========================================
    -- FINAL SYNC SUMMARY
    -- ==========================================
    Log("")
    Log("╔════════════════════════════════════════════════════════╗")
    Log("║           📊 LEGACY DATA SYNC SUMMARY                 ║")
    Log("╠════════════════════════════════════════════════════════╣")
    Log("║ Player:", player.Name, "(" .. tostring(userId) .. ")")
    Log("╠════════════════════════════════════════════════════════╣")
    
    -- Firebase status
    if firebaseData then
        Log("║ 🔥 Firebase:         ✅ CONNECTED")
        Log("║    - TotalSummits:   ", firebaseData.TotalSummits or "nil")
        if firebaseData.Mountains and firebaseData.Mountains[CONFIG.MountainName] then
            local m = firebaseData.Mountains[CONFIG.MountainName]
            Log("║    - Mountain.VIP:   ", tostring(m.VIP or false))
            Log("║    - Mountain.Akamsi:", tostring(m.Akamsi or false))
            Log("║    - Mountain.SahabatAdmin:", tostring(m.SahabatAdmin or false))
        else
            Log("║    - Mountains:       nil")
        end
    else
        Log("║ 🔥 Firebase:         ❌ NO DATA")
    end
    
    Log("╠════════════════════════════════════════════════════════╣")
    Log("║ 📦 OrderedDataStore Summits:  ", orderedSummits or "nil")
    Log("║ 📦 OrderedDataStore Donations:", donations or "nil")  
    Log("║ 📦 OrderedDataStore Playtime: ", playtimeMinutes and (playtimeMinutes .. " min") or "nil")
    Log("║ 📦 Wings DataStore:           ", wingsData and "Found" or "nil")
    Log("║ 📦 Crystal Aura DataStore:    ", crystalData and "Found" or "nil")
    Log("╠════════════════════════════════════════════════════════╣")
    Log("║               🎯 FINAL VALUES TO MIGRATE              ║")
    Log("╠════════════════════════════════════════════════════════╣")
    Log("║ TotalSummits:    ", legacyData.TotalSummits)
    Log("║ TotalDonations:  ", legacyData.TotalDonations)
    Log("║ TotalPlaytime:   ", legacyData.TotalPlaytime, "seconds (", math.floor(legacyData.TotalPlaytime / 60), "minutes)")
    Log("║ OwnedTools:      ", #legacyData.OwnedTools, "items")
    Log("║ OwnedAuras:      ", #legacyData.OwnedAuras, "items")
    Log("║ SpecialTitles:   ", #legacyData.SpecialTitles > 0 and table.concat(legacyData.SpecialTitles, ", ") or "(none)")
    Log("║ IsVIP:           ", tostring(legacyData.IsVIP))
    Log("║ IsAkamsi:        ", tostring(legacyData.IsAkamsi))
    Log("║ IsSahabatAdmin:  ", tostring(legacyData.IsSahabatAdmin))
    Log("╚════════════════════════════════════════════════════════╝")
    
    return legacyData
end

-- ==========================================
-- MAIN: Migrate legacy data to new system
-- ==========================================
function DataMigration:MigratePlayer(player, DataHandler)
    local currentData = DataHandler:GetData(player)
    
    if not currentData then
        LogWarn("Cannot migrate - player data not loaded:", player.Name)
        return false
    end
    
    -- Check if already migrated
    if currentData.LegacyDataMigrated == true then
        Log("Player already migrated, skipping:", player.Name)
        return true
    end
    
    Log("Starting migration for:", player.Name)
    
    -- Collect legacy data
    local legacyData = self:CollectLegacyData(player)
    
    -- ==========================================
    -- MERGE DATA
    -- ==========================================
    local migrationChanges = {}
    
    -- 1. TotalSummits - use higher value
    if legacyData.TotalSummits > (currentData.TotalSummits or 0) then
        currentData.TotalSummits = legacyData.TotalSummits
        table.insert(migrationChanges, "TotalSummits: " .. legacyData.TotalSummits)
    end
    
    -- 2. TotalDonations - use higher value
    if legacyData.TotalDonations > (currentData.TotalDonations or 0) then
        currentData.TotalDonations = legacyData.TotalDonations
        table.insert(migrationChanges, "TotalDonations: " .. legacyData.TotalDonations)
    end
    
    -- 2.5 TotalPlaytime - use higher value (stored in seconds)
    if legacyData.TotalPlaytime > (currentData.TotalPlaytime or 0) then
        currentData.TotalPlaytime = legacyData.TotalPlaytime
        local minutes = math.floor(legacyData.TotalPlaytime / 60)
        table.insert(migrationChanges, "TotalPlaytime: " .. minutes .. " minutes")
    end
    
    -- 3. OwnedTools - merge arrays (add wings from FlyTogether)
    for _, toolName in ipairs(legacyData.OwnedTools) do
        if not table.find(currentData.OwnedTools, toolName) then
            table.insert(currentData.OwnedTools, toolName)
            table.insert(migrationChanges, "Added Tool: " .. toolName)
        end
    end
    
    -- 4. OwnedAuras - merge arrays (add auras from Crystal Event)
    for _, auraName in ipairs(legacyData.OwnedAuras) do
        if not table.find(currentData.OwnedAuras or {}, auraName) then
            if not currentData.OwnedAuras then
                currentData.OwnedAuras = {}
            end
            table.insert(currentData.OwnedAuras, auraName)
            table.insert(migrationChanges, "Added Aura: " .. auraName)
        end
    end
    
    -- 5. Special Titles - add unlocked titles
    for _, titleName in ipairs(legacyData.SpecialTitles) do
        if not table.find(currentData.UnlockedTitles or {}, titleName) then
            if not currentData.UnlockedTitles then
                currentData.UnlockedTitles = {"Pendaki"}
            end
            table.insert(currentData.UnlockedTitles, titleName)
            table.insert(migrationChanges, "Unlocked Title: " .. titleName)
        end
    end
    
    -- 6. Set SpecialTitle if player has one (priority: SahabatAdmin > Akamsi > VIP > Donatur)
    if legacyData.IsSahabatAdmin then
        currentData.SpecialTitle = "SahabatAdmin"
        table.insert(migrationChanges, "SpecialTitle: SahabatAdmin")
    elseif legacyData.IsAkamsi then
        currentData.SpecialTitle = "Akamsi"
        table.insert(migrationChanges, "SpecialTitle: Akamsi")
    elseif legacyData.IsVIP then
        currentData.SpecialTitle = "VIP"
        table.insert(migrationChanges, "SpecialTitle: VIP")
    elseif legacyData.TotalDonations > 0 then
        currentData.SpecialTitle = "Donatur"
        table.insert(migrationChanges, "SpecialTitle: Donatur")
    end
    
    -- 7. Unlock summit titles based on TotalSummits
    local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
    if TitleConfig and TitleConfig.SummitTitles then
        local totalSummits = currentData.TotalSummits or 0
        for _, titleData in ipairs(TitleConfig.SummitTitles) do
            if totalSummits >= titleData.MinSummits then
                if not table.find(currentData.UnlockedTitles or {}, titleData.Name) then
                    if not currentData.UnlockedTitles then
                        currentData.UnlockedTitles = {"Pendaki"}
                    end
                    table.insert(currentData.UnlockedTitles, titleData.Name)
                    table.insert(migrationChanges, "Unlocked Summit Title: " .. titleData.Name)
                end
            end
        end
    end
    
    -- ==========================================
    -- MARK AS MIGRATED
    -- ==========================================
    currentData.LegacyDataMigrated = true
    currentData.MigrationDate = os.time()
    
    -- Save immediately
    local saveSuccess = DataHandler:SavePlayer(player)
    
    -- ==========================================
    -- MIGRATION RESULT SUMMARY
    -- ==========================================
    Log("")
    Log("╔════════════════════════════════════════════════════════════════╗")
    if saveSuccess then
        Log("║     ✅✅✅ MIGRATION SUCCESS ✅✅✅                              ║")
    else
        Log("║     ⚠️⚠️⚠️ MIGRATION COMPLETE BUT SAVE FAILED ⚠️⚠️⚠️          ║")
    end
    Log("╠════════════════════════════════════════════════════════════════╣")
    Log("║ Player:        ", player.Name, "(", player.UserId, ")")
    Log("║ Migration Time:", os.date("%Y-%m-%d %H:%M:%S", currentData.MigrationDate))
    Log("╠════════════════════════════════════════════════════════════════╣")
    Log("║                    📋 CHANGES APPLIED                          ║")
    Log("╠════════════════════════════════════════════════════════════════╣")
    
    if #migrationChanges > 0 then
        for _, change in ipairs(migrationChanges) do
            Log("║   ✓", change)
        end
    else
        Log("║   (No changes - player has no legacy data to migrate)")
    end
    
    Log("╠════════════════════════════════════════════════════════════════╣")
    Log("║                    📊 FINAL PLAYER DATA                        ║")
    Log("╠════════════════════════════════════════════════════════════════╣")
    Log("║ TotalSummits:    ", currentData.TotalSummits)
    Log("║ TotalDonations:  ", currentData.TotalDonations)
    Log("║ TotalPlaytime:   ", math.floor((currentData.TotalPlaytime or 0) / 60), "minutes")
    Log("║ Money:           ", currentData.Money)
    Log("║ SpecialTitle:    ", currentData.SpecialTitle or "(none)")
    Log("║ Title:           ", currentData.Title)
    Log("║ OwnedTools:      ", #currentData.OwnedTools, "items")
    Log("║ UnlockedTitles:  ", table.concat(currentData.UnlockedTitles or {}, ", "))
    Log("║ LegacyMigrated:  ", tostring(currentData.LegacyDataMigrated))
    Log("╠════════════════════════════════════════════════════════════════╣")
    
    if saveSuccess then
        Log("║ 💾 Save Status:  ✅ SAVED TO DATASTORE")
    else
        Log("║ 💾 Save Status:  ❌ SAVE FAILED - DATA MAY BE LOST!")
    end
    
    Log("╚════════════════════════════════════════════════════════════════╝")
    
    if saveSuccess then
        print("[MIGRATION] ✅ SUCCESS for", player.Name, "- Summits:", currentData.TotalSummits, "Titles:", table.concat(currentData.UnlockedTitles or {}, ", "))
    else
        warn("[MIGRATION] ⚠️ SAVE FAILED for", player.Name, "- Data may be lost on rejoin!")
    end
    
    return saveSuccess
end

-- ==========================================
-- UTILITY: Check if player needs migration
-- ==========================================
function DataMigration:NeedsMigration(player, DataHandler)
    local currentData = DataHandler:GetData(player)
    if not currentData then
        return false
    end
    return currentData.LegacyDataMigrated ~= true
end

-- ==========================================
-- UTILITY: Get migration status
-- ==========================================
function DataMigration:GetMigrationStatus(player, DataHandler)
    local currentData = DataHandler:GetData(player)
    if not currentData then
        return {
            status = "NO_DATA",
            migrated = false,
        }
    end
    
    return {
        status = currentData.LegacyDataMigrated and "MIGRATED" or "PENDING",
        migrated = currentData.LegacyDataMigrated == true,
        migrationDate = currentData.MigrationDate,
    }
end

print("✅ [DATA MIGRATION] Module loaded")

return DataMigration
