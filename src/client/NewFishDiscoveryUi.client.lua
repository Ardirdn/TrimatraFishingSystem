local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))
local FishCaughtEvent = ReplicatedStorage:WaitForChild("FishCaughtEvent")

print("🔍 [DEBUG UI] NewFishDiscovery script starting...")

-- ============================================
-- MODERN COLOR PALETTE
-- ============================================
local Colors = {
	Background = Color3.fromRGB(18, 18, 22),
	CardBg = Color3.fromRGB(28, 28, 35),
	Success = Color3.fromRGB(67, 181, 129),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(163, 166, 183),

	-- Rarity colors (modern, softer)
	Common = Color3.fromRGB(163, 166, 183),
	Uncommon = Color3.fromRGB(67, 181, 129),
	Rare = Color3.fromRGB(88, 166, 255),
	Epic = Color3.fromRGB(163, 108, 229),
	Legendary = Color3.fromRGB(255, 193, 7)
}

-- ============================================
-- SIMPLE NOTIFICATION
-- ============================================
local function showSimpleNotification(fishData, quantity)
	print("📢 [DEBUG UI] showSimpleNotification for:", fishData.Name)

	local notifGui = Instance.new("ScreenGui")
	notifGui.Name = "SimpleFishNotif"
	notifGui.ResetOnSpawn = false
	notifGui.DisplayOrder = 100
	notifGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 70)
	frame.Position = UDim2.new(1, 10, 0, 20)
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BackgroundColor3 = Colors.CardBg
	frame.BorderSizePixel = 0
	frame.Parent = notifGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors[fishData.Rarity] or Colors.Common
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = frame

	-- Icon background
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 50, 0, 50)
	iconBg.Position = UDim2.new(0, 10, 0.5, 0)
	iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = Colors.Background
	iconBg.BorderSizePixel = 0
	iconBg.Parent = frame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconBg

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = fishData.ImageID
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = iconBg

	-- Text
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -75, 1, 0)
	label.Position = UDim2.new(0, 70, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s x%d", fishData.Name, quantity)
	label.TextSize = 15
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Colors.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	-- Animate
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -330, 0, 20)})
	tweenIn:Play()

	task.wait(3)

	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(1, 10, 0, 20)})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	notifGui:Destroy()
end

-- ============================================
-- NEW DISCOVERY BANNER (ULTRA PREMIUM)
-- ============================================
local function showNewDiscoveryBanner(fishID, fishData, quantity)
	print("🌟 [DEBUG UI] NEW DISCOVERY BANNER (PREMIUM) TRIGGERED")

	-- 1. Setup ScreenGui utama
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "NewFishDiscovery"
	bannerGui.ResetOnSpawn = false
	bannerGui.DisplayOrder = 1000 -- Pastikan paling depan
	bannerGui.IgnoreGuiInset = true
	bannerGui.Parent = playerGui

	-- Rarity Color Setup
	local rarityColor = Colors[fishData.Rarity] or Colors.Common
	local rarityText = fishData.Rarity:upper()

	-- 2. Dark Backdrop (Cinematic feel)
	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1 -- Start transparent for fade in
	backdrop.BorderSizePixel = 0
	backdrop.Parent = bannerGui

	-- 3. Main Card Container (ADAPTIVE with Scale)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.55, 0, 0.38, 0) -- COMPACT: 55% width, 38% height
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = bannerGui
	card.Visible = false

	-- ═══ ADAPTIVE CONSTRAINTS (COMPACT) ═══
	-- Aspect Ratio Constraint (1.8:1 ratio - more compact)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1.8 -- 1.8:1 (more compact than before)
	aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
	aspectRatio.DominantAxis = Enum.DominantAxis.Width
	aspectRatio.Parent = card

	-- Size Constraint (Smaller Min & Max bounds)
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(380, 210) -- Smaller minimum size
	sizeConstraint.MaxSize = Vector2.new(650, 360) -- Smaller maximum size
	sizeConstraint.Parent = card

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16) -- Smaller corner radius for compact look
	cardCorner.Parent = card

	-- Card Stroke/Glow
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = rarityColor
	cardStroke.Thickness = 2 -- Thinner stroke for compact
	cardStroke.Transparency = 0.2
	cardStroke.Parent = card

	-- Gradient Background for Card
	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
	}
	cardGradient.Rotation = 45
	cardGradient.Parent = card

	-- ==========================================
	-- LEFT SIDE: VISUALS (Rays + 3D Model)
	-- ==========================================
	local visualContainer = Instance.new("Frame")
	visualContainer.Size = UDim2.new(0.48, 0, 1, 0) -- Slightly larger for better fish visibility
	visualContainer.BackgroundTransparency = 1
	visualContainer.Parent = card

	-- Rotating Rays Effect (Manual creation using frames since no asset ID)
	local raysContainer = Instance.new("Frame")
	raysContainer.Name = "RaysContainer"
	raysContainer.Size = UDim2.new(0, 280, 0, 280) -- Smaller rays for compact UI
	raysContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	raysContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	raysContainer.BackgroundTransparency = 1
	raysContainer.ClipsDescendants = false
	raysContainer.Parent = visualContainer

	-- Create sunburst rays using gradient frames
	for i = 1, 8 do
		local ray = Instance.new("Frame")
		ray.Size = UDim2.new(0.2, 0, 1, 0)
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.new(0.5, 0, 0.5, 0)
		ray.BackgroundColor3 = rarityColor
		ray.BorderSizePixel = 0
		ray.Rotation = (i * 45)
		ray.BackgroundTransparency = 0.85
		ray.Parent = raysContainer
		
		local rayCorner = Instance.new("UICorner")
		rayCorner.CornerRadius = UDim.new(1, 0)
		rayCorner.Parent = ray
	end

	-- Rotating Animation for Rays
	task.spawn(function()
		local rot = 0
		while raysContainer.Parent do
			rot = rot + 0.5
			raysContainer.Rotation = rot
			task.wait(0.016)
		end
	end)

	-- 3D Model Viewport (The Star of the Show)
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1.3, 0, 1.3, 0) -- Larger viewport for prominent fish display
	viewport.Position = UDim2.new(0, -15, -0.15, 0) -- Centered better
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -0.5)
	viewport.Parent = visualContainer

	-- ==========================================
	-- RIGHT SIDE: INFO & DETAILS
	-- ==========================================
	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(0.52, 0, 1, 0) -- Adjusted for new layout
	infoContainer.Position = UDim2.new(0.48, 0, 0, 0)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = card

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingTop = UDim.new(0, 18) -- Reduced padding for compact
	infoPadding.PaddingBottom = UDim.new(0, 18)
	infoPadding.PaddingRight = UDim.new(0, 20)
	infoPadding.PaddingLeft = UDim.new(0, 8)
	infoPadding.Parent = infoContainer

	-- List Layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6) -- Tighter spacing for compact
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Parent = infoContainer

	-- 1. "NEW DISCOVERY" Header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Text = "✨ NEW DISCOVERY ✨"
	headerLabel.Size = UDim2.new(1, 0, 0, 20) -- Smaller header
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextSize = 12 -- Smaller text
	headerLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.LayoutOrder = 1
	headerLabel.Parent = infoContainer

	-- 2. Fish Name (Huge)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = fishData.Name
	nameLabel.Size = UDim2.new(1, 0, 0, 40) -- Smaller but still prominent
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = 28 -- Smaller but readable
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = infoContainer

	-- Add shadow to name
	local nameShadow = Instance.new("TextLabel")
	nameShadow.Text = fishData.Name
	nameShadow.Size = UDim2.new(1, 0, 1, 0)
	nameShadow.Position = UDim2.new(0, 2, 0, 2)
	nameShadow.BackgroundTransparency = 1
	nameShadow.Font = Enum.Font.GothamBlack
	nameShadow.TextColor3 = rarityColor -- Tint shadow with rarity
	nameShadow.TextTransparency = 0.6
	nameShadow.TextXAlignment = Enum.TextXAlignment.Left
	nameShadow.TextScaled = true
	nameShadow.ZIndex = 0
	nameShadow.Parent = nameLabel

	-- 3. Rarity Badge & Price Container
	local metaContainer = Instance.new("Frame")
	metaContainer.Size = UDim2.new(1, 0, 0, 28) -- Smaller meta container
	metaContainer.BackgroundTransparency = 1
	metaContainer.LayoutOrder = 3
	metaContainer.Parent = infoContainer

	local metaLayout = Instance.new("UIListLayout")
	metaLayout.FillDirection = Enum.FillDirection.Horizontal
	metaLayout.Padding = UDim.new(0, 10) -- Tighter spacing
	metaLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	metaLayout.Parent = metaContainer

	-- Rarity Badge
	local rarityBadge = Instance.new("Frame")
	rarityBadge.BackgroundColor3 = rarityColor
	rarityBadge.Size = UDim2.new(0, 85, 1, 0) -- Smaller badge
	rarityBadge.Parent = metaContainer
	
	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(0, 6) -- Smaller corner
	rarityCorner.Parent = rarityBadge

	local rarityTextLabel = Instance.new("TextLabel")
	rarityTextLabel.Size = UDim2.new(1, 0, 1, 0)
	rarityTextLabel.BackgroundTransparency = 1
	rarityTextLabel.Text = rarityText
	rarityTextLabel.Font = Enum.Font.GothamBold
	rarityTextLabel.TextSize = 11 -- Smaller text
	rarityTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityTextLabel.Parent = rarityBadge

	-- Price Tag
	local priceTag = Instance.new("TextLabel")
	priceTag.Text = "💰 $" .. tostring(fishData.Price)
	priceTag.AutomaticSize = Enum.AutomaticSize.X
	priceTag.Size = UDim2.new(0, 0, 1, 0)
	priceTag.BackgroundTransparency = 1
	priceTag.Font = Enum.Font.GothamBold
	priceTag.TextColor3 = Colors.Success
	priceTag.TextSize = 16 -- Smaller price text
	priceTag.Parent = metaContainer

	-- 4. Tap to continue (Subtle)
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Text = "Tap to continue"
	hintLabel.Size = UDim2.new(1, 0, 0, 18) -- Smaller hint
	hintLabel.Position = UDim2.new(0.5, 0, 0.92, 0)
	hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextSize = 11 -- Smaller text
	hintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	hintLabel.TextTransparency = 0.4
	hintLabel.Parent = card

	-- ==========================================
	-- MODEL LOADING LOGIC (PRESERVED & WORKING)
	-- ==========================================
	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels") 
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FishModels"))
		or workspace:FindFirstChild("FishModels")

	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishID)
		if fishModel then
			local worldModel = Instance.new("WorldModel")
			worldModel.Parent = viewport
			
			local clonedModel = fishModel:Clone()
			clonedModel.Parent = worldModel

			if clonedModel:IsA("Model") then clonedModel:PivotTo(CFrame.new(0, 0, 0))
			elseif clonedModel:IsA("BasePart") then clonedModel.CFrame = CFrame.new(0, 0, 0) end

			-- AUTO-FIT LOGIC (PRESERVED)
			local modelSize = clonedModel:GetExtentsSize()
			local maxDim = math.max(modelSize.X, modelSize.Y, modelSize.Z)
			
			local fov = 65 -- Slightly narrower FOV for bigger fish appearance
			local fillFactor = 1.15 -- Closer zoom for compact UI
			local distance = (maxDim / 2) / math.tan(math.rad(fov / 2)) * fillFactor
			
			local camera = Instance.new("Camera")
			camera.FieldOfView = fov
			
			-- Cinematic Angle
			local angle = math.rad(20)
			local camX = distance * math.cos(angle) * 0.9
			local camY = maxDim * 0.15
			local camZ = distance * math.sin(angle) * 0.9 + distance * 0.5
			
			camera.CFrame = CFrame.new(Vector3.new(camX, camY, camZ), Vector3.new(0, 0, 0))
			camera.Parent = viewport
			viewport.CurrentCamera = camera

			-- Smooth Rotation
			local rot = 0
			task.spawn(function()
				while viewport.Parent do
					rot = rot + 0.8 -- Faster rotation
					if clonedModel and clonedModel.Parent then
						local currentCF = clonedModel:GetPivot()
						clonedModel:PivotTo(currentCF * CFrame.Angles(0, math.rad(0.8), 0))
					end
					task.wait(0.016)
				end
			end)
		end
	end

	-- ==========================================
	-- ANIMATIONS (ENTRANCE & SHINE)
	-- ==========================================
	
	-- 1. Fade Backdrop
	TweenService:Create(backdrop, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()

	-- 2. Card Pop Entrance (Scale-based, from 0 to full)
	card.Size = UDim2.new(0, 0, 0, 0) -- Start at 0
	card.Visible = true
	
	-- Target size is scale-based (constraints will handle aspect ratio) - COMPACT
	local popTween = TweenService:Create(card, 
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), -- Faster, snappier animation
		{Size = UDim2.new(0.55, 0, 0.38, 0)} -- COMPACT: 55% width, 38% height
	)
	popTween:Play()

	-- 3. Shine Effect (Highlight sweep)
	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0, 50, 2, 0)
	shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.8
	shine.Rotation = 45
	shine.BorderSizePixel = 0
	shine.ZIndex = 10
	shine.Parent = card
	
	task.delay(0.3, function()
		local shineTween = TweenService:Create(shine, 
			TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
			{Position = UDim2.new(1.5, 0, -0.5, 0)}
		)
		shineTween:Play()
	end)

	-- ==========================================
	-- CLOSE LOGIC
	-- ==========================================
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(1, 0, 1, 0)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = ""
	closeButton.ZIndex = 100
	closeButton.Parent = bannerGui

	local closing = false
	closeButton.MouseButton1Click:Connect(function()
		if closing then return end
		closing = true
		
		-- Animate Out
		TweenService:Create(backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		local closeTween = TweenService:Create(card, 
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		closeTween:Play()
		
		closeTween.Completed:Wait()
		bannerGui:Destroy()
	end)
end

-- ============================================
-- EVENT LISTENER
-- ============================================
FishCaughtEvent.OnClientEvent:Connect(function(data)
	print("📩 [DEBUG UI] FishCaughtEvent received!")
	print("📩 [DEBUG UI] Fish:", data.FishData.Name, "| New:", data.IsNewDiscovery)
	print("📩 [DEBUG UI] Fish ID:", data.FishID)

	if data.IsNewDiscovery then
		showNewDiscoveryBanner(data.FishID, data.FishData, data.Quantity)
	else
		showSimpleNotification(data.FishData, data.Quantity)
	end
end)

print("✅ New Fish Discovery UI Loaded!")
