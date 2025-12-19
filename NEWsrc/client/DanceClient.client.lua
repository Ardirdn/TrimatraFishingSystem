--[[
    DANCE SYSTEM CLIENT (MERGED - SCALE UI + PERSISTENT FAVORITES)
    Place in StarterPlayerScripts/DanceClient
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local HUDButton = require(script.Parent:WaitForChild("HUDButtonHelper"))
local DanceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DanceConfig"))

-- RemoteEvents (DanceRemotes)
local remoteFolder = ReplicatedStorage:WaitForChild("DanceRemotes")
local toggleFavoriteEvent = remoteFolder:WaitForChild("ToggleFavorite")
local getFavoritesFunc = remoteFolder:WaitForChild("GetFavorites")

-- RemoteEvents (DanceComm)
local danceComm = ReplicatedStorage:WaitForChild("DanceComm")
local StartDanceEvent = danceComm:WaitForChild("StartDance")
local StopDanceEvent = danceComm:WaitForChild("StopDance")
local SyncDanceEvent = danceComm:WaitForChild("SyncDance")
local UnsyncDanceEvent = danceComm:WaitForChild("UnsyncDance")
local SetSpeedEvent = danceComm:WaitForChild("SetSpeed")

-- ==================== CONSTANTS ====================
local COLORS = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Button = Color3.fromRGB(35, 35, 38),
	Accent = Color3.fromRGB(70, 130, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Border = Color3.fromRGB(50, 50, 55),
}

-- ==================== STATE ====================
local favorites = {}
local searchQuery = ""
local currentAnimation = nil
local animationSpeed = 1
local isCoordinateDancing = false

-- Animation Playback
local Tracks = {}
local Animators = {}
local AnimationDatas = {}

-- ==================== HELPER FUNCTIONS ====================
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

-- ==================== CREATE GUI (✅ SCALE-BASED) ====================
local screenGui = playerGui:WaitForChild("Dance")
--local screenGui = Instance.new("ScreenGui")
--screenGui.Name = "DanceSystemGUI"
--screenGui.ResetOnSpawn = false
--screenGui.Enabled = false
--screenGui.Parent = playerGui

-- Main Panel (✅ Scale)
local mainPanel = screenGui:WaitForChild("MainPanel")
--local mainPanel = Instance.new("Frame")
--mainPanel.Size = UDim2.new(0.27, 0, 0.65, 0) -- ✅ Scale
--mainPanel.Position = UDim2.new(0.02, 0, 0.5, 0) -- ✅ Scale
--mainPanel.AnchorPoint = Vector2.new(0, 0.5)
--mainPanel.BackgroundColor3 = COLORS.Background
--mainPanel.BorderSizePixel = 0
--mainPanel.Visible = false
--mainPanel.Parent = screenGui

--createCorner(15).Parent = mainPanel

-- Header (✅ Scale)
local header = mainPanel:WaitForChild("Header")
--local header = Instance.new("Frame")
--header.Size = UDim2.new(1, 0, 0.1, 0)
--header.BackgroundColor3 = COLORS.Panel
--header.BorderSizePixel = 0
--header.Parent = mainPanel

--createCorner(15).Parent = header

local headerTitle = header:WaitForChild("HeaderTitle")
--local headerTitle = Instance.new("TextLabel")
--headerTitle.Size = UDim2.new(0.7, 0, 1, 0)
--headerTitle.Position = UDim2.new(0.05, 0, 0, 0)
--headerTitle.BackgroundTransparency = 1
--headerTitle.Font = Enum.Font.GothamBold
--headerTitle.Text = "DANCE"
--headerTitle.TextColor3 = COLORS.Text
--headerTitle.TextSize = 16  -- ✅ FIXED SIZE
---- headerTitle.TextScaled = true  -- ❌ HAPUS INI
--headerTitle.TextXAlignment = Enum.TextXAlignment.Left
--headerTitle.Parent = header


local closeBtn = header:WaitForChild("CloseButton")
--local closeBtn = Instance.new("TextButton")
--closeBtn.Size = UDim2.new(0.12, 0, 0.8, 0)
--closeBtn.Position = UDim2.new(0.85, 0, 0.1, 0)
--closeBtn.BackgroundColor3 = COLORS.Button
--closeBtn.BorderSizePixel = 0
--closeBtn.Text = "✕"
--closeBtn.Font = Enum.Font.GothamBold
--closeBtn.TextSize = 18  -- ✅ FIXED SIZE
---- closeBtn.TextScaled = true  -- ❌ HAPUS INI
--closeBtn.TextColor3 = COLORS.Text
--closeBtn.Parent = header


--createCorner(8).Parent = closeBtn

-- Tab Frame (✅ Scale)
local tabFrame = mainPanel:WaitForChild("Category")
--local tabFrame = Instance.new("Frame")
--tabFrame.Size = UDim2.new(0.94, 0, 0.07, 0)
--tabFrame.Position = UDim2.new(0.03, 0, 0.12, 0)
--tabFrame.BackgroundTransparency = 1
--tabFrame.Parent = mainPanel

local allTab = tabFrame:WaitForChild("AllButton")
--local allTab = Instance.new("TextButton")
--allTab.Size = UDim2.new(0.48, 0, 1, 0)
--allTab.BackgroundColor3 = COLORS.Accent
--allTab.BorderSizePixel = 0
--allTab.Text = "All"
--allTab.Font = Enum.Font.GothamBold
--allTab.TextSize = 13  -- ✅ FIXED SIZE
---- allTab.TextScaled = true  -- ❌ HAPUS INI
--allTab.TextColor3 = COLORS.Text
--allTab.AutoButtonColor = false
--allTab.Parent = tabFrame

--createCorner(6).Parent = allTab

local favTab = tabFrame:WaitForChild("FavoritesButton")
local danceTab = tabFrame:WaitForChild("DanceButton")
local poseTab = tabFrame:WaitForChild("PoseButton")
--local favTab = Instance.new("TextButton")
--favTab.Size = UDim2.new(0.48, 0, 1, 0)
--favTab.Position = UDim2.new(0.52, 0, 0, 0)
--favTab.BackgroundColor3 = COLORS.Button
--favTab.BorderSizePixel = 0
--favTab.Text = "Favorites"
--favTab.Font = Enum.Font.GothamBold
--favTab.TextSize = 13  -- ✅ FIXED SIZE (SAMA dengan All)
---- favTab.TextScaled = true  -- ❌ HAPUS INI
--favTab.TextColor3 = COLORS.Text
--favTab.AutoButtonColor = false
--favTab.Parent = tabFrame


--createCorner(6).Parent = favTab

-- Search Frame (✅ Scale)
--local searchFrame = Instance.new("Frame")
--searchFrame.Size = UDim2.new(0.94, 0, 0.07, 0)
--searchFrame.Position = UDim2.new(0.03, 0, 0.21, 0)
--searchFrame.BackgroundColor3 = COLORS.Panel
--searchFrame.BorderSizePixel = 0
--searchFrame.Parent = mainPanel

--createCorner(6).Parent = searchFrame

--local searchIcon = Instance.new("TextLabel")
--searchIcon.Size = UDim2.new(0.1, 0, 1, 0)
--searchIcon.BackgroundTransparency = 1
--searchIcon.Font = Enum.Font.GothamBold
--searchIcon.Text = "🔍"
--searchIcon.TextColor3 = COLORS.TextSecondary
--searchIcon.TextSize = 14  -- ✅ FIXED SIZE
---- searchIcon.TextScaled = true  -- ❌ HAPUS INI
--searchIcon.Parent = searchFrame


--local searchBox = Instance.new("TextBox")
--searchBox.Size = UDim2.new(0.8, 0, 1, 0)
--searchBox.Position = UDim2.new(0.1, 0, 0, 0)
--searchBox.BackgroundTransparency = 1
--searchBox.Font = Enum.Font.Gotham
--searchBox.PlaceholderText = "Search..."
--searchBox.Text = ""
--searchBox.TextColor3 = COLORS.Text
--searchBox.TextSize = 12  -- ✅ FIXED SIZE
---- searchBox.TextScaled = true  -- ❌ HAPUS INI
--searchBox.TextXAlignment = Enum.TextXAlignment.Left
--searchBox.ClearTextOnFocus = false
--searchBox.Parent = searchFrame


--local clearSearchBtn = Instance.new("TextButton")
--clearSearchBtn.Size = UDim2.new(0.1, 0, 1, 0)
--clearSearchBtn.Position = UDim2.new(0.9, 0, 0, 0)
--clearSearchBtn.BackgroundTransparency = 1
--clearSearchBtn.Text = "✕"
--clearSearchBtn.Font = Enum.Font.GothamBold
--clearSearchBtn.TextSize = 14  -- ✅ FIXED SIZE
---- clearSearchBtn.TextScaled = true  -- ❌ HAPUS INI
--clearSearchBtn.TextColor3 = COLORS.TextSecondary
--clearSearchBtn.Visible = false
--clearSearchBtn.Parent = searchFrame


-- Scroll Frame (✅ Scale)
local scrollFrame = mainPanel:WaitForChild("ScrollPanel")
--local scrollFrame = Instance.new("ScrollingFrame")
--scrollFrame.Size = UDim2.new(0.94, 0, 0.5, 0)
--scrollFrame.Position = UDim2.new(0.03, 0, 0.3, 0)
--scrollFrame.BackgroundTransparency = 1
--scrollFrame.BorderSizePixel = 0
--scrollFrame.ScrollBarThickness = 4
--scrollFrame.ScrollBarImageColor3 = COLORS.Border
--scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
--scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
--scrollFrame.Parent = mainPanel

--local listLayout = Instance.new("UIListLayout")
--listLayout.Padding = UDim.new(0.015, 0)
--listLayout.SortOrder = Enum.SortOrder.LayoutOrder
--listLayout.Parent = scrollFrame

local animSlot = scrollFrame:WaitForChild("DanceCard")
animSlot.Parent = playerGui

local emptyLabel = scrollFrame:WaitForChild("EmptyCard")
--emptyLabel.Size = UDim2.new(1, 0, 0, 60)
--emptyLabel.BackgroundTransparency = 1
--emptyLabel.Font = Enum.Font.Gotham
--emptyLabel.Text = "No animations found"
--emptyLabel.TextColor3 = COLORS.TextSecondary
--emptyLabel.TextSize = 12  -- ✅ FIXED SIZE
---- emptyLabel.TextScaled = true  -- ❌ HAPUS INI
--emptyLabel.Visible = false
--emptyLabel.Parent = scrollFrame


-- Speed Control (✅ Scale)
local speedFrame = mainPanel:WaitForChild("SpeedPanel")
--local speedFrame = Instance.new("Frame")
--speedFrame.Size = UDim2.new(0.94, 0, 0.15, 0)
--speedFrame.Position = UDim2.new(0.03, 0, 0.82, 0)
--speedFrame.BackgroundColor3 = COLORS.Panel
--speedFrame.BorderSizePixel = 0
--speedFrame.Parent = mainPanel

--createCorner(8).Parent = speedFrame

local speedLabel = speedFrame:WaitForChild("TextLabel")
--local speedLabel = Instance.new("TextLabel")
--speedLabel.Size = UDim2.new(1, -20, 0.35, 0)
--speedLabel.Position = UDim2.new(0, 10, 0.1, 0)
--speedLabel.BackgroundTransparency = 1
--speedLabel.Font = Enum.Font.GothamBold
--speedLabel.Text = "Speed: 1.0x"
--speedLabel.TextColor3 = COLORS.Text
--speedLabel.TextSize = 11  -- ✅ FIXED SIZE
---- speedLabel.TextScaled = true  -- ❌ HAPUS INI
--speedLabel.TextXAlignment = Enum.TextXAlignment.Left
--speedLabel.Parent = speedFrame


local speedSliderBg = speedFrame:WaitForChild("Slider")
--local speedSliderBg = Instance.new("Frame")
--speedSliderBg.Size = UDim2.new(0.9, 0, 0.15, 0)
--speedSliderBg.Position = UDim2.new(0.05, 0, 0.65, 0)
--speedSliderBg.BackgroundColor3 = COLORS.Button
--speedSliderBg.BorderSizePixel = 0
--speedSliderBg.Parent = speedFrame

--createCorner(4).Parent = speedSliderBg

local speedSlider = speedSliderBg:WaitForChild("FillBar")
--local speedSlider = Instance.new("Frame")
--speedSlider.Size = UDim2.new(0.5, 0, 1, 0)
--speedSlider.BackgroundColor3 = COLORS.Accent
--speedSlider.BorderSizePixel = 0
--speedSlider.Parent = speedSliderBg

--createCorner(4).Parent = speedSlider

local speedHandle = speedSliderBg:WaitForChild("FillCircle")
--local speedHandle = Instance.new("Frame")
--speedHandle.Size = UDim2.new(0, 12, 0, 12)
--speedHandle.Position = UDim2.new(0.5, -6, 0.5, -6)
--speedHandle.BackgroundColor3 = COLORS.Text
--speedHandle.BorderSizePixel = 0
--speedHandle.Parent = speedSliderBg

--createCorner(6).Parent = speedHandle

-- ==================== ANIMATION PLAYBACK ====================

local function playAnim(targetPlayer, animData, synchronizedPlayer)
	local currentTrack = Tracks[targetPlayer]
	if currentTrack then
		currentTrack:Stop()
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animData.AnimationId

	local animator = Animators[targetPlayer]
	if not animator then
		animator = Instance.new("Animator")
		Animators[targetPlayer] = animator
	end

	local track = animator:LoadAnimation(anim)
	track:Play()
	track:AdjustSpeed(animData.Speed or 1)

	if synchronizedPlayer then
		local syncTrack = Tracks[synchronizedPlayer]
		if syncTrack then
			track.TimePosition = syncTrack.TimePosition
		end
	end

	Tracks[targetPlayer] = track
	AnimationDatas[targetPlayer] = animData
end

local function stopAnim(targetPlayer)
	local track = Tracks[targetPlayer]
	if track then
		track:Stop()
		Tracks[targetPlayer] = nil
	end
	AnimationDatas[targetPlayer] = nil
end

local function setSpeed(targetPlayer, speed)
	local track = Tracks[targetPlayer]
	if track then
		track:AdjustSpeed(speed)
	end
end

local function OnCharacterAdded(targetPlayer, char)
	local hum = char:WaitForChild("Humanoid")
	local anim = hum:FindFirstChildOfClass("Animator")
	Animators[targetPlayer] = anim

	if AnimationDatas[targetPlayer] then
		playAnim(targetPlayer, AnimationDatas[targetPlayer])
	end
end

local function OnPlayerAdded(targetPlayer)
	if targetPlayer.Character then
		OnCharacterAdded(targetPlayer, targetPlayer.Character)
	end
	targetPlayer.CharacterAdded:Connect(function(char)
		OnCharacterAdded(targetPlayer, char)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(p)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

-- ✅ FIX: Cleanup when player leaves to prevent memory leak
Players.PlayerRemoving:Connect(function(targetPlayer)
	if Tracks[targetPlayer] then
		Tracks[targetPlayer]:Stop()
		Tracks[targetPlayer] = nil
	end
	Animators[targetPlayer] = nil
	AnimationDatas[targetPlayer] = nil
end)

StartDanceEvent.OnClientEvent:Connect(playAnim)
StopDanceEvent.OnClientEvent:Connect(stopAnim)
SetSpeedEvent.OnClientEvent:Connect(setSpeed)

-- ==================== UI FUNCTIONS ====================

local function isFavorite(title)
	return table.find(favorites, title) ~= nil
end

local function toggleFavorite(title)
	toggleFavoriteEvent:FireServer(title)

	if isFavorite(title) then
		local index = table.find(favorites, title)
		table.remove(favorites, index)
	else
		table.insert(favorites, title)
	end
end

local function playAnimation(animData)
	StartDanceEvent:FireServer(animData)
	currentAnimation = animData
end

local function stopAnimation()
	StopDanceEvent:FireServer()
	currentAnimation = nil
end

local function updateSpeedLabel()
	speedLabel.Text = string.format("Speed: %.1fx", animationSpeed)
	SetSpeedEvent:FireServer(animationSpeed)
end

local function createAnimItem(animData)
	local isPlaying = currentAnimation and currentAnimation.Title == animData.Title

	local frame = animSlot:Clone()
	--local frame = Instance.new("Frame")
	--frame.Size = UDim2.new(1, 0, 0, 45)
	--frame.BackgroundColor3 = isPlaying and COLORS.Accent or COLORS.Panel
	--frame.BorderSizePixel = 0
	frame.Parent = scrollFrame

	--createCorner(6).Parent = frame
	
	local favoritedColor = Color3.fromHex("#fd0a73")
	local nonFavoritedColor = Color3.fromHex("#8badab")
	
	frame:WaitForChild("UIStroke").Transparency = isPlaying and 0 or 1

	local titleLabel = frame:WaitForChild("DanceInfo"):WaitForChild("DanceTitle")
	--local titleLabel = Instance.new("TextLabel")
	--titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
	--titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
	--titleLabel.BackgroundTransparency = 1
	--titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = animData.Title
	--titleLabel.TextColor3 = COLORS.Text
	--titleLabel.TextSize = 13  -- ✅ FIXED SIZE
	---- titleLabel.TextScaled = true  -- ❌ HAPUS INI
	--titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	--titleLabel.Parent = frame


	local favBtn = frame:WaitForChild("FavoriteButton")
	--local favBtn = Instance.new("TextButton")
	--favBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
	--favBtn.Position = UDim2.new(0.8, 0, 0.15, 0)
	--favBtn.BackgroundColor3 = COLORS.Button
	--favBtn.BorderSizePixel = 0
	--favBtn.Text = isFavorite(animData.Title) and "♥" or "♡"
	--favBtn.Font = Enum.Font.GothamBold
	--favBtn.TextSize = 16  -- ✅ FIXED SIZE
	---- favBtn.TextScaled = true  -- ❌ HAPUS INI
	--favBtn.TextColor3 = isFavorite(animData.Title) and Color3.fromRGB(255, 100, 100) or COLORS.TextSecondary
	--favBtn.AutoButtonColor = false
	--favBtn.Parent = 
	local favIcon = favBtn:WaitForChild("ImageLabel")
	favIcon.ImageColor3 = isFavorite(animData.Title) and favoritedColor or nonFavoritedColor


	--createCorner(4).Parent = favBtn

	favBtn.MouseButton1Click:Connect(function()
		toggleFavorite(animData.Title)
		updateAnimList()
	end)

	--local clickBtn = Instance.new("TextButton")
	--clickBtn.Size = UDim2.new(0.75, 0, 1, 0)
	--clickBtn.BackgroundTransparency = 1
	--clickBtn.Text = ""
	--clickBtn.Parent = frame

	frame.MouseButton1Click:Connect(function()
		if isPlaying then
			stopAnimation()
		else
			playAnimation(animData)
		end
		updateAnimList()
	end)
end

local currentTab = "All"
function updateAnimList()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		local destroyed = false
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local animsToShow = {}

	if currentTab == "All" then
		animsToShow = DanceConfig.Animations
	elseif currentTab == "Dance" then
		for _, anim in ipairs(DanceConfig.Animations) do
			if anim.Category == "Dance" then
				table.insert(animsToShow, anim)
			end
		end
	elseif currentTab == "Pose" then
		for _, anim in ipairs(DanceConfig.Animations) do
			if anim.Category == "Pose" then
				table.insert(animsToShow, anim)
			end
		end
	else
		for _, anim in ipairs(DanceConfig.Animations) do
			if isFavorite(anim.Title) then
				table.insert(animsToShow, anim)
			end
		end
	end

	if searchQuery ~= "" then
		local filtered = {}
		local lower = string.lower(searchQuery)
		for _, anim in ipairs(animsToShow) do
			if string.find(string.lower(anim.Title), lower, 1, true) or string.find(anim.AnimationId, searchQuery, 1, true) then
				table.insert(filtered, anim)
			end
		end
		animsToShow = filtered
	end

	if #animsToShow == 0 then
		emptyLabel.Visible = true
		--emptyLabel.Text = searchQuery ~= "" and "Animasi tidak ditemukan" or "No animations found"
	else
		emptyLabel.Visible = false
		for _, anim in ipairs(animsToShow) do
			createAnimItem(anim)
		end
	end
end

-- ==================== DRAG ====================
local function makeDraggable(frame, handle)
	local dragging = false
	local dragInput, mousePos, framePos

	handle.InputBegan:Connect(function(input)
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

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			local viewport = workspace.CurrentCamera.ViewportSize
			frame.Position = UDim2.new(
				framePos.X.Scale + (delta.X / viewport.X),
				0,
				framePos.Y.Scale + (delta.Y / viewport.Y),
				0
			)
		end
	end)
end

makeDraggable(mainPanel, header)

-- ==================== EVENTS ====================
-- Note: closeBtn click is handled at the bottom with closeDancePanel()

allTab.MouseButton1Click:Connect(function()
	--allTab.BackgroundColor3 = COLORS.Accent
	--favTab.BackgroundColor3 = COLORS.Button
	favTab:FindFirstChild("UIStroke").Transparency = 1
	danceTab:FindFirstChild("UIStroke").Transparency = 1
	poseTab:FindFirstChild("UIStroke").Transparency = 1
	allTab:FindFirstChild("UIStroke").Transparency = 0
	currentTab = "All"
	updateAnimList()
end)

favTab.MouseButton1Click:Connect(function()
	favTab:FindFirstChild("UIStroke").Transparency = 0
	danceTab:FindFirstChild("UIStroke").Transparency = 1
	poseTab:FindFirstChild("UIStroke").Transparency = 1
	allTab:FindFirstChild("UIStroke").Transparency = 1
	currentTab = "Favorite"
	updateAnimList()
end)
danceTab.MouseButton1Click:Connect(function()
	favTab:FindFirstChild("UIStroke").Transparency = 1
	danceTab:FindFirstChild("UIStroke").Transparency = 0
	poseTab:FindFirstChild("UIStroke").Transparency = 1
	allTab:FindFirstChild("UIStroke").Transparency = 1
	currentTab = "Dance"
	updateAnimList()
end)
poseTab.MouseButton1Click:Connect(function()
	favTab:FindFirstChild("UIStroke").Transparency = 1
	danceTab:FindFirstChild("UIStroke").Transparency = 1
	poseTab:FindFirstChild("UIStroke").Transparency = 0
	allTab:FindFirstChild("UIStroke").Transparency = 1
	currentTab = "Pose"
	updateAnimList()
end)

--searchBox:GetPropertyChangedSignal("Text"):Connect(function()
--	searchQuery = searchBox.Text
--	clearSearchBtn.Visible = searchQuery ~= ""
--	updateAnimList()
--end)

--clearSearchBtn.MouseButton1Click:Connect(function()
--	searchBox.Text = ""
--	searchQuery = ""
--	clearSearchBtn.Visible = false
--	updateAnimList()
--end)

-- Speed Slider
local draggingSpeed = false

speedSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
		local mouseX = UserInputService:GetMouseLocation().X
		local posX = speedSliderBg.AbsolutePosition.X
		local sizeX = speedSliderBg.AbsoluteSize.X
		local rel = math.clamp((mouseX - posX) / sizeX, 0, 1)

		speedSlider.Size = UDim2.new(rel, 0, 1, 0)
		speedHandle.Position = UDim2.new(rel, -6, 0.5, -6)

		animationSpeed = 0.1 + (rel * 3.9)
	end
end)

speedHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = false
		updateSpeedLabel()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSpeed and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mouseX = UserInputService:GetMouseLocation().X
		local posX = speedSliderBg.AbsolutePosition.X
		local sizeX = speedSliderBg.AbsoluteSize.X
		local rel = math.clamp((mouseX - posX) / sizeX, 0, 1)

		speedSlider.Size = UDim2.new(rel, 0, 1, 0)
		speedHandle.Position = UDim2.new(rel, -6, 0.5, -6)

		animationSpeed = 0.1 + (rel * 3.9)
	end
end)

-- ==================== HUD BUTTON (LEFT SIDE) ====================
local isPanelOpen = false

local function openDancePanel()
	if isPanelOpen then return end
	isPanelOpen = true
	screenGui.Enabled = true
	mainPanel.Visible = true

	-- ✅ LOAD FAVORITES
	task.spawn(function()
		task.wait(2)
		local success, loaded = pcall(function()
			return getFavoritesFunc:InvokeServer()
		end)

		if success and loaded then
			favorites = loaded
			print(string.format("💃 [DANCE CLIENT] Loaded %d favorites", #favorites))
			if mainPanel.Visible then
				updateAnimList()
			end
		else
			warn("⚠️ [DANCE CLIENT] Failed to load favorites")
		end
	end)

	updateAnimList()
end

local function closeDancePanel()
	if not isPanelOpen then return end
	isPanelOpen = false
	screenGui.Enabled = false
	mainPanel.Visible = false
end

-- Create HUD Button on Left side
local danceButton = HUDButton.Create({
	Side = "Left",
	Icon = "rbxassetid://128874172331140",
	Text = "Dance",
	Name = "DanceButton",
	OnClick = function()
		if isPanelOpen then
			closeDancePanel()
		else
			openDancePanel()
		end
	end
})

-- ✅ Update close button to also update state
closeBtn.MouseButton1Click:Connect(function()
	closeDancePanel()
end)

print("✅ [DANCE CLIENT] System loaded")
