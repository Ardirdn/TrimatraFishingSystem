--[[
    DONATE CLIENT (ORGANIZED UI WITH SCALE-BASED LAYOUT)
    Place in StarterPlayerScripts/DonateClient
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDButtonHelper = require(script.Parent:WaitForChild("HUDButtonHelper"))
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("DonateRemotes")
local getDonateDataFunc = remoteFolder:WaitForChild("GetDonateData")
local purchaseDonationEvent = remoteFolder:WaitForChild("PurchaseDonation")

local COLORS = DonateConfig.Colors

local donationData = {
	TotalDonations = 0,
	HasDonaturTitle = false
}

-- Helper functions
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, radius)
	return corner
end

local function createScaledCorner(scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	return corner
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

local function createTextSizeConstraint(minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize
	constraint.MaxTextSize = maxSize
	return constraint
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DonateGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Main Panel Container (untuk aspect ratio)
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0.55, 0, 0.85, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = screenGui

-- Aspect Ratio Constraint untuk main container
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1.3
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = mainContainer

-- Main Panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(1, 0, 1, 0)
mainPanel.Position = UDim2.new(0, 0, 0, 0)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
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

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.08, 0)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = mainPanel

createScaledCorner(0.15).Parent = header

-- Header Padding
local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0.02, 0)
headerPadding.PaddingRight = UDim.new(0.02, 0)
headerPadding.Parent = header

-- Header Title
local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.25, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "💝 DONATE"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

createTextSizeConstraint(12, 24).Parent = headerTitle

-- Donation Progress Frame
local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
progressFrame.Position = UDim2.new(0.35, 0, 0.5, 0)
progressFrame.AnchorPoint = Vector2.new(0, 0.5)
progressFrame.BackgroundColor3 = COLORS.Background
progressFrame.BorderSizePixel = 0
progressFrame.Parent = header

createScaledCorner(0.2).Parent = progressFrame

-- Progress Padding
local progressPadding = Instance.new("UIPadding")
progressPadding.PaddingLeft = UDim.new(0.05, 0)
progressPadding.PaddingRight = UDim.new(0.05, 0)
progressPadding.Parent = progressFrame

local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(1, 0, 1, 0)
progressLabel.Position = UDim2.new(0, 0, 0, 0)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.GothamBold
progressLabel.Text = "R$0 / R$1000"
progressLabel.TextColor3 = COLORS.Premium
progressLabel.TextScaled = true
progressLabel.TextXAlignment = Enum.TextXAlignment.Center
progressLabel.Parent = progressFrame

createTextSizeConstraint(10, 18).Parent = progressLabel

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.06, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.94, 0, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = COLORS.Text
closeBtn.Parent = header

createScaledCorner(0.25).Parent = closeBtn
createTextSizeConstraint(14, 24).Parent = closeBtn

-- Info Text
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0.055, 0)
infoLabel.Position = UDim2.new(0, 0, 0.095, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "Terima kasih atas dukunganmu! Donasi R$1000+ akan mendapatkan title 'Donatur' 💎"
infoLabel.TextColor3 = COLORS.TextSecondary
infoLabel.TextScaled = true
infoLabel.TextWrapped = true
infoLabel.Parent = mainPanel

createTextSizeConstraint(10, 16).Parent = infoLabel

-- Scroll Frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 0.82, 0)
scrollFrame.Position = UDim2.new(0, 0, 0.16, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = COLORS.Border
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainPanel

-- Scroll Frame Padding
local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0.01, 0)
scrollPadding.PaddingRight = UDim.new(0.02, 0)
scrollPadding.PaddingTop = UDim.new(0.02, 0)
scrollPadding.PaddingBottom = UDim.new(0.03, 0)
scrollPadding.Parent = scrollFrame

-- Vertical List Layout untuk cards
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

-- Create Donation Cards (Thin Horizontal Style)
local function createDonationCard(packageData, index)
	-- Card container - thin horizontal
	local card = Instance.new("Frame")
	card.Name = packageData.Title
	card.Size = UDim2.new(1, 0, 0, 55)
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.ClipsDescendants = true
	card.Parent = scrollFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- Subtle border
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = COLORS.Border
	cardStroke.Thickness = 1
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = card

	-- Left accent bar (warna tier)
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = packageData.Color
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 8)
	accentCorner.Parent = accentBar

	-- Tier Name (left side)
	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.new(0.25, 0, 1, 0)
	tierLabel.Position = UDim2.new(0, 15, 0, 0)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Font = Enum.Font.GothamBold
	tierLabel.Text = packageData.Title
	tierLabel.TextColor3 = packageData.Color
	tierLabel.TextScaled = true
	tierLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierLabel.Parent = card
	
	createTextSizeConstraint(10, 18).Parent = tierLabel

	-- Description (center-left)
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.25, 0, 1, 0)
	descLabel.Position = UDim2.new(0.22, 0, 0, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = packageData.Description
	descLabel.TextColor3 = COLORS.TextSecondary
	descLabel.TextScaled = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = card
	
	createTextSizeConstraint(8, 14).Parent = descLabel

	-- Price (center-right)
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 1, 0)
	priceLabel.Position = UDim2.new(0.5, 0, 0, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.Text = "R$" .. tostring(packageData.Amount)
	priceLabel.TextColor3 = COLORS.Premium
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Center
	priceLabel.Parent = card
	
	createTextSizeConstraint(12, 22).Parent = priceLabel

	-- Donate Button (right side)
	local donateBtn = Instance.new("TextButton")
	donateBtn.Size = UDim2.new(0.22, 0, 0.65, 0)
	donateBtn.Position = UDim2.new(0.75, 0, 0.5, 0)
	donateBtn.AnchorPoint = Vector2.new(0, 0.5)
	donateBtn.BackgroundColor3 = packageData.Color
	donateBtn.BackgroundTransparency = 0.15
	donateBtn.BorderSizePixel = 0
	donateBtn.Font = Enum.Font.GothamBold
	donateBtn.Text = "Donate"
	donateBtn.TextColor3 = COLORS.Text
	donateBtn.TextScaled = true
	donateBtn.AutoButtonColor = false
	donateBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = donateBtn
	
	createTextSizeConstraint(10, 16).Parent = donateBtn

	-- Hover effect
	local originalColor = packageData.Color
	donateBtn.MouseEnter:Connect(function()
		TweenService:Create(donateBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0,
			BackgroundColor3 = originalColor
		}):Play()
		TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.ButtonHover}):Play()
	end)

	donateBtn.MouseLeave:Connect(function()
		TweenService:Create(donateBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.15,
			BackgroundColor3 = originalColor
		}):Play()
		TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Panel}):Play()
	end)

	-- Click handler
	donateBtn.MouseButton1Click:Connect(function()
		if packageData.ProductId == 0 then
			game.StarterGui:SetCore("SendNotification", {
				Title = "Donate",
				Text = "Product ID belum di-set! Hubungi admin.",
				Duration = 3,
			})
		else
			purchaseDonationEvent:FireServer(packageData.ProductId)
		end
	end)
end

-- Update display
local function updateDisplay()
	progressLabel.Text = string.format("R$%d / R$%d", donationData.TotalDonations, DonateConfig.DonationThreshold)

	if donationData.HasDonaturTitle then
		infoLabel.Text = "✅ Kamu sudah memiliki title 'Donatur'! Terima kasih atas dukunganmu! 💎"
		infoLabel.TextColor3 = COLORS.Success
	end
end

-- Refresh data
local function refreshData()
	local success, data = pcall(function()
		return getDonateDataFunc:InvokeServer()
	end)

	if success and data then
		donationData = data
		updateDisplay()
	end
end

-- Show/Hide panel
-- Panel state
local isPanelOpen = false

local function showPanel()
	PanelManager:Open("DonatePanel") -- This closes other panels first
	isPanelOpen = true
	screenGui.Enabled = true
	mainPanel.Visible = true
	mainPanel.Size = UDim2.new(0.95, 0, 0.95, 0)
	mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	
	-- Animate panel masuk
	mainPanel.Size = UDim2.new(0.9, 0, 0.9, 0)
	TweenService:Create(mainPanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()
	
	refreshData()
end

local function hidePanel()
	isPanelOpen = false
	TweenService:Create(mainPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0.9, 0, 0.9, 0)
	}):Play()
	
	task.delay(0.2, function()
		mainPanel.Visible = false
		screenGui.Enabled = false
	end)
	PanelManager:Close("DonatePanel")
end

-- Register with PanelManager
PanelManager:Register("DonatePanel", hidePanel)

-- Event connections
closeBtn.MouseButton1Click:Connect(hidePanel)

-- Close button hover effect
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 60, 60)}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Button}):Play()
end)

-- Create all donation cards
for index, package in ipairs(DonateConfig.Packages) do
	createDonationCard(package, index)
end

-- Draggable
local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput, mousePos, framePos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = mainContainer.Position

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

			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			mainContainer.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,
				framePos.Y.Scale + deltaScaleY,
				0
			)
		end
	end)
end

makeDraggable(mainPanel, header)

-- HUD Button (Left side)
local donateButton = HUDButtonHelper.Create({
	Side = "Left",
	Icon = "rbxassetid://139364265261477",
	Text = "Donation",
	Name = "DonationButton",
	OnClick = function()
		if isPanelOpen then
			hidePanel()
		else
			showPanel()
		end
	end
})

print("✅ [DONATE CLIENT] Organized UI System loaded")
