--[[
    ROBLOX ADMIN PANEL SYSTEM - CLIENT
    Modern admin panel with notification system and player management
    
    Installation:
    1. Place this script in StarterPlayerScripts
    2. Place the ServerScript in ServerScriptService
    3. Make sure TopbarPlus module is available in ReplicatedStorage (optional)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ GANTI BAGIAN INI:
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))

-- Check if player is admin
local function isAdmin()
	return TitleConfig.IsAdmin(player.UserId)
end

-- Check if player is PRIMARY admin (full access)
local function isPrimaryAdmin()
	return TitleConfig.IsPrimaryAdmin(player.UserId)
end

if not isAdmin() then
	return -- Exit if not admin
end

-- Store admin access level for later use
local hasPrimaryAccess = isPrimaryAdmin()



-- Wait for RemoteEvents
local remoteFolder = ReplicatedStorage:WaitForChild("AdminRemotes", 10)
if not remoteFolder then
	warn("AdminRemotes folder not found! Server script may not be running.")
	return
end

local kickPlayerEvent = remoteFolder:WaitForChild("KickPlayer")
local banPlayerEvent = remoteFolder:WaitForChild("BanPlayer")
local teleportHereEvent = remoteFolder:WaitForChild("TeleportHere")
local teleportToEvent = remoteFolder:WaitForChild("TeleportTo")
local freezePlayerEvent = remoteFolder:WaitForChild("FreezePlayer")
local setSpeedEvent = remoteFolder:WaitForChild("SetSpeed")
local setGravityEvent = remoteFolder:WaitForChild("SetGravity")
local killPlayerEvent = remoteFolder:WaitForChild("KillPlayer")
local sendNotificationEvent = remoteFolder:WaitForChild("SendGlobalNotification", 5)



-- Try to load TopbarPlus with error handling
local Icon
local topbarPlusLoaded = false

local function loadTopbarPlus()
	local success, result = pcall(function()
		-- Try different possible locations
		local iconModule = ReplicatedStorage:FindFirstChild("Icon") 
			or ReplicatedStorage:FindFirstChild("TopbarPlus")
			or ReplicatedStorage:FindFirstChild("IconModule")

		if iconModule then
			return require(iconModule)
		else
			warn("TopbarPlus module not found in ReplicatedStorage")
			return nil
		end
	end)

	if success and result then
		Icon = result
		topbarPlusLoaded = true
		print("✓ TopbarPlus loaded successfully")
		return true
	else
		warn("Failed to load TopbarPlus: " .. tostring(result))
		return false
	end
end

-- Wait a bit for ReplicatedStorage to load
task.wait(1)
loadTopbarPlus()

-- If TopbarPlus fails, we'll create a fallback button
if not topbarPlusLoaded then
	warn("TopbarPlus not available, using fallback button")
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanelGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Add padding to ScreenGui so panel doesn't touch screen edges
local screenPadding = Instance.new("UIPadding")
screenPadding.PaddingTop = UDim.new(0.05, 0)
screenPadding.PaddingBottom = UDim.new(0.05, 0)
screenPadding.Parent = screenGui

-- Color Scheme
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
	Border = Color3.fromRGB(50, 50, 55)
}

-- Accent Color Variations (for cards - like Donate panel style)
local ACCENT_COLORS = {
	Color3.fromRGB(88, 166, 255),   -- Sky Blue
	Color3.fromRGB(139, 195, 74),   -- Light Green
	Color3.fromRGB(255, 152, 0),    -- Orange
	Color3.fromRGB(156, 39, 176),   -- Purple
	Color3.fromRGB(233, 30, 99),    -- Pink
	Color3.fromRGB(0, 188, 212),    -- Cyan
	Color3.fromRGB(255, 193, 7),    -- Amber
	Color3.fromRGB(76, 175, 80),    -- Green
}

-- Get accent color by index (cycles through colors)
local function getCardAccentColor(index)
	return ACCENT_COLORS[((index - 1) % #ACCENT_COLORS) + 1]
end

-- Utility Functions
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

-- Scaled corner (for responsive design)
local function createScaledCorner(scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	return corner
end

-- Text size constraint
local function createTextSizeConstraint(minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 8
	constraint.MaxTextSize = maxSize or 18
	return constraint
end

-- Scaled padding
local function createScaledPadding(top, bottom, left, right)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(top or 0, 0)
	pad.PaddingBottom = UDim.new(bottom or top or 0, 0)
	pad.PaddingLeft = UDim.new(left or top or 0, 0)
	pad.PaddingRight = UDim.new(right or left or top or 0, 0)
	return pad
end

local function tweenPosition(object, endPos, time, callback)
	local tween = TweenService:Create(object, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = endPos
	})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

local function tweenSize(object, endSize, time, callback)
	local tween = TweenService:Create(object, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = endSize
	})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

-- Make frame draggable
-- Make frame draggable (RESPONSIVE VERSION)
local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput, mousePos, framePos

	dragHandle = dragHandle or frame

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

			-- ✅ Konversi delta pixel ke scale
			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			frame.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,  -- ✅ Offset selalu 0
				framePos.Y.Scale + deltaScaleY,
				0   -- ✅ Offset selalu 0
			)
		end
	end)
end


-- Create Button
local function createButton(text, color, hoverColor)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0.1, 0)  -- ✅ Lebih besar (42px di layar 1080p)
	button.BackgroundColor3 = color or COLORS.Button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 14
	button.AutoButtonColor = false

	createCorner(6).Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor or COLORS.ButtonHover}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or COLORS.Button}):Play()
	end)

	return button
end

local showConfirmation

-- Main Container (for UIAspectRatioConstraint)
local mainContainer = Instance.new("Frame")
mainContainer.Name = "AdminPanelContainer"
mainContainer.Size = UDim2.new(0.55, 0, 0.85, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = screenGui

-- Aspect Ratio Constraint
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 0.7
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = mainContainer

-- Main Admin Panel
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(1, 0, 1, 0)
mainPanel.Position = UDim2.new(0, 0, 0, 0)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
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

-- Panel Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.09, 0)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = mainPanel

createScaledCorner(0.15).Parent = header

-- Header Padding
local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0.02, 0)
headerPadding.PaddingRight = UDim.new(0.02, 0)
headerPadding.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.85, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "Admin Panel"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local headerTitleConstraint = createTextSizeConstraint(12, 20)
headerTitleConstraint.Parent = headerTitle

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.08, 0, 0.7, 0)
closeButton.Position = UDim2.new(1, 0, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "×"
closeButton.TextColor3 = COLORS.Text
closeButton.TextScaled = true
closeButton.Parent = header

createScaledCorner(0.2).Parent = closeButton
createTextSizeConstraint(14, 24).Parent = closeButton

-- Tab System
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0.07, 0)
tabContainer.Position = UDim2.new(0, 0, 0.11, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.01, 0) -- Scale-based padding
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabContainer

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 0.8, 0)
contentContainer.Position = UDim2.new(0, 0, 0.19, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainPanel

-- Tab Creation Function (RESPONSIVE - EQUAL WIDTH) - FIXED
local currentTab = nil
local totalTabs = hasPrimaryAccess and 5 or 4  -- 5 tabs for primary admin (includes Log)

local function createTab(name, order)
	local tab = Instance.new("TextButton")

	-- Scale-based width with gap (5 tabs for primary admin, 4 for secondary)
	local tabWidth = hasPrimaryAccess and 0.19 or 0.24
	tab.Size = UDim2.new(tabWidth, 0, 1, 0)
	tab.BackgroundColor3 = COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamMedium
	tab.Text = name
	tab.TextColor3 = COLORS.TextSecondary
	tab.TextScaled = true
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = tabContainer

	createScaledCorner(0.15).Parent = tab

	-- Text size constraint
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 14
	textSizeConstraint.MinTextSize = 9
	textSizeConstraint.Parent = tab

	local content = Instance.new("Frame")
	content.Name = name .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Visible = false
	content.Parent = contentContainer

	tab.MouseButton1Click:Connect(function()
		-- Hide all tabs
		for _, child in ipairs(contentContainer:GetChildren()) do
			child.Visible = false
		end

		-- Reset all tab colors
		for _, tabBtn in ipairs(tabContainer:GetChildren()) do
			if tabBtn:IsA("TextButton") then
				tabBtn.BackgroundColor3 = COLORS.Button
				tabBtn.TextColor3 = COLORS.TextSecondary
			end
		end

		-- Show selected tab
		content.Visible = true
		tab.BackgroundColor3 = COLORS.Accent
		tab.TextColor3 = COLORS.Text
		currentTab = content
	end)

	return content, tab
end



-- Notification Tab
local notifTab, notifTabBtn = createTab("Notifications", 1)

local notifScroll = Instance.new("ScrollingFrame")
notifScroll.Size = UDim2.new(1, 0, 1, 0)
notifScroll.BackgroundTransparency = 1
notifScroll.BorderSizePixel = 0
notifScroll.ScrollBarThickness = 4
notifScroll.ScrollBarImageColor3 = COLORS.Border
notifScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
notifScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
notifScroll.Parent = notifTab

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 6)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Parent = notifScroll

-- Notification Type Selection
local typeFrame = Instance.new("Frame")
typeFrame.Size = UDim2.new(1, 0, 0, 40)
typeFrame.BackgroundTransparency = 1
typeFrame.LayoutOrder = 1
typeFrame.Parent = notifScroll

local typeLabel = Instance.new("TextLabel")
typeLabel.Size = UDim2.new(0, 100, 1, 0)
typeLabel.BackgroundTransparency = 1
typeLabel.Font = Enum.Font.GothamMedium
typeLabel.Text = "Type:"
typeLabel.TextColor3 = COLORS.Text
typeLabel.TextSize = 14
typeLabel.TextXAlignment = Enum.TextXAlignment.Left
typeLabel.Parent = typeFrame

local typeButtons = Instance.new("Frame")
typeButtons.Size = UDim2.new(1, -110, 1, 0)
typeButtons.Position = UDim2.new(0, 110, 0, 0)
typeButtons.BackgroundTransparency = 1
typeButtons.Parent = typeFrame

local typeLayout = Instance.new("UIListLayout")
typeLayout.FillDirection = Enum.FillDirection.Horizontal
typeLayout.Padding = UDim.new(0, 8)
typeLayout.Parent = typeButtons

local selectedType = "Server"

local function createTypeButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 1, 0)
	btn.BackgroundColor3 = text == "Server" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = typeButtons

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedType = text
		for _, child in ipairs(typeButtons:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Button
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
	end)

	return btn
end

createTypeButton("Server")
createTypeButton("Global")

-- ==================== NOTIFICATION UI TYPE SELECTION ====================
local uiTypeFrame = Instance.new("Frame")
uiTypeFrame.Size = UDim2.new(1, 0, 0, 70)
uiTypeFrame.BackgroundTransparency = 1
uiTypeFrame.LayoutOrder = 1.5
uiTypeFrame.Parent = notifScroll

local uiTypeLabel = Instance.new("TextLabel")
uiTypeLabel.Size = UDim2.new(1, 0, 0, 20)
uiTypeLabel.BackgroundTransparency = 1
uiTypeLabel.Font = Enum.Font.GothamMedium
uiTypeLabel.Text = "Notification Style:"
uiTypeLabel.TextColor3 = COLORS.Text
uiTypeLabel.TextSize = 14
uiTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
uiTypeLabel.Parent = uiTypeFrame

-- Row 1: Position (Middle / Side)
local positionRow = Instance.new("Frame")
positionRow.Size = UDim2.new(1, 0, 0, 25)
positionRow.Position = UDim2.new(0, 0, 0, 22)
positionRow.BackgroundTransparency = 1
positionRow.Parent = uiTypeFrame

local positionLayout = Instance.new("UIListLayout")
positionLayout.FillDirection = Enum.FillDirection.Horizontal
positionLayout.Padding = UDim.new(0, 8)
positionLayout.Parent = positionRow

local selectedPosition = "Side" -- Default: Side

local function createPositionButton(text, value)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 1, 0)
	btn.BackgroundColor3 = value == "Side" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = positionRow

	createCorner(6).Parent = btn
	createTextSizeConstraint(9, 12).Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedPosition = value
		for _, child in ipairs(positionRow:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Button
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
	end)

	return btn
end

createPositionButton("📍 Middle", "Middle")
createPositionButton("🔔 Side", "Side")

-- Row 2: Sender (Text Only / With Sender)
local senderRow = Instance.new("Frame")
senderRow.Size = UDim2.new(1, 0, 0, 25)
senderRow.Position = UDim2.new(0, 0, 0, 48)
senderRow.BackgroundTransparency = 1
senderRow.Parent = uiTypeFrame

local senderLayout = Instance.new("UIListLayout")
senderLayout.FillDirection = Enum.FillDirection.Horizontal
senderLayout.Padding = UDim.new(0, 8)
senderLayout.Parent = senderRow

local selectedSenderType = "TextOnly" -- Default: Text Only

local function createSenderButton(text, value)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 1, 0)
	btn.BackgroundColor3 = value == "TextOnly" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = senderRow

	createCorner(6).Parent = btn
	createTextSizeConstraint(9, 12).Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedSenderType = value
		for _, child in ipairs(senderRow:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Button
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
	end)

	return btn
end

createSenderButton("📝 Text Only", "TextOnly")
createSenderButton("👤 With Sender", "WithSender")

-- Function to get combined notification type
local function getNotificationType()
	return selectedPosition .. selectedSenderType
	-- Results: "MiddleTextOnly", "MiddleWithSender", "SideTextOnly", "SideWithSender"
end
-- ==================== END NOTIFICATION UI TYPE SELECTION ====================

-- Message Input
local messageFrame = Instance.new("Frame")
messageFrame.Size = UDim2.new(1, 0, 0.4, 0)
messageFrame.BackgroundTransparency = 1
messageFrame.LayoutOrder = 2
messageFrame.Parent = notifScroll

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, 0, 0.25, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamMedium
messageLabel.Text = "Message:"
messageLabel.TextColor3 = COLORS.Text
messageLabel.TextSize = 14
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Parent = messageFrame

local messageBox = Instance.new("TextBox")
messageBox.Size = UDim2.new(1, 0, 0.625, 0)
messageBox.Position = UDim2.new(0, 0, 0.313, 0)
messageBox.BackgroundColor3 = COLORS.Panel
messageBox.BorderSizePixel = 0
messageBox.Font = Enum.Font.Gotham
messageBox.PlaceholderText = "Enter notification message..."
messageBox.Text = ""
messageBox.TextColor3 = COLORS.Text
messageBox.TextSize = 13
messageBox.TextWrapped = true
messageBox.TextXAlignment = Enum.TextXAlignment.Left
messageBox.TextYAlignment = Enum.TextYAlignment.Top
messageBox.ClearTextOnFocus = false
messageBox.MultiLine = true
messageBox.Parent = messageFrame

createCorner(6).Parent = messageBox
createPadding(8).Parent = messageBox

-- Duration Slider
local durationFrame = Instance.new("Frame")
durationFrame.Size = UDim2.new(1, 0, 0.15, 0)
durationFrame.BackgroundTransparency = 1
durationFrame.LayoutOrder = 3
durationFrame.Parent = notifScroll

local durationLabel = Instance.new("TextLabel")
durationLabel.Size = UDim2.new(1, 0, 0, 20)
durationLabel.BackgroundTransparency = 1
durationLabel.Font = Enum.Font.GothamMedium
durationLabel.Text = "Duration: 5s"
durationLabel.TextColor3 = COLORS.Text
durationLabel.TextSize = 14
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = durationFrame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0, 8)
sliderBg.Position = UDim2.new(0, 0, 0, 35)
sliderBg.BackgroundColor3 = COLORS.Panel
sliderBg.BorderSizePixel = 0
sliderBg.Parent = durationFrame

createCorner(4).Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.042, 0, 1, 0)
sliderFill.BackgroundColor3 = COLORS.Accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

createCorner(4).Parent = sliderFill

local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 16, 0, 16)
sliderHandle.Position = UDim2.new(0.042, -8, 0.5, -8)
sliderHandle.BackgroundColor3 = COLORS.Text
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderBg

createCorner(8).Parent = sliderHandle

local selectedDuration = 5
local draggingSlider = false

sliderHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and draggingSlider then
		local mousePos = UserInputService:GetMouseLocation()
		local sliderPos = sliderBg.AbsolutePosition.X
		local sliderSize = sliderBg.AbsoluteSize.X
		local relativePos = math.clamp((mousePos.X - sliderPos) / sliderSize, 0, 1)

		selectedDuration = math.floor(relativePos * 120 + 1) -- 1 to 120 seconds
		durationLabel.Text = "Duration: " .. selectedDuration .. "s"

		sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
		sliderHandle.Position = UDim2.new(relativePos, -8, 0.5, -8)
	end
end)

-- Text Color Picker
local colorFrame = Instance.new("Frame")
colorFrame.Size = UDim2.new(1, 0, 0.15, 0)
colorFrame.BackgroundTransparency = 1
colorFrame.LayoutOrder = 4
colorFrame.Parent = notifScroll

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(1, 0, 0, 20)
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.Text = "Text Color:"
colorLabel.TextColor3 = COLORS.Text
colorLabel.TextSize = 14
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = colorFrame

local colorContainer = Instance.new("Frame")
colorContainer.Size = UDim2.new(1, 0, 0, 30)
colorContainer.Position = UDim2.new(0, 0, 0, 25)
colorContainer.BackgroundTransparency = 1
colorContainer.Parent = colorFrame

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0, 8)
colorLayout.Parent = colorContainer

local selectedColor = Color3.fromRGB(255, 255, 255)

local function createColorButton(color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 30, 0, 30)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = colorContainer

	createCorner(6).Parent = btn

	local checkmark = Instance.new("TextLabel")
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Font = Enum.Font.GothamBold
	checkmark.Text = "✓"
	checkmark.TextColor3 = Color3.fromRGB(0, 0, 0)
	checkmark.TextSize = 18
	checkmark.Visible = color == Color3.fromRGB(255, 255, 255)
	checkmark.Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedColor = color
		for _, child in ipairs(colorContainer:GetChildren()) do
			if child:IsA("TextButton") then
				local check = child:FindFirstChildOfClass("TextLabel")
				if check then
					check.Visible = false
				end
			end
		end
		checkmark.Visible = true
	end)
end

createColorButton(Color3.fromRGB(255, 255, 255))
createColorButton(Color3.fromRGB(88, 101, 242))
createColorButton(Color3.fromRGB(67, 181, 129))
createColorButton(Color3.fromRGB(250, 166, 26))
createColorButton(Color3.fromRGB(237, 66, 69))
createColorButton(Color3.fromRGB(153, 170, 181))

-- Send Button
local sendFrame = Instance.new("Frame")
sendFrame.Size = UDim2.new(1, 0, 0.113, 0)
sendFrame.BackgroundTransparency = 1
sendFrame.LayoutOrder = 5
sendFrame.Parent = notifScroll

local sendButton = createButton("Send Notification", COLORS.Accent, COLORS.AccentHover)
sendButton.Size = UDim2.new(1, 0, 1, 0)
sendButton.Parent = sendFrame

-- Update send button (line ~719)
sendButton.MouseButton1Click:Connect(function()
	if messageBox.Text ~= "" then
		local notifText = messageBox.Text
		local color = selectedColor or Color3.fromRGB(255, 255, 255)
		local notificationType = getNotificationType() -- MiddleTextOnly, MiddleWithSender, SideTextOnly, SideWithSender
		local duration = selectedDuration or 5

		-- Fire with color, notification type, and duration parameters
		sendNotificationEvent:FireServer(selectedType:lower(), notifText, color, notificationType, duration)

		messageBox.Text = ""
	end
end)



-- Players Tab
local playersTab, playersTabBtn = createTab("Players", 2)

-- ✅ Search Bar Container
local searchContainer = Instance.new("Frame")
searchContainer.Name = "SearchContainer"
searchContainer.Size = UDim2.new(1, 0, 0, 40)
searchContainer.Position = UDim2.new(0, 0, 0, 0)
searchContainer.BackgroundTransparency = 1
searchContainer.Parent = playersTab

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 35)
searchBox.Position = UDim2.new(0, 10, 0, 0)
searchBox.BackgroundColor3 = COLORS.Panel
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "🔍 Search players..."
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.PlaceholderColor3 = COLORS.TextSecondary
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchContainer

createCorner(8).Parent = searchBox
createStroke(COLORS.Border, 1).Parent = searchBox

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 12)
searchPadding.PaddingRight = UDim.new(0, 12)
searchPadding.Parent = searchBox

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, 0, 1, -50) -- Account for search bar
playersScroll.Position = UDim2.new(0, 0, 0, 45)
playersScroll.BackgroundTransparency = 1
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 4
playersScroll.ScrollBarImageColor3 = COLORS.Border
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersScroll.Parent = playersTab

-- ✅ FIX: Add padding to ScrollingFrame so cards don't get cut off
local playerScrollPadding = Instance.new("UIPadding")
playerScrollPadding.PaddingLeft = UDim.new(0, 10)
playerScrollPadding.PaddingRight = UDim.new(0, 10)
playerScrollPadding.PaddingTop = UDim.new(0, 5)
playerScrollPadding.PaddingBottom = UDim.new(0, 10)
playerScrollPadding.Parent = playersScroll

local playersLayout = Instance.new("UIListLayout")
playersLayout.Padding = UDim.new(0, 8)
playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersLayout.Parent = playersScroll

-- ✅ Search functionality variable (used later in updatePlayers)
local currentSearchQuery = ""

-- Player Detail Panel
local playerDetailPanel = Instance.new("Frame")
playerDetailPanel.Name = "PlayerDetail"
playerDetailPanel.Size = UDim2.new(0.208, 0, 0.509, 0)
playerDetailPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
playerDetailPanel.AnchorPoint = Vector2.new(0.5, 0.5)
playerDetailPanel.BackgroundColor3 = COLORS.Background
playerDetailPanel.BorderSizePixel = 0
playerDetailPanel.Visible = false
playerDetailPanel.ZIndex = 10
playerDetailPanel.Parent = screenGui

createCorner(12).Parent = playerDetailPanel
createStroke(COLORS.Border, 2).Parent = playerDetailPanel

local detailHeader = Instance.new("Frame")
detailHeader.Size = UDim2.new(1, 0, 0.091, 0)
detailHeader.BackgroundColor3 = COLORS.Header
detailHeader.BorderSizePixel = 0
detailHeader.Parent = playerDetailPanel

createCorner(12).Parent = detailHeader

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, -20, 1, 0)
detailTitle.Position = UDim2.new(0, 20, 0, 0)
detailTitle.BackgroundTransparency = 1
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Text = "Player Details"
detailTitle.TextColor3 = COLORS.Text
detailTitle.TextSize = 18
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.Parent = detailHeader

local detailCloseButton = Instance.new("TextButton")
detailCloseButton.Size = UDim2.new(0, 30, 0, 30)
detailCloseButton.Position = UDim2.new(1, -40, 0, 10)
detailCloseButton.BackgroundColor3 = COLORS.Button
detailCloseButton.BorderSizePixel = 0
detailCloseButton.Font = Enum.Font.GothamBold
detailCloseButton.Text = "×"
detailCloseButton.TextColor3 = COLORS.Text
detailCloseButton.TextSize = 20
detailCloseButton.Parent = detailHeader

createCorner(6).Parent = detailCloseButton

detailCloseButton.MouseButton1Click:Connect(function()
	tweenSize(playerDetailPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		playerDetailPanel.Visible = false
		playerDetailPanel.Size = UDim2.new(0.25, 0, 0.509, 0)
		
	end)
end)

local detailScroll = Instance.new("ScrollingFrame")
detailScroll.Size = UDim2.new(0.95, 0, 0.873, 0)
detailScroll.Position = UDim2.new(0.025, 0, 0.109, 0)
detailScroll.BackgroundTransparency = 1
detailScroll.BorderSizePixel = 0
detailScroll.ScrollBarThickness = 4
detailScroll.ScrollBarImageColor3 = COLORS.Border
detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
detailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailScroll.Parent = playerDetailPanel

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0, 10)
detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailLayout.Parent = detailScroll

-- Confirmation Dialog (FIXED - Bigger & Proper Layout)
local confirmDialog = Instance.new("Frame")
confirmDialog.Name = "ConfirmDialog"
confirmDialog.Size = UDim2.new(0, 380, 0, 200)  -- ✅ Lebih besar: 380x200px
confirmDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmDialog.AnchorPoint = Vector2.new(0.5, 0.5)
confirmDialog.BackgroundColor3 = COLORS.Background
confirmDialog.BorderSizePixel = 0
confirmDialog.Visible = false
confirmDialog.ZIndex = 150
confirmDialog.Parent = screenGui

createCorner(12).Parent = confirmDialog
createStroke(COLORS.Border, 2).Parent = confirmDialog

-- Header
local confirmHeader = Instance.new("Frame")
confirmHeader.Size = UDim2.new(1, 0, 0, 50)
confirmHeader.BackgroundColor3 = COLORS.Header
confirmHeader.BorderSizePixel = 0
confirmHeader.Parent = confirmDialog

createCorner(12).Parent = confirmHeader

local confirmHeaderBottom = Instance.new("Frame")
confirmHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
confirmHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
confirmHeaderBottom.BackgroundColor3 = COLORS.Header
confirmHeaderBottom.BorderSizePixel = 0
confirmHeaderBottom.Parent = confirmHeader

-- Title
local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, -30, 1, 0)
confirmTitle.Position = UDim2.new(0, 15, 0, 0)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Text = "Confirm Action"
confirmTitle.TextColor3 = COLORS.Text
confirmTitle.TextSize = 16
confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
confirmTitle.Parent = confirmHeader

-- Message (dengan padding proper)
local confirmMessage = Instance.new("TextLabel")
confirmMessage.Size = UDim2.new(1, -40, 0, 70)  -- ✅ Lebih tinggi untuk text wrapping
confirmMessage.Position = UDim2.new(0, 20, 0, 65)
confirmMessage.BackgroundTransparency = 1
confirmMessage.Font = Enum.Font.Gotham
confirmMessage.Text = ""
confirmMessage.TextColor3 = COLORS.TextSecondary
confirmMessage.TextSize = 14
confirmMessage.TextWrapped = true
confirmMessage.TextXAlignment = Enum.TextXAlignment.Center  -- ✅ Center text
confirmMessage.TextYAlignment = Enum.TextYAlignment.Top
confirmMessage.Parent = confirmDialog

-- Buttons Container (untuk center alignment)
local confirmButtons = Instance.new("Frame")
confirmButtons.Size = UDim2.new(1, -40, 0, 50)  -- ✅ Button lebih tinggi
confirmButtons.Position = UDim2.new(0, 20, 1, -65)  -- ✅ 15px from bottom
confirmButtons.BackgroundTransparency = 1
confirmButtons.Parent = confirmDialog

local confirmButtonLayout = Instance.new("UIListLayout")
confirmButtonLayout.FillDirection = Enum.FillDirection.Horizontal
confirmButtonLayout.Padding = UDim.new(0, 15)  -- ✅ 15px spacing
confirmButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
confirmButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
confirmButtonLayout.Parent = confirmButtons

local currentConfirmCallback = nil

-- ✅ Assign ke variable yang sudah di-declare sebelumnya
showConfirmation = function(title, message, callback)
	confirmTitle.Text = title
	confirmMessage.Text = message
	currentConfirmCallback = callback
	confirmDialog.Size = UDim2.new(0, 0, 0, 0)
	confirmDialog.Visible = true
	tweenSize(confirmDialog, UDim2.new(0, 380, 0, 200), 0.3)
end


-- Cancel Button
local cancelButton = createButton("Cancel", COLORS.Button, COLORS.ButtonHover)
cancelButton.Size = UDim2.new(0, 150, 1, 0)  -- ✅ Fixed width 150px
cancelButton.LayoutOrder = 1
cancelButton.Parent = confirmButtons

cancelButton.MouseButton1Click:Connect(function()
	tweenSize(confirmDialog, UDim2.new(0, 0, 0, 0), 0.3, function()
		confirmDialog.Visible = false
		currentConfirmCallback = nil
	end)
end)

-- Confirm Button
local confirmButton = createButton("Confirm", COLORS.Danger, COLORS.DangerHover)
confirmButton.Size = UDim2.new(0, 150, 1, 0)  -- ✅ Fixed width 150px
confirmButton.LayoutOrder = 2
confirmButton.Parent = confirmButtons

confirmButton.MouseButton1Click:Connect(function()
	if currentConfirmCallback then
		currentConfirmCallback()
	end
	tweenSize(confirmDialog, UDim2.new(0, 0, 0, 0), 0.3, function()
		confirmDialog.Visible = false
		currentConfirmCallback = nil
	end)
end)

-- Player Actions
local currentSpectatePlayer = nil
local originalCamera = nil
local spectateConnection = nil

local function createTeleportPopup(targetPlayer)
	-- ✅ HIDE ALL PANELS when popup opens
	mainContainer.Visible = false
	playerDetailPanel.Visible = false
	
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 280, 0, 180) -- ✅ Fixed pixel size for consistency
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Active = true
	popup.Draggable = true
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup

	-- ✅ FIX: Header with proper fixed size
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 45) -- Fixed 45px height
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	-- Header bottom cover (for rounded corners)
	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 15)
	headerBottom.Position = UDim2.new(0, 0, 1, -15)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Teleport " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -36, 0, 8)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true -- ✅ Show main panel
	end)

	-- ✅ FIX: Teleport Here Button with proper positioning
	local tpHereBtn = Instance.new("TextButton")
	tpHereBtn.Size = UDim2.new(1, -30, 0, 45)
	tpHereBtn.Position = UDim2.new(0, 15, 0, 55) -- Below header
	tpHereBtn.BackgroundColor3 = COLORS.Button
	tpHereBtn.BorderSizePixel = 0
	tpHereBtn.Font = Enum.Font.GothamBold
	tpHereBtn.Text = "Teleport " .. targetPlayer.Name .. " Here"
	tpHereBtn.TextColor3 = COLORS.Text
	tpHereBtn.TextSize = 13
	tpHereBtn.AutoButtonColor = false
	tpHereBtn.Parent = popup

	createCorner(8).Parent = tpHereBtn

	tpHereBtn.MouseEnter:Connect(function()
		tpHereBtn.BackgroundColor3 = COLORS.ButtonHover
	end)

	tpHereBtn.MouseLeave:Connect(function()
		tpHereBtn.BackgroundColor3 = COLORS.Button
	end)

	tpHereBtn.MouseButton1Click:Connect(function()
		teleportHereEvent:FireServer(targetPlayer.UserId)
		popup:Destroy()
		mainContainer.Visible = true -- ✅ Show main panel
	end)

	-- ✅ FIX: Teleport To Button with proper spacing
	local tpToBtn = Instance.new("TextButton")
	tpToBtn.Size = UDim2.new(1, -30, 0, 45)
	tpToBtn.Position = UDim2.new(0, 15, 0, 110) -- 55 + 45 + 10 spacing
	tpToBtn.BackgroundColor3 = COLORS.Button
	tpToBtn.BorderSizePixel = 0
	tpToBtn.Font = Enum.Font.GothamBold
	tpToBtn.Text = "Teleport To " .. targetPlayer.Name
	tpToBtn.TextColor3 = COLORS.Text
	tpToBtn.TextSize = 13
	tpToBtn.AutoButtonColor = false
	tpToBtn.Parent = popup

	createCorner(8).Parent = tpToBtn

	tpToBtn.MouseEnter:Connect(function()
		tpToBtn.BackgroundColor3 = COLORS.ButtonHover
	end)

	tpToBtn.MouseLeave:Connect(function()
		tpToBtn.BackgroundColor3 = COLORS.Button
	end)

	tpToBtn.MouseButton1Click:Connect(function()
		teleportToEvent:FireServer(targetPlayer.UserId)
		popup:Destroy()
		mainContainer.Visible = true -- ✅ Show main panel
	end)

	return popup
end

local function showGiveTitlePopup(targetPlayer)
	-- ✅ HIDE ALL PANELS when popup opens
	mainContainer.Visible = false
	playerDetailPanel.Visible = false
	
	local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
	
	-- Collect all givable titles
	local givableTitles = {}
	for titleName, titleData in pairs(TitleConfig.SpecialTitles) do
		if titleData.Givable == true then
			table.insert(givableTitles, {
				Name = titleName,
				DisplayName = titleData.DisplayName or titleName,
				Color = titleData.Color or COLORS.Text,
				Icon = titleData.Icon or "🏷️",
				Priority = titleData.Priority or 0
			})
		end
	end
	
	-- Sort by priority (highest first)
	table.sort(givableTitles, function(a, b)
		return a.Priority > b.Priority
	end)
	
	-- Calculate popup height (dynamic based on title count)
	local popupHeight = 110 + (#givableTitles * 50) -- Header + titles + button
	if popupHeight > 500 then popupHeight = 500 end -- Max height
	
	local popup = Instance.new("Frame")
	popup.Name = "GiveTitlePopup"
	popup.Size = UDim2.new(0, 350, 0, popupHeight) -- ✅ Slightly bigger
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Active = true
	popup.Draggable = true
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 15)
	headerBottom.Position = UDim2.new(0, 0, 1, -15)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Give Title to " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true -- ✅ Show main panel
	end)

	-- Scroll container for titles
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -100)
	scrollFrame.Position = UDim2.new(0, 10, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = COLORS.Border
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = popup

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	local selectedTitle = nil
	local selectedButton = nil

	-- Create button for each givable title
	for i, titleInfo in ipairs(givableTitles) do
		local titleBtn = Instance.new("TextButton")
		titleBtn.Size = UDim2.new(1, 0, 0, 42)
		titleBtn.BackgroundColor3 = COLORS.Panel
		titleBtn.BorderSizePixel = 0
		titleBtn.Text = ""
		titleBtn.AutoButtonColor = false
		titleBtn.LayoutOrder = i
		titleBtn.Parent = scrollFrame

		createCorner(8).Parent = titleBtn

		-- Accent bar
		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 4, 1, 0)
		accentBar.BackgroundColor3 = titleInfo.Color
		accentBar.BorderSizePixel = 0
		accentBar.Parent = titleBtn

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 8)
		accentCorner.Parent = accentBar

		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 30, 0, 30)
		iconLabel.Position = UDim2.new(0, 15, 0.5, 0)
		iconLabel.AnchorPoint = Vector2.new(0, 0.5)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.Gotham
		iconLabel.Text = titleInfo.Icon
		iconLabel.TextSize = 18
		iconLabel.Parent = titleBtn

		-- Title name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -60, 1, 0)
		nameLabel.Position = UDim2.new(0, 50, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = titleInfo.DisplayName
		nameLabel.TextColor3 = titleInfo.Color
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = titleBtn

		-- Hover effect
		titleBtn.MouseEnter:Connect(function()
			if selectedButton ~= titleBtn then
				TweenService:Create(titleBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
			end
		end)

		titleBtn.MouseLeave:Connect(function()
			if selectedButton ~= titleBtn then
				TweenService:Create(titleBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
			end
		end)

		-- Select title
		titleBtn.MouseButton1Click:Connect(function()
			-- Deselect previous
			if selectedButton then
				selectedButton.BackgroundColor3 = COLORS.Panel
			end

			-- Select new
			selectedTitle = titleInfo.Name
			selectedButton = titleBtn
			titleBtn.BackgroundColor3 = COLORS.Accent
		end)
	end

	-- Give button
	local giveBtn = Instance.new("TextButton")
	giveBtn.Size = UDim2.new(1, -20, 0, 40)
	giveBtn.Position = UDim2.new(0, 10, 1, -50)
	giveBtn.BackgroundColor3 = COLORS.Success
	giveBtn.BorderSizePixel = 0
	giveBtn.Font = Enum.Font.GothamBold
	giveBtn.Text = "Give Title"
	giveBtn.TextColor3 = COLORS.Text
	giveBtn.TextSize = 14
	giveBtn.Parent = popup

	createCorner(8).Parent = giveBtn

	giveBtn.MouseEnter:Connect(function()
		TweenService:Create(giveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(87, 201, 149)}):Play()
	end)

	giveBtn.MouseLeave:Connect(function()
		TweenService:Create(giveBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Success}):Play()
	end)

	giveBtn.MouseButton1Click:Connect(function()
		if not selectedTitle then
			StarterGui:SetCore("SendNotification", {
				Title = "Warning",
				Text = "Please select a title first!",
				Duration = 3
			})
			return
		end

		showConfirmation(
			"Give Title",
			string.format("Give '%s' title to %s?\n(Unlocks only, won't auto-equip)", selectedTitle, targetPlayer.Name),
			function()
				local giveTitleEvent = remoteFolder:FindFirstChild("GiveTitle")
				if giveTitleEvent then
					giveTitleEvent:FireServer(targetPlayer.UserId, selectedTitle)
					print(string.format("[ADMIN CLIENT] Gave title '%s' to %s", selectedTitle, targetPlayer.Name))
				end
				popup:Destroy()
				mainContainer.Visible = true -- ✅ Show main panel
			end
		)
	end)

	return popup
end



local function createModifyPlayerPopup(targetPlayer)
	-- ✅ HIDE ALL PANELS when popup opens
	mainContainer.Visible = false
	playerDetailPanel.Visible = false
	
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 320, 0, 350) -- ✅ Fixed pixel size
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Active = true -- Make draggable
	popup.Draggable = true -- Enable drag
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 15)
	headerBottom.Position = UDim2.new(0, 0, 1, -15)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Modify " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true -- ✅ Show main panel
	end)

	local contentY = 60

	-- Freeze Button (WITH TOGGLE STATE)
	local isFrozen = false
	local freezeBtn = Instance.new("TextButton")
	freezeBtn.Size = UDim2.new(1, -30, 0, 45)
	freezeBtn.Position = UDim2.new(0, 15, 0, contentY)
	freezeBtn.BackgroundColor3 = COLORS.Button
	freezeBtn.BorderSizePixel = 0
	freezeBtn.Font = Enum.Font.GothamBold
	freezeBtn.Text = "Freeze Player"
	freezeBtn.TextColor3 = COLORS.Text
	freezeBtn.TextSize = 13
	freezeBtn.AutoButtonColor = false
	freezeBtn.Parent = popup

	createCorner(8).Parent = freezeBtn

	freezeBtn.MouseButton1Click:Connect(function()
		isFrozen = not isFrozen

		if isFrozen then
			-- Frozen state (green)
			freezeBtn.BackgroundColor3 = COLORS.Success
			freezeBtn.Text = "Unfreeze Player"
			freezePlayerEvent:FireServer(targetPlayer.UserId, true)
		else
			-- Unfrozen state (gray)
			freezeBtn.BackgroundColor3 = COLORS.Button
			freezeBtn.Text = "Freeze Player"
			freezePlayerEvent:FireServer(targetPlayer.UserId, false)
		end
	end)

	contentY = contentY + 55

	-- Speed Label
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1, -30, 0, 20)
	speedLabel.Position = UDim2.new(0, 15, 0, contentY)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Text = "Speed Multiplier: 1.0x"
	speedLabel.TextColor3 = COLORS.Text
	speedLabel.TextSize = 12
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = popup

	contentY = contentY + 25

	-- Speed Slider
	local speedSliderBg = Instance.new("Frame")
	speedSliderBg.Size = UDim2.new(1, -30, 0, 8)
	speedSliderBg.Position = UDim2.new(0, 15, 0, contentY)
	speedSliderBg.BackgroundColor3 = COLORS.Panel
	speedSliderBg.BorderSizePixel = 0
	speedSliderBg.Parent = popup

	createCorner(4).Parent = speedSliderBg

	local speedFill = Instance.new("Frame")
	speedFill.Size = UDim2.new(0.2, 0, 1, 0)
	speedFill.BackgroundColor3 = COLORS.Accent
	speedFill.BorderSizePixel = 0
	speedFill.Parent = speedSliderBg

	createCorner(4).Parent = speedFill

	local speedHandle = Instance.new("Frame")
	speedHandle.Size = UDim2.new(0, 16, 0, 16)
	speedHandle.Position = UDim2.new(0.2, -8, 0.5, -8)
	speedHandle.BackgroundColor3 = COLORS.Text
	speedHandle.BorderSizePixel = 0
	speedHandle.Parent = speedSliderBg

	createCorner(8).Parent = speedHandle

	-- Speed slider interaction
	local draggingSpeed = false

	speedSliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSpeed = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSpeed and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position.X
			local sliderPos = speedSliderBg.AbsolutePosition.X
			local sliderSize = speedSliderBg.AbsoluteSize.X
			local relative = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)

			speedFill.Size = UDim2.new(relative, 0, 1, 0)
			speedHandle.Position = UDim2.new(relative, -8, 0.5, -8)

			local speedValue = 0.1 + (relative * 3.9)
			speedLabel.Text = string.format("Speed Multiplier: %.1fx", speedValue)
			setSpeedEvent:FireServer(targetPlayer.UserId, speedValue)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSpeed = false
		end
	end)

	contentY = contentY + 30

	-- Gravity Label
	local gravityLabel = Instance.new("TextLabel")
	gravityLabel.Size = UDim2.new(1, -30, 0, 20)
	gravityLabel.Position = UDim2.new(0, 15, 0, contentY)
	gravityLabel.BackgroundTransparency = 1
	gravityLabel.Font = Enum.Font.GothamBold
	gravityLabel.Text = "Gravity: Normal"
	gravityLabel.TextColor3 = COLORS.Text
	gravityLabel.TextSize = 12
	gravityLabel.TextXAlignment = Enum.TextXAlignment.Left
	gravityLabel.Parent = popup

	contentY = contentY + 25

	-- Gravity Buttons (CENTERED with equal spacing)
	local gravityTypes = {"Normal", "Low", "Zero", "High"}
	local currentGravity = "Normal"
	local buttonWidth = 0.23
	local totalGap = 1 - (buttonWidth * 4)
	local spacing = totalGap / 5 -- Equal spacing left, right, and between

	for i, gType in ipairs(gravityTypes) do
		local xPosition = spacing * i + buttonWidth * (i - 1)

		local gBtn = Instance.new("TextButton")
		gBtn.Size = UDim2.new(buttonWidth, 0, 0, 35)
		gBtn.Position = UDim2.new(xPosition, 0, 0, contentY)
		gBtn.BackgroundColor3 = (i == 1) and COLORS.Accent or COLORS.Button
		gBtn.BorderSizePixel = 0
		gBtn.Font = Enum.Font.GothamBold
		gBtn.Text = gType
		gBtn.TextColor3 = COLORS.Text
		gBtn.TextSize = 11
		gBtn.AutoButtonColor = false
		gBtn.Parent = popup

		createCorner(6).Parent = gBtn

		gBtn.MouseButton1Click:Connect(function()
			currentGravity = gType
			gravityLabel.Text = "Gravity: " .. gType

			local gravValue = 196.2
			if gType == "Low" then gravValue = 50
			elseif gType == "Zero" then gravValue = 0
			elseif gType == "High" then gravValue = 400 end

			setGravityEvent:FireServer(targetPlayer.UserId, gravValue)

			-- Update colors
			for _, btn in ipairs(popup:GetChildren()) do
				if btn:IsA("TextButton") and table.find(gravityTypes, btn.Text) then
					btn.BackgroundColor3 = (btn.Text == gType) and COLORS.Accent or COLORS.Button
				end
			end
		end)
	end


	return popup
end

-- ✅ FUNCTION BARU: Show Modify Summit Popup (FIXED - Bigger & Draggable)
local function showModifySummitPopup(targetPlayer)
	-- ✅ HIDE ALL PANELS when popup opens
	mainContainer.Visible = false
	playerDetailPanel.Visible = false
	
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 380, 0, 300)  -- ✅ Fixed pixel size
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup

	-- ✅ DRAGGABLE
	makeDraggable(popup)

	-- Header (Draggable handle)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	-- Header bottom filler (rounded corner fix)
	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 15)
	headerBottom.Position = UDim2.new(0, 0, 1, -15)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Modify " .. targetPlayer.Name .. " Summit Data"
	title.TextColor3 = COLORS.Text
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -40, 0, 10)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true -- ✅ Show main panel
	end)

	-- ✅ CONTENT CONTAINER (untuk spacing proper)
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(1, -30, 1, -65)  -- Leave space for header & bottom
	contentContainer.Position = UDim2.new(0, 15, 0, 60)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = popup

	-- Current Summit Display
	local currentLabel = Instance.new("TextLabel")
	currentLabel.Size = UDim2.new(1, 0, 0, 25)
	currentLabel.Position = UDim2.new(0, 0, 0, 0)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.Gotham
	currentLabel.Text = "Current Summit: Loading..."
	currentLabel.TextColor3 = COLORS.TextSecondary
	currentLabel.TextSize = 13
	currentLabel.TextXAlignment = Enum.TextXAlignment.Left
	currentLabel.Parent = contentContainer

	-- Get current summit value
	task.spawn(function()
		local playerStats = targetPlayer:FindFirstChild("PlayerStats")
		if playerStats then
			local summitValue = playerStats:FindFirstChild("Summit")
			if summitValue then
				currentLabel.Text = "Current Summit: " .. tostring(summitValue.Value)
			end
		end
	end)

	-- Input Label
	local inputLabel = Instance.new("TextLabel")
	inputLabel.Size = UDim2.new(1, 0, 0, 25)
	inputLabel.Position = UDim2.new(0, 0, 0, 35)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Font = Enum.Font.GothamBold
	inputLabel.Text = "New Summit Value:"
	inputLabel.TextColor3 = COLORS.Text
	inputLabel.TextSize = 14
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.Parent = contentContainer

	-- Input Box
	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(1, 0, 0, 50)  -- ✅ Lebih tinggi
	inputBox.Position = UDim2.new(0, 0, 0, 70)
	inputBox.BackgroundColor3 = COLORS.Panel
	inputBox.BorderSizePixel = 0
	inputBox.Font = Enum.Font.Gotham
	inputBox.PlaceholderText = "Enter summit value (e.g. 100)"
	inputBox.Text = ""
	inputBox.TextColor3 = COLORS.Text
	inputBox.TextSize = 15
	inputBox.ClearTextOnFocus = false
	inputBox.Parent = contentContainer

	createCorner(8).Parent = inputBox
	createPadding(12).Parent = inputBox

	-- Set Button
	local setBtn = createButton("Set Summit", COLORS.Success, Color3.fromRGB(77, 191, 139))
	setBtn.Size = UDim2.new(1, 0, 0, 50)  -- ✅ Lebih tinggi
	setBtn.Position = UDim2.new(0, 0, 0, 135)  -- ✅ Proper spacing
	setBtn.Parent = contentContainer

	setBtn.MouseButton1Click:Connect(function()
		local newValue = tonumber(inputBox.Text)

		if not newValue or newValue < 0 then
			-- Show error notification
			StarterGui:SetCore("SendNotification", {
				Title = "❌ Invalid Input",
				Text = "Please enter a valid number (0 or greater)",
				Duration = 3
			})
			return
		end

		-- Show confirmation dialog
		showConfirmation(
			"Modify Summit Data",
			string.format("Set %s's summit to %d?", targetPlayer.Name, newValue),
			function()
				local modifySummitEvent = remoteFolder:FindFirstChild("ModifySummitData")
				if modifySummitEvent then
					modifySummitEvent:FireServer(targetPlayer.UserId, newValue)
					print(string.format("[ADMIN CLIENT] Set %s's summit to %d", targetPlayer.Name, newValue))
				end
				popup:Destroy()
				mainContainer.Visible = true -- ✅ Show main panel
			end
		)
	end)

	return popup
end



-- Player card index counter for accent colors
local playerCardIndex = 0

local function createPlayerCard(targetPlayer)
	local isLocalPlayer = (targetPlayer == player)
	playerCardIndex = playerCardIndex + 1
	local accentColor = getCardAccentColor(playerCardIndex)

	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0, 60)
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.ClipsDescendants = true
	card.Parent = playersScroll

	createCorner(8).Parent = card
	
	-- Colored outline stroke (accent color)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = accentColor
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = card
	
	-- Left accent bar (like Donate panel)
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	
	-- Accent bar corner (only left side rounded)
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 8)
	accentCorner.Parent = accentBar

	-- Avatar - more square with subtle rounding
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 45, 0, 45)
	avatar.Position = UDim2.new(0, 15, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
	avatar.Parent = card

	createCorner(6).Parent = avatar  -- Square with subtle rounding

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 70, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = targetPlayer.Name .. (isLocalPlayer and " (You)" or "")
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card
	
	createTextSizeConstraint(10, 14).Parent = nameLabel

	local displayLabel = Instance.new("TextLabel")
	displayLabel.Size = UDim2.new(0.5, 0, 0, 16)
	displayLabel.Position = UDim2.new(0, 70, 0, 34)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Font = Enum.Font.Gotham
	displayLabel.Text = "@" .. targetPlayer.DisplayName
	displayLabel.TextColor3 = accentColor  -- Use accent color for display name
	displayLabel.TextScaled = true
	displayLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayLabel.Parent = card
	
	createTextSizeConstraint(9, 12).Parent = displayLabel



	-- ✅ TAMBAHKAN: Title Label di sebelah kanan
	local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

	local function updateTitleLabel()
		-- ✅ REQUEST TITLE DARI SERVER via ShopRemotes
		local titleText = "Pengunjung" -- Default
		local titleColor = COLORS.TextSecondary

		local shopRemotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
		if shopRemotes then
			local getTargetTitle = shopRemotes:FindFirstChild("GetTargetTitle")
			if getTargetTitle and getTargetTitle:IsA("RemoteFunction") then
				local success, serverTitle = pcall(function()
					return getTargetTitle:InvokeServer(targetPlayer)
				end)

				if success and serverTitle then
					titleText = serverTitle
					print("📥 [ADMIN CLIENT] Got title for", targetPlayer.Name, ":", titleText) -- DEBUG

					-- Set color based on title
					local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
					if TitleConfig.Titles[titleText] then
						titleColor = TitleConfig.Titles[titleText].Color
					end
				else
					warn("⚠️ [ADMIN CLIENT] Failed to get title for", targetPlayer.Name)
				end
			end
		end

		-- Create/Update title label UI
		local titleLabel = card:FindFirstChild("TitleLabel")
		if not titleLabel then
			titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Size = UDim2.new(0, 70, 0, 20)
			titleLabel.Position = UDim2.new(1, -80, 0, 20)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 11
			titleLabel.TextXAlignment = Enum.TextXAlignment.Right
			titleLabel.Parent = card
		end

		-- Update text
		if titleText == "Pengunjung" then
			titleLabel.Text = ""
		else
			titleLabel.Text = titleText
			titleLabel.TextColor3 = titleColor
		end
	end

	updateTitleLabel()

	-- Listen for changes (with debounce to prevent spam)
	local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
	local lastTitleUpdate = 0
	local TITLE_DEBOUNCE = 2  -- Minimum 2 seconds between updates
	
	if titleRemotes then
		local updateOther = titleRemotes:FindFirstChild("UpdateOtherPlayerTitle")
		if updateOther then
			updateOther.OnClientEvent:Connect(function(changedPlayer, newTitle)
				if changedPlayer == targetPlayer then
					-- Debounce to prevent spam
					local now = tick()
					if now - lastTitleUpdate < TITLE_DEBOUNCE then return end
					lastTitleUpdate = now
					
					task.wait(0.5)
					updateTitleLabel()
				end
			end)
		end
	end

	-- Allow hover effect and click functionality for ALL players (including self)
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
	end)

	card.MouseButton1Click:Connect(function()
		-- Clear previous detail content
		for _, child in ipairs(detailScroll:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

			-- Player Info Section
			local infoSection = Instance.new("Frame")
			infoSection.Size = UDim2.new(1, 0, 0, 120)
			infoSection.BackgroundColor3 = COLORS.Panel
			infoSection.BorderSizePixel = 0
			infoSection.LayoutOrder = 1
			infoSection.Parent = detailScroll

			createCorner(8).Parent = infoSection

			local detailAvatar = Instance.new("ImageLabel")
			detailAvatar.Size = UDim2.new(0, 80, 0, 80)
			detailAvatar.Position = UDim2.new(0, 20, 0, 20)
			detailAvatar.BackgroundColor3 = COLORS.Button
			detailAvatar.BorderSizePixel = 0
			detailAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
			detailAvatar.Parent = infoSection

			createCorner(40).Parent = detailAvatar

			local detailName = Instance.new("TextLabel")
			detailName.Size = UDim2.new(1, -120, 0, 25)
			detailName.Position = UDim2.new(0, 110, 0, 20)
			detailName.BackgroundTransparency = 1
			detailName.Font = Enum.Font.GothamBold
			detailName.Text = targetPlayer.Name
			detailName.TextColor3 = COLORS.Text
			detailName.TextSize = 18
			detailName.TextXAlignment = Enum.TextXAlignment.Left
			detailName.Parent = infoSection

			local detailDisplay = Instance.new("TextLabel")
			detailDisplay.Size = UDim2.new(1, -120, 0, 20)
			detailDisplay.Position = UDim2.new(0, 110, 0, 48)
			detailDisplay.BackgroundTransparency = 1
			detailDisplay.Font = Enum.Font.Gotham
			detailDisplay.Text = "@" .. targetPlayer.DisplayName
			detailDisplay.TextColor3 = COLORS.TextSecondary
			detailDisplay.TextSize = 14
			detailDisplay.TextXAlignment = Enum.TextXAlignment.Left
			detailDisplay.Parent = infoSection

			local detailUserId = Instance.new("TextLabel")
			detailUserId.Size = UDim2.new(1, -120, 0, 20)
			detailUserId.Position = UDim2.new(0, 110, 0, 70)
			detailUserId.BackgroundTransparency = 1
			detailUserId.Font = Enum.Font.Gotham
			detailUserId.Text = "ID: " .. targetPlayer.UserId
			detailUserId.TextColor3 = COLORS.TextSecondary
			detailUserId.TextSize = 12
			detailUserId.TextXAlignment = Enum.TextXAlignment.Left
			detailUserId.Parent = infoSection

			-- Action Buttons Grid
			local actionsFrame = Instance.new("Frame")
			actionsFrame.Size = UDim2.new(1, 0, 0, 0)
			actionsFrame.BackgroundTransparency = 1
			actionsFrame.LayoutOrder = 2
			actionsFrame.Parent = detailScroll

			local actionsLayout = Instance.new("UIListLayout")
			actionsLayout.Padding = UDim.new(0, 8)
			actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
			actionsLayout.Parent = actionsFrame

			actionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				actionsFrame.Size = UDim2.new(1, 0, 0, actionsLayout.AbsoluteContentSize.Y)
			end)

			-- Kick Button
			local kickBtn = createButton("Kick Player", COLORS.Button, COLORS.ButtonHover)
			kickBtn.LayoutOrder = 1
			kickBtn.Parent = actionsFrame

			kickBtn.MouseButton1Click:Connect(function()
				showConfirmation("Kick Player", "Are you sure you want to kick " .. targetPlayer.Name .. "?", function()
					if targetPlayer then
						kickPlayerEvent:FireServer(targetPlayer.UserId)
					end
				end)
			end)

			-- Ban Button
			local banBtn = createButton("Ban Player", COLORS.Button, COLORS.ButtonHover)
			banBtn.LayoutOrder = 2
			banBtn.Parent = actionsFrame

			banBtn.MouseButton1Click:Connect(function()
				showConfirmation("Ban Player", "Are you sure you want to ban " .. targetPlayer.Name .. "?", function()
					if targetPlayer then
						banPlayerEvent:FireServer(targetPlayer.UserId)
					end
				end)
			end)
			
			-- Teleport Button (NEW)
			local teleportBtn = createButton("Teleport", COLORS.Button, COLORS.ButtonHover)
			teleportBtn.LayoutOrder = 3
			teleportBtn.Parent = actionsFrame
			teleportBtn.MouseButton1Click:Connect(function()
				playerDetailPanel.Visible = false -- ✅ Hide detail panel
				createTeleportPopup(targetPlayer)
			end)

			-- Modify Player Button (NEW)
			local modifyBtn = createButton("Modify Player", COLORS.Button, COLORS.ButtonHover)
			modifyBtn.LayoutOrder = 4
			modifyBtn.Parent = actionsFrame
			modifyBtn.MouseButton1Click:Connect(function()
				playerDetailPanel.Visible = false -- ✅ Hide detail panel
				createModifyPlayerPopup(targetPlayer)
			end)



			-- Spectate Button
			local spectateBtn = createButton("Spectate Player", COLORS.Accent, COLORS.AccentHover)
			spectateBtn.LayoutOrder = 5
			spectateBtn.Parent = actionsFrame

			spectateBtn.MouseButton1Click:Connect(function()
				if currentSpectatePlayer then
					-- Stop spectating
					if spectateConnection then
						spectateConnection:Disconnect()
					end

					workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
					workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
					currentSpectatePlayer = nil
					spectateBtn.Text = "Spectate Player"
					spectateBtn.BackgroundColor3 = COLORS.Accent
				else
					-- Start spectating
					if targetPlayer and targetPlayer.Character then
						currentSpectatePlayer = targetPlayer
						local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")

						if targetHumanoid then
							workspace.CurrentCamera.CameraSubject = targetHumanoid
							spectateBtn.Text = "Stop Spectating"
							spectateBtn.BackgroundColor3 = COLORS.Success

							-- Monitor if player leaves or dies
							spectateConnection = targetPlayer.CharacterRemoving:Connect(function()
								if spectateConnection then
									spectateConnection:Disconnect()
								end
								workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
								workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
								currentSpectatePlayer = nil
								spectateBtn.Text = "Spectate Player"
								spectateBtn.BackgroundColor3 = COLORS.Accent
							end)
						end
					end
				end
			end)

			-- Kill Button
			local killBtn = createButton("Kill Player", COLORS.Danger, COLORS.DangerHover)
			killBtn.LayoutOrder = 6
			killBtn.Parent = actionsFrame

			killBtn.MouseButton1Click:Connect(function()
				showConfirmation("Kill Player", "Are you sure you want to kill " .. targetPlayer.Name .. "?", function()
					if targetPlayer then
						killPlayerEvent:FireServer(targetPlayer.UserId)
					end
				end)
			end)
			
			-- Give Title Button
			local giveTitleBtn = createButton("Give Title", COLORS.Accent, COLORS.AccentHover)
			giveTitleBtn.LayoutOrder = 7
			giveTitleBtn.Parent = actionsFrame
			giveTitleBtn.MouseButton1Click:Connect(function()
				if targetPlayer then
					playerDetailPanel.Visible = false -- ✅ Hide detail panel
					showGiveTitlePopup(targetPlayer)
				end
			end)
			
			-- ✅ Modify Summit Data Button (BARU)
			local modifySummitBtn = createButton("Modify Summit Data", COLORS.Accent, Color3.fromRGB(128, 141, 255))
			modifySummitBtn.LayoutOrder = 8  -- Setelah Set Title
			modifySummitBtn.Parent = actionsFrame
			modifySummitBtn.MouseButton1Click:Connect(function()
				if targetPlayer then
					playerDetailPanel.Visible = false -- ✅ Hide detail panel
					showModifySummitPopup(targetPlayer)
				end
			end)


			
		-- Give Items Button (TAMBAHKAN SETELAH setTitleBtn)
			local giveItemsBtn = createButton("Give Items", COLORS.Success, COLORS.Success)
			giveItemsBtn.LayoutOrder = 8
			giveItemsBtn.Parent = actionsFrame

			giveItemsBtn.MouseButton1Click:Connect(function()
				if not targetPlayer then return end

				-- Load ShopConfig
				local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

				-- ✅ HIDE ALL PANELS when popup opens
				mainContainer.Visible = false
				playerDetailPanel.Visible = false

				-- Create Give Items Popup (LARGER SIZE)
				local giveItemsPopup = Instance.new("Frame")
				giveItemsPopup.Name = "GiveItemsPopup"
				giveItemsPopup.Size = UDim2.new(0, 450, 0, 550) -- ✅ Fixed pixel size: 450x550
				giveItemsPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
				giveItemsPopup.AnchorPoint = Vector2.new(0.5, 0.5)
				giveItemsPopup.BackgroundColor3 = COLORS.Background
				giveItemsPopup.BorderSizePixel = 0
				giveItemsPopup.ZIndex = 30
				giveItemsPopup.ClipsDescendants = true -- ✅ Prevent overflow
				giveItemsPopup.Parent = screenGui

				createCorner(12).Parent = giveItemsPopup
				createStroke(COLORS.Border, 2).Parent = giveItemsPopup

				-- Header
				local popupHeader = Instance.new("Frame")
				popupHeader.Size = UDim2.new(1, 0, 0, 50)
				popupHeader.BackgroundColor3 = COLORS.Header
				popupHeader.BorderSizePixel = 0
				popupHeader.Parent = giveItemsPopup
				
				createCorner(12).Parent = popupHeader
				
				-- Header bottom filler
				local headerBottom = Instance.new("Frame")
				headerBottom.Size = UDim2.new(1, 0, 0, 15)
				headerBottom.Position = UDim2.new(0, 0, 1, -15)
				headerBottom.BackgroundColor3 = COLORS.Header
				headerBottom.BorderSizePixel = 0
				headerBottom.Parent = popupHeader

				local popupTitle = Instance.new("TextLabel")
				popupTitle.Size = UDim2.new(1, -60, 1, 0)
				popupTitle.Position = UDim2.new(0, 20, 0, 0)
				popupTitle.BackgroundTransparency = 1
				popupTitle.Font = Enum.Font.GothamBold
				popupTitle.Text = "Give Items to " .. targetPlayer.Name
				popupTitle.TextColor3 = COLORS.Text
				popupTitle.TextSize = 16
				popupTitle.TextXAlignment = Enum.TextXAlignment.Left
				popupTitle.Parent = popupHeader

				local closePopupBtn = Instance.new("TextButton")
				closePopupBtn.Size = UDim2.new(0, 30, 0, 30)
				closePopupBtn.Position = UDim2.new(1, -40, 0, 10)
				closePopupBtn.BackgroundColor3 = COLORS.Button
				closePopupBtn.BorderSizePixel = 0
				closePopupBtn.Font = Enum.Font.GothamBold
				closePopupBtn.Text = "×"
				closePopupBtn.TextColor3 = COLORS.Text
				closePopupBtn.TextSize = 20
				closePopupBtn.Parent = popupHeader

				createCorner(6).Parent = closePopupBtn

				-- ✅ Close popup and SHOW MAIN PANEL again
				closePopupBtn.MouseButton1Click:Connect(function()
					giveItemsPopup:Destroy()
					mainContainer.Visible = true -- ✅ Show main panel
				end)

				-- Tab Frame (FIXED - proper sizing)
				local tabFrame = Instance.new("Frame")
				tabFrame.Size = UDim2.new(1, -40, 0, 40)
				tabFrame.Position = UDim2.new(0, 20, 0, 60)
				tabFrame.BackgroundTransparency = 1
				tabFrame.ClipsDescendants = true
				tabFrame.Parent = giveItemsPopup

				local tabLayout = Instance.new("UIListLayout")
				tabLayout.FillDirection = Enum.FillDirection.Horizontal
				tabLayout.Padding = UDim.new(0, 10)
				tabLayout.Parent = tabFrame

				-- ✅ FIX: Tab buttons with proper width (fit in 450-40 = 410px)
				local auraTab = Instance.new("TextButton")
				auraTab.Size = UDim2.new(0, 125, 0, 35)
				auraTab.BackgroundColor3 = COLORS.Accent
				auraTab.BorderSizePixel = 0
				auraTab.Font = Enum.Font.GothamBold
				auraTab.Text = "Auras"
				auraTab.TextColor3 = COLORS.Text
				auraTab.TextSize = 13
				auraTab.AutoButtonColor = false
				auraTab.Parent = tabFrame

				createCorner(6).Parent = auraTab

				local toolTab = Instance.new("TextButton")
				toolTab.Size = UDim2.new(0, 125, 0, 35)
				toolTab.BackgroundColor3 = COLORS.Button
				toolTab.BorderSizePixel = 0
				toolTab.Font = Enum.Font.GothamBold
				toolTab.Text = "Tools"
				toolTab.TextColor3 = COLORS.Text
				toolTab.TextSize = 13
				toolTab.AutoButtonColor = false
				toolTab.Parent = tabFrame
				
				local moneyTab = Instance.new("TextButton")
				moneyTab.Size = UDim2.new(0, 125, 0, 35)
				moneyTab.BackgroundColor3 = COLORS.Button
				moneyTab.BorderSizePixel = 0
				moneyTab.Font = Enum.Font.GothamBold
				moneyTab.Text = "Money"
				moneyTab.TextColor3 = COLORS.Text
				moneyTab.TextSize = 13
				moneyTab.AutoButtonColor = false
				moneyTab.Parent = tabFrame

				createCorner(6).Parent = moneyTab
				createCorner(6).Parent = toolTab

				-- Content Frame (FIXED - more space for items)
				local contentFrame = Instance.new("Frame")
				contentFrame.Size = UDim2.new(1, -40, 0, 360) -- Fixed height
				contentFrame.Position = UDim2.new(0, 20, 0, 110)
				contentFrame.BackgroundTransparency = 1
				contentFrame.ClipsDescendants = true
				contentFrame.Parent = giveItemsPopup

				-- Aura Content
				local auraContent = Instance.new("ScrollingFrame")
				auraContent.Size = UDim2.new(1, 0, 1, 0)
				auraContent.BackgroundTransparency = 1
				auraContent.BorderSizePixel = 0
				auraContent.ScrollBarThickness = 4
				auraContent.ScrollBarImageColor3 = COLORS.Border
				auraContent.CanvasSize = UDim2.new(0, 0, 0, 0)
				auraContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
				auraContent.Visible = true
				auraContent.Parent = contentFrame

				local auraLayout = Instance.new("UIListLayout")
				auraLayout.Padding = UDim.new(0, 6)
				auraLayout.SortOrder = Enum.SortOrder.LayoutOrder
				auraLayout.Parent = auraContent

				-- Tool Content
				local toolContent = Instance.new("ScrollingFrame")
				toolContent.Size = UDim2.new(1, 0, 1, 0)
				toolContent.BackgroundTransparency = 1
				toolContent.BorderSizePixel = 0
				toolContent.ScrollBarThickness = 4
				toolContent.ScrollBarImageColor3 = COLORS.Border
				toolContent.CanvasSize = UDim2.new(0, 0, 0, 0)
				toolContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
				toolContent.Visible = false
				toolContent.Parent = contentFrame

				local toolLayout = Instance.new("UIListLayout")
				toolLayout.Padding = UDim.new(0, 6)
				toolLayout.SortOrder = Enum.SortOrder.LayoutOrder
				toolLayout.Parent = toolContent
				
				-- ✅ TAMBAHKAN MONEY CONTENT
				local moneyContent = Instance.new("ScrollingFrame")
				moneyContent.Size = UDim2.new(1, 0, 1, 0)
				moneyContent.BackgroundTransparency = 1
				moneyContent.BorderSizePixel = 0
				moneyContent.ScrollBarThickness = 4
				moneyContent.ScrollBarImageColor3 = COLORS.Border
				moneyContent.CanvasSize = UDim2.new(0, 0, 0, 0)
				moneyContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
				moneyContent.Visible = false
				moneyContent.Parent = contentFrame

				local moneyLayout = Instance.new("UIListLayout")
				moneyLayout.Padding = UDim.new(0, 6)
				moneyLayout.SortOrder = Enum.SortOrder.LayoutOrder
				moneyLayout.Parent = moneyContent

				-- Selected Items Storage
				local selectedAuras = {}
				local selectedTools = {}

				-- Create Aura Checkboxes
				for _, aura in ipairs(ShopConfig.Auras) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 40)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = auraContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0, 30, 0, 30)
					checkbox.Position = UDim2.new(0, 5, 0, 5)
					checkbox.BackgroundColor3 = COLORS.Button
					checkbox.BorderSizePixel = 0
					checkbox.Text = ""
					checkbox.AutoButtonColor = false
					checkbox.Parent = frame

					createCorner(6).Parent = checkbox

					local checkmark = Instance.new("TextLabel")
					checkmark.Size = UDim2.new(1, 0, 1, 0)
					checkmark.BackgroundTransparency = 1
					checkmark.Font = Enum.Font.GothamBold
					checkmark.Text = "✓"
					checkmark.TextColor3 = COLORS.Success
					checkmark.TextSize = 18
					checkmark.Visible = false
					checkmark.Parent = checkbox

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -45, 1, 0)
					label.Position = UDim2.new(0, 40, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = aura.Title
					label.TextColor3 = COLORS.Text
					label.TextSize = 13
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame

					checkbox.MouseButton1Click:Connect(function()
						local isSelected = table.find(selectedAuras, aura.AuraId)
						if isSelected then
							table.remove(selectedAuras, isSelected)
							checkmark.Visible = false
							checkbox.BackgroundColor3 = COLORS.Button
						else
							table.insert(selectedAuras, aura.AuraId)
							checkmark.Visible = true
							checkbox.BackgroundColor3 = COLORS.Success
						end
					end)
				end
				
				-- ✅ EXTRA AURAS: Crystal Event auras (not in shop)
				local extraAuras = {
					{AuraId = "Aura1", Title = "💎 Crystal Aura 1"},
					{AuraId = "Aura2", Title = "💎 Crystal Aura 2"},
					{AuraId = "Aura3", Title = "💎 Crystal Aura 3"},
					{AuraId = "Aura4", Title = "💎 Crystal Aura 4"},
					{AuraId = "Aura5", Title = "💎 Crystal Aura 5"},
					{AuraId = "Aura6", Title = "💎 Crystal Aura 6"},
					{AuraId = "Aura7", Title = "💎 Crystal Aura 7"},
					{AuraId = "Aura8", Title = "💎 Crystal Aura 8"},
				}
				
				-- Separator for extra auras
				local extraAurasLabel = Instance.new("TextLabel")
				extraAurasLabel.Size = UDim2.new(1, 0, 0, 25)
				extraAurasLabel.BackgroundTransparency = 1
				extraAurasLabel.Font = Enum.Font.GothamBold
				extraAurasLabel.Text = "── Crystal Event Auras ──"
				extraAurasLabel.TextColor3 = COLORS.TextSecondary
				extraAurasLabel.TextSize = 11
				extraAurasLabel.Parent = auraContent
				
				for _, aura in ipairs(extraAuras) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 40)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = auraContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0, 30, 0, 30)
					checkbox.Position = UDim2.new(0, 5, 0, 5)
					checkbox.BackgroundColor3 = COLORS.Button
					checkbox.BorderSizePixel = 0
					checkbox.Text = ""
					checkbox.AutoButtonColor = false
					checkbox.Parent = frame

					createCorner(6).Parent = checkbox

					local checkmark = Instance.new("TextLabel")
					checkmark.Size = UDim2.new(1, 0, 1, 0)
					checkmark.BackgroundTransparency = 1
					checkmark.Font = Enum.Font.GothamBold
					checkmark.Text = "✓"
					checkmark.TextColor3 = COLORS.Success
					checkmark.TextSize = 18
					checkmark.Visible = false
					checkmark.Parent = checkbox

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -45, 1, 0)
					label.Position = UDim2.new(0, 40, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = aura.Title
					label.TextColor3 = COLORS.Text
					label.TextSize = 13
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame

					checkbox.MouseButton1Click:Connect(function()
						local isSelected = table.find(selectedAuras, aura.AuraId)
						if isSelected then
							table.remove(selectedAuras, isSelected)
							checkmark.Visible = false
							checkbox.BackgroundColor3 = COLORS.Button
						else
							table.insert(selectedAuras, aura.AuraId)
							checkmark.Visible = true
							checkbox.BackgroundColor3 = COLORS.Success
						end
					end)
				end

				-- Create Tool Checkboxes
				for _, tool in ipairs(ShopConfig.Tools) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 40)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = toolContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0, 30, 0, 30)
					checkbox.Position = UDim2.new(0, 5, 0, 5)
					checkbox.BackgroundColor3 = COLORS.Button
					checkbox.BorderSizePixel = 0
					checkbox.Text = ""
					checkbox.AutoButtonColor = false
					checkbox.Parent = frame

					createCorner(6).Parent = checkbox

					local checkmark = Instance.new("TextLabel")
					checkmark.Size = UDim2.new(1, 0, 1, 0)
					checkmark.BackgroundTransparency = 1
					checkmark.Font = Enum.Font.GothamBold
					checkmark.Text = "✓"
					checkmark.TextColor3 = COLORS.Success
					checkmark.TextSize = 18
					checkmark.Visible = false
					checkmark.Parent = checkbox

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -45, 1, 0)
					label.Position = UDim2.new(0, 40, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = tool.Title
					label.TextColor3 = COLORS.Text
					label.TextSize = 13
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame

					checkbox.MouseButton1Click:Connect(function()
						local isSelected = table.find(selectedTools, tool.ToolId)
						if isSelected then
							table.remove(selectedTools, isSelected)
							checkmark.Visible = false
							checkbox.BackgroundColor3 = COLORS.Button
						else
							table.insert(selectedTools, tool.ToolId)
							checkmark.Visible = true
							checkbox.BackgroundColor3 = COLORS.Success
						end
					end)
				end
				
				-- ✅ EXTRA TOOLS: Items not in ShopConfig (Event items, special tools)
				local extraTools = {
					{ToolId = "KudaLumping", Title = "🐴 Kuda Lumping"},
					{ToolId = "FlyingSpeed1", Title = "✈️ Flying Speed 1"},
					{ToolId = "FlyingSpeed2", Title = "✈️ Flying Speed 2"},
					{ToolId = "FlyingSpeed3", Title = "✈️ Flying Speed 3"},
					{ToolId = "FlyingSpeed4", Title = "✈️ Flying Speed 4"},
					{ToolId = "FlyingSpeed5", Title = "✈️ Flying Speed 5"},
					{ToolId = "FlyingSpeed6", Title = "✈️ Flying Speed 6"},
					{ToolId = "FlyingSpeed7", Title = "✈️ Flying Speed 7"},
					{ToolId = "FlyingSpeed8", Title = "✈️ Flying Speed 8"},
				}
				
				-- Separator label for extra tools
				local extraToolsLabel = Instance.new("TextLabel")
				extraToolsLabel.Size = UDim2.new(1, 0, 0, 25)
				extraToolsLabel.BackgroundTransparency = 1
				extraToolsLabel.Font = Enum.Font.GothamBold
				extraToolsLabel.Text = "── Event Items ──"
				extraToolsLabel.TextColor3 = COLORS.TextSecondary
				extraToolsLabel.TextSize = 11
				extraToolsLabel.Parent = toolContent
				
				for _, tool in ipairs(extraTools) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 40)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = toolContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0, 30, 0, 30)
					checkbox.Position = UDim2.new(0, 5, 0, 5)
					checkbox.BackgroundColor3 = COLORS.Button
					checkbox.BorderSizePixel = 0
					checkbox.Text = ""
					checkbox.AutoButtonColor = false
					checkbox.Parent = frame

					createCorner(6).Parent = checkbox

					local checkmark = Instance.new("TextLabel")
					checkmark.Size = UDim2.new(1, 0, 1, 0)
					checkmark.BackgroundTransparency = 1
					checkmark.Font = Enum.Font.GothamBold
					checkmark.Text = "✓"
					checkmark.TextColor3 = COLORS.Success
					checkmark.TextSize = 18
					checkmark.Visible = false
					checkmark.Parent = checkbox

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -45, 1, 0)
					label.Position = UDim2.new(0, 40, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = tool.Title
					label.TextColor3 = COLORS.Text
					label.TextSize = 13
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame

					checkbox.MouseButton1Click:Connect(function()
						local isSelected = table.find(selectedTools, tool.ToolId)
						if isSelected then
							table.remove(selectedTools, isSelected)
							checkmark.Visible = false
							checkbox.BackgroundColor3 = COLORS.Button
						else
							table.insert(selectedTools, tool.ToolId)
							checkmark.Visible = true
							checkbox.BackgroundColor3 = COLORS.Success
						end
					end)
				end
				
				-- ✅ TAMBAHKAN: Create Money Options
				for _, pack in ipairs(ShopConfig.MoneyPacks) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 50)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = moneyContent

					createCorner(6).Parent = frame

					local titleLabel = Instance.new("TextLabel")
					titleLabel.Size = UDim2.new(0.5, -10, 0, 20)
					titleLabel.Position = UDim2.new(0, 10, 0, 8)
					titleLabel.BackgroundTransparency = 1
					titleLabel.Font = Enum.Font.GothamBold
					titleLabel.Text = pack.Title
					titleLabel.TextColor3 = COLORS.Text
					titleLabel.TextSize = 13
					titleLabel.TextXAlignment = Enum.TextXAlignment.Left
					titleLabel.Parent = frame

					local amountLabel = Instance.new("TextLabel")
					amountLabel.Size = UDim2.new(0.5, -10, 0, 18)
					amountLabel.Position = UDim2.new(0, 10, 0, 28)
					amountLabel.BackgroundTransparency = 1
					amountLabel.Font = Enum.Font.Gotham
					amountLabel.Text = "$" .. tostring(pack.MoneyReward)
					amountLabel.TextColor3 = COLORS.Success
					amountLabel.TextSize = 12
					amountLabel.TextXAlignment = Enum.TextXAlignment.Left
					amountLabel.Parent = frame

					local selectBtn = Instance.new("TextButton")
					selectBtn.Size = UDim2.new(0, 80, 0, 35)
					selectBtn.Position = UDim2.new(1, -90, 0.5, -17)
					selectBtn.BackgroundColor3 = COLORS.Accent
					selectBtn.BorderSizePixel = 0
					selectBtn.Font = Enum.Font.GothamBold
					selectBtn.Text = "Select"
					selectBtn.TextColor3 = COLORS.Text
					selectBtn.TextSize = 12
					selectBtn.AutoButtonColor = false
					selectBtn.Parent = frame

					createCorner(6).Parent = selectBtn

					selectBtn.MouseButton1Click:Connect(function()
						selectedMoneyAmount = pack.MoneyReward

						-- Reset all buttons
						for _, child in ipairs(moneyContent:GetChildren()) do
							if child:IsA("Frame") then
								local btn = child:FindFirstChildWhichIsA("TextButton")
								if btn then
									btn.BackgroundColor3 = COLORS.Accent
									btn.Text = "Select"
								end
							end
						end

						-- Highlight selected
						selectBtn.BackgroundColor3 = COLORS.Success
						selectBtn.Text = "Selected"
					end)
				end

				-- Tab Switching
				auraTab.MouseButton1Click:Connect(function()
					auraTab.BackgroundColor3 = COLORS.Accent
					toolTab.BackgroundColor3 = COLORS.Button
					moneyTab.BackgroundColor3 = COLORS.Button
					auraContent.Visible = true
					toolContent.Visible = false
					moneyContent.Visible = false
				end)

				toolTab.MouseButton1Click:Connect(function()
					toolTab.BackgroundColor3 = COLORS.Accent
					auraTab.BackgroundColor3 = COLORS.Button
					moneyTab.BackgroundColor3 = COLORS.Button
					toolContent.Visible = true
					auraContent.Visible = false
					moneyContent.Visible = false
				end)
				
				moneyTab.MouseButton1Click:Connect(function()
					moneyTab.BackgroundColor3 = COLORS.Accent
					auraTab.BackgroundColor3 = COLORS.Button
					toolTab.BackgroundColor3 = COLORS.Button
					moneyContent.Visible = true
					auraContent.Visible = false
					toolContent.Visible = false
				end)
				

			-- Give Button (FIXED POSITION for 550px popup)
				local giveBtn = createButton("Give Selected Items", COLORS.Success, COLORS.Success)
				giveBtn.Size = UDim2.new(1, -40, 0, 50)
				giveBtn.Position = UDim2.new(0, 20, 0, 485) -- Fixed Y position
				giveBtn.Parent = giveItemsPopup

				giveBtn.MouseButton1Click:Connect(function()
					if #selectedAuras > 0 or #selectedTools > 0 or selectedMoneyAmount > 0 then
						local giveItemsEvent = remoteFolder:FindFirstChild("GiveItems")
						if giveItemsEvent then
							giveItemsEvent:FireServer(targetPlayer.UserId, selectedAuras, selectedTools, selectedMoneyAmount)
							print("✅ [ADMIN] Items given to " .. targetPlayer.Name)
						end
					end
					giveItemsPopup:Destroy()
					mainContainer.Visible = true -- ✅ Show main panel after giving items
				end)
				
				-- Note: Popup is already draggable via popup.Draggable = true (not popup header)
			end)

			-- Show panel with animation
			playerDetailPanel.Size = UDim2.new(0, 0, 0, 0)
			playerDetailPanel.Visible = true
			tweenSize(playerDetailPanel, UDim2.new(0.208, 0, 0.7, 0), 0.3)

	end)

	return card
end




-- Update player list
-- ✅ PERFORMANCE FIX: Store card references for incremental updates
local playerCards = {}  -- [userId] = card UI element

local function removePlayerCard(targetPlayer)
	local userId = targetPlayer.UserId
	if playerCards[userId] then
		playerCards[userId]:Destroy()
		playerCards[userId] = nil
	end
end

local function addPlayerCard(targetPlayer)
	if playerCards[targetPlayer.UserId] then return end  -- Already exists
	createPlayerCard(targetPlayer)
	-- Note: createPlayerCard adds to playersScroll, we track by userId separately
end

local function updatePlayerList()
	playerCardIndex = 0 -- Reset counter for consistent accent colors
	
	for _, card in ipairs(playersScroll:GetChildren()) do
		if card:IsA("TextButton") then
			card:Destroy()
		end
	end
	playerCards = {}  -- Clear tracking

	-- Add all players including the local player (admin)
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		createPlayerCard(targetPlayer)
		-- Store reference by UserId for incremental updates
		local cards = playersScroll:GetChildren()
		for _, card in ipairs(cards) do
			if card:IsA("TextButton") then
				-- The last added card is for this player
				playerCards[targetPlayer.UserId] = card
			end
		end
	end
end

-- ✅ PERFORMANCE FIX: Incremental player list updates instead of full rebuild
-- Only add the new player's card, don't recreate everything
Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(0.5)
	if not playerCards[newPlayer.UserId] then
		playerCardIndex = playerCardIndex + 1
		createPlayerCard(newPlayer)
		playerCards[newPlayer.UserId] = playersScroll:GetChildren()[#playersScroll:GetChildren()]
	end
end)

-- Only remove the leaving player's card
Players.PlayerRemoving:Connect(function(leavingPlayer)
	task.wait(0.1)
	if playerCards[leavingPlayer.UserId] then
		playerCards[leavingPlayer.UserId]:Destroy()
		playerCards[leavingPlayer.UserId] = nil
	end
end)

-- Initial player list (only once on load)
updatePlayerList()

-- ✅ SEARCH FUNCTIONALITY: Filter player cards when typing
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(searchBox.Text)
	currentSearchQuery = query
	
	for _, card in ipairs(playersScroll:GetChildren()) do
		if card:IsA("TextButton") then
			local nameLabel = card:FindFirstChild("TextLabel")
			if nameLabel then
				local playerName = string.lower(nameLabel.Text or "")
				if query == "" or string.find(playerName, query, 1, true) then
					card.Visible = true
				else
					card.Visible = false
				end
			end
		end
	end
end)

-- Make panels draggable
makeDraggable(mainPanel, header)
makeDraggable(playerDetailPanel, detailHeader)

-- Set default tab
notifTabBtn.BackgroundColor3 = COLORS.Accent
notifTabBtn.TextColor3 = COLORS.Text
notifTab.Visible = true
currentTab = notifTab
-- ✅✅✅ EVENT MANAGER TAB (FULLY RESPONSIVE)
local eventsTab, eventsTabBtn = createTab("Events", 3)

local eventsScroll = Instance.new("ScrollingFrame")
eventsScroll.Size = UDim2.new(1, 0, 1, 0)
eventsScroll.BackgroundTransparency = 1
eventsScroll.BorderSizePixel = 0
eventsScroll.ScrollBarThickness = 4
eventsScroll.ScrollBarImageColor3 = COLORS.Border
eventsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
eventsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
eventsScroll.Parent = eventsTab

local eventsLayout = Instance.new("UIListLayout")
eventsLayout.Padding = UDim.new(0, 10)
eventsLayout.SortOrder = Enum.SortOrder.LayoutOrder
eventsLayout.Parent = eventsScroll

-- Title
local eventsTitle = Instance.new("TextLabel")
eventsTitle.Size = UDim2.new(1, 0, 0, 30)
eventsTitle.BackgroundTransparency = 1
eventsTitle.Font = Enum.Font.GothamBold
eventsTitle.Text = "🎉 Global Event Manager"
eventsTitle.TextColor3 = COLORS.Text
eventsTitle.TextSize = 18
eventsTitle.TextScaled = false
eventsTitle.TextXAlignment = Enum.TextXAlignment.Left
eventsTitle.LayoutOrder = 1
eventsTitle.Parent = eventsScroll

local eventsDesc = Instance.new("TextLabel")
eventsDesc.Size = UDim2.new(1, 0, 0, 40)
eventsDesc.BackgroundTransparency = 1
eventsDesc.Font = Enum.Font.Gotham
eventsDesc.Text = "Activate events to boost summit rewards across ALL servers"
eventsDesc.TextColor3 = COLORS.TextSecondary
eventsDesc.TextSize = 13
eventsDesc.TextWrapped = true
eventsDesc.TextXAlignment = Enum.TextXAlignment.Left
eventsDesc.LayoutOrder = 2
eventsDesc.Parent = eventsScroll

-- Load EventConfig
local EventConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EventConfig"))

-- Get active event from server
local eventRemotes = ReplicatedStorage:WaitForChild("EventRemotes")
local getActiveEventFunc = eventRemotes:WaitForChild("GetActiveEvent")
local setEventRemote = eventRemotes:WaitForChild("SetEvent")
local eventChangedRemote = eventRemotes:WaitForChild("EventChanged")

local currentActiveEventId = nil

-- Function to request current active event
task.spawn(function()
	local success, activeEvent = pcall(function()
		return getActiveEventFunc:InvokeServer()
	end)

	if success and activeEvent then
		currentActiveEventId = activeEvent.Id
		print("[ADMIN CLIENT] Current active event:", activeEvent.Name)
	end
end)

-- ✅ RESPONSIVE EVENT CARDS
for i, event in ipairs(EventConfig.AvailableEvents) do
	local eventCard = Instance.new("Frame")
	eventCard.Size = UDim2.new(1, 0, 0, 120)  -- Fixed height OK untuk list
	eventCard.BackgroundColor3 = COLORS.Panel
	eventCard.BorderSizePixel = 0
	eventCard.LayoutOrder = 2 + i
	eventCard.Parent = eventsScroll

	createCorner(8).Parent = eventCard

	-- ✅ Icon (LEFT - SCALE)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.1, 0, 0, 50)  -- 10% width, 50px height
	iconLabel.Position = UDim2.new(0.02, 0, 0.5, -25)  -- 2% dari kiri, centered vertically
	iconLabel.AnchorPoint = Vector2.new(0, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = event.Icon
	iconLabel.TextSize = 32
	iconLabel.TextScaled = false
	iconLabel.Parent = eventCard

	-- ✅ Event Name (SCALE)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0, 30)  -- 50% width
	nameLabel.Position = UDim2.new(0.13, 0, 0.15, 0)  -- 13% from left, 15% from top
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = event.Name
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 16
	nameLabel.TextScaled = false
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = eventCard

	-- ✅ Event Description (SCALE)
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.5, 0, 0, 25)  -- 50% width
	descLabel.Position = UDim2.new(0.13, 0, 0.45, 0)  -- 13% from left, 45% from top
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = event.Description
	descLabel.TextColor3 = COLORS.TextSecondary
	descLabel.TextSize = 12
	descLabel.TextScaled = false
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = eventCard

	-- ✅ Multiplier Badge (SCALE)
	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(0.12, 0, 0, 30)  -- 12% width, 30px height
	badgeLabel.Position = UDim2.new(0.13, 0, 0.7, 0)  -- 13% from left, 70% from top
	badgeLabel.BackgroundColor3 = event.Color
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.Text = "x" .. event.Multiplier
	badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeLabel.TextSize = 14
	badgeLabel.TextScaled = false
	badgeLabel.Parent = eventCard

	createCorner(6).Parent = badgeLabel

	-- ✅ Toggle Button (SCALE - RESPONSIVE!)
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0.28, 0, 0.42, 0)  -- 28% width, 42% height
	toggleBtn.Position = UDim2.new(0.7, 0, 0.29, 0)  -- 70% from left, 29% from top (centered)
	toggleBtn.BackgroundColor3 = COLORS.Button
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Text = "Activate"
	toggleBtn.TextColor3 = COLORS.Text
	toggleBtn.TextSize = 14
	toggleBtn.TextScaled = true  -- ✅ Auto-scale text
	toggleBtn.AutoButtonColor = false
	toggleBtn.Parent = eventCard

	createCorner(8).Parent = toggleBtn

	-- ✅ TextScaled constraint untuk button
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 14
	textSizeConstraint.MinTextSize = 10
	textSizeConstraint.Parent = toggleBtn

	-- Update button state based on active event
	local function updateButtonState()
		if currentActiveEventId == event.Id then
			toggleBtn.BackgroundColor3 = COLORS.Success
			toggleBtn.Text = "Active ✓"
		else
			toggleBtn.BackgroundColor3 = COLORS.Button
			toggleBtn.Text = "Activate"
		end
	end

	updateButtonState()

	-- Toggle Button Click
	toggleBtn.MouseButton1Click:Connect(function()
		if currentActiveEventId == event.Id then
			-- Deactivate current event
			showConfirmation(
				"Deactivate Event?",
				"Deactivate " .. event.Name .. "?\nSummit rewards will return to normal.",
				function()
					setEventRemote:FireServer("deactivate")
					currentActiveEventId = nil

					-- Update all buttons
					for _, card in pairs(eventsScroll:GetChildren()) do
						if card:IsA("Frame") and card ~= eventsTitle and card ~= eventsDesc then
							local btn = card:FindFirstChildWhichIsA("TextButton")
							if btn then
								btn.BackgroundColor3 = COLORS.Button
								btn.Text = "Activate"
							end
						end
					end
				end
			)
		else
			-- Activate this event
			showConfirmation(
				"Activate Event?",
				string.format("Activate %s?\nAll players on ALL servers will get x%d Summit rewards!", event.Name, event.Multiplier),
				function()
					setEventRemote:FireServer("activate", event.Id)
					currentActiveEventId = event.Id

					-- Update all buttons
					for _, card in pairs(eventsScroll:GetChildren()) do
						if card:IsA("Frame") and card ~= eventsTitle and card ~= eventsDesc then
							local btn = card:FindFirstChildWhichIsA("TextButton")
							if btn then
								btn.BackgroundColor3 = COLORS.Button
								btn.Text = "Activate"
							end
						end
					end

					updateButtonState()
				end
			)
		end
	end)

	-- Hover effects
	toggleBtn.MouseEnter:Connect(function()
		if currentActiveEventId ~= event.Id then
			toggleBtn.BackgroundColor3 = COLORS.ButtonHover
		end
	end)

	toggleBtn.MouseLeave:Connect(function()
		updateButtonState()
	end)
end

-- Listen for event changes from server
eventChangedRemote.OnClientEvent:Connect(function(newActiveEvent)
	if newActiveEvent then
		currentActiveEventId = newActiveEvent.Id
		print("[ADMIN CLIENT] Event changed to:", newActiveEvent.Name)
	else
		currentActiveEventId = nil
		print("[ADMIN CLIENT] Event deactivated")
	end

	-- Update all buttons
	for _, card in pairs(eventsScroll:GetChildren()) do
		if card:IsA("Frame") then
			local toggleBtn = card:FindFirstChildWhichIsA("TextButton")
			if toggleBtn then
				-- Check if this card matches active event
				for _, ev in ipairs(EventConfig.AvailableEvents) do
					local nameLabel = card:FindFirstChild("TextLabel")
					if nameLabel and nameLabel.Text == ev.Name then
						if currentActiveEventId == ev.Id then
							toggleBtn.BackgroundColor3 = COLORS.Success
							toggleBtn.Text = "Active ✓"
						else
							toggleBtn.BackgroundColor3 = COLORS.Button
							toggleBtn.Text = "Activate"
						end
						break
					end
				end
			end
		end
	end
end)

-- ✅✅✅ AKHIR EVENT MANAGER TAB



-- Leaderboard Tab
local leaderboardTab, leaderboardTabBtn = createTab("Leaderboard", 4)

local leaderboardScroll = Instance.new("ScrollingFrame")
leaderboardScroll.Size = UDim2.new(1, 0, 1, 0)
leaderboardScroll.BackgroundTransparency = 1
leaderboardScroll.BorderSizePixel = 0
leaderboardScroll.ScrollBarThickness = 4
leaderboardScroll.ScrollBarImageColor3 = COLORS.Border
leaderboardScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
leaderboardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
leaderboardScroll.Parent = leaderboardTab

local leaderboardLayout = Instance.new("UIListLayout")
leaderboardLayout.Padding = UDim.new(0, 10)
leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
leaderboardLayout.Parent = leaderboardScroll

-- Search Input
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0, 50)
searchFrame.BackgroundTransparency = 1
searchFrame.LayoutOrder = 1
searchFrame.Parent = leaderboardScroll

local searchLabel = Instance.new("TextLabel")
searchLabel.Size = UDim2.new(1, 0, 0, 20)
searchLabel.BackgroundTransparency = 1
searchLabel.Font = Enum.Font.GothamBold
searchLabel.Text = "Search Player(s)"
searchLabel.TextColor3 = COLORS.Text
searchLabel.TextSize = 14
searchLabel.TextXAlignment = Enum.TextXAlignment.Left
searchLabel.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.82, 0, 0, 35)
searchBox.Position = UDim2.new(0, 0, 0, 25)
searchBox.BackgroundColor3 = COLORS.Panel
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Enter username(s), separate with comma (max 5)"
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.TextSize = 13
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame

createCorner(6).Parent = searchBox
createPadding(10).Parent = searchBox

local searchButton = Instance.new("TextButton")
searchButton.Size = UDim2.new(0.15, 0, 0, 35)
searchButton.Position = UDim2.new(0.84, 0, 0, 25)
searchButton.BackgroundColor3 = COLORS.Accent
searchButton.BorderSizePixel = 0
searchButton.Font = Enum.Font.GothamBold
searchButton.Text = "🔍"
searchButton.TextColor3 = COLORS.Text
searchButton.TextSize = 18
searchButton.AutoButtonColor = false
searchButton.Parent = searchFrame

createCorner(6).Parent = searchButton

-- Search Results Container
local resultsContainer = Instance.new("Frame")
resultsContainer.Size = UDim2.new(1, 0, 0, 0)
resultsContainer.BackgroundTransparency = 1
resultsContainer.LayoutOrder = 2
resultsContainer.Parent = leaderboardScroll

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.Padding = UDim.new(0, 8)
resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultsLayout.Parent = resultsContainer

resultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	resultsContainer.Size = UDim2.new(1, 0, 0, resultsLayout.AbsoluteContentSize.Y)
end)

-- Delete All Button (Hidden by default)
local deleteAllFrame = Instance.new("Frame")
deleteAllFrame.Size = UDim2.new(1, 0, 0, 50)
deleteAllFrame.BackgroundTransparency = 1
deleteAllFrame.LayoutOrder = 3
deleteAllFrame.Visible = false
deleteAllFrame.Parent = leaderboardScroll

local deleteAllButton = createButton("🗑️ Delete All Selected Players", COLORS.Danger, COLORS.DangerHover)
deleteAllButton.Size = UDim2.new(1, 0, 1, 0)
deleteAllButton.Parent = deleteAllFrame

-- ==================== LEADERBOARD VIEWER ====================
-- Sub-category tabs for viewing leaderboards
local viewerSeparator = Instance.new("Frame")
viewerSeparator.Size = UDim2.new(1, 0, 0, 1)
viewerSeparator.BackgroundColor3 = COLORS.Border
viewerSeparator.LayoutOrder = 4
viewerSeparator.Parent = leaderboardScroll

local viewerTitleFrame = Instance.new("Frame")
viewerTitleFrame.Size = UDim2.new(1, 0, 0, 30)
viewerTitleFrame.BackgroundTransparency = 1
viewerTitleFrame.LayoutOrder = 5
viewerTitleFrame.Parent = leaderboardScroll

local viewerTitle = Instance.new("TextLabel")
viewerTitle.Size = UDim2.new(1, 0, 1, 0)
viewerTitle.BackgroundTransparency = 1
viewerTitle.Font = Enum.Font.GothamBold
viewerTitle.Text = "📊 Leaderboard Viewer"
viewerTitle.TextColor3 = COLORS.Text
viewerTitle.TextSize = 14
viewerTitle.TextXAlignment = Enum.TextXAlignment.Left
viewerTitle.Parent = viewerTitleFrame

-- Sub-category buttons container
local subCategoryFrame = Instance.new("Frame")
subCategoryFrame.Size = UDim2.new(1, 0, 0, 35)
subCategoryFrame.BackgroundTransparency = 1
subCategoryFrame.LayoutOrder = 6
subCategoryFrame.Parent = leaderboardScroll

local subCategoryLayout = Instance.new("UIListLayout")
subCategoryLayout.FillDirection = Enum.FillDirection.Horizontal
subCategoryLayout.Padding = UDim.new(0, 6)
subCategoryLayout.Parent = subCategoryFrame

local currentLeaderboardType = "summit"
local leaderboardSubButtons = {}

local function createSubCategoryButton(text, leaderboardType, icon)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.24, -5, 1, 0)
	btn.BackgroundColor3 = COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = icon .. " " .. text
	btn.TextColor3 = COLORS.TextSecondary
	btn.TextSize = 11
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = subCategoryFrame
	
	createCorner(6).Parent = btn
	
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 12
	textConstraint.MinTextSize = 8
	textConstraint.Parent = btn
	
	leaderboardSubButtons[leaderboardType] = btn
	return btn, leaderboardType
end

local summitBtn = createSubCategoryButton("Summit", "summit", "🏔️")
local speedrunBtn = createSubCategoryButton("Speedrun", "speedrun", "⏱️")
local donateBtn = createSubCategoryButton("Donate", "donate", "💎")
local playtimeBtn = createSubCategoryButton("Playtime", "playtime", "⌚")

-- Leaderboard viewer container
local viewerContainer = Instance.new("Frame")
viewerContainer.Size = UDim2.new(1, 0, 0, 300)
viewerContainer.BackgroundColor3 = COLORS.Panel
viewerContainer.BorderSizePixel = 0
viewerContainer.LayoutOrder = 7
viewerContainer.Parent = leaderboardScroll

createCorner(8).Parent = viewerContainer

local viewerScroll = Instance.new("ScrollingFrame")
viewerScroll.Size = UDim2.new(1, -10, 1, -10)
viewerScroll.Position = UDim2.new(0, 5, 0, 5)
viewerScroll.BackgroundTransparency = 1
viewerScroll.BorderSizePixel = 0
viewerScroll.ScrollBarThickness = 4
viewerScroll.ScrollBarImageColor3 = COLORS.Border
viewerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
viewerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
viewerScroll.Parent = viewerContainer

local viewerLayout = Instance.new("UIListLayout")
viewerLayout.Padding = UDim.new(0, 4)
viewerLayout.SortOrder = Enum.SortOrder.LayoutOrder
viewerLayout.Parent = viewerScroll

-- Loading indicator
local loadingLabel = Instance.new("TextLabel")
loadingLabel.Size = UDim2.new(1, 0, 0, 40)
loadingLabel.BackgroundTransparency = 1
loadingLabel.Font = Enum.Font.GothamMedium
loadingLabel.Text = "Click a category to load leaderboard..."
loadingLabel.TextColor3 = COLORS.TextSecondary
loadingLabel.TextSize = 12
loadingLabel.Parent = viewerScroll

-- Function to create leaderboard entry row
local function createLeaderboardRow(data, leaderboardType)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 35)
	row.BackgroundColor3 = COLORS.Button
	row.BorderSizePixel = 0
	row.LayoutOrder = data.Rank
	row.Parent = viewerScroll
	
	createCorner(6).Parent = row
	
	-- Rank
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0.08, 0, 1, 0)
	rankLabel.Position = UDim2.new(0.02, 0, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.Text = "#" .. data.Rank
	rankLabel.TextColor3 = data.Rank <= 3 and COLORS.Accent or COLORS.Text
	rankLabel.TextSize = 12
	rankLabel.TextScaled = true
	rankLabel.Parent = row
	
	local rankConstraint = Instance.new("UITextSizeConstraint")
	rankConstraint.MaxTextSize = 14
	rankConstraint.MinTextSize = 10
	rankConstraint.Parent = rankLabel
	
	-- Username
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.1, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = data.Username
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 12
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	
	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 13
	nameConstraint.MinTextSize = 9
	nameConstraint.Parent = nameLabel
	
	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.25, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = data.FormattedValue
	valueLabel.TextColor3 = COLORS.Accent
	valueLabel.TextSize = 12
	valueLabel.TextScaled = true
	valueLabel.Parent = row
	
	local valueConstraint = Instance.new("UITextSizeConstraint")
	valueConstraint.MaxTextSize = 13
	valueConstraint.MinTextSize = 9
	valueConstraint.Parent = valueLabel
	
	-- Delete button
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
	deleteBtn.Position = UDim2.new(0.82, 0, 0.15, 0)
	deleteBtn.BackgroundColor3 = COLORS.Danger
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.Text = "🗑️"
	deleteBtn.TextColor3 = COLORS.Text
	deleteBtn.TextSize = 14
	deleteBtn.AutoButtonColor = false
	deleteBtn.Parent = row
	
	createCorner(4).Parent = deleteBtn
	
	deleteBtn.MouseButton1Click:Connect(function()
		local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
		if deleteLeaderboardEvent then
			deleteLeaderboardEvent:FireServer(data.UserId, leaderboardType)
			row:Destroy()
			
			game.StarterGui:SetCore("SendNotification", {
				Title = "Deleted",
				Text = string.format("Deleted %s from %s leaderboard", data.Username, leaderboardType),
				Duration = 3,
			})
		end
	end)
	
	-- Hover effects
	deleteBtn.MouseEnter:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.DangerHover or Color3.fromRGB(255, 80, 80)}):Play()
	end)
	deleteBtn.MouseLeave:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Danger}):Play()
	end)
	
	return row
end

-- Function to load leaderboard data
local function loadLeaderboard(leaderboardType)
	-- Clear existing entries
	for _, child in ipairs(viewerScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	loadingLabel.Text = "⏳ Loading " .. leaderboardType .. " leaderboard..."
	loadingLabel.Visible = true
	
	-- Update button states
	for type, btn in pairs(leaderboardSubButtons) do
		if type == leaderboardType then
			btn.BackgroundColor3 = COLORS.Accent
			btn.TextColor3 = COLORS.Text
		else
			btn.BackgroundColor3 = COLORS.Button
			btn.TextColor3 = COLORS.TextSecondary
		end
	end
	
	currentLeaderboardType = leaderboardType
	
	-- Fetch data from server
	local getLeaderboardFunc = remoteFolder:FindFirstChild("GetLeaderboardData")
	if not getLeaderboardFunc then
		loadingLabel.Text = "❌ Leaderboard function not available!"
		return
	end
	
	local success, result = pcall(function()
		return getLeaderboardFunc:InvokeServer(leaderboardType, 50)
	end)
	
	if success and result and result.success then
		loadingLabel.Visible = false
		
		if #result.data == 0 then
			loadingLabel.Text = "📭 No entries found in " .. leaderboardType .. " leaderboard"
			loadingLabel.Visible = true
			return
		end
		
		for _, entry in ipairs(result.data) do
			createLeaderboardRow(entry, leaderboardType)
		end
	else
		loadingLabel.Text = "❌ Failed to load leaderboard data"
		loadingLabel.Visible = true
	end
end

-- Connect sub-category buttons
for leaderboardType, btn in pairs(leaderboardSubButtons) do
	btn.MouseButton1Click:Connect(function()
		loadLeaderboard(leaderboardType)
	end)
	
	-- Hover effects
	btn.MouseEnter:Connect(function()
		if currentLeaderboardType ~= leaderboardType then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.ButtonHover or COLORS.Border}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentLeaderboardType ~= leaderboardType then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
		end
	end)
end

-- ==================== END LEADERBOARD VIEWER ====================

-- Function to create player result card
local searchResults = {} -- Store search results

local function createLeaderboardCard(data)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 180)
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.Parent = resultsContainer

	createCorner(8).Parent = card

	-- Avatar
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 60, 0, 60)
	avatar.Position = UDim2.new(0, 10, 0, 10)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. data.UserId .. "&w=150&h=150"
	avatar.Parent = card

	createCorner(30).Parent = avatar

	-- Username
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -85, 0, 25)
	nameLabel.Position = UDim2.new(0, 75, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = data.Username
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- User ID
	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(1, -85, 0, 20)
	idLabel.Position = UDim2.new(0, 75, 0, 35)
	idLabel.BackgroundTransparency = 1
	idLabel.Font = Enum.Font.Gotham
	idLabel.Text = "ID: " .. data.UserId
	idLabel.TextColor3 = COLORS.TextSecondary
	idLabel.TextSize = 12
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Parent = card

	-- Stats Display
	local statsY = 75
	local stats = {
		{icon = "🏔️", label = "Summit", value = tostring(data.Summit)},
		{icon = "⏱️", label = "Speedrun", value = data.Speedrun},
		{icon = "⌚", label = "Playtime", value = string.format("%dh %dm", math.floor(data.Playtime / 3600), math.floor((data.Playtime % 3600) / 60))},
		{icon = "💎", label = "Donate", value = "R$" .. tostring(data.Donate)}
	}

	for i, stat in ipairs(stats) do
		local statFrame = Instance.new("Frame")
		statFrame.Size = UDim2.new(0.48, 0, 0, 20)
		statFrame.Position = UDim2.new((i - 1) % 2 == 0 and 0.02 or 0.5, 0, 0, statsY + math.floor((i - 1) / 2) * 25)
		statFrame.BackgroundTransparency = 1
		statFrame.Parent = card

		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(1, 0, 1, 0)
		statLabel.BackgroundTransparency = 1
		statLabel.Font = Enum.Font.Gotham
		statLabel.Text = stat.icon .. " " .. stat.label .. ": " .. stat.value
		statLabel.TextColor3 = COLORS.TextSecondary
		statLabel.TextSize = 12
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = statFrame
	end

	-- Delete Button
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0.96, 0, 0, 35)
	deleteBtn.Position = UDim2.new(0.02, 0, 1, -45)
	deleteBtn.BackgroundColor3 = COLORS.Danger
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.Text = "🗑️ Delete Data"
	deleteBtn.TextColor3 = COLORS.Text
	deleteBtn.TextSize = 13
	deleteBtn.AutoButtonColor = false
	deleteBtn.Parent = card

	createCorner(6).Parent = deleteBtn

	deleteBtn.MouseEnter:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.DangerHover}):Play()
	end)

	deleteBtn.MouseLeave:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Danger}):Play()
	end)

	deleteBtn.MouseButton1Click:Connect(function()
		-- Show delete options popup
		local deletePopup = Instance.new("Frame")
		deletePopup.Size = UDim2.new(0, 320, 0, 280)
		deletePopup.Position = UDim2.new(0.5, 0, 0.5, 0)
		deletePopup.AnchorPoint = Vector2.new(0.5, 0.5)
		deletePopup.BackgroundColor3 = COLORS.Background
		deletePopup.BorderSizePixel = 0
		deletePopup.ZIndex = 200
		deletePopup.Parent = screenGui

		createCorner(12).Parent = deletePopup
		createStroke(COLORS.Border, 2).Parent = deletePopup

		-- Header
		local popupHeader = Instance.new("Frame")
		popupHeader.Size = UDim2.new(1, 0, 0, 50)
		popupHeader.BackgroundColor3 = COLORS.Header
		popupHeader.BorderSizePixel = 0
		popupHeader.Parent = deletePopup

		createCorner(12).Parent = popupHeader

		local headerBottom = Instance.new("Frame")
		headerBottom.Size = UDim2.new(1, 0, 0, 15)
		headerBottom.Position = UDim2.new(0, 0, 1, -15)
		headerBottom.BackgroundColor3 = COLORS.Header
		headerBottom.BorderSizePixel = 0
		headerBottom.Parent = popupHeader

		local popupTitle = Instance.new("TextLabel")
		popupTitle.Size = UDim2.new(1, -50, 1, 0)
		popupTitle.Position = UDim2.new(0, 15, 0, 0)
		popupTitle.BackgroundTransparency = 1
		popupTitle.Font = Enum.Font.GothamBold
		popupTitle.Text = "Delete " .. data.Username .. "'s Data"
		popupTitle.TextColor3 = COLORS.Text
		popupTitle.TextSize = 14
		popupTitle.TextXAlignment = Enum.TextXAlignment.Left
		popupTitle.Parent = popupHeader

		local closePopupBtn = Instance.new("TextButton")
		closePopupBtn.Size = UDim2.new(0, 30, 0, 30)
		closePopupBtn.Position = UDim2.new(1, -40, 0, 10)
		closePopupBtn.BackgroundColor3 = COLORS.Button
		closePopupBtn.BorderSizePixel = 0
		closePopupBtn.Text = "✕"
		closePopupBtn.Font = Enum.Font.GothamBold
		closePopupBtn.TextSize = 16
		closePopupBtn.TextColor3 = COLORS.Text
		closePopupBtn.Parent = popupHeader

		createCorner(6).Parent = closePopupBtn

		closePopupBtn.MouseButton1Click:Connect(function()
			deletePopup:Destroy()
		end)

		-- Delete options
		local yPos = 65
		local deleteOptions = {
			{text = "Delete Summit Data", type = "summit"},
			{text = "Delete Speedrun Data", type = "speedrun"},
			{text = "Delete Playtime Data", type = "playtime"},
			{text = "Delete Donation Data", type = "donate"},
			{text = "DELETE ALL DATA", type = "all", isAll = true}
		}

		for _, option in ipairs(deleteOptions) do
			local optionBtn = Instance.new("TextButton")
			optionBtn.Size = UDim2.new(1, -30, 0, 38)
			optionBtn.Position = UDim2.new(0, 15, 0, yPos)
			optionBtn.BackgroundColor3 = option.isAll and COLORS.Danger or COLORS.Button
			optionBtn.BorderSizePixel = 0
			optionBtn.Font = Enum.Font.GothamBold
			optionBtn.Text = option.text
			optionBtn.TextColor3 = COLORS.Text
			optionBtn.TextSize = 12
			optionBtn.AutoButtonColor = false
			optionBtn.Parent = deletePopup

			createCorner(6).Parent = optionBtn

			optionBtn.MouseButton1Click:Connect(function()
				-- Langsung pakai confirmDialog yang sudah ada
				confirmTitle.Text = "Confirm Delete"
				confirmMessage.Text = string.format("Are you sure you want to delete %s data from %s?", 
					option.type == "all" and "ALL" or option.type, 
					data.Username
				)
				currentConfirmCallback = function()
					local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
					if deleteLeaderboardEvent then
						deleteLeaderboardEvent:FireServer(data.UserId, option.type)
					end

					deletePopup:Destroy()
					card:Destroy()

					local hasResults = false
					for _, child in pairs(resultsContainer:GetChildren()) do
						if child:IsA("Frame") then
							hasResults = true
							break
						end
					end

					if not hasResults then
						deleteAllFrame.Visible = false
					end
				end

				confirmDialog.Size = UDim2.new(0, 0, 0, 0)
				confirmDialog.Visible = true
				tweenSize(confirmDialog, UDim2.new(0, 380, 0, 200), 0.3)
			end)


			yPos = yPos + 43
		end
	end)

	return card
end

-- Search Button Handler
searchButton.MouseButton1Click:Connect(function()
	if searchBox.Text == "" then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "Please enter at least one username!",
			Duration = 3,
		})
		return
	end

	-- Clear previous results
	for _, child in pairs(resultsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	searchResults = {}

	-- Parse usernames (split by comma)
	local usernames = {}
	for username in string.gmatch(searchBox.Text, "[^,]+") do
		local trimmed = string.match(username, "^%s*(.-)%s*$") -- Trim whitespace
		if trimmed ~= "" then
			table.insert(usernames, trimmed)
		end
	end

	if #usernames == 0 then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "No valid usernames entered!",
			Duration = 3,
		})
		return
	end

	if #usernames > 5 then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "Maximum 5 players at once!",
			Duration = 3,
		})
		return
	end

	-- Search each player
	local searchLeaderboardFunc = remoteFolder:FindFirstChild("SearchLeaderboard")
	if not searchLeaderboardFunc then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Error",
			Text = "Search function not available!",
			Duration = 3,
		})
		return
	end

	local foundCount = 0

	for _, username in ipairs(usernames) do
		local success, result = pcall(function()
			return searchLeaderboardFunc:InvokeServer(username)
		end)

		if success and result and result.success then
			createLeaderboardCard(result.data)
			table.insert(searchResults, result.data)
			foundCount = foundCount + 1
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Player Not Found",
				Text = string.format("'%s' not found in database!", username),
				Duration = 3,
			})
		end
	end

	-- Show delete all button if results found
	if foundCount > 0 then
		deleteAllFrame.Visible = true
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Complete",
			Text = string.format("Found %d player(s)!", foundCount),
			Duration = 3,
		})
	else
		deleteAllFrame.Visible = false
	end
end)

deleteAllButton.MouseButton1Click:Connect(function()
	if #searchResults == 0 then return end

	local playerNames = {}
	for _, data in ipairs(searchResults) do
		table.insert(playerNames, data.Username)
	end

	-- Langsung pakai confirmDialog
	confirmTitle.Text = "Delete All Data"
	confirmMessage.Text = string.format("Delete ALL leaderboard data from %d player(s)?\n%s", 
		#searchResults,
		table.concat(playerNames, ", ")
	)
	currentConfirmCallback = function()
		local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
		if deleteLeaderboardEvent then
			for _, data in ipairs(searchResults) do
				deleteLeaderboardEvent:FireServer(data.UserId, "all")
			end
		end

		-- Clear results
		for _, child in pairs(resultsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		searchResults = {}
		deleteAllFrame.Visible = false
		searchBox.Text = ""

		game.StarterGui:SetCore("SendNotification", {
			Title = "Success",
			Text = "All selected data deleted!",
			Duration = 3,
		})
	end

	confirmDialog.Size = UDim2.new(0, 0, 0, 0)
	confirmDialog.Visible = true
	tweenSize(confirmDialog, UDim2.new(0, 380, 0, 200), 0.3)
end)

-- ==================== LOG TAB (PRIMARY ADMIN ONLY) ====================
local logTab, logTabBtn
if hasPrimaryAccess then
	logTab, logTabBtn = createTab("Log", 5)
	
	local logScroll = Instance.new("ScrollingFrame")
	logScroll.Size = UDim2.new(1, 0, 1, 0)
	logScroll.BackgroundTransparency = 1
	logScroll.BorderSizePixel = 0
	logScroll.ScrollBarThickness = 4
	logScroll.ScrollBarImageColor3 = COLORS.Border
	logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	logScroll.Parent = logTab
	
	local logLayout = Instance.new("UIListLayout")
	logLayout.Padding = UDim.new(0, 15)
	logLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	logLayout.Parent = logScroll
	
	-- Title
	local logTitle = Instance.new("TextLabel")
	logTitle.Size = UDim2.new(1, 0, 0, 40)
	logTitle.BackgroundTransparency = 1
	logTitle.Font = Enum.Font.GothamBold
	logTitle.Text = "📝 Admin Activity Log"
	logTitle.TextColor3 = COLORS.Text
	logTitle.TextSize = 18
	logTitle.TextScaled = false
	logTitle.TextXAlignment = Enum.TextXAlignment.Center
	logTitle.LayoutOrder = 1
	logTitle.Parent = logScroll
	
	-- Description
	local logDesc = Instance.new("TextLabel")
	logDesc.Size = UDim2.new(0.9, 0, 0, 50)
	logDesc.BackgroundTransparency = 1
	logDesc.Font = Enum.Font.Gotham
	logDesc.Text = "Monitor admin actions across all servers. Track kicks, bans, freezes, title changes, summit modifications, and notifications."
	logDesc.TextColor3 = COLORS.TextSecondary
	logDesc.TextSize = 12
	logDesc.TextWrapped = true
	logDesc.TextXAlignment = Enum.TextXAlignment.Center
	logDesc.LayoutOrder = 2
	logDesc.Parent = logScroll
	
	-- Open Logs Button
	local openLogsBtn = Instance.new("TextButton")
	openLogsBtn.Size = UDim2.new(0.7, 0, 0, 60)
	openLogsBtn.BackgroundColor3 = COLORS.Accent
	openLogsBtn.BorderSizePixel = 0
	openLogsBtn.Font = Enum.Font.GothamBold
	openLogsBtn.Text = "📂 Open Admin Logs"
	openLogsBtn.TextColor3 = COLORS.Text
	openLogsBtn.TextSize = 16
	openLogsBtn.AutoButtonColor = false
	openLogsBtn.LayoutOrder = 3
	openLogsBtn.Parent = logScroll
	
	createCorner(10).Parent = openLogsBtn
	
	-- Button hover effect
	openLogsBtn.MouseEnter:Connect(function()
		TweenService:Create(openLogsBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.AccentHover}):Play()
	end)
	
	openLogsBtn.MouseLeave:Connect(function()
		TweenService:Create(openLogsBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Accent}):Play()
	end)
	
	-- Open Log UI
	openLogsBtn.MouseButton1Click:Connect(function()
		-- Wait for AdminLogClient to initialize
		if _G.AdminLogUI then
			_G.AdminLogUI:Open()
		else
			warn("[ADMIN CLIENT] AdminLogUI not initialized yet")
			StarterGui:SetCore("SendNotification", {
				Title = "Error",
				Text = "Log UI is loading, please try again.",
				Duration = 3
			})
		end
	end)
	
	-- Info cards
	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.new(0.9, 0, 0, 130)
	infoFrame.BackgroundColor3 = COLORS.Panel
	infoFrame.BorderSizePixel = 0
	infoFrame.LayoutOrder = 4
	infoFrame.Parent = logScroll
	
	createCorner(8).Parent = infoFrame
	
	local infoLayout = Instance.new("UIListLayout")
	infoLayout.Padding = UDim.new(0, 8)
	infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	infoLayout.Parent = infoFrame
	
	local infoPadding = createPadding(12)
	infoPadding.Parent = infoFrame
	
	local infoItems = {
		{"📊 All Logs", "View all admin actions with filters"},
		{"👥 Admin List", "See all admins and their activity"},
		{"🔍 Filter", "Filter by action type: kick, ban, freeze, etc."},
		{"🌐 Cross-Server", "Logs sync across all servers"}
	}
	
	for i, item in ipairs(infoItems) do
		local infoRow = Instance.new("Frame")
		infoRow.Size = UDim2.new(1, 0, 0, 22)
		infoRow.BackgroundTransparency = 1
		infoRow.LayoutOrder = i
		infoRow.Parent = infoFrame
		
		local infoIcon = Instance.new("TextLabel")
		infoIcon.Size = UDim2.new(0, 25, 1, 0)
		infoIcon.BackgroundTransparency = 1
		infoIcon.Font = Enum.Font.Gotham
		infoIcon.Text = item[1]:sub(1, 2)
		infoIcon.TextColor3 = COLORS.Text
		infoIcon.TextSize = 14
		infoIcon.TextXAlignment = Enum.TextXAlignment.Left
		infoIcon.Parent = infoRow
		
		local infoText = Instance.new("TextLabel")
		infoText.Size = UDim2.new(1, -30, 1, 0)
		infoText.Position = UDim2.new(0, 30, 0, 0)
		infoText.BackgroundTransparency = 1
		infoText.Font = Enum.Font.Gotham
		infoText.Text = item[1]:sub(3) .. " - " .. item[2]
		infoText.TextColor3 = COLORS.TextSecondary
		infoText.TextSize = 11
		infoText.TextXAlignment = Enum.TextXAlignment.Left
		infoText.TextTruncate = Enum.TextTruncate.AtEnd
		infoText.Parent = infoRow
	end
	
	print("✅ [ADMIN CLIENT] Log tab created for Primary Admin")
end

-- ==================== SECONDARY ADMIN ACCESS CONTROL ====================
-- Hide and disable restricted tabs for Secondary Admins
if not hasPrimaryAccess then
	-- Hide Notifications tab
	if notifTabBtn then
		notifTabBtn.Visible = false
		notifTabBtn.Active = false
	end
	if notifTab then
		notifTab.Visible = false
	end
	
	-- Hide Events tab
	if eventsTabBtn then
		eventsTabBtn.Visible = false
		eventsTabBtn.Active = false
	end
	if eventsTab then
		eventsTab.Visible = false
	end
	
	-- Show Players tab by default for Secondary Admin
	if playersTab and playersTabBtn then
		playersTab.Visible = true
		playersTabBtn.BackgroundColor3 = COLORS.Accent
		playersTabBtn.TextColor3 = COLORS.Text
		currentTab = playersTab
	end
	
	-- Update tab sizes (only 2 tabs: Players, Leaderboard)
	for _, tabBtn in ipairs(tabContainer:GetChildren()) do
		if tabBtn:IsA("TextButton") and tabBtn.Visible then
			tabBtn.Size = UDim2.new(0.49, 0, 1, 0) -- ~50% width each
		end
	end
	
	print("✅ [ADMIN CLIENT] Secondary Admin mode - restricted access applied")
else
	-- Show Notifications tab by default for Primary Admin
	if notifTab and notifTabBtn then
		notifTab.Visible = true
		notifTabBtn.BackgroundColor3 = COLORS.Accent
		notifTabBtn.TextColor3 = COLORS.Text
		currentTab = notifTab
	end
	
	print("✅ [ADMIN CLIENT] Primary Admin mode - full access")
end

-- Create Admin Button
local isOpen = false -- Pindahkan ke scope global

-- Forward declarations for admin panel functions
local closeAdminPanel
local openAdminPanel

-- Function to close admin panel (for PanelManager)
closeAdminPanel = function()
	if not isOpen then return end
	isOpen = false
	-- Sembunyikan konten sebelum animasi
	for _, child in ipairs(contentContainer:GetChildren()) do
		child.Visible = false
	end

	tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		mainPanel.Visible = false
		mainPanel.Size = UDim2.new(1, 0, 1, 0) -- Full size of container
		-- Kembalikan visibility tab yang aktif
		if currentTab then
			currentTab.Visible = true
		end
	end)
	PanelManager:Close("AdminPanel")
end

-- Function to open admin panel (for PanelManager)
openAdminPanel = function()
	PanelManager:Open("AdminPanel") -- This closes other panels first
	isOpen = true
	mainPanel.Size = UDim2.new(0, 0, 0, 0)
	mainPanel.Visible = true
	tweenSize(mainPanel, UDim2.new(1, 0, 1, 0), 0.3) -- Full size of container
end

-- Register with PanelManager
PanelManager:Register("AdminPanel", closeAdminPanel)

if topbarPlusLoaded and Icon then
	-- Use TopbarPlus
	print("Creating TopbarPlus icon...")
	local adminIcon = Icon.new()
	adminIcon:setLabel("Admin")
	adminIcon:setImage("rbxassetid://128692376033664")

	-- Removed setTip() since it's not available in all TopbarPlus versions

	adminIcon.selected:Connect(function()
		openAdminPanel()
	end)

	adminIcon.deselected:Connect(function()
		closeAdminPanel()
	end)

	-- Connect close button to deselect icon
	closeButton.MouseButton1Click:Connect(function()
		adminIcon:deselect()
	end)

	print("✓ TopbarPlus icon created")
else
	-- Fallback: Create custom button
	warn("Using fallback admin button")

	-- Hide default topbar to prevent conflicts
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

	local fallbackButton = Instance.new("ScreenGui")
	fallbackButton.Name = "AdminButton"
	fallbackButton.ResetOnSpawn = false
	fallbackButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fallbackButton.DisplayOrder = 999
	fallbackButton.Parent = playerGui

	local buttonFrame = Instance.new("TextButton")
	buttonFrame.Size = UDim2.new(0.063, 0, 0.037, 0)
	buttonFrame.Position = UDim2.new(0.005, 0, 0.009, 0)
	buttonFrame.BackgroundColor3 = COLORS.Panel
	buttonFrame.BorderSizePixel = 0
	buttonFrame.Font = Enum.Font.GothamBold
	buttonFrame.Text = ""
	buttonFrame.AutoButtonColor = false
	buttonFrame.Parent = fallbackButton

	createCorner(8).Parent = buttonFrame
	createStroke(COLORS.Border, 2).Parent = buttonFrame

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.Position = UDim2.new(0, 8, 0, 8)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://7733954760"
	icon.ImageColor3 = COLORS.Text
	icon.Parent = buttonFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 40, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "Admin"
	label.TextColor3 = COLORS.Text
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = buttonFrame

	buttonFrame.MouseButton1Click:Connect(function()
		if isOpen then
			closeAdminPanel()
			buttonFrame.BackgroundColor3 = COLORS.Panel
		else
			openAdminPanel()
			buttonFrame.BackgroundColor3 = COLORS.Accent
		end
	end)

	buttonFrame.MouseEnter:Connect(function()
		if not isOpen then
			TweenService:Create(buttonFrame, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
		end
	end)

	buttonFrame.MouseLeave:Connect(function()
		if not isOpen then
			TweenService:Create(buttonFrame, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
		end
	end)

	-- Close panel when close button is clicked
	closeButton.MouseButton1Click:Connect(function()
		closeAdminPanel()
		buttonFrame.BackgroundColor3 = COLORS.Panel
	end)

	print("✓ Fallback admin button created")
end

print("Admin Panel System Loaded Successfully")