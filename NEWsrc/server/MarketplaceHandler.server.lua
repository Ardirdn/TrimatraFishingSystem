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

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TitleServer)

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))

local purchaseHistory = {}

-- ✅ AUTO-CLEANUP: Bersihkan purchaseHistory setiap 10 menit untuk mencegah memory leak
task.spawn(function()
	while true do
		task.wait(600) -- 10 menit
		local count = 0
		for _ in pairs(purchaseHistory) do 
			count = count + 1 
		end
		if count > 0 then
			purchaseHistory = {}
			print(string.format("[MARKETPLACE] 🧹 Cleared %d purchase history entries (memory cleanup)", count))
		end
	end
end)

print("✅ [MARKETPLACE HANDLER] Initializing...")

-- ✅ DEBUG: Log all valid ProductIds at startup
print("📋 [MARKETPLACE] Valid Money Pack ProductIds:")
for i, pack in ipairs(ShopConfig.MoneyPacks) do
	print(string.format("   %d. %s = ProductId: %d, Reward: $%d", i, pack.Title, pack.ProductId, pack.MoneyReward))
end

print("📋 [MARKETPLACE] Valid Donation ProductIds:")
for i, pkg in ipairs(DonateConfig.Packages) do
	print(string.format("   %d. %s = ProductId: %d", i, pkg.Title, pkg.ProductId))
end

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

-- NOTE: Donation Leaderboard display updates are now handled by LeaderboardServer.server.lua
-- Leaderboards are in workspace.Leaderboards folder and support multiple copies
local function updateDonationLeaderboard()
	-- Handled by LeaderboardServer
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

			-- Update donation leaderboard via DataHandler
			DataHandler:UpdateLeaderboards(player)

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
	print(string.format("🔍 [MARKETPLACE] Checking %d money packs for ProductId: %d", #ShopConfig.MoneyPacks, productId))
	for i, pack in ipairs(ShopConfig.MoneyPacks) do
		print(string.format("   Pack %d: %s (ProductId: %d) - Match: %s", i, pack.Title, pack.ProductId, tostring(pack.ProductId == productId)))
		if pack.ProductId == productId then
			print(string.format("💰 [MARKETPLACE] ✅ MATCHED! Processing money pack: %s", pack.Title))

			local beforeMoney = DataHandler:Get(player, "Money") or 0
			print(string.format("   Before: $%d, Adding: $%d", beforeMoney, pack.MoneyReward))
			
			local incrementSuccess = DataHandler:Increment(player, "Money", pack.MoneyReward)
			print(string.format("   Increment success: %s", tostring(incrementSuccess)))
			
			DataHandler:Increment(player, "TotalDonations", pack.Price)
			DataHandler:SavePlayer(player)
			
			local afterMoney = DataHandler:Get(player, "Money") or 0
			print(string.format("   After: $%d", afterMoney))

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
			print(string.format("✅ [MARKETPLACE] Money pack purchased: %s bought $%d (New balance: $%d)", player.Name, pack.MoneyReward, afterMoney))
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
