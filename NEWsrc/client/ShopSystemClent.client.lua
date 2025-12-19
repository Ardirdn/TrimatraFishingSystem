--[[
    SHOP SYSTEM CLIENT - COMPLETE & FINAL FIXED
    Place in StarterPlayerScripts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDButtonHelper = require(script.Parent:WaitForChild("HUDButtonHelper"))
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("ShopRemotes", 10)
if not remoteFolder then
	warn("[SHOP CLIENT] ShopRemotes folder not found, disabling shop")
	return
end

local getShopDataEvent = remoteFolder:WaitForChild("GetShopData", 10)
local purchaseItemEvent = remoteFolder:WaitForChild("PurchaseItem", 10)
local purchaseGamepassEvent = remoteFolder:WaitForChild("PurchaseGamepass", 10)
local purchaseMoneyPackEvent = remoteFolder:WaitForChild("PurchaseMoneyPack", 10)
local updatePlayerDataEvent = remoteFolder:WaitForChild("UpdatePlayerData", 10)

if not getShopDataEvent or not purchaseItemEvent then
	warn("[SHOP CLIENT] Required remotes not found, disabling shop")
	return
end

-- ==================== CONSTANTS ====================
local COLORS = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Header = Color3.fromRGB(30, 30, 33),
	Button = Color3.fromRGB(35, 35, 38),
	ButtonHover = Color3.fromRGB(45, 45, 48),
	Accent = Color3.fromRGB(70, 130, 255),
	AccentHover = Color3.fromRGB(90, 150, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Border = Color3.fromRGB(50, 50, 55),
	Success = Color3.fromRGB(67, 181, 129),
	Danger = Color3.fromRGB(237, 66, 69),
	Premium = Color3.fromRGB(255, 215, 0),
}

-- State - Initialize with empty tables
local currentMoney = 0
local ownedAuras = {}
local ownedTools = {}
local ownedGamepasses = {}
local currentTab = "Auras"
local currentAuraFilter = "All"
local currentToolFilter = "All"

-- Forward declarations (defined later)
local isShopOpen = false
local toggleShop

-- Accent Colors untuk variasi
local ACCENT_COLORS = {
	Color3.fromRGB(70, 130, 255),   -- Blue
	Color3.fromRGB(130, 80, 220),   -- Purple
	Color3.fromRGB(60, 180, 130),   -- Teal
	Color3.fromRGB(220, 120, 60),   -- Orange
	Color3.fromRGB(200, 70, 120),   -- Pink
	Color3.fromRGB(100, 160, 80),   -- Green
}

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

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

local function createTextSizeConstraint(minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize
	constraint.MaxTextSize = maxSize
	return constraint
end

local function getAccentColor(index)
	return ACCENT_COLORS[((index - 1) % #ACCENT_COLORS) + 1]
end

local function formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fm", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fk", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

local function showNotification(message, color)
	StarterGui:SetCore("SendNotification", {
		Title = "Shop",
		Text = message,
		Duration = 3,
	})
end

-- ==================== CREATE GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Main Container (untuk aspect ratio)
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0.55, 0, 0.85, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = screenGui

-- Aspect Ratio Constraint untuk main container
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1.3
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = mainContainer

-- Main Panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(1, 0, 1, 0)
mainPanel.Position = UDim2.new(0, 0, 0, 0)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = mainContainer

createScaledCorner(0.02).Parent = mainPanel
createStroke(COLORS.Border, 2).Parent = mainPanel

-- Main Panel Padding
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingLeft = UDim.new(0.02, 0)
mainPadding.PaddingRight = UDim.new(0.02, 0)
mainPadding.PaddingTop = UDim.new(0.015, 0)
mainPadding.PaddingBottom = UDim.new(0.02, 0)
mainPadding.Parent = mainPanel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.1, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = mainPanel

createScaledCorner(0.15).Parent = header

-- Header Padding
local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0.02, 0)
headerPadding.PaddingRight = UDim.new(0.02, 0)
headerPadding.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.2, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "🛒 SHOP"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

createTextSizeConstraint(12, 24).Parent = headerTitle

-- Money Display in Header
local moneyFrame = Instance.new("Frame")
moneyFrame.Size = UDim2.new(0.25, 0, 0.6, 0)
moneyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
moneyFrame.AnchorPoint = Vector2.new(0, 0.5)
moneyFrame.BackgroundColor3 = COLORS.Background
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = header

createScaledCorner(0.2).Parent = moneyFrame

-- Money Frame Padding
local moneyFramePadding = Instance.new("UIPadding")
moneyFramePadding.PaddingLeft = UDim.new(0.05, 0)
moneyFramePadding.PaddingRight = UDim.new(0.05, 0)
moneyFramePadding.Parent = moneyFrame

local moneyIcon = Instance.new("ImageLabel")
moneyIcon.Size = UDim2.new(0.12, 0, 0.7, 0)
moneyIcon.Position = UDim2.new(0.95, 0, 0.5, 0)
moneyIcon.AnchorPoint = Vector2.new(1, 0.5)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Image = "rbxassetid://7733964640"
moneyIcon.ImageColor3 = COLORS.Success
moneyIcon.Parent = moneyFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.8, 0, 1, 0)
moneyLabel.Position = UDim2.new(0, 0, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.Text = "$0"
moneyLabel.TextColor3 = COLORS.Success
moneyLabel.TextScaled = true
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyFrame

createTextSizeConstraint(10, 18).Parent = moneyLabel

-- Add Money Button
local addMoneyBtn = Instance.new("TextButton")
addMoneyBtn.Size = UDim2.new(0.05, 0, 0.6, 0)
addMoneyBtn.Position = UDim2.new(0.78, 0, 0.5, 0)
addMoneyBtn.AnchorPoint = Vector2.new(0, 0.5)
addMoneyBtn.BackgroundColor3 = COLORS.Accent
addMoneyBtn.BorderSizePixel = 0
addMoneyBtn.Text = "+"
addMoneyBtn.Font = Enum.Font.GothamBold
addMoneyBtn.TextScaled = true
addMoneyBtn.TextColor3 = COLORS.Text
addMoneyBtn.Parent = header

createScaledCorner(0.25).Parent = addMoneyBtn
createTextSizeConstraint(14, 24).Parent = addMoneyBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.06, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.97, 0, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = COLORS.Text
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

createScaledCorner(0.25).Parent = closeBtn
createTextSizeConstraint(14, 24).Parent = closeBtn

-- Close button hover effect
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Danger}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Button}):Play()
end)

-- Tab Container (dengan background panel)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0.1, 0)
tabContainer.Position = UDim2.new(0, 0, 0.11, 0)
tabContainer.BackgroundColor3 = COLORS.Panel
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainPanel

createScaledCorner(0.12).Parent = tabContainer

-- Tab Container Padding
local tabContainerPadding = Instance.new("UIPadding")
tabContainerPadding.PaddingLeft = UDim.new(0.02, 0)
tabContainerPadding.PaddingRight = UDim.new(0.02, 0)
tabContainerPadding.PaddingTop = UDim.new(0.1, 0)
tabContainerPadding.PaddingBottom = UDim.new(0.1, 0)
tabContainerPadding.Parent = tabContainer

-- Tab Frame (inside container)
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 1, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = tabContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.01, 0)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabFrame

-- Content Frame (adjusted position)
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 0.75, 0)
contentFrame.Position = UDim2.new(0, 0, 0.23, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainPanel

-- ==================== TAB CREATION ====================
local tabs = {}
local tabIcons = {
	Auras = "✨",
	Tools = "🔧",
	Gamepasses = "🎮",
	Money = "💰"
}

local function createTab(tabName, order)
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0.22, 0, 1, 0)
	tab.BackgroundColor3 = tabName == "Auras" and COLORS.Accent or COLORS.Background
	tab.BackgroundTransparency = tabName == "Auras" and 0 or 0.5
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.Text = tabIcons[tabName] .. " " .. tabName
	tab.TextColor3 = tabName == "Auras" and COLORS.Text or COLORS.TextSecondary
	tab.TextScaled = true
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = tabFrame

	createScaledCorner(0.25).Parent = tab
	createTextSizeConstraint(9, 14).Parent = tab
	
	-- Tab padding
	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0.08, 0)
	tabPadding.PaddingRight = UDim.new(0.08, 0)
	tabPadding.PaddingTop = UDim.new(0.1, 0)
	tabPadding.PaddingBottom = UDim.new(0.1, 0)
	tabPadding.Parent = tab
	
	-- Hover effect
	tab.MouseEnter:Connect(function()
		if tabs[tabName] and not tabs[tabName].Content.Visible then
			TweenService:Create(tab, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
		end
	end)
	
	tab.MouseLeave:Connect(function()
		if tabs[tabName] and not tabs[tabName].Content.Visible then
			TweenService:Create(tab, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
		end
	end)

	-- Content container
	local content = Instance.new("Frame")
	content.Name = tabName .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Visible = tabName == "Auras"
	content.Parent = contentFrame

	tabs[tabName] = {Button = tab, Content = content}

	tab.MouseButton1Click:Connect(function()
		-- Hide all tabs
		for name, tabData in pairs(tabs) do
			tabData.Content.Visible = false
			tabData.Button.BackgroundColor3 = COLORS.Background
			tabData.Button.BackgroundTransparency = 0.5
			tabData.Button.TextColor3 = COLORS.TextSecondary
		end

		-- Show selected tab
		content.Visible = true
		tab.BackgroundColor3 = COLORS.Accent
		tab.BackgroundTransparency = 0
		tab.TextColor3 = COLORS.Text
		currentTab = tabName
	end)

	return content
end

-- Create tabs
local aurasContent = createTab("Auras", 1)
local toolsContent = createTab("Tools", 2)
local gamepassesContent = createTab("Gamepasses", 3)
local moneyContent = createTab("Money", 4)

-- ==================== AURAS TAB ====================
-- Filter Container (pill style)
local auraFilterFrame = Instance.new("Frame")
auraFilterFrame.Size = UDim2.new(1, 0, 0.12, 0)
auraFilterFrame.BackgroundTransparency = 1
auraFilterFrame.Parent = aurasContent

local auraFilterLayout = Instance.new("UIListLayout")
auraFilterLayout.FillDirection = Enum.FillDirection.Horizontal
auraFilterLayout.Padding = UDim.new(0.015, 0)
auraFilterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
auraFilterLayout.Parent = auraFilterFrame

-- Filter Label
local auraFilterLabel = Instance.new("TextLabel")
auraFilterLabel.Size = UDim2.new(0.1, 0, 0.7, 0)
auraFilterLabel.BackgroundTransparency = 1
auraFilterLabel.Font = Enum.Font.Gotham
auraFilterLabel.Text = "Filter:"
auraFilterLabel.TextColor3 = COLORS.TextSecondary
auraFilterLabel.TextScaled = true
auraFilterLabel.TextXAlignment = Enum.TextXAlignment.Left
auraFilterLabel.LayoutOrder = 0
auraFilterLabel.Parent = auraFilterFrame

createTextSizeConstraint(8, 12).Parent = auraFilterLabel

local function createFilterBtn(text, filter)
	local isActive = filter == "All"
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.12, 0, 0.7, 0)
	btn.BackgroundColor3 = isActive and COLORS.Accent or COLORS.Background
	btn.BackgroundTransparency = isActive and 0.1 or 0.7
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = isActive and COLORS.Text or COLORS.TextSecondary
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = auraFilterFrame

	createScaledCorner(0.4).Parent = btn
	createTextSizeConstraint(8, 12).Parent = btn
	
	-- Border stroke for pills
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = isActive and COLORS.Accent or COLORS.Border
	btnStroke.Thickness = 1
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Parent = btn
	
	-- Hover effect
	btn.MouseEnter:Connect(function()
		if not (currentAuraFilter == filter) then
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = COLORS.Accent}):Play()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
		end
	end)
	
	btn.MouseLeave:Connect(function()
		if not (currentAuraFilter == filter) then
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = COLORS.Border}):Play()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		currentAuraFilter = filter
		for _, child in ipairs(auraFilterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Background
				child.BackgroundTransparency = 0.7
				child.TextColor3 = COLORS.TextSecondary
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = COLORS.Border end
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
		btn.BackgroundTransparency = 0.1
		btn.TextColor3 = COLORS.Text
		btnStroke.Color = COLORS.Accent
		updateAurasList()
	end)

	return btn
end

createFilterBtn("All", "All")
createFilterBtn("Premium", "Premium")
createFilterBtn("Normal", "Normal")

-- Auras Scroll
local aurasScroll = Instance.new("ScrollingFrame")
aurasScroll.Size = UDim2.new(1, 0, 0.86, 0)
aurasScroll.Position = UDim2.new(0, 0, 0.14, 0)
aurasScroll.BackgroundTransparency = 1
aurasScroll.BorderSizePixel = 0
aurasScroll.ScrollBarThickness = 6
aurasScroll.ScrollBarImageColor3 = COLORS.Border
aurasScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
aurasScroll.ScrollingDirection = Enum.ScrollingDirection.Y
aurasScroll.Parent = aurasContent

-- Auras Scroll Padding
local aurasScrollPadding = Instance.new("UIPadding")
aurasScrollPadding.PaddingTop = UDim.new(0, 8)
aurasScrollPadding.PaddingBottom = UDim.new(0, 8)
aurasScrollPadding.PaddingLeft = UDim.new(0, 5)
aurasScrollPadding.PaddingRight = UDim.new(0, 5)
aurasScrollPadding.Parent = aurasScroll

local aurasGrid = Instance.new("UIGridLayout")
aurasGrid.CellSize = UDim2.new(0.31, 0, 0, 150)
aurasGrid.CellPadding = UDim2.new(0.02, 0, 0, 12)
aurasGrid.SortOrder = Enum.SortOrder.LayoutOrder
aurasGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
aurasGrid.Parent = aurasScroll

-- Manual canvas size calculation (prevents scroll reset)
aurasGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	aurasScroll.CanvasSize = UDim2.new(0, 0, 0, aurasGrid.AbsoluteContentSize.Y + 20)
end)

local aurasEmptyLabel = Instance.new("TextLabel")
aurasEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
aurasEmptyLabel.BackgroundTransparency = 1
aurasEmptyLabel.Font = Enum.Font.Gotham
aurasEmptyLabel.Text = "Kamu sudah membeli semua aura, Terimakasih"
aurasEmptyLabel.TextColor3 = COLORS.TextSecondary
aurasEmptyLabel.TextScaled = true
aurasEmptyLabel.Visible = false
aurasEmptyLabel.Parent = aurasScroll

createTextSizeConstraint(10, 16).Parent = aurasEmptyLabel

-- ==================== TOOLS TAB ====================
-- Filter Container (pill style)
local toolFilterFrame = Instance.new("Frame")
toolFilterFrame.Size = UDim2.new(1, 0, 0.12, 0)
toolFilterFrame.BackgroundTransparency = 1
toolFilterFrame.Parent = toolsContent

local toolFilterLayout = Instance.new("UIListLayout")
toolFilterLayout.FillDirection = Enum.FillDirection.Horizontal
toolFilterLayout.Padding = UDim.new(0.015, 0)
toolFilterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
toolFilterLayout.Parent = toolFilterFrame

-- Filter Label
local toolFilterLabel = Instance.new("TextLabel")
toolFilterLabel.Size = UDim2.new(0.1, 0, 0.7, 0)
toolFilterLabel.BackgroundTransparency = 1
toolFilterLabel.Font = Enum.Font.Gotham
toolFilterLabel.Text = "Filter:"
toolFilterLabel.TextColor3 = COLORS.TextSecondary
toolFilterLabel.TextScaled = true
toolFilterLabel.TextXAlignment = Enum.TextXAlignment.Left
toolFilterLabel.LayoutOrder = 0
toolFilterLabel.Parent = toolFilterFrame

createTextSizeConstraint(8, 12).Parent = toolFilterLabel

local function createToolFilterBtn(text, filter)
	local isActive = filter == "All"
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.12, 0, 0.7, 0)
	btn.BackgroundColor3 = isActive and COLORS.Accent or COLORS.Background
	btn.BackgroundTransparency = isActive and 0.1 or 0.7
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = isActive and COLORS.Text or COLORS.TextSecondary
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = toolFilterFrame

	createScaledCorner(0.4).Parent = btn
	createTextSizeConstraint(8, 12).Parent = btn
	
	-- Border stroke for pills
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = isActive and COLORS.Accent or COLORS.Border
	btnStroke.Thickness = 1
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Parent = btn
	
	-- Hover effect
	btn.MouseEnter:Connect(function()
		if not (currentToolFilter == filter) then
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = COLORS.Accent}):Play()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
		end
	end)
	
	btn.MouseLeave:Connect(function()
		if not (currentToolFilter == filter) then
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = COLORS.Border}):Play()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		currentToolFilter = filter
		for _, child in ipairs(toolFilterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Background
				child.BackgroundTransparency = 0.7
				child.TextColor3 = COLORS.TextSecondary
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = COLORS.Border end
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
		btn.BackgroundTransparency = 0.1
		btn.TextColor3 = COLORS.Text
		btnStroke.Color = COLORS.Accent
		updateToolsList()
	end)

	return btn
end

createToolFilterBtn("All", "All")
createToolFilterBtn("Premium", "Premium")
createToolFilterBtn("Normal", "Normal")

-- Tools Scroll
local toolsScroll = Instance.new("ScrollingFrame")
toolsScroll.Size = UDim2.new(1, 0, 0.86, 0)
toolsScroll.Position = UDim2.new(0, 0, 0.14, 0)
toolsScroll.BackgroundTransparency = 1
toolsScroll.BorderSizePixel = 0
toolsScroll.ScrollBarThickness = 6
toolsScroll.ScrollBarImageColor3 = COLORS.Border
toolsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
toolsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
toolsScroll.Parent = toolsContent

-- Tools Scroll Padding
local toolsScrollPadding = Instance.new("UIPadding")
toolsScrollPadding.PaddingTop = UDim.new(0, 8)
toolsScrollPadding.PaddingBottom = UDim.new(0, 8)
toolsScrollPadding.PaddingLeft = UDim.new(0, 5)
toolsScrollPadding.PaddingRight = UDim.new(0, 5)
toolsScrollPadding.Parent = toolsScroll

local toolsGrid = Instance.new("UIGridLayout")
toolsGrid.CellSize = UDim2.new(0.31, 0, 0, 150)
toolsGrid.CellPadding = UDim2.new(0.02, 0, 0, 12)
toolsGrid.SortOrder = Enum.SortOrder.LayoutOrder
toolsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
toolsGrid.Parent = toolsScroll

-- Manual canvas size calculation (prevents scroll reset)
toolsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	toolsScroll.CanvasSize = UDim2.new(0, 0, 0, toolsGrid.AbsoluteContentSize.Y + 20)
end)

local toolsEmptyLabel = Instance.new("TextLabel")
toolsEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
toolsEmptyLabel.BackgroundTransparency = 1
toolsEmptyLabel.Font = Enum.Font.Gotham
toolsEmptyLabel.Text = "Kamu sudah membeli semua tools, Terimakasih"
toolsEmptyLabel.TextColor3 = COLORS.TextSecondary
toolsEmptyLabel.TextScaled = true
toolsEmptyLabel.Visible = false
toolsEmptyLabel.Parent = toolsScroll

createTextSizeConstraint(10, 16).Parent = toolsEmptyLabel

-- ==================== GAMEPASSES TAB ====================
local gamepassScroll = Instance.new("ScrollingFrame")
gamepassScroll.Size = UDim2.new(1, 0, 1, 0)
gamepassScroll.BackgroundTransparency = 1
gamepassScroll.BorderSizePixel = 0
gamepassScroll.ScrollBarThickness = 6
gamepassScroll.ScrollBarImageColor3 = COLORS.Border
gamepassScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
gamepassScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
gamepassScroll.ScrollingDirection = Enum.ScrollingDirection.X
gamepassScroll.Parent = gamepassesContent

local gamepassLayout = Instance.new("UIListLayout")
gamepassLayout.Padding = UDim.new(0, 10)
gamepassLayout.FillDirection = Enum.FillDirection.Horizontal
gamepassLayout.SortOrder = Enum.SortOrder.LayoutOrder
gamepassLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gamepassLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gamepassLayout.Parent = gamepassScroll

local gamepassPadding = Instance.new("UIPadding")
gamepassPadding.PaddingLeft = UDim.new(0, 5)
gamepassPadding.PaddingRight = UDim.new(0, 5)
gamepassPadding.PaddingTop = UDim.new(0, 5)
gamepassPadding.Parent = gamepassScroll

local gamepassEmptyLabel = Instance.new("TextLabel")
gamepassEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
gamepassEmptyLabel.BackgroundTransparency = 1
gamepassEmptyLabel.Font = Enum.Font.Gotham
gamepassEmptyLabel.Text = "Kamu sudah membeli semua gamepass, Terimakasih"
gamepassEmptyLabel.TextColor3 = COLORS.TextSecondary
gamepassEmptyLabel.TextScaled = true
gamepassEmptyLabel.Visible = false
gamepassEmptyLabel.Parent = gamepassScroll

createTextSizeConstraint(10, 16).Parent = gamepassEmptyLabel

-- ==================== MONEY TAB ====================
local moneyScroll = Instance.new("ScrollingFrame")
moneyScroll.Size = UDim2.new(1, 0, 1, 0)
moneyScroll.BackgroundTransparency = 1
moneyScroll.BorderSizePixel = 0
moneyScroll.ScrollBarThickness = 6
moneyScroll.ScrollBarImageColor3 = COLORS.Border
moneyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
moneyScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
moneyScroll.ScrollingDirection = Enum.ScrollingDirection.X
moneyScroll.Parent = moneyContent

local moneyLayout = Instance.new("UIListLayout")
moneyLayout.Padding = UDim.new(0, 10)
moneyLayout.FillDirection = Enum.FillDirection.Horizontal
moneyLayout.SortOrder = Enum.SortOrder.LayoutOrder
moneyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
moneyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
moneyLayout.Parent = moneyScroll

local moneyPadding = Instance.new("UIPadding")
moneyPadding.PaddingLeft = UDim.new(0, 5)
moneyPadding.PaddingRight = UDim.new(0, 5)
moneyPadding.PaddingTop = UDim.new(0, 5)
moneyPadding.Parent = moneyScroll

-- ==================== ITEM CREATION FUNCTIONS ====================

-- Item index untuk accent color
local auraItemIndex = 0
local toolItemIndex = 0

local function createAuraItem(auraData)
	auraItemIndex = auraItemIndex + 1
	local accentColor = getAccentColor(auraItemIndex)
	
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = aurasScroll

	createScaledCorner(0.06).Parent = frame
	
	-- Accent stroke
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = accentColor
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = frame
	
	-- Card padding
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingLeft = UDim.new(0.04, 0)
	cardPadding.PaddingRight = UDim.new(0.04, 0)
	cardPadding.PaddingTop = UDim.new(0.03, 0)
	cardPadding.PaddingBottom = UDim.new(0.03, 0)
	cardPadding.Parent = frame
	
	-- Left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.Position = UDim2.new(0, -frame.AbsoluteSize.X * 0.04, 0, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = frame
	
	createScaledCorner(0.5).Parent = accentBar

	-- Thumbnail
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(1, 0, 0.45, 0)
	thumbnail.Position = UDim2.new(0, 0, 0, 0)
	thumbnail.BackgroundColor3 = COLORS.Button
	thumbnail.BorderSizePixel = 0
	thumbnail.Image = auraData.Thumbnail
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = frame

	createScaledCorner(0.08).Parent = thumbnail

	-- Premium Badge
	if auraData.IsPremium then
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(0.4, 0, 0.2, 0)
		badge.Position = UDim2.new(0.02, 0, 0.02, 0)
		badge.BackgroundColor3 = COLORS.Premium
		badge.BorderSizePixel = 0
		badge.Parent = thumbnail

		createScaledCorner(0.3).Parent = badge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "PREMIUM"
		badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		badgeLabel.TextScaled = true
		badgeLabel.Parent = badge
		
		createTextSizeConstraint(8, 12).Parent = badgeLabel
	end

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.48, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = auraData.Title
	titleLabel.TextColor3 = accentColor
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = frame
	
	createTextSizeConstraint(10, 14).Parent = titleLabel

	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.12, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.62, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = auraData.IsPremium and ("R$ " .. auraData.Price) or formatMoney(auraData.Price)
	priceLabel.TextColor3 = auraData.IsPremium and COLORS.Premium or COLORS.Success
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = frame
	
	createTextSizeConstraint(10, 16).Parent = priceLabel

	-- Buy Button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(1, 0, 0.18, 0)
	buyBtn.Position = UDim2.new(0, 0, 0.78, 0)
	buyBtn.BackgroundColor3 = accentColor
	buyBtn.BackgroundTransparency = 0.15
	buyBtn.BorderSizePixel = 0
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = "Buy"
	buyBtn.TextColor3 = COLORS.Text
	buyBtn.TextScaled = true
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = frame

	createScaledCorner(0.2).Parent = buyBtn
	createTextSizeConstraint(10, 15).Parent = buyBtn
	
	-- Hover effect
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 2.5}):Play()
	end)
	
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
	end)

	-- Buy button click
	buyBtn.MouseButton1Click:Connect(function()
		if auraData.IsPremium then
			-- Premium purchase with Robux
			if not auraData.ProductId or auraData.ProductId == 0 then
				showNotification("Product ID not set!", COLORS.Danger)
			else
				purchaseItemEvent:FireServer("Aura", auraData.AuraId, auraData.Price, true, auraData.ProductId)
			end
		else
			-- In-game money purchase
			if currentMoney >= auraData.Price then
				purchaseItemEvent:FireServer("Aura", auraData.AuraId, auraData.Price, false, nil)
				showNotification("Purchased: " .. auraData.Title, COLORS.Success)
			else
				showNotification("Not enough money!", COLORS.Danger)
			end
		end
	end)

	return frame
end

local function createToolItem(toolData)
	toolItemIndex = toolItemIndex + 1
	local accentColor = getAccentColor(toolItemIndex)
	
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = toolsScroll

	createScaledCorner(0.06).Parent = frame
	
	-- Accent stroke
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = accentColor
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = frame
	
	-- Card padding
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingLeft = UDim.new(0.04, 0)
	cardPadding.PaddingRight = UDim.new(0.04, 0)
	cardPadding.PaddingTop = UDim.new(0.03, 0)
	cardPadding.PaddingBottom = UDim.new(0.03, 0)
	cardPadding.Parent = frame
	
	-- Left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.Position = UDim2.new(0, -frame.AbsoluteSize.X * 0.04, 0, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = frame
	
	createScaledCorner(0.5).Parent = accentBar

	-- Thumbnail
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(1, 0, 0.45, 0)
	thumbnail.Position = UDim2.new(0, 0, 0, 0)
	thumbnail.BackgroundColor3 = COLORS.Button
	thumbnail.BorderSizePixel = 0
	thumbnail.Image = toolData.Thumbnail
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = frame

	createScaledCorner(0.08).Parent = thumbnail

	-- Premium Badge
	if toolData.IsPremium then
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(0.4, 0, 0.2, 0)
		badge.Position = UDim2.new(0.02, 0, 0.02, 0)
		badge.BackgroundColor3 = COLORS.Premium
		badge.BorderSizePixel = 0
		badge.Parent = thumbnail

		createScaledCorner(0.3).Parent = badge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "PREMIUM"
		badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		badgeLabel.TextScaled = true
		badgeLabel.Parent = badge
		
		createTextSizeConstraint(8, 12).Parent = badgeLabel
	end

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.48, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = toolData.Title
	titleLabel.TextColor3 = accentColor
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = frame
	
	createTextSizeConstraint(10, 14).Parent = titleLabel

	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.12, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.62, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = toolData.IsPremium and ("R$ " .. toolData.Price) or formatMoney(toolData.Price)
	priceLabel.TextColor3 = toolData.IsPremium and COLORS.Premium or COLORS.Success
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = frame
	
	createTextSizeConstraint(10, 16).Parent = priceLabel

	-- Buy Button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(1, 0, 0.18, 0)
	buyBtn.Position = UDim2.new(0, 0, 0.78, 0)
	buyBtn.BackgroundColor3 = accentColor
	buyBtn.BackgroundTransparency = 0.15
	buyBtn.BorderSizePixel = 0
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = "Buy"
	buyBtn.TextColor3 = COLORS.Text
	buyBtn.TextScaled = true
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = frame

	createScaledCorner(0.2).Parent = buyBtn
	createTextSizeConstraint(10, 15).Parent = buyBtn
	
	-- Hover effect
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 2.5}):Play()
	end)
	
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
	end)

	-- Buy button click
	buyBtn.MouseButton1Click:Connect(function()
		if toolData.IsPremium then
			-- Premium purchase with Robux
			if not toolData.ProductId or toolData.ProductId == 0 then
				showNotification("Product ID not set!", COLORS.Danger)
			else
				purchaseItemEvent:FireServer("Tool", toolData.ToolId, toolData.Price, true, toolData.ProductId)
			end
		else
			-- In-game money purchase
			if currentMoney >= toolData.Price then
				purchaseItemEvent:FireServer("Tool", toolData.ToolId, toolData.Price, false, nil)
				showNotification("Purchased: " .. toolData.Title, COLORS.Success)
			else
				showNotification("Not enough money!", COLORS.Danger)
			end
		end
	end)

	return frame
end

local gamepassItemIndex = 0
local moneyPackItemIndex = 0

local function createGamepassItem(gamepassData)
	gamepassItemIndex = gamepassItemIndex + 1
	local accentColor = getAccentColor(gamepassItemIndex)
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.45, 0, 0.95, 0)
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = gamepassScroll

	createScaledCorner(0.04).Parent = frame
	
	-- Accent stroke
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = accentColor
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = frame
	
	-- Card padding
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingLeft = UDim.new(0.04, 0)
	cardPadding.PaddingRight = UDim.new(0.04, 0)
	cardPadding.PaddingTop = UDim.new(0.03, 0)
	cardPadding.PaddingBottom = UDim.new(0.03, 0)
	cardPadding.Parent = frame

	-- Thumbnail
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(1, 0, 0.4, 0)
	thumbnail.Position = UDim2.new(0, 0, 0, 0)
	thumbnail.BackgroundColor3 = COLORS.Button
	thumbnail.BorderSizePixel = 0
	thumbnail.Image = gamepassData.Thumbnail
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = frame

	createScaledCorner(0.08).Parent = thumbnail

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.43, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = gamepassData.Name
	titleLabel.TextColor3 = accentColor
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = frame
	
	createTextSizeConstraint(12, 18).Parent = titleLabel

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 0.15, 0)
	descLabel.Position = UDim2.new(0, 0, 0.54, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = gamepassData.Description or ""
	descLabel.TextColor3 = COLORS.TextSecondary
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = frame
	
	createTextSizeConstraint(9, 13).Parent = descLabel

	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.1, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.7, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = "R$ " .. gamepassData.Price
	priceLabel.TextColor3 = COLORS.Premium
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = frame
	
	createTextSizeConstraint(12, 20).Parent = priceLabel

	-- Buy Button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(1, 0, 0.12, 0)
	buyBtn.Position = UDim2.new(0, 0, 0.83, 0)
	buyBtn.BackgroundColor3 = accentColor
	buyBtn.BackgroundTransparency = 0.15
	buyBtn.BorderSizePixel = 0
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = "Purchase"
	buyBtn.TextColor3 = COLORS.Text
	buyBtn.TextScaled = true
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = frame

	createScaledCorner(0.2).Parent = buyBtn
	createTextSizeConstraint(10, 16).Parent = buyBtn
	
	-- Hover effect
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 2.5}):Play()
	end)
	
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
	end)

	buyBtn.MouseButton1Click:Connect(function()
		purchaseGamepassEvent:FireServer(gamepassData.Name)
	end)

	return frame
end

local function createMoneyPackItem(packData)
	moneyPackItemIndex = moneyPackItemIndex + 1
	local accentColor = getAccentColor(moneyPackItemIndex)
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.35, 0, 0.95, 0)
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = moneyScroll

	createScaledCorner(0.04).Parent = frame
	
	-- Accent stroke
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = accentColor
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = frame
	
	-- Card padding
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingLeft = UDim.new(0.04, 0)
	cardPadding.PaddingRight = UDim.new(0.04, 0)
	cardPadding.PaddingTop = UDim.new(0.03, 0)
	cardPadding.PaddingBottom = UDim.new(0.03, 0)
	cardPadding.Parent = frame

	-- Thumbnail
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(1, 0, 0.4, 0)
	thumbnail.Position = UDim2.new(0, 0, 0, 0)
	thumbnail.BackgroundColor3 = COLORS.Button
	thumbnail.BorderSizePixel = 0
	thumbnail.Image = packData.Thumbnail
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = frame

	createScaledCorner(0.08).Parent = thumbnail

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.43, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = packData.Title
	titleLabel.TextColor3 = accentColor
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = frame
	
	createTextSizeConstraint(10, 16).Parent = titleLabel

	-- Reward
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, 0, 0.12, 0)
	rewardLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Text = formatMoney(packData.MoneyReward)
	rewardLabel.TextColor3 = COLORS.Success
	rewardLabel.TextScaled = true
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardLabel.Parent = frame
	
	createTextSizeConstraint(14, 22).Parent = rewardLabel

	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.1, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.68, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = "R$ " .. packData.Price
	priceLabel.TextColor3 = COLORS.Premium
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = frame
	
	createTextSizeConstraint(10, 18).Parent = priceLabel

	-- Buy Button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(1, 0, 0.12, 0)
	buyBtn.Position = UDim2.new(0, 0, 0.83, 0)
	buyBtn.BackgroundColor3 = accentColor
	buyBtn.BackgroundTransparency = 0.15
	buyBtn.BorderSizePixel = 0
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = "Purchase"
	buyBtn.TextColor3 = COLORS.Text
	buyBtn.TextScaled = true
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = frame

	createScaledCorner(0.2).Parent = buyBtn
	createTextSizeConstraint(10, 16).Parent = buyBtn
	
	-- Hover effect
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 2.5}):Play()
	end)
	
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
	end)

	buyBtn.MouseButton1Click:Connect(function()
		purchaseMoneyPackEvent:FireServer(packData.ProductId)
	end)

	return frame
end

-- ==================== UPDATE FUNCTIONS ====================

function updateAurasList()
	-- Reset item index untuk accent colors
	auraItemIndex = 0
	
	-- Clear existing
	for _, child in ipairs(aurasScroll:GetChildren()) do
		if child:IsA("Frame") and child ~= aurasEmptyLabel then
			child:Destroy()
		end
	end

	local itemsToShow = {}

	-- Safety check
	if not ShopConfig.Auras or type(ShopConfig.Auras) ~= "table" then
		aurasEmptyLabel.Visible = true
		aurasEmptyLabel.Text = "No auras available"
		return
	end

	-- Ensure ownedAuras is a table
	if not ownedAuras or type(ownedAuras) ~= "table" then
		ownedAuras = {}
	end

	for _, aura in ipairs(ShopConfig.Auras) do
		-- Check if already owned (with safety check)
		local isOwned = false
		if ownedAuras and type(ownedAuras) == "table" then
			isOwned = table.find(ownedAuras, aura.AuraId) ~= nil
		end

		if not isOwned then
			-- Check filter
			if currentAuraFilter == "All" then
				table.insert(itemsToShow, aura)
			elseif currentAuraFilter == "Premium" and aura.IsPremium then
				table.insert(itemsToShow, aura)
			elseif currentAuraFilter == "Normal" and not aura.IsPremium then
				table.insert(itemsToShow, aura)
			end
		end
	end

	if #itemsToShow == 0 then
		aurasEmptyLabel.Visible = true
	else
		aurasEmptyLabel.Visible = false
		for _, aura in ipairs(itemsToShow) do
			createAuraItem(aura)
		end
	end
end

function updateToolsList()
	-- Reset item index untuk accent colors
	toolItemIndex = 0
	
	-- Clear existing
	for _, child in ipairs(toolsScroll:GetChildren()) do
		if child:IsA("Frame") and child ~= toolsEmptyLabel then
			child:Destroy()
		end
	end

	local itemsToShow = {}

	-- Safety check
	if not ShopConfig.Tools or type(ShopConfig.Tools) ~= "table" then
		toolsEmptyLabel.Visible = true
		toolsEmptyLabel.Text = "No tools available"
		return
	end

	-- Ensure ownedTools is a table
	if not ownedTools or type(ownedTools) ~= "table" then
		ownedTools = {}
	end

	for _, tool in ipairs(ShopConfig.Tools) do
		-- Check if already owned (with safety check)
		local isOwned = false
		if ownedTools and type(ownedTools) == "table" then
			isOwned = table.find(ownedTools, tool.ToolId) ~= nil
		end

		if not isOwned then
			-- Check filter
			if currentToolFilter == "All" then
				table.insert(itemsToShow, tool)
			elseif currentToolFilter == "Premium" and tool.IsPremium then
				table.insert(itemsToShow, tool)
			elseif currentToolFilter == "Normal" and not tool.IsPremium then
				table.insert(itemsToShow, tool)
			end
		end
	end

	if #itemsToShow == 0 then
		toolsEmptyLabel.Visible = true
	else
		toolsEmptyLabel.Visible = false
		for _, tool in ipairs(itemsToShow) do
			createToolItem(tool)
		end
	end
end

function updateGamepassesList()
	-- Reset item index untuk accent colors
	gamepassItemIndex = 0
	
	-- Clear existing
	for _, child in ipairs(gamepassScroll:GetChildren()) do
		if child:IsA("Frame") and child ~= gamepassEmptyLabel then
			child:Destroy()
		end
	end

	local itemsToShow = {}

	-- Safety check
	if not ShopConfig.Gamepasses or type(ShopConfig.Gamepasses) ~= "table" then
		gamepassEmptyLabel.Visible = true
		gamepassEmptyLabel.Text = "No gamepasses available"
		return
	end

	-- Ensure ownedGamepasses is a table
	if not ownedGamepasses or type(ownedGamepasses) ~= "table" then
		ownedGamepasses = {}
	end

	for _, gp in ipairs(ShopConfig.Gamepasses) do
		-- Check if already owned (with safety check)
		local isOwned = false
		if ownedGamepasses and type(ownedGamepasses) == "table" then
			isOwned = table.find(ownedGamepasses, gp.Name) ~= nil
		end

		if not isOwned then
			table.insert(itemsToShow, gp)
		end
	end

	if #itemsToShow == 0 then
		gamepassEmptyLabel.Visible = true
	else
		gamepassEmptyLabel.Visible = false
		for _, gp in ipairs(itemsToShow) do
			createGamepassItem(gp)
		end
	end
end

function updateMoneyPacksList()
	-- Reset item index untuk accent colors
	moneyPackItemIndex = 0
	
	-- Clear existing
	for _, child in ipairs(moneyScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Safety check
	if not ShopConfig.MoneyPacks or type(ShopConfig.MoneyPacks) ~= "table" then
		return
	end

	for _, pack in ipairs(ShopConfig.MoneyPacks) do
		createMoneyPackItem(pack)
	end
end

function updateMoneyDisplay()
	moneyLabel.Text = formatMoney(currentMoney)
end

function refreshShopData()
	local success, result = pcall(function()
		return getShopDataEvent:InvokeServer()
	end)

	if success and result then
		-- Update with default values if nil
		currentMoney = result.Money or 0
		ownedAuras = result.OwnedAuras or {}
		ownedTools = result.OwnedTools or {}
		ownedGamepasses = result.OwnedGamepasses or {}

		-- Ensure they are tables
		if type(ownedAuras) ~= "table" then ownedAuras = {} end
		if type(ownedTools) ~= "table" then ownedTools = {} end
		if type(ownedGamepasses) ~= "table" then ownedGamepasses = {} end

		updateMoneyDisplay()
		updateAurasList()
		updateToolsList()
		updateGamepassesList()
		updateMoneyPacksList()
	else
		warn("Failed to get shop data:", result)
		-- Set defaults on error
		ownedAuras = {}
		ownedTools = {}
		ownedGamepasses = {}
		currentMoney = 0

		updateMoneyDisplay()
		updateAurasList()
		updateToolsList()
		updateGamepassesList()
		updateMoneyPacksList()
	end
end

-- ==================== EVENTS ====================

closeBtn.MouseButton1Click:Connect(function()
	if isShopOpen then
		toggleShop()
	end
end)

addMoneyBtn.MouseButton1Click:Connect(function()
	-- Switch to Money tab
	for _, tabData in pairs(tabs) do
		tabData.Content.Visible = false
		tabData.Button.BackgroundColor3 = COLORS.Button
	end

	tabs["Money"].Content.Visible = true
	tabs["Money"].Button.BackgroundColor3 = COLORS.Accent
	currentTab = "Money"
end)

-- Listen for data updates
updatePlayerDataEvent.OnClientEvent:Connect(function(data)
	if not data then return end

	currentMoney = data.Money or 0
	ownedAuras = data.OwnedAuras or {}
	ownedTools = data.OwnedTools or {}

	-- Ensure they are tables
	if type(ownedAuras) ~= "table" then ownedAuras = {} end
	if type(ownedTools) ~= "table" then ownedTools = {} end

	updateMoneyDisplay()

	-- Refresh current tab
	if currentTab == "Auras" then
		updateAurasList()
	elseif currentTab == "Tools" then
		updateToolsList()
	elseif currentTab == "Gamepasses" then
		updateGamepassesList()
	end
end)

-- Money value changed
local moneyValue = player:WaitForChild("Money", 10)
if moneyValue then
	moneyValue.Changed:Connect(function(value)
		currentMoney = value
		updateMoneyDisplay()
	end)

	-- Initial value
	currentMoney = moneyValue.Value
	updateMoneyDisplay()
end

-- Drag functionality
local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput, mousePos, framePos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = mainContainer.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			local viewport = workspace.CurrentCamera.ViewportSize

			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			mainContainer.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,
				framePos.Y.Scale + deltaScaleY,
				0
			)
		end
	end)
end

makeDraggable(mainPanel, header)

-- ==================== HUD BUTTON ====================

local function closeShop()
	isShopOpen = false
	screenGui.Enabled = false
	mainPanel.Visible = false
	PanelManager:Close("ShopPanel")
end

local function openShop()
	PanelManager:Open("ShopPanel") -- This closes other panels first
	isShopOpen = true
	screenGui.Enabled = true
	mainPanel.Visible = true
	refreshShopData()
end

toggleShop = function()
	if isShopOpen then
		closeShop()
	else
		openShop()
	end
end

-- Register with PanelManager
PanelManager:Register("ShopPanel", closeShop)

local shopButton = HUDButtonHelper.Create({
	Side = "Left",
	Name = "ShopButton",
	Icon = "rbxassetid://135251669370797",
	Text = "Shop",
	OnClick = toggleShop
})

-- Initial load with delay
task.spawn(function()
	task.wait(2)
	refreshShopData()
end)

print("✓ Shop System Client loaded successfully")