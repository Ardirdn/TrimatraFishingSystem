--[[
    SETTINGS CLIENT v2.0 (FIXED & ADAPTIVE)
    
    FIXES:
    - Uses Icon system for HUD button
    - Fully adaptive UI with Scale (not Offset)
    - Camera Tracking using CameraSubject
    - Camera Smoothness with proper implementation
    - Bubble Chat properly disabled
    - Dropdown with correct ZIndex
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- ==================== DESIGN CONSTANTS ====================
local COLORS = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Header = Color3.fromRGB(30, 30, 33),
	Button = Color3.fromRGB(35, 35, 38),
	ButtonHover = Color3.fromRGB(45, 45, 48),
	Accent = Color3.fromRGB(70, 130, 255),
	AccentHover = Color3.fromRGB(90, 150, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(150, 150, 160),
	Border = Color3.fromRGB(50, 50, 55),
	ToggleOn = Color3.fromRGB(67, 181, 129),
	ToggleOff = Color3.fromRGB(70, 70, 80),
	SliderTrack = Color3.fromRGB(50, 50, 60),
	SliderFill = Color3.fromRGB(70, 130, 255),
}

-- ==================== SETTINGS STATE ====================
local Settings = {
	-- Gameplay
	HideTitle = false,
	HidePlayer = "Disable",
	HideAura = false,
	MuteAllPlayer = false,
	ShowBubbleChat = true,
	
	-- Camera
	CameraTracking = "Default",
	FieldOfView = 70,
	CameraSmoothness = 0,  -- 0-100, 0 = no smooth, 100 = max smooth
	CameraSway = false,
}

-- ==================== CAMERA SMOOTH SYSTEM ====================
local smoothConnection = nil
local swayConnection = nil
local smoothCurrent = Vector2.zero
local smoothTargetX, smoothTargetY = 0, 0

local function applyCameraSmoothness()
	-- Disconnect existing
	if smoothConnection then
		RunService:UnbindFromRenderStep("SettingsSmoothCam")
		smoothConnection = nil
	end
	
	if Settings.CameraSmoothness <= 0 then
		-- Disable smooth camera
		UserInputService.MouseDeltaSensitivity = 1
		camera.CameraType = Enum.CameraType.Custom
		return
	end
	
	-- Slider 0 = speed 30 (tidak smooth), Slider 100 = speed 4 (paling smooth)
	local sliderValue = Settings.CameraSmoothness / 100
	local speed = 30 - (26 * sliderValue)  -- Range 30 to 4
	
	local rad = 180 / math.pi
	local clamp = math.clamp
	local sensitivity = 1
	local releaseSpeed = 0.5
	
	UserInputService.MouseDeltaSensitivity = 0.01
	camera.CameraType = Enum.CameraType.Custom
	
	RunService:BindToRenderStep("SettingsSmoothCam", Enum.RenderPriority.Camera.Value - 1, function(dt)
		local delta = UserInputService:GetMouseDelta() * sensitivity * 100
		smoothTargetX = smoothTargetX - delta.X
		smoothTargetY = clamp(smoothTargetY - delta.Y, -89, 89)
		smoothCurrent = smoothCurrent:Lerp(Vector2.new(smoothTargetX, smoothTargetY), dt * speed)
		camera.CFrame = CFrame.fromOrientation(smoothCurrent.Y / rad, smoothCurrent.X / rad, 0)
	end)
	
	smoothConnection = true
end

local function applyCameraSway()
	if swayConnection then
		RunService:UnbindFromRenderStep("SettingsCameraSway")
		swayConnection = nil
	end
	
	if not Settings.CameraSway then return end
	
	local swayTurn = 0
	
	RunService:BindToRenderStep("SettingsCameraSway", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		local mousedelta = UserInputService:GetMouseDelta()
		swayTurn = swayTurn + (math.clamp(mousedelta.X, -6, 6) - swayTurn) * (6 * deltaTime)
		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(swayTurn))
	end)
	
	swayConnection = true
end

local function applyCameraTracking()
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	if Settings.CameraTracking == "Head" then
		local head = character:FindFirstChild("Head")
		if head then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
			camera.CameraSubject = head
		end
	elseif Settings.CameraTracking == "Torso" then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
			camera.CameraSubject = hrp
		end
	else
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
		camera.CameraSubject = humanoid
	end
end

-- ==================== UI HELPERS ====================
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
screenGui.Name = "SettingsGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50
screenGui.Enabled = false
screenGui.Parent = playerGui

-- ==================== MAIN PANEL (ADAPTIVE) ====================
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.new(0.35, 0, 0.7, 0)  -- Scale-based
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = COLORS.Background
panel.BorderSizePixel = 0
panel.Visible = true
panel.Parent = screenGui

-- Aspect Ratio Constraint
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 0.9
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = panel

-- Size constraint
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(350, 400)
sizeConstraint.MaxSize = Vector2.new(0, 0)
sizeConstraint.Parent = panel

createCorner(16).Parent = panel
createStroke(COLORS.Border, 2).Parent = panel

-- Header (Scale-based)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.1, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = panel

createCorner(16).Parent = header

-- Fix bottom corners
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0.4, 0)
headerFix.Position = UDim2.new(0, 0, 0.6, 0)
headerFix.BackgroundColor3 = COLORS.Panel
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Size = UDim2.new(0.7, 0, 1, 0)
headerTitle.Position = UDim2.new(0.05, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBlack
headerTitle.Text = "⚙️ SETTINGS"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local titleSizeConstraint = Instance.new("UITextSizeConstraint")
titleSizeConstraint.MaxTextSize = 16
titleSizeConstraint.MinTextSize = 0
titleSizeConstraint.Parent = headerTitle

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0.12, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.86, 0, 0.15, 0)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLORS.Text
closeBtn.TextScaled = true
closeBtn.Parent = header

createCorner(10).Parent = closeBtn

local closeSizeConstraint = Instance.new("UITextSizeConstraint")
closeSizeConstraint.MaxTextSize = 16
closeSizeConstraint.MinTextSize = 0
closeSizeConstraint.Parent = closeBtn

-- ==================== TAB BAR (ADAPTIVE) ====================
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(0.9, 0, 0.08, 0)
tabBar.Position = UDim2.new(0.05, 0, 0.12, 0)
tabBar.BackgroundColor3 = COLORS.Panel
tabBar.BorderSizePixel = 0
tabBar.Parent = panel

createCorner(10).Parent = tabBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.02, 0)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabBar

local tabs = {}
local tabContents = {}
local currentTab = nil

local function createTab(name, icon)
	local tab = Instance.new("TextButton")
	tab.Name = name .. "Tab"
	tab.Size = UDim2.new(0.45, 0, 0.8, 0)
	tab.BackgroundColor3 = COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.Text = icon .. " " .. name
	tab.TextColor3 = COLORS.TextDim
	tab.TextScaled = true
	tab.Parent = tabBar
	
	createCorner(8).Parent = tab
	
	local tabTextConstraint = Instance.new("UITextSizeConstraint")
	tabTextConstraint.MaxTextSize = 16
	tabTextConstraint.MinTextSize = 0
	tabTextConstraint.Parent = tab
	
	-- Content container
	local content = Instance.new("ScrollingFrame")
	content.Name = name .. "Content"
	content.Size = UDim2.new(0.9, 0, 0.75, 0)
	content.Position = UDim2.new(0.05, 0, 0.22, 0)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.ScrollBarImageColor3 = COLORS.Accent
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Visible = false
	content.Parent = panel
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0.02, 0)
	contentLayout.Parent = content
	
	tabs[name] = tab
	tabContents[name] = content
	
	tab.MouseButton1Click:Connect(function()
		for tabName, t in pairs(tabs) do
			if tabName == name then
				t.BackgroundColor3 = COLORS.Accent
				t.TextColor3 = COLORS.Text
				tabContents[tabName].Visible = true
				currentTab = tabName
			else
				t.BackgroundColor3 = COLORS.Button
				t.TextColor3 = COLORS.TextDim
				tabContents[tabName].Visible = false
			end
		end
	end)
	
	return tab, content
end

createTab("Gameplay", "🎮")
createTab("Camera", "📷")

-- ==================== UI COMPONENTS (ADAPTIVE) ====================

local activeDropdown = nil  -- Track active dropdown for closing

local function createToggle(parent, label, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = label .. "Toggle"
	container.Size = UDim2.new(1, 0, 0, 50)
	container.BackgroundColor3 = COLORS.Panel
	container.BorderSizePixel = 0
	container.Parent = parent
	
	createCorner(10).Parent = container
	
	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.7, 0, 1, 0)
	labelText.Position = UDim2.new(0.03, 0, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.GothamMedium
	labelText.Text = label
	labelText.TextColor3 = COLORS.Text
	labelText.TextScaled = true
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Parent = container
	
	local labelSizeConstraint = Instance.new("UITextSizeConstraint")
	labelSizeConstraint.MaxTextSize = 16
	labelSizeConstraint.MinTextSize = 0
	labelSizeConstraint.Parent = labelText
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, 50, 0, 26)
	toggleBg.Position = UDim2.new(0.85, 0, 0.5, 0)
	toggleBg.AnchorPoint = Vector2.new(0.5, 0.5)
	toggleBg.BackgroundColor3 = defaultValue and COLORS.ToggleOn or COLORS.ToggleOff
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	createCorner(13).Parent = toggleBg
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Name = "Circle"
	toggleCircle.Size = UDim2.new(0, 20, 0, 20)
	toggleCircle.Position = defaultValue and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
	toggleCircle.AnchorPoint = Vector2.new(0, 0.5)
	toggleCircle.BackgroundColor3 = COLORS.Text
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	createCorner(10).Parent = toggleCircle
	
	local isOn = defaultValue
	
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Parent = container
	
	toggleBtn.MouseButton1Click:Connect(function()
		isOn = not isOn
		
		TweenService:Create(toggleBg, TweenInfo.new(0.2), {
			BackgroundColor3 = isOn and COLORS.ToggleOn or COLORS.ToggleOff
		}):Play()
		
		TweenService:Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Position = isOn and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		}):Play()
		
		if callback then callback(isOn) end
	end)
	
	return container
end

local function createDropdown(parent, label, options, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = label .. "Dropdown"
	container.Size = UDim2.new(1, 0, 0, 50)
	container.BackgroundColor3 = COLORS.Panel
	container.BorderSizePixel = 0
	container.ZIndex = 10
	container.Parent = parent
	
	createCorner(10).Parent = container
	
	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.45, 0, 1, 0)
	labelText.Position = UDim2.new(0.03, 0, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.GothamMedium
	labelText.Text = label
	labelText.TextColor3 = COLORS.Text
	labelText.TextScaled = true
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.ZIndex = 10
	labelText.Parent = container
	
	local labelSizeConstraint = Instance.new("UITextSizeConstraint")
	labelSizeConstraint.MaxTextSize = 16
	labelSizeConstraint.MinTextSize = 0
	labelSizeConstraint.Parent = labelText
	
	local dropdownBtn = Instance.new("TextButton")
	dropdownBtn.Name = "DropdownBtn"
	dropdownBtn.Size = UDim2.new(0.45, 0, 0.65, 0)
	dropdownBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	dropdownBtn.AnchorPoint = Vector2.new(0, 0.5)
	dropdownBtn.BackgroundColor3 = COLORS.Button
	dropdownBtn.BorderSizePixel = 0
	dropdownBtn.Font = Enum.Font.GothamMedium
	dropdownBtn.Text = defaultValue .. " ▼"
	dropdownBtn.TextColor3 = COLORS.Text
	dropdownBtn.TextScaled = true
	dropdownBtn.ZIndex = 10
	dropdownBtn.Parent = container
	
	createCorner(8).Parent = dropdownBtn
	
	local dropdownTextConstraint = Instance.new("UITextSizeConstraint")
	dropdownTextConstraint.MaxTextSize = 16
	dropdownTextConstraint.MinTextSize = 0
	dropdownTextConstraint.Parent = dropdownBtn
	
	-- Dropdown list (HIGH ZINDEX)
	local dropdownList = Instance.new("Frame")
	dropdownList.Name = "DropdownList"
	dropdownList.Size = UDim2.new(1, 0, 0, #options * 35 + 10)
	dropdownList.Position = UDim2.new(0, 0, 1, 5)
	dropdownList.BackgroundColor3 = COLORS.Background
	dropdownList.BorderSizePixel = 0
	dropdownList.Visible = false
	dropdownList.ZIndex = 999  -- HIGH ZINDEX
	dropdownList.Parent = dropdownBtn
	
	createCorner(8).Parent = dropdownList
	createStroke(COLORS.Border, 1).Parent = dropdownList
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = dropdownList
	
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 5)
	listPadding.PaddingLeft = UDim.new(0, 5)
	listPadding.PaddingRight = UDim.new(0, 5)
	listPadding.Parent = dropdownList
	
	local currentValue = defaultValue
	
	for _, option in ipairs(options) do
		local optionBtn = Instance.new("TextButton")
		optionBtn.Size = UDim2.new(1, 0, 0, 30)
		optionBtn.BackgroundColor3 = COLORS.Panel
		optionBtn.BorderSizePixel = 0
		optionBtn.Font = Enum.Font.GothamMedium
		optionBtn.Text = option
		optionBtn.TextColor3 = COLORS.Text
		optionBtn.TextScaled = true
		optionBtn.ZIndex = 1000
		optionBtn.Parent = dropdownList
		
		createCorner(6).Parent = optionBtn
		
		local optionTextConstraint = Instance.new("UITextSizeConstraint")
		optionTextConstraint.MaxTextSize = 16
		optionTextConstraint.MinTextSize = 0
		optionTextConstraint.Parent = optionBtn
		
		optionBtn.MouseEnter:Connect(function()
			TweenService:Create(optionBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Accent}):Play()
		end)
		
		optionBtn.MouseLeave:Connect(function()
			TweenService:Create(optionBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Panel}):Play()
		end)
		
		optionBtn.MouseButton1Click:Connect(function()
			currentValue = option
			dropdownBtn.Text = option .. " ▼"
			dropdownList.Visible = false
			activeDropdown = nil
			if callback then callback(option) end
		end)
	end
	
	dropdownBtn.MouseButton1Click:Connect(function()
		-- Close any other dropdown
		if activeDropdown and activeDropdown ~= dropdownList then
			activeDropdown.Visible = false
		end
		
		dropdownList.Visible = not dropdownList.Visible
		activeDropdown = dropdownList.Visible and dropdownList or nil
	end)
	
	return container
end

local function createSlider(parent, label, minVal, maxVal, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = label .. "Slider"
	container.Size = UDim2.new(1, 0, 0, 70)
	container.BackgroundColor3 = COLORS.Panel
	container.BorderSizePixel = 0
	container.Parent = parent
	
	createCorner(10).Parent = container
	
	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.6, 0, 0.4, 0)
	labelText.Position = UDim2.new(0.03, 0, 0.1, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.GothamMedium
	labelText.Text = label
	labelText.TextColor3 = COLORS.Text
	labelText.TextScaled = true
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Parent = container
	
	local labelSizeConstraint = Instance.new("UITextSizeConstraint")
	labelSizeConstraint.MaxTextSize = 16
	labelSizeConstraint.MinTextSize = 0
	labelSizeConstraint.Parent = labelText
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
	valueLabel.Position = UDim2.new(0.77, 0, 0.1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = tostring(defaultValue)
	valueLabel.TextColor3 = COLORS.Accent
	valueLabel.TextScaled = true
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = container
	
	local valueSizeConstraint = Instance.new("UITextSizeConstraint")
	valueSizeConstraint.MaxTextSize = 16
	valueSizeConstraint.MinTextSize = 0
	valueSizeConstraint.Parent = valueLabel
	
	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = "Track"
	sliderTrack.Size = UDim2.new(0.9, 0, 0, 8)
	sliderTrack.Position = UDim2.new(0.05, 0, 0.7, 0)
	sliderTrack.BackgroundColor3 = COLORS.SliderTrack
	sliderTrack.BorderSizePixel = 0
	sliderTrack.Parent = container
	
	createCorner(4).Parent = sliderTrack
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "Fill"
	sliderFill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
	sliderFill.BackgroundColor3 = COLORS.SliderFill
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderTrack
	
	createCorner(4).Parent = sliderFill
	
	local sliderKnob = Instance.new("Frame")
	sliderKnob.Name = "Knob"
	sliderKnob.Size = UDim2.new(0, 16, 0, 16)
	sliderKnob.Position = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 0.5, 0)
	sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderKnob.BackgroundColor3 = COLORS.Text
	sliderKnob.BorderSizePixel = 0
	sliderKnob.Parent = sliderTrack
	
	createCorner(8).Parent = sliderKnob
	
	local currentValue = defaultValue
	local dragging = false
	
	local function updateSlider(input)
		local trackAbsPos = sliderTrack.AbsolutePosition.X
		local trackAbsSize = sliderTrack.AbsoluteSize.X
		local mouseX = input.Position.X
		
		local ratio = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
		currentValue = math.floor(minVal + (maxVal - minVal) * ratio)
		
		sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
		sliderKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = tostring(currentValue)
		
		if callback then callback(currentValue) end
	end
	
	sliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider(input)
		end
	end)
	
	sliderKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	return container
end

-- ==================== POPULATE TABS ====================

-- Gameplay Tab
local gameplayContent = tabContents["Gameplay"]

createToggle(gameplayContent, "🏷️ Hide Title", Settings.HideTitle, function(value)
	Settings.HideTitle = value
	
	-- ✅ ONLY toggle PlayerInfoBillboard via TitleClient
	-- Roblox default name is ALWAYS hidden (handled by TitleClient)
	if _G.SetHideTitles then _G.SetHideTitles(value) end
end)

createDropdown(gameplayContent, "👥 Hide Players", {"Disable", "Friends Only", "All"}, Settings.HidePlayer, function(value)
	Settings.HidePlayer = value
	
	local hideAll = (value == "All")
	local friendsOnly = (value == "Friends Only")
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local shouldHide = hideAll
			
			if friendsOnly then
				local isFriend = pcall(function() return player:IsFriendsWith(otherPlayer.UserId) end)
				shouldHide = not isFriend
			end
			
			if otherPlayer.Character then
				-- Hide character parts
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = shouldHide and 1 or 0
					elseif part:IsA("Decal") or part:IsA("Texture") then
						part.LocalTransparencyModifier = shouldHide and 1 or 0
					end
				end
				
				-- ✅ Hide PlayerInfoBillboard (Roblox default always hidden by TitleClient)
				local head = otherPlayer.Character:FindFirstChild("Head")
				if head then
					local billboard = head:FindFirstChild("PlayerInfoBillboard")
					if billboard then
						billboard.Enabled = not shouldHide
					end
				end
			end
		end
	end
end)

createToggle(gameplayContent, "✨ Hide Aura", Settings.HideAura, function(value)
	Settings.HideAura = value
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				-- ✅ Find EquippedAura folder specifically
				local equippedAura = hrp:FindFirstChild("EquippedAura")
				if equippedAura then
					-- Hide all visual effects inside aura
					for _, child in ipairs(equippedAura:GetDescendants()) do
						if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
							child.Enabled = not value
						elseif child:IsA("BasePart") or child:IsA("MeshPart") then
							child.LocalTransparencyModifier = value and 1 or 0
						elseif child:IsA("Decal") or child:IsA("Texture") then
							child.LocalTransparencyModifier = value and 1 or 0
						elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
							child.Enabled = not value
						end
					end
				end
			end
			
			-- Also check for any other aura-named objects
			for _, child in ipairs(otherPlayer.Character:GetDescendants()) do
				if child.Name:lower():find("aura") then
					if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
						child.Enabled = not value
					elseif child:IsA("BasePart") then
						child.LocalTransparencyModifier = value and 1 or 0
					end
				end
			end
		end
	end
end)

createToggle(gameplayContent, "🔇 Mute All Players", Settings.MuteAllPlayer, function(value)
	Settings.MuteAllPlayer = value
	
	-- ✅ Mute voice chat for all players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			-- Try to mute via VoiceChatService
			pcall(function()
				local VoiceChatService = game:GetService("VoiceChatService")
				if VoiceChatService then
					VoiceChatService:SetPlayerMuted(otherPlayer, value)
				end
			end)
			
			-- Also mute any Sound objects in their character
			if otherPlayer.Character then
				for _, sound in ipairs(otherPlayer.Character:GetDescendants()) do
					if sound:IsA("Sound") then
						sound.Volume = value and 0 or 1
					end
				end
			end
		end
	end
end)

createToggle(gameplayContent, "💬 Show Bubble Chat", Settings.ShowBubbleChat, function(value)
	Settings.ShowBubbleChat = value
	
	-- ✅ PROPER BUBBLE CHAT TOGGLE
	pcall(function()
		local bubbleConfig = TextChatService:FindFirstChild("BubbleChatConfiguration")
		if bubbleConfig then
			bubbleConfig.Enabled = value
		end
	end)
	
	pcall(function()
		local chat = game:GetService("Chat")
		if chat and chat:FindFirstChild("BubbleChat") then
			chat.BubbleChat.Enabled = value
		end
	end)
end)

-- Camera Tab
local cameraContent = tabContents["Camera"]

createDropdown(cameraContent, "🎯 Camera Tracking", {"Default", "Head", "Torso"}, Settings.CameraTracking, function(value)
	Settings.CameraTracking = value
	applyCameraTracking()
end)

createSlider(cameraContent, "📐 Field of View", 40, 120, Settings.FieldOfView, function(value)
	Settings.FieldOfView = value
	camera.FieldOfView = value
end)

createSlider(cameraContent, "🎬 Camera Smoothness", 0, 100, Settings.CameraSmoothness, function(value)
	Settings.CameraSmoothness = value
	applyCameraSmoothness()
end)

createToggle(cameraContent, "🌊 Camera Sway", Settings.CameraSway, function(value)
	Settings.CameraSway = value
	applyCameraSway()
end)

-- Select default tab
tabs["Gameplay"].BackgroundColor3 = COLORS.Accent
tabs["Gameplay"].TextColor3 = COLORS.Text
tabContents["Gameplay"].Visible = true
currentTab = "Gameplay"

-- ==================== PANEL TOGGLE ====================
local function togglePanel()
	screenGui.Enabled = not screenGui.Enabled
end

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Close dropdown when clicking elsewhere
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if activeDropdown then
			task.wait()
			activeDropdown.Visible = false
			activeDropdown = nil
		end
	end
	if input.KeyCode == Enum.KeyCode.Escape and screenGui.Enabled then
		screenGui.Enabled = false
		panel.Visible = false
	end
end)

-- Apply camera tracking when character spawns
player.CharacterAdded:Connect(function()
	task.wait(1)
	applyCameraTracking()
end)

-- ==================== HUD BUTTON (Like Vibe, Freecam, Music) ====================
local HUDButton = require(script.Parent:WaitForChild("HUDButtonHelper"))

local settingsHudBtn = HUDButton.Create({
	Side = "Right",
	Icon = "rbxassetid://129398451343170",
	Text = "Settings",
	Name = "SettingsButton",
	OnClick = function()
		panel.Visible = not panel.Visible
		screenGui.Enabled = panel.Visible
	end
})

-- Setup panel visibility
screenGui.Enabled = true
panel.Visible = false

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

-- Export settings
_G.GameSettings = Settings

print("✅ [SETTINGS CLIENT v2] Loaded with HUD button (Right side)")

