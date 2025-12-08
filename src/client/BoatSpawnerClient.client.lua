--[[
	BoatSpawnerClient - Client-side boat spawner UI
	Place in StarterPlayerScripts
	
	Features:
	- Floating button to open boat spawner
	- List of available boats with stats
	- Spawn button for each boat
	- Premium modern UI design
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remote events
local BoatSpawnerFolder = ReplicatedStorage:WaitForChild("BoatSpawner", 10)
if not BoatSpawnerFolder then
	warn("⚠️ [BOAT SPAWNER CLIENT] BoatSpawner folder not found!")
	return
end

local SpawnBoatEvent = BoatSpawnerFolder:WaitForChild("SpawnBoat")
local GetBoatsEvent = BoatSpawnerFolder:WaitForChild("GetBoats")

-- ==================== UI COLORS ====================
local Colors = {
	Background = Color3.fromRGB(20, 25, 35),
	Panel = Color3.fromRGB(30, 35, 50),
	Card = Color3.fromRGB(40, 45, 65),
	CardHover = Color3.fromRGB(50, 55, 80),
	Accent = Color3.fromRGB(65, 150, 255),
	AccentHover = Color3.fromRGB(85, 170, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(180, 185, 200),
	Success = Color3.fromRGB(80, 200, 120),
	Warning = Color3.fromRGB(255, 180, 50),
}

-- ==================== CREATE UI ====================

local function createUI()
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BoatSpawnerUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Floating Button
	local floatButton = Instance.new("ImageButton")
	floatButton.Name = "SpawnerButton"
	floatButton.Size = UDim2.new(0, 60, 0, 60)
	floatButton.Position = UDim2.new(0, 20, 0.5, -100)
	floatButton.BackgroundColor3 = Colors.Accent
	floatButton.BorderSizePixel = 0
	floatButton.Image = ""
	floatButton.AutoButtonColor = false
	floatButton.Parent = screenGui
	
	local floatCorner = Instance.new("UICorner")
	floatCorner.CornerRadius = UDim.new(0, 30)
	floatCorner.Parent = floatButton
	
	local floatIcon = Instance.new("TextLabel")
	floatIcon.Size = UDim2.new(1, 0, 1, 0)
	floatIcon.BackgroundTransparency = 1
	floatIcon.Text = "🚤"
	floatIcon.TextSize = 28
	floatIcon.Font = Enum.Font.GothamBold
	floatIcon.TextColor3 = Colors.Text
	floatIcon.Parent = floatButton
	
	local floatShadow = Instance.new("ImageLabel")
	floatShadow.Name = "Shadow"
	floatShadow.Size = UDim2.new(1, 20, 1, 20)
	floatShadow.Position = UDim2.new(0, -10, 0, -5)
	floatShadow.BackgroundTransparency = 1
	floatShadow.Image = "rbxassetid://5554236805"
	floatShadow.ImageColor3 = Color3.new(0, 0, 0)
	floatShadow.ImageTransparency = 0.6
	floatShadow.ZIndex = 0
	floatShadow.Parent = floatButton
	
	-- Main Popup Frame
	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.Size = UDim2.new(0, 400, 0, 500)
	popup.Position = UDim2.new(0.5, -200, 0.5, -250)
	popup.BackgroundColor3 = Colors.Background
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.Parent = screenGui
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 16)
	popupCorner.Parent = popup
	
	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Colors.Accent
	popupStroke.Thickness = 2
	popupStroke.Transparency = 0.5
	popupStroke.Parent = popup
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Colors.Panel
	header.BorderSizePixel = 0
	header.Parent = popup
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header
	
	-- Fix corner for header bottom
	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0, 20)
	headerFix.Position = UDim2.new(0, 0, 1, -20)
	headerFix.BackgroundColor3 = Colors.Panel
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🚤 Boat Spawner"
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Colors.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.BackgroundColor3 = Colors.Card
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = Colors.TextDim
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = header
	
	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn
	
	-- Boat List Container
	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "BoatList"
	listContainer.Size = UDim2.new(1, -40, 1, -80)
	listContainer.Position = UDim2.new(0, 20, 0, 70)
	listContainer.BackgroundTransparency = 1
	listContainer.BorderSizePixel = 0
	listContainer.ScrollBarThickness = 6
	listContainer.ScrollBarImageColor3 = Colors.Accent
	listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	listContainer.Parent = popup
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 12)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listContainer
	
	return {
		screenGui = screenGui,
		floatButton = floatButton,
		popup = popup,
		listContainer = listContainer,
		closeBtn = closeBtn,
	}
end

-- ==================== CREATE BOAT CARD ====================

local function createBoatCard(boatData, parent)
	local card = Instance.new("Frame")
	card.Name = boatData.Name
	card.Size = UDim2.new(1, 0, 0, 120)
	card.BackgroundColor3 = Colors.Card
	card.BorderSizePixel = 0
	card.Parent = parent
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card
	
	-- Boat Icon
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 80, 0, 80)
	iconFrame.Position = UDim2.new(0, 15, 0, 20)
	iconFrame.BackgroundColor3 = Colors.Panel
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 10)
	iconCorner.Parent = iconFrame
	
	local iconText = Instance.new("TextLabel")
	iconText.Size = UDim2.new(1, 0, 1, 0)
	iconText.BackgroundTransparency = 1
	iconText.Text = "🚤"
	iconText.TextSize = 36
	iconText.Font = Enum.Font.GothamBold
	iconText.TextColor3 = Colors.Text
	iconText.Parent = iconFrame
	
	-- Boat Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 180, 0, 25)
	nameLabel.Position = UDim2.new(0, 110, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = boatData.DisplayName
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Colors.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card
	
	-- Stats
	local statsText = string.format("⚡ Speed: %d  |  🚀 Accel: %.2f", boatData.MaxSpeed, boatData.Acceleration)
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(0, 180, 0, 20)
	statsLabel.Position = UDim2.new(0, 110, 0, 42)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = statsText
	statsLabel.TextSize = 12
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextColor3 = Colors.TextDim
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = card
	
	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, 180, 0, 20)
	priceLabel.Position = UDim2.new(0, 110, 0, 62)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = boatData.Price == 0 and "🆓 Free" or string.format("💰 $%d", boatData.Price)
	priceLabel.TextSize = 14
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextColor3 = boatData.Price == 0 and Colors.Success or Colors.Warning
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card
	
	-- Spawn Button
	local spawnBtn = Instance.new("TextButton")
	spawnBtn.Name = "SpawnButton"
	spawnBtn.Size = UDim2.new(0, 80, 0, 35)
	spawnBtn.Position = UDim2.new(1, -95, 0.5, -17)
	spawnBtn.BackgroundColor3 = Colors.Accent
	spawnBtn.BorderSizePixel = 0
	spawnBtn.Text = "Spawn"
	spawnBtn.TextSize = 14
	spawnBtn.Font = Enum.Font.GothamBold
	spawnBtn.TextColor3 = Colors.Text
	spawnBtn.AutoButtonColor = false
	spawnBtn.Parent = card
	
	local spawnBtnCorner = Instance.new("UICorner")
	spawnBtnCorner.CornerRadius = UDim.new(0, 8)
	spawnBtnCorner.Parent = spawnBtn
	
	-- Button Hover Effects
	spawnBtn.MouseEnter:Connect(function()
		TweenService:Create(spawnBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.AccentHover}):Play()
	end)
	
	spawnBtn.MouseLeave:Connect(function()
		TweenService:Create(spawnBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent}):Play()
	end)
	
	-- Spawn Click
	spawnBtn.MouseButton1Click:Connect(function()
		-- Visual feedback
		spawnBtn.Text = "..."
		spawnBtn.BackgroundColor3 = Colors.Success
		
		-- Send spawn request
		SpawnBoatEvent:FireServer(boatData.Name)
		
		-- Reset button after delay
		task.delay(1, function()
			spawnBtn.Text = "Spawn"
			spawnBtn.BackgroundColor3 = Colors.Accent
		end)
	end)
	
	return card
end

-- ==================== MAIN ====================

local ui = createUI()
local isOpen = false

-- Toggle popup
local function togglePopup()
	isOpen = not isOpen
	
	if isOpen then
		-- Load boats
		local boats = GetBoatsEvent:InvokeServer()
		
		-- Clear existing cards
		for _, child in ipairs(ui.listContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		-- Create cards
		if boats and #boats > 0 then
			for _, boatData in ipairs(boats) do
				createBoatCard(boatData, ui.listContainer)
			end
			
			-- Update canvas size
			local layout = ui.listContainer:FindFirstChildOfClass("UIListLayout")
			if layout then
				ui.listContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
			end
		else
			-- No boats message
			local noBoats = Instance.new("TextLabel")
			noBoats.Size = UDim2.new(1, 0, 0, 100)
			noBoats.BackgroundTransparency = 1
			noBoats.Text = "No boats available!\n\nAdd boat models to:\nServerStorage/BoatTemplates"
			noBoats.TextSize = 14
			noBoats.Font = Enum.Font.Gotham
			noBoats.TextColor3 = Colors.TextDim
			noBoats.TextWrapped = true
			noBoats.Parent = ui.listContainer
		end
		
		-- Show popup with animation
		ui.popup.Visible = true
		ui.popup.Position = UDim2.new(0.5, -200, 0.5, -220)
		ui.popup.BackgroundTransparency = 1
		
		TweenService:Create(ui.popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -200, 0.5, -250),
			BackgroundTransparency = 0
		}):Play()
	else
		-- Hide popup with animation
		local tween = TweenService:Create(ui.popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -200, 0.5, -220),
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			if not isOpen then
				ui.popup.Visible = false
			end
		end)
	end
end

-- Button click
ui.floatButton.MouseButton1Click:Connect(togglePopup)
ui.closeBtn.MouseButton1Click:Connect(function()
	if isOpen then togglePopup() end
end)

-- Button hover effect
ui.floatButton.MouseEnter:Connect(function()
	TweenService:Create(ui.floatButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Colors.AccentHover,
		Size = UDim2.new(0, 65, 0, 65)
	}):Play()
end)

ui.floatButton.MouseLeave:Connect(function()
	TweenService:Create(ui.floatButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Colors.Accent,
		Size = UDim2.new(0, 60, 0, 60)
	}):Play()
end)

print("🚤 [BOAT SPAWNER CLIENT] Initialized")
