--[[
    CAMERA CINEMATIC CLIENT
    Place in StarterPlayerScripts
    
    Allows players to take cinematic screenshots by hiding UI
    - Hide all UI elements
    - Optional camera controls for better angles
    - Screenshot mode indicator
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State
local isCinematicMode = false
local hiddenGuis = {}
local originalCoreGuiState = {}

-- ==================== CREATE SCREEN GUI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CameraCinematicGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100 -- High priority so button always visible
screenGui.Parent = playerGui

-- ==================== USE HUD BUTTON TEMPLATE (RIGHT SIDE) ====================

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local hudGui = playerGui:WaitForChild("HUD", 10)
local rightFrame = hudGui and hudGui:FindFirstChild("Right")
local buttonTemplate = rightFrame and rightFrame:FindFirstChild("ButtonTemplate")

local floatingButton = nil
local buttonText = nil
local buttonContainer = nil

if buttonTemplate then
	-- ✅ Hide the original template
	buttonTemplate.Visible = false
	
	-- Clone the template
	buttonContainer = buttonTemplate:Clone()
	buttonContainer.Name = "PhotoButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 3 -- Third button on right
	buttonContainer.BackgroundTransparency = 1 -- ✅ Transparent container
	buttonContainer.Parent = rightFrame
	
	-- Get references
	floatingButton = buttonContainer:FindFirstChild("ImageButton")
	buttonText = buttonContainer:FindFirstChild("TextLabel")
	
	-- Set button properties
	if floatingButton then
		floatingButton.Image = "rbxassetid://139242732181104" -- Camera icon
		floatingButton.BackgroundTransparency = 1 -- ✅ Transparent button
	end
	
	if buttonText then
		buttonText.Text = "Photo"
	end
	
	print("✅ [CAMERA] Using HUD template button (Right)")
else
	-- Fallback: Create button manually if template not found
	warn("[CAMERA] HUD template not found, creating button manually")
	
	floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "CameraButton"
	floatingButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	floatingButton.Position = UDim2.new(0.99, 0, 0.6, 0)
	floatingButton.AnchorPoint = Vector2.new(1, 0)
	floatingButton.BackgroundTransparency = 1
	floatingButton.BorderSizePixel = 0
	floatingButton.Image = "rbxassetid://139242732181104"
	floatingButton.ScaleType = Enum.ScaleType.Fit
	floatingButton.Parent = screenGui
	
	buttonText = Instance.new("TextLabel")
	buttonText.Size = UDim2.new(1, 0, 0.3, 0)
	buttonText.Position = UDim2.new(0, 0, 1, 2)
	buttonText.BackgroundTransparency = 1
	buttonText.Font = Enum.Font.GothamBold
	buttonText.Text = "Photo"
	buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
	buttonText.TextScaled = true
	buttonText.Parent = floatingButton
end

-- ==================== CINEMATIC MODE INDICATOR ====================

local modeIndicator = Instance.new("TextLabel")
modeIndicator.Name = "ModeIndicator"
modeIndicator.Size = UDim2.new(0.3, 0, 0.05, 0)
modeIndicator.Position = UDim2.new(0.5, 0, 0.02, 0)
modeIndicator.AnchorPoint = Vector2.new(0.5, 0)
modeIndicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modeIndicator.BackgroundTransparency = 0.5
modeIndicator.Font = Enum.Font.GothamBold
modeIndicator.Text = "📷 PHOTO MODE - Click button again to exit"
modeIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
modeIndicator.TextScaled = true
modeIndicator.Visible = false
modeIndicator.Parent = screenGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(0, 8)
indicatorCorner.Parent = modeIndicator

local indicatorTextConstraint = Instance.new("UITextSizeConstraint")
indicatorTextConstraint.MinTextSize = 10
indicatorTextConstraint.MaxTextSize = 16
indicatorTextConstraint.Parent = modeIndicator

-- ==================== CORE GUI TYPES TO HIDE ====================

local coreGuiTypes = {
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.EmotesMenu,
}

-- ==================== FUNCTIONS ====================

local function hideAllUI()
	hiddenGuis = {}
	
	-- Hide all ScreenGuis except our own
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui ~= screenGui then
			if gui.Enabled then
				table.insert(hiddenGuis, gui)
				gui.Enabled = false
			end
		end
	end
	
	-- Hide CoreGui elements
	originalCoreGuiState = {}
	for _, coreType in ipairs(coreGuiTypes) do
		local success, enabled = pcall(function()
			return StarterGui:GetCoreGuiEnabled(coreType)
		end)
		if success then
			originalCoreGuiState[coreType] = enabled
			if enabled then
				pcall(function()
					StarterGui:SetCoreGuiEnabled(coreType, false)
				end)
			end
		end
	end
	
	print("📷 [CAMERA] Hid all UI for photo mode")
end

local function showAllUI()
	-- Restore ScreenGuis
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then
			gui.Enabled = true
		end
	end
	hiddenGuis = {}
	
	-- Restore CoreGui elements
	for coreType, wasEnabled in pairs(originalCoreGuiState) do
		if wasEnabled then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(coreType, true)
			end)
		end
	end
	originalCoreGuiState = {}
	
	print("📷 [CAMERA] Restored all UI")
end

local function toggleCinematicMode()
	isCinematicMode = not isCinematicMode
	
	if isCinematicMode then
		hideAllUI()
		modeIndicator.Visible = true
		if floatingButton then
			floatingButton.ImageColor3 = Color3.fromRGB(100, 255, 100) -- Green tint when active
		end
		if buttonText then
			buttonText.TextColor3 = Color3.fromRGB(100, 255, 100)
		end
		
		-- Hide indicator after 3 seconds
		task.delay(3, function()
			if isCinematicMode then
				TweenService:Create(modeIndicator, TweenInfo.new(0.5), {
					BackgroundTransparency = 1,
					TextTransparency = 1
				}):Play()
			end
		end)
	else
		showAllUI()
		modeIndicator.Visible = false
		modeIndicator.BackgroundTransparency = 0.5
		modeIndicator.TextTransparency = 0
		if floatingButton then
			floatingButton.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Normal color
		end
		if buttonText then
			buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- ==================== BUTTON CLICK ====================

if floatingButton then
	floatingButton.MouseButton1Click:Connect(function()
		toggleCinematicMode()
	end)
end

-- ==================== KEYBOARD SHORTCUT ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Press P for Photo mode
	if input.KeyCode == Enum.KeyCode.P then
		toggleCinematicMode()
	end
	
	-- Press Escape to exit photo mode
	if input.KeyCode == Enum.KeyCode.Escape and isCinematicMode then
		toggleCinematicMode()
	end
end)

-- ==================== CLEANUP ON CHARACTER RESPAWN ====================

player.CharacterAdded:Connect(function()
	if isCinematicMode then
		-- Exit cinematic mode on respawn
		isCinematicMode = false
		showAllUI()
		modeIndicator.Visible = false
		floatingButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

print("✅ [CAMERA CINEMATIC] Loaded - Press P or click button for photo mode")
