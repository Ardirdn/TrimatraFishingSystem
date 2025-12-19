--[[
    FISHERMAN SHOP CLIENT
    Place in StarterPlayerScripts
    
    UI for selling fish at the Fisherman Shop
    - ProximityPrompt interaction
    - Cart system with quantity slider
    - Fish disappears from list when added to cart
    - Two-step confirmation
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))

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
local isQuantityPopupOpen = false
local fishInventoryData = nil
local cart = {} -- {fishId = quantity}
local selectedFilter = "All"
local currentSelectingFish = nil

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

local function getAvailableFishCount(fishId)
	if not fishInventoryData or not fishInventoryData.FishList then return 0 end
	for _, fish in ipairs(fishInventoryData.FishList) do
		if fish.FishId == fishId then
			local inCart = cart[fishId] or 0
			return math.max(0, fish.Count - inCart)
		end
	end
	return 0
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
shopPanel.Size = UDim2.new(0.55, 0, 0.85, 0)
shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.BackgroundColor3 = COLORS.Background
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = screenGui

-- AspectRatio based on Width
local shopAspect = Instance.new("UIAspectRatioConstraint")
shopAspect.AspectRatio = 0.9
shopAspect.DominantAxis = Enum.DominantAxis.Width
shopAspect.Parent = shopPanel

createCorner(16).Parent = shopPanel

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = COLORS.Warning
shopStroke.Thickness = 2
shopStroke.Parent = shopPanel

-- Main Panel Padding
local shopPadding = Instance.new("UIPadding")
shopPadding.PaddingTop = UDim.new(0.015, 0)
shopPadding.PaddingBottom = UDim.new(0.015, 0)
shopPadding.PaddingLeft = UDim.new(0.025, 0)
shopPadding.PaddingRight = UDim.new(0.025, 0)
shopPadding.Parent = shopPanel

-- Header
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0.07, 0)
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = shopPanel

createCorner(12).Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.75, 0, 0.7, 0)
titleLabel.Position = UDim2.new(0.025, 0, 0.15, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "🐟 FISHERMAN'S MARKET"
titleLabel.TextColor3 = COLORS.Warning
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local titleTextConstraint = Instance.new("UITextSizeConstraint")
titleTextConstraint.MaxTextSize = 24
titleTextConstraint.Parent = titleLabel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.07, 0, 0.7, 0)
closeButton.Position = UDim2.new(0.92, 0, 0.15, 0)
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

-- Filter Bar
local filterFrame = Instance.new("Frame")
filterFrame.Name = "FilterFrame"
filterFrame.Size = UDim2.new(1, 0, 0.045, 0)
filterFrame.Position = UDim2.new(0, 0, 0.085, 0)
filterFrame.BackgroundTransparency = 1
filterFrame.Parent = shopPanel

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0.01, 0)
filterLayout.Parent = filterFrame

local filterButtons = {}
local filters = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary"}

for i, filterName in ipairs(filters) do
	local btn = Instance.new("TextButton")
	btn.Name = "Filter_" .. filterName
	btn.Size = UDim2.new(0.12, 0, 1, 0)
	btn.BackgroundColor3 = filterName == "All" and COLORS.Accent or COLORS.CardBg
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = filterName
	btn.TextColor3 = filterName == "All" and COLORS.Text or COLORS.SubText
	btn.TextScaled = true
	btn.LayoutOrder = i
	btn.Parent = filterFrame
	
	local btnTextConstraint = Instance.new("UITextSizeConstraint")
	btnTextConstraint.MaxTextSize = 12
	btnTextConstraint.Parent = btn
	
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
contentFrame.Size = UDim2.new(1, 0, 0.62, 0)
contentFrame.Position = UDim2.new(0, 0, 0.14, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = COLORS.Warning
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = shopPanel

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0.01, 0)
contentPadding.PaddingBottom = UDim.new(0.01, 0)
contentPadding.PaddingLeft = UDim.new(0.01, 0)
contentPadding.PaddingRight = UDim.new(0.01, 0)
contentPadding.Parent = contentFrame

local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(0.23, 0, 0, 130)
contentGrid.CellPadding = UDim2.new(0.015, 0, 0.015, 0)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = contentFrame

-- Bottom Action Bar
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(1, 0, 0.14, 0)
actionBar.Position = UDim2.new(0, 0, 0.84, 0)
actionBar.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
actionBar.BorderSizePixel = 0
actionBar.Parent = shopPanel

createCorner(10).Parent = actionBar

local actionPadding = Instance.new("UIPadding")
actionPadding.PaddingTop = UDim.new(0.08, 0)
actionPadding.PaddingBottom = UDim.new(0.08, 0)
actionPadding.PaddingLeft = UDim.new(0.02, 0)
actionPadding.PaddingRight = UDim.new(0.02, 0)
actionPadding.Parent = actionBar

-- Cart Info
local cartInfoLabel = Instance.new("TextLabel")
cartInfoLabel.Name = "CartInfo"
cartInfoLabel.Size = UDim2.new(1, 0, 0.35, 0)
cartInfoLabel.Position = UDim2.new(0, 0, 0, 0)
cartInfoLabel.BackgroundTransparency = 1
cartInfoLabel.Font = Enum.Font.GothamBold
cartInfoLabel.Text = "🛒 Cart: 0 fish | Total: $0"
cartInfoLabel.TextColor3 = COLORS.Warning
cartInfoLabel.TextScaled = true
cartInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
cartInfoLabel.Parent = actionBar

local cartInfoTextConstraint = Instance.new("UITextSizeConstraint")
cartInfoTextConstraint.MaxTextSize = 16
cartInfoTextConstraint.Parent = cartInfoLabel

-- Action Buttons
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, 0, 0.55, 0)
btnFrame.Position = UDim2.new(0, 0, 0.4, 0)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = actionBar

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0.02, 0)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Parent = btnFrame

local clearCartBtn = Instance.new("TextButton")
clearCartBtn.Name = "ClearCart"
clearCartBtn.Size = UDim2.new(0.2, 0, 1, 0)
clearCartBtn.BackgroundColor3 = COLORS.CardBg
clearCartBtn.BorderSizePixel = 0
clearCartBtn.Font = Enum.Font.GothamBold
clearCartBtn.Text = "🗑️ CLEAR"
clearCartBtn.TextColor3 = COLORS.SubText
clearCartBtn.TextScaled = true
clearCartBtn.LayoutOrder = 1
clearCartBtn.Parent = btnFrame

local clearTextConstraint = Instance.new("UITextSizeConstraint")
clearTextConstraint.MaxTextSize = 14
clearTextConstraint.Parent = clearCartBtn

createCorner(8).Parent = clearCartBtn

local sellAllBtn = Instance.new("TextButton")
sellAllBtn.Name = "SellAll"
sellAllBtn.Size = UDim2.new(0.35, 0, 1, 0)
sellAllBtn.BackgroundColor3 = COLORS.Danger
sellAllBtn.BorderSizePixel = 0
sellAllBtn.Font = Enum.Font.GothamBold
sellAllBtn.Text = "💰 SELL ALL"
sellAllBtn.TextColor3 = COLORS.Text
sellAllBtn.TextScaled = true
sellAllBtn.LayoutOrder = 2
sellAllBtn.Parent = btnFrame

local sellAllTextConstraint = Instance.new("UITextSizeConstraint")
sellAllTextConstraint.MaxTextSize = 14
sellAllTextConstraint.Parent = sellAllBtn

createCorner(8).Parent = sellAllBtn

local viewCartBtn = Instance.new("TextButton")
viewCartBtn.Name = "ViewCart"
viewCartBtn.Size = UDim2.new(0.35, 0, 1, 0)
viewCartBtn.BackgroundColor3 = COLORS.Success
viewCartBtn.BorderSizePixel = 0
viewCartBtn.Font = Enum.Font.GothamBold
viewCartBtn.Text = "🛒 VIEW CART"
viewCartBtn.TextColor3 = COLORS.Text
viewCartBtn.TextScaled = true
viewCartBtn.LayoutOrder = 3
viewCartBtn.Parent = btnFrame

local viewCartTextConstraint = Instance.new("UITextSizeConstraint")
viewCartTextConstraint.MaxTextSize = 14
viewCartTextConstraint.Parent = viewCartBtn

createCorner(8).Parent = viewCartBtn

-- ==================== QUANTITY POPUP ====================

local quantityPopup = Instance.new("Frame")
quantityPopup.Name = "QuantityPopup"
quantityPopup.Size = UDim2.new(0.35, 0, 0.35, 0)
quantityPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
quantityPopup.AnchorPoint = Vector2.new(0.5, 0.5)
quantityPopup.BackgroundColor3 = COLORS.Background
quantityPopup.BorderSizePixel = 0
quantityPopup.Visible = false
quantityPopup.ZIndex = 20
quantityPopup.Parent = screenGui

local quantityAspect = Instance.new("UIAspectRatioConstraint")
quantityAspect.AspectRatio = 1.5
quantityAspect.DominantAxis = Enum.DominantAxis.Width
quantityAspect.Parent = quantityPopup

createCorner(12).Parent = quantityPopup

local quantityStroke = Instance.new("UIStroke")
quantityStroke.Color = COLORS.Accent
quantityStroke.Thickness = 2
quantityStroke.Parent = quantityPopup

local quantityPadding = Instance.new("UIPadding")
quantityPadding.PaddingTop = UDim.new(0.03, 0)
quantityPadding.PaddingBottom = UDim.new(0.05, 0)
quantityPadding.PaddingLeft = UDim.new(0.05, 0)
quantityPadding.PaddingRight = UDim.new(0.05, 0)
quantityPadding.Parent = quantityPopup

local quantityTitle = Instance.new("TextLabel")
quantityTitle.Size = UDim2.new(1, 0, 0.18, 0)
quantityTitle.Position = UDim2.new(0, 0, 0, 0)
quantityTitle.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
quantityTitle.Font = Enum.Font.GothamBold
quantityTitle.Text = "Select Quantity"
quantityTitle.TextColor3 = COLORS.Text
quantityTitle.TextScaled = true
quantityTitle.ZIndex = 21
quantityTitle.Parent = quantityPopup

local quantityTitleTextConstraint = Instance.new("UITextSizeConstraint")
quantityTitleTextConstraint.MaxTextSize = 18
quantityTitleTextConstraint.Parent = quantityTitle

createCorner(8).Parent = quantityTitle

local quantityCloseBtn = Instance.new("TextButton")
quantityCloseBtn.Size = UDim2.new(0.12, 0, 0.14, 0)
quantityCloseBtn.Position = UDim2.new(0.88, 0, 0.02, 0)
quantityCloseBtn.BackgroundColor3 = COLORS.Danger
quantityCloseBtn.BorderSizePixel = 0
quantityCloseBtn.Font = Enum.Font.GothamBold
quantityCloseBtn.Text = "X"
quantityCloseBtn.TextColor3 = COLORS.Text
quantityCloseBtn.TextScaled = true
quantityCloseBtn.ZIndex = 22
quantityCloseBtn.Parent = quantityPopup

local quantityCloseBtnAspect = Instance.new("UIAspectRatioConstraint")
quantityCloseBtnAspect.AspectRatio = 1
quantityCloseBtnAspect.Parent = quantityCloseBtn

local quantityCloseTextConstraint = Instance.new("UITextSizeConstraint")
quantityCloseTextConstraint.MaxTextSize = 16
quantityCloseTextConstraint.Parent = quantityCloseBtn

createCorner(6).Parent = quantityCloseBtn

-- Fish info in popup
local popupFishName = Instance.new("TextLabel")
popupFishName.Size = UDim2.new(1, 0, 0.12, 0)
popupFishName.Position = UDim2.new(0, 0, 0.2, 0)
popupFishName.BackgroundTransparency = 1
popupFishName.Font = Enum.Font.GothamBold
popupFishName.Text = "Fish Name"
popupFishName.TextColor3 = COLORS.Text
popupFishName.TextScaled = true
popupFishName.TextXAlignment = Enum.TextXAlignment.Left
popupFishName.ZIndex = 21
popupFishName.Parent = quantityPopup

local popupFishNameTextConstraint = Instance.new("UITextSizeConstraint")
popupFishNameTextConstraint.MaxTextSize = 16
popupFishNameTextConstraint.Parent = popupFishName

local popupAvailable = Instance.new("TextLabel")
popupAvailable.Size = UDim2.new(1, 0, 0.1, 0)
popupAvailable.Position = UDim2.new(0, 0, 0.32, 0)
popupAvailable.BackgroundTransparency = 1
popupAvailable.Font = Enum.Font.Gotham
popupAvailable.Text = "Available: 0"
popupAvailable.TextColor3 = COLORS.SubText
popupAvailable.TextScaled = true
popupAvailable.TextXAlignment = Enum.TextXAlignment.Left
popupAvailable.ZIndex = 21
popupAvailable.Parent = quantityPopup

local popupAvailableTextConstraint = Instance.new("UITextSizeConstraint")
popupAvailableTextConstraint.MaxTextSize = 13
popupAvailableTextConstraint.Parent = popupAvailable

-- Slider
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(1, 0, 0.1, 0)
sliderFrame.Position = UDim2.new(0, 0, 0.45, 0)
sliderFrame.BackgroundColor3 = COLORS.CardBg
sliderFrame.ZIndex = 21
sliderFrame.Parent = quantityPopup

createCorner(10).Parent = sliderFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = COLORS.Accent
sliderFill.ZIndex = 22
sliderFill.Parent = sliderFrame

createCorner(10).Parent = sliderFill

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0.08, 0, 1.2, 0)
sliderKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.BackgroundColor3 = COLORS.Text
sliderKnob.BorderSizePixel = 0
sliderKnob.Text = ""
sliderKnob.ZIndex = 23
sliderKnob.Parent = sliderFrame

local sliderKnobAspect = Instance.new("UIAspectRatioConstraint")
sliderKnobAspect.AspectRatio = 1
sliderKnobAspect.Parent = sliderKnob

createCorner(12).Parent = sliderKnob

-- Quantity display
local quantityDisplay = Instance.new("TextLabel")
quantityDisplay.Size = UDim2.new(1, 0, 0.12, 0)
quantityDisplay.Position = UDim2.new(0, 0, 0.58, 0)
quantityDisplay.BackgroundTransparency = 1
quantityDisplay.Font = Enum.Font.GothamBlack
quantityDisplay.Text = "Quantity: 1"
quantityDisplay.TextColor3 = COLORS.Warning
quantityDisplay.TextScaled = true
quantityDisplay.ZIndex = 21
quantityDisplay.Parent = quantityPopup

local quantityDisplayTextConstraint = Instance.new("UITextSizeConstraint")
quantityDisplayTextConstraint.MaxTextSize = 20
quantityDisplayTextConstraint.Parent = quantityDisplay

-- Bottom buttons row
local popupBtnFrame = Instance.new("Frame")
popupBtnFrame.Size = UDim2.new(1, 0, 0.18, 0)
popupBtnFrame.Position = UDim2.new(0, 0, 0.75, 0)
popupBtnFrame.BackgroundTransparency = 1
popupBtnFrame.ZIndex = 21
popupBtnFrame.Parent = quantityPopup

local popupBtnLayout = Instance.new("UIListLayout")
popupBtnLayout.FillDirection = Enum.FillDirection.Horizontal
popupBtnLayout.Padding = UDim.new(0.03, 0)
popupBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
popupBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
popupBtnLayout.Parent = popupBtnFrame

-- Max button
local maxBtn = Instance.new("TextButton")
maxBtn.Size = UDim2.new(0.25, 0, 1, 0)
maxBtn.BackgroundColor3 = COLORS.Accent
maxBtn.BorderSizePixel = 0
maxBtn.Font = Enum.Font.GothamBold
maxBtn.Text = "MAX"
maxBtn.TextColor3 = COLORS.Text
maxBtn.TextScaled = true
maxBtn.ZIndex = 21
maxBtn.LayoutOrder = 1
maxBtn.Parent = popupBtnFrame

local maxBtnTextConstraint = Instance.new("UITextSizeConstraint")
maxBtnTextConstraint.MaxTextSize = 14
maxBtnTextConstraint.Parent = maxBtn

createCorner(6).Parent = maxBtn

-- Add to cart button in popup
local popupAddBtn = Instance.new("TextButton")
popupAddBtn.Size = UDim2.new(0.55, 0, 1, 0)
popupAddBtn.BackgroundColor3 = COLORS.Success
popupAddBtn.BorderSizePixel = 0
popupAddBtn.Font = Enum.Font.GothamBold
popupAddBtn.Text = "🛒 ADD TO CART"
popupAddBtn.TextColor3 = COLORS.Text
popupAddBtn.TextScaled = true
popupAddBtn.ZIndex = 21
popupAddBtn.LayoutOrder = 2
popupAddBtn.Parent = popupBtnFrame

local popupAddBtnTextConstraint = Instance.new("UITextSizeConstraint")
popupAddBtnTextConstraint.MaxTextSize = 14
popupAddBtnTextConstraint.Parent = popupAddBtn

createCorner(6).Parent = popupAddBtn

-- Slider logic
local selectedQuantity = 1
local maxQuantity = 1
local isDraggingSlider = false

local function updateSliderVisual(percent)
	percent = math.clamp(percent, 0, 1)
	sliderFill.Size = UDim2.new(percent, 0, 1, 0)
	sliderKnob.Position = UDim2.new(percent, 0, 0.5, 0)
	selectedQuantity = math.max(1, math.floor(percent * maxQuantity + 0.5))
	quantityDisplay.Text = "Quantity: " .. selectedQuantity
end

sliderKnob.MouseButton1Down:Connect(function()
	isDraggingSlider = true
end)

sliderFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingSlider = true
		local relX = (input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X
		updateSliderVisual(relX)
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		local relX = (input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X
		updateSliderVisual(relX)
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingSlider = false
	end
end)

maxBtn.MouseButton1Click:Connect(function()
	updateSliderVisual(1)
end)

quantityCloseBtn.MouseButton1Click:Connect(function()
	quantityPopup.Visible = false
	isQuantityPopupOpen = false
end)

-- ==================== CART PANEL ====================

local cartPanel = Instance.new("Frame")
cartPanel.Name = "CartPanel"
cartPanel.Size = UDim2.new(0.4, 0, 0.65, 0)
cartPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
cartPanel.AnchorPoint = Vector2.new(0.5, 0.5)
cartPanel.BackgroundColor3 = COLORS.Background
cartPanel.BorderSizePixel = 0
cartPanel.Visible = false
cartPanel.ZIndex = 10
cartPanel.Parent = screenGui

local cartAspect = Instance.new("UIAspectRatioConstraint")
cartAspect.AspectRatio = 0.9
cartAspect.DominantAxis = Enum.DominantAxis.Width
cartAspect.Parent = cartPanel

createCorner(16).Parent = cartPanel

local cartStroke = Instance.new("UIStroke")
cartStroke.Color = COLORS.Success
cartStroke.Thickness = 2
cartStroke.Parent = cartPanel

local cartMainPadding = Instance.new("UIPadding")
cartMainPadding.PaddingTop = UDim.new(0.02, 0)
cartMainPadding.PaddingBottom = UDim.new(0.02, 0)
cartMainPadding.PaddingLeft = UDim.new(0.03, 0)
cartMainPadding.PaddingRight = UDim.new(0.03, 0)
cartMainPadding.Parent = cartPanel

-- Cart Header
local cartHeader = Instance.new("Frame")
cartHeader.Size = UDim2.new(1, 0, 0.1, 0)
cartHeader.Position = UDim2.new(0, 0, 0, 0)
cartHeader.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
cartHeader.BorderSizePixel = 0
cartHeader.ZIndex = 11
cartHeader.Parent = cartPanel

createCorner(12).Parent = cartHeader

local cartTitle = Instance.new("TextLabel")
cartTitle.Size = UDim2.new(0.75, 0, 0.7, 0)
cartTitle.Position = UDim2.new(0.03, 0, 0.15, 0)
cartTitle.BackgroundTransparency = 1
cartTitle.Font = Enum.Font.GothamBlack
cartTitle.Text = "🛒 SELL CART"
cartTitle.TextColor3 = COLORS.Success
cartTitle.TextScaled = true
cartTitle.TextXAlignment = Enum.TextXAlignment.Left
cartTitle.ZIndex = 11
cartTitle.Parent = cartHeader

local cartTitleTextConstraint = Instance.new("UITextSizeConstraint")
cartTitleTextConstraint.MaxTextSize = 22
cartTitleTextConstraint.Parent = cartTitle

local cartClose = Instance.new("TextButton")
cartClose.Size = UDim2.new(0.1, 0, 0.7, 0)
cartClose.Position = UDim2.new(0.88, 0, 0.15, 0)
cartClose.BackgroundColor3 = COLORS.Danger
cartClose.BorderSizePixel = 0
cartClose.Font = Enum.Font.GothamBold
cartClose.Text = "X"
cartClose.TextColor3 = COLORS.Text
cartClose.TextScaled = true
cartClose.ZIndex = 11
cartClose.Parent = cartHeader

local cartCloseAspect = Instance.new("UIAspectRatioConstraint")
cartCloseAspect.AspectRatio = 1
cartCloseAspect.Parent = cartClose

local cartCloseTextConstraint = Instance.new("UITextSizeConstraint")
cartCloseTextConstraint.MaxTextSize = 16
cartCloseTextConstraint.Parent = cartClose

createCorner(8).Parent = cartClose

-- Cart Content
local cartContent = Instance.new("ScrollingFrame")
cartContent.Name = "CartContent"
cartContent.Size = UDim2.new(1, 0, 0.6, 0)
cartContent.Position = UDim2.new(0, 0, 0.12, 0)
cartContent.BackgroundColor3 = COLORS.CardBgDark
cartContent.ScrollBarThickness = 4
cartContent.ScrollBarImageColor3 = COLORS.Success
cartContent.CanvasSize = UDim2.new(0, 0, 0, 0)
cartContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
cartContent.ZIndex = 11
cartContent.Parent = cartPanel

createCorner(8).Parent = cartContent

local cartList = Instance.new("UIListLayout")
cartList.Padding = UDim.new(0.01, 0)
cartList.Parent = cartContent

local cartPadding = Instance.new("UIPadding")
cartPadding.PaddingTop = UDim.new(0.02, 0)
cartPadding.PaddingLeft = UDim.new(0.02, 0)
cartPadding.PaddingRight = UDim.new(0.02, 0)
cartPadding.PaddingBottom = UDim.new(0.02, 0)
cartPadding.Parent = cartContent

-- Cart Total
local cartTotalFrame = Instance.new("Frame")
cartTotalFrame.Size = UDim2.new(1, 0, 0.09, 0)
cartTotalFrame.Position = UDim2.new(0, 0, 0.74, 0)
cartTotalFrame.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
cartTotalFrame.ZIndex = 11
cartTotalFrame.Parent = cartPanel

createCorner(8).Parent = cartTotalFrame

local cartTotalLabel = Instance.new("TextLabel")
cartTotalLabel.Size = UDim2.new(0.94, 0, 0.8, 0)
cartTotalLabel.Position = UDim2.new(0.03, 0, 0.1, 0)
cartTotalLabel.BackgroundTransparency = 1
cartTotalLabel.Font = Enum.Font.GothamBlack
cartTotalLabel.Text = "TOTAL: $0"
cartTotalLabel.TextColor3 = COLORS.Success
cartTotalLabel.TextScaled = true
cartTotalLabel.TextXAlignment = Enum.TextXAlignment.Center
cartTotalLabel.ZIndex = 11
cartTotalLabel.Parent = cartTotalFrame

local cartTotalTextConstraint = Instance.new("UITextSizeConstraint")
cartTotalTextConstraint.MaxTextSize = 22
cartTotalTextConstraint.Parent = cartTotalLabel

-- Cart Actions
local cartActionFrame = Instance.new("Frame")
cartActionFrame.Size = UDim2.new(1, 0, 0.1, 0)
cartActionFrame.Position = UDim2.new(0, 0, 0.86, 0)
cartActionFrame.BackgroundTransparency = 1
cartActionFrame.ZIndex = 11
cartActionFrame.Parent = cartPanel

local cartActionLayout = Instance.new("UIListLayout")
cartActionLayout.FillDirection = Enum.FillDirection.Horizontal
cartActionLayout.Padding = UDim.new(0.02, 0)
cartActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cartActionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cartActionLayout.Parent = cartActionFrame

local confirmSellBtn = Instance.new("TextButton")
confirmSellBtn.Size = UDim2.new(0.55, 0, 1, 0)
confirmSellBtn.BackgroundColor3 = COLORS.Success
confirmSellBtn.BorderSizePixel = 0
confirmSellBtn.Font = Enum.Font.GothamBold
confirmSellBtn.Text = "✅ CONFIRM SELL"
confirmSellBtn.TextColor3 = COLORS.Text
confirmSellBtn.TextScaled = true
confirmSellBtn.ZIndex = 11
confirmSellBtn.LayoutOrder = 1
confirmSellBtn.Parent = cartActionFrame

local confirmSellTextConstraint = Instance.new("UITextSizeConstraint")
confirmSellTextConstraint.MaxTextSize = 14
confirmSellTextConstraint.Parent = confirmSellBtn

createCorner(8).Parent = confirmSellBtn

local discardCartBtn = Instance.new("TextButton")
discardCartBtn.Size = UDim2.new(0.35, 0, 1, 0)
discardCartBtn.BackgroundColor3 = COLORS.CardBg
discardCartBtn.BorderSizePixel = 0
discardCartBtn.Font = Enum.Font.GothamBold
discardCartBtn.Text = "↩️ DISCARD"
discardCartBtn.TextColor3 = COLORS.SubText
discardCartBtn.TextScaled = true
discardCartBtn.ZIndex = 11
discardCartBtn.LayoutOrder = 2
discardCartBtn.Parent = cartActionFrame

local discardTextConstraint = Instance.new("UITextSizeConstraint")
discardTextConstraint.MaxTextSize = 14
discardTextConstraint.Parent = discardCartBtn

createCorner(8).Parent = discardCartBtn

-- ==================== FISH CARD FOR SHOP (SAME STYLE AS FISH COLLECTION) ====================

local function createShopFishCard(fishData)
	local available = getAvailableFishCount(fishData.FishId)
	
	-- Skip if all fish are in cart
	if available <= 0 then return nil end
	
	local card = Instance.new("Frame")
	card.Name = "FishCard_" .. fishData.FishId
	card.BackgroundColor3 = COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = getRarityColor(fishData.Rarity)
	cardStroke.Thickness = 2
	cardStroke.Parent = card
	
	-- Image Container (SAME AS FISH COLLECTION)
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(1, -10, 0, 50)
	imageContainer.Position = UDim2.new(0, 5, 0, 5)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	local fishImage = Instance.new("ImageLabel")
	fishImage.Size = UDim2.new(0.7, 0, 0.85, 0)
	fishImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	fishImage.AnchorPoint = Vector2.new(0.5, 0.5)
	fishImage.BackgroundTransparency = 1
	fishImage.Image = fishData.ImageID or ""
	fishImage.ScaleType = Enum.ScaleType.Fit
	fishImage.Parent = imageContainer
	
	-- Count badge
	local countBadge = Instance.new("TextLabel")
	countBadge.Size = UDim2.new(0, 30, 0, 16)
	countBadge.Position = UDim2.new(1, -3, 0, 3)
	countBadge.AnchorPoint = Vector2.new(1, 0)
	countBadge.BackgroundColor3 = COLORS.Warning
	countBadge.Font = Enum.Font.GothamBold
	countBadge.Text = "x" .. available
	countBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
	countBadge.TextSize = 9
	countBadge.Parent = imageContainer
	createCorner(4).Parent = countBadge
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 14)
	nameLabel.Position = UDim2.new(0, 3, 0, 58)
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
	priceLabel.Size = UDim2.new(1, -6, 0, 12)
	priceLabel.Position = UDim2.new(0, 3, 0, 72)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.Text = formatMoney(fishData.Price or 0) .. " each"
	priceLabel.TextColor3 = COLORS.Success
	priceLabel.TextSize = 9
	priceLabel.TextXAlignment = Enum.TextXAlignment.Center
	priceLabel.Parent = card
	
	-- Button container
	local btnContainer = Instance.new("Frame")
	btnContainer.Size = UDim2.new(1, -10, 0, 28)
	btnContainer.Position = UDim2.new(0, 5, 1, -32)
	btnContainer.BackgroundTransparency = 1
	btnContainer.Parent = card
	
	-- Quick add (add 1)
	local quickAddBtn = Instance.new("TextButton")
	quickAddBtn.Size = UDim2.new(0.65, -2, 1, 0)
	quickAddBtn.Position = UDim2.new(0, 0, 0, 0)
	quickAddBtn.BackgroundColor3 = COLORS.Accent
	quickAddBtn.BorderSizePixel = 0
	quickAddBtn.Font = Enum.Font.GothamBold
	quickAddBtn.Text = "🛒 +1"
	quickAddBtn.TextColor3 = COLORS.Text
	quickAddBtn.TextSize = 10
	quickAddBtn.Parent = btnContainer
	
	createCorner(5).Parent = quickAddBtn
	
	-- Quantity select button
	local qtyBtn = Instance.new("TextButton")
	qtyBtn.Size = UDim2.new(0.35, -2, 1, 0)
	qtyBtn.Position = UDim2.new(0.65, 2, 0, 0)
	qtyBtn.BackgroundColor3 = COLORS.Warning
	qtyBtn.BorderSizePixel = 0
	qtyBtn.Font = Enum.Font.GothamBold
	qtyBtn.Text = "..."
	qtyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	qtyBtn.TextSize = 14
	qtyBtn.Parent = btnContainer
	
	createCorner(5).Parent = qtyBtn
	
	-- Quick add click
	quickAddBtn.MouseButton1Click:Connect(function()
		local currentAvailable = getAvailableFishCount(fishData.FishId)
		if currentAvailable > 0 then
			cart[fishData.FishId] = (cart[fishData.FishId] or 0) + 1
			updateCartInfo()
			updateShopDisplay() -- Refresh to update counts/hide cards
			
			-- Flash feedback
			TweenService:Create(quickAddBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Success}):Play()
			task.delay(0.1, function()
				if quickAddBtn.Parent then
					TweenService:Create(quickAddBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Accent}):Play()
				end
			end)
		end
	end)
	
	-- Quantity select click
	qtyBtn.MouseButton1Click:Connect(function()
		local currentAvailable = getAvailableFishCount(fishData.FishId)
		if currentAvailable > 0 then
			currentSelectingFish = fishData.FishId
			maxQuantity = currentAvailable
			selectedQuantity = 1
			
			popupFishName.Text = fishData.Name
			popupAvailable.Text = "Available: " .. currentAvailable .. " (Price: " .. formatMoney(fishData.Price or 0) .. " each)"
			updateSliderVisual(1 / maxQuantity)
			
			quantityPopup.Visible = true
			isQuantityPopupOpen = true
		end
	end)
	
	card.Parent = contentFrame
	return card
end

-- Popup add to cart
popupAddBtn.MouseButton1Click:Connect(function()
	if currentSelectingFish and selectedQuantity > 0 then
		cart[currentSelectingFish] = (cart[currentSelectingFish] or 0) + selectedQuantity
		updateCartInfo()
		updateShopDisplay()
		
		quantityPopup.Visible = false
		isQuantityPopupOpen = false
		currentSelectingFish = nil
	end
end)

-- ==================== CART ITEM ====================

local function createCartItem(fishId, quantity)
	local fishData = FishConfig.Fish[fishId]
	if not fishData then return nil end
	
	local item = Instance.new("Frame")
	item.Name = "CartItem_" .. fishId
	item.Size = UDim2.new(1, -10, 0, 45)
	item.BackgroundColor3 = COLORS.CardBg
	item.ZIndex = 12
	item.Parent = cartContent
	
	createCorner(6).Parent = item
	
	-- Fish name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
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
	valueLabel.Position = UDim2.new(0.45, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = formatMoney(value)
	valueLabel.TextColor3 = COLORS.Success
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 12
	valueLabel.Parent = item
	
	-- Remove button
	local removeBtn = Instance.new("TextButton")
	removeBtn.Size = UDim2.new(0, 35, 0, 35)
	removeBtn.Position = UDim2.new(1, -40, 0.5, 0)
	removeBtn.AnchorPoint = Vector2.new(0, 0.5)
	removeBtn.BackgroundColor3 = COLORS.Danger
	removeBtn.BorderSizePixel = 0
	removeBtn.Font = Enum.Font.GothamBold
	removeBtn.Text = "X"
	removeBtn.TextColor3 = COLORS.Text
	removeBtn.TextSize = 14
	removeBtn.ZIndex = 12
	removeBtn.Parent = item
	
	createCorner(6).Parent = removeBtn
	
	removeBtn.MouseButton1Click:Connect(function()
		cart[fishId] = nil
		updateCartDisplay()
		updateCartInfo()
		updateShopDisplay() -- Show fish back in shop
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
	quantityPopup.Visible = false
	isCartOpen = false
	isQuantityPopupOpen = false
end

closeButton.MouseButton1Click:Connect(closeShop)
cartClose.MouseButton1Click:Connect(function()
	cartPanel.Visible = false
	isCartOpen = false
end)

-- ==================== CART ACTIONS ====================

viewCartBtn.MouseButton1Click:Connect(function()
	updateCartDisplay()
	cartPanel.Visible = true
	isCartOpen = true
end)

clearCartBtn.MouseButton1Click:Connect(function()
	cart = {}
	updateCartInfo()
	updateCartDisplay()
	updateShopDisplay()
end)

discardCartBtn.MouseButton1Click:Connect(function()
	cart = {}
	updateCartInfo()
	updateCartDisplay()
	updateShopDisplay()
	cartPanel.Visible = false
	isCartOpen = false
end)

confirmSellBtn.MouseButton1Click:Connect(function()
	local _, count = getCartTotal()
	if count > 0 and sellSelectedFishEvent then
		sellSelectedFishEvent:FireServer(cart)
		-- ✅ Play transaction sound
		SoundConfig.PlayLocalSound("Transaction")
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
		-- ✅ Play transaction sound
		SoundConfig.PlayLocalSound("Transaction")
		cart = {}
		updateCartInfo()
		task.delay(0.5, fetchInventory)
	end
end)

-- ==================== PROXIMITY PROMPT SETUP ====================

local function setupProximityPrompt()
	task.wait(3)
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
