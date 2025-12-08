--[[
    ROD SHOP CLIENT
    Place in StarterPlayerScripts
    
    UI for purchasing fishing rods and floaters
    Uses existing UI from StarterGui/RodShopGUI
    Uses centralized data from DataHandler
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- No longer using TopbarPlus, using ProximityPrompt instead
local RodShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RodShopConfig"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))

-- Wait for remotes
local remoteFolder = ReplicatedStorage:WaitForChild("RodShopRemotes", 10)
if not remoteFolder then
	warn("[ROD SHOP CLIENT] RodShopRemotes not found!")
	return
end

local getShopDataFunc = remoteFolder:WaitForChild("GetShopData", 5)
local buyRodEvent = remoteFolder:WaitForChild("BuyRod", 5)
local buyFloaterEvent = remoteFolder:WaitForChild("BuyFloater", 5)
local equipRodEvent = remoteFolder:WaitForChild("EquipRod", 5)
local equipFloaterEvent = remoteFolder:WaitForChild("EquipFloater", 5)
local unequipFloaterEvent = remoteFolder:WaitForChild("UnequipFloater", 5)
local getOwnedItemsFunc = remoteFolder:WaitForChild("GetOwnedItems", 5)
local shopUpdatedEvent = remoteFolder:WaitForChild("ShopUpdated", 5)
local equipmentChangedEvent = remoteFolder:WaitForChild("EquipmentChanged", 5)

-- State
local currentTab = "Rods"
local shopData = nil

-- Colors for dynamic elements
local COLORS = {
	Success = Color3.fromRGB(80, 200, 120),
	Danger = Color3.fromRGB(255, 80, 80),
	Accent = Color3.fromRGB(70, 130, 255),
	Premium = Color3.fromRGB(255, 215, 0),
	Equipped = Color3.fromRGB(100, 200, 150),
	Owned = Color3.fromRGB(70, 130, 255),
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

print("✅ [ROD SHOP CLIENT] Starting initialization...")

-- ==================== HELPER FUNCTIONS ====================

local function formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. amount
	end
end

local function getRarityColor(rarity)
	return COLORS[rarity] or COLORS.Common
end

-- ==================== GET EXISTING GUI ====================

task.wait(3) -- Wait for UI to load from StarterGui

local screenGui = playerGui:WaitForChild("RodShopGUI", 10)
if not screenGui then
	warn("[ROD SHOP CLIENT] RodShopGUI not found in PlayerGui!")
	return
end

-- Main Panel
local mainPanel = screenGui:WaitForChild("MainPanel")

-- Header elements (optional - may not exist in new hierarchy)
local headerFrame = mainPanel:FindFirstChild("HeaderFrame")
local moneyAmountLabel = nil
local closeButton = nil

if headerFrame then
	local moneyDisplayFrame = headerFrame:FindFirstChild("MoneyDisplayFrame")
	if moneyDisplayFrame then
		moneyAmountLabel = moneyDisplayFrame:FindFirstChild("MoneyAmountLabel")
	end
	closeButton = headerFrame:FindFirstChild("CloseButton")
end

-- Tab buttons (optional)
local tabContainerFrame = mainPanel:FindFirstChild("TabContainerFrame")
local rodsTabButton = nil
local floatersTabButton = nil

if tabContainerFrame then
	rodsTabButton = tabContainerFrame:FindFirstChild("RodsTabButton")
	floatersTabButton = tabContainerFrame:FindFirstChild("FloatersTabButton")
end

-- Content Container
local contentContainerFrame = mainPanel:WaitForChild("ContentContainerFrame")

-- Rods Content Panel
local rodsContentPanel = contentContainerFrame:WaitForChild("RodsContentPanel")
local rodsScrollFrame = rodsContentPanel:WaitForChild("RodsScrollFrame")
local rodCardTemplate = rodsScrollFrame:WaitForChild("RodCardTemplate")
local rodsEmptyLabel = rodsScrollFrame:FindFirstChild("RodsEmptyLabel")

-- Floaters Content Panel
local floatersContentPanel = contentContainerFrame:WaitForChild("FloatersContentPanel")
local floatersScrollFrame = floatersContentPanel:WaitForChild("FloatersScrollFrame")
local floaterCardTemplate = floatersScrollFrame:WaitForChild("FloaterCardTemplate")
local floatersEmptyLabel = floatersScrollFrame:FindFirstChild("RodsEmptyLabel") or floatersScrollFrame:FindFirstChild("FloatersEmptyLabel")

-- Hide templates
rodCardTemplate.Visible = false
floaterCardTemplate.Visible = false

-- Store templates in a safe place
rodCardTemplate.Parent = playerGui
floaterCardTemplate.Parent = playerGui

print("✅ [ROD SHOP CLIENT] Found all UI elements")

-- ==================== CLOSE BUTTON HANDLER ====================

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		mainPanel.Visible = false
	end)
end

-- ==================== TAB SWITCHING ====================

local function switchToTab(tabName)
	currentTab = tabName
	
	-- Update tab button colors (if they exist)
	if rodsTabButton and floatersTabButton then
		if tabName == "Rods" then
			rodsTabButton.BackgroundColor3 = COLORS.Accent
			floatersTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		else
			rodsTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
			floatersTabButton.BackgroundColor3 = COLORS.Accent
		end
	end
	
	-- Update visibility
	rodsContentPanel.Visible = (tabName == "Rods")
	floatersContentPanel.Visible = (tabName == "Floaters")
	
	updateShopDisplay()
end

if rodsTabButton then
	rodsTabButton.MouseButton1Click:Connect(function()
		switchToTab("Rods")
	end)
end

if floatersTabButton then
	floatersTabButton.MouseButton1Click:Connect(function()
		switchToTab("Floaters")
	end)
end

-- Initialize visibility
rodsContentPanel.Visible = true
floatersContentPanel.Visible = false

-- ==================== ITEM CREATION (USING TEMPLATES) ====================

local function createRodItem(rodData, isOwned, isEquipped)
	local rodCard = rodCardTemplate:Clone()
	rodCard.Name = "RodCard_" .. rodData.RodId
	rodCard.Visible = true
	rodCard.Parent = rodsScrollFrame
	
	local rarityColor = getRarityColor(rodData.Rarity)
	
	-- Update UIStroke color for rarity
	local uiStroke = rodCard:FindFirstChild("UIStroke")
	if uiStroke then
		uiStroke.Color = rarityColor
	end
	
	-- Update Thumbnail
	local thumbnailImage = rodCard:FindFirstChild("ThumbnailImage")
	if thumbnailImage then
		thumbnailImage.Image = rodData.Thumbnail or ""
	end
	
	-- Update Rarity Label
	local rarityLabel = rodCard:FindFirstChild("RarityLabel")
	if rarityLabel then
		rarityLabel.Text = rodData.Rarity:upper()
		rarityLabel.TextColor3 = rarityColor
	end
	
	-- Update Item Name
	local itemNameLabel = rodCard:FindFirstChild("ItemNameLabel")
	if itemNameLabel then
		itemNameLabel.Text = rodData.DisplayName
	end
	
	-- Update Bonus Info
	local bonusInfoLabel = rodCard:FindFirstChild("BonusInfoLabel")
	if bonusInfoLabel then
		bonusInfoLabel.Text = string.format("+%d%% Catch Bonus", rodData.CatchBonus or 0)
		bonusInfoLabel.TextColor3 = COLORS.Success
	end
	
	-- Update Price
	local priceLabel = rodCard:FindFirstChild("PriceLabel")
	if priceLabel then
		priceLabel.Text = rodData.IsPremium and ("R$ " .. rodData.Price) or formatMoney(rodData.Price)
		priceLabel.TextColor3 = rodData.IsPremium and COLORS.Premium or COLORS.Success
	end
	
	-- Update Action Button
	local actionButton = rodCard:FindFirstChild("ActionButton")
	if actionButton then
		-- Get or create text label inside button
		local buttonTextLabel = actionButton:FindFirstChild("TextLabel") or actionButton
		
		if isEquipped then
			actionButton.BackgroundColor3 = COLORS.Equipped
			if buttonTextLabel:IsA("TextLabel") then
				buttonTextLabel.Text = "Equipped"
			elseif actionButton:IsA("TextButton") then
				actionButton.Text = "Equipped"
			end
		elseif isOwned then
			actionButton.BackgroundColor3 = COLORS.Accent
			if buttonTextLabel:IsA("TextLabel") then
				buttonTextLabel.Text = "Equip"
			elseif actionButton:IsA("TextButton") then
				actionButton.Text = "Equip"
			end
			
			actionButton.MouseButton1Click:Connect(function()
				equipRodEvent:FireServer(rodData.RodId)
				task.wait(0.5)
				fetchShopData()
			end)
		else
			actionButton.BackgroundColor3 = COLORS.Success
			if buttonTextLabel:IsA("TextLabel") then
				buttonTextLabel.Text = "Buy"
			elseif actionButton:IsA("TextButton") then
				actionButton.Text = "Buy"
			end
			
			actionButton.MouseButton1Click:Connect(function()
				buyRodEvent:FireServer(rodData.RodId)
				task.wait(0.5)
				fetchShopData()
			end)
		end
	end
	
	-- Handle badge display on thumbnail
	if thumbnailImage then
		-- Remove any existing badge
		local existingBadge = thumbnailImage:FindFirstChild("StatusBadge")
		if existingBadge then existingBadge:Destroy() end
		
		if isEquipped or isOwned or rodData.IsPremium then
			local badge = Instance.new("Frame")
			badge.Name = "StatusBadge"
			badge.Size = UDim2.new(0.5, 0, 0.2, 0)
			badge.Position = UDim2.new(0.25, 0, 0.05, 0)
			badge.BorderSizePixel = 0
			badge.Parent = thumbnailImage
			
			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 4)
			badgeCorner.Parent = badge
			
			local badgeLabel = Instance.new("TextLabel")
			badgeLabel.Name = "BadgeLabel"
			badgeLabel.Size = UDim2.new(1, 0, 1, 0)
			badgeLabel.BackgroundTransparency = 1
			badgeLabel.Font = Enum.Font.GothamBold
			badgeLabel.TextSize = 10
			badgeLabel.Parent = badge
			
			if isEquipped then
				badge.BackgroundColor3 = COLORS.Equipped
				badgeLabel.Text = "EQUIPPED"
				badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			elseif isOwned then
				badge.BackgroundColor3 = COLORS.Owned
				badgeLabel.Text = "OWNED"
				badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			elseif rodData.IsPremium then
				badge.BackgroundColor3 = COLORS.Premium
				badgeLabel.Text = "PREMIUM"
				badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			end
		end
	end
	
	return rodCard
end

local function createFloaterItem(floaterData, isOwned, isEquipped)
	local floaterCard = floaterCardTemplate:Clone()
	floaterCard.Name = "FloaterCard_" .. floaterData.FloaterId
	floaterCard.Visible = true
	floaterCard.Parent = floatersScrollFrame
	
	local rarityColor = getRarityColor(floaterData.Rarity)
	
	-- Update UIStroke color for rarity
	local uiStroke = floaterCard:FindFirstChild("UIStroke")
	if uiStroke then
		uiStroke.Color = rarityColor
	end
	
	-- Update Thumbnail
	local thumbnailImage = floaterCard:FindFirstChild("ThumbnailImage")
	if thumbnailImage then
		thumbnailImage.Image = floaterData.Thumbnail or ""
	end
	
	-- Update Rarity Label
	local rarityLabel = floaterCard:FindFirstChild("RarityLabel")
	if rarityLabel then
		rarityLabel.Text = floaterData.Rarity:upper()
		rarityLabel.TextColor3 = rarityColor
	end
	
	-- Update Item Name
	local itemNameLabel = floaterCard:FindFirstChild("ItemNameLabel")
	if itemNameLabel then
		itemNameLabel.Text = floaterData.DisplayName
	end
	
	-- Update Bonus Info
	local bonusInfoLabel = floaterCard:FindFirstChild("BonusInfoLabel")
	if bonusInfoLabel then
		bonusInfoLabel.Text = string.format("+%d%% Luck Bonus", floaterData.LuckBonus or 0)
		bonusInfoLabel.TextColor3 = COLORS.Accent
	end
	
	-- Update Price
	local priceLabel = floaterCard:FindFirstChild("PriceLabel")
	if priceLabel then
		priceLabel.Text = floaterData.IsPremium and ("R$ " .. floaterData.Price) or formatMoney(floaterData.Price)
		priceLabel.TextColor3 = floaterData.IsPremium and COLORS.Premium or COLORS.Success
	end
	
	-- Update Action Button
	local actionButton = floaterCard:FindFirstChild("ActionButton")
	if actionButton then
		local buttonTextLabel = actionButton:FindFirstChild("TextLabel") or actionButton
		
		if isEquipped then
			actionButton.BackgroundColor3 = COLORS.Danger
			if buttonTextLabel:IsA("TextLabel") then
				buttonTextLabel.Text = "Unequip"
			elseif actionButton:IsA("TextButton") then
				actionButton.Text = "Unequip"
			end
			
			actionButton.MouseButton1Click:Connect(function()
				unequipFloaterEvent:FireServer()
				task.wait(0.5)
				fetchShopData()
			end)
		elseif isOwned then
			actionButton.BackgroundColor3 = COLORS.Accent
			if buttonTextLabel:IsA("TextLabel") then
				buttonTextLabel.Text = "Equip"
			elseif actionButton:IsA("TextButton") then
				actionButton.Text = "Equip"
			end
			
			actionButton.MouseButton1Click:Connect(function()
				equipFloaterEvent:FireServer(floaterData.FloaterId)
				task.wait(0.5)
				fetchShopData()
			end)
		else
			actionButton.BackgroundColor3 = COLORS.Success
			if buttonTextLabel:IsA("TextLabel") then
				buttonTextLabel.Text = "Buy"
			elseif actionButton:IsA("TextButton") then
				actionButton.Text = "Buy"
			end
			
			actionButton.MouseButton1Click:Connect(function()
				buyFloaterEvent:FireServer(floaterData.FloaterId)
				task.wait(0.5)
				fetchShopData()
			end)
		end
	end
	
	-- Handle badge display on thumbnail
	if thumbnailImage then
		local existingBadge = thumbnailImage:FindFirstChild("StatusBadge")
		if existingBadge then existingBadge:Destroy() end
		
		if isEquipped or isOwned or floaterData.IsPremium then
			local badge = Instance.new("Frame")
			badge.Name = "StatusBadge"
			badge.Size = UDim2.new(0.5, 0, 0.2, 0)
			badge.Position = UDim2.new(0.25, 0, 0.05, 0)
			badge.BorderSizePixel = 0
			badge.Parent = thumbnailImage
			
			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 4)
			badgeCorner.Parent = badge
			
			local badgeLabel = Instance.new("TextLabel")
			badgeLabel.Name = "BadgeLabel"
			badgeLabel.Size = UDim2.new(1, 0, 1, 0)
			badgeLabel.BackgroundTransparency = 1
			badgeLabel.Font = Enum.Font.GothamBold
			badgeLabel.TextSize = 10
			badgeLabel.Parent = badge
			
			if isEquipped then
				badge.BackgroundColor3 = COLORS.Equipped
				badgeLabel.Text = "EQUIPPED"
				badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			elseif isOwned then
				badge.BackgroundColor3 = COLORS.Owned
				badgeLabel.Text = "OWNED"
				badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			elseif floaterData.IsPremium then
				badge.BackgroundColor3 = COLORS.Premium
				badgeLabel.Text = "PREMIUM"
				badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			end
		end
	end
	
	return floaterCard
end

-- ==================== UPDATE FUNCTIONS ====================

function updateShopDisplay()
	if not shopData then return end
	
	-- Update money display (if it exists)
	if moneyAmountLabel then
		moneyAmountLabel.Text = formatMoney(shopData.Money or 0)
	end
	
	-- Clear existing rod items (except template and layout)
	for _, child in ipairs(rodsScrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("RodCard_") then
			child:Destroy()
		end
	end
	
	-- Clear existing floater items (except template and layout)
	for _, child in ipairs(floatersScrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("FloaterCard_") then
			child:Destroy()
		end
	end
	
	if currentTab == "Rods" then
		-- Hide empty label if we have items
		if rodsEmptyLabel then
			rodsEmptyLabel.Visible = (#RodShopConfig.Rods == 0)
		end
		
		-- Display rods
		for _, rodData in ipairs(RodShopConfig.Rods) do
			local isOwned = table.find(shopData.OwnedRods or {}, rodData.RodId) ~= nil
			local isEquipped = shopData.EquippedRod == rodData.RodId
			createRodItem(rodData, isOwned, isEquipped)
		end
	else
		-- Hide empty label if we have items
		if floatersEmptyLabel then
			floatersEmptyLabel.Visible = (#RodShopConfig.Floaters == 0)
		end
		
		-- Display floaters
		for _, floaterData in ipairs(RodShopConfig.Floaters) do
			local isOwned = table.find(shopData.OwnedFloaters or {}, floaterData.FloaterId) ~= nil
			local isEquipped = shopData.EquippedFloater == floaterData.FloaterId
			createFloaterItem(floaterData, isOwned, isEquipped)
		end
	end
end

function fetchShopData()
	if not getShopDataFunc then return end
	
	local success, data = pcall(function()
		return getShopDataFunc:InvokeServer()
	end)
	
	if success and data then
		shopData = data
		updateShopDisplay()
	end
end

-- ==================== SHOP STATE ====================

local isShopOpen = false

local function openShop()
	if isShopOpen then return end
	isShopOpen = true
	mainPanel.Visible = true
	fetchShopData()
	print("🛒 [ROD SHOP] Shop opened")
end

local function closeShop()
	if not isShopOpen then return end
	isShopOpen = false
	mainPanel.Visible = false
	print("🛒 [ROD SHOP] Shop closed")
end

-- ==================== CLOSE BUTTON ====================

-- Find close button if exists
local closeButton = mainPanel:FindFirstChild("CloseButton") or mainPanel:FindFirstChild("CloseBtn")
if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		closeShop()
	end)
end

-- ==================== PROXIMITY PROMPT SETUP ====================

local function setupProximityPrompt()
	local equipmentShop = workspace:FindFirstChild("EquipmentShop")
	
	if not equipmentShop then
		warn("[ROD SHOP CLIENT] EquipmentShop part not found in Workspace!")
		-- Try again later
		task.delay(5, setupProximityPrompt)
		return
	end
	
	-- Find or create proximity prompt
	local prompt = equipmentShop:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Equipment Shop"
		prompt.ActionText = "Browse Rods & Floaters"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = equipmentShop
	end
	
	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			if isShopOpen then
				closeShop()
			else
				openShop()
			end
		end
	end)
	
	print("✅ [ROD SHOP CLIENT] Proximity prompt setup complete!")
end

-- ==================== INITIAL STATE ====================

-- Hide main panel initially
mainPanel.Visible = false

-- Initial fetch
task.spawn(function()
	task.wait(1)
	fetchShopData()
end)

-- ==================== AUTO-REFRESH ON SERVER EVENTS ====================

-- When player buys something, auto-refresh shop
if shopUpdatedEvent then
	shopUpdatedEvent.OnClientEvent:Connect(function(itemType, itemId)
		print("🔄 [ROD SHOP CLIENT] Shop updated! Type:", itemType, "ID:", itemId)
		-- ✅ Play transaction sound
		SoundConfig.PlayLocalSound("Transaction")
		fetchShopData()
	end)
end

-- When player equips something, auto-refresh shop
if equipmentChangedEvent then
	equipmentChangedEvent.OnClientEvent:Connect(function(data)
		print("🔄 [ROD SHOP CLIENT] Equipment changed!", data.Type)
		fetchShopData()
	end)
end

-- ==================== INITIALIZE PROXIMITY PROMPT ====================

task.spawn(setupProximityPrompt)

print("✅ [ROD SHOP CLIENT] Loaded - Go to EquipmentShop to browse rods & floaters!")
