--[[
    MARKETPLACE HANDLER
    Place in ServerScriptService/MarketplaceHandler
    
    Unified ProcessReceipt handler for all purchases:
    - Donations
    - Money Packs
    - Premium Auras/Tools
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(ServerScriptService:WaitForChild("TItleServer"))

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))

local purchaseHistory = {}

print("✅ [MARKETPLACE HANDLER] Initializing...")

-- Helper: Send data update to client
local function sendDataUpdate(player)
	local data = DataHandler:GetData(player)
	if not data then return end

	local updateEvent = ReplicatedStorage:FindFirstChild("ShopRemotes"):FindFirstChild("UpdatePlayerData")
	if updateEvent then
		pcall(function()
			updateEvent:FireClient(player, {
				Money = data.Money,
				OwnedAuras = data.OwnedAuras,
				OwnedTools = data.OwnedTools,
			})
		end)
	end
end

-- Helper: Update donation leaderboard
local function updateDonationLeaderboard()
	local DataStoreService = game:GetService("DataStoreService")
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore("DonationLeaderboard")

	local leaderboardPart = workspace:FindFirstChild("DonationLeaderboard")
	if not leaderboardPart then return end

	local surfaceGui = leaderboardPart:FindFirstChild("SurfaceGui")
	if not surfaceGui then return end

	local scrollingFrame = surfaceGui:FindFirstChild("ScrollingFrame")
	if not scrollingFrame then return end

	local sample = scrollingFrame:FindFirstChild("Sample")
	if not sample then return end

	sample.Visible = false

	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Sample" then
			child:Destroy()
		end
	end

	local success, data = pcall(function()
		return DonationLeaderboard:GetSortedAsync(false, 10)
	end)

	if not success then return end

	local page = data:GetCurrentPage()

	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local totalDonated = entry.value

		local nameSuccess, username = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)

		local displayName = nameSuccess and username or "Player"

		local newFrame = sample:Clone()
		newFrame.Name = "Entry" .. rank
		newFrame.Visible = true

		local rankLabel = newFrame:FindFirstChild("Rank")
		if rankLabel then
			rankLabel.Text = "#" .. rank
		end

		local nameLabel = newFrame:FindFirstChild("PlayerName")
		if nameLabel then
			nameLabel.Text = displayName
		end

		local valueLabel = newFrame:FindFirstChild("Amount")
		if valueLabel then
			valueLabel.Text = "R$" .. tostring(totalDonated)
		end

		newFrame.Parent = scrollingFrame
	end

	print("[MARKETPLACE] Donation leaderboard updated")
end

-- Unified ProcessReceipt
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId

	print(string.format("💳 [MARKETPLACE] Processing: User %d, Product %d, Purchase %s", userId, productId, purchaseId))

	-- Prevent duplicates
	if purchaseHistory[purchaseId] then
		print(string.format("⚠️ [MARKETPLACE] Duplicate purchase detected: %s", purchaseId))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		print(string.format("⚠️ [MARKETPLACE] Player not found: %d", userId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- ===== 1. CHECK DONATIONS =====
	for _, package in ipairs(DonateConfig.Packages) do
		if package.ProductId == productId then
			print(string.format("💝 [MARKETPLACE] Processing donation: %s", package.Title))

			local amount = package.Amount
			DataHandler:Increment(player, "TotalDonations", amount)
			local totalDonations = DataHandler:Get(player, "TotalDonations")
			DataHandler:SavePlayer(player)

			if totalDonations >= DonateConfig.DonationThreshold then
				TitleServer:GrantSpecialTitle(player, "Donatur")
				NotificationService:Send(player, {
					Message = "🎉 Kamu mendapatkan title 'Donatur'! Terima kasih!",
					Type = "success",
					Duration = 7,
					Icon = "💎"
				})
			else
				NotificationService:Send(player, {
					Message = string.format("Terima kasih telah donate R$%d! 💖", amount),
					Type = "success",
					Duration = 5,
					Icon = "💝"
				})
			end

			-- Update donation leaderboard
			local DataStoreService = game:GetService("DataStoreService")
			local DonationLeaderboard = DataStoreService:GetOrderedDataStore("DonationLeaderboard")
			pcall(function()
				DonationLeaderboard:SetAsync(tostring(userId), totalDonations)
			end)

			task.spawn(function()
				task.wait(1)
				updateDonationLeaderboard()
			end)

			purchaseHistory[purchaseId] = true
			print(string.format("✅ [MARKETPLACE] Donation completed: %s donated R$%d (Total: R$%d)", player.Name, amount, totalDonations))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- ===== 2. CHECK MONEY PACKS =====
	for _, pack in ipairs(ShopConfig.MoneyPacks) do
		if pack.ProductId == productId then
			print(string.format("💰 [MARKETPLACE] Processing money pack: %s", pack.Title))

			DataHandler:Increment(player, "Money", pack.MoneyReward)
			DataHandler:Increment(player, "TotalDonations", pack.Price)
			DataHandler:SavePlayer(player)

			local totalDonations = DataHandler:Get(player, "TotalDonations")
			if totalDonations >= DonateConfig.DonationThreshold then
				TitleServer:GrantSpecialTitle(player, "Donatur")
			end

			NotificationService:Send(player, {
				Message = string.format("Received $%d! Thank you for supporting!", pack.MoneyReward),
				Type = "success",
				Duration = 5,
				Icon = "💰"
			})

			sendDataUpdate(player)
			purchaseHistory[purchaseId] = true
			print(string.format("✅ [MARKETPLACE] Money pack purchased: %s bought $%d", player.Name, pack.MoneyReward))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- ===== 3. CHECK PREMIUM AURAS =====
	for _, aura in ipairs(ShopConfig.Auras) do
		if aura.IsPremium and aura.ProductId == productId then
			print(string.format("✨ [MARKETPLACE] Processing premium aura: %s", aura.Title))

			if not DataHandler:ArrayContains(player, "OwnedAuras", aura.AuraId) then
				DataHandler:AddToArray(player, "OwnedAuras", aura.AuraId)
				DataHandler:SavePlayer(player)

				NotificationService:Send(player, {
					Message = string.format("Purchased %s!", aura.Title),
					Type = "success",
					Duration = 5
				})

				sendDataUpdate(player)
			end

			purchaseHistory[purchaseId] = true
			print(string.format("✅ [MARKETPLACE] Premium aura purchased: %s", aura.Title))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- ===== 4. CHECK PREMIUM TOOLS =====
	for _, tool in ipairs(ShopConfig.Tools) do
		if tool.IsPremium and tool.ProductId == productId then
			print(string.format("🔧 [MARKETPLACE] Processing premium tool: %s", tool.Title))

			if not DataHandler:ArrayContains(player, "OwnedTools", tool.ToolId) then
				DataHandler:AddToArray(player, "OwnedTools", tool.ToolId)
				DataHandler:SavePlayer(player)

				NotificationService:Send(player, {
					Message = string.format("Purchased %s!", tool.Title),
					Type = "success",
					Duration = 5
				})

				sendDataUpdate(player)
			end

			purchaseHistory[purchaseId] = true
			print(string.format("✅ [MARKETPLACE] Premium tool purchased: %s", tool.Title))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	
	-- ===== 5. CHECK SKIP CHECKPOINT =====
	if _G.SKIP_PRODUCT_ID and productId == _G.SKIP_PRODUCT_ID then
		print(string.format("🚀 [MARKETPLACE] Processing skip checkpoint for %s", player.Name))

		-- Execute skip via global function
		if _G.ExecuteSkipCheckpoint then
			_G.ExecuteSkipCheckpoint(player)
		else
			warn("[MARKETPLACE] Skip function not found!")
		end

		purchaseHistory[purchaseId] = true
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Unknown product
	warn(string.format("⚠️ [MARKETPLACE] Unknown product ID: %d", productId))
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

print("✅ [MARKETPLACE HANDLER] System loaded")
