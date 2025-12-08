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
		data.UnlockedTitles = {"Pengunjung"}
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

-- ==================== ✅ NEW: EQUIP/UNEQUIP SYSTEM ====================

function TitleServer:EquipTitle(player, titleName)
	local data = DataHandler:GetData(player)
	if not data then return false end

	-- Ensure UnlockedTitles exists
	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pengunjung"}
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



	-- Apply privileges
	self:ApplyPrivileges(player, titleName)

	-- Broadcast to all clients
	self:BroadcastTitle(player, titleName)

	-- ✅ ADDED: Broadcast for chat titles
	BroadcastTitle:FireAllClients(player.UserId, titleName)

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



	-- Broadcast (no title)
	self:BroadcastTitle(player, nil)

	-- ✅ ADDED: Broadcast for chat titles
	BroadcastTitle:FireAllClients(player.UserId, nil)

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
	end
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
	end
end

function TitleServer:GiveTool(player, toolName)
	if not player.Character then return end

	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then
		warn("[PRIVILEGES] Tools folder not found in ReplicatedStorage")
		return
	end

	local toolTemplate = toolsFolder:FindFirstChild(toolName)
	if not toolTemplate then
		warn(string.format("[PRIVILEGES] Tool not found: %s", toolName))
		return
	end

	local backpack = player:FindFirstChild("Backpack")

	-- Check if already has tool in backpack
	if backpack and backpack:FindFirstChild(toolName) then
		return -- Already has it
	end

	-- Check if already equipped
	if player.Character:FindFirstChild(toolName) then
		return -- Already equipped
	end

	-- Give tool to backpack
	local toolClone = toolTemplate:Clone()
	toolClone.Parent = backpack or player.Character


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


end

-- ==================== EXISTING FUNCTIONS (KEPT AS-IS) ====================

function TitleServer:DetermineTitle(player)
	local userId = player.UserId
	local data = DataHandler:GetData(player)

	if not data then
		warn(string.format("⚠️ [TITLE SERVER] No data for %s", player.Name))
		return "Pengunjung"
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
		self:UnlockSummitTitles(player, data.TotalSummits or 0)
		return
	end

	-- OLD LOGIC: Check SpecialTitle
	if data.SpecialTitle and data.SpecialTitle ~= "" then
		return
	end

	if data.TitleSource and data.TitleSource ~= "summit" then
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
		self:BroadcastTitle(player, newTitle)
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



	self:BroadcastTitle(player, specialTitleName)
	return true
end

function TitleServer:RemoveSpecialTitle(player)
	DataHandler:Set(player, "SpecialTitle", nil)

	local newTitle = self:DetermineTitle(player)
	DataHandler:Set(player, "Title", newTitle)
	DataHandler:Set(player, "TitleSource", "summit")
	DataHandler:SavePlayer(player)



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



		self:BroadcastTitle(player, titleName)
		return true
	else
		DataHandler:Set(player, "SpecialTitle", "")
		DataHandler:Set(player, "TitleSource", "summit")

		local correctSummitTitle = getSummitTitle(data.TotalSummits or 0)
		DataHandler:Set(player, "Title", correctSummitTitle)
		DataHandler:SavePlayer(player)



		self:BroadcastTitle(player, correctSummitTitle)
		return true
	end
end

function TitleServer:GetTitle(player)
	if not player or not player.Parent then
		return "Pengunjung"
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

	pcall(function()
		updateTitleEvent:FireClient(player, titleName)
	end)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Parent then
			pcall(function()
				updateOtherPlayerTitleEvent:FireClient(otherPlayer, player, titleName)
			end)
		end
	end

	print(string.format("📤 [TITLE] Broadcasted title for %s: %s", player.Name, titleName or "None"))
end

function TitleServer:InitializePlayer(player)
	task.wait(1)

	local data = DataHandler:GetData(player)
	if not data then return end

	-- ✅ Ensure UnlockedTitles exists
	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pengunjung"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end

	-- ✅ Unlock summit titles based on current summits
	self:UnlockSummitTitles(player, data.TotalSummits or 0)

	-- ✅ Check for special titles
	if table.find(TitleConfig.AdminIds, player.UserId) then
		self:UnlockTitle(player, "Admin")
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

	task.wait(2)
	self:BroadcastTitle(player, title)

	-- ✅ ADDED: Broadcast for chat titles
	task.wait(0.5)
	BroadcastTitle:FireAllClients(player.UserId, data.EquippedTitle or title)
	print(string.format("[TITLE SERVER] Broadcasted initial title for chat: %s", player.Name))
end

function TitleServer:AdminSetSummits(player, newSummitCount)
	if newSummitCount < 0 then newSummitCount = 0 end

	DataHandler:Set(player, "TotalSummits", newSummitCount)

	if player:FindFirstChild("leaderstats") then
		local summitValue = player.leaderstats:FindFirstChild("Summit")
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
			UnlockedTitles = {"Pengunjung"},
			EquippedTitle = nil
		}
	end

	return {
		UnlockedTitles = data.UnlockedTitles or {"Pengunjung"},
		EquippedTitle = data.EquippedTitle
	}
end

getTitleFunc.OnServerInvoke = function(caller, targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then
		return "Pengunjung"
	end

	return TitleServer:GetTitle(targetPlayer)
end

-- ==================== PLAYER EVENTS ====================

Players.PlayerAdded:Connect(function(player)
	TitleServer:InitializePlayer(player)

	-- ✅ Handle respawn - reapply privileges
	player.CharacterAdded:Connect(function(character)
		task.wait(1)

		local data = DataHandler:GetData(player)
		if data and data.EquippedTitle then
			TitleServer:ApplyPrivileges(player, data.EquippedTitle)
		end

		local title = TitleServer:GetTitle(player)
		TitleServer:BroadcastTitle(player, title)
	end)
end)

-- ==================== ACCESS CONTROL SYSTEM (KEPT AS-IS) ====================

print("🔒 [TITLE SERVER] Initializing Access Control...")

local collidersFolder = workspace:WaitForChild("Colliders", 10)

if not collidersFolder then
	warn("⚠️ [ACCESS CONTROL] Colliders folder not found in Workspace!")
else
	print("🔒 [ACCESS CONTROL] Found Colliders folder")

	local function hasAccess(player, zoneFolderName)
		local data = DataHandler:GetData(player)
		if not data then
			return false
		end

		-- ✅ Use equipped title for access check
		local playerTitle = data.EquippedTitle or data.Title or "Pengunjung"

		local allowedTitles = TitleConfig.AccessRules[zoneFolderName]
		if not allowedTitles then
			return false
		end

		for _, allowedTitle in ipairs(allowedTitles) do
			if playerTitle == allowedTitle then
				return true
			end
		end

		return false
	end

	local function updateCanCollideForPlayer(player, part, zoneFolderName)
		local character = player.Character
		if not character then return end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end

		local access = hasAccess(player, zoneFolderName)

		if access then
			for _, playerPart in ipairs(character:GetDescendants()) do
				if playerPart:IsA("BasePart") then
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = playerPart
					constraint.Part1 = part
					constraint.Name = "ZonePass_" .. zoneFolderName
					constraint.Parent = playerPart

					task.delay(2, function()
						if constraint and constraint.Parent then
							constraint:Destroy()
						end
					end)
				end
			end
		else
			if not player:GetAttribute("ZoneWarning_" .. zoneFolderName) then
				player:SetAttribute("ZoneWarning_" .. zoneFolderName, true)

				local allowedTitles = TitleConfig.AccessRules[zoneFolderName]
				local titleList = table.concat(allowedTitles, ", ")

				pcall(function()
					NotificationService:Send(player, {
						Message = string.format("🔒 Akses Ditolak! Butuh title: %s", titleList),
						Type = "error",
						Duration = 3,
						Icon = "❌"
					})
				end)

				task.delay(3, function()
					player:SetAttribute("ZoneWarning_" .. zoneFolderName, nil)
				end)
			end
		end
	end

	local function setupZonePart(part, zoneFolderName)
		if not part:IsA("BasePart") then return end

		part.Transparency = 0.7
		part.CanCollide = true
		part.Anchored = true
		part.Material = Enum.Material.Neon

		local zoneColor = TitleConfig.ZoneColors[zoneFolderName]
		if zoneColor then
			part.Color = zoneColor
		end

		print(string.format("🔒 [ACCESS] Setup zone part: %s/%s", zoneFolderName, part.Name))

		part.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if not player then return end

			updateCanCollideForPlayer(player, part, zoneFolderName)
		end)
	end

	local function setupZoneFolder(zoneFolder)
		if not zoneFolder:IsA("Folder") then return end

		local zoneFolderName = zoneFolder.Name

		print(string.format("🔒 [ACCESS] Setting up zone folder: %s", zoneFolderName))

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

	print("✅ [ACCESS CONTROL] System loaded")
end

print("✅ [TITLE SERVER v3] System loaded with Unlock/Equip & Privileges")

return TitleServer
