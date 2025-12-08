--[[
	GLOBAL UI MANAGER
	Manages UI visibility across all panels
	
	When one UI opens, all other UIs auto-hide
	Music widget is special - hides by clicking frame, shows when music menu closes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("✅ [UI MANAGER] Initializing...")

-- ============================================
-- UI REGISTRY
-- ============================================
local ManagedUIs = {
	-- Format: { GUIName = "MainPanelName" }
	EquipmentGUI = "MainPanel",
	FishCollectionGUI = "MainPanel",
	RodShopGUI = "MainPanel",
	FishermanShopGUI = "MainPanel",
	InventoryGUI = "MainPanel",
	RedeemGUI = "MainPanel",
	DonateGUI = "MainPanel",
	ShopGUI = "MainPanel",
}

-- Music widget is special case
local MusicGUIName = "MusicPlayer"
local MusicMainPanel = "MainPanel"
local MusicLibraryPanel = "MyLibraryPanel"
local MusicWidgetPanel = "WidgetPanel"
local MusicPlaylistPopup = "PlaylistPopupPanel"

-- Current open UI
local currentOpenUI = nil

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
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
	
	-- Hide music main panel and library (but not widget)
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
	print("🔄 [UI MANAGER]", guiName, "opened")
end

local function onUIClosed(guiName)
	if currentOpenUI == guiName then
		currentOpenUI = nil
		print("🔄 [UI MANAGER]", guiName, "closed")
	end
end

-- ============================================
-- MONITOR UI VISIBILITY
-- ============================================
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
	
	-- Monitor music UI separately
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

-- ============================================
-- RETRY SETUP (wait for GUIs to load)
-- ============================================
local function waitAndSetup()
	task.wait(3) -- Wait for all UIs to initialize
	setupUIMonitoring()
	print("✅ [UI MANAGER] Monitoring active")
end

-- Also listen for new GUIs
playerGui.ChildAdded:Connect(function(child)
	if ManagedUIs[child.Name] or child.Name == MusicGUIName then
		task.wait(0.5)
		setupUIMonitoring()
	end
end)

-- ============================================
-- EXPOSE GLOBAL FUNCTIONS
-- ============================================
_G.UIManager = {
	HideAllUIs = hideAllUIs,
	GetCurrentOpenUI = function() return currentOpenUI end,
	IsAnyUIOpen = function() return currentOpenUI ~= nil end,
}

-- Start
task.spawn(waitAndSetup)

print("✅ [UI MANAGER] Loaded")
