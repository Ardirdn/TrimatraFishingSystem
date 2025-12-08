--[[
    FISH COLLECTION CLIENT
    Place in StarterPlayerScripts
    
    UI for Fish Inventory and Fish Index (Pokedex-style)
    - Inventory: Fish player owns, can sell
    - Index: All fish types, discovered/undiscovered
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))

-- Wait for remotes
local remoteFolder = ReplicatedStorage:WaitForChild("FishermanShopRemotes", 10)
if not remoteFolder then
	warn("[FISH COLLECTION] FishermanShopRemotes not found!")
	return
end

local getFishInventoryFunc = remoteFolder:WaitForChild("GetFishInventory", 5)
local getDiscoveredFishFunc = remoteFolder:WaitForChild("GetDiscoveredFish", 5)
local fishSoldEvent = remoteFolder:FindFirstChild("FishSold")

-- State
local isOpen = false
local currentTab = "Inventory"
local currentSort = "Rarity"
local fishInventoryData = nil
local fishIndexData = nil

-- ✅ NEW: Fish holding state
local isHoldingFish = false
local heldFishTool = nil
local previouslyHeldRod = nil -- Remember rod before holding fish

-- Colors
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

print("✅ [FISH COLLECTION] Starting initialization...")

-- ==================== HELPER FUNCTIONS ====================

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function getRarityColor(rarity)
	return COLORS[rarity] or COLORS.Common
end

local function formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. amount
	end
end

-- ==================== CREATE UI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishCollectionGUI"
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
floatingButton.Name = "FishButton"
floatingButton.Size = UDim2.new(0, buttonBaseSize, 0, buttonBaseSize)
floatingButton.Position = UDim2.new(0, 10, 0.5, 0)
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
buttonIcon.Text = "🐟"
buttonIcon.TextColor3 = COLORS.Text
buttonIcon.TextSize = isMobile and 22 or 28
buttonIcon.TextScaled = isMobile
buttonIcon.Parent = floatingButton

local buttonText = Instance.new("TextLabel")
buttonText.Size = UDim2.new(1, 0, 0.3, 0)
buttonText.Position = UDim2.new(0, 0, 0.65, 0)
buttonText.BackgroundTransparency = 1
buttonText.Font = Enum.Font.GothamBold
buttonText.Text = "Fish"
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

-- ==================== MAIN PANEL (RESPONSIVE) ====================

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

-- Header
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
titleLabel.Text = "🐟 FISH COLLECTION"
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

-- Tab Buttons
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

local inventoryTabBtn = Instance.new("TextButton")
inventoryTabBtn.Name = "InventoryTab"
inventoryTabBtn.Size = UDim2.new(0.5, -5, 1, 0)
inventoryTabBtn.BackgroundColor3 = COLORS.Accent
inventoryTabBtn.BorderSizePixel = 0
inventoryTabBtn.Font = Enum.Font.GothamBold
inventoryTabBtn.Text = "📦 INVENTORY"
inventoryTabBtn.TextColor3 = COLORS.Text
inventoryTabBtn.TextSize = 14
inventoryTabBtn.Parent = tabFrame

createCorner(8).Parent = inventoryTabBtn

local indexTabBtn = Instance.new("TextButton")
indexTabBtn.Name = "IndexTab"
indexTabBtn.Size = UDim2.new(0.5, -5, 1, 0)
indexTabBtn.BackgroundColor3 = COLORS.CardBg
indexTabBtn.BorderSizePixel = 0
indexTabBtn.Font = Enum.Font.GothamBold
indexTabBtn.Text = "📖 INDEX"
indexTabBtn.TextColor3 = COLORS.SubText
indexTabBtn.TextSize = 14
indexTabBtn.Parent = tabFrame

createCorner(8).Parent = indexTabBtn

-- Sort Button (for Inventory)
local sortButton = Instance.new("TextButton")
sortButton.Name = "SortButton"
sortButton.Size = UDim2.new(0, 100, 0, 30)
sortButton.Position = UDim2.new(1, -115, 0, 115)
sortButton.BackgroundColor3 = COLORS.CardBg
sortButton.BorderSizePixel = 0
sortButton.Font = Enum.Font.GothamBold
sortButton.Text = "⬇️ Sort"
sortButton.TextColor3 = COLORS.Text
sortButton.TextSize = 12
sortButton.Parent = mainPanel

createCorner(6).Parent = sortButton

-- Sort Popup
local sortPopup = Instance.new("Frame")
sortPopup.Name = "SortPopup"
sortPopup.Size = UDim2.new(0, 120, 0, 100)
sortPopup.Position = UDim2.new(1, -130, 0, 148)
sortPopup.BackgroundColor3 = COLORS.CardBg
sortPopup.BorderSizePixel = 0
sortPopup.Visible = false
sortPopup.ZIndex = 10
sortPopup.Parent = mainPanel

createCorner(8).Parent = sortPopup

local sortStroke = Instance.new("UIStroke")
sortStroke.Color = COLORS.Accent
sortStroke.Thickness = 1
sortStroke.Parent = sortPopup

local sortOptions = {"Rarity", "Price", "Name"}
for i, option in ipairs(sortOptions) do
	local optBtn = Instance.new("TextButton")
	optBtn.Size = UDim2.new(1, -10, 0, 28)
	optBtn.Position = UDim2.new(0, 5, 0, 5 + (i-1) * 30)
	optBtn.BackgroundColor3 = currentSort == option and COLORS.Accent or Color3.fromRGB(35, 55, 75)
	optBtn.BorderSizePixel = 0
	optBtn.Font = Enum.Font.GothamBold
	optBtn.Text = option
	optBtn.TextColor3 = COLORS.Text
	optBtn.TextSize = 11
	optBtn.ZIndex = 11
	optBtn.Parent = sortPopup
	
	createCorner(5).Parent = optBtn
	
	optBtn.MouseButton1Click:Connect(function()
		currentSort = option
		sortPopup.Visible = false
		-- Update all sort buttons color
		for _, child in ipairs(sortPopup:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = child.Text == currentSort and COLORS.Accent or Color3.fromRGB(35, 55, 75)
			end
		end
		-- Refresh display
		if currentTab == "Inventory" then
			updateInventoryDisplay()
		end
	end)
end

sortButton.MouseButton1Click:Connect(function()
	sortPopup.Visible = not sortPopup.Visible
end)

-- Content Frame
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -30, 1, -210)
contentFrame.Position = UDim2.new(0, 15, 0, 150)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = COLORS.Accent
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainPanel

local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(0.25, -8, 0, 130)
contentGrid.CellPadding = UDim2.new(0, 8, 0, 8)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 5)
contentPadding.PaddingBottom = UDim.new(0, 10)
contentPadding.Parent = contentFrame

-- Bottom Stats Bar
local statsBar = Instance.new("Frame")
statsBar.Name = "StatsBar"
statsBar.Size = UDim2.new(1, -30, 0, 45)
statsBar.Position = UDim2.new(0, 15, 1, -55)
statsBar.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
statsBar.BorderSizePixel = 0
statsBar.Parent = mainPanel

createCorner(10).Parent = statsBar

local totalValueLabel = Instance.new("TextLabel")
totalValueLabel.Name = "TotalValue"
totalValueLabel.Size = UDim2.new(0.5, 0, 1, 0)
totalValueLabel.Position = UDim2.new(0, 15, 0, 0)
totalValueLabel.BackgroundTransparency = 1
totalValueLabel.Font = Enum.Font.GothamBold
totalValueLabel.Text = "💰 Total Value: $0"
totalValueLabel.TextColor3 = COLORS.Success
totalValueLabel.TextSize = 16
totalValueLabel.TextXAlignment = Enum.TextXAlignment.Left
totalValueLabel.Parent = statsBar

local discoveredLabel = Instance.new("TextLabel")
discoveredLabel.Name = "Discovered"
discoveredLabel.Size = UDim2.new(0.5, -15, 1, 0)
discoveredLabel.Position = UDim2.new(0.5, 0, 0, 0)
discoveredLabel.BackgroundTransparency = 1
discoveredLabel.Font = Enum.Font.GothamBold
discoveredLabel.Text = "📖 Discovered: 0/0"
discoveredLabel.TextColor3 = COLORS.Accent
discoveredLabel.TextSize = 16
discoveredLabel.TextXAlignment = Enum.TextXAlignment.Right
discoveredLabel.Parent = statsBar

-- ==================== HOLD FISH FUNCTION ====================

local function holdFish(fishId, fishName)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	local backpack = player:FindFirstChild("Backpack")
	if not humanoid or not backpack then return end
	
	-- Check if already holding this fish
	if isHoldingFish and heldFishTool and heldFishTool.Name == fishName then
		-- Unequip fish
		humanoid:UnequipTools()
		
		-- Don't destroy fish tool, just unequip
		-- Re-equip previous rod if we had one
		if previouslyHeldRod then
			local rodTool = backpack:FindFirstChild(previouslyHeldRod)
			if rodTool then
				humanoid:EquipTool(rodTool)
			end
			previouslyHeldRod = nil
		end
		
		isHoldingFish = false
		heldFishTool = nil
		print("🐟 [FISH COLLECTION] Unequipped fish:", fishName)
		return
	end
	
	-- Remember current rod if holding one
	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name:find("FishingRod") then
		previouslyHeldRod = currentTool.Name
	elseif currentTool == nil then
		previouslyHeldRod = nil -- No rod was held before
	end
	
	-- Find fish tool in backpack
	local fishTool = nil
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == fishName then
			fishTool = tool
			break
		end
	end
	
	-- Also check character
	if not fishTool then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == fishName then
				fishTool = tool
				break
			end
		end
	end
	
	if fishTool then
		humanoid:EquipTool(fishTool)
		isHoldingFish = true
		heldFishTool = fishTool
		print("🐟 [FISH COLLECTION] Equipped fish:", fishName)
	else
		print("⚠️ [FISH COLLECTION] Fish tool not found:", fishName)
	end
end

-- ==================== FISH CARD CREATION ====================

local function createFishCard(fishData, isInventory, isDiscovered)
	local card = Instance.new("Frame")
	card.Name = "FishCard_" .. fishData.FishId
	card.BackgroundColor3 = isDiscovered == false and Color3.fromRGB(10, 15, 20) or COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isDiscovered == false and Color3.fromRGB(40, 40, 50) or getRarityColor(fishData.Rarity)
	cardStroke.Thickness = isDiscovered == false and 1 or 2
	cardStroke.Parent = card
	
	-- Fish Image Container
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(1, -10, 0, 60)
	imageContainer.Position = UDim2.new(0, 5, 0, 5)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	-- Fish Image (or silhouette if not discovered)
	local fishImage = Instance.new("ImageLabel")
	fishImage.Size = UDim2.new(0.8, 0, 0.8, 0)
	fishImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	fishImage.AnchorPoint = Vector2.new(0.5, 0.5)
	fishImage.BackgroundTransparency = 1
	fishImage.Image = fishData.ImageID or ""
	fishImage.ImageColor3 = isDiscovered == false and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
	fishImage.ScaleType = Enum.ScaleType.Fit
	fishImage.Parent = imageContainer
	
	-- Count badge (for inventory)
	if isInventory and fishData.Count and fishData.Count > 0 then
		local countBadge = Instance.new("TextLabel")
		countBadge.Size = UDim2.new(0, 30, 0, 18)
		countBadge.Position = UDim2.new(1, -5, 0, 5)
		countBadge.AnchorPoint = Vector2.new(1, 0)
		countBadge.BackgroundColor3 = COLORS.Warning
		countBadge.Font = Enum.Font.GothamBold
		countBadge.Text = "x" .. fishData.Count
		countBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
		countBadge.TextSize = 10
		countBadge.Parent = imageContainer
		createCorner(4).Parent = countBadge
	end
	
	-- Fish Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 16)
	nameLabel.Position = UDim2.new(0, 3, 0, 68)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = fishData.Name or "???"
	nameLabel.TextColor3 = isDiscovered == false and COLORS.SubText or COLORS.Text
	nameLabel.TextSize = 10
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	-- Rarity
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -6, 0, 14)
	rarityLabel.Position = UDim2.new(0, 3, 0, 84)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = (fishData.Rarity or "Unknown"):upper()
	rarityLabel.TextColor3 = getRarityColor(fishData.Rarity)
	rarityLabel.TextSize = 9
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	-- Price (hide if not discovered in Index)
	if isDiscovered ~= false then
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, -6, 0, 18)
		priceLabel.Position = UDim2.new(0, 3, 1, -22)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Text = isInventory and formatMoney(fishData.TotalValue or 0) or formatMoney(fishData.Price or 0)
		priceLabel.TextColor3 = COLORS.Success
		priceLabel.TextSize = 11
		priceLabel.TextXAlignment = Enum.TextXAlignment.Center
		priceLabel.Parent = card
	else
		local unknownLabel = Instance.new("TextLabel")
		unknownLabel.Size = UDim2.new(1, -6, 0, 18)
		unknownLabel.Position = UDim2.new(0, 3, 1, -22)
		unknownLabel.BackgroundTransparency = 1
		unknownLabel.Font = Enum.Font.GothamBold
		unknownLabel.Text = "???"
		unknownLabel.TextColor3 = COLORS.SubText
		unknownLabel.TextSize = 11
		unknownLabel.TextXAlignment = Enum.TextXAlignment.Center
		unknownLabel.Parent = card
	end
	
	-- ✅ NEW: Click to hold fish (for inventory mode only)
	if isInventory and fishData.Count and fishData.Count > 0 then
		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.ZIndex = 10
		clickBtn.Parent = card
		
		clickBtn.MouseButton1Click:Connect(function()
			holdFish(fishData.FishId, fishData.Name)
		end)
		
		-- Hover effect
		clickBtn.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Accent}):Play()
		end)
		
		clickBtn.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.CardBg}):Play()
		end)
	end
	
	card.Parent = contentFrame
	return card
end

-- ==================== DISPLAY FUNCTIONS ====================

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

function updateInventoryDisplay()
	clearContent()
	sortButton.Visible = true
	
	if not fishInventoryData or not fishInventoryData.FishList then return end
	
	local fishList = fishInventoryData.FishList
	
	-- Sort
	local rarityOrder = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6}
	
	if currentSort == "Rarity" then
		table.sort(fishList, function(a, b)
			local orderA = rarityOrder[a.Rarity] or 0
			local orderB = rarityOrder[b.Rarity] or 0
			if orderA == orderB then
				return a.Name < b.Name
			end
			return orderB < orderA -- Higher rarity first
		end)
	elseif currentSort == "Price" then
		table.sort(fishList, function(a, b)
			return (a.TotalValue or 0) > (b.TotalValue or 0)
		end)
	elseif currentSort == "Name" then
		table.sort(fishList, function(a, b)
			return a.Name < b.Name
		end)
	end
	
	-- Create cards
	for _, fishData in ipairs(fishList) do
		createFishCard(fishData, true, true)
	end
	
	-- Update stats
	totalValueLabel.Text = "💰 Total Value: " .. formatMoney(fishInventoryData.TotalValue or 0)
	totalValueLabel.Visible = true
	discoveredLabel.Visible = false
end

local function updateIndexDisplay()
	clearContent()
	sortButton.Visible = false
	sortPopup.Visible = false
	
	if not fishIndexData or not fishIndexData.AllFish then return end
	
	local allFish = fishIndexData.AllFish
	local discoveredCount = 0
	
	-- Create cards for all fish
	for _, fishData in ipairs(allFish) do
		createFishCard(fishData, false, fishData.IsDiscovered)
		if fishData.IsDiscovered then
			discoveredCount = discoveredCount + 1
		end
	end
	
	-- Update stats
	totalValueLabel.Visible = false
	discoveredLabel.Visible = true
	discoveredLabel.Text = string.format("📖 Discovered: %d/%d", discoveredCount, #allFish)
end

-- ==================== DATA FETCHING ====================

local function fetchInventory()
	if not getFishInventoryFunc then return end
	
	local success, data = pcall(function()
		return getFishInventoryFunc:InvokeServer()
	end)
	
	if success and data then
		fishInventoryData = data
		if currentTab == "Inventory" then
			updateInventoryDisplay()
		end
	end
end

local function fetchIndex()
	if not getDiscoveredFishFunc then return end
	
	local success, data = pcall(function()
		return getDiscoveredFishFunc:InvokeServer()
	end)
	
	if success and data then
		fishIndexData = data
		if currentTab == "Index" then
			updateIndexDisplay()
		end
	end
end

-- ==================== TAB SWITCHING ====================

local function switchTab(tab)
	currentTab = tab
	sortPopup.Visible = false
	
	if tab == "Inventory" then
		inventoryTabBtn.BackgroundColor3 = COLORS.Accent
		inventoryTabBtn.TextColor3 = COLORS.Text
		indexTabBtn.BackgroundColor3 = COLORS.CardBg
		indexTabBtn.TextColor3 = COLORS.SubText
		fetchInventory()
	else
		indexTabBtn.BackgroundColor3 = COLORS.Accent
		indexTabBtn.TextColor3 = COLORS.Text
		inventoryTabBtn.BackgroundColor3 = COLORS.CardBg
		inventoryTabBtn.TextColor3 = COLORS.SubText
		fetchIndex()
	end
end

inventoryTabBtn.MouseButton1Click:Connect(function()
	switchTab("Inventory")
end)

indexTabBtn.MouseButton1Click:Connect(function()
	switchTab("Index")
end)

-- ==================== OPEN/CLOSE ====================

local function togglePanel()
	isOpen = not isOpen
	mainPanel.Visible = isOpen
	
	if isOpen then
		switchTab(currentTab)
	end
end

floatingButton.MouseButton1Click:Connect(togglePanel)
closeButton.MouseButton1Click:Connect(function()
	isOpen = false
	mainPanel.Visible = false
	sortPopup.Visible = false
end)

-- ==================== AUTO-REFRESH ====================

if fishSoldEvent then
	fishSoldEvent.OnClientEvent:Connect(function(data)
		print("🔄 [FISH COLLECTION] Fish sold, refreshing...")
		fetchInventory()
	end)
end

-- ==================== KEYBIND ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.F then
		togglePanel()
	end
end)

print("✅ [FISH COLLECTION] Loaded - Press F or click button to open")
