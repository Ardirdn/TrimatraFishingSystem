--[[
    PLAYER INFO SERVER - AUTO TITLE ASSIGNMENT
    Place in ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local VIPStore = DataStoreService:GetDataStore("VIPStatus_v1")

-- Wait for remote folder with timeout
local PlayerInfoRemotes = ReplicatedStorage:WaitForChild("PlayerInfoRemotes", 10)
if not PlayerInfoRemotes then
	warn("❌ [PLAYER INFO SERVER] PlayerInfoRemotes not found - creating...")
	PlayerInfoRemotes = Instance.new("Folder")
	PlayerInfoRemotes.Name = "PlayerInfoRemotes"
	PlayerInfoRemotes.Parent = ReplicatedStorage
end

local GiveGamepassEvent = PlayerInfoRemotes:WaitForChild("GiveGamepass", 5)
if not GiveGamepassEvent then
	GiveGamepassEvent = Instance.new("RemoteEvent")
	GiveGamepassEvent.Name = "GiveGamepass"
	GiveGamepassEvent.Parent = PlayerInfoRemotes
end

-- Handle gift requests
GiveGamepassEvent.OnServerEvent:Connect(function(buyerPlayer, targetUserId, gamepassType)
	print("🎁 [SERVER] Gift request received!")
	print("  Buyer:", buyerPlayer.Name)
	print("  Target UserId:", targetUserId)
	print("  Type:", gamepassType)

	-- Validate
	if not buyerPlayer or not targetUserId or not gamepassType then
		warn("⚠️ Invalid gift request!")
		return
	end

	-- Save VIP status to DataStore
	local saveSuccess = pcall(function()
		local currentData = VIPStore:GetAsync(tostring(targetUserId)) or {}

		if gamepassType == "VIP" then
			currentData.HasVIP = true
			currentData.VIPGiftedBy = buyerPlayer.UserId
			currentData.VIPGiftedAt = os.time()
		elseif gamepassType == "VVIP" then
			currentData.HasVVIP = true
			currentData.VVIPGiftedBy = buyerPlayer.UserId
			currentData.VVIPGiftedAt = os.time()
		end

		VIPStore:SetAsync(tostring(targetUserId), currentData)
		print("✅ [SERVER] VIP status saved to DataStore")
	end)

	if not saveSuccess then
		warn("⚠️ Failed to save VIP status")
		return
	end

	-- Find target player
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then
		print("✅ [SERVER] Target player is ONLINE:", targetPlayer.Name)

		-- ✅ AUTO-ASSIGN TITLE
		task.spawn(function()
			-- Wait for title system to load
			task.wait(0.5)

			-- Get Title system
			local TitleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
			if not TitleRemotes then
				warn("⚠️ TitleRemotes not found!")
				return
			end

			-- Get SetTitle remote function
			local SetTitle = TitleRemotes:FindFirstChild("SetTitle")
			if not SetTitle then
				warn("⚠️ SetTitle RemoteFunction not found!")
				return
			end

			-- Set title to VIP/VVIP
			local titleName = gamepassType -- "VIP" or "VVIP"

			local setSuccess = pcall(function()
				SetTitle:InvokeClient(targetPlayer, titleName)
				print("✅ [SERVER] Title set to:", titleName)
			end)

			if setSuccess then
				-- Notify target player
				local NotificationRemote = ReplicatedStorage:FindFirstChild("NotificationRemote")
				if NotificationRemote then
					NotificationRemote:FireClient(targetPlayer, {
						Title = "Gift Received!",
						Text = buyerPlayer.DisplayName .. " gave you " .. titleName .. "!",
						Duration = 5
					})
				end

				print("✅ [SERVER] Title assigned and notification sent")
			else
				warn("⚠️ Failed to set title")
			end
		end)
	else
		print("ℹ️ [SERVER] Target player is OFFLINE")
	end
end)

-- ✅ CREATE GiveItem RemoteEvent for Auras & Tools
local GiveItemEvent = PlayerInfoRemotes:FindFirstChild("GiveItem")
if not GiveItemEvent then
	GiveItemEvent = Instance.new("RemoteEvent")
	GiveItemEvent.Name = "GiveItem"
	GiveItemEvent.Parent = PlayerInfoRemotes
	print("✅ [SERVER] GiveItem RemoteEvent created")
end

-- ✅ HANDLE AURA & TOOL GIFTS
GiveItemEvent.OnServerEvent:Connect(function(buyerPlayer, targetUserId, rewardType, rewardId)
	print("🎁 [SERVER] Item gift request received!")
	print("  Buyer:", buyerPlayer.Name)
	print("  Target UserId:", targetUserId)
	print("  Type:", rewardType)
	print("  ID:", rewardId)

	-- Validate
	if not buyerPlayer or not targetUserId or not rewardType or not rewardId then
		warn("⚠️ Invalid item gift request!")
		return
	end

	-- Find target player
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then
		print("✅ [SERVER] Target player is ONLINE:", targetPlayer.Name)

		if rewardType == "Aura" then
			-- Give Aura
			print("🌟 [SERVER] Giving aura:", rewardId)

			-- Save to DataStore (if you have AuraDataStore)
			local AuraStore = DataStoreService:GetDataStore("AuraData_v1")
			local saveSuccess = pcall(function()
				local currentData = AuraStore:GetAsync(tostring(targetUserId)) or {UnlockedAuras = {}}

				-- Add aura if not already unlocked
				if not table.find(currentData.UnlockedAuras, rewardId) then
					table.insert(currentData.UnlockedAuras, rewardId)
					AuraStore:SetAsync(tostring(targetUserId), currentData)
					print("✅ [SERVER] Aura unlocked in DataStore")
				end
			end)

			-- Fire to client to unlock aura immediately
			local AuraRemotes = ReplicatedStorage:FindFirstChild("AuraRemotes")
			if AuraRemotes then
				local UnlockAuraEvent = AuraRemotes:FindFirstChild("UnlockAura")
				if UnlockAuraEvent then
					UnlockAuraEvent:FireClient(targetPlayer, rewardId)
					print("✅ [SERVER] Aura unlock event sent to client")
				end
			end

		elseif rewardType == "Tool" then
			-- Give Tool
			print("⚔️ [SERVER] Giving tool:", rewardId)

			-- Get tool from ServerStorage or ReplicatedStorage
			local tool = game:GetService("ServerStorage"):FindFirstChild(rewardId)

			if not tool then
				tool = ReplicatedStorage:FindFirstChild(rewardId)
			end

			if tool then
				local toolClone = tool:Clone()
				toolClone.Parent = targetPlayer.Backpack
				print("✅ [SERVER] Tool given to player")
			else
				warn("⚠️ Tool not found:", rewardId)
			end

		elseif rewardType == "Gamepass" then
			-- Handle as gamepass (same as VIP/VVIP logic)
			print("👑 [SERVER] Giving gamepass:", rewardId)
			-- Use existing VIP logic or handle separately
		end

	else
		print("ℹ️ [SERVER] Target player is OFFLINE")
	end
end)


print("✓ Player Info Server loaded successfully")
