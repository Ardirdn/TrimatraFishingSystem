--[[
    CHECKPOINT CLIENT v3
    Uses HUD template buttons instead of generated UI
    Place in StarterPlayerScripts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ CONFIG
local CONFIG = {
	SHOW_CHECKPOINT_BUTTON = true,
}

if not CONFIG.SHOW_CHECKPOINT_BUTTON then
	print("[CHECKPOINT CLIENT] Button hidden by config")
	return
end

-- Wait for CheckpointRemotes
local checkpointRemotes = ReplicatedStorage:WaitForChild("CheckpointRemotes", 30)
if not checkpointRemotes then
	warn("[CHECKPOINT CLIENT] CheckpointRemotes not found!")
	return
end

local teleportToBasecamp = checkpointRemotes:WaitForChild("TeleportToBasecamp", 10)
local skipCheckpoint = checkpointRemotes:WaitForChild("SkipCheckpoint", 10)

if not teleportToBasecamp or not skipCheckpoint then
	warn("[CHECKPOINT CLIENT] Remote events not found!")
	return
end

-- ✅ HUD BUTTON HELPER
local HUDButtonHelper = require(script.Parent:WaitForChild("HUDButtonHelper"))

-- ✅ COLOR SCHEME
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

-- ✅ UTILITY FUNCTIONS
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

-- ✅ CREATE SCREENGUI FOR POPUP (Separate from HUD)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheckpointGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ✅ CREATE POPUP PANEL
local popupPanel = Instance.new("Frame")
popupPanel.Name = "PopupPanel"
popupPanel.Size = UDim2.new(0.25, 0, 0.35, 0)
popupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
popupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
popupPanel.BackgroundColor3 = COLORS.Background
popupPanel.BorderSizePixel = 0
popupPanel.Visible = false
popupPanel.Parent = screenGui

createCorner(12).Parent = popupPanel
createStroke(COLORS.Border, 2).Parent = popupPanel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = popupPanel

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
title.Text = "⛰️ Checkpoint Menu"
title.TextColor3 = COLORS.Text
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "✕"
closeButton.TextColor3 = COLORS.Text
closeButton.TextSize = 18
closeButton.Parent = header

createCorner(6).Parent = closeButton

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 60)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = popupPanel

-- Reset Button
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(1, 0, 0.4, 0)
resetButton.Position = UDim2.new(0, 0, 0.05, 0)
resetButton.BackgroundColor3 = COLORS.Danger
resetButton.BorderSizePixel = 0
resetButton.Text = ""
resetButton.AutoButtonColor = false
resetButton.Parent = contentContainer

createCorner(8).Parent = resetButton
createStroke(Color3.fromRGB(200, 50, 50), 2).Parent = resetButton

local resetIcon = Instance.new("TextLabel")
resetIcon.Size = UDim2.new(1, 0, 0.5, 0)
resetIcon.Position = UDim2.new(0, 0, 0.1, 0)
resetIcon.BackgroundTransparency = 1
resetIcon.Font = Enum.Font.GothamBold
resetIcon.Text = "🏕️"
resetIcon.TextColor3 = COLORS.Text
resetIcon.TextScaled = true
resetIcon.Parent = resetButton

local resetIconConstraint = Instance.new("UITextSizeConstraint")
resetIconConstraint.MaxTextSize = 40
resetIconConstraint.Parent = resetIcon

local resetText = Instance.new("TextLabel")
resetText.Size = UDim2.new(1, 0, 0.4, 0)
resetText.Position = UDim2.new(0, 0, 0.58, 0)
resetText.BackgroundTransparency = 1
resetText.Font = Enum.Font.GothamBold
resetText.Text = "RESET TO BASECAMP"
resetText.TextColor3 = COLORS.Text
resetText.TextScaled = true
resetText.Parent = resetButton

local resetTextConstraint = Instance.new("UITextSizeConstraint")
resetTextConstraint.MaxTextSize = 14
resetTextConstraint.MinTextSize = 10
resetTextConstraint.Parent = resetText

-- Skip Button
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(1, 0, 0.4, 0)
skipButton.Position = UDim2.new(0, 0, 0.55, 0)
skipButton.BackgroundColor3 = COLORS.Accent
skipButton.BorderSizePixel = 0
skipButton.Text = ""
skipButton.AutoButtonColor = false
skipButton.Parent = contentContainer

createCorner(8).Parent = skipButton
createStroke(Color3.fromRGB(70, 80, 200), 2).Parent = skipButton

local skipIcon = Instance.new("TextLabel")
skipIcon.Size = UDim2.new(1, 0, 0.5, 0)
skipIcon.Position = UDim2.new(0, 0, 0.1, 0)
skipIcon.BackgroundTransparency = 1
skipIcon.Font = Enum.Font.GothamBold
skipIcon.Text = "⚡"
skipIcon.TextColor3 = COLORS.Text
skipIcon.TextScaled = true
skipIcon.Parent = skipButton

local skipIconConstraint = Instance.new("UITextSizeConstraint")
skipIconConstraint.MaxTextSize = 40
skipIconConstraint.Parent = skipIcon

local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1, 0, 0.4, 0)
skipText.Position = UDim2.new(0, 0, 0.58, 0)
skipText.BackgroundTransparency = 1
skipText.Font = Enum.Font.GothamBold
skipText.Text = "SKIP CHECKPOINT"
skipText.TextColor3 = COLORS.Text
skipText.TextScaled = true
skipText.Parent = skipButton

local skipTextConstraint = Instance.new("UITextSizeConstraint")
skipTextConstraint.MaxTextSize = 14
skipTextConstraint.MinTextSize = 10
skipTextConstraint.Parent = skipText

-- ✅ COOLDOWN SYSTEM
local resetCooldownActive = false
local skipCooldownActive = false
local COOLDOWN_TIME = 3

-- ✅ TOGGLE PANEL
local panelOpen = false
local cpButtonRef = nil

local function togglePanel()
	panelOpen = not panelOpen

	if panelOpen then
		popupPanel.Size = UDim2.new(0, 0, 0, 0)
		popupPanel.Visible = true
		TweenService:Create(popupPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.25, 0, 0.35, 0)
		}):Play()
	else
		TweenService:Create(popupPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()

		task.delay(0.2, function()
			popupPanel.Visible = false
		end)
	end
end

-- ✅ CREATE HUD BUTTON
cpButtonRef = HUDButtonHelper.Create({
	Side = "Right",
	Name = "CheckpointButton",
	Icon = "rbxassetid://97814029463478",
	Text = "Checkpoint",
	OnClick = togglePanel
})

-- ✅ CLOSE BUTTON CLICK
closeButton.MouseButton1Click:Connect(togglePanel)

-- ✅ RESET BUTTON EVENTS
resetButton.MouseEnter:Connect(function()
	if resetCooldownActive then return end
	TweenService:Create(resetButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.DangerHover
	}):Play()
end)

resetButton.MouseLeave:Connect(function()
	if resetCooldownActive then return end
	TweenService:Create(resetButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Danger
	}):Play()
end)

-- ✅ SKIP BUTTON EVENTS
skipButton.MouseEnter:Connect(function()
	if skipCooldownActive then return end
	TweenService:Create(skipButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.AccentHover
	}):Play()
end)

skipButton.MouseLeave:Connect(function()
	if skipCooldownActive then return end
	TweenService:Create(skipButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Accent
	}):Play()
end)

-- ✅ RESET BUTTON CLICK
resetButton.MouseButton1Click:Connect(function()
	if resetCooldownActive then
		warn("[CHECKPOINT CLIENT] Reset cooldown active")
		return
	end

	resetCooldownActive = true
	local originalText = resetText.Text

	TweenService:Create(resetButton, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(150, 30, 30)
	}):Play()

	teleportToBasecamp:FireServer()
	print("[CHECKPOINT CLIENT] Reset to basecamp requested")

	for i = COOLDOWN_TIME, 1, -1 do
		resetText.Text = string.format("⏳ %ds", i)
		task.wait(1)
	end

	resetText.Text = originalText
	resetCooldownActive = false

	TweenService:Create(resetButton, TweenInfo.new(0.3), {
		BackgroundColor3 = COLORS.Danger
	}):Play()
end)

-- ✅ SKIP BUTTON CLICK
skipButton.MouseButton1Click:Connect(function()
	if skipCooldownActive then
		warn("[CHECKPOINT CLIENT] Skip cooldown active")
		return
	end

	skipCooldownActive = true
	local originalText = skipText.Text

	TweenService:Create(skipButton, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(60, 70, 180)
	}):Play()

	skipCheckpoint:FireServer()
	print("[CHECKPOINT CLIENT] Skip checkpoint requested")

	togglePanel()

	for i = COOLDOWN_TIME, 1, -1 do
		skipText.Text = string.format("⏳ %ds", i)
		task.wait(1)
	end

	skipText.Text = originalText
	skipCooldownActive = false

	TweenService:Create(skipButton, TweenInfo.new(0.3), {
		BackgroundColor3 = COLORS.Accent
	}):Play()
end)

-- ✅ ADAPTIVE SCALING FOR POPUP
local function updateScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize

	if viewportSize.X < 600 then
		popupPanel.Size = UDim2.new(0.65, 0, 0.45, 0)
	else
		popupPanel.Size = UDim2.new(0.25, 0, 0.35, 0)
	end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

print("✅ [CHECKPOINT CLIENT] UI loaded (HUD Template style)")
