--[[
    FISHERMAN SHOP CLIENT
    Place in StarterPlayerScripts
    
    UI for selling fish at the Fisherman Shop
    - ProximityPrompt interaction
    - Cart system with two-step confirmation
    - Filter by rarity
    - Select multiple fish to sell
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))

-- Wait for remotes
local remoteFolder = ReplicatedStorage:WaitForChild("FishermanShopRemotes", 10)
if not remoteFolder then
	warn("[FISHERMAN SHOP CLIENT] FishermanShopRemotes not found!")
	return
end

local getFishInventoryFunc = remoteFolder:WaitForChild("GetFishInventory", 5)
local sellFishEvent = remoteFolder:FindFirstChild("SellFish")
local sellAllFishEvent = remoteFolder:FindFirstChild("SellAllFish")
local sellSelectedFishEvent = remoteFolder:FindFirstChild("SellSelectedFish")
local fishSoldEvent = remoteFolder:FindFirstChild("FishSold")

-- State
local isShopOpen = false
local isCartOpen = false
local fishInventoryData = nil
local cart = {} -- {fishId = quantity}
local selectedFilter = "All"

-- Colors
local COLORS = {
	Background = Color3.fromRGB(20, 15, 10),
	CardBg = Color3.fromRGB(40, 35, 25),
	Accent = Color3.fromRGB(200, 150, 50),
	Success = Color3.fromRGB(80, 200, 120),
	Danger = Color3.fromRGB(255, 80, 80),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(180, 170, 150),
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 50, 100)
}

print("✅ [FISHERMAN SHOP CLIENT] Starting initialization...")

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
		return "$" .. tostring(amount)
	end
end

local function getCartTotal()
	local total = 0
	local count = 0
	for fishId, qty in pairs(cart) do
		local fishData = FishConfig.Fish[fishId]
		if fishData then
			total = total + (fishData.Price or 0) * qty
			count = count + qty
		end
	end
	return total, count
end

-- ==================== CREATE UI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishermanShopGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ==================== MAIN SHOP PANEL ====================

local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.Size = UDim2.new(0, 600, 0, 550)
shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.BackgroundColor3 = COLORS.Background
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = screenGui

createCorner(16).Parent = shopPanel

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = COLORS.Accent
shopStroke.Thickness = 3
shopStroke.Parent = shopPanel

-- Header
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 60)
headerFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = shopPanel

createCorner(16).Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "🐟 FISHERMAN'S MARKET"
titleLabel.TextColor3 = COLORS.Accent
titleLabel.TextSize = 26
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 45, 0, 45)
closeButton.Position = UDim2.new(1, -55, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(0, 0.5)
closeButton.BackgroundColor3 = COLORS.Danger
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Text
closeButton.TextSize = 20
closeButton.Parent = headerFrame

createCorner(10).Parent = closeButton

-- Filter Bar
local filterFrame = Instance.new("Frame")
filterFrame.Name = "FilterFrame"
filterFrame.Size = UDim2.new(1, -30, 0, 35)
filterFrame.Position = UDim2.new(0, 15, 0, 70)
filterFrame.BackgroundTransparency = 1
filterFrame.Parent = shopPanel

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0, 8)
filterLayout.Parent = filterFrame

local filterButtons = {}
local filters = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary"}

for i, filterName in ipairs(filters) do
	local btn = Instance.new("TextButton")
	btn.Name = "Filter_" .. filterName
	btn.Size = UDim2.new(0, 80, 1, 0)
	btn.BackgroundColor3 = filterName == "All" and COLORS.Accent or COLORS.CardBg
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = filterName
	btn.TextColor3 = filterName == "All" and COLORS.Text or COLORS.SubText
	btn.TextSize = 11
	btn.LayoutOrder = i
	btn.Parent = filterFrame
	
	createCorner(6).Parent = btn
	filterButtons[filterName] = btn
	
	btn.MouseButton1Click:Connect(function()
		selectedFilter = filterName
		for name, button in pairs(filterButtons) do
			button.BackgroundColor3 = name == filterName and COLORS.Accent or COLORS.CardBg
			button.TextColor3 = name == filterName and COLORS.Text or COLORS.SubText
		end
		updateShopDisplay()
	end)
end

-- Content Frame
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -30, 1, -230)
contentFrame.Position = UDim2.new(0, 15, 0, 115)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 18)
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = COLORS.Accent
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = shopPanel

createCorner(10).Parent = contentFrame

local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(0.25, -8, 0, 140)
contentGrid.CellPadding = UDim2.new(0, 8, 0, 8)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.Parent = contentFrame

-- Bottom Action Bar
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(1, -30, 0, 100)
actionBar.Position = UDim2.new(0, 15, 1, -110)
actionBar.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
actionBar.BorderSizePixel = 0
actionBar.Parent = shopPanel

createCorner(12).Parent = actionBar

-- Cart Info
local cartInfoLabel = Instance.new("TextLabel")
cartInfoLabel.Name = "CartInfo"
cartInfoLabel.Size = UDim2.new(1, -20, 0, 25)
cartInfoLabel.Position = UDim2.new(0, 10, 0, 8)
cartInfoLabel.BackgroundTransparency = 1
cartInfoLabel.Font = Enum.Font.GothamBold
cartInfoLabel.Text = "🛒 Cart: 0 fish | Total: $0"
cartInfoLabel.TextColor3 = COLORS.Accent
cartInfoLabel.TextSize = 16
cartInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
cartInfoLabel.Parent = actionBar

-- Action Buttons
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, -20, 0, 50)
btnFrame.Position = UDim2.new(0, 10, 0, 40)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = actionBar

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 10)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Parent = btnFrame

local sellAllBtn = Instance.new("TextButton")
sellAllBtn.Name = "SellAll"
sellAllBtn.Size = UDim2.new(0, 150, 1, 0)
sellAllBtn.BackgroundColor3 = COLORS.Danger
sellAllBtn.BorderSizePixel = 0
sellAllBtn.Font = Enum.Font.GothamBold
sellAllBtn.Text = "💰 SELL ALL"
sellAllBtn.TextColor3 = COLORS.Text
sellAllBtn.TextSize = 14
sellAllBtn.Parent = btnFrame

createCorner(10).Parent = sellAllBtn

local addToCartBtn = Instance.new("TextButton")
addToCartBtn.Name = "AddToCart"
addToCartBtn.Size = UDim2.new(0, 150, 1, 0)
addToCartBtn.BackgroundColor3 = COLORS.Accent
addToCartBtn.BorderSizePixel = 0
addToCartBtn.Font = Enum.Font.GothamBold
addToCartBtn.Text = "🛒 VIEW CART"
addToCartBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
addToCartBtn.TextSize = 14
addToCartBtn.Parent = btnFrame

createCorner(10).Parent = addToCartBtn

local clearCartBtn = Instance.new("TextButton")
clearCartBtn.Name = "ClearCart"
clearCartBtn.Size = UDim2.new(0, 100, 1, 0)
clearCartBtn.BackgroundColor3 = COLORS.CardBg
clearCartBtn.BorderSizePixel = 0
clearCartBtn.Font = Enum.Font.GothamBold
clearCartBtn.Text = "🗑️ CLEAR"
clearCartBtn.TextColor3 = COLORS.SubText
clearCartBtn.TextSize = 12
clearCartBtn.Parent = btnFrame

createCorner(10).Parent = clearCartBtn

-- ==================== CART PANEL ====================

local cartPanel = Instance.new("Frame")
cartPanel.Name = "CartPanel"
cartPanel.Size = UDim2.new(0, 400, 0, 450)
cartPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
cartPanel.AnchorPoint = Vector2.new(0.5, 0.5)
cartPanel.BackgroundColor3 = COLORS.Background
cartPanel.BorderSizePixel = 0
cartPanel.Visible = false
cartPanel.ZIndex = 10
cartPanel.Parent = screenGui

createCorner(16).Parent = cartPanel

local cartStroke = Instance.new("UIStroke")
cartStroke.Color = COLORS.Success
cartStroke.Thickness = 3
cartStroke.Parent = cartPanel

-- Cart Header
local cartHeader = Instance.new("Frame")
cartHeader.Size = UDim2.new(1, 0, 0, 50)
cartHeader.BackgroundColor3 = Color3.fromRGB(30, 50, 35)
cartHeader.BorderSizePixel = 0
cartHeader.ZIndex = 11
cartHeader.Parent = cartPanel

createCorner(16).Parent = cartHeader

local cartTitle = Instance.new("TextLabel")
cartTitle.Size = UDim2.new(0.7, 0, 1, 0)
cartTitle.Position = UDim2.new(0, 15, 0, 0)
cartTitle.BackgroundTransparency = 1
cartTitle.Font = Enum.Font.GothamBlack
cartTitle.Text = "🛒 SELL CART"
cartTitle.TextColor3 = COLORS.Success
cartTitle.TextSize = 20
cartTitle.TextXAlignment = Enum.TextXAlignment.Left
cartTitle.ZIndex = 11
cartTitle.Parent = cartHeader

local cartClose = Instance.new("TextButton")
cartClose.Size = UDim2.new(0, 35, 0, 35)
cartClose.Position = UDim2.new(1, -45, 0.5, 0)
cartClose.AnchorPoint = Vector2.new(0, 0.5)
cartClose.BackgroundColor3 = COLORS.Danger
cartClose.BorderSizePixel = 0
cartClose.Font = Enum.Font.GothamBold
cartClose.Text = "X"
cartClose.TextColor3 = COLORS.Text
cartClose.TextSize = 16
cartClose.ZIndex = 11
cartClose.Parent = cartHeader

createCorner(8).Parent = cartClose

-- Cart Content
local cartContent = Instance.new("ScrollingFrame")
cartContent.Name = "CartContent"
cartContent.Size = UDim2.new(1, -20, 1, -160)
cartContent.Position = UDim2.new(0, 10, 0, 60)
cartContent.BackgroundColor3 = Color3.fromRGB(25, 40, 30)
cartContent.ScrollBarThickness = 4
cartContent.ScrollBarImageColor3 = COLORS.Success
cartContent.CanvasSize = UDim2.new(0, 0, 0, 0)
cartContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
cartContent.ZIndex = 11
cartContent.Parent = cartPanel

createCorner(8).Parent = cartContent

local cartList = Instance.new("UIListLayout")
cartList.Padding = UDim.new(0, 5)
cartList.Parent = cartContent

-- Cart Total
local cartTotalFrame = Instance.new("Frame")
cartTotalFrame.Size = UDim2.new(1, -20, 0, 40)
cartTotalFrame.Position = UDim2.new(0, 10, 1, -90)
cartTotalFrame.BackgroundColor3 = Color3.fromRGB(30, 50, 35)
cartTotalFrame.ZIndex = 11
cartTotalFrame.Parent = cartPanel

createCorner(8).Parent = cartTotalFrame

local cartTotalLabel = Instance.new("TextLabel")
cartTotalLabel.Size = UDim2.new(1, -20, 1, 0)
cartTotalLabel.Position = UDim2.new(0, 10, 0, 0)
cartTotalLabel.BackgroundTransparency = 1
cartTotalLabel.Font = Enum.Font.GothamBlack
cartTotalLabel.Text = "TOTAL: $0"
cartTotalLabel.TextColor3 = COLORS.Success
cartTotalLabel.TextSize = 22
cartTotalLabel.TextXAlignment = Enum.TextXAlignment.Center
cartTotalLabel.ZIndex = 11
cartTotalLabel.Parent = cartTotalFrame

-- Cart Actions
local cartActionFrame = Instance.new("Frame")
cartActionFrame.Size = UDim2.new(1, -20, 0, 40)
cartActionFrame.Position = UDim2.new(0, 10, 1, -45)
cartActionFrame.BackgroundTransparency = 1
cartActionFrame.ZIndex = 11
cartActionFrame.Parent = cartPanel

local cartActionLayout = Instance.new("UIListLayout")
cartActionLayout.FillDirection = Enum.FillDirection.Horizontal
cartActionLayout.Padding = UDim.new(0, 10)
cartActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cartActionLayout.Parent = cartActionFrame

local confirmSellBtn = Instance.new("TextButton")
confirmSellBtn.Size = UDim2.new(0, 150, 1, 0)
confirmSellBtn.BackgroundColor3 = COLORS.Success
confirmSellBtn.BorderSizePixel = 0
confirmSellBtn.Font = Enum.Font.GothamBold
confirmSellBtn.Text = "✅ CONFIRM SELL"
confirmSellBtn.TextColor3 = COLORS.Text
confirmSellBtn.TextSize = 14
confirmSellBtn.ZIndex = 11
confirmSellBtn.Parent = cartActionFrame

createCorner(8).Parent = confirmSellBtn

local discardCartBtn = Instance.new("TextButton")
discardCartBtn.Size = UDim2.new(0, 120, 1, 0)
discardCartBtn.BackgroundColor3 = COLORS.CardBg
discardCartBtn.BorderSizePixel = 0
discardCartBtn.Font = Enum.Font.GothamBold
discardCartBtn.Text = "↩️ DISCARD"
discardCartBtn.TextColor3 = COLORS.SubText
discardCartBtn.TextSize = 12
discardCartBtn.ZIndex = 11
discardCartBtn.Parent = cartActionFrame

createCorner(8).Parent = discardCartBtn

-- ==================== FISH CARD FOR SHOP ====================

local function createShopFishCard(fishData)
	local card = Instance.new("Frame")
	card.Name = "FishCard_" .. fishData.FishId
	card.BackgroundColor3 = COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = getRarityColor(fishData.Rarity)
	cardStroke.Thickness = 2
	cardStroke.Parent = card
	
	-- Image
	local imageFrame = Instance.new("Frame")
	imageFrame.Size = UDim2.new(1, -10, 0, 55)
	imageFrame.Position = UDim2.new(0, 5, 0, 5)
	imageFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 15)
	imageFrame.Parent = card
	
	createCorner(6).Parent = imageFrame
	
	local fishImage = Instance.new("ImageLabel")
	fishImage.Size = UDim2.new(0.8, 0, 0.8, 0)
	fishImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	fishImage.AnchorPoint = Vector2.new(0.5, 0.5)
	fishImage.BackgroundTransparency = 1
	fishImage.Image = fishData.ImageID or ""
	fishImage.ScaleType = Enum.ScaleType.Fit
	fishImage.Parent = imageFrame
	
	-- Count badge
	local countBadge = Instance.new("TextLabel")
	countBadge.Size = UDim2.new(0, 30, 0, 18)
	countBadge.Position = UDim2.new(1, -5, 0, 3)
	countBadge.AnchorPoint = Vector2.new(1, 0)
	countBadge.BackgroundColor3 = COLORS.Accent
	countBadge.Font = Enum.Font.GothamBold
	countBadge.Text = "x" .. (fishData.Count or 0)
	countBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
	countBadge.TextSize = 10
	countBadge.Parent = imageFrame
	createCorner(4).Parent = countBadge
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 14)
	nameLabel.Position = UDim2.new(0, 3, 0, 62)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = fishData.Name
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 9
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	-- Price per fish
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -6, 0, 14)
	priceLabel.Position = UDim2.new(0, 3, 0, 76)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.Text = formatMoney(fishData.Price or 0) .. " each"
	priceLabel.TextColor3 = COLORS.Success
	priceLabel.TextSize = 9
	priceLabel.TextXAlignment = Enum.TextXAlignment.Center
	priceLabel.Parent = card
	
	-- Add to Cart button
	local addBtn = Instance.new("TextButton")
	addBtn.Size = UDim2.new(1, -10, 0, 30)
	addBtn.Position = UDim2.new(0, 5, 1, -35)
	addBtn.BackgroundColor3 = COLORS.Accent
	addBtn.BorderSizePixel = 0
	addBtn.Font = Enum.Font.GothamBold
	addBtn.Text = "🛒 Add to Cart"
	addBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
	addBtn.TextSize = 10
	addBtn.Parent = card
	
	createCorner(6).Parent = addBtn
	
	addBtn.MouseButton1Click:Connect(function()
		local currentInCart = cart[fishData.FishId] or 0
		local available = fishData.Count - currentInCart
		
		if available > 0 then
			cart[fishData.FishId] = currentInCart + 1
			updateCartInfo()
			
			-- Visual feedback
			TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Success}):Play()
			task.delay(0.1, function()
				TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Accent}):Play()
			end)
		end
	end)
	
	card.Parent = contentFrame
	return card
end

-- ==================== CART ITEM ====================

local function createCartItem(fishId, quantity)
	local fishData = FishConfig.Fish[fishId]
	if not fishData then return nil end
	
	local item = Instance.new("Frame")
	item.Name = "CartItem_" .. fishId
	item.Size = UDim2.new(1, -10, 0, 40)
	item.BackgroundColor3 = Color3.fromRGB(35, 55, 40)
	item.ZIndex = 12
	item.Parent = cartContent
	
	createCorner(6).Parent = item
	
	-- Fish name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = string.format("%s (x%d)", fishData.Name, quantity)
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = item
	
	-- Value
	local value = (fishData.Price or 0) * quantity
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = formatMoney(value)
	valueLabel.TextColor3 = COLORS.Success
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 12
	valueLabel.Parent = item
	
	-- Remove button
	local removeBtn = Instance.new("TextButton")
	removeBtn.Size = UDim2.new(0, 30, 0, 30)
	removeBtn.Position = UDim2.new(1, -35, 0.5, 0)
	removeBtn.AnchorPoint = Vector2.new(0, 0.5)
	removeBtn.BackgroundColor3 = COLORS.Danger
	removeBtn.BorderSizePixel = 0
	removeBtn.Font = Enum.Font.GothamBold
	removeBtn.Text = "X"
	removeBtn.TextColor3 = COLORS.Text
	removeBtn.TextSize = 12
	removeBtn.ZIndex = 12
	removeBtn.Parent = item
	
	createCorner(5).Parent = removeBtn
	
	removeBtn.MouseButton1Click:Connect(function()
		cart[fishId] = nil
		updateCartDisplay()
		updateCartInfo()
	end)
	
	return item
end

-- ==================== DISPLAY FUNCTIONS ====================

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function clearCartContent()
	for _, child in ipairs(cartContent:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

function updateShopDisplay()
	clearContent()
	
	if not fishInventoryData or not fishInventoryData.FishList then return end
	
	for _, fishData in ipairs(fishInventoryData.FishList) do
		-- Filter
		if selectedFilter == "All" or fishData.Rarity == selectedFilter then
			createShopFishCard(fishData)
		end
	end
end

function updateCartInfo()
	local total, count = getCartTotal()
	cartInfoLabel.Text = string.format("🛒 Cart: %d fish | Total: %s", count, formatMoney(total))
end

function updateCartDisplay()
	clearCartContent()
	
	local total = 0
	for fishId, qty in pairs(cart) do
		if qty > 0 then
			createCartItem(fishId, qty)
			local fishData = FishConfig.Fish[fishId]
			if fishData then
				total = total + (fishData.Price or 0) * qty
			end
		end
	end
	
	cartTotalLabel.Text = "TOTAL: " .. formatMoney(total)
end

local function fetchInventory()
	if not getFishInventoryFunc then return end
	
	local success, data = pcall(function()
		return getFishInventoryFunc:InvokeServer()
	end)
	
	if success and data then
		fishInventoryData = data
		updateShopDisplay()
	end
end

-- ==================== SHOP OPEN/CLOSE ====================

local function openShop()
	isShopOpen = true
	shopPanel.Visible = true
	cart = {}
	fetchInventory()
	updateCartInfo()
end

local function closeShop()
	isShopOpen = false
	shopPanel.Visible = false
	cartPanel.Visible = false
	isCartOpen = false
end

closeButton.MouseButton1Click:Connect(closeShop)
cartClose.MouseButton1Click:Connect(function()
	cartPanel.Visible = false
	isCartOpen = false
end)

-- ==================== CART ACTIONS ====================

addToCartBtn.MouseButton1Click:Connect(function()
	updateCartDisplay()
	cartPanel.Visible = true
	isCartOpen = true
end)

clearCartBtn.MouseButton1Click:Connect(function()
	cart = {}
	updateCartInfo()
	updateCartDisplay()
end)

discardCartBtn.MouseButton1Click:Connect(function()
	cart = {}
	updateCartInfo()
	updateCartDisplay()
	cartPanel.Visible = false
	isCartOpen = false
end)

confirmSellBtn.MouseButton1Click:Connect(function()
	local _, count = getCartTotal()
	if count > 0 and sellSelectedFishEvent then
		sellSelectedFishEvent:FireServer(cart)
		cart = {}
		updateCartInfo()
		cartPanel.Visible = false
		isCartOpen = false
		task.delay(0.5, fetchInventory)
	end
end)

sellAllBtn.MouseButton1Click:Connect(function()
	if sellAllFishEvent then
		sellAllFishEvent:FireServer()
		cart = {}
		updateCartInfo()
		task.delay(0.5, fetchInventory)
	end
end)

-- ==================== PROXIMITY PROMPT SETUP ====================

local function setupProximityPrompt()
	local fishermanShop = workspace:FindFirstChild("FishermanShop")
	
	if not fishermanShop then
		warn("[FISHERMAN SHOP CLIENT] FishermanShop part not found in Workspace!")
		-- Try again later
		task.delay(5, setupProximityPrompt)
		return
	end
	
	-- Find or create proximity prompt
	local prompt = fishermanShop:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Fisherman's Market"
		prompt.ActionText = "Sell Fish"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = fishermanShop
	end
	
	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			openShop()
		end
	end)
	
	print("✅ [FISHERMAN SHOP CLIENT] Proximity prompt setup complete!")
end

-- ==================== AUTO-REFRESH ====================

if fishSoldEvent then
	fishSoldEvent.OnClientEvent:Connect(function(data)
		print("🔄 [FISHERMAN SHOP] Fish sold, refreshing...")
		task.delay(0.5, fetchInventory)
	end)
end

-- ==================== INITIALIZE ====================

task.spawn(setupProximityPrompt)

print("✅ [FISHERMAN SHOP CLIENT] Loaded - Go to FishermanShop to sell fish!")
