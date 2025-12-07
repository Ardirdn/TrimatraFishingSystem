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

local DonationLeaderboard = DataStoreService:GetOrderedDataStore("DonationLeaderboard")

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

-- Update Donation Leaderboard Display
local function updateDonationLeaderboard()
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
		if rankLabel then rankLabel.Text = "#" .. rank end

		local nameLabel = newFrame:FindFirstChild("PlayerName")
		if nameLabel then nameLabel.Text = displayName end

		local valueLabel = newFrame:FindFirstChild("Amount")
		if valueLabel then valueLabel.Text = "R$" .. tostring(totalDonated) end

		newFrame.Parent = scrollingFrame
	end

	print("[DONATE] Leaderboard updated")
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