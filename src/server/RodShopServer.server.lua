--[[
    ROD SHOP SERVER
    Place in ServerScriptService
    
    Handles fishing rod and floater purchases & equipment
    Uses DataHandler for centralized data management
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataHandler = require(script.Parent.DataHandler)
local RodShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RodShopConfig"))

-- Create RemoteFolder
local remoteFolder = ReplicatedStorage:FindFirstChild("RodShopRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RodShopRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents & Functions
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

local getShopDataFunc = createRemote("GetShopData", true)
local buyRodEvent = createRemote("BuyRod", false)
local buyFloaterEvent = createRemote("BuyFloater", false)
local equipRodEvent = createRemote("EquipRod", false)
local unequipRodEvent = createRemote("UnequipRod", false) -- NEW: Unequip rod
local equipFloaterEvent = createRemote("EquipFloater", false)
local unequipFloaterEvent = createRemote("UnequipFloater", false)
local getOwnedItemsFunc = createRemote("GetOwnedItems", true)
local shopUpdatedEvent = createRemote("ShopUpdated", false) -- NEW: Notify client when shop data changes
local equipmentChangedEvent = createRemote("EquipmentChanged", false) -- NEW: Notify when equipment changes

-- Reference to FishingRods folder for giving tools
local FishingRodsFolder = ReplicatedStorage:FindFirstChild("FishingRods")

print("✅ [ROD SHOP SERVER] Initialized")

-- ==================== HELPER FUNCTIONS ====================

local function getRodData(rodId)
	return RodShopConfig.GetRodById(rodId)
end

local function getFloaterData(floaterId)
	return RodShopConfig.GetFloaterById(floaterId)
end

local function sendNotification(player, message, notifType, icon)
	-- Gunakan sistem notifikasi yang sudah ada jika tersedia
	local NotificationServer = script.Parent:FindFirstChild("NotificationServer")
	if NotificationServer then
		local NotificationService = require(NotificationServer)
		NotificationService:Send(player, {
			Message = message,
			Type = notifType or "info",
			Duration = 3,
			Icon = icon
		})
	else
		print(string.format("[ROD SHOP] %s: %s", player.Name, message))
	end
end

-- ==================== GET SHOP DATA ====================

getShopDataFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then return nil end
	
	return {
		OwnedRods = data.OwnedRods or {"FishingRod_Wood1"},
		OwnedFloaters = data.OwnedFloaters or {},
		EquippedRod = data.EquippedRod or "FishingRod_Wood1",
		EquippedFloater = data.EquippedFloater,
		Money = data.Money or 0,
		Rods = RodShopConfig.Rods,
		Floaters = RodShopConfig.Floaters
	}
end

-- ==================== GET OWNED ITEMS ====================

getOwnedItemsFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then return nil end
	
	return {
		OwnedRods = data.OwnedRods or {"FishingRod_Wood1"},
		OwnedFloaters = data.OwnedFloaters or {},
		EquippedRod = data.EquippedRod or "FishingRod_Wood1",
		EquippedFloater = data.EquippedFloater
	}
end

-- ==================== BUY ROD ====================

buyRodEvent.OnServerEvent:Connect(function(player, rodId)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	local rodData = getRodData(rodId)
	if not rodData then
		sendNotification(player, "Invalid rod!", "error", "❌")
		return
	end
	
	-- Initialize OwnedRods if nil
	if not data.OwnedRods then
		DataHandler:Set(player, "OwnedRods", {"FishingRod_Wood1"})
		data = DataHandler:GetData(player)
	end
	
	-- Check if already owned
	if DataHandler:ArrayContains(player, "OwnedRods", rodId) then
		sendNotification(player, "You already own this rod!", "warning", "⚠️")
		return
	end
	
	-- Handle Premium (Robux) purchase
	if rodData.IsPremium then
		if not rodData.ProductId or rodData.ProductId == 0 then
			sendNotification(player, "This item is not available yet!", "error", "❌")
			return
		end
		MarketplaceService:PromptProductPurchase(player, rodData.ProductId)
		return
	end
	
	-- Check money
	local currentMoney = data.Money or 0
	if currentMoney < rodData.Price then
		sendNotification(player, string.format("Not enough money! Need $%d", rodData.Price), "error", "💰")
		return
	end
	
	-- Purchase
	DataHandler:Increment(player, "Money", -rodData.Price)
	DataHandler:AddToArray(player, "OwnedRods", rodId)
	DataHandler:SavePlayer(player)
	
	-- Notify client to refresh shop data
	shopUpdatedEvent:FireClient(player, "Rod", rodId)
	
	sendNotification(player, string.format("Purchased %s for $%d!", rodData.DisplayName, rodData.Price), "success", "🎣")
	print(string.format("🎣 [ROD SHOP] %s purchased %s for $%d", player.Name, rodData.DisplayName, rodData.Price))
end)

-- ==================== BUY FLOATER ====================

buyFloaterEvent.OnServerEvent:Connect(function(player, floaterId)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	local floaterData = getFloaterData(floaterId)
	if not floaterData then
		sendNotification(player, "Invalid floater!", "error", "❌")
		return
	end
	
	-- Initialize OwnedFloaters if nil
	if not data.OwnedFloaters then
		DataHandler:Set(player, "OwnedFloaters", {})
		data = DataHandler:GetData(player)
	end
	
	-- Check if already owned
	if DataHandler:ArrayContains(player, "OwnedFloaters", floaterId) then
		sendNotification(player, "You already own this floater!", "warning", "⚠️")
		return
	end
	
	-- Handle Premium (Robux) purchase
	if floaterData.IsPremium then
		if not floaterData.ProductId or floaterData.ProductId == 0 then
			sendNotification(player, "This item is not available yet!", "error", "❌")
			return
		end
		MarketplaceService:PromptProductPurchase(player, floaterData.ProductId)
		return
	end
	
	-- Check money
	local currentMoney = data.Money or 0
	if currentMoney < floaterData.Price then
		sendNotification(player, string.format("Not enough money! Need $%d", floaterData.Price), "error", "💰")
		return
	end
	
	-- Purchase
	DataHandler:Increment(player, "Money", -floaterData.Price)
	DataHandler:AddToArray(player, "OwnedFloaters", floaterId)
	DataHandler:SavePlayer(player)
	
	-- Notify client to refresh shop data
	shopUpdatedEvent:FireClient(player, "Floater", floaterId)
	
	sendNotification(player, string.format("Purchased %s for $%d!", floaterData.DisplayName, floaterData.Price), "success", "🎈")
	print(string.format("🎈 [ROD SHOP] %s purchased %s for $%d", player.Name, floaterData.DisplayName, floaterData.Price))
end)

-- ==================== EQUIP ROD ====================

-- Helper function to give rod tool to player
local function giveRodTool(player, rodId)
	if not FishingRodsFolder then
		warn("[ROD SHOP] FishingRodsFolder not found!")
		return
	end
	
	-- Get the Rods subfolder
	local RodsFolder = FishingRodsFolder:FindFirstChild("Rods")
	if not RodsFolder then
		warn("[ROD SHOP] Rods subfolder not found in FishingRodsFolder!")
		return
	end
	
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	
	if not backpack then return end
	
	-- Remove any existing fishing rod tools from backpack and character
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			-- Check if it's a fishing rod by name pattern or Edge part
			local handle = tool:FindFirstChild("Handle")
			local isRod = tool.Name:find("FishingRod") or tool.Name:find("Rod") 
				or (handle and handle:FindFirstChild("Edge"))
			if isRod then
				tool:Destroy()
			end
		end
	end
	
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				local handle = tool:FindFirstChild("Handle")
				local isRod = tool.Name:find("FishingRod") or tool.Name:find("Rod") 
					or (handle and handle:FindFirstChild("Edge"))
				if isRod then
					tool:Destroy()
				end
			end
		end
	end
	
	-- Find rod template in Rods subfolder
	local rodTemplate = RodsFolder:FindFirstChild(rodId)
	if not rodTemplate then
		-- Try to find by matching name pattern
		for _, child in ipairs(RodsFolder:GetChildren()) do
			if child:IsA("Tool") and (child.Name == rodId or child.Name:find(rodId)) then
				rodTemplate = child
				break
			end
		end
	end
	
	if rodTemplate and rodTemplate:IsA("Tool") then
		local newRod = rodTemplate:Clone()
		newRod.Parent = backpack
		
		-- Auto equip the rod
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:EquipTool(newRod)
		end
		
		print("✅ [ROD SHOP] Gave rod tool to player:", rodId)
	else
		warn("[ROD SHOP] Rod template not found in RodsFolder:", rodId)
		-- List available rods for debugging
		print("[ROD SHOP] Available rods in folder:")
		for _, child in ipairs(RodsFolder:GetChildren()) do
			print("  -", child.Name)
		end
	end
end

equipRodEvent.OnServerEvent:Connect(function(player, rodId)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	-- Check if owned
	if not DataHandler:ArrayContains(player, "OwnedRods", rodId) then
		sendNotification(player, "You don't own this rod!", "error", "❌")
		return
	end
	
	local rodData = getRodData(rodId)
	if not rodData then
		sendNotification(player, "Invalid rod!", "error", "❌")
		return
	end
	
	-- Equip in data
	DataHandler:Set(player, "EquippedRod", rodId)
	DataHandler:SavePlayer(player)
	
	-- Give rod tool to player
	giveRodTool(player, rodId)
	
	-- Notify client that equipment changed
	equipmentChangedEvent:FireClient(player, {
		Type = "Rod",
		RodId = rodId,
		EquippedRod = rodId,
		EquippedFloater = data.EquippedFloater
	})
	
	sendNotification(player, string.format("Equipped %s!", rodData.DisplayName), "success", "🎣")
	print(string.format("🎣 [ROD SHOP] %s equipped %s", player.Name, rodData.DisplayName))
end)

-- ==================== UNEQUIP ROD ====================

unequipRodEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	-- Set equipped rod to empty/nil
	DataHandler:Set(player, "EquippedRod", "")
	DataHandler:SavePlayer(player)
	
	-- Remove rod tools from player
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:find("FishingRod") or tool.Name:find("Rod")) then
				tool:Destroy()
			end
		end
	end
	
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
		
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:find("FishingRod") or tool.Name:find("Rod")) then
				tool:Destroy()
			end
		end
	end
	
	-- Notify client that equipment changed
	equipmentChangedEvent:FireClient(player, {
		Type = "Rod",
		RodId = nil,
		EquippedRod = "",
		EquippedFloater = data.EquippedFloater
	})
	
	sendNotification(player, "Rod unequipped!", "info", "🎣")
	print(string.format("🎣 [ROD SHOP] %s unequipped rod", player.Name))
end)

equipFloaterEvent.OnServerEvent:Connect(function(player, floaterId)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	-- Check if owned
	if not DataHandler:ArrayContains(player, "OwnedFloaters", floaterId) then
		sendNotification(player, "You don't own this floater!", "error", "❌")
		return
	end
	
	local floaterData = getFloaterData(floaterId)
	if not floaterData then
		sendNotification(player, "Invalid floater!", "error", "❌")
		return
	end
	
	-- Equip
	DataHandler:Set(player, "EquippedFloater", floaterId)
	DataHandler:SavePlayer(player)
	
	-- Notify client that equipment changed
	equipmentChangedEvent:FireClient(player, {
		Type = "Floater",
		FloaterId = floaterId,
		EquippedRod = data.EquippedRod,
		EquippedFloater = floaterId
	})
	
	sendNotification(player, string.format("Equipped %s!", floaterData.DisplayName), "success", "🎈")
	print(string.format("🎈 [ROD SHOP] %s equipped %s", player.Name, floaterData.DisplayName))
end)

-- ==================== UNEQUIP FLOATER ====================

unequipFloaterEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	
	local data = DataHandler:GetData(player)
	if not data then
		sendNotification(player, "Data not loaded!", "error", "❌")
		return
	end
	
	-- Unequip
	DataHandler:Set(player, "EquippedFloater", nil)
	DataHandler:SavePlayer(player)
	
	-- Notify client that equipment changed
	equipmentChangedEvent:FireClient(player, {
		Type = "Floater",
		FloaterId = nil,
		EquippedRod = data.EquippedRod,
		EquippedFloater = nil
	})
	
	sendNotification(player, "Floater unequipped!", "info", "🎈")
	print(string.format("🎈 [ROD SHOP] %s unequipped floater", player.Name))
end)

print("✅ [ROD SHOP SERVER] System loaded")
