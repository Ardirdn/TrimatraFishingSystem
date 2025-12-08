--[[
    EQUIPMENT SYSTEM CLIENT (ADAPTIVE VERSION)
    Place in StarterPlayerScripts
    
    Handles Equipment UI for Rods & Floaters only
    Floating circular button on left side of screen
    
    ✅ FULLY ADAPTIVE: Uses Scale + AspectRatioConstraint
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
local unequipRodEvent = rodShopRemotes:WaitForChild("UnequipRod", 5)
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

print("✅ [EQUIPMENT CLIENT] Starting initialization (ADAPTIVE VERSION)...")

-- ==================== HELPER FUNCTIONS ====================

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createScaledCorner(scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	return corner
end

local function getRarityColor(rarity)
	return COLORS[rarity] or COLORS.Common
end

-- ==================== MOBILE DETECTION ====================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==================== CREATE UI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EquipmentGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ==================== USE HUD BUTTON TEMPLATE (LEFT SIDE) ====================

local hudGui = playerGui:WaitForChild("HUD", 10)
local leftFrame = hudGui and hudGui:FindFirstChild("Left")
local buttonTemplate = leftFrame and leftFrame:FindFirstChild("ButtonTemplate")

local floatingButton = nil

if buttonTemplate then
	-- ✅ Hide the original template
	buttonTemplate.Visible = false
	
	-- Clone the template
	local buttonContainer = buttonTemplate:Clone()
	buttonContainer.Name = "EquipButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 1 -- First button
	buttonContainer.BackgroundTransparency = 1 -- ✅ Transparent container
	buttonContainer.Parent = leftFrame
	
	-- Get references
	floatingButton = buttonContainer:FindFirstChild("ImageButton")
	local buttonText = buttonContainer:FindFirstChild("TextLabel")
	
	-- Set button properties
	if floatingButton then
		floatingButton.Image = "rbxassetid://139408214639598" -- Equipment icon
		floatingButton.BackgroundTransparency = 1 -- ✅ Transparent button
	end
	
	if buttonText then
		buttonText.Text = "Equip"
	end
	
	print("✅ [EQUIPMENT] Using HUD template button")
else
	-- Fallback: Create button manually if template not found
	warn("[EQUIPMENT] HUD template not found, creating button manually")
	
	floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "EquipmentButton"
	floatingButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	floatingButton.Position = UDim2.new(0.01, 0, 0.4, 0)
	floatingButton.BackgroundTransparency = 1
	floatingButton.BorderSizePixel = 0
	floatingButton.Image = "rbxassetid://139408214639598"
	floatingButton.ScaleType = Enum.ScaleType.Fit
	floatingButton.Parent = screenGui
	
	local buttonAspect = Instance.new("UIAspectRatioConstraint")
	buttonAspect.AspectRatio = 1
	buttonAspect.Parent = floatingButton
	
	local buttonText = Instance.new("TextLabel")
	buttonText.Size = UDim2.new(1, 0, 0.3, 0)
	buttonText.Position = UDim2.new(0, 0, 1, 2)
	buttonText.BackgroundTransparency = 1
	buttonText.Font = Enum.Font.GothamBold
	buttonText.Text = "Equip"
	buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
	buttonText.TextScaled = true
	buttonText.Parent = floatingButton
end


-- ==================== MAIN PANEL (FULLY ADAPTIVE) ====================

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0.45, 0, 0.75, 0) -- 45% width, 75% height of screen
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

-- Maintain aspect ratio (550/600 = 0.917)
local panelAspect = Instance.new("UIAspectRatioConstraint")
panelAspect.AspectRatio = 1.2-- Width/Height
panelAspect.DominantAxis = Enum.DominantAxis.Height
panelAspect.Parent = mainPanel

-- Size constraint for panel
local panelSizeConstraint = Instance.new("UISizeConstraint")
panelSizeConstraint.MinSize = Vector2.new(320, 350)
panelSizeConstraint.MaxSize = Vector2.new(600, 650)
panelSizeConstraint.Parent = mainPanel

createCorner(16).Parent = mainPanel

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Accent
mainStroke.Thickness = 2
mainStroke.Parent = mainPanel

-- ==================== HEADER (ADAPTIVE) ====================

local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0.09, 0) -- 9% of panel height
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainPanel

createCorner(16).Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 0.8, 0)
titleLabel.Position = UDim2.new(0.03, 0, 0.1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "🎣 EQUIPMENT"
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

-- Text size constraint for title
local titleTextConstraint = Instance.new("UITextSizeConstraint")
titleTextConstraint.MinTextSize = 12
titleTextConstraint.MaxTextSize = 28
titleTextConstraint.Parent = titleLabel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.12, 0, 0.7, 0)
closeButton.Position = UDim2.new(0.86, 0, 0.15, 0)
closeButton.BackgroundColor3 = COLORS.Danger
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Text
closeButton.TextScaled = true
closeButton.Parent = headerFrame

-- Keep close button square-ish
local closeAspect = Instance.new("UIAspectRatioConstraint")
closeAspect.AspectRatio = 1
closeAspect.Parent = closeButton

createCorner(8).Parent = closeButton

-- ==================== TAB BUTTONS (ADAPTIVE) ====================

local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(0.94, 0, 0.065, 0) -- 6.5% of panel height
tabFrame.Position = UDim2.new(0.03, 0, 0.105, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.02, 0)
tabLayout.Parent = tabFrame

local rodsTabBtn = Instance.new("TextButton")
rodsTabBtn.Name = "RodsTab"
rodsTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
rodsTabBtn.BackgroundColor3 = COLORS.Accent
rodsTabBtn.BorderSizePixel = 0
rodsTabBtn.Font = Enum.Font.GothamBold
rodsTabBtn.Text = "🎣 RODS"
rodsTabBtn.TextColor3 = COLORS.Text
rodsTabBtn.TextScaled = true
rodsTabBtn.Parent = tabFrame

local rodsTabTextConstraint = Instance.new("UITextSizeConstraint")
rodsTabTextConstraint.MinTextSize = 10
rodsTabTextConstraint.MaxTextSize = 16
rodsTabTextConstraint.Parent = rodsTabBtn

createCorner(8).Parent = rodsTabBtn

local floatersTabBtn = Instance.new("TextButton")
floatersTabBtn.Name = "FloatersTab"
floatersTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
floatersTabBtn.BackgroundColor3 = COLORS.CardBg
floatersTabBtn.BorderSizePixel = 0
floatersTabBtn.Font = Enum.Font.GothamBold
floatersTabBtn.Text = "🎈 FLOATERS"
floatersTabBtn.TextColor3 = COLORS.SubText
floatersTabBtn.TextScaled = true
floatersTabBtn.Parent = tabFrame

local floatersTabTextConstraint = Instance.new("UITextSizeConstraint")
floatersTabTextConstraint.MinTextSize = 10
floatersTabTextConstraint.MaxTextSize = 16
floatersTabTextConstraint.Parent = floatersTabBtn

createCorner(8).Parent = floatersTabBtn

-- ==================== CONTENT FRAME (ADAPTIVE GRID) ====================

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(0.94, 0, 0.65, 0) -- 65% of panel height
contentFrame.Position = UDim2.new(0.03, 0, 0.19, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = COLORS.Accent
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainPanel

-- Adaptive Grid - 4 columns on desktop, 3 on mobile
local columns = isMobile and 3 or 4
local cellWidth = 1 / columns

local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(cellWidth, -8, 0, 130) -- Fixed height for cards
contentGrid.CellPadding = UDim2.new(0.01, 0, 0, 8)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0.01, 0)
contentPadding.PaddingBottom = UDim.new(0.02, 0)
contentPadding.Parent = contentFrame

-- ==================== STATS BAR (ADAPTIVE) ====================

local statsBar = Instance.new("Frame")
statsBar.Name = "StatsBar"
statsBar.Size = UDim2.new(0.94, 0, 0.075, 0) -- 7.5% of panel height
statsBar.Position = UDim2.new(0.03, 0, 0.91, 0)
statsBar.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
statsBar.BorderSizePixel = 0
statsBar.Parent = mainPanel

createCorner(10).Parent = statsBar

local equippedLabel = Instance.new("TextLabel")
equippedLabel.Name = "EquippedInfo"
equippedLabel.Size = UDim2.new(0.94, 0, 0.85, 0)
equippedLabel.Position = UDim2.new(0.03, 0, 0.075, 0)
equippedLabel.BackgroundTransparency = 1
equippedLabel.Font = Enum.Font.GothamBold
equippedLabel.Text = "🎣 Equipped: Loading..."
equippedLabel.TextColor3 = COLORS.Success
equippedLabel.TextScaled = true
equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedLabel.Parent = statsBar

local equippedTextConstraint = Instance.new("UITextSizeConstraint")
equippedTextConstraint.MinTextSize = 10
equippedTextConstraint.MaxTextSize = 18
equippedTextConstraint.Parent = equippedLabel

-- ==================== ITEM CARD CREATION (ADAPTIVE) ====================

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
	
	-- Image Container (adaptive within card)
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0.9, 0, 0.45, 0)
	imageContainer.Position = UDim2.new(0.05, 0, 0.04, 0)
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
		badge.Size = UDim2.new(0.4, 0, 0.3, 0)
		badge.Position = UDim2.new(0.95, 0, 0.05, 0)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = COLORS.Success
		badge.Font = Enum.Font.GothamBold
		badge.Text = "✓"
		badge.TextColor3 = COLORS.Text
		badge.TextScaled = true
		badge.Parent = imageContainer
		createCorner(4).Parent = badge
	end
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.94, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.03, 0, 0.52, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = rodConfig.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	local nameTextConstraint = Instance.new("UITextSizeConstraint")
	nameTextConstraint.MinTextSize = 8
	nameTextConstraint.MaxTextSize = 12
	nameTextConstraint.Parent = nameLabel
	
	-- Rarity
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.94, 0, 0.1, 0)
	rarityLabel.Position = UDim2.new(0.03, 0, 0.65, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = rodConfig.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(rodConfig.Rarity)
	rarityLabel.TextScaled = true
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	local rarityTextConstraint = Instance.new("UITextSizeConstraint")
	rarityTextConstraint.MinTextSize = 7
	rarityTextConstraint.MaxTextSize = 10
	rarityTextConstraint.Parent = rarityLabel
	
	-- Action Button
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
	actionBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
	actionBtn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Text = isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = COLORS.Text
	actionBtn.TextScaled = true
	actionBtn.Parent = card
	
	local actionTextConstraint = Instance.new("UITextSizeConstraint")
	actionTextConstraint.MinTextSize = 8
	actionTextConstraint.MaxTextSize = 12
	actionTextConstraint.Parent = actionBtn
	
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
	
	-- Image Container
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0.9, 0, 0.45, 0)
	imageContainer.Position = UDim2.new(0.05, 0, 0.04, 0)
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
		badge.Size = UDim2.new(0.4, 0, 0.3, 0)
		badge.Position = UDim2.new(0.95, 0, 0.05, 0)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = COLORS.Success
		badge.Font = Enum.Font.GothamBold
		badge.Text = "✓"
		badge.TextColor3 = COLORS.Text
		badge.TextScaled = true
		badge.Parent = imageContainer
		createCorner(4).Parent = badge
	end
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.94, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.03, 0, 0.52, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = floaterConfig.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	local nameTextConstraint = Instance.new("UITextSizeConstraint")
	nameTextConstraint.MinTextSize = 8
	nameTextConstraint.MaxTextSize = 12
	nameTextConstraint.Parent = nameLabel
	
	-- Rarity
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.94, 0, 0.1, 0)
	rarityLabel.Position = UDim2.new(0.03, 0, 0.65, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = floaterConfig.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(floaterConfig.Rarity)
	rarityLabel.TextScaled = true
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	local rarityTextConstraint = Instance.new("UITextSizeConstraint")
	rarityTextConstraint.MinTextSize = 7
	rarityTextConstraint.MaxTextSize = 10
	rarityTextConstraint.Parent = rarityLabel
	
	-- Action Button
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
	actionBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
	actionBtn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Text = isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = COLORS.Text
	actionBtn.TextScaled = true
	actionBtn.Parent = card
	
	local actionTextConstraint = Instance.new("UITextSizeConstraint")
	actionTextConstraint.MinTextSize = 8
	actionTextConstraint.MaxTextSize = 12
	actionTextConstraint.Parent = actionBtn
	
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

print("✅ [EQUIPMENT CLIENT] Loaded (ADAPTIVE VERSION) - Press G or click button to open")
