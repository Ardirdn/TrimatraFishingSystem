--[[
    INVENTORY CLIENT v3.0 - WITH TITLES TAB & EQUIP SYSTEM
    Place in StarterPlayerScripts/InventoryClientV3
    
    PENTING: Hapus script InventorySystemClient yang lama!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hide default Roblox backpack/hotbar (we use custom inventory)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local HUDButtonHelper = require(script.Parent:WaitForChild("HUDButtonHelper"))
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))
local InventoryConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryConfig"))
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- RemoteEvents
local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 10)
if not inventoryRemotes then
	warn("[INVENTORY CLIENT v3] InventoryRemotes not found!")
	return
end

local getInventoryFunc = inventoryRemotes:WaitForChild("GetInventory", 10)

-- ✅ FIX: Use WaitForChild instead of FindFirstChild to wait for server to create remotes
local equipAuraEvent = inventoryRemotes:WaitForChild("EquipAura", 10)
local unequipAuraEvent = inventoryRemotes:WaitForChild("UnequipAura", 10)
local equipToolEvent = inventoryRemotes:WaitForChild("EquipTool", 10)
local unequipToolEvent = inventoryRemotes:WaitForChild("UnequipTool", 10)

-- Check if inventory remotes exist (optional for backward compatibility)
if not equipAuraEvent then
	warn("[INVENTORY CLIENT v3] EquipAura not found after 10s wait - Aura equip disabled")
end
if not equipToolEvent then
	warn("[INVENTORY CLIENT v3] EquipTool not found after 10s wait - Tool equip disabled")
end

local titleRemotes = ReplicatedStorage:WaitForChild("TitleRemotes", 10)
if not titleRemotes then
	warn("[INVENTORY CLIENT v3] TitleRemotes not found!")
	return
end

local getUnlockedTitlesFunc = titleRemotes:WaitForChild("GetUnlockedTitles", 5)
local equipTitleEvent = titleRemotes:WaitForChild("EquipTitle", 5)
local unequipTitleEvent = titleRemotes:WaitForChild("UnequipTitle", 5)

-- State
local currentCategory = "All"
local currentTitleFilter = "All"
local inventoryData = {
	OwnedAuras = {},
	OwnedTools = {},
	EquippedAura = nil,
	EquippedTool = nil
}

local titleData = {
	UnlockedTitles = {},
	EquippedTitle = nil
}

-- Colors
local COLORS = InventoryConfig.Colors

-- Forward declarations (defined later)
local isInventoryOpen = false
local toggleInventory

print("✅ [INVENTORY CLIENT v3] Starting initialization...")

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

-- ==================== CREATE GUI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGUI_V3"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true
screenGui.Parent = playerGui

-- Main Container (untuk aspect ratio)
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0.55, 0, 0.8, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = screenGui

-- Aspect Ratio Constraint
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1.4
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
mainPadding.PaddingLeft = UDim.new(0.025, 0)
mainPadding.PaddingRight = UDim.new(0.025, 0)
mainPadding.PaddingTop = UDim.new(0.02, 0)
mainPadding.PaddingBottom = UDim.new(0.025, 0)
mainPadding.Parent = mainPanel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.12, 0)
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
headerTitle.Size = UDim2.new(0.35, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "📦 INVENTORY"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

createTextSizeConstraint(14, 24).Parent = headerTitle

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

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Danger}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Button}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
	if isInventoryOpen then
		toggleInventory()
	end
end)

-- Category Frame
local categoryFrame = Instance.new("Frame")
categoryFrame.Size = UDim2.new(1, 0, 0.08, 0)
categoryFrame.Position = UDim2.new(0, 0, 0.14, 0)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = mainPanel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0.015, 0)
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Parent = categoryFrame

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 0.74, 0)
contentFrame.Position = UDim2.new(0, 0, 0.24, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainPanel

-- ==================== CATEGORY TABS ====================

local categoryTabs = {}

local function createCategoryTab(categoryName, order)
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0.15, 0, 1, 0)
	tab.BackgroundColor3 = categoryName == "All" and COLORS.Accent or COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.Text = categoryName
	tab.TextColor3 = COLORS.Text
	tab.TextScaled = true
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = categoryFrame

	createScaledCorner(0.2).Parent = tab
	createTextSizeConstraint(10, 16).Parent = tab
	
	-- Tab padding
	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0.1, 0)
	tabPadding.PaddingRight = UDim.new(0.1, 0)
	tabPadding.PaddingTop = UDim.new(0.15, 0)
	tabPadding.PaddingBottom = UDim.new(0.15, 0)
	tabPadding.Parent = tab

	local content = Instance.new("Frame")
	content.Name = categoryName .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Visible = categoryName == "All"
	content.Parent = contentFrame

	categoryTabs[categoryName] = {Button = tab, Content = content}

	tab.MouseButton1Click:Connect(function()
		for _, tabData in pairs(categoryTabs) do
			tabData.Content.Visible = false
			tabData.Button.BackgroundColor3 = COLORS.Button
		end

		content.Visible = true
		tab.BackgroundColor3 = COLORS.Accent
		currentCategory = categoryName

		if categoryName == "Titles" then
			updateTitlesTab()
		else
			updateInventory()
		end
	end)

	return content
end

local allContent = createCategoryTab("All", 1)
local aurasContent = createCategoryTab("Auras", 2)
local toolsContent = createCategoryTab("Tools", 3)
local titlesContent = createCategoryTab("Titles", 4)

-- ==================== ALL TAB ====================

local allScroll = Instance.new("ScrollingFrame")
allScroll.Size = UDim2.new(1, 0, 1, 0)
allScroll.BackgroundTransparency = 1
allScroll.BorderSizePixel = 0
allScroll.ScrollBarThickness = 6
allScroll.ScrollBarImageColor3 = COLORS.Border
allScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
allScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
allScroll.Parent = allContent

local allScrollPadding = Instance.new("UIPadding")
allScrollPadding.PaddingTop = UDim.new(0.02, 0)
allScrollPadding.PaddingBottom = UDim.new(0.02, 0)
allScrollPadding.Parent = allScroll

local allGrid = Instance.new("UIGridLayout")
allGrid.CellSize = UDim2.new(0.22, 0, 0, 120)
allGrid.CellPadding = UDim2.new(0.025, 0, 0, 12)
allGrid.SortOrder = Enum.SortOrder.LayoutOrder
allGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
allGrid.Parent = allScroll

-- ==================== AURAS TAB ====================

local aurasScroll = Instance.new("ScrollingFrame")
aurasScroll.Size = UDim2.new(1, 0, 1, 0)
aurasScroll.BackgroundTransparency = 1
aurasScroll.BorderSizePixel = 0
aurasScroll.ScrollBarThickness = 6
aurasScroll.ScrollBarImageColor3 = COLORS.Border
aurasScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
aurasScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
aurasScroll.Parent = aurasContent

local aurasScrollPadding = Instance.new("UIPadding")
aurasScrollPadding.PaddingTop = UDim.new(0.02, 0)
aurasScrollPadding.PaddingBottom = UDim.new(0.02, 0)
aurasScrollPadding.Parent = aurasScroll

local aurasGrid = Instance.new("UIGridLayout")
aurasGrid.CellSize = UDim2.new(0.22, 0, 0, 120)
aurasGrid.CellPadding = UDim2.new(0.025, 0, 0, 12)
aurasGrid.SortOrder = Enum.SortOrder.LayoutOrder
aurasGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
aurasGrid.Parent = aurasScroll

-- ==================== TOOLS TAB ====================

local toolsScroll = Instance.new("ScrollingFrame")
toolsScroll.Size = UDim2.new(1, 0, 1, 0)
toolsScroll.BackgroundTransparency = 1
toolsScroll.BorderSizePixel = 0
toolsScroll.ScrollBarThickness = 6
toolsScroll.ScrollBarImageColor3 = COLORS.Border
toolsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
toolsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
toolsScroll.Parent = toolsContent

local toolsScrollPadding = Instance.new("UIPadding")
toolsScrollPadding.PaddingTop = UDim.new(0.02, 0)
toolsScrollPadding.PaddingBottom = UDim.new(0.02, 0)
toolsScrollPadding.Parent = toolsScroll

local toolsGrid = Instance.new("UIGridLayout")
toolsGrid.CellSize = UDim2.new(0.22, 0, 0, 120)
toolsGrid.CellPadding = UDim2.new(0.025, 0, 0, 12)
toolsGrid.SortOrder = Enum.SortOrder.LayoutOrder
toolsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
toolsGrid.Parent = toolsScroll

-- ==================== TITLES TAB ====================

-- Filter Frame
local titleFilterFrame = Instance.new("Frame")
titleFilterFrame.Size = UDim2.new(1, 0, 0.1, 0)
titleFilterFrame.BackgroundTransparency = 1
titleFilterFrame.Parent = titlesContent

local titleFilterLayout = Instance.new("UIListLayout")
titleFilterLayout.FillDirection = Enum.FillDirection.Horizontal
titleFilterLayout.Padding = UDim.new(0.02, 0)
titleFilterLayout.Parent = titleFilterFrame

local function createTitleFilterBtn(text, filter)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.18, 0, 1, 0)
	btn.BackgroundColor3 = filter == "All" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = titleFilterFrame

	createScaledCorner(0.2).Parent = btn
	createTextSizeConstraint(10, 14).Parent = btn

	btn.MouseButton1Click:Connect(function()
		currentTitleFilter = filter
		for _, child in ipairs(titleFilterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Button
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
		updateTitlesTab()
	end)

	return btn
end

createTitleFilterBtn("All", "All")
createTitleFilterBtn("Special", "Special")
createTitleFilterBtn("Summit", "Summit")

-- Titles Scroll
local titlesScroll = Instance.new("ScrollingFrame")
titlesScroll.Size = UDim2.new(1, 0, 0.88, 0)
titlesScroll.Position = UDim2.new(0, 0, 0.12, 0)
titlesScroll.BackgroundTransparency = 1
titlesScroll.BorderSizePixel = 0
titlesScroll.ScrollBarThickness = 6
titlesScroll.ScrollBarImageColor3 = COLORS.Border
titlesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
titlesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
titlesScroll.Parent = titlesContent

local titlesScrollPadding = Instance.new("UIPadding")
titlesScrollPadding.PaddingTop = UDim.new(0.02, 0)
titlesScrollPadding.PaddingBottom = UDim.new(0.02, 0)
titlesScrollPadding.Parent = titlesScroll

local titlesGrid = Instance.new("UIGridLayout")
titlesGrid.CellSize = UDim2.new(0.48, 0, 0, 70)
titlesGrid.CellPadding = UDim2.new(0.025, 0, 0, 10)
titlesGrid.SortOrder = Enum.SortOrder.LayoutOrder
titlesGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
titlesGrid.Parent = titlesScroll

local titlesEmptyLabel = Instance.new("TextLabel")
titlesEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
titlesEmptyLabel.BackgroundTransparency = 1
titlesEmptyLabel.Font = Enum.Font.Gotham
titlesEmptyLabel.Text = "No titles unlocked yet"
titlesEmptyLabel.TextColor3 = COLORS.TextSecondary
titlesEmptyLabel.TextScaled = true
titlesEmptyLabel.Visible = false
titlesEmptyLabel.Parent = titlesScroll

createTextSizeConstraint(12, 18).Parent = titlesEmptyLabel

-- ==================== ITEM CREATION ====================

local function createAuraItem(auraId, parentFrame)
	if not equipAuraEvent or not unequipAuraEvent then
		return nil -- Skip if remotes don't exist
	end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createScaledCorner(0.08).Parent = frame

	local isEquipped = inventoryData.EquippedAura == auraId

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0.7, 0, 0.15, 0)
		equippedBadge.Position = UDim2.new(0.5, 0, 0.03, 0)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createScaledCorner(0.3).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.TextScaled = true
		badgeLabel.Parent = equippedBadge
		
		createTextSizeConstraint(8, 12).Parent = badgeLabel
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.35, 0)
	icon.Position = UDim2.new(0, 0, 0.2, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "✨"
	icon.TextColor3 = COLORS.Accent
	icon.TextScaled = true
	icon.Parent = frame
	
	createTextSizeConstraint(20, 36).Parent = icon

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.58, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = auraId
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	
	createTextSizeConstraint(9, 14).Parent = nameLabel

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.85, 0, 0.18, 0)
	btn.Position = UDim2.new(0.5, 0, 0.78, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = frame

	createScaledCorner(0.25).Parent = btn
	createTextSizeConstraint(9, 14).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipAuraEvent:FireServer()
			-- Update local state immediately for responsive UI
			inventoryData.EquippedAura = nil
		else
			equipAuraEvent:FireServer(auraId)
			-- Update local state immediately for responsive UI
			inventoryData.EquippedAura = auraId
		end
		-- Refresh UI after short delay to let server process
		task.delay(0.1, function()
			updateInventory()
		end)
	end)

	return frame
end

local function createToolItem(toolId, parentFrame)
	if not equipToolEvent or not unequipToolEvent then
		return nil
	end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createScaledCorner(0.08).Parent = frame

	local isEquipped = inventoryData.EquippedTool == toolId

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0.7, 0, 0.15, 0)
		equippedBadge.Position = UDim2.new(0.5, 0, 0.03, 0)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createScaledCorner(0.3).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.TextScaled = true
		badgeLabel.Parent = equippedBadge
		
		createTextSizeConstraint(8, 12).Parent = badgeLabel
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.35, 0)
	icon.Position = UDim2.new(0, 0, 0.2, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "🔧"
	icon.TextColor3 = COLORS.Success
	icon.TextScaled = true
	icon.Parent = frame
	
	createTextSizeConstraint(20, 36).Parent = icon

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.58, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = toolId
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	
	createTextSizeConstraint(9, 14).Parent = nameLabel

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.85, 0, 0.18, 0)
	btn.Position = UDim2.new(0.5, 0, 0.78, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = frame

	createScaledCorner(0.25).Parent = btn
	createTextSizeConstraint(9, 14).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipToolEvent:FireServer()
			-- Update local state immediately for responsive UI
			inventoryData.EquippedTool = nil
		else
			equipToolEvent:FireServer(toolId)
			-- Update local state immediately for responsive UI
			inventoryData.EquippedTool = toolId
		end
		-- Refresh UI after short delay to let server process
		task.delay(0.1, function()
			updateInventory()
		end)
	end)

	return frame
end

local function createTitleItem(titleName)
	local titleInfo = nil

	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if titleData.Name == titleName then
			titleInfo = titleData
			break
		end
	end

	if not titleInfo and TitleConfig.SpecialTitles[titleName] then
		local data = TitleConfig.SpecialTitles[titleName]
		titleInfo = {
			Name = titleName,
			DisplayName = data.DisplayName,
			Color = data.Color,
			Icon = data.Icon
		}
	end

	if not titleInfo then return nil end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = titlesScroll

	createScaledCorner(0.1).Parent = frame
	createStroke(titleInfo.Color, 2).Parent = frame

	local isEquipped = titleData.EquippedTitle == titleName

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0.35, 0, 0.25, 0)
		equippedBadge.Position = UDim2.new(0.5, 0, 0.05, 0)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createScaledCorner(0.3).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.TextScaled = true
		badgeLabel.Parent = equippedBadge
		
		createTextSizeConstraint(8, 12).Parent = badgeLabel
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0.12, 0, 0.5, 0)
	icon.Position = UDim2.new(0.03, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = titleInfo.Icon
	icon.TextColor3 = titleInfo.Color
	icon.TextScaled = true
	icon.Parent = frame
	
	createTextSizeConstraint(16, 28).Parent = icon

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.16, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = titleInfo.DisplayName
	nameLabel.TextColor3 = titleInfo.Color
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	
	createTextSizeConstraint(10, 16).Parent = nameLabel

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.25, 0, 0.5, 0)
	btn.Position = UDim2.new(0.95, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = frame

	createScaledCorner(0.2).Parent = btn
	createTextSizeConstraint(9, 14).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipTitleEvent:FireServer()
			-- Update local state immediately for responsive UI
			titleData.EquippedTitle = nil
		else
			equipTitleEvent:FireServer(titleName)
			-- Update local state immediately for responsive UI
			titleData.EquippedTitle = titleName
		end
		-- Refresh UI after short delay to let server process
		task.delay(0.1, function()
			updateTitlesTab()
		end)
	end)

	return frame
end

-- ==================== UPDATE FUNCTIONS ====================

function updateInventory()
	for _, child in ipairs(allScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, child in ipairs(aurasScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, child in ipairs(toolsScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if inventoryData.OwnedAuras then
		for _, auraId in ipairs(inventoryData.OwnedAuras) do
			if currentCategory == "All" or currentCategory == "Auras" then
				local targetParent = currentCategory == "All" and allScroll or aurasScroll
				createAuraItem(auraId, targetParent)
			end
		end
	end

	if inventoryData.OwnedTools then
		for _, toolId in ipairs(inventoryData.OwnedTools) do
			if currentCategory == "All" or currentCategory == "Tools" then
				local targetParent = currentCategory == "All" and allScroll or toolsScroll
				createToolItem(toolId, targetParent)
			end
		end
	end
	
	-- ✅ AdminWing is now part of OwnedTools for admins, handled by the loop above
end

function updateTitlesTab()
	for _, child in ipairs(titlesScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local itemsToShow = {}

	if not titleData.UnlockedTitles then
		titleData.UnlockedTitles = {}
	end

	for _, titleName in ipairs(titleData.UnlockedTitles) do
		local isSpecial = TitleConfig.SpecialTitles[titleName] ~= nil
		local isSummit = false

		for _, summitTitle in ipairs(TitleConfig.SummitTitles) do
			if summitTitle.Name == titleName then
				isSummit = true
				break
			end
		end

		if currentTitleFilter == "All" then
			table.insert(itemsToShow, titleName)
		elseif currentTitleFilter == "Special" and isSpecial then
			table.insert(itemsToShow, titleName)
		elseif currentTitleFilter == "Summit" and isSummit then
			table.insert(itemsToShow, titleName)
		end
	end

	if #itemsToShow == 0 then
		titlesEmptyLabel.Visible = true
		titlesEmptyLabel.Text = currentTitleFilter == "All" 
			and "No titles unlocked yet" 
			or ("No " .. currentTitleFilter .. " titles unlocked")
	else
		titlesEmptyLabel.Visible = false
		for _, titleName in ipairs(itemsToShow) do
			createTitleItem(titleName)
		end
	end
end

-- ==================== FETCH DATA ====================

local function fetchInventory()
	if not getInventoryFunc then return end

	local success, data = pcall(function()
		return getInventoryFunc:InvokeServer()
	end)

	if success and data then
		inventoryData = data
		-- ✅ DEBUG: Log inventory data for troubleshooting
		print(string.format("📦 [INVENTORY CLIENT] Fetched data - Auras: %d, Tools: %d, EquippedAura: %s, EquippedTool: %s", 
			#(data.OwnedAuras or {}), #(data.OwnedTools or {}), 
			tostring(data.EquippedAura), tostring(data.EquippedTool)))
		updateInventory()
	else
		warn("[INVENTORY CLIENT] Failed to fetch inventory data:", tostring(data))
	end
end

local function fetchTitles()
	if not getUnlockedTitlesFunc then return end

	local success, data = pcall(function()
		return getUnlockedTitlesFunc:InvokeServer()
	end)

	if success and data then
		titleData = data
		if currentCategory == "Titles" then
			updateTitlesTab()
		end
	end
end

-- ==================== HUD BUTTON ====================

local function closeInventory()
	isInventoryOpen = false
	mainPanel.Visible = false
	PanelManager:Close("InventoryPanel")
end

local function openInventory()
	PanelManager:Open("InventoryPanel") -- This closes other panels first
	isInventoryOpen = true
	mainPanel.Visible = true
	fetchInventory()
	fetchTitles()
end

toggleInventory = function()
	if isInventoryOpen then
		closeInventory()
	else
		openInventory()
	end
end

-- Register with PanelManager
PanelManager:Register("InventoryPanel", closeInventory)

local inventoryButton = HUDButtonHelper.Create({
	Side = "Left",
	Name = "InventoryButton",
	Icon = "rbxassetid://86603627178306",
	Text = "Inventory",
	OnClick = toggleInventory
})

-- ==================== KEYBIND ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		toggleInventory()
	end
end)

-- ✅ LISTEN FOR INVENTORY UPDATE EVENT (admin gave items)
local inventoryUpdatedEvent = inventoryRemotes:FindFirstChild("InventoryUpdated")
if inventoryUpdatedEvent then
	inventoryUpdatedEvent.OnClientEvent:Connect(function(updatedData)
		print("📦 [INVENTORY CLIENT] Received inventory update from server")
		if updatedData then
			inventoryData = updatedData
			-- Refresh UI if inventory is open
			if isInventoryOpen then
				if currentCategory == "Titles" then
					updateTitlesTab()
				else
					updateInventory()
				end
			end
		end
	end)
	print("✅ [INVENTORY CLIENT v3] InventoryUpdated listener connected")
end

print("✅ [INVENTORY CLIENT v3] Loaded with Titles tab")
