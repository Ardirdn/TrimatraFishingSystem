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

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))


local remoteFolder = ReplicatedStorage:WaitForChild("ShopRemotes")
local getShopDataEvent = remoteFolder:WaitForChild("GetShopData")
local purchaseItemEvent = remoteFolder:WaitForChild("PurchaseItem")
local purchaseGamepassEvent = remoteFolder:WaitForChild("PurchaseGamepass")
local purchaseMoneyPackEvent = remoteFolder:WaitForChild("PurchaseMoneyPack")
local updatePlayerDataEvent = remoteFolder:WaitForChild("UpdatePlayerData")

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

-- ==================== HELPER FUNCTIONS ====================
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
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
task.wait(3)
local screenGui = playerGui:WaitForChild("Shop")
--local screenGui = Instance.new("ScreenGui")
--screenGui.Name = "ShopGUI"
--screenGui.ResetOnSpawn = false
--screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
--screenGui.Enabled = false
--screenGui.Parent = playerGui

-- Main Panel
local mainPanel = screenGui:WaitForChild("ShopPanel")
--local mainPanel = Instance.new("Frame")
--mainPanel.Size = UDim2.new(0.45, 0, 0.6, 0)  -- 800/1920, 500/1080
--mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
--mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
--mainPanel.BackgroundColor3 = COLORS.Background
--mainPanel.BorderSizePixel = 0
--mainPanel.Visible = false
--mainPanel.Parent = screenGui

--createCorner(15).Parent = mainPanel
--createStroke(COLORS.Border, 2).Parent = mainPanel

-- Header
local header = mainPanel:WaitForChild("Header")
--local header = Instance.new("Frame")
--header.Size = UDim2.new(1, 0, 0.12, 0)
--header.BackgroundColor3 = COLORS.Panel
--header.BorderSizePixel = 0
--header.Parent = mainPanel

--createCorner(15).Parent = header

--local headerBottom = Instance.new("Frame")
--headerBottom.Size = UDim2.new(1, 0, 0, 15)
--headerBottom.Position = UDim2.new(0, 0, 1, -15)
--headerBottom.BackgroundColor3 = COLORS.Panel
--headerBottom.BorderSizePixel = 0
--headerBottom.Parent = header

--local headerTitle = Instance.new("TextLabel")
--headerTitle.Size = UDim2.new(0.25, 0, 1, 0)  -- 200/800
--headerTitle.Position = UDim2.new(0.025, 0, 0, 0)
--headerTitle.BackgroundTransparency = 1
--headerTitle.Font = Enum.Font.GothamBold
--headerTitle.Text = "SHOP"
--headerTitle.TextColor3 = COLORS.Text
--headerTitle.TextSize = 20
--headerTitle.TextXAlignment = Enum.TextXAlignment.Left
--headerTitle.Parent = header

-- Money Display in Header
local moneyFrame = header:WaitForChild("MoneyInfoPanel")
--local moneyFrame = Instance.new("Frame")
--moneyFrame.Size = UDim2.new(0.25, 0, 0.583, 0)  -- 200/800, 35/60
--moneyFrame.Position = UDim2.new(0.575, 0, 0.5, 0)  -- (800-340)/800
--moneyFrame.AnchorPoint = Vector2.new(0, 0.5)
--moneyFrame.BackgroundColor3 = COLORS.Background
--moneyFrame.BorderSizePixel = 0
--moneyFrame.Parent = header

--createCorner(8).Parent = moneyFrame

--local moneyIcon = Instance.new("ImageLabel")
--moneyIcon.Size = UDim2.new(0.12, 0, 0.686, 0)  -- 24/200, 24/35
--moneyIcon.Position = UDim2.new(0.95, 0, 0.5, 0)
--moneyIcon.AnchorPoint = Vector2.new(1, 0.5)
--moneyIcon.BackgroundTransparency = 1
--moneyIcon.Image = "rbxassetid://7733964640"
--moneyIcon.ImageColor3 = COLORS.Success
--moneyIcon.Parent = moneyFrame

local moneyLabel = moneyFrame:WaitForChild("TextLabel")
--local moneyLabel = Instance.new("TextLabel")
--moneyLabel.Size = UDim2.new(0.8, 0, 1, 0)
--moneyLabel.Position = UDim2.new(0.05, 0, 0, 0)
--moneyLabel.BackgroundTransparency = 1
--moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.Text = "$0"
--moneyLabel.TextColor3 = COLORS.Success
--moneyLabel.TextSize = 16
--moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
--moneyLabel.Parent = moneyFrame

-- Add Money Button
local addMoneyBtn = moneyFrame:WaitForChild("AddButton")
--local addMoneyBtn = Instance.new("TextButton")
--addMoneyBtn.Size = UDim2.new(0.044, 0, 0.583, 0)  -- 35/800, 35/60
--addMoneyBtn.Position = UDim2.new(0.85, 0, 0.5, 0)
--addMoneyBtn.AnchorPoint = Vector2.new(0, 0.5)
--addMoneyBtn.BackgroundColor3 = COLORS.Accent
--addMoneyBtn.BorderSizePixel = 0
--addMoneyBtn.Text = "+"
--addMoneyBtn.Font = Enum.Font.GothamBold
--addMoneyBtn.TextSize = 20
--addMoneyBtn.TextColor3 = COLORS.Text
--addMoneyBtn.Parent = header

--createCorner(8).Parent = addMoneyBtn

-- Close Button
local closeBtn = header:WaitForChild("CloseButton")
--local closeBtn = Instance.new("TextButton")
--closeBtn.Size = UDim2.new(0.05, 0, 0.667, 0)  -- 40/800, 40/60
--closeBtn.Position = UDim2.new(0.9875, 0, 0.5, 0)
--closeBtn.AnchorPoint = Vector2.new(1, 0.5)
--closeBtn.BackgroundColor3 = COLORS.Button
--closeBtn.BorderSizePixel = 0
--closeBtn.Text = "✕"
--closeBtn.Font = Enum.Font.GothamBold
--closeBtn.TextSize = 20
--closeBtn.TextColor3 = COLORS.Text
--closeBtn.Parent = header

--createCorner(10).Parent = closeBtn

-- Tab Frame
local tabFrame = mainPanel:WaitForChild("Category")
local tabPanels = mainPanel:WaitForChild("Panel")

--local tabFrame = Instance.new("Frame")
--tabFrame.Size = UDim2.new(0.9625, 0, 0.08, 0)  -- (800-30)/800, 40/500
--tabFrame.Position = UDim2.new(0.019, 0, 0.14, 0)  -- 15/800, 70/500
--tabFrame.BackgroundTransparency = 1
--tabFrame.Parent = mainPanel

--local tabLayout = Instance.new("UIListLayout")
--tabLayout.FillDirection = Enum.FillDirection.Horizontal
--tabLayout.Padding = UDim.new(0, 8)
--tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
--tabLayout.Parent = tabFrame

-- Content Frame
--local contentFrame = Instance.new("Frame")
--contentFrame.Size = UDim2.new(0.9625, 0, 0.76, 0)  -- (500-130)/500
--contentFrame.Position = UDim2.new(0.019, 0, 0.24, 0)  -- 120/500
--contentFrame.BackgroundTransparency = 1
--contentFrame.Parent = mainPanel
-- ==================== TAB CREATION ====================
local tabs = {}

local function detectTab(tabName, order)
	local tab = tabFrame:WaitForChild(tabName.."Button")
	local stroke = tab:WaitForChild("UIStroke")
	stroke.Transparency = tabName == "Auras" and 0 or 1
	--local tab = Instance.new("TextButton")
	--tab.Size = UDim2.new(0, 0, 1, 0)
	--tab.BackgroundColor3 = tabName == "Auras" and COLORS.Accent or COLORS.Button
	--tab.BorderSizePixel = 0
	--tab.Font = Enum.Font.GothamBold
	--tab.Text = tabName
	--tab.TextColor3 = COLORS.Text
	--tab.TextSize = 14
	--tab.AutoButtonColor = false
	--tab.LayoutOrder = order
	--tab.Parent = tabFrame

	--createCorner(8).Parent = tab

	-- Auto size
	--local textSize = game:GetService("TextService"):GetTextSize(tabName, 14, Enum.Font.GothamBold, Vector2.new(1000, 40))
	--tab.Size = UDim2.new(0, textSize.X + 30, 1, 0)

	-- Content container
	local content = tabPanels:WaitForChild(tabName .. "Panel")
	--local content = Instance.new("Frame")
	--content.Name = tabName .. "Content"
	--content.Size = UDim2.new(1, 0, 1, 0)
	--content.BackgroundTransparency = 1
	--content.Visible = tabName == "Auras"
	--content.Parent = contentFrame

	tabs[tabName] = {Button = tab, Content = content, Stroke = stroke}

	tab.MouseButton1Click:Connect(function()
		-- Hide all tabs
		for _, tabData in pairs(tabs) do
			tabData.Content.Visible = false
			--tabData.Button.BackgroundColor3 = COLORS.Button
			tabData.Stroke.Transparency = 1
		end

		-- Show selected tab
		content.Visible = true
		--tab.BackgroundColor3 = COLORS.Accent
		stroke.Transparency = 0
		currentTab = tabName
	end)

	return content
end

-- Create tabs
local aurasContent = detectTab("Auras", 1)
local toolsContent = detectTab("Tools", 2)
local gamepassesContent = detectTab("Gamepasses", 3)
local moneyContent = detectTab("Money", 4)

-- ==================== AURAS TAB ====================
-- Filter Frame
local auraFilterFrame = aurasContent:WaitForChild("SubCategoryPanel")
--local auraFilterFrame = Instance.new("Frame")
--auraFilterFrame.Size = UDim2.new(1, 0, 0.092, 0)
--auraFilterFrame.BackgroundTransparency = 1
--auraFilterFrame.Parent = aurasContent

--local auraFilterLayout = Instance.new("UIListLayout")
--auraFilterLayout.FillDirection = Enum.FillDirection.Horizontal
--auraFilterLayout.Padding = UDim.new(0, 8)
--auraFilterLayout.Parent = auraFilterFrame

local function detectFilterBtn(text, filter)
	local btn = auraFilterFrame:WaitForChild(filter .. "Button")
	local stroke = btn:WaitForChild("UIStroke")
	--local btn = Instance.new("TextButton")
	--btn.Size = UDim2.new(0.117, 0, 1, 0)  -- 90/770 (content width)
	--btn.BackgroundColor3 = filter == "All" and COLORS.Accent or COLORS.Button
	--btn.BorderSizePixel = 0
	--btn.Font = Enum.Font.GothamBold
	--btn.Text = text
	--btn.TextColor3 = COLORS.Text
	--btn.TextSize = 13
	--btn.AutoButtonColor = false
	--btn.Parent = auraFilterFrame
	stroke.Transparency = filter == "All" and 0 or 1

	--createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		currentAuraFilter = filter
		for _, child in ipairs(auraFilterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				--child.BackgroundColor3 = COLORS.Button
				child:FindFirstChild("UIStroke").Transparency = 1
			end
		end
		--btn.BackgroundColor3 = COLORS.Accent
		stroke.Transparency = 0
		updateAurasList()
	end)

	return btn
end

detectFilterBtn("All", "All")
detectFilterBtn("Premium", "Premium")
detectFilterBtn("Free", "Free")

-- Auras Scroll
local aurasScroll = aurasContent:WaitForChild("AuraList")
local aurasSlot = aurasScroll:WaitForChild("ShopCard")
aurasSlot.Parent = playerGui
for _, child in aurasScroll:GetChildren() do
	if child:IsA("Frame") then
		child:Destroy()
	end
end
--local aurasScroll = Instance.new("ScrollingFrame")
--aurasScroll.Size = UDim2.new(1, 0, 0.882, 0)  -- (380-45)/380
--aurasScroll.Position = UDim2.new(0, 0, 0.118, 0)
--aurasScroll.BackgroundTransparency = 1
--aurasScroll.BorderSizePixel = 0
--aurasScroll.ScrollBarThickness = 4
--aurasScroll.ScrollBarImageColor3 = COLORS.Border
--aurasScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
--aurasScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
--aurasScroll.Parent = aurasContent

--local aurasGrid = Instance.new("UIGridLayout")
--aurasGrid.CellSize = UDim2.new(0.312, 0, 0.737, 0)  -- 240/770, 280/380
--aurasGrid.CellPadding = UDim2.new(0.013, 0, 0.026, 0)  -- 10/770, 10/380
--aurasGrid.SortOrder = Enum.SortOrder.LayoutOrder
--aurasGrid.Parent = aurasScroll

local aurasEmptyLabel = aurasContent:WaitForChild("EmptyLabel")
--local aurasEmptyLabel = Instance.new("TextLabel")
--aurasEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
--aurasEmptyLabel.BackgroundTransparency = 1
--aurasEmptyLabel.Font = Enum.Font.Gotham
--aurasEmptyLabel.Text = "Kamu sudah membeli semua aura, Terimakasih"
--aurasEmptyLabel.TextColor3 = COLORS.TextSecondary
--aurasEmptyLabel.TextSize = 14
--aurasEmptyLabel.Visible = false
--aurasEmptyLabel.Parent = aurasScroll

-- ==================== TOOLS TAB ====================
-- Filter Frame
local toolFilterFrame = toolsContent:WaitForChild("SubCategoryPanel")
--local toolFilterFrame = Instance.new("Frame")
--toolFilterFrame.Size = UDim2.new(1, 0, 0.092, 0)
--toolFilterFrame.BackgroundTransparency = 1
--toolFilterFrame.Parent = toolsContent

--local toolFilterLayout = Instance.new("UIListLayout")
--toolFilterLayout.FillDirection = Enum.FillDirection.Horizontal
--toolFilterLayout.Padding = UDim.new(0, 8)
--toolFilterLayout.Parent = toolFilterFrame

local function detectToolFilterBtn(text, filter)
	local btn = toolFilterFrame:WaitForChild(filter .. "Button")
	local stroke = btn:WaitForChild("UIStroke")
	stroke.Transparency = filter == "All" and 0 or 1
	--local btn = Instance.new("TextButton")
	--btn.Size = UDim2.new(0.117, 0, 1, 0)
	--btn.BackgroundColor3 = filter == "All" and COLORS.Accent or COLORS.Button
	--btn.BorderSizePixel = 0
	--btn.Font = Enum.Font.GothamBold
	--btn.Text = text
	--btn.TextColor3 = COLORS.Text
	--btn.TextSize = 13
	--btn.AutoButtonColor = false
	--btn.Parent = toolFilterFrame

	--createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		currentToolFilter = filter
		for _, child in ipairs(toolFilterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				--child.BackgroundColor3 = COLORS.Button
				child:FindFirstChild("UIStroke").Transparency = 1
			end
		end
		--btn.BackgroundColor3 = COLORS.Accent
		stroke.Transparency = 0
		updateToolsList()
	end)

	return btn
end

detectToolFilterBtn("All", "All")
detectToolFilterBtn("Premium", "Premium")
detectToolFilterBtn("Free", "Free")

-- Tools Scroll
local toolsScroll = toolsContent:WaitForChild("ToolList")

local toolSlot = toolsScroll:WaitForChild("ShopCard")
toolSlot.Parent = playerGui
for _, child in toolsScroll:GetChildren() do
	if child:IsA("Frame") then
		child:Destroy()
	end
end
--local toolsScroll = Instance.new("ScrollingFrame")
--toolsScroll.Size = UDim2.new(1, 0, 0.882, 0)
--toolsScroll.Position = UDim2.new(0, 0, 0.118, 0)
--toolsScroll.BackgroundTransparency = 1
--toolsScroll.BorderSizePixel = 0
--toolsScroll.ScrollBarThickness = 4
--toolsScroll.ScrollBarImageColor3 = COLORS.Border
--toolsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
--toolsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
--toolsScroll.Parent = toolsContent

--local toolsGrid = Instance.new("UIGridLayout")
--toolsGrid.CellSize = UDim2.new(0.312, 0, 0.737, 0)
--toolsGrid.CellPadding = UDim2.new(0.013, 0, 0.026, 0)
--toolsGrid.SortOrder = Enum.SortOrder.LayoutOrder
--toolsGrid.Parent = toolsScroll

local toolsEmptyLabel = toolsContent:WaitForChild("EmptyLabel")
--local toolsEmptyLabel = Instance.new("TextLabel")
--toolsEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
--toolsEmptyLabel.BackgroundTransparency = 1
--toolsEmptyLabel.Font = Enum.Font.Gotham
--toolsEmptyLabel.Text = "Kamu sudah membeli semua tools, Terimakasih"
--toolsEmptyLabel.TextColor3 = COLORS.TextSecondary
--toolsEmptyLabel.TextSize = 14
--toolsEmptyLabel.Visible = false
--toolsEmptyLabel.Parent = toolsScroll

-- ==================== GAMEPASSES TAB ====================
local gamepassScroll = gamepassesContent:WaitForChild("GamepassList")
local gamepassSlot = gamepassScroll:WaitForChild("ShopCard")
gamepassSlot.Parent = playerGui
for _, child in gamepassScroll:GetChildren() do
	if child:IsA("Frame") then
		child:Destroy()
	end
end
--local gamepassScroll = Instance.new("ScrollingFrame")
--gamepassScroll.Size = UDim2.new(1, 0, 1, 0)
--gamepassScroll.BackgroundTransparency = 1
--gamepassScroll.BorderSizePixel = 0
--gamepassScroll.ScrollBarThickness = 6
--gamepassScroll.ScrollBarImageColor3 = COLORS.Border
--gamepassScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
--gamepassScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
--gamepassScroll.ScrollingDirection = Enum.ScrollingDirection.X
--gamepassScroll.Parent = gamepassesContent

--local gamepassLayout = Instance.new("UIListLayout")
--gamepassLayout.Padding = UDim.new(0, 10)
--gamepassLayout.FillDirection = Enum.FillDirection.Horizontal
--gamepassLayout.SortOrder = Enum.SortOrder.LayoutOrder
--gamepassLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
--gamepassLayout.VerticalAlignment = Enum.VerticalAlignment.Top
--gamepassLayout.Parent = gamepassScroll

--local gamepassPadding = Instance.new("UIPadding")
--gamepassPadding.PaddingLeft = UDim.new(0, 5)
--gamepassPadding.PaddingRight = UDim.new(0, 5)
--gamepassPadding.PaddingTop = UDim.new(0, 5)
--gamepassPadding.Parent = gamepassScroll

local gamepassEmptyLabel = gamepassesContent:WaitForChild("EmptyLabel")
--local gamepassEmptyLabel = Instance.new("TextLabel")
--gamepassEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
--gamepassEmptyLabel.BackgroundTransparency = 1
--gamepassEmptyLabel.Font = Enum.Font.Gotham
--gamepassEmptyLabel.Text = "Kamu sudah membeli semua gamepass, Terimakasih"
--gamepassEmptyLabel.TextColor3 = COLORS.TextSecondary
--gamepassEmptyLabel.TextSize = 14
--gamepassEmptyLabel.Visible = false
--gamepassEmptyLabel.Parent = gamepassScroll

-- ==================== MONEY TAB ====================
local moneyScroll = moneyContent:WaitForChild("MoneysList")
local moneySlot = moneyScroll:WaitForChild("ShopCard")
moneySlot.Parent = playerGui
for _, child in moneyScroll:GetChildren() do
	if child:IsA("Frame") then
		child:Destroy()
	end
end
--local moneyScroll = Instance.new("ScrollingFrame")
--moneyScroll.Size = UDim2.new(1, 0, 1, 0)
--moneyScroll.BackgroundTransparency = 1
--moneyScroll.BorderSizePixel = 0
--moneyScroll.ScrollBarThickness = 6
--moneyScroll.ScrollBarImageColor3 = COLORS.Border
--moneyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
--moneyScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
--moneyScroll.ScrollingDirection = Enum.ScrollingDirection.X
--moneyScroll.Parent = moneyContent

--local moneyLayout = Instance.new("UIListLayout")
--moneyLayout.Padding = UDim.new(0, 10)
--moneyLayout.FillDirection = Enum.FillDirection.Horizontal
--moneyLayout.SortOrder = Enum.SortOrder.LayoutOrder
--moneyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
--moneyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
--moneyLayout.Parent = moneyScroll

--local moneyPadding = Instance.new("UIPadding")
--moneyPadding.PaddingLeft = UDim.new(0, 5)
--moneyPadding.PaddingRight = UDim.new(0, 5)
--moneyPadding.PaddingTop = UDim.new(0, 5)
--moneyPadding.Parent = moneyScroll

-- ==================== ITEM CREATION FUNCTIONS ====================

local function createAuraItem(auraData)

	local frame = aurasSlot:Clone()
	--local frame = Instance.new("Frame")
	--frame.BackgroundColor3 = COLORS.Panel
	--frame.BorderSizePixel = 0
	frame.Parent = aurasScroll
	
	

	--createCorner(10).Parent = frame

	-- Thumbnail
	--local thumbnail = Instance.new("ImageLabel")
	--thumbnail.Size = UDim2.new(0.917, 0, 0.5, 0)
	--thumbnail.Position = UDim2.new(0.042, 0, 0.036, 0)
	--thumbnail.BackgroundColor3 = COLORS.Button
	--thumbnail.BorderSizePixel = 0
	--thumbnail.Image = auraData.Thumbnail
	--thumbnail.Parent = frame

	--createCorner(8).Parent = thumbnail
	local premiumColor = Color3.fromHex("#2fff00")
	local normalColor = Color3.fromHex("#ffe100")
	
	local premiumStroke = Color3.fromHex("#a5a500")
	local normalStroke = Color3.fromHex("#4d565b")

	local premiumButton =Color3.fromHex("#e2d21f")
	local normalButton = Color3.fromHex("#c5d4e2")

	frame:FindFirstChild("UIStroke").Color = auraData.IsPremium and premiumStroke or normalStroke
	local thumbnailFrame = frame:FindFirstChild("ThumbnailFrame")
	local premiumLabel = thumbnailFrame:FindFirstChild("PremiumLabel")
	premiumLabel.Visible = auraData.IsPremium
	
	frame:FindFirstChild("BuyButton").BackgroundColor3 = auraData.IsPremium and premiumButton or normalButton
	frame:FindFirstChild("ProductPrice").TextColor3 = auraData.IsPremium and premiumColor or normalColor

	frame:FindFirstChild("ProductPrice").Text = auraData.IsPremium and ("" .. auraData.Price) or formatMoney(auraData.Price)
	frame:FindFirstChild("ProductTitle").Text = auraData.Title
	
	thumbnailFrame:FindFirstChild("Thumbnail").Image = auraData.Thumbnail
	

	-- Premium Badge
	--if auraData.IsPremium then
	--	local badge = Instance.new("Frame")
	--	badge.Size = UDim2.new(0.364, 0, 0.171, 0)
	--	badge.Position = UDim2.new(0.045, 0, 0.071, 0)
	--	badge.BackgroundColor3 = COLORS.Premium
	--	badge.BorderSizePixel = 0
	--	badge.Parent = thumbnail

	--	createCorner(6).Parent = badge

	--	local badgeLabel = Instance.new("TextLabel")
	--	badgeLabel.Size = UDim2.new(1, 0, 1, 0)
	--	badgeLabel.BackgroundTransparency = 1
	--	badgeLabel.Font = Enum.Font.GothamBold
	--	badgeLabel.Text = "PREMIUM"
	--	badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	--	badgeLabel.TextSize = 11
	--	badgeLabel.Parent = badge
	--end

	---- Title
	--local titleLabel = Instance.new("TextLabel")
	--titleLabel.Size = UDim2.new(0.943, 0, 0.079, 0)
	--titleLabel.Position = UDim2.new(0.029, 0, 0.474, 0)
	--titleLabel.BackgroundTransparency = 1
	--titleLabel.Font = Enum.Font.GothamBold
	--titleLabel.Text = auraData.Title
	--titleLabel.TextColor3 = COLORS.Text
	--titleLabel.TextSize = 14
	--titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	--titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	--titleLabel.Parent = frame

	---- Price
	--local priceLabel = Instance.new("TextLabel")
	--priceLabel.Size = UDim2.new(0.917, 0, 0.071, 0)
	--priceLabel.Position = UDim2.new(0.042, 0, 0.679, 0)
	--priceLabel.BackgroundTransparency = 1
	--priceLabel.Font = Enum.Font.GothamBold
	--priceLabel.Text = auraData.IsPremium and ("R$ " .. auraData.Price) or formatMoney(auraData.Price)
	--priceLabel.TextColor3 = auraData.IsPremium and COLORS.Premium or COLORS.Success
	--priceLabel.TextSize = 16
	--priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	--priceLabel.Parent = frame

	---- Buy Button
	--local buyBtn = Instance.new("TextButton")
	--buyBtn.Size = UDim2.new(0.917, 0, 0.161, 0)
	--buyBtn.Position = UDim2.new(0.042, 0, 0.804, 0)
	--buyBtn.BackgroundColor3 = COLORS.Accent
	--buyBtn.BorderSizePixel = 0
	--buyBtn.Font = Enum.Font.GothamBold
	--buyBtn.Text = "Buy"
	--buyBtn.TextColor3 = COLORS.Text
	--buyBtn.TextSize = 15
	--buyBtn.AutoButtonColor = false
	--buyBtn.Parent = frame

	--createCorner(8).Parent = buyBtn

	-- Bagian buy button di createAuraItem
	frame:FindFirstChild("BuyButton").MouseButton1Click:Connect(function()
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

	local frame = aurasSlot:Clone()
	--local frame = Instance.new("Frame")
	--frame.BackgroundColor3 = COLORS.Panel
	--frame.BorderSizePixel = 0
	frame.Parent = toolsScroll



	--createCorner(10).Parent = frame

	-- Thumbnail
	--local thumbnail = Instance.new("ImageLabel")
	--thumbnail.Size = UDim2.new(0.917, 0, 0.5, 0)
	--thumbnail.Position = UDim2.new(0.042, 0, 0.036, 0)
	--thumbnail.BackgroundColor3 = COLORS.Button
	--thumbnail.BorderSizePixel = 0
	--thumbnail.Image = auraData.Thumbnail
	--thumbnail.Parent = frame

	--createCorner(8).Parent = thumbnail
	local premiumColor = Color3.fromHex("#2fff00")
	local normalColor = Color3.fromHex("#ffe100")

	local premiumStroke = Color3.fromHex("#a5a500")
	local normalStroke = Color3.fromHex("#4d565b")

	local premiumButton =Color3.fromHex("#e2d21f")
	local normalButton = Color3.fromHex("#c5d4e2")

	frame:FindFirstChild("UIStroke").Color = toolData.IsPremium and premiumStroke or normalStroke
	local thumbnailFrame = frame:FindFirstChild("ThumbnailFrame")
	local premiumLabel = thumbnailFrame:FindFirstChild("PremiumLabel")
	premiumLabel.Visible = toolData.IsPremium

	frame:FindFirstChild("BuyButton").BackgroundColor3 = toolData.IsPremium and premiumButton or normalButton
	frame:FindFirstChild("ProductPrice").TextColor3 = toolData.IsPremium and premiumColor or normalColor

	thumbnailFrame:FindFirstChild("Thumbnail").Image = toolData.Thumbnail

	frame:FindFirstChild("ProductPrice").Text = toolData.IsPremium and ("" .. toolData.Price) or formatMoney(toolData.Price)
	frame:FindFirstChild("ProductTitle").Text = toolData.Title
	
	-- Premium Badge
	--if auraData.IsPremium then
	--	local badge = Instance.new("Frame")
	--	badge.Size = UDim2.new(0.364, 0, 0.171, 0)
	--	badge.Position = UDim2.new(0.045, 0, 0.071, 0)
	--	badge.BackgroundColor3 = COLORS.Premium
	--	badge.BorderSizePixel = 0
	--	badge.Parent = thumbnail

	--	createCorner(6).Parent = badge

	--	local badgeLabel = Instance.new("TextLabel")
	--	badgeLabel.Size = UDim2.new(1, 0, 1, 0)
	--	badgeLabel.BackgroundTransparency = 1
	--	badgeLabel.Font = Enum.Font.GothamBold
	--	badgeLabel.Text = "PREMIUM"
	--	badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	--	badgeLabel.TextSize = 11
	--	badgeLabel.Parent = badge
	--end

	---- Title
	--local titleLabel = Instance.new("TextLabel")
	--titleLabel.Size = UDim2.new(0.943, 0, 0.079, 0)
	--titleLabel.Position = UDim2.new(0.029, 0, 0.474, 0)
	--titleLabel.BackgroundTransparency = 1
	--titleLabel.Font = Enum.Font.GothamBold
	--titleLabel.Text = auraData.Title
	--titleLabel.TextColor3 = COLORS.Text
	--titleLabel.TextSize = 14
	--titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	--titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	--titleLabel.Parent = frame

	---- Price
	--local priceLabel = Instance.new("TextLabel")
	--priceLabel.Size = UDim2.new(0.917, 0, 0.071, 0)
	--priceLabel.Position = UDim2.new(0.042, 0, 0.679, 0)
	--priceLabel.BackgroundTransparency = 1
	--priceLabel.Font = Enum.Font.GothamBold
	--priceLabel.Text = auraData.IsPremium and ("R$ " .. auraData.Price) or formatMoney(auraData.Price)
	--priceLabel.TextColor3 = auraData.IsPremium and COLORS.Premium or COLORS.Success
	--priceLabel.TextSize = 16
	--priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	--priceLabel.Parent = frame

	---- Buy Button
	--local buyBtn = Instance.new("TextButton")
	--buyBtn.Size = UDim2.new(0.917, 0, 0.161, 0)
	--buyBtn.Position = UDim2.new(0.042, 0, 0.804, 0)
	--buyBtn.BackgroundColor3 = COLORS.Accent
	--buyBtn.BorderSizePixel = 0
	--buyBtn.Font = Enum.Font.GothamBold
	--buyBtn.Text = "Buy"
	--buyBtn.TextColor3 = COLORS.Text
	--buyBtn.TextSize = 15
	--buyBtn.AutoButtonColor = false
	--buyBtn.Parent = frame

	--createCorner(8).Parent = buyBtn

	-- Bagian buy button di createToolItem
	frame:FindFirstChild("BuyButton").MouseButton1Click:Connect(function()
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

local function createGamepassItem(gamepassData)
	local frame = gamepassSlot:Clone()
	
	--local frame = Instance.new("Frame")
	--frame.Size = UDim2.new(0.455, 0, 1, 0) -- Kurangi height dari 450 ke 380
	--frame.BackgroundColor3 = COLORS.Panel
	--frame.BorderSizePixel = 0
	frame.Parent = gamepassScroll

	--createCorner(10).Parent = frame
	
	frame:FindFirstChild("ThumbnailFrame"):FindFirstChild("Thumbnail").Image = gamepassData.Thumbnail
	-- Thumbnail
	--local thumbnail = Instance.new("ImageLabel")
	--thumbnail.Size = UDim2.new(0.943, 0, 0.421, 0)
	--thumbnail.Position = UDim2.new(0.029, 0, 0.026, 0)
	--thumbnail.BackgroundColor3 = COLORS.Button
	--thumbnail.BorderSizePixel = 0
	--thumbnail.Image = gamepassData.Thumbnail
	--thumbnail.Parent = frame

	--createCorner(8).Parent = thumbnail

	-- Title
	--local titleLabel = Instance.new("TextLabel")
	--titleLabel.Size = UDim2.new(0.943, 0, 0.079, 0)
	--titleLabel.Position = UDim2.new(0.029, 0, 0.474, 0)-- Sesuaikan posisi
	--titleLabel.BackgroundTransparency = 1
	--titleLabel.Font = Enum.Font.GothamBold
	--titleLabel.Text = gamepassData.Name
	--titleLabel.TextColor3 = COLORS.Text
	--titleLabel.TextSize = 18
	--titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	--titleLabel.Parent = frame
	
	frame:FindFirstChild("ProductTitle").Text = gamepassData.Name
	frame:FindFirstChild("ProductDescription").Text = gamepassData.Description or ""

	-- Description
	--local descLabel = Instance.new("TextLabel")
	--descLabel.Size = UDim2.new(0.943, 0, 0.132, 0)
	--descLabel.Position = UDim2.new(0.029, 0, 0.566, 0)
	--descLabel.BackgroundTransparency = 1
	--descLabel.Font = Enum.Font.Gotham
	--descLabel.Text = gamepassData.Description or ""
	--descLabel.TextColor3 = COLORS.TextSecondary
	--descLabel.TextSize = 12
	--descLabel.TextWrapped = true
	--descLabel.TextXAlignment = Enum.TextXAlignment.Left
	--descLabel.TextYAlignment = Enum.TextYAlignment.Top
	--descLabel.Parent = frame

	---- Price
	--local priceLabel = Instance.new("TextLabel")
	--priceLabel.Size = UDim2.new(0.943, 0, 0.066, 0)
	--priceLabel.Position = UDim2.new(0.029, 0, 0.711, 0)
	--priceLabel.BackgroundTransparency = 1
	--priceLabel.Font = Enum.Font.GothamBold
	--priceLabel.Text = "R$ " .. gamepassData.Price
	--priceLabel.TextColor3 = COLORS.Premium
	--priceLabel.TextSize = 20
	--priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	--priceLabel.Parent = frame

	---- Buy Button
	--local buyBtn = Instance.new("TextButton")
	--buyBtn.Size = UDim2.new(0.943, 0, 0.118, 0)
	--buyBtn.Position = UDim2.new(0.029, 0, 0.803, 0) -- Posisi tetap terlihat
	--buyBtn.BackgroundColor3 = COLORS.Success
	--buyBtn.BorderSizePixel = 0
	--buyBtn.Font = Enum.Font.GothamBold
	--buyBtn.Text = "Purchase"
	--buyBtn.TextColor3 = COLORS.Text
	--buyBtn.TextSize = 16
	--buyBtn.AutoButtonColor = false
	--buyBtn.Parent = frame

	--createCorner(8).Parent = buyBtn
	
	frame:FindFirstChild("BuyButton"):FindFirstChild("TextLabel").Text = "" .. gamepassData.Price

	frame:FindFirstChild("BuyButton").MouseButton1Click:Connect(function()
		purchaseGamepassEvent:FireServer(gamepassData.Name)
	end)

	return frame
end

local function createMoneyPackItem(packData)
	local frame = moneySlot:Clone()
	--local frame = Instance.new("Frame")
	--frame.Size = UDim2.new(0.364, 0, 0.947, 0)
	--frame.BackgroundColor3 = COLORS.Panel
	--frame.BorderSizePixel = 0
	frame.Parent = moneyScroll

	--createCorner(10).Parent = frame

	-- Thumbnail
	frame:FindFirstChild("ThumbnailFrame"):FindFirstChild("Thumbnail").Image = packData.Thumbnail
	
	--local thumbnail = Instance.new("ImageLabel")
	--thumbnail.Size = UDim2.new(0.943, 0, 0.421, 0)  -- (350-20)/350, 160/380
	--thumbnail.Position = UDim2.new(0.029, 0, 0.026, 0)
	--thumbnail.BackgroundColor3 = COLORS.Button
	--thumbnail.BorderSizePixel = 0
	--thumbnail.Image = packData.Thumbnail
	--thumbnail.Parent = frame

	--createCorner(8).Parent = thumbnail

	-- Title
	frame:FindFirstChild("ProductTitle").Text = packData.Title
	--local titleLabel = Instance.new("TextLabel")
	--titleLabel.Size = UDim2.new(0.929, 0, 0.078, 0)
	--titleLabel.Position = UDim2.new(0.036, 0, 0.556, 0)
	--titleLabel.BackgroundTransparency = 1
	--titleLabel.Font = Enum.Font.GothamBold
	--titleLabel.Text = packData.Title
	--titleLabel.TextColor3 = COLORS.Text
	--titleLabel.TextSize = 16
	--titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	--titleLabel.Parent = frame

	-- Reward
	frame:FindFirstChild("ProductDescription").Text = formatMoney(packData.MoneyReward)
	--local rewardLabel = Instance.new("TextLabel")
	--rewardLabel.Size = UDim2.new(0.929, 0, 0.083, 0)
	--rewardLabel.Position = UDim2.new(0.036, 0, 0.647, 0)
	--rewardLabel.BackgroundTransparency = 1
	--rewardLabel.Font = Enum.Font.GothamBold
	--rewardLabel.Text = formatMoney(packData.MoneyReward)
	--rewardLabel.TextColor3 = COLORS.Success
	--rewardLabel.TextSize = 22
	--rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	--rewardLabel.Parent = frame

	---- Price
	--local priceLabel = Instance.new("TextLabel")
	--priceLabel.Size = UDim2.new(0.929, 0, 0.061, 0)
	--priceLabel.Position = UDim2.new(0.036, 0, 0.744, 0)
	--priceLabel.BackgroundTransparency = 1
	--priceLabel.Font = Enum.Font.GothamBold
	--priceLabel.Text = "R$ " .. packData.Price
	--priceLabel.TextColor3 = COLORS.Premium
	--priceLabel.TextSize = 18
	--priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	--priceLabel.Parent = frame

	-- Buy Button
	--local buyBtn = Instance.new("TextButton")
	--buyBtn.Size = UDim2.new(0.943, 0, 0.118, 0)
	--buyBtn.Position = UDim2.new(0.029, 0, 0.803, 0)
	--buyBtn.BackgroundColor3 = COLORS.Success
	--buyBtn.BorderSizePixel = 0
	--buyBtn.Font = Enum.Font.GothamBold
	--buyBtn.Text = "Purchase"
	--buyBtn.TextColor3 = COLORS.Text
	--buyBtn.TextSize = 16
	--buyBtn.AutoButtonColor = false
	--buyBtn.Parent = frame

	--createCorner(8).Parent = buyBtn
	frame:FindFirstChild("BuyButton"):FindFirstChild("TextLabel").Text = "" .. packData.Price
	frame:FindFirstChild("BuyButton").MouseButton1Click:Connect(function()
		purchaseMoneyPackEvent:FireServer(packData.ProductId)
	end)

	return frame
end

-- ==================== UPDATE FUNCTIONS ====================

function updateAurasList()
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
	mainPanel.Visible = false
	screenGui.Enabled = false
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
			framePos = frame.Position

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

			-- ✅ Konversi ke scale
			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			frame.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,  -- ✅ Offset = 0
				framePos.Y.Scale + deltaScaleY,
				0   -- ✅ Offset = 0
			)
		end
	end)
end

makeDraggable(mainPanel, header)

-- ==================== TOPBAR ICON ====================
local shopIcon = Icon.new()
	:setImage("rbxassetid://99623444925621")
	:setLabel("Shop")
	:bindEvent("selected", function()
		screenGui.Enabled = true
		mainPanel.Visible = true
		refreshShopData()
	end)
	:bindEvent("deselected", function()
		screenGui.Enabled = false
		mainPanel.Visible = false
	end)

-- Initial load with delay
task.spawn(function()
	task.wait(2)
	refreshShopData()
end)

print("✓ Shop System Client loaded successfully")