--[[
    FISH COLLECTION CLIENT (ADAPTIVE VERSION)
    Place in StarterPlayerScripts
    
    UI for Fish Inventory and Fish Index (Pokedex-style)
    - Inventory: Fish player owns, can hold
    - Index: All fish types, discovered/undiscovered
    
    ✅ FULLY ADAPTIVE: Uses Scale + AspectRatioConstraint
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

-- Fish holding state
local isHoldingFish = false
local heldFishTool = nil
local previouslyHeldRod = nil

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

print("✅ [FISH COLLECTION] Starting initialization (ADAPTIVE VERSION)...")

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

-- ==================== MOBILE DETECTION ====================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==================== CREATE UI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishCollectionGUI"
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
	buttonContainer.Name = "FishButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 2 -- Second button (after Equip)
	buttonContainer.BackgroundTransparency = 1 -- ✅ Transparent container
	buttonContainer.Parent = leftFrame
	
	-- Get references
	floatingButton = buttonContainer:FindFirstChild("ImageButton")
	local buttonText = buttonContainer:FindFirstChild("TextLabel")
	
	-- Set button properties
	if floatingButton then
		floatingButton.Image = "rbxassetid://88132286506428" -- Fish icon
		floatingButton.BackgroundTransparency = 1 -- ✅ Transparent button
	end
	
	if buttonText then
		buttonText.Text = "Fish"
	end
	
	print("✅ [FISH COLLECTION] Using HUD template button")
else
	-- Fallback: Create button manually if template not found
	warn("[FISH COLLECTION] HUD template not found, creating button manually")
	
	floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "FishButton"
	floatingButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	floatingButton.Position = UDim2.new(0.01, 0, 0.5, 0)
	floatingButton.BackgroundTransparency = 1
	floatingButton.BorderSizePixel = 0
	floatingButton.Image = "rbxassetid://88132286506428"
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
	buttonText.Text = "Fish"
	buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
	buttonText.TextScaled = true
	buttonText.Parent = floatingButton
end


-- ==================== MAIN PANEL (FULLY ADAPTIVE) ====================

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0.5, 0, 0.8, 0)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

-- AspectRatio based on Width
local panelAspect = Instance.new("UIAspectRatioConstraint")
panelAspect.AspectRatio = 0.85
panelAspect.DominantAxis = Enum.DominantAxis.Width
panelAspect.Parent = mainPanel

createCorner(16).Parent = mainPanel

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Accent
mainStroke.Thickness = 2
mainStroke.Parent = mainPanel

-- Main Panel Padding
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0.02, 0)
mainPadding.PaddingBottom = UDim.new(0.02, 0)
mainPadding.PaddingLeft = UDim.new(0.03, 0)
mainPadding.PaddingRight = UDim.new(0.03, 0)
mainPadding.Parent = mainPanel

-- ==================== HEADER (ADAPTIVE) ====================

local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0.08, 0)
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainPanel

createCorner(12).Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.75, 0, 0.7, 0)
titleLabel.Position = UDim2.new(0.03, 0, 0.15, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "🐟 FISH COLLECTION"
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local titleTextConstraint = Instance.new("UITextSizeConstraint")
titleTextConstraint.MaxTextSize = 26
titleTextConstraint.Parent = titleLabel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.08, 0, 0.7, 0)
closeButton.Position = UDim2.new(0.9, 0, 0.15, 0)
closeButton.BackgroundColor3 = COLORS.Danger
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Text
closeButton.TextScaled = true
closeButton.Parent = headerFrame

local closeTextConstraint = Instance.new("UITextSizeConstraint")
closeTextConstraint.MaxTextSize = 18
closeTextConstraint.Parent = closeButton

local closeAspect = Instance.new("UIAspectRatioConstraint")
closeAspect.AspectRatio = 1
closeAspect.Parent = closeButton

createCorner(8).Parent = closeButton

-- ==================== TAB BUTTONS (ADAPTIVE) ====================

local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(1, 0, 0.06, 0)
tabFrame.Position = UDim2.new(0, 0, 0.1, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.02, 0)
tabLayout.Parent = tabFrame

local inventoryTabBtn = Instance.new("TextButton")
inventoryTabBtn.Name = "InventoryTab"
inventoryTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
inventoryTabBtn.BackgroundColor3 = COLORS.Accent
inventoryTabBtn.BorderSizePixel = 0
inventoryTabBtn.Font = Enum.Font.GothamBold
inventoryTabBtn.Text = "📦 INVENTORY"
inventoryTabBtn.TextColor3 = COLORS.Text
inventoryTabBtn.TextScaled = true
inventoryTabBtn.Parent = tabFrame

local invTabTextConstraint = Instance.new("UITextSizeConstraint")
invTabTextConstraint.MaxTextSize = 16
invTabTextConstraint.Parent = inventoryTabBtn

createCorner(8).Parent = inventoryTabBtn

local indexTabBtn = Instance.new("TextButton")
indexTabBtn.Name = "IndexTab"
indexTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
indexTabBtn.BackgroundColor3 = COLORS.CardBg
indexTabBtn.BorderSizePixel = 0
indexTabBtn.Font = Enum.Font.GothamBold
indexTabBtn.Text = "📖 INDEX"
indexTabBtn.TextColor3 = COLORS.SubText
indexTabBtn.TextScaled = true
indexTabBtn.Parent = tabFrame

local indexTabTextConstraint = Instance.new("UITextSizeConstraint")
indexTabTextConstraint.MaxTextSize = 16
indexTabTextConstraint.Parent = indexTabBtn

createCorner(8).Parent = indexTabBtn

-- ==================== SORT BUTTON (ADAPTIVE) ====================

local sortButton = Instance.new("TextButton")
sortButton.Name = "SortButton"
sortButton.Size = UDim2.new(0.18, 0, 0.045, 0)
sortButton.Position = UDim2.new(0.82, 0, 0.175, 0)
sortButton.BackgroundColor3 = COLORS.CardBg
sortButton.BorderSizePixel = 0
sortButton.Font = Enum.Font.GothamBold
sortButton.Text = "⬇️ Sort"
sortButton.TextColor3 = COLORS.Text
sortButton.TextScaled = true
sortButton.Parent = mainPanel

local sortTextConstraint = Instance.new("UITextSizeConstraint")
sortTextConstraint.MaxTextSize = 14
sortTextConstraint.Parent = sortButton

createCorner(6).Parent = sortButton

-- Sort Popup (adaptive)
local sortPopup = Instance.new("Frame")
sortPopup.Name = "SortPopup"
sortPopup.Size = UDim2.new(0.2, 0, 0.15, 0)
sortPopup.Position = UDim2.new(0.8, 0, 0.225, 0)
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

local sortLayout = Instance.new("UIListLayout")
sortLayout.FillDirection = Enum.FillDirection.Vertical
sortLayout.Padding = UDim.new(0.02, 0)
sortLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sortLayout.Parent = sortPopup

local sortPadding = Instance.new("UIPadding")
sortPadding.PaddingTop = UDim.new(0.05, 0)
sortPadding.PaddingBottom = UDim.new(0.05, 0)
sortPadding.PaddingLeft = UDim.new(0.05, 0)
sortPadding.PaddingRight = UDim.new(0.05, 0)
sortPadding.Parent = sortPopup

local sortOptions = {"Rarity", "Price", "Name"}
for i, option in ipairs(sortOptions) do
	local optBtn = Instance.new("TextButton")
	optBtn.Size = UDim2.new(1, 0, 0.28, 0)
	optBtn.BackgroundColor3 = currentSort == option and COLORS.Accent or Color3.fromRGB(35, 55, 75)
	optBtn.BorderSizePixel = 0
	optBtn.Font = Enum.Font.GothamBold
	optBtn.Text = option
	optBtn.TextColor3 = COLORS.Text
	optBtn.TextScaled = true
	optBtn.ZIndex = 11
	optBtn.Parent = sortPopup
	
	local optTextConstraint = Instance.new("UITextSizeConstraint")
	optTextConstraint.MaxTextSize = 13
	optTextConstraint.Parent = optBtn
	
	createCorner(5).Parent = optBtn
	
	optBtn.MouseButton1Click:Connect(function()
		currentSort = option
		sortPopup.Visible = false
		for _, child in ipairs(sortPopup:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = child.Text == currentSort and COLORS.Accent or Color3.fromRGB(35, 55, 75)
			end
		end
		if currentTab == "Inventory" then
			updateInventoryDisplay()
		end
	end)
end

sortButton.MouseButton1Click:Connect(function()
	sortPopup.Visible = not sortPopup.Visible
end)

-- ==================== CONTENT FRAME (ADAPTIVE GRID) ====================

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 0.62, 0)
contentFrame.Position = UDim2.new(0, 0, 0.23, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = COLORS.Accent
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainPanel

-- Content Padding
local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0.01, 0)
contentPadding.PaddingBottom = UDim.new(0.02, 0)
contentPadding.PaddingLeft = UDim.new(0.01, 0)
contentPadding.PaddingRight = UDim.new(0.01, 0)
contentPadding.Parent = contentFrame

-- Adaptive Grid
local columns = isMobile and 3 or 4
local cellWidth = 1 / columns

local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(cellWidth - 0.02, 0, 0, 130)
contentGrid.CellPadding = UDim2.new(0.015, 0, 0.015, 0)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = contentFrame

-- ==================== STATS BAR (ADAPTIVE) ====================

local statsBar = Instance.new("Frame")
statsBar.Name = "StatsBar"
statsBar.Size = UDim2.new(1, 0, 0.07, 0)
statsBar.Position = UDim2.new(0, 0, 0.9, 0)
statsBar.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
statsBar.BorderSizePixel = 0
statsBar.Parent = mainPanel

createCorner(10).Parent = statsBar

local statsPadding = Instance.new("UIPadding")
statsPadding.PaddingLeft = UDim.new(0.03, 0)
statsPadding.PaddingRight = UDim.new(0.03, 0)
statsPadding.Parent = statsBar

local totalValueLabel = Instance.new("TextLabel")
totalValueLabel.Name = "TotalValue"
totalValueLabel.Size = UDim2.new(0.48, 0, 0.8, 0)
totalValueLabel.Position = UDim2.new(0, 0, 0.1, 0)
totalValueLabel.BackgroundTransparency = 1
totalValueLabel.Font = Enum.Font.GothamBold
totalValueLabel.Text = "💰 Total Value: $0"
totalValueLabel.TextColor3 = COLORS.Success
totalValueLabel.TextScaled = true
totalValueLabel.TextXAlignment = Enum.TextXAlignment.Left
totalValueLabel.Parent = statsBar

local valueTextConstraint = Instance.new("UITextSizeConstraint")
valueTextConstraint.MaxTextSize = 16
valueTextConstraint.Parent = totalValueLabel

local discoveredLabel = Instance.new("TextLabel")
discoveredLabel.Name = "Discovered"
discoveredLabel.Size = UDim2.new(0.48, 0, 0.8, 0)
discoveredLabel.Position = UDim2.new(0.52, 0, 0.1, 0)
discoveredLabel.BackgroundTransparency = 1
discoveredLabel.Font = Enum.Font.GothamBold
discoveredLabel.Text = "📖 Discovered: 0/0"
discoveredLabel.TextColor3 = COLORS.Accent
discoveredLabel.TextScaled = true
discoveredLabel.TextXAlignment = Enum.TextXAlignment.Right
discoveredLabel.Parent = statsBar

local discTextConstraint = Instance.new("UITextSizeConstraint")
discTextConstraint.MaxTextSize = 16
discTextConstraint.Parent = discoveredLabel

-- ==================== HOLD FISH FUNCTION ====================

local function holdFish(fishId, fishName)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	local backpack = player:FindFirstChild("Backpack")
	if not humanoid or not backpack then return end
	
	if isHoldingFish and heldFishTool and heldFishTool.Name == fishName then
		humanoid:UnequipTools()
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
	
	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name:find("FishingRod") then
		previouslyHeldRod = currentTool.Name
	elseif currentTool == nil then
		previouslyHeldRod = nil
	end
	
	local fishTool = nil
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == fishName then
			fishTool = tool
			break
		end
	end
	
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

-- ==================== FISH CARD CREATION (ADAPTIVE) ====================

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
	
	-- Fish Image Container (adaptive)
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0.9, 0, 0.45, 0)
	imageContainer.Position = UDim2.new(0.05, 0, 0.04, 0)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	-- Fish Image
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
		countBadge.Size = UDim2.new(0.35, 0, 0.28, 0)
		countBadge.Position = UDim2.new(0.95, 0, 0.05, 0)
		countBadge.AnchorPoint = Vector2.new(1, 0)
		countBadge.BackgroundColor3 = COLORS.Warning
		countBadge.Font = Enum.Font.GothamBold
		countBadge.Text = "x" .. fishData.Count
		countBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
		countBadge.TextScaled = true
		countBadge.Parent = imageContainer
		createCorner(4).Parent = countBadge
		
		local countTextConstraint = Instance.new("UITextSizeConstraint")
		countTextConstraint.MinTextSize = 8
		countTextConstraint.MaxTextSize = 12
		countTextConstraint.Parent = countBadge
	end
	
	-- Fish Name (adaptive)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.94, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.03, 0, 0.52, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = fishData.Name or "???"
	nameLabel.TextColor3 = isDiscovered == false and COLORS.SubText or COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	local nameTextConstraint = Instance.new("UITextSizeConstraint")
	nameTextConstraint.MinTextSize = 8
	nameTextConstraint.MaxTextSize = 12
	nameTextConstraint.Parent = nameLabel
	
	-- Rarity (adaptive)
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.94, 0, 0.1, 0)
	rarityLabel.Position = UDim2.new(0.03, 0, 0.65, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = (fishData.Rarity or "Unknown"):upper()
	rarityLabel.TextColor3 = getRarityColor(fishData.Rarity)
	rarityLabel.TextScaled = true
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	local rarityTextConstraint = Instance.new("UITextSizeConstraint")
	rarityTextConstraint.MinTextSize = 7
	rarityTextConstraint.MaxTextSize = 10
	rarityTextConstraint.Parent = rarityLabel
	
	-- Price (adaptive)
	if isDiscovered ~= false then
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.94, 0, 0.14, 0)
		priceLabel.Position = UDim2.new(0.03, 0, 0.82, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Text = isInventory and formatMoney(fishData.TotalValue or 0) or formatMoney(fishData.Price or 0)
		priceLabel.TextColor3 = COLORS.Success
		priceLabel.TextScaled = true
		priceLabel.TextXAlignment = Enum.TextXAlignment.Center
		priceLabel.Parent = card
		
		local priceTextConstraint = Instance.new("UITextSizeConstraint")
		priceTextConstraint.MinTextSize = 9
		priceTextConstraint.MaxTextSize = 13
		priceTextConstraint.Parent = priceLabel
	else
		local unknownLabel = Instance.new("TextLabel")
		unknownLabel.Size = UDim2.new(0.94, 0, 0.14, 0)
		unknownLabel.Position = UDim2.new(0.03, 0, 0.82, 0)
		unknownLabel.BackgroundTransparency = 1
		unknownLabel.Font = Enum.Font.GothamBold
		unknownLabel.Text = "???"
		unknownLabel.TextColor3 = COLORS.SubText
		unknownLabel.TextScaled = true
		unknownLabel.TextXAlignment = Enum.TextXAlignment.Center
		unknownLabel.Parent = card
		
		local unknownTextConstraint = Instance.new("UITextSizeConstraint")
		unknownTextConstraint.MinTextSize = 9
		unknownTextConstraint.MaxTextSize = 13
		unknownTextConstraint.Parent = unknownLabel
	end
	
	-- Click to hold fish (for inventory)
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
	local rarityOrder = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6}
	
	if currentSort == "Rarity" then
		table.sort(fishList, function(a, b)
			local orderA = rarityOrder[a.Rarity] or 0
			local orderB = rarityOrder[b.Rarity] or 0
			if orderA == orderB then
				return a.Name < b.Name
			end
			return orderB < orderA
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
	
	for _, fishData in ipairs(fishList) do
		createFishCard(fishData, true, true)
	end
	
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
	
	for _, fishData in ipairs(allFish) do
		createFishCard(fishData, false, fishData.IsDiscovered)
		if fishData.IsDiscovered then
			discoveredCount = discoveredCount + 1
		end
	end
	
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

print("✅ [FISH COLLECTION] Loaded (ADAPTIVE VERSION) - Press F or click button to open")
