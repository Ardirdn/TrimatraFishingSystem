--[[
    CINEMATIC CAMERA CLIENT
    Place in StarterPlayerScripts
    
    Features:
    - TopbarPlus icon
    - Confirmation dialog
    - Exit instructions (PC: Space, Mobile: Button)
    - Full Android support with intuitive controls
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDButtonHelper = require(script.Parent:WaitForChild("HUDButtonHelper"))
local Freecam = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Freecam"))

local spaceConnection = nil -- Tambahkan di bagian atas bersama variable lain

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isActive = false

-- ==================== COLORS ====================
local COLORS = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Button = Color3.fromRGB(35, 35, 38),
	ButtonHover = Color3.fromRGB(45, 45, 48),
	Accent = Color3.fromRGB(70, 130, 255),
	Success = Color3.fromRGB(67, 181, 129),
	Danger = Color3.fromRGB(237, 66, 69),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Border = Color3.fromRGB(50, 50, 55),
}

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

-- ==================== CREATE MAIN GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CinematicCameraGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 200
screenGui.Enabled = false
screenGui.Parent = playerGui

-- ==================== CONFIRMATION DIALOG ====================
local confirmationFrame = Instance.new("Frame")
confirmationFrame.Name = "ConfirmationDialog"
confirmationFrame.Size = UDim2.new(0, 400, 0, 200)
confirmationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
confirmationFrame.BackgroundColor3 = COLORS.Background
confirmationFrame.BorderSizePixel = 0
confirmationFrame.Visible = false
confirmationFrame.Parent = screenGui

createCorner(15).Parent = confirmationFrame
createStroke(COLORS.Border, 2).Parent = confirmationFrame

-- Blur background
local blurFrame = Instance.new("Frame")
blurFrame.Name = "BlurBackground"
blurFrame.Size = UDim2.new(1, 0, 1, 0)
blurFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blurFrame.BackgroundTransparency = 0.5
blurFrame.BorderSizePixel = 0
blurFrame.Visible = false
blurFrame.ZIndex = confirmationFrame.ZIndex - 1
blurFrame.Parent = screenGui

-- Icon
local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(0, 60, 0, 60)
iconLabel.Position = UDim2.new(0.5, 0, 0, 25)
iconLabel.AnchorPoint = Vector2.new(0.5, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Font = Enum.Font.GothamBold
iconLabel.Text = "📹"
iconLabel.TextSize = 40
iconLabel.TextColor3 = COLORS.Accent
iconLabel.Parent = confirmationFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 30)
titleLabel.Position = UDim2.new(0, 20, 0, 90)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Nyalakan Cinematic Camera?"
titleLabel.TextSize = 16
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = confirmationFrame

-- Button Container
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, -40, 0, 45)
buttonContainer.Position = UDim2.new(0, 20, 1, -65)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = confirmationFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.Padding = UDim.new(0, 10)
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.Parent = buttonContainer

-- Cancel Button
local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0, 165, 1, 0)
cancelBtn.BackgroundColor3 = COLORS.Button
cancelBtn.BorderSizePixel = 0
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.Text = "Batalkan"
cancelBtn.TextSize = 14
cancelBtn.TextColor3 = COLORS.Text
cancelBtn.AutoButtonColor = false
cancelBtn.Parent = buttonContainer

createCorner(8).Parent = cancelBtn

-- Confirm Button
local confirmBtn = Instance.new("TextButton")
confirmBtn.Size = UDim2.new(0, 165, 1, 0)
confirmBtn.BackgroundColor3 = COLORS.Accent
confirmBtn.BorderSizePixel = 0
confirmBtn.Font = Enum.Font.GothamBold
confirmBtn.Text = "Ya"
confirmBtn.TextSize = 14
confirmBtn.TextColor3 = COLORS.Text
confirmBtn.AutoButtonColor = false
confirmBtn.Parent = buttonContainer

createCorner(8).Parent = confirmBtn

-- ==================== EXIT INSTRUCTION (PC) ====================
local exitInstruction = Instance.new("Frame")
exitInstruction.Name = "ExitInstruction"
exitInstruction.Size = UDim2.new(0, 350, 0, 50)
exitInstruction.Position = UDim2.new(0.5, 0, 1, -70)
exitInstruction.AnchorPoint = Vector2.new(0.5, 0)
exitInstruction.BackgroundColor3 = COLORS.Background
exitInstruction.BackgroundTransparency = 0.3
exitInstruction.BorderSizePixel = 0
exitInstruction.Visible = false
exitInstruction.Parent = screenGui

createCorner(10).Parent = exitInstruction

local instructionText = Instance.new("TextLabel")
instructionText.Size = UDim2.new(1, 0, 1, 0)
instructionText.BackgroundTransparency = 1
instructionText.Font = Enum.Font.GothamBold
instructionText.Text = "⌨️ Tekan SPACE untuk keluar dari Cinematic Camera"
instructionText.TextSize = 14
instructionText.TextColor3 = COLORS.Text
instructionText.TextStrokeTransparency = 0.5
instructionText.Parent = exitInstruction

-- ==================== EXIT BUTTON (MOBILE) ====================
local mobileExitBtn = Instance.new("TextButton")
mobileExitBtn.Name = "MobileExitButton"
mobileExitBtn.Size = UDim2.new(0, 100, 0, 50)
mobileExitBtn.Position = UDim2.new(1, -120, 1, -70)
mobileExitBtn.BackgroundColor3 = COLORS.Danger
mobileExitBtn.BorderSizePixel = 0
mobileExitBtn.Font = Enum.Font.GothamBold
mobileExitBtn.Text = "Keluar"
mobileExitBtn.TextSize = 16
mobileExitBtn.TextColor3 = COLORS.Text
mobileExitBtn.Visible = false
mobileExitBtn.ZIndex = 999
mobileExitBtn.Parent = screenGui

createCorner(10).Parent = mobileExitBtn
createStroke(Color3.fromRGB(200, 50, 50), 2).Parent = mobileExitBtn

-- ==================== FUNCTIONS ====================

local function showConfirmation()
	screenGui.Enabled = true
	blurFrame.Visible = true
	confirmationFrame.Visible = true

	-- Animation
	confirmationFrame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(confirmationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 400, 0, 200)
	}):Play()
end

local function hideConfirmation()
	local tween = TweenService:Create(confirmationFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		confirmationFrame.Visible = false
		blurFrame.Visible = false
		screenGui.Enabled = false
	end)
end

local function stopCinematicCamera()
	if not isActive then return end

	Freecam:Stop()
	isActive = false
	exitInstruction.Visible = false
	mobileExitBtn.Visible = false
	screenGui.Enabled = false

	-- ✅ Disconnect space listener
	if spaceConnection then
		spaceConnection:Disconnect()
		spaceConnection = nil
	end
end


local function startCinematicCamera()
	if isActive then return end
	isActive = true

	hideConfirmation()

	-- Start freecam
	Freecam:Start(function()
		-- Callback when freecam ends
		isActive = false
		exitInstruction.Visible = false
		mobileExitBtn.Visible = false
		screenGui.Enabled = false

		-- ✅ Disconnect space listener
		if spaceConnection then
			spaceConnection:Disconnect()
			spaceConnection = nil
		end
	end)

	-- ✅ Listen for Space key press
	if not isMobile then
		spaceConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end

			if input.KeyCode == Enum.KeyCode.Space then
				stopCinematicCamera()
			end
		end)
	end

	-- Show exit UI
	task.wait(0.3)
	screenGui.Enabled = true

	if isMobile then
		mobileExitBtn.Visible = true
		-- Fade in animation
		mobileExitBtn.BackgroundTransparency = 1
		TweenService:Create(mobileExitBtn, TweenInfo.new(0.3), {
			BackgroundTransparency = 0
		}):Play()
	else
		exitInstruction.Visible = true
		-- Slide up animation
		exitInstruction.Position = UDim2.new(0.5, 0, 1, 0)
		TweenService:Create(exitInstruction, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, 0, 1, -70)
		}):Play()
	end
end

-- ==================== EVENT CONNECTIONS ====================

cancelBtn.MouseButton1Click:Connect(function()
	hideConfirmation()
end)

confirmBtn.MouseButton1Click:Connect(function()
	startCinematicCamera()
end)

mobileExitBtn.MouseButton1Click:Connect(function()
	stopCinematicCamera()
end)

-- Hover effects
local function addHoverEffect(button, normalColor, hoverColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

addHoverEffect(cancelBtn, COLORS.Button, COLORS.ButtonHover)
addHoverEffect(confirmBtn, COLORS.Accent, Color3.fromRGB(90, 150, 255))
addHoverEffect(mobileExitBtn, COLORS.Danger, Color3.fromRGB(255, 80, 80))

local freecamButton = HUDButtonHelper.Create({
	Side = "Right",
	Name = "FreecamButton",
	Icon = "rbxassetid://84135978863201",
	Text = "Freecam",
	OnClick = function()
		-- Toggle behavior: if dialog is visible, hide it; otherwise show it
		if confirmationFrame.Visible then
			hideConfirmation()
		else
			showConfirmation()
		end
	end
})

print("✅ [CINEMATIC CAMERA] Client loaded (HUD Template style)")