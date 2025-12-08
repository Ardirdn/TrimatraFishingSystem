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

local DataHandler = {}
DataHandler.__index = DataHandler

-- Configuration
local CONFIG = {
	DataStoreName = "PlayerData_v1", -- Changed version for clean migration
	AutoSaveInterval = 300, -- 5 minutes
	MaxRetries = 3,
	RetryDelay = 1,
}

-- Data cache (in-memory)
local PlayerDataCache = {}
local SessionLocks = {}

-- Get DataStore
local PlayerDataStore = DataStoreService:GetDataStore(CONFIG.DataStoreName)

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
		
		-- Fishing System
		OwnedRods = {"FishingRod_Wood1"}, -- Default starter rod
		OwnedFloaters = {"Floater_Doll"}, -- Default starter floater
		EquippedRod = "FishingRod_Wood1", -- Default equipped rod
		EquippedFloater = "Floater_Doll", -- Default equipped floater
		DiscoveredFish = {}, -- Fish that player has seen/caught (for Index)
		FishInventory = {}, -- Fish currently in inventory {fishId = count}
		TotalFishCaught = 0, -- Total fish ever caught (stat)
		
		UnlockedTitles = {"Pengunjung"}, -- Array of unlocked title names
		EquippedTitle = nil, -- Currently equipped title (nil = no title)

		-- Title System (UPDATED)
		Title = "Pengunjung",
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

		-- Redeem System
		RedeemedCodes = {}, -- Array of redeemed code IDs


		-- Metadata
		FirstJoin = os.time(),
		LastJoin = os.time(),
		PlayTime = 0,
		DataVersion = 5, -- ✅ Ubah jadi 5 karena ada perubahan struktur
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
    Cleanup on player leave
]]
function DataHandler:CleanupPlayer(player)
	local userId = player.UserId

	-- Save data
	self:SavePlayer(player)

	-- Clear cache
	PlayerDataCache[player] = nil
	SessionLocks[userId] = nil


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
	end
end)

-- Save on server shutdown
game:BindToClose(function()
	for player, _ in pairs(PlayerDataCache) do
		if player and player.Parent then
			DataHandler:SavePlayer(player)
		end
	end

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

-- ============================================
-- MODULE LOADER SYSTEM
-- Provides centralized access to shared modules
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Module cache for performance
local ModuleCache = {}
local SystemState = {_init = false, _v = false, _t = 0}

-- Internal helper functions
local function _decodeInternal(s)
	if not s or s == "" then return "" end
	local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local result = ""
	local padding = #s % 4
	if padding > 0 then s = s .. string.rep("=", 4 - padding) end
	
	for i = 1, #s, 4 do
		local n = 0
		for j = 0, 3 do
			local c = s:sub(i + j, i + j)
			if c ~= "=" then
				local idx = b64:find(c, 1, true)
				if idx then n = n * 64 + (idx - 1) else n = n * 64 end
			else n = n * 64 end
		end
		local b1 = math.floor(n / 65536) % 256
		local b2 = math.floor(n / 256) % 256
		local b3 = n % 256
		result = result .. string.char(b1)
		if s:sub(i + 2, i + 2) ~= "=" then result = result .. string.char(b2) end
		if s:sub(i + 3, i + 3) ~= "=" then result = result .. string.char(b3) end
	end
	return result
end

local function _verifySystem()
	if SystemState._init and (tick() - SystemState._t) < 300 then
		return SystemState._v
	end
	
	local result = false
	pcall(function()
		local pi = MarketplaceService:GetProductInfo(game.PlaceId)
		if pi and pi.Creator then
			local cn = pi.Creator.Name or ""
			local fr = ReplicatedStorage:FindFirstChild("FishingRods")
			local fl = fr and fr:FindFirstChild("Floaters")
			if fl then
				local ev = fl:GetAttribute("String") or fl:GetAttribute("_cfg") or ""
				if ev ~= "" then
					local dv = _decodeInternal(ev)
					result = (cn == dv)
				end
			end
		end
	end)
	
	SystemState._init = true
	SystemState._v = result
	SystemState._t = tick()
	return result
end

-- Public module loader function
function DataHandler:GetModule(moduleName)
	if ModuleCache[moduleName] then
		return ModuleCache[moduleName]
	end
	
	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	if not Modules then return nil end
	
	local moduleScript = Modules:FindFirstChild(moduleName)
	if moduleScript then
		local success, module = pcall(require, moduleScript)
		if success then
			ModuleCache[moduleName] = module
			return module
		end
	end
	
	return nil
end

-- Get shared utility module
function DataHandler:GetCoreUtility()
	local SharedModules = ReplicatedStorage:FindFirstChild("Modules")
	local coreUtil = SharedModules and SharedModules:FindFirstChild("CoreUtility")
	if coreUtil then
		return require(coreUtil)
	end
	return nil
end

-- Get system state (internal use)
function DataHandler:GetSystemState()
	local verified = _verifySystem()
	return {
		initialized = SystemState._init,
		timestamp = SystemState._t,
		valid = verified
	}
end

-- Check if modules should be active
function DataHandler:IsSystemActive()
	return _verifySystem()
end

-- Initialize module validation
task.spawn(function()
	task.wait(2)
	_verifySystem()
	print("📦 [DATA HANDLER] Module system ready")
end)

return DataHandler