--[[
    DONATE SERVER (SIMPLIFIED)
    Place in ServerScriptService/DonateServer
    
    Handles:
    - Donate UI data requests
    - Donation purchase prompts
    - Leaderboard updates
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

-- Create RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("DonateRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "DonateRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getDonateDataFunc = remoteFolder:FindFirstChild("GetDonateData")
if not getDonateDataFunc then
	getDonateDataFunc = Instance.new("RemoteFunction")
	getDonateDataFunc.Name = "GetDonateData"
	getDonateDataFunc.Parent = remoteFolder
end

local purchaseDonationEvent = remoteFolder:FindFirstChild("PurchaseDonation")
if not purchaseDonationEvent then
	purchaseDonationEvent = Instance.new("RemoteEvent")
	purchaseDonationEvent.Name = "PurchaseDonation"
	purchaseDonationEvent.Parent = remoteFolder
end

print("✅ [DONATE SERVER] Initialized")

-- Get player donation data
getDonateDataFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			TotalDonations = 0,
			HasDonaturTitle = false
		}
	end

	local hasDonatur = data.TotalDonations >= DonateConfig.DonationThreshold

	return {
		TotalDonations = data.TotalDonations or 0,
		HasDonaturTitle = hasDonatur
	}
end

-- Purchase Donation
purchaseDonationEvent.OnServerEvent:Connect(function(player, productId)
	if not productId or productId == 0 then
		NotificationService:Send(player, {
			Message = "Product ID not configured!",
			Type = "error",
			Duration = 3
		})
		return
	end

	print(string.format("💰 [DONATE] Purchase request: %s - Product %d", player.Name, productId))
	MarketplaceService:PromptProductPurchase(player, productId)
end)

-- NOTE: Donation Leaderboard display updates are now handled by LeaderboardServer.server.lua
-- Leaderboards are in workspace.Leaderboards folder and support multiple copies
local function updateDonationLeaderboard()
	-- Handled by LeaderboardServer
end

-- Auto update leaderboard
task.spawn(function()
	while task.wait(60) do
		updateDonationLeaderboard()
	end
end)

task.wait(3)
updateDonationLeaderboard()

print("✅ [DONATE SERVER] System loaded")