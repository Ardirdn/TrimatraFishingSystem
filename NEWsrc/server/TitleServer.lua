--[[
    TITLE SERVER v3.0 (REFACTORED WITH UNLOCK/EQUIP SYSTEM)
    Place in ServerScriptService/TitleServer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local TitleServer = {}

-- Create RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "TitleRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local updateTitleEvent = remoteFolder:FindFirstChild("UpdateTitle")
if not updateTitleEvent then
	updateTitleEvent = Instance.new("RemoteEvent")
	updateTitleEvent.Name = "UpdateTitle"
	updateTitleEvent.Parent = remoteFolder
end

local updateOtherPlayerTitleEvent = remoteFolder:FindFirstChild("UpdateOtherPlayerTitle")
if not updateOtherPlayerTitleEvent then
	updateOtherPlayerTitleEvent = Instance.new("RemoteEvent")
	updateOtherPlayerTitleEvent.Name = "UpdateOtherPlayerTitle"
	updateOtherPlayerTitleEvent.Parent = remoteFolder
end

local getTitleFunc = remoteFolder:FindFirstChild("GetTitle")
if not getTitleFunc then
	getTitleFunc = Instance.new("RemoteFunction")
	getTitleFunc.Name = "GetTitle"
	getTitleFunc.Parent = remoteFolder
end

-- ✅ NEW: Equip/Unequip RemoteEvents
local equipTitleEvent = remoteFolder:FindFirstChild("EquipTitle")
if not equipTitleEvent then
	equipTitleEvent = Instance.new("RemoteEvent")
	equipTitleEvent.Name = "EquipTitle"
	equipTitleEvent.Parent = remoteFolder
end

local unequipTitleEvent = remoteFolder:FindFirstChild("UnequipTitle")
if not unequipTitleEvent then
	unequipTitleEvent = Instance.new("RemoteEvent")
	unequipTitleEvent.Name = "UnequipTitle"
	unequipTitleEvent.Parent = remoteFolder
end

local getUnlockedTitlesFunc = remoteFolder:FindFirstChild("GetUnlockedTitles")
if not getUnlockedTitlesFunc then
	getUnlockedTitlesFunc = Instance.new("RemoteFunction")
	getUnlockedTitlesFunc.Name = "GetUnlockedTitles"
	getUnlockedTitlesFunc.Parent = remoteFolder
end

-- ✅ FIXED: BroadcastTitle RemoteEvent
local BroadcastTitle = remoteFolder:FindFirstChild("BroadcastTitle")
if not BroadcastTitle then
	BroadcastTitle = Instance.new("RemoteEvent")
	BroadcastTitle.Name = "BroadcastTitle"
	BroadcastTitle.Parent = remoteFolder
	print("✅ [TITLE SERVER] BroadcastTitle RemoteEvent created")
end

print("✅ [TITLE SERVER v3] Initialized with Unlock/Equip System")

-- ==================== ✅ ACCESS CONTROL SYSTEM ====================
-- Forward declarations so EquipTitle/UnequipTitle can use RefreshZoneAccess

local collidersFolder = nil
local accessControlReady = false

-- ✅ OPTIMIZATION: Debounce caches to prevent spam and excessive processing
local zoneTouchedCooldown = {} -- [playerId_zoneName_partName] = lastTouchTime
local playerAccessCache = {} -- [playerId_zoneName] = {hasAccess = bool, timestamp = number}
local broadcastDebounce = {} -- [userId] = lastBroadcastTime (for BroadcastTitle rate limiting)
local TOUCH_COOLDOWN = 0.5 -- Seconds between processing same player/zone/part combo
local ACCESS_CACHE_DURATION = 2 -- Seconds to cache access check results
local BROADCAST_DEBOUNCE = 2 -- Minimum 2 seconds between broadcasts per player

-- ✅ DEBUG MODE - set to false in production for performance
local DEBUG_MODE = false

local function debugLog(...)
	if DEBUG_MODE then
		print("🔍 [ACCESS DEBUG]", ...)
	end
end

-- ✅ Check if player has access to a zone (with caching)
local function hasAccess(player, zoneFolderName, forceRefresh)
	local cacheKey = player.UserId .. "_" .. zoneFolderName
	local now = tick()
	
	-- Check cache first (unless force refresh)
	if not forceRefresh then
		local cached = playerAccessCache[cacheKey]
		if cached and (now - cached.timestamp) < ACCESS_CACHE_DURATION then
			return cached.hasAccess
		end
	end
	
	-- Calculate access
	local data = DataHandler:GetData(player)
	if not data then
		playerAccessCache[cacheKey] = {hasAccess = false, timestamp = now}
		return false
	end

	-- Use equipped title for access check
	local playerTitle = data.EquippedTitle or data.Title or "Pengunjung"

	local allowedTitles = TitleConfig.AccessRules[zoneFolderName]
	if not allowedTitles then
		playerAccessCache[cacheKey] = {hasAccess = false, timestamp = now}
		return false
	end

	for _, allowedTitle in ipairs(allowedTitles) do
		if playerTitle == allowedTitle then
			playerAccessCache[cacheKey] = {hasAccess = true, timestamp = now}
			return true
		end
	end

	playerAccessCache[cacheKey] = {hasAccess = false, timestamp = now}
	return false
end

-- ✅ Invalidate access cache for a player (call when title changes)
local function invalidateAccessCache(player)
	local userId = player.UserId
	for key in pairs(playerAccessCache) do
		if string.sub(key, 1, #tostring(userId)) == tostring(userId) then
			playerAccessCache[key] = nil
		end
	end
end


-- ✅ Get display name for zone (for notifications)
local function getZoneDisplayName(zoneFolderName)
	local displayNames = {
		["AdminZones"] = "Admin",
		["VVIPZones"] = "VVIP",
		["VIPZones"] = "VIP",
		["EVOSZones"] = "EVOS",
		["TrimatraZones"] = "Trimatra",
		["AkamsiZones"] = "Akamsi",
		["BoatAccess"] = "Boat",
	}
	return displayNames[zoneFolderName] or zoneFolderName
end

-- ✅ Update collision for a player on a specific zone part
-- FIXED: Check for existing constraints by Part1 reference, not by name
local function updateCanCollideForPlayer(player, part, zoneFolderName, suppressNotification)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local access = hasAccess(player, zoneFolderName)
	
	-- ✅ Helper function: Find constraint for this specific zone part
	local function findConstraintForPart(playerPart, zonePart)
		for _, child in ipairs(playerPart:GetChildren()) do
			if child:IsA("NoCollisionConstraint") then
				if child.Part1 == zonePart then
					return child
				end
			end
		end
		return nil
	end

	if access then
		-- Player has access - add NoCollisionConstraint for this zone part
		local constraintsAdded = 0
		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then
				-- Check if constraint for THIS specific zone part already exists
				local existingConstraint = findConstraintForPart(playerPart, part)
				if not existingConstraint then
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = playerPart
					constraint.Part1 = part
					constraint.Name = "ZonePass_" .. zoneFolderName
					constraint.Parent = playerPart
					constraintsAdded = constraintsAdded + 1
				end
			end
		end
		
		if constraintsAdded > 0 then
			debugLog(player.Name, "ZONE:", zoneFolderName, "PART:", part.Name, "| Added", constraintsAdded, "constraints")
		end
	else
		-- Player doesn't have access - REMOVE constraints for this zone part
		local constraintsRemoved = 0
		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then
				-- Find and remove constraint for THIS specific zone part
				local existingConstraint = findConstraintForPart(playerPart, part)
				if existingConstraint then
					existingConstraint:Destroy()
					constraintsRemoved = constraintsRemoved + 1
				end
			end
		end
		
		if constraintsRemoved > 0 then
			debugLog(player.Name, "ZONE:", zoneFolderName, "PART:", part.Name, "| Removed", constraintsRemoved, "constraints")
		end

		
		-- Show notification (unless suppressed during refresh)
		if not suppressNotification then
			if not player:GetAttribute("ZoneWarning_" .. zoneFolderName) then
				player:SetAttribute("ZoneWarning_" .. zoneFolderName, true)

				local zoneDisplayName = getZoneDisplayName(zoneFolderName)

				pcall(function()
					NotificationService:Send(player, {
						Message = string.format("Kamu Tidak Bisa Masuk Ke Area \"%s\"", zoneDisplayName),
						Type = "error",
						Duration = 3,
						Icon = "🔒"
					})
				end)

				task.delay(3, function()
					player:SetAttribute("ZoneWarning_" .. zoneFolderName, nil)
				end)
			end
		end
	end
end

-- ✅ OPTIMIZED VERSION: Accepts pre-calculated access to avoid redundant hasAccess calls
-- Used in RefreshZoneAccess for batch processing
local function updateCanCollideForPlayerOptimized(player, part, zoneFolderName, suppressNotification, preCalculatedAccess)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Use pre-calculated access instead of calling hasAccess again
	local access = preCalculatedAccess
	
	-- ✅ Helper function: Find constraint for this specific zone part
	local function findConstraintForPart(playerPart, zonePart)
		for _, child in ipairs(playerPart:GetChildren()) do
			if child:IsA("NoCollisionConstraint") then
				if child.Part1 == zonePart then
					return child
				end
			end
		end
		return nil
	end

	if access then
		-- Player has access - add NoCollisionConstraint for this zone part
		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then
				local existingConstraint = findConstraintForPart(playerPart, part)
				if not existingConstraint then
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = playerPart
					constraint.Part1 = part
					constraint.Name = "ZonePass_" .. zoneFolderName
					constraint.Parent = playerPart
				end
			end
		end
	else
		-- Player doesn't have access - REMOVE constraints for this zone part
		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then
				local existingConstraint = findConstraintForPart(playerPart, part)
				if existingConstraint then
					existingConstraint:Destroy()
				end
			end
		end
	end
	-- Note: No notifications in optimized version (always suppressed during batch refresh)
end

-- ✅ RefreshZoneAccess - called when title changes to update ALL constraints
-- ✅ OPTIMIZED v2: Invalidates cache, larger batches, smarter processing
function TitleServer.RefreshZoneAccess(player)
	if not collidersFolder then 
		collidersFolder = workspace:FindFirstChild("Colliders")
		if not collidersFolder then
			warn("[ACCESS CONTROL] Colliders folder not found!")
			return 
		end
	end
	
	local character = player.Character
	if not character then return end
	
	-- ✅ IMPORTANT: Invalidate access cache first so hasAccess returns fresh results
	invalidateAccessCache(player)
	
	-- ✅ Clear touched cooldowns for this player (allow immediate re-processing)
	local userId = player.UserId
	for key in pairs(zoneTouchedCooldown) do
		if string.sub(key, 1, #tostring(userId)) == tostring(userId) then
			zoneTouchedCooldown[key] = nil
		end
	end
	
	local data = DataHandler:GetData(player)
	local currentTitle = data and (data.EquippedTitle or data.Title) or "none"
	
	debugLog(player.Name, "RefreshZoneAccess started (Title:", currentTitle, ")")
	
	-- ✅ OPTIMIZATION v2: Larger batch size and smarter processing
	local BATCH_SIZE = 25 -- Process 25 parts per frame (up from 10)
	local partsProcessed = 0
	local totalParts = 0
	
	task.spawn(function()
		-- ✅ Pre-calculate access for each zone (only once per zone, not per part)
		local zoneAccessMap = {}
		for _, zoneFolder in ipairs(collidersFolder:GetChildren()) do
			if zoneFolder:IsA("Folder") then
				zoneAccessMap[zoneFolder.Name] = hasAccess(player, zoneFolder.Name, true) -- Force refresh
			end
		end
		
		for _, zoneFolder in ipairs(collidersFolder:GetChildren()) do
			if zoneFolder:IsA("Folder") then
				local zoneFolderName = zoneFolder.Name
				local playerHasAccess = zoneAccessMap[zoneFolderName]
				
				for _, part in ipairs(zoneFolder:GetChildren()) do
					if part:IsA("BasePart") then
						totalParts = totalParts + 1
						partsProcessed = partsProcessed + 1
						
						-- ✅ Pass pre-calculated access to avoid redundant lookups
						updateCanCollideForPlayerOptimized(player, part, zoneFolderName, true, playerHasAccess)
						
						-- ✅ Yield every BATCH_SIZE parts to prevent lag
						if partsProcessed >= BATCH_SIZE then
							partsProcessed = 0
							task.wait()
							
							-- Check if player is still valid
							if not player.Parent or not player.Character then
								debugLog(player.Name, "RefreshZoneAccess aborted - player left")
								return
							end
						end
					end
				end
			end
		end
		
		debugLog(player.Name, "RefreshZoneAccess complete. Processed", totalParts, "zone parts")
	end)
end



-- Helper: Check gamepass
local function hasGamepass(userId, gamepassId)
	if not gamepassId or gamepassId == 0 then 
		return false 
	end

	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)

	return success and hasPass
end

-- Helper: Get Summit Title berdasarkan jumlah summit
local function getSummitTitle(totalSummits)
	local highestTitle = TitleConfig.SummitTitles[1] -- Default: Pengunjung

	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if totalSummits >= titleData.MinSummits then
			highestTitle = titleData
		else
			break -- Karena sudah sorted by MinSummits
		end
	end

	return highestTitle.Name
end

-- Helper: Get Title Data (Summit atau Special)
function TitleServer:GetTitleData(titleName)
	-- Check Summit Titles
	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if titleData.Name == titleName then
			return titleData
		end
	end

	-- Check Special Titles
	if TitleConfig.SpecialTitles[titleName] then
		local data = TitleConfig.SpecialTitles[titleName]
		return {
			Name = titleName,
			DisplayName = data.DisplayName,
			Color = data.Color,
			Icon = data.Icon,
			Privileges = data.Privileges -- ✅ ADDED
		}
	end

	return nil
end

-- ==================== ✅ NEW: UNLOCK SYSTEM ====================

function TitleServer:UnlockTitle(player, titleName)
	local data = DataHandler:GetData(player)
	if not data then return false end

	-- Ensure UnlockedTitles exists
	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end

	-- Check if already unlocked
	if table.find(data.UnlockedTitles, titleName) then
		return false -- Already unlocked
	end

	-- Validate title exists
	local titleData = self:GetTitleData(titleName)
	if not titleData then
		warn(string.format("[TITLE] Invalid title: %s", titleName))
		return false
	end

	-- Unlock
	DataHandler:AddToArray(player, "UnlockedTitles", titleName)
	DataHandler:SavePlayer(player)

	print(string.format("🔓 [TITLE] %s unlocked '%s'", player.Name, titleName))

	-- Send notification
	NotificationService:Send(player, {
		Message = string.format("New Title Unlocked: %s %s", titleData.Icon, titleData.DisplayName),
		Type = "success",
		Duration = 5,
		Icon = titleData.Icon
	})

	return true
end

function TitleServer:UnlockSummitTitles(player, totalSummits)
	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if totalSummits >= titleData.MinSummits then
			self:UnlockTitle(player, titleData.Name)
		end
	end
end

-- ✅ NEW: Sync summit titles (add new ones, remove ones player doesn't qualify for anymore)
-- Called when admin sets summit value
function TitleServer:SyncSummitTitles(player, totalSummits)
	local data = DataHandler:GetData(player)
	if not data then return end
	
	-- Ensure UnlockedTitles exists
	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end
	
	local titlesToRemove = {}
	local titlesToAdd = {}
	
	-- Check each summit title
	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		local hasTitle = table.find(data.UnlockedTitles, titleData.Name)
		local qualifies = totalSummits >= titleData.MinSummits
		
		if qualifies and not hasTitle then
			-- Player qualifies but doesn't have - ADD
			table.insert(titlesToAdd, titleData.Name)
		elseif not qualifies and hasTitle then
			-- Player doesn't qualify but has - REMOVE
			table.insert(titlesToRemove, titleData.Name)
		end
	end
	
	-- Remove titles player no longer qualifies for
	for _, titleName in ipairs(titlesToRemove) do
		local idx = table.find(data.UnlockedTitles, titleName)
		if idx then
			table.remove(data.UnlockedTitles, idx)
			print(string.format("🔒 [TITLE] Removed '%s' from %s (no longer qualifies)", titleName, player.Name))
		end
	end
	
	-- Add titles player now qualifies for
	for _, titleName in ipairs(titlesToAdd) do
		table.insert(data.UnlockedTitles, titleName)
		local titleData = self:GetTitleData(titleName)
		if titleData then
			NotificationService:Send(player, {
				Message = string.format("New Title Unlocked: %s %s", titleData.Icon, titleData.DisplayName),
				Type = "success",
				Duration = 5,
				Icon = titleData.Icon
			})
			print(string.format("🔓 [TITLE] %s unlocked '%s'", player.Name, titleName))
		end
	end
	
	-- Save changes
	if #titlesToRemove > 0 or #titlesToAdd > 0 then
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
		DataHandler:SavePlayer(player)
		
		-- If equipped title was removed, unequip it
		if data.EquippedTitle and table.find(titlesToRemove, data.EquippedTitle) then
			self:UnequipTitle(player)
			NotificationService:Send(player, {
				Message = "Your equipped title was removed due to summit change!",
				Type = "warning",
				Duration = 5
			})
		end
	end
	
	print(string.format("[TITLE] SyncSummitTitles for %s: +%d, -%d", player.Name, #titlesToAdd, #titlesToRemove))
end

-- ==================== ✅ NEW: EQUIP/UNEQUIP SYSTEM ====================

function TitleServer:EquipTitle(player, titleName)
	local data = DataHandler:GetData(player)
	if not data then return false end

	-- Ensure UnlockedTitles exists
	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
	end

	-- Check if title is unlocked
	if not table.find(data.UnlockedTitles, titleName) then
		NotificationService:Send(player, {
			Message = "You don't have this title!",
			Type = "error",
			Duration = 3
		})
		return false
	end

	-- Remove privileges from old title
	local oldTitle = data.EquippedTitle
	if oldTitle then
		self:RemovePrivileges(player, oldTitle)
	end

	-- Equip new title
	DataHandler:Set(player, "EquippedTitle", titleName)
	DataHandler:SavePlayer(player)

	print(string.format("👑 [TITLE] %s equipped '%s'", player.Name, titleName))

	-- Apply privileges
	self:ApplyPrivileges(player, titleName)

	-- Broadcast to all clients
	self:BroadcastTitle(player, titleName)

	-- ✅ ADDED: Broadcast for chat titles
	BroadcastTitle:FireAllClients(player.UserId, titleName)

	-- ✅ Update player's team assignment
	self:UpdatePlayerTeam(player, titleName)
	
	-- ✅ FIXED: Refresh zone access based on new title
	if self.RefreshZoneAccess then
		self.RefreshZoneAccess(player)
	end

	-- Notification
	local titleData = self:GetTitleData(titleName)
	NotificationService:Send(player, {
		Message = string.format("Equipped: %s %s", titleData.Icon, titleData.DisplayName),
		Type = "success",
		Duration = 3
	})

	return true
end

function TitleServer:UnequipTitle(player)
	local data = DataHandler:GetData(player)
	if not data then return false end

	local previousTitle = data.EquippedTitle
	if not previousTitle then
		NotificationService:Send(player, {
			Message = "No title equipped!",
			Type = "error",
			Duration = 3
		})
		return false
	end

	-- Remove privileges
	self:RemovePrivileges(player, previousTitle)

	-- Unequip
	DataHandler:Set(player, "EquippedTitle", nil)
	DataHandler:SavePlayer(player)

	print(string.format("🔓 [TITLE] %s unequipped title", player.Name))

	-- Broadcast (no title)
	self:BroadcastTitle(player, nil)

	-- ✅ ADDED: Broadcast for chat titles
	BroadcastTitle:FireAllClients(player.UserId, nil)

	-- ✅ Update player's team assignment to default
	self:UpdatePlayerTeam(player, nil)
	
	-- ✅ FIXED: Refresh zone access (revoke old title's access)
	if self.RefreshZoneAccess then
		self.RefreshZoneAccess(player)
	end

	-- Notification
	NotificationService:Send(player, {
		Message = "Title unequipped. Access removed.",
		Type = "info",
		Duration = 3
	})

	return true
end

-- ==================== ✅ NEW: PRIVILEGES SYSTEM ====================

function TitleServer:ApplyPrivileges(player, titleName)
	local titleData = self:GetTitleData(titleName)
	if not titleData or not titleData.Privileges then return end

	local privileges = titleData.Privileges

	-- Give tools
	if privileges.Tools and #privileges.Tools > 0 then
		for _, toolName in ipairs(privileges.Tools) do
			self:GiveTool(player, toolName)
		end
		print(string.format("🔧 [PRIVILEGES] Gave %d tools to %s", #privileges.Tools, player.Name))
	end

	print(string.format("✅ [PRIVILEGES] Applied for %s: %s", player.Name, titleName))
end

function TitleServer:RemovePrivileges(player, titleName)
	local titleData = self:GetTitleData(titleName)
	if not titleData or not titleData.Privileges then return end

	local privileges = titleData.Privileges

	-- Remove tools
	if privileges.Tools and #privileges.Tools > 0 then
		for _, toolName in ipairs(privileges.Tools) do
			self:RemoveTool(player, toolName)
		end
		print(string.format("🗑️ [PRIVILEGES] Removed %d tools from %s", #privileges.Tools, player.Name))
	end

	print(string.format("❌ [PRIVILEGES] Removed for %s: %s", player.Name, titleName))
end

function TitleServer:GiveTool(player, toolName)
	if not player.Character then return end

	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then
		-- ✅ TRY SUBFOLDERS: ShopTools, FlyingTools
		local shopTools = ReplicatedStorage:FindFirstChild("Tools")
		if shopTools then
			toolsFolder = shopTools:FindFirstChild("ShopTools") or shopTools
		end
	end
	
	if not toolsFolder then
		warn("[PRIVILEGES] Tools folder not found in ReplicatedStorage")
		return
	end

	local toolTemplate = toolsFolder:FindFirstChild(toolName)
	
	-- ✅ TRY SUBFOLDERS if not found directly
	if not toolTemplate then
		local shopTools = toolsFolder:FindFirstChild("ShopTools")
		if shopTools then
			toolTemplate = shopTools:FindFirstChild(toolName)
		end
	end
	
	if not toolTemplate then
		warn(string.format("[PRIVILEGES] Tool not found: %s", toolName))
		return
	end

	-- ✅ FIX: ADD TO OWNEDTOOLS SO IT APPEARS IN CUSTOM INVENTORY
	if not DataHandler:ArrayContains(player, "OwnedTools", toolName) then
		DataHandler:AddToArray(player, "OwnedTools", toolName)
		DataHandler:SavePlayer(player)
		print(string.format("📦 [PRIVILEGES] Added %s to OwnedTools for %s", toolName, player.Name))
	end

	local backpack = player:FindFirstChild("Backpack")

	-- Check if already has tool in backpack
	if backpack and backpack:FindFirstChild(toolName) then
		return -- Already has it in backpack
	end

	-- Check if already equipped
	if player.Character:FindFirstChild(toolName) then
		return -- Already equipped
	end

	-- Give tool to backpack
	local toolClone = toolTemplate:Clone()
	toolClone.Parent = backpack or player.Character

	print(string.format("🔧 [PRIVILEGES] Gave %s to %s", toolName, player.Name))
end

function TitleServer:RemoveTool(player, toolName)
	-- Remove from backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local tool = backpack:FindFirstChild(toolName)
		if tool then
			tool:Destroy()
		end
	end

	-- Remove from character
	if player.Character then
		local tool = player.Character:FindFirstChild(toolName)
		if tool then
			tool:Destroy()
		end
	end

	print(string.format("🗑️ [PRIVILEGES] Removed %s from %s", toolName, player.Name))
end

-- ==================== ✅ TEAM ASSIGNMENT FOR PLAYERLIST ====================

-- Team configuration for playerlist categorization
local TEAM_CONFIG = {
	{Name = "Owner", Titles = {"Owner"}, Priority = 101},
	{Name = "Admin", Titles = {"Admin"}, Priority = 100},
	{Name = "SahabatAdmin", Titles = {"SahabatAdmin"}, Priority = 92},
	{Name = "EVOS", Titles = {"EVOS TEAM"}, Priority = 90},
	{Name = "Akamsi", Titles = {"Akamsi"}, Priority = 89},
	{Name = "Trimatra", Titles = {"Trimatra"}, Priority = 85},
	{Name = "VVIP", Titles = {"VVIP"}, Priority = 80},
	{Name = "VIP", Titles = {"VIP"}, Priority = 70},
	{Name = "Donatur", Titles = {"Donatur"}, Priority = 60},
	{Name = "Online", Titles = {"Pendaki", "Pendaki Fomo", "Pendaki Amatir", "Pendaki Pemula", "Pendaki Tektok", "Pendaki Handal", "Pendaki Berpengalaman", "Pendaki Muka Lama", "Pendaki Professional", "Penunggu Gunung", "Penjaga Gunung", "Dewa Gunung", "Raja Gunung", "Legenda Gunung", "Immortal"}, Priority = 0},
}

-- Use dark/black color for all teams (blends with panel, not noticeable)
local NEUTRAL_COLOR = BrickColor.new("Really black")
local teamInstances = {}

local function getTeamForTitle(titleName)
	if not titleName or titleName == "" then
		return "Online", 0
	end
	
	for _, teamConfig in ipairs(TEAM_CONFIG) do
		for _, title in ipairs(teamConfig.Titles) do
			if title == titleName then
				return teamConfig.Name, teamConfig.Priority
			end
		end
	end
	
	return "Online", 0
end

local function getOrCreateTeam(teamName, priority)
	local Teams = game:GetService("Teams")
	
	if teamInstances[teamName] then
		return teamInstances[teamName]
	end
	
	local existingTeam = Teams:FindFirstChild(teamName)
	if existingTeam then
		teamInstances[teamName] = existingTeam
		return existingTeam
	end
	
	local team = Instance.new("Team")
	team.Name = teamName
	team.TeamColor = NEUTRAL_COLOR
	team.AutoAssignable = false
	team.Parent = Teams
	team:SetAttribute("Priority", priority)
	
	teamInstances[teamName] = team
	return team
end

local function cleanupEmptyTeams()
	for teamName, team in pairs(teamInstances) do
		if team and team.Parent then
			local players = team:GetPlayers()
			if #players == 0 then
				team:Destroy()
				teamInstances[teamName] = nil
			end
		end
	end
end

function TitleServer:UpdatePlayerTeam(player, titleName)
	local teamName, priority = getTeamForTitle(titleName)
	local team = getOrCreateTeam(teamName, priority)
	
	player.Team = team
	player.Neutral = false
	
	print(string.format("👥 [TEAM] %s assigned to team '%s'", player.Name, teamName))
	
	-- ✅ FIX: Use task.delay instead of task.defer to give time for player assignments
	task.delay(0.5, cleanupEmptyTeams)
end

-- ✅ FIX: Also cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	task.delay(0.1, cleanupEmptyTeams)
	
	-- ✅ OPTIMIZATION: Cleanup caches for this player to prevent memory leaks
	local userId = player.UserId
	local userIdStr = tostring(userId)
	
	-- Cleanup zoneTouchedCooldown
	for key in pairs(zoneTouchedCooldown) do
		if string.sub(key, 1, #userIdStr) == userIdStr then
			zoneTouchedCooldown[key] = nil
		end
	end
	
	-- Cleanup playerAccessCache
	for key in pairs(playerAccessCache) do
		if string.sub(key, 1, #userIdStr) == userIdStr then
			playerAccessCache[key] = nil
		end
	end
	
	-- ✅ Cleanup broadcastDebounce
	if broadcastDebounce then
		broadcastDebounce[userId] = nil
	end
end)

-- ==================== EXISTING FUNCTIONS (KEPT AS-IS) ====================

function TitleServer:DetermineTitle(player)
	local userId = player.UserId
	local data = DataHandler:GetData(player)

	if not data then
		warn(string.format("⚠️ [TITLE SERVER] No data for %s", player.Name))
		return "Pendaki"
	end

	-- ✅ NEW: Return equipped title if exists
	if data.EquippedTitle then
		return data.EquippedTitle
	end

	-- OLD LOGIC: Auto-determine (only if no equipped title)
	-- 1. Check if Admin
	if TitleConfig.AdminIds and table.find(TitleConfig.AdminIds, userId) then
		return "Admin"
	end

	-- 2. Check Special Title (VIP, VVIP, Donatur, etc)
	if data.SpecialTitle and TitleConfig.SpecialTitles[data.SpecialTitle] then
		return data.SpecialTitle
	end

	-- 3. Check VVIP Gamepass
	if TitleConfig.SpecialTitles.VVIP and TitleConfig.SpecialTitles.VVIP.GamepassId ~= 0 then
		if hasGamepass(userId, TitleConfig.SpecialTitles.VVIP.GamepassId) then
			DataHandler:Set(player, "SpecialTitle", "VVIP")
			DataHandler:Set(player, "TitleSource", "special")
			return "VVIP"
		end
	end

	-- 4. Check VIP Gamepass
	if TitleConfig.SpecialTitles.VIP and TitleConfig.SpecialTitles.VIP.GamepassId ~= 0 then
		if hasGamepass(userId, TitleConfig.SpecialTitles.VIP.GamepassId) then
			DataHandler:Set(player, "SpecialTitle", "VIP")
			DataHandler:Set(player, "TitleSource", "special")
			return "VIP"
		end
	end

	-- 5. Check Donatur (based on donation threshold)
	if data.TotalDonations >= TitleConfig.DonationThreshold then
		DataHandler:Set(player, "SpecialTitle", "Donatur")
		DataHandler:Set(player, "TitleSource", "special")
		return "Donatur"
	end

	-- 6. Summit Title (based on TotalSummits)
	local summitTitle = getSummitTitle(data.TotalSummits or 0)
	return summitTitle
end

function TitleServer:UpdateSummitTitle(player)
	local data = DataHandler:GetData(player)
	if not data then return end

	-- Check if player has equipped title (manual selection)
	if data.EquippedTitle then
		print(string.format("[TITLE] ⏭️ Player %s has equipped title '%s', skipping auto-update", 
			player.Name, data.EquippedTitle))

		-- Still unlock new summit titles
		self:UnlockSummitTitles(player, data.TotalSummits or 0)
		return
	end

	-- OLD LOGIC: Check SpecialTitle
	if data.SpecialTitle and data.SpecialTitle ~= "" then
		print(string.format("[TITLE] ⏭️ Player %s has SpecialTitle '%s', skipping summit title update", 
			player.Name, data.SpecialTitle))
		return
	end

	if data.TitleSource and data.TitleSource ~= "summit" then
		print(string.format("[TITLE] ⏭️ Player %s has non-summit title (source: %s), skipping update", 
			player.Name, data.TitleSource))
		return
	end

	local newTitle = getSummitTitle(data.TotalSummits or 0)
	local currentTitle = data.Title

	-- Unlock new summit titles
	self:UnlockSummitTitles(player, data.TotalSummits or 0)

	if newTitle ~= currentTitle then
		DataHandler:Set(player, "Title", newTitle)
		DataHandler:Set(player, "TitleSource", "summit")
		DataHandler:SavePlayer(player)

		print(string.format("[TITLE] ✅ Summit title upgraded for %s: %s → %s (Summits: %d)", 
			player.Name, currentTitle, newTitle, data.TotalSummits))

		self:BroadcastTitle(player, newTitle)
	else
		print(string.format("[TITLE] Summit title unchanged for %s: %s (Summits: %d)", 
			player.Name, currentTitle, data.TotalSummits))
	end
end

function TitleServer:GrantSpecialTitle(player, specialTitleName)
	if not TitleConfig.SpecialTitles[specialTitleName] then
		warn(string.format("⚠️ [TITLE] Invalid special title: %s", specialTitleName))
		return false
	end

	DataHandler:Set(player, "SpecialTitle", specialTitleName)
	DataHandler:Set(player, "Title", specialTitleName)
	DataHandler:Set(player, "TitleSource", "special")
	DataHandler:SavePlayer(player)

	print(string.format("👑 [TITLE] Special title granted to %s: %s", player.Name, specialTitleName))

	self:BroadcastTitle(player, specialTitleName)
	return true
end

function TitleServer:RemoveSpecialTitle(player)
	DataHandler:Set(player, "SpecialTitle", nil)

	local newTitle = self:DetermineTitle(player)
	DataHandler:Set(player, "Title", newTitle)
	DataHandler:Set(player, "TitleSource", "summit")
	DataHandler:SavePlayer(player)

	print(string.format("🔓 [TITLE] Special title removed from %s, new title: %s", player.Name, newTitle))

	self:BroadcastTitle(player, newTitle)
	return true
end

function TitleServer:SetTitle(player, titleName, source, isSpecial)
	print(string.format("[TITLE] Setting title for %s: %s (source: %s, special: %s)", 
		player.Name, titleName, source or "manual", tostring(isSpecial)))

	local data = DataHandler:GetData(player)

	local isSummitTitle = false
	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if titleData.Name == titleName then
			isSummitTitle = true
			break
		end
	end

	if isSummitTitle then
		print(string.format("[TITLE] '%s' detected as Summit Title, treating as non-special", titleName))
		isSpecial = false
	end

	if isSpecial then
		if not TitleConfig.SpecialTitles[titleName] and titleName ~= "Admin" then
			warn(string.format("⚠️ [TITLE] Invalid special title: %s", titleName))
			return false
		end

		DataHandler:Set(player, "SpecialTitle", titleName)
		DataHandler:Set(player, "Title", titleName)
		DataHandler:Set(player, "TitleSource", source or "admin")
		DataHandler:SavePlayer(player)

		print(string.format("👑 [TITLE] ✅ Set SpecialTitle for %s: %s", player.Name, titleName))

		self:BroadcastTitle(player, titleName)
		return true
	else
		DataHandler:Set(player, "SpecialTitle", "")
		DataHandler:Set(player, "TitleSource", "summit")

		local correctSummitTitle = getSummitTitle(data.TotalSummits or 0)
		DataHandler:Set(player, "Title", correctSummitTitle)
		DataHandler:SavePlayer(player)

		print(string.format("🔓 [TITLE] ✅ Cleared SpecialTitle for %s", player.Name))
		print(string.format("🔄 [TITLE] ✅ Recalculated title based on summits (%d): %s", 
			data.TotalSummits or 0, correctSummitTitle))

		self:BroadcastTitle(player, correctSummitTitle)
		return true
	end
end

function TitleServer:GetTitle(player)
	if not player or not player.Parent then
		return "Pendaki"
	end

	return self:DetermineTitle(player)
end

-- ✅ ADDED: GetPlayerTitle function for ChatTitleClient
function TitleServer:GetPlayerTitle(player)
	return self:GetTitle(player)
end

function TitleServer:BroadcastTitle(player, titleName)
	if not player or not player.Parent then
		return
	end

	-- ✅ SIMPLIFIED: Only fire to the player themselves
	-- Other clients will fetch via GetTitle when they need it
	pcall(function()
		updateTitleEvent:FireClient(player, titleName)
	end)
	
	-- ✅ OPTIONAL: Notify other clients (rate limited, for immediate UI update)
	local userId = player.UserId
	local now = tick()
	local lastBroadcast = broadcastDebounce[userId]
	
	if not lastBroadcast or (now - lastBroadcast) >= BROADCAST_DEBOUNCE then
		broadcastDebounce[userId] = now
		pcall(function()
			updateOtherPlayerTitleEvent:FireAllClients(player, titleName)
		end)
	end
end

function TitleServer:InitializePlayer(player)
	task.wait(1)

	local data = DataHandler:GetData(player)
	if not data then return end

	-- ✅ Ensure UnlockedTitles exists
	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end

	-- ✅ Unlock summit titles based on current summits
	self:UnlockSummitTitles(player, data.TotalSummits or 0)

	-- ✅ Check for special titles
	if table.find(TitleConfig.AdminIds, player.UserId) then
		self:UnlockTitle(player, "Admin")
		
		-- ✅ Auto-equip Admin title
		if data.EquippedTitle ~= "Admin" then
			DataHandler:Set(player, "EquippedTitle", "Admin")
		end
		
		-- ✅ Give AdminWing tool to admins
		self:GiveAdminWing(player)
	end

	-- Check gamepasses
	for titleName, titleData in pairs(TitleConfig.SpecialTitles) do
		if titleData.GamepassId and titleData.GamepassId ~= 0 then
			if hasGamepass(player.UserId, titleData.GamepassId) then
				self:UnlockTitle(player, titleName)
			end
		end
	end

	-- Determine title
	local title = self:DetermineTitle(player)
	local currentTitle = DataHandler:Get(player, "Title")
	if currentTitle ~= title then
		DataHandler:Set(player, "Title", title)
		DataHandler:SavePlayer(player)
	end

	print(string.format("🎯 [TITLE] Initialized for %s: %s", player.Name, title))

	-- ✅ Apply privileges if equipped
	if data.EquippedTitle then
		task.wait(1)
		self:ApplyPrivileges(player, data.EquippedTitle)
	end

	-- ✅ Assign player to team based on equipped title
	self:UpdatePlayerTeam(player, data.EquippedTitle or title)

	-- ✅ SIMPLIFIED: Only broadcast to own client (other clients fetch via GetTitle)
	task.wait(2)
	self:BroadcastTitle(player, data.EquippedTitle or title)
end

-- ✅ NEW: Called after data migration is complete
-- This ensures Admin title and AdminWing are properly given after legacy data is migrated
function TitleServer:InitializePlayerPostMigration(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then return end
	
	print(string.format("🎯 [TITLE] Post-migration init for %s (Summits: %d)", 
		player.Name, data.TotalSummits or 0))
	
	-- ==========================================
	-- ✅ UNLOCK SUMMIT TITLES BASED ON MIGRATED DATA
	-- ==========================================
	if data.TotalSummits and data.TotalSummits > 0 then
		self:UnlockSummitTitles(player, data.TotalSummits)
		print(string.format("🏔️ [TITLE] Unlocked summit titles for %s based on %d summits", 
			player.Name, data.TotalSummits))
	end
	
	-- ==========================================
	-- ✅ CHECK FOR ADMIN
	-- ==========================================
	if table.find(TitleConfig.AdminIds, player.UserId) then
		-- Unlock Admin title
		if not table.find(data.UnlockedTitles or {}, "Admin") then
			self:UnlockTitle(player, "Admin")
			print(string.format("👑 [TITLE] Unlocked Admin title for %s", player.Name))
		end
		
		-- Auto-equip Admin title if not already equipped
		if data.EquippedTitle ~= "Admin" then
			DataHandler:Set(player, "EquippedTitle", "Admin")
			DataHandler:SavePlayer(player)
			self:UpdatePlayerTeam(player, "Admin")
			print(string.format("👑 [TITLE] Auto-equipped Admin title for %s", player.Name))
		end
		
		-- Give AdminWing tool
		self:GiveAdminWing(player)
	end
	
	-- ==========================================
	-- ✅ DETERMINE FINAL TITLE
	-- ==========================================
	local title = self:DetermineTitle(player)
	
	-- Update stored title if changed
	local currentStoredTitle = data.Title
	if currentStoredTitle ~= title then
		DataHandler:Set(player, "Title", title)
		DataHandler:SavePlayer(player)
	end
	
	-- ✅ SIMPLIFIED: Single broadcast, no spam
	self:BroadcastTitle(player, data.EquippedTitle or title)
	
	-- Update team assignment in playerlist
	self:UpdatePlayerTeam(player, data.EquippedTitle or title)
	
	print(string.format("✅ [TITLE] Post-migration complete for %s (Title: %s)", 
		player.Name, data.EquippedTitle or title))
end

-- ✅ NEW: Give AdminWing to admin player (adds to OwnedTools for inventory system)
function TitleServer:GiveAdminWing(player)
	if not player or not player.Parent then return end
	if not table.find(TitleConfig.AdminIds, player.UserId) then return end
	
	-- Add AdminWing to OwnedTools if not already owned
	if not DataHandler:ArrayContains(player, "OwnedTools", "AdminWing") then
		DataHandler:AddToArray(player, "OwnedTools", "AdminWing")
		print(string.format("👑 [TITLE] Added AdminWing to OwnedTools for admin: %s", player.Name))
	end
	
	-- Auto-equip AdminWing if no tool equipped
	local equippedTool = DataHandler:Get(player, "EquippedTool")
	if not equippedTool then
		DataHandler:Set(player, "EquippedTool", "AdminWing")
		print(string.format("👑 [TITLE] Auto-equipped AdminWing for admin: %s", player.Name))
	end
	
	DataHandler:SavePlayer(player)
end

function TitleServer:AdminSetSummits(player, newSummitCount)
	if newSummitCount < 0 then newSummitCount = 0 end

	DataHandler:Set(player, "TotalSummits", newSummitCount)

	if player:FindFirstChild("PlayerStats") then
		local summitValue = player.PlayerStats:FindFirstChild("Summit")
		if summitValue then
			summitValue.Value = newSummitCount
		end
	end

	self:UpdateSummitTitle(player)

	DataHandler:SavePlayer(player)
	print(string.format("👨‍💼 [ADMIN] Set summits for %s: %d", player.Name, newSummitCount))
end

-- ==================== ✅ NEW: REMOTE HANDLERS ====================

equipTitleEvent.OnServerEvent:Connect(function(player, titleName)
	TitleServer:EquipTitle(player, titleName)
end)

unequipTitleEvent.OnServerEvent:Connect(function(player)
	TitleServer:UnequipTitle(player)
end)

getUnlockedTitlesFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			UnlockedTitles = {"Pendaki"},
			EquippedTitle = nil
		}
	end

	return {
		UnlockedTitles = data.UnlockedTitles or {"Pendaki"},
		EquippedTitle = data.EquippedTitle
	}
end

getTitleFunc.OnServerInvoke = function(caller, targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then
		return "Pendaki"
	end

	return TitleServer:GetTitle(targetPlayer)
end

-- ==================== PLAYER EVENTS ====================

Players.PlayerAdded:Connect(function(player)
	TitleServer:InitializePlayer(player)

	-- ✅ Handle respawn - reapply privileges and collision groups
	player.CharacterAdded:Connect(function(character)
		task.wait(1)

		local data = DataHandler:GetData(player)
		if data and data.EquippedTitle then
			TitleServer:ApplyPrivileges(player, data.EquippedTitle)
		end
		
		-- ✅ Apply correct collision group for zone access
		TitleServer.RefreshZoneAccess(player)

		local title = TitleServer:GetTitle(player)
		TitleServer:BroadcastTitle(player, title)
	end)
end)


-- ==================== ACCESS CONTROL SYSTEM INITIALIZATION ====================
-- Setup zone parts and their Touched events for NoCollisionConstraint approach

print("🔒 [TITLE SERVER] Initializing Access Control...")

-- ✅ Set the module-level collidersFolder variable
collidersFolder = workspace:WaitForChild("Colliders", 10)

if not collidersFolder then
	warn("⚠️ [ACCESS CONTROL] Colliders folder not found in Workspace!")
else
	print("🔒 [ACCESS CONTROL] Found Colliders folder")
	accessControlReady = true
	
	-- Count parts for debug
	local totalParts = 0

	local function setupZonePart(part, zoneFolderName)
		if not part:IsA("BasePart") then return end

		-- Make invisible and collidable
		part.Transparency = 1
		part.CanCollide = true
		part.Anchored = true
		
		totalParts = totalParts + 1

		-- ✅ OPTIMIZED: Connect Touched event with debounce to prevent spam
		part.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if not player then return end

			-- ✅ DEBOUNCE: Check if we recently processed this player/zone/part combo
			local cooldownKey = player.UserId .. "_" .. zoneFolderName .. "_" .. part.Name
			local now = tick()
			local lastTouch = zoneTouchedCooldown[cooldownKey]
			
			if lastTouch and (now - lastTouch) < TOUCH_COOLDOWN then
				return -- Skip, recently processed
			end
			
			-- Update cooldown timestamp
			zoneTouchedCooldown[cooldownKey] = now

			-- Uses module-level updateCanCollideForPlayer function
			updateCanCollideForPlayer(player, part, zoneFolderName)
		end)
	end

	local function setupZoneFolder(zoneFolder)
		if not zoneFolder:IsA("Folder") then return end

		local zoneFolderName = zoneFolder.Name
		debugLog("Setting up zone folder:", zoneFolderName)

		for _, part in ipairs(zoneFolder:GetChildren()) do
			setupZonePart(part, zoneFolderName)
		end

		zoneFolder.ChildAdded:Connect(function(part)
			task.wait(0.1)
			setupZonePart(part, zoneFolderName)
		end)
	end

	for _, zoneFolder in ipairs(collidersFolder:GetChildren()) do
		setupZoneFolder(zoneFolder)
	end

	collidersFolder.ChildAdded:Connect(function(zoneFolder)
		task.wait(0.1)
		setupZoneFolder(zoneFolder)
	end)

	print(string.format("✅ [ACCESS CONTROL] System loaded - %d zone parts found", totalParts))
end




print("✅ [TITLE SERVER v3] System loaded with Unlock/Equip & Privileges")

return TitleServer
