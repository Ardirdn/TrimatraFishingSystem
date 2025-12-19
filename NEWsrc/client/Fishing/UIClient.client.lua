--[[
	UI CLIENT (COMBINED)
	Combines: EquipmentSystemClient + GlobalUIManager + NativeNotificationClient
	Place in StarterPlayerScripts > Fishing
	
	Handles:
	- Equipment UI for Rods & Floaters
	- Global UI visibility management (auto-hide when one UI opens)
	- Native Roblox notifications
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================================================================================
--                         SECTION: SHARED COLORS
-- ================================================================================

local COLORS = {
	Background = Color3.fromRGB(15, 25, 40),
	CardBg = Color3.fromRGB(25, 40, 60),
	CardBgDark = Color3.fromRGB(15, 25, 35),
	Accent = Color3.fromRGB(50, 150, 220),
	Success = Color3.fromRGB(80, 200, 120),
	Danger = Color3.fromRGB(255, 80, 80),
	Warning = Color3.fromRGB(255, 200, 50),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(150, 170, 190),
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 50, 100)
}

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function getRarityColor(rarity)
	return COLORS[rarity] or COLORS.Common
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ================================================================================
--                      SECTION: NATIVE NOTIFICATION CLIENT
-- ================================================================================

-- Wait for SetCore to be available
local function waitForCore()
	local success = false
	repeat
		success = pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "Test",
				Text = "Test",
				Duration = 0.01
			})
		end)
		if not success then
			task.wait(0.5)
		end
	until success
end

task.spawn(waitForCore)

-- Listen for notifications from remote folders
local function listenToRemoteFolder(folderName)
	local remoteFolder = ReplicatedStorage:WaitForChild(folderName, 10)
	if not remoteFolder then return end
	
	local notifEvent = remoteFolder:FindFirstChild("NativeNotification")
	if notifEvent and notifEvent:IsA("RemoteEvent") then
		notifEvent.OnClientEvent:Connect(function(data)
			if not data then return end
			
			pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title = data.Title or "Notification",
					Text = data.Text or data.Message or "",
					Icon = data.Icon or "",
					Duration = data.Duration or 3
				})
			end)
		end)
		print("✅ [NATIVE NOTIF] Listening to", folderName)
	end
end

task.wait(1)
listenToRemoteFolder("RodShopRemotes")
listenToRemoteFolder("FishermanShopRemotes")

print("✅ [NATIVE NOTIFICATION] Loaded")

-- ================================================================================
--                      SECTION: GLOBAL UI MANAGER
-- ================================================================================

local ManagedUIs = {
	EquipmentGUI = "MainPanel",
	FishCollectionGUI = "MainPanel",
	RodShopGUI = "MainPanel",
	FishermanShopGUI = "MainPanel",
	InventoryGUI = "MainPanel",
	RedeemGUI = "MainPanel",
	DonateGUI = "MainPanel",
	ShopGUI = "MainPanel",
}

local MusicGUIName = "MusicPlayer"
local MusicMainPanel = "MainPanel"
local MusicLibraryPanel = "MyLibraryPanel"
local MusicWidgetPanel = "WidgetPanel"
local MusicPlaylistPopup = "PlaylistPopupPanel"

local currentOpenUI = nil

local function hideAllUIs(exceptGUI)
	for guiName, panelName in pairs(ManagedUIs) do
		if guiName ~= exceptGUI then
			local gui = playerGui:FindFirstChild(guiName)
			if gui then
				local panel = gui:FindFirstChild(panelName)
				if panel and panel:IsA("GuiObject") then
					panel.Visible = false
				end
			end
		end
	end
	
	if exceptGUI ~= MusicGUIName then
		local musicGui = playerGui:FindFirstChild(MusicGUIName)
		if musicGui then
			local mainPanel = musicGui:FindFirstChild(MusicMainPanel)
			local libraryPanel = musicGui:FindFirstChild(MusicLibraryPanel)
			local popupPanel = musicGui:FindFirstChild(MusicPlaylistPopup)
			
			if mainPanel then mainPanel.Visible = false end
			if libraryPanel then libraryPanel.Visible = false end
			if popupPanel then popupPanel.Visible = false end
		end
	end
end

local function onUIOpened(guiName)
	if currentOpenUI == guiName then return end
	
	hideAllUIs(guiName)
	currentOpenUI = guiName
end

local function onUIClosed(guiName)
	if currentOpenUI == guiName then
		currentOpenUI = nil
	end
end

local function setupUIMonitoring()
	for guiName, panelName in pairs(ManagedUIs) do
		local gui = playerGui:FindFirstChild(guiName)
		if gui then
			local panel = gui:FindFirstChild(panelName)
			if panel and panel:IsA("GuiObject") then
				panel:GetPropertyChangedSignal("Visible"):Connect(function()
					if panel.Visible then
						onUIOpened(guiName)
					else
						onUIClosed(guiName)
					end
				end)
			end
		end
	end
	
	local musicGui = playerGui:FindFirstChild(MusicGUIName)
	if musicGui then
		local mainPanel = musicGui:FindFirstChild(MusicMainPanel)
		local libraryPanel = musicGui:FindFirstChild(MusicLibraryPanel)
		
		if mainPanel then
			mainPanel:GetPropertyChangedSignal("Visible"):Connect(function()
				if mainPanel.Visible then
					onUIOpened(MusicGUIName)
				else
					onUIClosed(MusicGUIName)
				end
			end)
		end
		
		if libraryPanel then
			libraryPanel:GetPropertyChangedSignal("Visible"):Connect(function()
				if libraryPanel.Visible then
					onUIOpened(MusicGUIName)
				end
			end)
		end
	end
end

local function waitAndSetupUIMonitor()
	task.wait(3)
	setupUIMonitoring()
	print("✅ [UI MANAGER] Monitoring active")
end

playerGui.ChildAdded:Connect(function(child)
	if ManagedUIs[child.Name] or child.Name == MusicGUIName then
		task.wait(0.5)
		setupUIMonitoring()
	end
end)

_G.UIManager = {
	HideAllUIs = hideAllUIs,
	GetCurrentOpenUI = function() return currentOpenUI end,
	IsAnyUIOpen = function() return currentOpenUI ~= nil end,
}

task.spawn(waitAndSetupUIMonitor)

print("✅ [UI MANAGER] Loaded")

-- ================================================================================
--                      SECTION: EQUIPMENT SYSTEM CLIENT
-- ================================================================================

local RodShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RodShopConfig"))

-- RemoteEvents
local rodShopRemotes = ReplicatedStorage:WaitForChild("RodShopRemotes", 10)
if not rodShopRemotes then
	warn("[EQUIPMENT CLIENT] RodShopRemotes not found!")
	return
end

local getOwnedItemsFunc = rodShopRemotes:WaitForChild("GetOwnedItems", 5)
local equipRodEvent = rodShopRemotes:WaitForChild("EquipRod", 5)
local unequipRodEvent = rodShopRemotes:WaitForChild("UnequipRod", 5)
local equipFloaterEvent = rodShopRemotes:WaitForChild("EquipFloater", 5)
local unequipFloaterEvent = rodShopRemotes:WaitForChild("UnequipFloater", 5)
local equipmentChangedEvent = rodShopRemotes:FindFirstChild("EquipmentChanged")
local shopUpdatedEvent = rodShopRemotes:FindFirstChild("ShopUpdated")

-- Equipment State
local isEquipOpen = false
local currentEquipTab = "Rods"
local equipmentData = {
	OwnedRods = {"FishingRod_Wood1"},
	OwnedFloaters = {"Floater_Doll"},
	EquippedRod = "FishingRod_Wood1",
	EquippedFloater = "Floater_Doll"
}

-- ==================== CREATE EQUIPMENT UI ====================

local equipScreenGui = Instance.new("ScreenGui")
equipScreenGui.Name = "EquipmentGUI"
equipScreenGui.ResetOnSpawn = false
equipScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
equipScreenGui.Parent = playerGui

-- Use HUD Button Template
local hudGui = playerGui:WaitForChild("HUD", 10)
local leftFrame = hudGui and hudGui:FindFirstChild("Left")
local buttonTemplate = leftFrame and leftFrame:FindFirstChild("ButtonTemplate")

local equipFloatingButton = nil

if buttonTemplate then
	buttonTemplate.Visible = false
	
	local buttonContainer = buttonTemplate:Clone()
	buttonContainer.Name = "EquipButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 1
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = leftFrame
	
	equipFloatingButton = buttonContainer:FindFirstChild("ImageButton")
	local buttonText = buttonContainer:FindFirstChild("TextLabel")
	
	if equipFloatingButton then
		equipFloatingButton.Image = "rbxassetid://139408214639598"
		equipFloatingButton.BackgroundTransparency = 1
	end
	
	if buttonText then
		buttonText.Text = "Equip"
	end
else
	equipFloatingButton = Instance.new("ImageButton")
	equipFloatingButton.Name = "EquipmentButton"
	equipFloatingButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	equipFloatingButton.Position = UDim2.new(0.01, 0, 0.4, 0)
	equipFloatingButton.BackgroundTransparency = 1
	equipFloatingButton.BorderSizePixel = 0
	equipFloatingButton.Image = "rbxassetid://139408214639598"
	equipFloatingButton.ScaleType = Enum.ScaleType.Fit
	equipFloatingButton.Parent = equipScreenGui
	
	local buttonAspect = Instance.new("UIAspectRatioConstraint")
	buttonAspect.AspectRatio = 1
	buttonAspect.Parent = equipFloatingButton
end

-- Main Equipment Panel
local equipMainPanel = Instance.new("Frame")
equipMainPanel.Name = "MainPanel"
equipMainPanel.Size = UDim2.new(0.5, 0, 0.8, 0)
equipMainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
equipMainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
equipMainPanel.BackgroundColor3 = COLORS.Background
equipMainPanel.BorderSizePixel = 0
equipMainPanel.Visible = false
equipMainPanel.Parent = equipScreenGui

-- AspectRatio based on width
local panelAspect = Instance.new("UIAspectRatioConstraint")
panelAspect.AspectRatio = 0.85
panelAspect.DominantAxis = Enum.DominantAxis.Width
panelAspect.Parent = equipMainPanel

createCorner(16).Parent = equipMainPanel

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Accent
mainStroke.Thickness = 2
mainStroke.Parent = equipMainPanel

-- Main Panel Padding
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0.02, 0)
mainPadding.PaddingBottom = UDim.new(0.02, 0)
mainPadding.PaddingLeft = UDim.new(0.03, 0)
mainPadding.PaddingRight = UDim.new(0.03, 0)
mainPadding.Parent = equipMainPanel

-- Header
local equipHeaderFrame = Instance.new("Frame")
equipHeaderFrame.Name = "Header"
equipHeaderFrame.Size = UDim2.new(1, 0, 0.08, 0)
equipHeaderFrame.Position = UDim2.new(0, 0, 0, 0)
equipHeaderFrame.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
equipHeaderFrame.BorderSizePixel = 0
equipHeaderFrame.Parent = equipMainPanel

createCorner(12).Parent = equipHeaderFrame

local equipTitleLabel = Instance.new("TextLabel")
equipTitleLabel.Size = UDim2.new(0.75, 0, 0.7, 0)
equipTitleLabel.Position = UDim2.new(0.03, 0, 0.15, 0)
equipTitleLabel.BackgroundTransparency = 1
equipTitleLabel.Font = Enum.Font.GothamBlack
equipTitleLabel.Text = "🎣 EQUIPMENT"
equipTitleLabel.TextColor3 = COLORS.Text
equipTitleLabel.TextScaled = true
equipTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
equipTitleLabel.Parent = equipHeaderFrame

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 28
titleConstraint.Parent = equipTitleLabel

local equipCloseButton = Instance.new("TextButton")
equipCloseButton.Size = UDim2.new(0.08, 0, 0.7, 0)
equipCloseButton.Position = UDim2.new(0.9, 0, 0.15, 0)
equipCloseButton.BackgroundColor3 = COLORS.Danger
equipCloseButton.BorderSizePixel = 0
equipCloseButton.Font = Enum.Font.GothamBold
equipCloseButton.Text = "X"
equipCloseButton.TextColor3 = COLORS.Text
equipCloseButton.TextScaled = true
equipCloseButton.Parent = equipHeaderFrame

local closeTextConstraint = Instance.new("UITextSizeConstraint")
closeTextConstraint.MaxTextSize = 18
closeTextConstraint.Parent = equipCloseButton

local closeAspect = Instance.new("UIAspectRatioConstraint")
closeAspect.AspectRatio = 1
closeAspect.Parent = equipCloseButton

createCorner(8).Parent = equipCloseButton

-- Tab Buttons
local equipTabFrame = Instance.new("Frame")
equipTabFrame.Name = "TabFrame"
equipTabFrame.Size = UDim2.new(1, 0, 0.06, 0)
equipTabFrame.Position = UDim2.new(0, 0, 0.1, 0)
equipTabFrame.BackgroundTransparency = 1
equipTabFrame.Parent = equipMainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.02, 0)
tabLayout.Parent = equipTabFrame

local rodsTabBtn = Instance.new("TextButton")
rodsTabBtn.Name = "RodsTab"
rodsTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
rodsTabBtn.BackgroundColor3 = COLORS.Accent
rodsTabBtn.BorderSizePixel = 0
rodsTabBtn.Font = Enum.Font.GothamBold
rodsTabBtn.Text = "🎣 RODS"
rodsTabBtn.TextColor3 = COLORS.Text
rodsTabBtn.TextScaled = true
rodsTabBtn.Parent = equipTabFrame

local rodTabTextConstraint = Instance.new("UITextSizeConstraint")
rodTabTextConstraint.MaxTextSize = 16
rodTabTextConstraint.Parent = rodsTabBtn

createCorner(8).Parent = rodsTabBtn

local floatersTabBtn = Instance.new("TextButton")
floatersTabBtn.Name = "FloatersTab"
floatersTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
floatersTabBtn.BackgroundColor3 = COLORS.CardBg
floatersTabBtn.BorderSizePixel = 0
floatersTabBtn.Font = Enum.Font.GothamBold
floatersTabBtn.Text = "🎈 FLOATERS"
floatersTabBtn.TextColor3 = COLORS.SubText
floatersTabBtn.TextScaled = true
floatersTabBtn.Parent = equipTabFrame

local floaterTabTextConstraint = Instance.new("UITextSizeConstraint")
floaterTabTextConstraint.MaxTextSize = 16
floaterTabTextConstraint.Parent = floatersTabBtn

createCorner(8).Parent = floatersTabBtn

-- Content Frame
local equipContentFrame = Instance.new("ScrollingFrame")
equipContentFrame.Name = "ContentFrame"
equipContentFrame.Size = UDim2.new(1, 0, 0.68, 0)
equipContentFrame.Position = UDim2.new(0, 0, 0.18, 0)
equipContentFrame.BackgroundTransparency = 1
equipContentFrame.ScrollBarThickness = 6
equipContentFrame.ScrollBarImageColor3 = COLORS.Accent
equipContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
equipContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
equipContentFrame.Parent = equipMainPanel

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0.01, 0)
contentPadding.PaddingBottom = UDim.new(0.01, 0)
contentPadding.PaddingLeft = UDim.new(0.01, 0)
contentPadding.PaddingRight = UDim.new(0.01, 0)
contentPadding.Parent = equipContentFrame

local columns = isMobile and 3 or 4
local cellWidth = 1 / columns

local contentGrid = Instance.new("UIGridLayout")
contentGrid.CellSize = UDim2.new(cellWidth - 0.02, 0, 0, 130)
contentGrid.CellPadding = UDim2.new(0.015, 0, 0.015, 0)
contentGrid.SortOrder = Enum.SortOrder.LayoutOrder
contentGrid.Parent = equipContentFrame

-- Stats Bar
local equipStatsBar = Instance.new("Frame")
equipStatsBar.Name = "StatsBar"
equipStatsBar.Size = UDim2.new(1, 0, 0.08, 0)
equipStatsBar.Position = UDim2.new(0, 0, 0.9, 0)
equipStatsBar.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
equipStatsBar.BorderSizePixel = 0
equipStatsBar.Parent = equipMainPanel

createCorner(10).Parent = equipStatsBar

local statsPadding = Instance.new("UIPadding")
statsPadding.PaddingLeft = UDim.new(0.03, 0)
statsPadding.PaddingRight = UDim.new(0.03, 0)
statsPadding.Parent = equipStatsBar

local equippedLabel = Instance.new("TextLabel")
equippedLabel.Name = "EquippedInfo"
equippedLabel.Size = UDim2.new(1, 0, 0.8, 0)
equippedLabel.Position = UDim2.new(0, 0, 0.1, 0)
equippedLabel.BackgroundTransparency = 1
equippedLabel.Font = Enum.Font.GothamBold
equippedLabel.Text = "🎣 Equipped: Loading..."
equippedLabel.TextColor3 = COLORS.Success
equippedLabel.TextScaled = true
equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedLabel.Parent = equipStatsBar

local equippedTextConstraint = Instance.new("UITextSizeConstraint")
equippedTextConstraint.MaxTextSize = 16
equippedTextConstraint.Parent = equippedLabel

-- ==================== EQUIPMENT ITEM CARD ====================

local function createRodCard(rodId, isEquipped)
	local rodConfig = RodShopConfig.GetRodById(rodId)
	if not rodConfig then return nil end
	
	local card = Instance.new("Frame")
	card.Name = "RodCard_" .. rodId
	card.BackgroundColor3 = COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isEquipped and COLORS.Success or getRarityColor(rodConfig.Rarity)
	cardStroke.Thickness = isEquipped and 3 or 2
	cardStroke.Parent = card
	
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0.9, 0, 0.45, 0)
	imageContainer.Position = UDim2.new(0.05, 0, 0.04, 0)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(0.8, 0, 0.8, 0)
	thumbnail.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbnail.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbnail.BackgroundTransparency = 1
	thumbnail.Image = rodConfig.ImageId or ""
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = imageContainer
	
	if isEquipped then
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0.4, 0, 0.3, 0)
		badge.Position = UDim2.new(0.95, 0, 0.05, 0)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = COLORS.Success
		badge.Font = Enum.Font.GothamBold
		badge.Text = "✓"
		badge.TextColor3 = COLORS.Text
		badge.TextScaled = true
		badge.Parent = imageContainer
		createCorner(4).Parent = badge
	end
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.94, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.03, 0, 0.52, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = rodConfig.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.94, 0, 0.1, 0)
	rarityLabel.Position = UDim2.new(0.03, 0, 0.65, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = rodConfig.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(rodConfig.Rarity)
	rarityLabel.TextScaled = true
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
	actionBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
	actionBtn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Text = isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = COLORS.Text
	actionBtn.TextScaled = true
	actionBtn.Parent = card
	
	createCorner(5).Parent = actionBtn
	
	actionBtn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipRodEvent:FireServer()
		else
			equipRodEvent:FireServer(rodId)
		end
	end)
	
	card.Parent = equipContentFrame
	return card
end

local function createFloaterCard(floaterId, isEquipped)
	local floaterConfig = RodShopConfig.GetFloaterById(floaterId)
	if not floaterConfig then return nil end
	
	local card = Instance.new("Frame")
	card.Name = "FloaterCard_" .. floaterId
	card.BackgroundColor3 = COLORS.CardBg
	card.BorderSizePixel = 0
	
	createCorner(10).Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isEquipped and COLORS.Success or getRarityColor(floaterConfig.Rarity)
	cardStroke.Thickness = isEquipped and 3 or 2
	cardStroke.Parent = card
	
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0.9, 0, 0.45, 0)
	imageContainer.Position = UDim2.new(0.05, 0, 0.04, 0)
	imageContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
	imageContainer.Parent = card
	
	createCorner(6).Parent = imageContainer
	
	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(0.8, 0, 0.8, 0)
	thumbnail.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbnail.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbnail.BackgroundTransparency = 1
	thumbnail.Image = floaterConfig.ImageId or ""
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = imageContainer
	
	if isEquipped then
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0.4, 0, 0.3, 0)
		badge.Position = UDim2.new(0.95, 0, 0.05, 0)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = COLORS.Success
		badge.Font = Enum.Font.GothamBold
		badge.Text = "✓"
		badge.TextColor3 = COLORS.Text
		badge.TextScaled = true
		badge.Parent = imageContainer
		createCorner(4).Parent = badge
	end
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.94, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.03, 0, 0.52, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = floaterConfig.DisplayName
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = card
	
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.94, 0, 0.1, 0)
	rarityLabel.Position = UDim2.new(0.03, 0, 0.65, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Text = floaterConfig.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(floaterConfig.Rarity)
	rarityLabel.TextScaled = true
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	rarityLabel.Parent = card
	
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
	actionBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
	actionBtn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Text = isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = COLORS.Text
	actionBtn.TextScaled = true
	actionBtn.Parent = card
	
	createCorner(5).Parent = actionBtn
	
	actionBtn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipFloaterEvent:FireServer()
		else
			equipFloaterEvent:FireServer(floaterId)
		end
	end)
	
	card.Parent = equipContentFrame
	return card
end

-- ==================== EQUIPMENT DATA FUNCTIONS ====================

local function clearEquipContent()
	for _, child in ipairs(equipContentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function updateEquipDisplay()
	clearEquipContent()
	
	if currentEquipTab == "Rods" then
		for _, rodId in ipairs(equipmentData.OwnedRods or {}) do
			local isEquipped = (equipmentData.EquippedRod == rodId)
			createRodCard(rodId, isEquipped)
		end
		
		local equippedRodConfig = RodShopConfig.GetRodById(equipmentData.EquippedRod)
		if equippedRodConfig then
			equippedLabel.Text = "🎣 Equipped Rod: " .. equippedRodConfig.DisplayName
		else
			equippedLabel.Text = "🎣 No Rod Equipped"
		end
	else
		for _, floaterId in ipairs(equipmentData.OwnedFloaters or {}) do
			local isEquipped = (equipmentData.EquippedFloater == floaterId)
			createFloaterCard(floaterId, isEquipped)
		end
		
		local equippedFloaterConfig = RodShopConfig.GetFloaterById(equipmentData.EquippedFloater)
		if equippedFloaterConfig then
			equippedLabel.Text = "🎈 Equipped Floater: " .. equippedFloaterConfig.DisplayName
		else
			equippedLabel.Text = "🎈 No Floater Equipped"
		end
	end
end

local function fetchEquipData()
	if not getOwnedItemsFunc then return end
	
	local success, data = pcall(function()
		return getOwnedItemsFunc:InvokeServer()
	end)
	
	if success and data then
		equipmentData = data
		updateEquipDisplay()
	end
end

-- ==================== EQUIPMENT TAB SWITCHING ====================

local function switchEquipTab(tab)
	currentEquipTab = tab
	
	if tab == "Rods" then
		rodsTabBtn.BackgroundColor3 = COLORS.Accent
		rodsTabBtn.TextColor3 = COLORS.Text
		floatersTabBtn.BackgroundColor3 = COLORS.CardBg
		floatersTabBtn.TextColor3 = COLORS.SubText
	else
		floatersTabBtn.BackgroundColor3 = COLORS.Accent
		floatersTabBtn.TextColor3 = COLORS.Text
		rodsTabBtn.BackgroundColor3 = COLORS.CardBg
		rodsTabBtn.TextColor3 = COLORS.SubText
	end
	
	updateEquipDisplay()
end

rodsTabBtn.MouseButton1Click:Connect(function()
	switchEquipTab("Rods")
end)

floatersTabBtn.MouseButton1Click:Connect(function()
	switchEquipTab("Floaters")
end)

-- ==================== EQUIPMENT OPEN/CLOSE ====================

local function toggleEquipPanel()
	isEquipOpen = not isEquipOpen
	equipMainPanel.Visible = isEquipOpen
	
	if isEquipOpen then
		fetchEquipData()
	end
end

equipFloatingButton.MouseButton1Click:Connect(toggleEquipPanel)
equipCloseButton.MouseButton1Click:Connect(function()
	isEquipOpen = false
	equipMainPanel.Visible = false
end)

-- ==================== EQUIPMENT AUTO-REFRESH ====================

if equipmentChangedEvent then
	equipmentChangedEvent.OnClientEvent:Connect(function(data)
		print("🔄 [EQUIPMENT] Equipment changed!")
		fetchEquipData()
	end)
end

if shopUpdatedEvent then
	shopUpdatedEvent.OnClientEvent:Connect(function()
		print("🔄 [EQUIPMENT] Shop updated!")
		fetchEquipData()
	end)
end

-- ==================== KEYBIND ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.G then
		toggleEquipPanel()
	end
end)

print("✅ [UI CLIENT] Loaded (Combined Equipment + UI Manager + Notifications)")
