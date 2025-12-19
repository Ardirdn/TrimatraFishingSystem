--[[
    FISHERMAN SHOP SERVER
    Place in ServerScriptService
    
    Handles fish selling logic
    Player can sell fish from their FishInventory to get money
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.Parent.DataHandler)
local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))

-- Create RemoteFolder
local remoteFolder = ReplicatedStorage:FindFirstChild("FishermanShopRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "FishermanShopRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteFunctions/Events
local function createRemote(name, isFunction)
	local existing = remoteFolder:FindFirstChild(name)
	if existing then return existing end
	
	local remote
	if isFunction then
		remote = Instance.new("RemoteFunction")
	else
		remote = Instance.new("RemoteEvent")
	end
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local getFishInventoryFunc = createRemote("GetFishInventory", true)
local sellFishEvent = createRemote("SellFish", false)
local sellAllFishEvent = createRemote("SellAllFish", false)
local sellSelectedFishEvent = createRemote("SellSelectedFish", false)
local fishSoldEvent = createRemote("FishSold", false) -- Notify client when fish sold
local getDiscoveredFishFunc = createRemote("GetDiscoveredFish", true)

print("✅ [FISHERMAN SHOP SERVER] Initialized")

-- ==================== HELPER FUNCTIONS ====================

-- Create RemoteEvent for notifications
local nativeNotifEvent = remoteFolder:FindFirstChild("NativeNotification")
if not nativeNotifEvent then
	nativeNotifEvent = Instance.new("RemoteEvent")
	nativeNotifEvent.Name = "NativeNotification"
	nativeNotifEvent.Parent = remoteFolder
end

local function sendNotification(player, message, notifType, icon)
	-- Gunakan notifikasi bawaan Roblox
	pcall(function()
		nativeNotifEvent:FireClient(player, {
			Title = "Fisherman Shop",
			Text = message,
			Icon = icon or "rbxassetid://6031075938", -- Default fish icon
			Duration = 3
		})
	end)
	print(string.format("[FISHERMAN SHOP] %s: %s", player.Name, message))
end

local function calculateFishValue(fishId, count)
	local fishData = FishConfig.Fish[fishId]
	if not fishData then return 0 end
	return (fishData.Price or 0) * count
end

local function getTotalInventoryValue(fishInventory)
	local total = 0
	for fishId, count in pairs(fishInventory) do
		total = total + calculateFishValue(fishId, count)
	end
	return total
end

-- ==================== GET FISH INVENTORY ====================

getFishInventoryFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then return nil end
	
	local fishInventory = data.FishInventory or {}
	local totalValue = getTotalInventoryValue(fishInventory)
	
	-- Build detailed list with fish data
	local fishList = {}
	for fishId, count in pairs(fishInventory) do
		local fishData = FishConfig.Fish[fishId]
		if fishData and count > 0 then
			table.insert(fishList, {
				FishId = fishId,
				Count = count,
				Name = fishData.Name,
				Rarity = fishData.Rarity,
				Price = fishData.Price or 0,
				TotalValue = (fishData.Price or 0) * count,
				ImageID = fishData.ImageID,
				ModelId = fishData.ModelId
			})
		end
	end
	
	return {
		FishList = fishList,
		TotalValue = totalValue,
		Money = data.Money or 0
	}
end

-- ==================== GET DISCOVERED FISH (FOR INDEX) ====================

getDiscoveredFishFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then return nil end
	
	local discoveredFish = data.DiscoveredFish or {}
	local allFish = {}
	
	-- Get all fish from config and mark discovered/undiscovered
	for fishId, fishData in pairs(FishConfig.Fish) do
		local isDiscovered = discoveredFish[fishId] == true
		table.insert(allFish, {
			FishId = fishId,
			Name = fishData.Name,
			Rarity = fishData.Rarity,
			Price = isDiscovered and (fishData.Price or 0) or nil, -- Hide price if not discovered
			ImageID = fishData.ImageID,
			ModelId = fishData.ModelId,
			IsDiscovered = isDiscovered
		})
	end
	
	-- Sort by rarity order
	local rarityOrder = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6}
	table.sort(allFish, function(a, b)
		local orderA = rarityOrder[a.Rarity] or 0
		local orderB = rarityOrder[b.Rarity] or 0
		if orderA == orderB then
			return a.Name < b.Name
		end
		return orderA < orderB
	end)
	
	return {
		AllFish = allFish,
		DiscoveredCount = #discoveredFish,
		TotalCount = 0 -- Will be calculated by client since it's a dictionary
	}
end

-- ==================== SELL SINGLE FISH ====================

sellFishEvent.OnServerEvent:Connect(function(player, fishId, quantity)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	local fishInventory = data.FishInventory or {}
	local currentCount = fishInventory[fishId] or 0
	
	quantity = math.min(quantity or 1, currentCount)
	
	if currentCount <= 0 or quantity <= 0 then
		sendNotification(player, "You don't have this fish!", "error", "❌")
		return
	end
	
	local fishData = FishConfig.Fish[fishId]
	if not fishData then
		sendNotification(player, "Invalid fish!", "error", "❌")
		return
	end
	
	local fishValue = (fishData.Price or 0) * quantity
	
	-- Remove fish from inventory
	fishInventory[fishId] = currentCount - quantity
	if fishInventory[fishId] <= 0 then
		fishInventory[fishId] = nil
	end
	
	-- Update data
	DataHandler:Set(player, "FishInventory", fishInventory)
	DataHandler:Increment(player, "Money", fishValue)
	DataHandler:SavePlayer(player)
	
	-- Notify
	sendNotification(player, string.format("Sold %dx %s for $%d!", quantity, fishData.Name, fishValue), "success", "💰")
	
	-- Fire event to client for UI update
	fishSoldEvent:FireClient(player, {
		FishId = fishId,
		Quantity = quantity,
		Earned = fishValue,
		NewMoney = DataHandler:Get(player, "Money") or 0
	})
	
	print(string.format("💰 [FISHERMAN SHOP] %s sold %dx %s for $%d", player.Name, quantity, fishData.Name, fishValue))
end)

-- ==================== SELL ALL FISH ====================

sellAllFishEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	local fishInventory = data.FishInventory or {}
	local totalValue = getTotalInventoryValue(fishInventory)
	local totalCount = 0
	
	for _, count in pairs(fishInventory) do
		totalCount = totalCount + count
	end
	
	if totalCount <= 0 then
		sendNotification(player, "No fish to sell!", "warning", "🐟")
		return
	end
	
	-- Clear inventory and add money
	DataHandler:Set(player, "FishInventory", {})
	DataHandler:Increment(player, "Money", totalValue)
	DataHandler:SavePlayer(player)
	
	-- Notify
	sendNotification(player, string.format("Sold %d fish for $%d!", totalCount, totalValue), "success", "💰")
	
	-- Fire event to client
	fishSoldEvent:FireClient(player, {
		FishId = "ALL",
		Quantity = totalCount,
		Earned = totalValue,
		NewMoney = DataHandler:Get(player, "Money") or 0
	})
	
	print(string.format("💰 [FISHERMAN SHOP] %s sold ALL fish (%d) for $%d", player.Name, totalCount, totalValue))
end)

-- ==================== SELL SELECTED FISH ====================

sellSelectedFishEvent.OnServerEvent:Connect(function(player, selectedFish)
	if not player or not player.Parent then return end
	if not selectedFish or type(selectedFish) ~= "table" then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	local fishInventory = data.FishInventory or {}
	local totalValue = 0
	local totalCount = 0
	local soldFish = {}
	
	-- selectedFish format: {fishId = quantity}
	for fishId, quantity in pairs(selectedFish) do
		local currentCount = fishInventory[fishId] or 0
		local sellCount = math.min(quantity, currentCount)
		
		if sellCount > 0 then
			local fishData = FishConfig.Fish[fishId]
			if fishData then
				local fishValue = (fishData.Price or 0) * sellCount
				
				-- Remove from inventory
				fishInventory[fishId] = currentCount - sellCount
				if fishInventory[fishId] <= 0 then
					fishInventory[fishId] = nil
				end
				
				totalValue = totalValue + fishValue
				totalCount = totalCount + sellCount
				table.insert(soldFish, {
					FishId = fishId,
					Name = fishData.Name,
					Count = sellCount,
					Value = fishValue
				})
			end
		end
	end
	
	if totalCount <= 0 then
		sendNotification(player, "No valid fish to sell!", "warning", "🐟")
		return
	end
	
	-- Update data
	DataHandler:Set(player, "FishInventory", fishInventory)
	DataHandler:Increment(player, "Money", totalValue)
	DataHandler:SavePlayer(player)
	
	-- Notify
	sendNotification(player, string.format("Sold %d fish for $%d!", totalCount, totalValue), "success", "💰")
	
	-- Fire event to client
	fishSoldEvent:FireClient(player, {
		FishId = "SELECTED",
		Quantity = totalCount,
		Earned = totalValue,
		NewMoney = DataHandler:Get(player, "Money") or 0,
		SoldFish = soldFish
	})
	
	print(string.format("💰 [FISHERMAN SHOP] %s sold SELECTED fish (%d) for $%d", player.Name, totalCount, totalValue))
end)

print("✅ [FISHERMAN SHOP SERVER] System loaded")
