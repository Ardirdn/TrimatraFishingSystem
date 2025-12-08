--[[
    EQUIPMENT SYSTEM CLIENT
    Place in StarterPlayerScripts
    
    Handles Equipment UI for Rods & Floaters only
    Floating circular button on left side of screen
    
    Style matched with Fish Collection UI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RodShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RodShopConfig"))

-- RemoteEvents
local rodShopRemotes = ReplicatedStorage:WaitForChild("RodShopRemotes", 10)
if not rodShopRemotes then
	warn("[EQUIPMENT CLIENT] RodShopRemotes not found!")
	return
end

local getOwnedItemsFunc = rodShopRemotes:WaitForChild("GetOwnedItems", 5)
local equipRodEvent = rodShopRemotes:WaitForChild("EquipRod", 5)
local unequipRodEvent = rodShopRemotes:WaitForChild("UnequipRod", 5) -- NEW
local equipFloaterEvent = rodShopRemotes:WaitForChild("EquipFloater", 5)
local unequipFloaterEvent = rodShopRemotes:WaitForChild("UnequipFloater", 5)
local equipmentChangedEvent = rodShopRemotes:FindFirstChild("EquipmentChanged")
local shopUpdatedEvent = rodShopRemotes:FindFirstChild("ShopUpdated")

-- State
local isOpen = false
local currentTab = "Rods"
local equipmentData = {
	OwnedRods = {"FishingRod_Wood1"},
	OwnedFloaters = {"Floater_Doll"},
	EquippedRod = "FishingRod_Wood1",
	EquippedFloater = "Floater_Doll"
}

-- Colors (SAME AS FISH COLLECTION)
local COLORS = {
	Background = Color3.fromRGB(15, 25, 40),
	CardBg = Color3.fromRGB(25, 40, 60),
	CardBgDark = Color3.fromRGB(15, 25, 35),
	Accent = Color3.fromRGB(50, 150, 220),
	Success = Color3.fromRGB(80, 200, 120),
	Danger = Color3.fromRGB(255, 80, 80),
	Warning = Color3.fromRGB(255, 200, 50),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(150, 170, 190),
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 50, 100)
}

print("✅ [EQUIPMENT CLIENT] Starting initialization...")

-- ==================== HELPER FUNCTIONS ====================

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function getRarityColor(rarity)
	return COLORS[rarity] or COLORS.Common
end

-- ==================== CREATE UI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EquipmentGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ==================== MOBILE RESPONSIVE DETECTION ====================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local screenSize = workspace.CurrentCamera.ViewportSize
local isSmallScreen = screenSize.X < 800 or screenSize.Y < 600

-- Responsive button size
local buttonBaseSize = isMobile and 55 or 70
local buttonHoverSize = isMobile and 62 or 80

-- ==================== FLOATING BUTTON (RESPONSIVE) ====================

local floatingButton = Instance.new("TextButton")
floatingButton.Name = "EquipmentButton"
floatingButton.Size = UDim2.new(0, buttonBaseSize, 0, buttonBaseSize)
floatingButton.Position = UDim2.new(0, 10, 0.4, 0)
floatingButton.BackgroundColor3 = COLORS.Accent
floatingButton.BorderSizePixel = 0
floatingButton.Text = ""
floatingButton.AutoButtonColor = false
floatingButton.Parent = screenGui

createCorner(buttonBaseSize/2).Parent = floatingButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(80, 180, 240)
buttonStroke.Thickness = isMobile and 2 or 3
buttonStroke.Parent = floatingButton

local buttonIcon = Instance.new("TextLabel")
buttonIcon.Size = UDim2.new(1, 0, 0.6, 0)
buttonIcon.Position = UDim2.new(0, 0, 0.05, 0)
buttonIcon.BackgroundTransparency = 1
buttonIcon.Font = Enum.Font.GothamBlack
buttonIcon.Text = "🎣"
buttonIcon.TextColor3 = COLORS.Text
buttonIcon.TextSize = isMobile and 22 or 28
buttonIcon.TextScaled = isMobile
buttonIcon.Parent = floatingButton

local buttonText = Instance.new("TextLabel")
buttonText.Size = UDim2.new(1, 0, 0.3, 0)
buttonText.Position = UDim2.new(0, 0, 0.65, 0)
buttonText.BackgroundTransparency = 1
buttonText.Font = Enum.Font.GothamBold
buttonText.Text = "Equip"
buttonText.TextColor3 = COLORS.Text
buttonText.TextSize = isMobile and 8 or 10
buttonText.TextScaled = isMobile
buttonText.Parent = floatingButton

-- Hover effect (desktop only)
if not isMobile then
	floatingButton.MouseEnter:Connect(function()
		TweenService:Create(floatingButton, TweenInfo.new(0.2), {Size = UDim2.new(0, buttonHoverSize, 0, buttonHoverSize)}):Play()
	end)

	floatingButton.MouseLeave:Connect(function()
		TweenService:Create(floatingButton, TweenInfo.new(0.2), {Size = UDim2.new(0, buttonBaseSize, 0, buttonBaseSize)}):Play()
	end)
end

-- ==================== MAIN PANEL (SAME SIZE & STYLE AS FISH) ====================

-- Responsive panel size
local panelWidth = isMobile and 0.95 or 0 -- Scale for mobile, fixed for desktop
local panelWidthOffset = isMobile and 0 or 550
local panelHeight = isMobile and 0.85 or 0
local panelHeightOffset = isMobile and 0 or 600

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(panelWidth, panelWidthOffset, panelHeight, panelHeightOffset)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

-- Size constraint for mobile
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(320, 400)
sizeConstraint.MaxSize = Vector2.new(600, 700)
sizeConstraint.Parent = mainPanel

createCorner(16).Parent = mainPanel

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Accent
mainStroke.Thickness = 2
mainStroke.Parent = mainPanel

-- Header (SAME STYLE AS FISH)
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 55)
headerFrame.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainPanel

createCorner(16).Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "🎣 EQUIPMENT"
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextSize = 24
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(0, 0.5)
closeButton.BackgroundColor3 = COLORS.Danger
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Text
closeButton.TextSize = 18
closeButton.Parent = headerFrame

createCorner(8).Parent = closeButton

-- Tab Buttons (SAME STYLE AS FISH)
local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(1, -30, 0, 40)
tabFrame.Position = UDim2.new(0, 15, 0, 65)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabFrame

local rodsTabBtn = Instance.new("TextButton")
rodsTabBtn.Name = "RodsTab"
rodsTabBtn.Size = UDim2.new(0.5, -5, 1, 0)
rodsTabBtn.BackgroundColor3 = COLORS.Accent
rodsTabBtn.BorderSizePixel = 0
rodsTabBtn.Font = Enum.Font.GothamBold
rodsTabBtn.Text = "🎣 RODS"
rodsTabBtn.TextColor3 = COLORS.Text
rodsTabBtn.TextSize = 14
rodsTabBtn.Parent = tabFrame

createCorner(8).Parent = rodsTabBtn

local floatersTabBtn = Instance.new("TextButton")
floatersTabBtn.Name = "FloatersTab"
floatersTabBtn.Size = UDim2.new(0.5, -5, 1, 0)
floatersTabBtn.BackgroundColor3 = COLORS.CardBg
floatersTabBtn.BorderSizePixel = 0
floatersTabBtn.Font = Enum.Font.GothamBold
floatersTabBtn.Text = "🎈 FLOATERS"
floatersTabBtn.TextColor3 = COLORS.SubText
floatersTabBtn.TextSize = 14
floatersTabBtn.Parent = tabFrame

createCorner(8).Parent = floatersTabBtn

-- Content Frame (SAME STYLE AS FISH - 4 columns)
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -30, 1, -180)
contentFrame.Position = UDim2.new(0, 15, 0, 120)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = COLORS.Accent
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainPanel

-- SAME GRID AS FISH COLLECTION
local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(0.25, -8, 0, 130)
contentGrid.CellPadding = UDim2.new(0, 8, 0, 8)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 5)
contentPadding.PaddingBottom = UDim.new(0, 10)
contentPadding.Parent = contentFrame

-- Bottom Stats Bar (SAME STYLE AS FISH)
local statsBar = Instance.new("Frame")
statsBar.Name = "StatsBar"
statsBar.Size = UDim2.new(1, -30, 0, 45)
statsBar.Position = UDim2.new(0, 15, 1, -55)
statsBar.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
statsBar.BorderSizePixel = 0
statsBar.Parent = mainPanel

createCorner(10).Parent = statsBar

local equippedLabel = Instance.new("TextLabel")
equippedLabel.Name = "EquippedInfo"
equippedLabel.Size = UDim2.new(1, -30, 1, 0)
equippedLabel.Position = UDim2.new(0, 15, 0, 0)
equippedLabel.BackgroundTransparency = 1
equippedLabel.Font = Enum.Font.GothamBold
equippedLabel.Text = "🎣 Equipped: Loading..."
equippedLabel.TextColor3 = COLORS.Success
equippedLabel.TextSize = 16
equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedLabel.Parent = statsBar

-- ==================== ITEM CARD CREATION (SAME STYLE AS FISH CARDS) ====================

local function createRodCard(rodId, isEquipped)
	local rodConfig = RodShopConfig.GetRodById(rodId)
	if not rodConfig then return nil end
	
	local card = Instance.new("Frame")
	card.Name = "RodCard_" .. rodId
	card.BackgroundColor3 = COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isEquipped and COLORS.Success or getRarityColor(rodConfig.Rarity)
	cardStroke.Thickness = isEquipped and 3 or 2
	cardStroke.Parent = card
	
	-- Image Container (SAME AS FISH)
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(1, -10, 0, 60)
	imageContainer.Position = UDim2.new(0, 5, 0, 5)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	-- Thumbnail
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(0.8, 0, 0.8, 0)
	thumbnail.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbnail.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbnail.BackgroundTransparency = 1
	thumbnail.Image = rodConfig.Thumbnail or ""
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = imageContainer
	
	-- Equipped badge
	if isEquipped then
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 50, 0, 18)
		badge.Position = UDim2.new(1, -5, 0, 5)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = COLORS.Success
		badge.Font = Enum.Font.GothamBold
		badge.Text = "✓"
		badge.TextColor3 = COLORS.Text
		badge.TextSize = 12
		badge.Parent = imageContainer
		createCorner(4).Parent = badge
	end
	
	-- Name (SAME STYLE AS FISH)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 16)
	nameLabel.Position = UDim2.new(0, 3, 0, 68)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = rodConfig.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 10
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	-- Rarity (SAME STYLE AS FISH)
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -6, 0, 14)
	rarityLabel.Position = UDim2.new(0, 3, 0, 84)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = rodConfig.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(rodConfig.Rarity)
	rarityLabel.TextSize = 9
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	-- Action Button (Equip/Unequip) - SAME AS FLOATER
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(1, -10, 0, 22)
	actionBtn.Position = UDim2.new(0, 5, 1, -26)
	actionBtn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Text = isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = COLORS.Text
	actionBtn.TextSize = 10
	actionBtn.Parent = card
	
	createCorner(5).Parent = actionBtn
	
	actionBtn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipRodEvent:FireServer()
		else
			equipRodEvent:FireServer(rodId)
		end
	end)
	
	card.Parent = contentFrame
	return card
end

local function createFloaterCard(floaterId, isEquipped)
	local floaterConfig = RodShopConfig.GetFloaterById(floaterId)
	if not floaterConfig then return nil end
	
	local card = Instance.new("Frame")
	card.Name = "FloaterCard_" .. floaterId
	card.BackgroundColor3 = COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isEquipped and COLORS.Success or getRarityColor(floaterConfig.Rarity)
	cardStroke.Thickness = isEquipped and 3 or 2
	cardStroke.Parent = card
	
	-- Image Container (SAME AS FISH)
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(1, -10, 0, 60)
	imageContainer.Position = UDim2.new(0, 5, 0, 5)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	-- Thumbnail
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(0.8, 0, 0.8, 0)
	thumbnail.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbnail.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbnail.BackgroundTransparency = 1
	thumbnail.Image = floaterConfig.Thumbnail or ""
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = imageContainer
	
	-- Equipped badge
	if isEquipped then
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 50, 0, 18)
		badge.Position = UDim2.new(1, -5, 0, 5)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = COLORS.Success
		badge.Font = Enum.Font.GothamBold
		badge.Text = "✓"
		badge.TextColor3 = COLORS.Text
		badge.TextSize = 12
		badge.Parent = imageContainer
		createCorner(4).Parent = badge
	end
	
	-- Name (SAME STYLE AS FISH)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 16)
	nameLabel.Position = UDim2.new(0, 3, 0, 68)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = floaterConfig.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 10
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	-- Rarity (SAME STYLE AS FISH)
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -6, 0, 14)
	rarityLabel.Position = UDim2.new(0, 3, 0, 84)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = floaterConfig.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(floaterConfig.Rarity)
	rarityLabel.TextSize = 9
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	-- Action Button (Equip/Unequip)
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(1, -10, 0, 22)
	actionBtn.Position = UDim2.new(0, 5, 1, -26)
	actionBtn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Text = isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = COLORS.Text
	actionBtn.TextSize = 10
	actionBtn.Parent = card
	
	createCorner(5).Parent = actionBtn
	
	actionBtn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipFloaterEvent:FireServer()
		else
			equipFloaterEvent:FireServer(floaterId)
		end
	end)
	
	card.Parent = contentFrame
	return card
end

-- ==================== DATA FUNCTIONS ====================

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function updateDisplay()
	clearContent()
	
	if currentTab == "Rods" then
		for _, rodId in ipairs(equipmentData.OwnedRods or {}) do
			local isEquipped = (equipmentData.EquippedRod == rodId)
			createRodCard(rodId, isEquipped)
		end
		
		-- Update equipped info
		local equippedRodConfig = RodShopConfig.GetRodById(equipmentData.EquippedRod)
		if equippedRodConfig then
			equippedLabel.Text = "🎣 Equipped Rod: " .. equippedRodConfig.DisplayName
		else
			equippedLabel.Text = "🎣 No Rod Equipped"
		end
	else
		for _, floaterId in ipairs(equipmentData.OwnedFloaters or {}) do
			local isEquipped = (equipmentData.EquippedFloater == floaterId)
			createFloaterCard(floaterId, isEquipped)
		end
		
		-- Update equipped info
		local equippedFloaterConfig = RodShopConfig.GetFloaterById(equipmentData.EquippedFloater)
		if equippedFloaterConfig then
			equippedLabel.Text = "🎈 Equipped Floater: " .. equippedFloaterConfig.DisplayName
		else
			equippedLabel.Text = "🎈 No Floater Equipped"
		end
	end
end

local function fetchData()
	if not getOwnedItemsFunc then return end
	
	local success, data = pcall(function()
		return getOwnedItemsFunc:InvokeServer()
	end)
	
	if success and data then
		equipmentData = data
		updateDisplay()
	end
end

-- ==================== TAB SWITCHING ====================

local function switchTab(tab)
	currentTab = tab
	
	if tab == "Rods" then
		rodsTabBtn.BackgroundColor3 = COLORS.Accent
		rodsTabBtn.TextColor3 = COLORS.Text
		floatersTabBtn.BackgroundColor3 = COLORS.CardBg
		floatersTabBtn.TextColor3 = COLORS.SubText
	else
		floatersTabBtn.BackgroundColor3 = COLORS.Accent
		floatersTabBtn.TextColor3 = COLORS.Text
		rodsTabBtn.BackgroundColor3 = COLORS.CardBg
		rodsTabBtn.TextColor3 = COLORS.SubText
	end
	
	updateDisplay()
end

rodsTabBtn.MouseButton1Click:Connect(function()
	switchTab("Rods")
end)

floatersTabBtn.MouseButton1Click:Connect(function()
	switchTab("Floaters")
end)

-- ==================== OPEN/CLOSE ====================

local function togglePanel()
	isOpen = not isOpen
	mainPanel.Visible = isOpen
	
	if isOpen then
		fetchData()
	end
end

floatingButton.MouseButton1Click:Connect(togglePanel)
closeButton.MouseButton1Click:Connect(function()
	isOpen = false
	mainPanel.Visible = false
end)

-- ==================== AUTO-REFRESH ====================

if equipmentChangedEvent then
	equipmentChangedEvent.OnClientEvent:Connect(function(data)
		print("🔄 [EQUIPMENT] Equipment changed!")
		fetchData()
	end)
end

if shopUpdatedEvent then
	shopUpdatedEvent.OnClientEvent:Connect(function()
		print("🔄 [EQUIPMENT] Shop updated!")
		fetchData()
	end)
end

-- ==================== KEYBIND ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.G then
		togglePanel()
	end
end)

print("✅ [EQUIPMENT CLIENT] Loaded - Press G or click button to open")
