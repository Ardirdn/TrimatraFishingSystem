--[[
    ADMIN SYSTEM SERVER (Refactored)
    Place in ServerScriptService/AdminServer
    
    Simplified:
    - Uses Data Handler for all data operations
    - Uses Notification System for all feedback
    - Calls Title System for title management
    - Focus: Admin commands only
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TitleServer)

-- ✅ GANTI JADI INI:
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

-- Admin Log Service
local AdminLogServer = require(script.Parent.AdminLogService)

-- ✅ BAN SYSTEM DATASTORE (persistent)
local BanDataStore = DataStoreService:GetDataStore("BannedPlayers_v1")
local BannedUsersCache = {} -- In-memory cache for fast lookups

-- ✅ Load ban status from DataStore
local function isPlayerBanned(userId)
	-- Check cache first
	if BannedUsersCache[userId] ~= nil then
		return BannedUsersCache[userId]
	end
	
	-- Check DataStore
	local success, isBanned = pcall(function()
		return BanDataStore:GetAsync(tostring(userId))
	end)
	
	if success and isBanned then
		BannedUsersCache[userId] = true
		return true
	end
	
	BannedUsersCache[userId] = false
	return false
end

-- ✅ Ban a player (save to DataStore)
local function banPlayer(userId, bannedBy, reason)
	local banData = {
		BannedAt = os.time(),
		BannedBy = bannedBy,
		Reason = reason or "No reason provided"
	}
	
	local success, err = pcall(function()
		BanDataStore:SetAsync(tostring(userId), banData)
	end)
	
	if success then
		BannedUsersCache[userId] = true
		return true
	else
		warn("[BAN SYSTEM] Failed to save ban:", err)
		return false
	end
end

-- ✅ Unban a player
local function unbanPlayer(userId)
	local success, err = pcall(function()
		BanDataStore:RemoveAsync(tostring(userId))
	end)
	
	if success then
		BannedUsersCache[userId] = false
		return true
	else
		warn("[BAN SYSTEM] Failed to remove ban:", err)
		return false
	end
end

-- Check if player is admin (using TitleConfig)
local function isAdmin(userId)
	return TitleConfig.IsAdmin(userId)
end

-- Check if player is PRIMARY admin (full access)
local function isPrimaryAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId)
end

-- Create RemoteEvents folder
local remoteFolder = ReplicatedStorage:FindFirstChild("AdminRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "AdminRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local kickPlayerEvent = remoteFolder:FindFirstChild("KickPlayer")
if not kickPlayerEvent then
	kickPlayerEvent = Instance.new("RemoteEvent")
	kickPlayerEvent.Name = "KickPlayer"
	kickPlayerEvent.Parent = remoteFolder
end

local banPlayerEvent = remoteFolder:FindFirstChild("BanPlayer")
if not banPlayerEvent then
	banPlayerEvent = Instance.new("RemoteEvent")
	banPlayerEvent.Name = "BanPlayer"
	banPlayerEvent.Parent = remoteFolder
end

local teleportHereEvent = remoteFolder:FindFirstChild("TeleportHere")
if not teleportHereEvent then
	teleportHereEvent = Instance.new("RemoteEvent")
	teleportHereEvent.Name = "TeleportHere"
	teleportHereEvent.Parent = remoteFolder
end

local teleportToEvent = remoteFolder:FindFirstChild("TeleportTo")
if not teleportToEvent then
	teleportToEvent = Instance.new("RemoteEvent")
	teleportToEvent.Name = "TeleportTo"
	teleportToEvent.Parent = remoteFolder
end

local freezePlayerEvent = remoteFolder:FindFirstChild("FreezePlayer")
if not freezePlayerEvent then
	freezePlayerEvent = Instance.new("RemoteEvent")
	freezePlayerEvent.Name = "FreezePlayer"
	freezePlayerEvent.Parent = remoteFolder
end

local setSpeedEvent = remoteFolder:FindFirstChild("SetSpeed")
if not setSpeedEvent then
	setSpeedEvent = Instance.new("RemoteEvent")
	setSpeedEvent.Name = "SetSpeed"
	setSpeedEvent.Parent = remoteFolder
end

local setGravityEvent = remoteFolder:FindFirstChild("SetGravity")
if not setGravityEvent then
	setGravityEvent = Instance.new("RemoteEvent")
	setGravityEvent.Name = "SetGravity"
	setGravityEvent.Parent = remoteFolder
end

local killPlayerEvent = remoteFolder:FindFirstChild("KillPlayer")
if not killPlayerEvent then
	killPlayerEvent = Instance.new("RemoteEvent")
	killPlayerEvent.Name = "KillPlayer"
	killPlayerEvent.Parent = remoteFolder
end

local setPlayerTitleEvent = remoteFolder:FindFirstChild("SetPlayerTitle")
if not setPlayerTitleEvent then
	setPlayerTitleEvent = Instance.new("RemoteEvent")
	setPlayerTitleEvent.Name = "SetPlayerTitle"
	setPlayerTitleEvent.Parent = remoteFolder
end

local giveItemsEvent = remoteFolder:FindFirstChild("GiveItems")
if not giveItemsEvent then
	giveItemsEvent = Instance.new("RemoteEvent")
	giveItemsEvent.Name = "GiveItems"
	giveItemsEvent.Parent = remoteFolder
end

local modifySummitDataEvent = remoteFolder:FindFirstChild("ModifySummitData")
if not modifySummitDataEvent then
	modifySummitDataEvent = Instance.new("RemoteEvent")
	modifySummitDataEvent.Name = "ModifySummitData"
	modifySummitDataEvent.Parent = remoteFolder
end

-- Give Title (unlock only, no auto-equip)
local giveTitleEvent = remoteFolder:FindFirstChild("GiveTitle")
if not giveTitleEvent then
	giveTitleEvent = Instance.new("RemoteEvent")
	giveTitleEvent.Name = "GiveTitle"
	giveTitleEvent.Parent = remoteFolder
end

-- ✅ TAMBAHKAN INI SETELAH modifySummitDataEvent

local searchLeaderboardEvent = remoteFolder:FindFirstChild("SearchLeaderboard")
if not searchLeaderboardEvent then
	searchLeaderboardEvent = Instance.new("RemoteFunction")
	searchLeaderboardEvent.Name = "SearchLeaderboard"
	searchLeaderboardEvent.Parent = remoteFolder
end

local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
if not deleteLeaderboardEvent then
	deleteLeaderboardEvent = Instance.new("RemoteEvent")
	deleteLeaderboardEvent.Name = "DeleteLeaderboard"
	deleteLeaderboardEvent.Parent = remoteFolder
end

-- GetLeaderboardData RemoteFunction (for leaderboard viewer)
local getLeaderboardDataFunc = remoteFolder:FindFirstChild("GetLeaderboardData")
if not getLeaderboardDataFunc then
	getLeaderboardDataFunc = Instance.new("RemoteFunction")
	getLeaderboardDataFunc.Name = "GetLeaderboardData"
	getLeaderboardDataFunc.Parent = remoteFolder
end

-- ✅ Unban Player Remote Event
local unbanPlayerEvent = remoteFolder:FindFirstChild("UnbanPlayer")
if not unbanPlayerEvent then
	unbanPlayerEvent = Instance.new("RemoteEvent")
	unbanPlayerEvent.Name = "UnbanPlayer"
	unbanPlayerEvent.Parent = remoteFolder
end

print("✅ [ADMIN SERVER] Initialized")

-- ✅ BAN CHECK ON PLAYER JOIN
Players.PlayerAdded:Connect(function(player)
	-- Check if player is banned (async check from DataStore or cache)
	task.spawn(function()
		if isPlayerBanned(player.UserId) then
			print(string.format("🚫 [BAN SYSTEM] Kicking banned player: %s (%d)", player.Name, player.UserId))
			player:Kick("You are permanently banned from this game.")
		end
	end)
end)

-- ✅ INVENTORY UPDATE EVENT (for real-time sync when admin gives items)
local inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not inventoryRemotes then
	inventoryRemotes = Instance.new("Folder")
	inventoryRemotes.Name = "InventoryRemotes"
	inventoryRemotes.Parent = ReplicatedStorage
end

local inventoryUpdatedEvent = inventoryRemotes:FindFirstChild("InventoryUpdated")
if not inventoryUpdatedEvent then
	inventoryUpdatedEvent = Instance.new("RemoteEvent")
	inventoryUpdatedEvent.Name = "InventoryUpdated"
	inventoryUpdatedEvent.Parent = inventoryRemotes
end

print("✅ [ADMIN SERVER] Ban system and inventory sync ready")

-- Global/Server Notification RemoteEvent
local sendGlobalNotificationEvent = remoteFolder:FindFirstChild("SendGlobalNotification")
if not sendGlobalNotificationEvent then
	sendGlobalNotificationEvent = Instance.new("RemoteEvent")
	sendGlobalNotificationEvent.Name = "SendGlobalNotification"
	sendGlobalNotificationEvent.Parent = remoteFolder
end

-- Kick Player
kickPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to kick: %s", admin.Name))
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local targetName = targetPlayer.Name
		targetPlayer:Kick("You have been kicked by an administrator")

		NotificationService:Send(admin, {
			Message = string.format("Kicked %s", targetName),
			Type = "success",
			Duration = 3
		})

		-- Log the action
		AdminLogServer:Log(admin.UserId, admin.Name, "kick", {UserId = targetUserId, Name = targetName}, "")

		print(string.format("👮 [ADMIN SERVER] %s kicked %s", admin.Name, targetName))
	end
end)

-- Ban Player (with persistent DataStore)
banPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to ban: %s", admin.Name))
		return
	end

	-- Get target name (player may or may not be online)
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local targetName = targetPlayer and targetPlayer.Name or "Unknown"
	
	-- ✅ Save ban to DataStore (persistent)
	local banSuccess = banPlayer(targetUserId, admin.Name, "Banned by admin")
	
	if banSuccess then
		-- Kick if online
		if targetPlayer then
			targetName = targetPlayer.Name
			targetPlayer:Kick("You have been banned by an administrator. Ban is permanent.")
		end

		NotificationService:Send(admin, {
			Message = string.format("Banned %s (Permanent)", targetName),
			Type = "success",
			Duration = 3
		})

		-- Log the action
		AdminLogServer:Log(admin.UserId, admin.Name, "ban", {UserId = targetUserId, Name = targetName}, "Permanent")

		print(string.format("🚫 [ADMIN SERVER] %s PERMANENTLY banned %s (saved to DataStore)", admin.Name, targetName))
	else
		NotificationService:Send(admin, {
			Message = "Failed to save ban to DataStore!",
			Type = "error",
			Duration = 3
		})
	end
end)

-- ✅ Unban Player (remove from DataStore)
unbanPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to unban: %s", admin.Name))
		return
	end

	-- Get username for logging
	local targetName = "Unknown"
	local nameSuccess, name = pcall(function()
		return Players:GetNameFromUserIdAsync(targetUserId)
	end)
	if nameSuccess then
		targetName = name
	end

	-- ✅ Remove ban from DataStore
	local unbanSuccess = unbanPlayer(targetUserId)

	if unbanSuccess then
		NotificationService:Send(admin, {
			Message = string.format("Unbanned %s", targetName),
			Type = "success",
			Duration = 3
		})

		-- Log the action
		AdminLogServer:Log(admin.UserId, admin.Name, "unban", {UserId = targetUserId, Name = targetName}, "")

		print(string.format("✅ [ADMIN SERVER] %s unbanned %s (removed from DataStore)", admin.Name, targetName))
	else
		NotificationService:Send(admin, {
			Message = "Failed to unban player!",
			Type = "error",
			Duration = 3
		})
	end
end)

-- Teleport Here
teleportHereEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character and admin.Character then
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		local adminRoot = admin.Character:FindFirstChild("HumanoidRootPart")

		if targetRoot and adminRoot then
			targetRoot.CFrame = adminRoot.CFrame * CFrame.new(0, 0, -5)

			NotificationService:Send(admin, {
				Message = string.format("Teleported %s here", targetPlayer.Name),
				Type = "success",
				Duration = 3
			})

			print(string.format("📍 [ADMIN SERVER] %s teleported %s here", admin.Name, targetPlayer.Name))
		end
	end
end)

-- Teleport To
teleportToEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character and admin.Character then
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		local adminRoot = admin.Character:FindFirstChild("HumanoidRootPart")

		if targetRoot and adminRoot then
			adminRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)

			NotificationService:Send(admin, {
				Message = string.format("Teleported to %s", targetPlayer.Name),
				Type = "success",
				Duration = 3
			})

			print(string.format("📍 [ADMIN SERVER] %s teleported to %s", admin.Name, targetPlayer.Name))
		end
	end
end)

-- Freeze Player
local frozenPlayers = {}

freezePlayerEvent.OnServerEvent:Connect(function(admin, targetUserId, shouldFreeze)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			if shouldFreeze then
				frozenPlayers[targetUserId] = {
					originalWalkSpeed = humanoid.WalkSpeed,
					originalJumpPower = humanoid.JumpPower
				}
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0

				NotificationService:Send(admin, {
					Message = string.format("Froze %s", targetPlayer.Name),
					Type = "success",
					Duration = 3
				})

				NotificationService:Send(targetPlayer, {
					Message = "You have been frozen by an admin",
					Type = "warning",
					Duration = 5
				})

				print(string.format("❄️ [ADMIN SERVER] %s froze %s", admin.Name, targetPlayer.Name))

				-- Log the action
				AdminLogServer:Log(admin.UserId, admin.Name, "freeze", {UserId = targetUserId, Name = targetPlayer.Name}, "Frozen")

				-- Auto unfreeze after 3 minutes
				task.delay(180, function()
					if frozenPlayers[targetUserId] and targetPlayer.Character then
						local hum = targetPlayer.Character:FindFirstChild("Humanoid")
						if hum then
							hum.WalkSpeed = frozenPlayers[targetUserId].originalWalkSpeed
							hum.JumpPower = frozenPlayers[targetUserId].originalJumpPower
							frozenPlayers[targetUserId] = nil
						end
					end
				end)
			else
				if frozenPlayers[targetUserId] then
					humanoid.WalkSpeed = frozenPlayers[targetUserId].originalWalkSpeed
					humanoid.JumpPower = frozenPlayers[targetUserId].originalJumpPower
					frozenPlayers[targetUserId] = nil

					NotificationService:Send(admin, {
						Message = string.format("Unfroze %s", targetPlayer.Name),
						Type = "success",
						Duration = 3
					})

					NotificationService:Send(targetPlayer, {
						Message = "You have been unfrozen",
						Type = "info",
						Duration = 3
					})

					print(string.format("🔥 [ADMIN SERVER] %s unfroze %s", admin.Name, targetPlayer.Name))

					-- Log the action
					AdminLogServer:Log(admin.UserId, admin.Name, "freeze", {UserId = targetUserId, Name = targetPlayer.Name}, "Unfrozen")
				end
			end
		end
	end
end)

-- Set Speed
setSpeedEvent.OnServerEvent:Connect(function(admin, targetUserId, speedMultiplier)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16 * speedMultiplier

			NotificationService:Send(admin, {
				Message = string.format("Set %s's speed to %dx", targetPlayer.Name, speedMultiplier),
				Type = "success",
				Duration = 3
			})

			print(string.format("⚡ [ADMIN SERVER] %s set %s's speed to %dx", admin.Name, targetPlayer.Name, speedMultiplier))
		end
	end
end)

-- Set Gravity
setGravityEvent.OnServerEvent:Connect(function(admin, targetUserId, gravityValue)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local bodyForce = humanoidRootPart:FindFirstChild("AdminGravityForce")
			if not bodyForce then
				bodyForce = Instance.new("BodyForce")
				bodyForce.Name = "AdminGravityForce"
				bodyForce.Parent = humanoidRootPart
			end

			local mass = 0
			for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					mass = mass + part:GetMass()
				end
			end

			local gravityDifference = workspace.Gravity - gravityValue
			bodyForce.Force = Vector3.new(0, mass * gravityDifference, 0)

			NotificationService:Send(admin, {
				Message = string.format("Set %s's gravity to %d", targetPlayer.Name, gravityValue),
				Type = "success",
				Duration = 3
			})

			print(string.format("🌍 [ADMIN SERVER] %s set %s's gravity to %d", admin.Name, targetPlayer.Name, gravityValue))
		end
	end
end)

-- Reset gravity on respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bodyForce = hrp:FindFirstChild("AdminGravityForce")
			if bodyForce then
				bodyForce:Destroy()
			end
		end
	end)
end)

-- ✅ FIX: Cleanup frozenPlayers when player leaves
Players.PlayerRemoving:Connect(function(player)
	if frozenPlayers[player.UserId] then
		frozenPlayers[player.UserId] = nil
	end
end)

-- Kill Player
killPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0

			NotificationService:Send(admin, {
				Message = string.format("Killed %s", targetPlayer.Name),
				Type = "success",
				Duration = 3
			})

			print(string.format("💀 [ADMIN SERVER] %s killed %s", admin.Name, targetPlayer.Name))
		end
	end
end)

-- Set Player Title
setPlayerTitleEvent.OnServerEvent:Connect(function(admin, targetUserId, titleName)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then 
		NotificationService:Send(admin, {
			Message = "Target player not found!",
			Type = "error",
			Duration = 3
		})
		return 
	end

	print(string.format("👑 [ADMIN SERVER] %s setting title for %s to %s", admin.Name, targetPlayer.Name, titleName))

	-- Use Title System to set title
	local success = TitleServer:SetTitle(targetPlayer, titleName, "admin", true)

	if success then
		-- Notify target player
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you title: %s", admin.Name, titleName),
			Type = "admin",
			Duration = 5,
			Icon = "👑"
		})

		-- Notify admin
		NotificationService:Send(admin, {
			Message = string.format("Set %s's title to %s", targetPlayer.Name, titleName),
			Type = "success",
			Duration = 3
		})

		print(string.format("✅ [ADMIN SERVER] Title set successfully"))

		-- Log the action
		AdminLogServer:Log(admin.UserId, admin.Name, "set_title", {UserId = targetUserId, Name = targetPlayer.Name}, "Title: " .. titleName)
	else
		NotificationService:Send(admin, {
			Message = "Failed to set title!",
			Type = "error",
			Duration = 3
		})
	end
end)

-- Give Title (unlock only, no auto-equip)
giveTitleEvent.OnServerEvent:Connect(function(admin, targetUserId, titleName)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then 
		NotificationService:Send(admin, {
			Message = "Target player not found!",
			Type = "error",
			Duration = 3
		})
		return 
	end

	-- Check if title is givable
	local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
	local titleData = TitleConfig.SpecialTitles[titleName]
	
	if not titleData then
		NotificationService:Send(admin, {
			Message = "Title not found!",
			Type = "error",
			Duration = 3
		})
		return
	end
	
	if titleData.Givable == false then
		NotificationService:Send(admin, {
			Message = "This title cannot be given!",
			Type = "error",
			Duration = 3
		})
		return
	end

	print(string.format("🎁 [ADMIN SERVER] %s giving title '%s' to %s", admin.Name, titleName, targetPlayer.Name))

	-- Unlock title without equipping (add to OwnedTitles)
	local success = false
	
	-- Try using TitleServer:UnlockTitle if available
	if TitleServer.UnlockTitle then
		success = TitleServer:UnlockTitle(targetPlayer, titleName, "admin")
	else
		-- Fallback: directly add to OwnedTitles via DataHandler
		local ownedTitles = DataHandler:Get(targetPlayer, "OwnedTitles") or {}
		
		-- Check if already owned
		local alreadyOwned = false
		for _, owned in ipairs(ownedTitles) do
			if owned == titleName then
				alreadyOwned = true
				break
			end
		end
		
		if not alreadyOwned then
			DataHandler:AddToArray(targetPlayer, "OwnedTitles", titleName)
			DataHandler:SavePlayer(targetPlayer)
			success = true
		else
			NotificationService:Send(admin, {
				Message = string.format("%s already owns this title!", targetPlayer.Name),
				Type = "warning",
				Duration = 3
			})
			return
		end
	end

	if success then
		-- Notify target player
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you title: %s", admin.Name, titleName),
			Type = "admin",
			Duration = 5,
			Icon = "🎁"
		})

		-- Notify admin
		NotificationService:Send(admin, {
			Message = string.format("Gave '%s' title to %s", titleName, targetPlayer.Name),
			Type = "success",
			Duration = 3
		})

		-- Log the action
		AdminLogServer:Log(admin.UserId, admin.Name, "give_title", {UserId = targetUserId, Name = targetPlayer.Name}, "Title: " .. titleName)

		print(string.format("✅ [ADMIN SERVER] Title '%s' given to %s (unlock only, no equip)", titleName, targetPlayer.Name))
	else
		NotificationService:Send(admin, {
			Message = "Failed to give title!",
			Type = "error",
			Duration = 3
		})
	end
end)

-- Give Items (Money, Auras, Tools)
giveItemsEvent.OnServerEvent:Connect(function(admin, targetUserId, auras, tools, moneyAmount)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then return end

	print(string.format("🎁 [ADMIN SERVER] %s giving items to %s", admin.Name, targetPlayer.Name))

	local itemList = {}

	-- Give Money
	if moneyAmount and moneyAmount > 0 then
		DataHandler:Increment(targetPlayer, "Money", moneyAmount)
		table.insert(itemList, string.format("$%d", moneyAmount))
		print(string.format("💰 [ADMIN SERVER] Gave $%d to %s", moneyAmount, targetPlayer.Name))
	end

	-- Give Auras
	if auras and #auras > 0 then
		for _, auraId in ipairs(auras) do
			DataHandler:AddToArray(targetPlayer, "OwnedAuras", auraId)
		end
		table.insert(itemList, string.format("%d Aura(s)", #auras))
		print(string.format("✨ [ADMIN SERVER] Gave %d auras to %s", #auras, targetPlayer.Name))
	end

	-- Give Tools
	if tools and #tools > 0 then
		for _, toolId in ipairs(tools) do
			DataHandler:AddToArray(targetPlayer, "OwnedTools", toolId)
		end
		table.insert(itemList, string.format("%d Tool(s)", #tools))
		print(string.format("🔧 [ADMIN SERVER] Gave %d tools to %s", #tools, targetPlayer.Name))
	end

	-- Save data
	DataHandler:SavePlayer(targetPlayer)

	if #itemList > 0 then
		-- Notify target player
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you: %s", admin.Name, table.concat(itemList, ", ")),
			Type = "admin",
			Duration = 5,
			Icon = "🎁"
		})

		-- Notify admin
		NotificationService:Send(admin, {
			Message = string.format("Gave %s: %s", targetPlayer.Name, table.concat(itemList, ", ")),
			Type = "success",
			Duration = 3
		})

		-- ✅ FIRE INVENTORY UPDATE EVENT (real-time UI refresh for player)
		if inventoryUpdatedEvent then
			local updatedData = {
				OwnedAuras = DataHandler:Get(targetPlayer, "OwnedAuras") or {},
				OwnedTools = DataHandler:Get(targetPlayer, "OwnedTools") or {},
				EquippedAura = DataHandler:Get(targetPlayer, "EquippedAura"),
				EquippedTool = DataHandler:Get(targetPlayer, "EquippedTool"),
			}
			inventoryUpdatedEvent:FireClient(targetPlayer, updatedData)
			print(string.format("📦 [ADMIN SERVER] Inventory update event fired to %s", targetPlayer.Name))
		end

		print(string.format("✅ [ADMIN SERVER] Items given successfully"))
	end
end)

-- Update SendGlobalNotification handler (PRIMARY ADMIN ONLY)
sendGlobalNotificationEvent.OnServerEvent:Connect(function(admin, notifType, message, textColor, notificationType, duration)
	-- Only Primary Admin can send notifications
	if not isPrimaryAdmin(admin.UserId) then 
		NotificationService:Send(admin, {
			Message = "Only Primary Admin can send notifications!",
			Type = "error",
			Duration = 3
		})
		return 
	end

	print(string.format("📢 [ADMIN SERVER] %s sending %s notification: %s (type: %s, duration: %ds)", 
		admin.Name, notifType, message, notificationType or "SideTextOnly", duration or 5))

	if notifType == "global" or notifType == "server" then
		-- Convert Color3 to table if needed
		local colorData = textColor
		if typeof(textColor) == "Color3" then
			colorData = {textColor.R, textColor.G, textColor.B}
		end

		-- Send to all players with new notification type system
		NotificationService:SendToAll({
			Message = message,
			NotificationType = notificationType or "SideTextOnly",
			Duration = duration or 10,
			-- Sender info for WithSender types
			SenderUserId = admin.UserId,
			SenderName = admin.DisplayName,
			SenderUsername = admin.Name,
			Sender = {
				UserId = admin.UserId,
				Name = admin.Name,
				DisplayName = admin.DisplayName
			}
		}, admin) -- Pass admin as sender

		-- Confirm to admin
		NotificationService:Send(admin, {
			Message = "Global notification sent!",
			NotificationType = "SideTextOnly",
			Duration = 3
		})

		print("✅ [ADMIN SERVER] Global notification sent")

		-- Log the action
		AdminLogServer:Log(admin.UserId, admin.Name, "notification", {UserId = 0, Name = "All Players"}, "Type: " .. notifType .. ", Msg: " .. string.sub(message, 1, 50))
	end
end)

modifySummitDataEvent.OnServerEvent:Connect(function(admin, targetUserId, newSummitValue)
	if not isAdmin(admin.UserId) then return end

	if type(newSummitValue) ~= "number" or newSummitValue < 0 then
		NotificationService:Send(admin, {
			Message = "Invalid summit value!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		NotificationService:Send(admin, {
			Message = "Target player not found!",
			Type = "error",
			Duration = 3
		})
		return
	end

	print(string.format("[ADMIN] %s modifying summit for %s to %d", admin.Name, targetPlayer.Name, newSummitValue))

	-- 1. Update DataHandler & Save
	DataHandler:Set(targetPlayer, "TotalSummits", newSummitValue)
	DataHandler:SavePlayer(targetPlayer)
	print("[ADMIN] ✅ DataStore updated")
	
	-- 1.5. ✅ UPDATE LEADERBOARD ORDEREDDATASTORE
	DataHandler:UpdateLeaderboards(targetPlayer)
	print("[ADMIN] ✅ Leaderboard OrderedDataStore updated")
	
	-- 1.6. ✅ REFRESH LEADERBOARD DISPLAY (SurfaceGui)
	task.spawn(function()
		task.wait(0.5) -- Wait for OrderedDataStore to be fully written
		local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
		if refreshEvent and refreshEvent:IsA("BindableEvent") then
			refreshEvent:Fire("Summit")
			print("[ADMIN] ✅ Leaderboard display refreshed")
		end
	end)

	-- 2. Update PlayerStats UI
	if targetPlayer:FindFirstChild("PlayerStats") then
		local summitValue = targetPlayer.PlayerStats:FindFirstChild("Summit")
		if summitValue then
			summitValue.Value = newSummitValue
			print("[ADMIN] ✅ PlayerStats updated")
		end
	end

	-- 3. SYNC LOCAL CACHE VIA BINDABLE EVENT (with proper data parameter)
	task.spawn(function()
		task.wait(0.5)

		print("[ADMIN] Triggering sync via BindableEvent...")
		local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")

		if syncEvent and syncEvent:IsA("BindableEvent") then
			-- ✅ FIX: Pass migratedData with updated TotalSummits so CheckpointSystem can sync its cache
			local syncData = {
				TotalSummits = newSummitValue,
				TotalDonations = DataHandler:Get(targetPlayer, "TotalDonations"),
				LastCheckpoint = DataHandler:Get(targetPlayer, "LastCheckpoint"),
				BestSpeedrun = DataHandler:Get(targetPlayer, "BestSpeedrun"),
				TotalPlaytime = DataHandler:Get(targetPlayer, "TotalPlaytime"),
			}
			syncEvent:Fire(targetPlayer, syncData)
			print("[ADMIN] ✅ Sync event fired with data!")
		else
			warn("[ADMIN] ❌ Sync event not found!")
		end
	end)


	-- 4. Sync summit titles (add/remove based on new value)
	task.spawn(function()
		task.wait(1)  -- Wait biar sync selesai dulu
		TitleServer:SyncSummitTitles(targetPlayer, newSummitValue)
		print("[ADMIN] ✅ Title synced")
	end)

	-- 5. Notify
	NotificationService:Send(targetPlayer, {
		Message = string.format("Admin set your summit to %d", newSummitValue),
		Type = "info",
		Duration = 5
	})

	NotificationService:Send(admin, {
		Message = string.format("Set %s's summit to %d", targetPlayer.Name, newSummitValue),
		Type = "success",
		Duration = 3
	})

	print(string.format("[ADMIN] ✅ DONE! %s summit = %d", targetPlayer.Name, newSummitValue))

	-- Log the action
	AdminLogServer:Log(admin.UserId, admin.Name, "set_summit", {UserId = targetUserId, Name = targetPlayer.Name}, "New value: " .. newSummitValue)
end)

-- ✅ SEARCH LEADERBOARD DATA
searchLeaderboardEvent.OnServerInvoke = function(admin, username)
	if not isAdmin(admin.UserId) then
		return {success = false, message = "Not authorized"}
	end

	print(string.format("[ADMIN] %s searching for: %s", admin.Name, username))

	-- Get player by username
	local targetUserId = nil
	local targetUsername = nil

	-- Try to get UserID from username
	local success, result = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)

	if not success or not result then
		return {success = false, message = "Player not found"}
	end

	targetUserId = result

	-- Get username (for display)
	local nameSuccess, displayName = pcall(function()
		return Players:GetNameFromUserIdAsync(targetUserId)
	end)

	targetUsername = nameSuccess and displayName or username

	-- Get data from all leaderboards (using centralized config)
	local DataStoreService = game:GetService("DataStoreService")
	local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
	local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
	local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

	local leaderboardData = {
		UserId = targetUserId,
		Username = targetUsername,
		Summit = 0,
		Speedrun = "N/A",
		Playtime = 0,
		Donate = 0
	}

	-- Get Summit data
	pcall(function()
		local data = SummitLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Summit = data
		end
	end)

	-- Get Speedrun data
	pcall(function()
		local data = SpeedrunLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			local timeSeconds = math.abs(data) / 1000
			leaderboardData.Speedrun = string.format("%02d:%02d:%02d", 
				math.floor(timeSeconds / 3600),
				math.floor((timeSeconds % 3600) / 60),
				math.floor(timeSeconds % 60)
			)
		end
	end)

	-- Get Playtime data
	pcall(function()
		local data = PlaytimeLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Playtime = data
		end
	end)

	-- Get Donation data
	pcall(function()
		local data = DonationLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Donate = data
		end
	end)

	return {success = true, data = leaderboardData}
end

deleteLeaderboardEvent.OnServerEvent:Connect(function(player, targetUserId, dataType)
	if not isAdmin(player.UserId) then return end

	print("[ADMIN] " .. player.Name .. " deleting " .. dataType .. " data for UserID: " .. targetUserId)

	local DataStoreService = game:GetService("DataStoreService")
	local PlayerDataStore = DataStoreService:GetDataStore(DataStoreConfig.PlayerData) -- ✅ Use config

	-- ✅ LANGSUNG UPDATE DATASTORE dengan UpdateAsync (bypass cache completely)
	local success, errorMsg = pcall(function()
		return PlayerDataStore:UpdateAsync("Player_" .. targetUserId, function(oldData)
			if not oldData then
				oldData = DataHandler:GetData(Players:GetPlayerByUserId(targetUserId))
				if not oldData then return nil end
			end

			-- Reset fields
			if dataType == "summit" or dataType == "all" then
				oldData.TotalSummits = 0
			end
			if dataType == "speedrun" or dataType == "all" then
				oldData.BestSpeedrun = 0
			end
			if dataType == "playtime" or dataType == "all" then
				oldData.TotalPlaytime = 0
			end
			if dataType == "donate" or dataType == "all" then
				oldData.TotalDonation = 0
			end

			print("[ADMIN] ✅ UpdateAsync writing: TotalSummits = " .. (oldData.TotalSummits or 0))
			return oldData -- ✅ This OVERWRITES DataStore immediately
		end)
	end)

	if not success then
		warn("[ADMIN] ❌ Failed UpdateAsync: " .. tostring(errorMsg))
		NotificationService:Send(player, {
			Message = "Failed to delete data!",
			Type = "error",
			Duration = 3
		})
		return
	end

	print("[ADMIN] ✅ DataStore updated via UpdateAsync")

	-- ✅ DELETE FROM LEADERBOARDS (using centralized config)
	local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
	local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
	local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

	if dataType == "summit" or dataType == "all" then
		pcall(function() SummitLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end
	if dataType == "speedrun" or dataType == "all" then
		pcall(function() SpeedrunLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end
	if dataType == "playtime" or dataType == "all" then
		pcall(function() PlaytimeLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end
	if dataType == "donate" or dataType == "all" then
		pcall(function() DonationLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end

	-- ✅ UPDATE IN-MEMORY CACHE (kalau player online)
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		-- FORCE reload data from DataStore
		task.spawn(function()
			task.wait(0.5)

			-- ✅ Get fresh data from DataStore
			local freshData = nil
			pcall(function()
				freshData = PlayerDataStore:GetAsync("Player_" .. targetUserId)
			end)

			if freshData then
				-- ✅ Update DataHandler cache dengan data fresh
				local cache = DataHandler:GetData(targetPlayer)
				if cache then
					if dataType == "summit" or dataType == "all" then
						cache.TotalSummits = 0
					end
					if dataType == "speedrun" or dataType == "all" then
						cache.BestSpeedrun = 0
					end
					if dataType == "playtime" or dataType == "all" then
						cache.TotalPlaytime = 0
					end
					if dataType == "donate" or dataType == "all" then
						cache.TotalDonation = 0
					end
					print("[ADMIN] ✅ Updated in-memory cache")
				end

				-- Update PlayerStats
				if targetPlayer:FindFirstChild("PlayerStats") then
					local playerStats = targetPlayer.PlayerStats
					if dataType == "summit" or dataType == "all" and playerStats:FindFirstChild("Summit") then
						playerStats.Summit.Value = 0
					end
					if dataType == "speedrun" or dataType == "all" and playerStats:FindFirstChild("Best Speedrun") then
						playerStats["Best Speedrun"].Value = 0
					end
					if dataType == "playtime" or dataType == "all" and playerStats:FindFirstChild("Playtime") then
						playerStats.Playtime.Value = 0
					end
					print("[ADMIN] ✅ Updated PlayerStats")
				end

				-- ✅ FIX: Use SyncPlayerDataEvent to update CheckpointSystem cache properly
				local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")
				if syncEvent and syncEvent:IsA("BindableEvent") then
					local syncData = {
						TotalSummits = cache and cache.TotalSummits or 0,
						TotalDonations = cache and cache.TotalDonations or 0,
						LastCheckpoint = cache and cache.LastCheckpoint or 0,
						BestSpeedrun = cache and cache.BestSpeedrun or nil,
						TotalPlaytime = cache and cache.TotalPlaytime or 0,
					}
					syncEvent:Fire(targetPlayer, syncData)
					print("[ADMIN] ✅ Sync event fired for CheckpointSystem cache update")
				end
			end
		end)

		-- Notify player
		NotificationService:Send(targetPlayer, {
			Message = string.format("%s data has been reset to 0!", dataType:upper()),
			Type = "warning",
			Duration = 5
		})
	end

	-- ✅ FIX: Use RefreshLeaderboardsEvent instead of trying to require CheckpointSystem
	task.delay(1, function()
		local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
		if refreshEvent and refreshEvent:IsA("BindableEvent") then
			refreshEvent:Fire("All")  -- Refresh all leaderboards
			print("[ADMIN] ✅ Leaderboard display refresh triggered")
		end
	end)

	-- Notify admin
	NotificationService:Send(player, {
		Message = string.format("%s data PERMANENTLY deleted!", dataType:upper()),
		Type = "success",
		Duration = 5
	})

	-- Log the action (get target username)
	local targetUsername = "Unknown"
	pcall(function()
		targetUsername = Players:GetNameFromUserIdAsync(targetUserId)
	end)
	AdminLogServer:Log(player.UserId, player.Name, "delete_data", {UserId = targetUserId, Name = targetUsername}, "Type: " .. dataType:upper())

	print("[ADMIN] ✅ DONE! Data deleted via UpdateAsync")
end)





print("✅ [ADMIN SERVER] System loaded")

-- ✅ GET LEADERBOARD DATA (for leaderboard viewer)
getLeaderboardDataFunc.OnServerInvoke = function(admin, leaderboardType, limit)
	if not isAdmin(admin.UserId) then
		return {success = false, message = "Not authorized"}
	end
	
	limit = limit or 50 -- Default limit
	if limit > 100 then limit = 100 end -- Max limit
	
	print(string.format("[ADMIN] %s fetching %s leaderboard (limit: %d)", admin.Name, leaderboardType, limit))
	
	local DataStoreService = game:GetService("DataStoreService")
	local leaderboard = nil
	local isAscending = false -- For speedrun, lower is better
	local formatValue = nil
	
	if leaderboardType == "summit" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
		formatValue = function(val) return tostring(val) end
	elseif leaderboardType == "speedrun" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
		isAscending = true
		formatValue = function(val)
			local timeSeconds = math.abs(val) / 1000
			return string.format("%02d:%02d:%02d", 
				math.floor(timeSeconds / 3600),
				math.floor((timeSeconds % 3600) / 60),
				math.floor(timeSeconds % 60)
			)
		end
	elseif leaderboardType == "donate" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)
		formatValue = function(val) return "R$" .. tostring(val) end
	elseif leaderboardType == "playtime" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
		formatValue = function(val)
			return string.format("%dh %dm", math.floor(val / 3600), math.floor((val % 3600) / 60))
		end
	else
		return {success = false, message = "Invalid leaderboard type"}
	end
	
	local entries = {}
	
	local success, errorMsg = pcall(function()
		local pages
		if isAscending then
			pages = leaderboard:GetSortedAsync(true, limit) -- Ascending for speedrun
		else
			pages = leaderboard:GetSortedAsync(false, limit) -- Descending for others
		end
		
		local currentPage = pages:GetCurrentPage()
		
		for rank, entry in ipairs(currentPage) do
			local userId = tonumber(entry.key)
			local value = entry.value
			
			-- Get username
			local username = "Unknown"
			local nameSuccess, displayName = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameSuccess then
				username = displayName
			end
			
			table.insert(entries, {
				Rank = rank,
				UserId = userId,
				Username = username,
				Value = value,
				FormattedValue = formatValue(value)
			})
		end
	end)
	
	if not success then
		warn("[ADMIN] Failed to fetch leaderboard: " .. tostring(errorMsg))
		return {success = false, message = "Failed to fetch data"}
	end
	
	return {success = true, data = entries, type = leaderboardType}
end