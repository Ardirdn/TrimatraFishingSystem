--[[
    ADMIN LOG CLIENT
    UI terpisah untuk melihat log aktivitas admin
    Hanya dapat diakses oleh Primary Admin
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- TitleConfig untuk cek admin
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Only allow primary admin
if not TitleConfig.IsPrimaryAdmin(player.UserId) then
	return
end

-- Wait for RemoteEvents
local remoteFolder = ReplicatedStorage:WaitForChild("AdminRemotes", 10)
if not remoteFolder then
	warn("[ADMIN LOG CLIENT] AdminRemotes not found!")
	return
end

local getLogsFunc = remoteFolder:WaitForChild("GetAdminLogs", 10)
local getAdminListFunc = remoteFolder:WaitForChild("GetAdminList", 10)

if not getLogsFunc or not getAdminListFunc then
	warn("[ADMIN LOG CLIENT] Log remote functions not found!")
	return
end

-- Color Scheme (matching AdminClient)
local COLORS = {
	Background = Color3.fromRGB(25, 25, 30),
	Panel = Color3.fromRGB(30, 30, 35),
	Header = Color3.fromRGB(35, 35, 40),
	Button = Color3.fromRGB(45, 45, 50),
	ButtonHover = Color3.fromRGB(55, 55, 60),
	Accent = Color3.fromRGB(88, 101, 242),
	AccentHover = Color3.fromRGB(108, 121, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Danger = Color3.fromRGB(237, 66, 69),
	DangerHover = Color3.fromRGB(255, 86, 89),
	Success = Color3.fromRGB(67, 181, 129),
	Warning = Color3.fromRGB(255, 193, 7),
	Border = Color3.fromRGB(50, 50, 55)
}

-- Action type colors
local ACTION_COLORS = {
	kick = Color3.fromRGB(255, 152, 0),      -- Orange
	ban = Color3.fromRGB(237, 66, 69),       -- Red
	freeze = Color3.fromRGB(0, 188, 212),    -- Cyan
	set_title = Color3.fromRGB(156, 39, 176), -- Purple
	give_title = Color3.fromRGB(233, 30, 99), -- Pink
	set_summit = Color3.fromRGB(139, 195, 74), -- Green
	notification = Color3.fromRGB(33, 150, 243), -- Blue
	teleport = Color3.fromRGB(255, 193, 7),   -- Yellow
	kill = Color3.fromRGB(183, 28, 28),       -- Dark Red
	give_items = Color3.fromRGB(76, 175, 80), -- Green
	set_speed = Color3.fromRGB(255, 87, 34),  -- Deep Orange
	set_gravity = Color3.fromRGB(103, 58, 183), -- Deep Purple
	delete_data = Color3.fromRGB(244, 67, 54) -- Red
}

-- Action type icons
local ACTION_ICONS = {
	kick = "👢",
	ban = "🚫",
	freeze = "❄️",
	set_title = "👑",
	give_title = "🎁",
	set_summit = "⛰️",
	notification = "📢",
	teleport = "📍",
	kill = "💀",
	give_items = "🎁",
	set_speed = "⚡",
	set_gravity = "🌍",
	delete_data = "🗑️"
}

-- Utility functions
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createPadding(padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, padding)
	pad.PaddingBottom = UDim.new(0, padding)
	pad.PaddingLeft = UDim.new(0, padding)
	pad.PaddingRight = UDim.new(0, padding)
	return pad
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

-- ==================== MAIN UI ====================

local isOpen = false
local currentCategory = "all" -- all, admin_list, or specific admin ID
local currentFilter = "all" -- action type filter
local selectedAdminId = nil

-- Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminLogGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "AdminLogContainer"
mainContainer.Size = UDim2.new(0.6, 0, 0.8, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundColor3 = COLORS.Background
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false
mainContainer.ClipsDescendants = true
mainContainer.Parent = screenGui

createCorner(12).Parent = mainContainer
createStroke(COLORS.Border, 2).Parent = mainContainer

-- Aspect Ratio
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1.4
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = mainContainer

-- Main Padding
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingLeft = UDim.new(0.02, 0)
mainPadding.PaddingRight = UDim.new(0.02, 0)
mainPadding.PaddingTop = UDim.new(0.015, 0)
mainPadding.PaddingBottom = UDim.new(0.02, 0)
mainPadding.Parent = mainContainer

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.08, 0)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = mainContainer

createCorner(8).Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.85, 0, 1, 0)
headerTitle.Position = UDim2.new(0.02, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "📋 Admin Activity Log"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local headerTextConstraint = Instance.new("UITextSizeConstraint")
headerTextConstraint.MinTextSize = 12
headerTextConstraint.MaxTextSize = 20
headerTextConstraint.Parent = headerTitle

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.06, 0, 0.7, 0)
closeButton.Position = UDim2.new(0.97, 0, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "×"
closeButton.TextColor3 = COLORS.Text
closeButton.TextScaled = true
closeButton.Parent = header

createCorner(6).Parent = closeButton

-- Left Panel (Category Selection)
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.25, 0, 0.88, 0)
leftPanel.Position = UDim2.new(0, 0, 0.1, 0)
leftPanel.BackgroundColor3 = COLORS.Panel
leftPanel.BorderSizePixel = 0
leftPanel.Parent = mainContainer

createCorner(8).Parent = leftPanel

local leftPadding = createPadding(10)
leftPadding.Parent = leftPanel

local leftScroll = Instance.new("ScrollingFrame")
leftScroll.Size = UDim2.new(1, 0, 1, 0)
leftScroll.BackgroundTransparency = 1
leftScroll.BorderSizePixel = 0
leftScroll.ScrollBarThickness = 4
leftScroll.ScrollBarImageColor3 = COLORS.Border
leftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
leftScroll.Parent = leftPanel

local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 6)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Parent = leftScroll

-- Right Panel (Log Display)
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.72, 0, 0.88, 0)
rightPanel.Position = UDim2.new(0.27, 0, 0.1, 0)
rightPanel.BackgroundColor3 = COLORS.Panel
rightPanel.BorderSizePixel = 0
rightPanel.Parent = mainContainer

createCorner(8).Parent = rightPanel

local rightPadding = createPadding(10)
rightPadding.Parent = rightPanel

-- Filter Bar
local filterBar = Instance.new("Frame")
filterBar.Name = "FilterBar"
filterBar.Size = UDim2.new(1, 0, 0, 35)
filterBar.BackgroundTransparency = 1
filterBar.Parent = rightPanel

local filterLabel = Instance.new("TextLabel")
filterLabel.Size = UDim2.new(0, 60, 1, 0)
filterLabel.BackgroundTransparency = 1
filterLabel.Font = Enum.Font.GothamBold
filterLabel.Text = "Filter:"
filterLabel.TextColor3 = COLORS.Text
filterLabel.TextSize = 12
filterLabel.TextXAlignment = Enum.TextXAlignment.Left
filterLabel.Parent = filterBar

local filterScroll = Instance.new("ScrollingFrame")
filterScroll.Size = UDim2.new(1, -65, 1, 0)
filterScroll.Position = UDim2.new(0, 65, 0, 0)
filterScroll.BackgroundTransparency = 1
filterScroll.BorderSizePixel = 0
filterScroll.ScrollBarThickness = 0
filterScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
filterScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
filterScroll.ScrollingDirection = Enum.ScrollingDirection.X
filterScroll.Parent = filterBar

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0, 5)
filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
filterLayout.Parent = filterScroll

-- Log Display
local logScroll = Instance.new("ScrollingFrame")
logScroll.Name = "LogScroll"
logScroll.Size = UDim2.new(1, 0, 1, -45)
logScroll.Position = UDim2.new(0, 0, 0, 40)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 4
logScroll.ScrollBarImageColor3 = COLORS.Border
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = rightPanel

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 4)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logScroll

-- ==================== UI FUNCTIONS ====================

local categoryButtons = {}
local filterButtons = {}

local function clearChildren(parent, keepLayout)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function createCategoryButton(text, icon, layoutOrder, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.BackgroundColor3 = COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = icon .. " " .. text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.LayoutOrder = layoutOrder
	btn.Parent = leftScroll
	
	createCorner(6).Parent = btn
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = btn
	
	btn.MouseEnter:Connect(function()
		if btn.BackgroundColor3 ~= COLORS.Accent then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.ButtonHover}):Play()
		end
	end)
	
	btn.MouseLeave:Connect(function()
		if btn.BackgroundColor3 ~= COLORS.Accent then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
		end
	end)
	
	btn.MouseButton1Click:Connect(onClick)
	
	return btn
end

local function createFilterButton(text, actionType, layoutOrder)
	local color = ACTION_COLORS[actionType] or COLORS.Accent
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 75, 0, 26)
	btn.BackgroundColor3 = COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = COLORS.TextSecondary
	btn.TextSize = 10
	btn.AutoButtonColor = false
	btn.LayoutOrder = layoutOrder
	btn.Parent = filterScroll
	
	btn.MouseEnter:Connect(function()
		if currentFilter ~= actionType then
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.ButtonHover}):Play()
		end
	end)
	
	btn.MouseLeave:Connect(function()
		if currentFilter ~= actionType then
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Button}):Play()
		end
	end)
	
	btn.MouseButton1Click:Connect(function()
		-- Reset all filter buttons
		for filterType, filterBtn in pairs(filterButtons) do
			filterBtn.BackgroundColor3 = COLORS.Button
			filterBtn.TextColor3 = COLORS.TextSecondary
		end
		
		-- Highlight selected
		btn.BackgroundColor3 = color
		btn.TextColor3 = COLORS.Text
		
		currentFilter = actionType
		loadLogs()
	end)
	
	filterButtons[actionType] = btn
	return btn
end

local function createLogEntry(logData, layoutOrder)
	local actionColor = ACTION_COLORS[logData.ActionType] or COLORS.Accent
	local actionIcon = ACTION_ICONS[logData.ActionType] or "📋"
	
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 60)
	card.BackgroundColor3 = COLORS.Background
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = logScroll
	
	createCorner(6).Parent = card
	
	-- Accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = actionColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 6)
	accentCorner.Parent = accentBar
	
	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 30, 0, 30)
	iconLabel.Position = UDim2.new(0, 12, 0.5, 0)
	iconLabel.AnchorPoint = Vector2.new(0, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = actionIcon
	iconLabel.TextSize = 20
	iconLabel.Parent = card
	
	-- Admin info
	local adminLabel = Instance.new("TextLabel")
	adminLabel.Size = UDim2.new(0.3, 0, 0, 18)
	adminLabel.Position = UDim2.new(0, 48, 0, 8)
	adminLabel.BackgroundTransparency = 1
	adminLabel.Font = Enum.Font.GothamBold
	adminLabel.Text = logData.AdminName or "Unknown"
	adminLabel.TextColor3 = COLORS.Text
	adminLabel.TextSize = 12
	adminLabel.TextXAlignment = Enum.TextXAlignment.Left
	adminLabel.TextTruncate = Enum.TextTruncate.AtEnd
	adminLabel.Parent = card
	
	-- Action type badge
	local actionBadge = Instance.new("TextLabel")
	actionBadge.Size = UDim2.new(0, 0, 0, 16)
	actionBadge.AutomaticSize = Enum.AutomaticSize.X
	actionBadge.Position = UDim2.new(0, 48, 0, 28)
	actionBadge.BackgroundColor3 = actionColor
	actionBadge.Font = Enum.Font.GothamMedium
	actionBadge.Text = "  " .. string.upper(string.gsub(logData.ActionType or "unknown", "_", " ")) .. "  "
	actionBadge.TextColor3 = COLORS.Text
	actionBadge.TextSize = 9
	actionBadge.Parent = card
	
	createCorner(4).Parent = actionBadge
	
	-- Target info
	local targetLabel = Instance.new("TextLabel")
	targetLabel.Size = UDim2.new(0.35, 0, 0, 16)
	targetLabel.Position = UDim2.new(0.35, 0, 0.5, -8)
	targetLabel.BackgroundTransparency = 1
	targetLabel.Font = Enum.Font.Gotham
	targetLabel.Text = "→ " .. (logData.TargetName or "N/A")
	targetLabel.TextColor3 = COLORS.TextSecondary
	targetLabel.TextSize = 11
	targetLabel.TextXAlignment = Enum.TextXAlignment.Left
	targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
	targetLabel.Parent = card
	
	-- Details
	if logData.Details and logData.Details ~= "" then
		local detailsLabel = Instance.new("TextLabel")
		detailsLabel.Size = UDim2.new(0.35, 0, 0, 14)
		detailsLabel.Position = UDim2.new(0.35, 0, 0.5, 8)
		detailsLabel.BackgroundTransparency = 1
		detailsLabel.Font = Enum.Font.Gotham
		detailsLabel.Text = logData.Details
		detailsLabel.TextColor3 = COLORS.TextSecondary
		detailsLabel.TextSize = 9
		detailsLabel.TextXAlignment = Enum.TextXAlignment.Left
		detailsLabel.TextTruncate = Enum.TextTruncate.AtEnd
		detailsLabel.Parent = card
	end
	
	-- Timestamp
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0.25, 0, 0, 14)
	timeLabel.Position = UDim2.new(0.73, 0, 0.5, -7)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.Text = logData.Date or "Unknown"
	timeLabel.TextColor3 = COLORS.TextSecondary
	timeLabel.TextSize = 10
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Parent = card
	
	-- Server ID (truncated)
	local serverLabel = Instance.new("TextLabel")
	serverLabel.Size = UDim2.new(0.25, 0, 0, 12)
	serverLabel.Position = UDim2.new(0.73, 0, 0.5, 8)
	serverLabel.BackgroundTransparency = 1
	serverLabel.Font = Enum.Font.Gotham
	serverLabel.Text = "Server: " .. string.sub(logData.ServerId or "?", 1, 8) .. "..."
	serverLabel.TextColor3 = Color3.fromRGB(100, 100, 105)
	serverLabel.TextSize = 8
	serverLabel.TextXAlignment = Enum.TextXAlignment.Right
	serverLabel.Parent = card
	
	return card
end

local function createAdminCard(adminData, layoutOrder)
	local isPrimary = adminData.IsPrimary
	local accentColor = isPrimary and COLORS.Warning or COLORS.Accent
	
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0, 70)
	card.BackgroundColor3 = COLORS.Background
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = false
	card.LayoutOrder = layoutOrder
	card.Parent = logScroll
	
	createCorner(6).Parent = card
	
	-- Accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 6)
	accentCorner.Parent = accentBar
	
	-- Avatar
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 45, 0, 45)
	avatar.Position = UDim2.new(0, 15, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Parent = card
	
	createCorner(6).Parent = avatar
	
	-- Load avatar
	pcall(function()
		avatar.Image = Players:GetUserThumbnailAsync(adminData.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	
	-- Admin name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0, 18)
	nameLabel.Position = UDim2.new(0, 70, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = adminData.Name or "Unknown"
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card
	
	-- Role badge
	local roleBadge = Instance.new("TextLabel")
	roleBadge.Size = UDim2.new(0, 0, 0, 16)
	roleBadge.AutomaticSize = Enum.AutomaticSize.X
	roleBadge.Position = UDim2.new(0, 70, 0, 32)
	roleBadge.BackgroundColor3 = accentColor
	roleBadge.Font = Enum.Font.GothamMedium
	roleBadge.Text = isPrimary and "  MAIN ADMIN  " or "  SIDE ADMIN  "
	roleBadge.TextColor3 = COLORS.Text
	roleBadge.TextSize = 9
	roleBadge.Parent = card
	
	createCorner(4).Parent = roleBadge
	
	-- Stats
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(0.3, 0, 0, 14)
	statsLabel.Position = UDim2.new(0, 70, 0, 52)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.Text = string.format("Actions: %d", adminData.TotalActions or 0)
	statsLabel.TextColor3 = COLORS.TextSecondary
	statsLabel.TextSize = 10
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = card
	
	-- Last active
	local lastActiveLabel = Instance.new("TextLabel")
	lastActiveLabel.Size = UDim2.new(0.35, 0, 0, 14)
	lastActiveLabel.Position = UDim2.new(0.63, 0, 0.5, -7)
	lastActiveLabel.BackgroundTransparency = 1
	lastActiveLabel.Font = Enum.Font.Gotham
	lastActiveLabel.Text = "Last: " .. (adminData.LastAction or "Never")
	lastActiveLabel.TextColor3 = COLORS.TextSecondary
	lastActiveLabel.TextSize = 10
	lastActiveLabel.TextXAlignment = Enum.TextXAlignment.Right
	lastActiveLabel.Parent = card
	
	-- Click to view logs
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
	end)
	
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Background}):Play()
	end)
	
	card.MouseButton1Click:Connect(function()
		selectedAdminId = adminData.UserId
		currentCategory = "admin_" .. tostring(adminData.UserId)
		headerTitle.Text = "📋 Logs: " .. adminData.Name
		
		-- Update category buttons
		for cat, btn in pairs(categoryButtons) do
			btn.BackgroundColor3 = COLORS.Button
		end
		
		loadLogs()
	end)
	
	return card
end

-- ==================== DATA LOADING ====================

function loadLogs()
	clearChildren(logScroll, true)
	
	-- Loading indicator
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Size = UDim2.new(1, 0, 0, 40)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Font = Enum.Font.GothamMedium
	loadingLabel.Text = "Loading logs..."
	loadingLabel.TextColor3 = COLORS.TextSecondary
	loadingLabel.TextSize = 14
	loadingLabel.LayoutOrder = 1
	loadingLabel.Parent = logScroll
	
	task.spawn(function()
		local adminFilter = nil
		if selectedAdminId then
			adminFilter = selectedAdminId
		end
		
		local success, result = pcall(function()
			return getLogsFunc:InvokeServer(currentFilter, adminFilter)
		end)
		
		if loadingLabel then
			loadingLabel:Destroy()
		end
		
		if not success or not result or not result.success then
			local errorLabel = Instance.new("TextLabel")
			errorLabel.Size = UDim2.new(1, 0, 0, 40)
			errorLabel.BackgroundTransparency = 1
			errorLabel.Font = Enum.Font.GothamMedium
			errorLabel.Text = "Failed to load logs: " .. (result and result.message or "Unknown error")
			errorLabel.TextColor3 = COLORS.Danger
			errorLabel.TextSize = 12
			errorLabel.LayoutOrder = 1
			errorLabel.Parent = logScroll
			return
		end
		
		local logs = result.logs or {}
		
		if #logs == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 40)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Font = Enum.Font.GothamMedium
			emptyLabel.Text = "No logs found"
			emptyLabel.TextColor3 = COLORS.TextSecondary
			emptyLabel.TextSize = 12
			emptyLabel.LayoutOrder = 1
			emptyLabel.Parent = logScroll
			return
		end
		
		for i, logData in ipairs(logs) do
			createLogEntry(logData, i)
		end
	end)
end

local function loadAdminList()
	clearChildren(logScroll, true)
	selectedAdminId = nil
	headerTitle.Text = "📋 Admin List"
	
	-- Loading indicator
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Size = UDim2.new(1, 0, 0, 40)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Font = Enum.Font.GothamMedium
	loadingLabel.Text = "Loading admin list..."
	loadingLabel.TextColor3 = COLORS.TextSecondary
	loadingLabel.TextSize = 14
	loadingLabel.LayoutOrder = 1
	loadingLabel.Parent = logScroll
	
	task.spawn(function()
		local success, result = pcall(function()
			return getAdminListFunc:InvokeServer()
		end)
		
		if loadingLabel then
			loadingLabel:Destroy()
		end
		
		if not success or not result or not result.success then
			local errorLabel = Instance.new("TextLabel")
			errorLabel.Size = UDim2.new(1, 0, 0, 40)
			errorLabel.BackgroundTransparency = 1
			errorLabel.Font = Enum.Font.GothamMedium
			errorLabel.Text = "Failed to load admin list"
			errorLabel.TextColor3 = COLORS.Danger
			errorLabel.TextSize = 12
			errorLabel.LayoutOrder = 1
			errorLabel.Parent = logScroll
			return
		end
		
		local admins = result.admins or {}
		
		-- Sort: Primary first, then by TotalActions
		table.sort(admins, function(a, b)
			if a.IsPrimary ~= b.IsPrimary then
				return a.IsPrimary
			end
			return (a.TotalActions or 0) > (b.TotalActions or 0)
		end)
		
		for i, adminData in ipairs(admins) do
			createAdminCard(adminData, i)
		end
	end)
end

local function setupCategoryButtons()
	clearChildren(leftScroll, true)
	categoryButtons = {}
	
	-- Header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(1, 0, 0, 25)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.Text = "Categories"
	headerLabel.TextColor3 = COLORS.Text
	headerLabel.TextSize = 12
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.LayoutOrder = 0
	headerLabel.Parent = leftScroll
	
	-- All Logs
	local allLogsBtn = createCategoryButton("All Logs", "📋", 1, function()
		currentCategory = "all"
		currentFilter = "all"
		selectedAdminId = nil
		headerTitle.Text = "📋 Admin Activity Log"
		
		for cat, btn in pairs(categoryButtons) do
			btn.BackgroundColor3 = COLORS.Button
		end
		categoryButtons["all"].BackgroundColor3 = COLORS.Accent
		
		-- Reset filter buttons
		for _, filterBtn in pairs(filterButtons) do
			filterBtn.BackgroundColor3 = COLORS.Button
			filterBtn.TextColor3 = COLORS.TextSecondary
		end
		if filterButtons["all"] then
			filterButtons["all"].BackgroundColor3 = COLORS.Accent
			filterButtons["all"].TextColor3 = COLORS.Text
		end
		
		loadLogs()
	end)
	categoryButtons["all"] = allLogsBtn
	allLogsBtn.BackgroundColor3 = COLORS.Accent
	
	-- Admin List
	local adminListBtn = createCategoryButton("Admin List", "👥", 2, function()
		currentCategory = "admin_list"
		
		for cat, btn in pairs(categoryButtons) do
			btn.BackgroundColor3 = COLORS.Button
		end
		categoryButtons["admin_list"].BackgroundColor3 = COLORS.Accent
		
		loadAdminList()
	end)
	categoryButtons["admin_list"] = adminListBtn
	
	-- Separator
	local separator = Instance.new("Frame")
	separator.Size = UDim2.new(0.9, 0, 0, 1)
	separator.Position = UDim2.new(0.05, 0, 0, 0)
	separator.BackgroundColor3 = COLORS.Border
	separator.BorderSizePixel = 0
	separator.LayoutOrder = 3
	separator.Parent = leftScroll
end

local function setupFilterButtons()
	clearChildren(filterScroll, true)
	filterButtons = {}
	
	-- All filter
	local allBtn = createFilterButton("All", "all", 0)
	allBtn.BackgroundColor3 = COLORS.Accent
	allBtn.TextColor3 = COLORS.Text
	
	-- Action type filters
	local filters = {
		{name = "Kick", type = "kick"},
		{name = "Ban", type = "ban"},
		{name = "Freeze", type = "freeze"},
		{name = "Title", type = "set_title"},
		{name = "Summit", type = "set_summit"},
		{name = "Notif", type = "notification"},
		{name = "Delete", type = "delete_data"},
	}
	
	for i, filter in ipairs(filters) do
		createFilterButton(filter.name, filter.type, i)
	end
end

-- ==================== OPEN/CLOSE ====================

local function openLogPanel()
	if isOpen then return end
	isOpen = true
	
	mainContainer.Visible = true
	mainContainer.Position = UDim2.new(0.5, 0, 1.5, 0)
	
	TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()
	
	-- Initial load
	loadLogs()
end

local function closeLogPanel()
	if not isOpen then return end
	isOpen = false
	
	TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0)
	}):Play()
	
	task.delay(0.3, function()
		if not isOpen then
			mainContainer.Visible = false
		end
	end)
end

-- Close button
closeButton.MouseButton1Click:Connect(closeLogPanel)

-- Setup UI
setupCategoryButtons()
setupFilterButtons()

-- ==================== PUBLIC API ====================
-- This allows AdminClient to open the log panel

local AdminLogUI = {}

function AdminLogUI:Open()
	openLogPanel()
end

function AdminLogUI:Close()
	closeLogPanel()
end

function AdminLogUI:IsOpen()
	return isOpen
end

-- Store in shared for access from AdminClient
_G.AdminLogUI = AdminLogUI

print("✅ [ADMIN LOG CLIENT] Initialized")

return AdminLogUI
