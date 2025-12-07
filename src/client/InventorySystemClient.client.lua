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

-- ==================== DISABLE DEFAULT BACKPACK/HOTBAR ====================
-- Karena kita menggunakan sistem inventory custom, nonaktifkan hotbar Roblox default
local function disableDefaultBackpack()
	local success, err = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	
	if not success then
		-- Retry jika gagal (mungkin karena CoreGui belum ready)
		task.delay(1, function()
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
		end)
	else
		print("✅ [INVENTORY] Default backpack/hotbar disabled")
	end
end

disableDefaultBackpack()

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local InventoryConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryConfig"))
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- RemoteEvents
local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 10)
if not inventoryRemotes then
	warn("[INVENTORY CLIENT v3] InventoryRemotes not found!")
	return
end

local getInventoryFunc = inventoryRemotes:WaitForChild("GetInventory", 5)
local equipItemEvent = inventoryRemotes:FindFirstChild("EquipItem") -- ✅ Use FindFirstChild
local unequipItemEvent = inventoryRemotes:FindFirstChild("UnequipItem")

-- Check if inventory remotes exist (optional for backward compatibility)
if not equipItemEvent then
	warn("[INVENTORY CLIENT v3] EquipItem not found - Aura/Tool equip disabled")
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

-- Colors (extend with rarity colors)
local COLORS = InventoryConfig.Colors
COLORS.Common = Color3.fromRGB(200, 200, 200)
COLORS.Uncommon = Color3.fromRGB(100, 255, 100)
COLORS.Rare = Color3.fromRGB(80, 150, 255)
COLORS.Epic = Color3.fromRGB(200, 100, 255)
COLORS.Legendary = Color3.fromRGB(255, 170, 0)

print("✅ [INVENTORY CLIENT v4] Starting initialization...")

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

-- ==================== CREATE GUI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGUI_V3"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true  -- ✅ UBAH JADI TRUE
screenGui.Parent = playerGui


-- Main Panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 700, 0, 500)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

createCorner(15).Parent = mainPanel
createStroke(COLORS.Border, 2).Parent = mainPanel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = mainPanel

createCorner(15).Parent = header

local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0, 15)
headerBottom.Position = UDim2.new(0, 0, 1, -15)
headerBottom.BackgroundColor3 = COLORS.Panel
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0, 200, 1, 0)
headerTitle.Position = UDim2.new(0, 20, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "INVENTORY"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextSize = 20
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = COLORS.Text
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

createCorner(10).Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	closeBtn.BackgroundColor3 = COLORS.Danger
end)

closeBtn.MouseLeave:Connect(function()
	closeBtn.BackgroundColor3 = COLORS.Button
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
end)

-- Category Frame
local categoryFrame = Instance.new("Frame")
categoryFrame.Size = UDim2.new(1, -30, 0, 40)
categoryFrame.Position = UDim2.new(0, 15, 0, 70)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = mainPanel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 8)
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Parent = categoryFrame

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -30, 1, -130)
contentFrame.Position = UDim2.new(0, 15, 0, 120)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainPanel

-- ==================== CATEGORY TABS ====================

local categoryTabs = {}

local function createCategoryTab(categoryName, order)
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0, 0, 1, 0)
	tab.BackgroundColor3 = categoryName == "All" and COLORS.Accent or COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.Text = categoryName
	tab.TextColor3 = COLORS.Text
	tab.TextSize = 14
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = categoryFrame

	createCorner(8).Parent = tab

	local textSize = game:GetService("TextService"):GetTextSize(categoryName, 14, Enum.Font.GothamBold, Vector2.new(1000, 40))
	tab.Size = UDim2.new(0, textSize.X + 30, 1, 0)

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
		elseif categoryName == "Rods" or categoryName == "Floaters" then
			updateFishingTab()
		else
			updateInventory()
		end
	end)

	return content
end

local allContent = createCategoryTab("All", 1)
local aurasContent = createCategoryTab("Auras", 2)
local toolsContent = createCategoryTab("Tools", 3)
-- Rods and Floaters removed - moved to Equipment UI
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

local allGrid = Instance.new("UIGridLayout")
allGrid.CellSize = UDim2.new(0, 100, 0, 120)
allGrid.CellPadding = UDim2.new(0, 10, 0, 10)
allGrid.SortOrder = Enum.SortOrder.LayoutOrder
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

local aurasGrid = Instance.new("UIGridLayout")
aurasGrid.CellSize = UDim2.new(0, 100, 0, 120)
aurasGrid.CellPadding = UDim2.new(0, 10, 0, 10)
aurasGrid.SortOrder = Enum.SortOrder.LayoutOrder
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

local toolsGrid = Instance.new("UIGridLayout")
toolsGrid.CellSize = UDim2.new(0, 100, 0, 120)
toolsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
toolsGrid.SortOrder = Enum.SortOrder.LayoutOrder
toolsGrid.Parent = toolsScroll

-- ==================== RODS TAB ====================

local rodsScroll = Instance.new("ScrollingFrame")
rodsScroll.Size = UDim2.new(1, 0, 1, 0)
rodsScroll.BackgroundTransparency = 1
rodsScroll.BorderSizePixel = 0
rodsScroll.ScrollBarThickness = 6
rodsScroll.ScrollBarImageColor3 = COLORS.Border
rodsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rodsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rodsScroll.Parent = rodsContent

local rodsGrid = Instance.new("UIGridLayout")
rodsGrid.CellSize = UDim2.new(0, 100, 0, 120)
rodsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
rodsGrid.SortOrder = Enum.SortOrder.LayoutOrder
rodsGrid.Parent = rodsScroll

local rodsEmptyLabel = Instance.new("TextLabel")
rodsEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
rodsEmptyLabel.BackgroundTransparency = 1
rodsEmptyLabel.Font = Enum.Font.Gotham
rodsEmptyLabel.Text = "No rods owned"
rodsEmptyLabel.TextColor3 = COLORS.TextSecondary
rodsEmptyLabel.TextSize = 14
rodsEmptyLabel.Visible = false
rodsEmptyLabel.Parent = rodsScroll

-- ==================== FLOATERS TAB ====================

local floatersScroll = Instance.new("ScrollingFrame")
floatersScroll.Size = UDim2.new(1, 0, 1, 0)
floatersScroll.BackgroundTransparency = 1
floatersScroll.BorderSizePixel = 0
floatersScroll.ScrollBarThickness = 6
floatersScroll.ScrollBarImageColor3 = COLORS.Border
floatersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
floatersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
floatersScroll.Parent = floatersContent

local floatersGrid = Instance.new("UIGridLayout")
floatersGrid.CellSize = UDim2.new(0, 100, 0, 120)
floatersGrid.CellPadding = UDim2.new(0, 10, 0, 10)
floatersGrid.SortOrder = Enum.SortOrder.LayoutOrder
floatersGrid.Parent = floatersScroll

local floatersEmptyLabel = Instance.new("TextLabel")
floatersEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
floatersEmptyLabel.BackgroundTransparency = 1
floatersEmptyLabel.Font = Enum.Font.Gotham
floatersEmptyLabel.Text = "No floaters owned"
floatersEmptyLabel.TextColor3 = COLORS.TextSecondary
floatersEmptyLabel.TextSize = 14
floatersEmptyLabel.Visible = false
floatersEmptyLabel.Parent = floatersScroll

-- ==================== TITLES TAB ====================

-- Filter Frame
local titleFilterFrame = Instance.new("Frame")
titleFilterFrame.Size = UDim2.new(1, 0, 0, 35)
titleFilterFrame.BackgroundTransparency = 1
titleFilterFrame.Parent = titlesContent

local titleFilterLayout = Instance.new("UIListLayout")
titleFilterLayout.FillDirection = Enum.FillDirection.Horizontal
titleFilterLayout.Padding = UDim.new(0, 8)
titleFilterLayout.Parent = titleFilterFrame

local function createTitleFilterBtn(text, filter)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 1, 0)
	btn.BackgroundColor3 = filter == "All" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = titleFilterFrame

	createCorner(6).Parent = btn

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
titlesScroll.Size = UDim2.new(1, 0, 1, -45)
titlesScroll.Position = UDim2.new(0, 0, 0, 45)
titlesScroll.BackgroundTransparency = 1
titlesScroll.BorderSizePixel = 0
titlesScroll.ScrollBarThickness = 6
titlesScroll.ScrollBarImageColor3 = COLORS.Border
titlesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
titlesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
titlesScroll.Parent = titlesContent

local titlesGrid = Instance.new("UIGridLayout")
titlesGrid.CellSize = UDim2.new(0, 200, 0, 80)
titlesGrid.CellPadding = UDim2.new(0, 10, 0, 10)
titlesGrid.SortOrder = Enum.SortOrder.LayoutOrder
titlesGrid.Parent = titlesScroll

local titlesEmptyLabel = Instance.new("TextLabel")
titlesEmptyLabel.Size = UDim2.new(1, 0, 0, 100)
titlesEmptyLabel.BackgroundTransparency = 1
titlesEmptyLabel.Font = Enum.Font.Gotham
titlesEmptyLabel.Text = "No titles unlocked yet"
titlesEmptyLabel.TextColor3 = COLORS.TextSecondary
titlesEmptyLabel.TextSize = 14
titlesEmptyLabel.Visible = false
titlesEmptyLabel.Parent = titlesScroll

-- ==================== ITEM CREATION ====================

local function createAuraItem(auraId, parentFrame)
	if not equipItemEvent or not unequipItemEvent then
		return nil -- Skip if remotes don't exist
	end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createCorner(10).Parent = frame

	local isEquipped = inventoryData.EquippedAura == auraId

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0, 70, 0, 20)
		equippedBadge.Position = UDim2.new(0.5, 0, 0, 5)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.TextSize = 10
		badgeLabel.Parent = equippedBadge
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.Position = UDim2.new(0, 0, 0, 25)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "✨"
	icon.TextColor3 = COLORS.Accent
	icon.TextSize = 30
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = auraId
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 12
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 25)
	btn.Position = UDim2.new(0.5, 0, 1, -30)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.Parent = frame

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipItemEvent:FireServer("Aura")
		else
			equipItemEvent:FireServer("Aura", auraId)
		end
	end)

	return frame
end

local function createToolItem(toolId, parentFrame)
	if not equipItemEvent or not unequipItemEvent then
		return nil
	end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createCorner(10).Parent = frame

	local isEquipped = inventoryData.EquippedTool == toolId

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0, 70, 0, 20)
		equippedBadge.Position = UDim2.new(0.5, 0, 0, 5)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.TextSize = 10
		badgeLabel.Parent = equippedBadge
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.Position = UDim2.new(0, 0, 0, 25)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "🔧"
	icon.TextColor3 = COLORS.Success
	icon.TextSize = 30
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = toolId
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 12
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 25)
	btn.Position = UDim2.new(0.5, 0, 1, -30)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.Parent = frame

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipItemEvent:FireServer("Tool")
		else
			equipItemEvent:FireServer("Tool", toolId)
		end
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

	createCorner(10).Parent = frame
	createStroke(titleInfo.Color, 2).Parent = frame

	local isEquipped = titleData.EquippedTitle == titleName

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0, 70, 0, 20)
		equippedBadge.Position = UDim2.new(0.5, 0, 0, 5)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.TextSize = 10
		badgeLabel.Parent = equippedBadge
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0, 10, 0.5, -15)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = titleInfo.Icon
	icon.TextColor3 = titleInfo.Color
	icon.TextSize = 24
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -120, 0, 25)
	nameLabel.Position = UDim2.new(0, 45, 0.5, -12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = titleInfo.DisplayName
	nameLabel.TextColor3 = titleInfo.Color
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 70, 0, 30)
	btn.Position = UDim2.new(1, -80, 0.5, -15)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.Parent = frame

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipTitleEvent:FireServer()
		else
			equipTitleEvent:FireServer(titleName)
		end
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

-- ==================== FISHING TAB (RODS & FLOATERS) ====================

-- Try to get RodShop remotes
local rodShopRemotes = ReplicatedStorage:FindFirstChild("RodShopRemotes")
local getOwnedItemsFunc = rodShopRemotes and rodShopRemotes:FindFirstChild("GetOwnedItems")
local equipRodEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("EquipRod")
local equipFloaterEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("EquipFloater")
local unequipFloaterEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("UnequipFloater")
local shopUpdatedEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("ShopUpdated")
local equipmentChangedEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("EquipmentChanged")

-- Try to get RodShopConfig
local RodShopConfig = nil
pcall(function()
	RodShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RodShopConfig"))
end)

-- Fishing data
local fishingData = {
	OwnedRods = {"FishingRod_Wood1"},
	OwnedFloaters = {},
	EquippedRod = "FishingRod_Wood1",
	EquippedFloater = nil
}

local function createRodItem(rodId, parentFrame)
	if not RodShopConfig then return nil end
	
	local rodData = RodShopConfig.GetRodById(rodId)
	if not rodData then return nil end
	
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createCorner(10).Parent = frame
	
	local isEquipped = fishingData.EquippedRod == rodId
	
	-- Rarity stroke
	local rarityColor = COLORS[rodData.Rarity] or COLORS.Text
	createStroke(rarityColor, 2).Parent = frame

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0, 70, 0, 20)
		equippedBadge.Position = UDim2.new(0.5, 0, 0, 5)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Success
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		badgeLabel.TextSize = 10
		badgeLabel.Parent = equippedBadge
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.Position = UDim2.new(0, 0, 0, 25)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "🎣"
	icon.TextColor3 = rarityColor
	icon.TextSize = 30
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = rodData.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 11
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 25)
	btn.Position = UDim2.new(0.5, 0, 1, -30)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = isEquipped and COLORS.Success or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Equipped" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.Parent = frame

	createCorner(6).Parent = btn

	if not isEquipped and equipRodEvent then
		btn.MouseButton1Click:Connect(function()
			equipRodEvent:FireServer(rodId)
			task.wait(0.3)
			fetchFishingData()
			updateFishingTab()
		end)
	end

	return frame
end

local function createFloaterItem(floaterId, parentFrame)
	if not RodShopConfig then return nil end
	
	local floaterData = RodShopConfig.GetFloaterById(floaterId)
	if not floaterData then return nil end
	
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createCorner(10).Parent = frame
	
	local isEquipped = fishingData.EquippedFloater == floaterId
	
	-- Rarity stroke
	local rarityColor = COLORS[floaterData.Rarity] or COLORS.Text
	createStroke(rarityColor, 2).Parent = frame

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0, 70, 0, 20)
		equippedBadge.Position = UDim2.new(0.5, 0, 0, 5)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Success
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		badgeLabel.TextSize = 10
		badgeLabel.Parent = equippedBadge
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.Position = UDim2.new(0, 0, 0, 25)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "🎈"
	icon.TextColor3 = rarityColor
	icon.TextSize = 30
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = floaterData.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 11
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 25)
	btn.Position = UDim2.new(0.5, 0, 1, -30)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.Parent = frame

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped and unequipFloaterEvent then
			unequipFloaterEvent:FireServer()
		elseif equipFloaterEvent then
			equipFloaterEvent:FireServer(floaterId)
		end
		task.wait(0.3)
		fetchFishingData()
		updateFishingTab()
	end)

	return frame
end

function fetchFishingData()
	if not getOwnedItemsFunc then return end
	
	local success, data = pcall(function()
		return getOwnedItemsFunc:InvokeServer()
	end)
	
	if success and data then
		fishingData = data
	end
end

function updateFishingTab()
	-- Clear rods scroll
	for _, child in ipairs(rodsScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Clear floaters scroll
	for _, child in ipairs(floatersScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if currentCategory == "Rods" then
		if not fishingData.OwnedRods or #fishingData.OwnedRods == 0 then
			rodsEmptyLabel.Visible = true
		else
			rodsEmptyLabel.Visible = false
			for _, rodId in ipairs(fishingData.OwnedRods) do
				createRodItem(rodId, rodsScroll)
			end
		end
	elseif currentCategory == "Floaters" then
		if not fishingData.OwnedFloaters or #fishingData.OwnedFloaters == 0 then
			floatersEmptyLabel.Visible = true
		else
			floatersEmptyLabel.Visible = false
			for _, floaterId in ipairs(fishingData.OwnedFloaters) do
				createFloaterItem(floaterId, floatersScroll)
			end
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
		updateInventory()
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

local inventoryIcon = Icon.new()
	:setLabel("Inventory")
	:setImage(18929686504)
	:setOrder(2)
	:bindEvent("selected", function()
		mainPanel.Visible = true
		fetchInventory()
		fetchTitles()
		fetchFishingData()
	end)
	:bindEvent("deselected", function()
		mainPanel.Visible = false
	end)

-- ==================== KEYBIND ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if mainPanel.Visible then
			mainPanel.Visible = false
			inventoryIcon:deselect()
		else
			mainPanel.Visible = true
			inventoryIcon:select()
			fetchInventory()
			fetchTitles()
			fetchFishingData()
		end
	end
end)

-- ==================== AUTO-REFRESH ON SERVER EVENTS ====================

-- When player buys/equips something, auto-refresh fishing data
if shopUpdatedEvent then
	shopUpdatedEvent.OnClientEvent:Connect(function(itemType, itemId)
		print("🔄 [INVENTORY CLIENT] Shop updated, refreshing fishing data...")
		fetchFishingData()
		if currentCategory == "Rods" or currentCategory == "Floaters" then
			updateFishingTab()
		end
	end)
end

if equipmentChangedEvent then
	equipmentChangedEvent.OnClientEvent:Connect(function(data)
		print("🔄 [INVENTORY CLIENT] Equipment changed, refreshing fishing data...")
		fetchFishingData()
		if currentCategory == "Rods" or currentCategory == "Floaters" then
			updateFishingTab()
		end
	end)
end

print("✅ [INVENTORY CLIENT v5] Loaded with Titles, Rods & Floaters tabs + Auto-refresh")
