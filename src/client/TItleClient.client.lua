--[[
    TITLE CLIENT (Refactored)
    Place in StarterPlayerScripts/TitleClient
    
    - Receives title updates from server
    - Displays titles above player heads
    - Integrates with Data Handler

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("TitleRemotes")
local updateTitleEvent = remoteFolder:WaitForChild("UpdateTitle")
local updateOtherPlayerTitleEvent = remoteFolder:WaitForChild("UpdateOtherPlayerTitle")
local getTitleFunc = remoteFolder:WaitForChild("GetTitle")

local playerTitles = {}
local playerCountries = {}

-- Colors
local COLORS = {
	Background = Color3.fromRGB(20, 25, 35),
	BackgroundTransparency = 0.5,
	TextStroke = 0.7,
	NameColor = Color3.fromRGB(255, 255, 255),
	MoneyColor = Color3.fromRGB(100, 200, 130),
}

-- Distance culling constants
local MAX_VISIBLE_DISTANCE = 20 -- studs

-- Create Title Billboard (REDESIGNED v2)
local function createTitleBillboard(character)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	-- Remove existing
	local existing = head:FindFirstChild("TitleBillboard")
	if existing then existing:Destroy() end

	-- Get player from character
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	local displayName = targetPlayer and targetPlayer.DisplayName or character.Name
	local username = targetPlayer and ("@" .. targetPlayer.Name) or ""

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TitleBillboard"
	billboard.Size = UDim2.new(0, 250, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = MAX_VISIBLE_DISTANCE
	billboard.Parent = head

	-- ==========================================
	-- MAIN CONTAINER (Single Frame)
	-- ==========================================
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = COLORS.Background
	mainFrame.BackgroundTransparency = COLORS.BackgroundTransparency
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = billboard
	
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame
	
	-- Dynamic stroke - will be updated based on title
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Name = "MainStroke"
	mainStroke.Color = Color3.fromRGB(80, 90, 110) -- Default subtle color
	mainStroke.Thickness = 2
	mainStroke.Transparency = 0.3
	mainStroke.Parent = mainFrame
	
	local mainPadding = Instance.new("UIPadding")
	mainPadding.PaddingLeft = UDim.new(0, 14)
	mainPadding.PaddingRight = UDim.new(0, 14)
	mainPadding.PaddingTop = UDim.new(0, 10)
	mainPadding.PaddingBottom = UDim.new(0, 10)
	mainPadding.Parent = mainFrame

	-- ==========================================
	-- LEFT SIDE: Display Name + Username + Money
	-- ==========================================
	local leftContainer = Instance.new("Frame")
	leftContainer.Name = "LeftContainer"
	leftContainer.Size = UDim2.new(0.65, -5, 1, 0)
	leftContainer.Position = UDim2.new(0, 0, 0, 0)
	leftContainer.BackgroundTransparency = 1
	leftContainer.Parent = mainFrame
	
	local leftLayout = Instance.new("UIListLayout")
	leftLayout.FillDirection = Enum.FillDirection.Vertical
	leftLayout.Padding = UDim.new(0, 1)
	leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	leftLayout.Parent = leftContainer

	-- Display Name (Large)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = 17
	nameLabel.TextColor3 = COLORS.NameColor
	nameLabel.TextStrokeTransparency = 0.6
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = displayName
	nameLabel.LayoutOrder = 1
	nameLabel.Parent = leftContainer

	-- Username (@username)
	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "UsernameLabel"
	usernameLabel.Size = UDim2.new(1, 0, 0, 14)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.TextSize = 11
	usernameLabel.TextColor3 = Color3.fromRGB(140, 150, 170)
	usernameLabel.TextStrokeTransparency = 0.8
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.Text = username
	usernameLabel.LayoutOrder = 2
	usernameLabel.Parent = leftContainer

	-- Money Row
	local moneyRow = Instance.new("Frame")
	moneyRow.Name = "MoneyRow"
	moneyRow.Size = UDim2.new(1, 0, 0, 16)
	moneyRow.BackgroundTransparency = 1
	moneyRow.LayoutOrder = 3
	moneyRow.Parent = leftContainer
	
	local moneyRowLayout = Instance.new("UIListLayout")
	moneyRowLayout.FillDirection = Enum.FillDirection.Horizontal
	moneyRowLayout.Padding = UDim.new(0, 5)
	moneyRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	moneyRowLayout.Parent = moneyRow
	
	-- Money Icon
	local moneyIcon = Instance.new("TextLabel")
	moneyIcon.Name = "MoneyIcon"
	moneyIcon.Size = UDim2.new(0, 14, 0, 14)
	moneyIcon.BackgroundTransparency = 1
	moneyIcon.Font = Enum.Font.GothamBold
	moneyIcon.TextSize = 12
	moneyIcon.Text = "💰"
	moneyIcon.LayoutOrder = 1
	moneyIcon.Parent = moneyRow

	-- Money
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(0, 80, 0, 16)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextSize = 13
	moneyLabel.TextColor3 = COLORS.MoneyColor
	moneyLabel.TextStrokeTransparency = 0.7
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = "$0"
	moneyLabel.LayoutOrder = 2
	moneyLabel.Parent = moneyRow

	-- ==========================================
	-- RIGHT SIDE: Title Badge
	-- ==========================================
	local titleBadge = Instance.new("Frame")
	titleBadge.Name = "TitleBadge"
	titleBadge.Size = UDim2.new(0.35, -5, 0, 28)
	titleBadge.Position = UDim2.new(0.65, 5, 0.5, 0)
	titleBadge.AnchorPoint = Vector2.new(0, 0.5)
	titleBadge.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Default color
	titleBadge.BackgroundTransparency = 0.1
	titleBadge.BorderSizePixel = 0
	titleBadge.Visible = false
	titleBadge.Parent = mainFrame
	
	local titleBadgeCorner = Instance.new("UICorner")
	titleBadgeCorner.CornerRadius = UDim.new(0, 8)
	titleBadgeCorner.Parent = titleBadge
	
	-- Title badge glow/stroke
	local titleBadgeStroke = Instance.new("UIStroke")
	titleBadgeStroke.Name = "BadgeStroke"
	titleBadgeStroke.Color = Color3.fromRGB(255, 255, 255)
	titleBadgeStroke.Thickness = 1
	titleBadgeStroke.Transparency = 0.7
	titleBadgeStroke.Parent = titleBadge
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 11
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.Text = ""
	titleLabel.Parent = titleBadge

	-- ==========================================
	-- DISTANCE CULLING (RunService)
	-- ==========================================
	local camera = workspace.CurrentCamera
	local distanceConnection
	
	distanceConnection = RunService.Heartbeat:Connect(function()
		if not head or not head.Parent then
			distanceConnection:Disconnect()
			return
		end
		
		if camera then
			local distance = (camera.CFrame.Position - head.Position).Magnitude
			billboard.Enabled = distance <= MAX_VISIBLE_DISTANCE
		end
	end)

	return billboard
end

-- Update title display (NEW STRUCTURE v2)
local function updateTitleDisplay(character, titleName)
	-- ✅ FIXED: Early return if titleName is nil or empty
	if not titleName or titleName == "" then
		warn("[TITLE CLIENT] updateTitleDisplay called with nil/empty titleName")
		return
	end
	
	local head = character:FindFirstChild("Head")
	if not head then return end

	local billboard = head:FindFirstChild("TitleBillboard")
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local titleBadge = mainFrame:FindFirstChild("TitleBadge")
	local titleLabel = titleBadge and titleBadge:FindFirstChild("TitleLabel")
	local mainStroke = mainFrame:FindFirstChild("MainStroke")
	
	if not titleBadge or not titleLabel then return end

	-- Get title data from config
	local titleData = nil

	-- Check Summit Titles first
	for _, data in ipairs(TitleConfig.SummitTitles) do
		if data.Name == titleName then
			titleData = data
			break
		end
	end

	-- If not found, check Special Titles
	if not titleData and TitleConfig.SpecialTitles[titleName] then
		local specialData = TitleConfig.SpecialTitles[titleName]
		titleData = {
			Name = titleName,
			DisplayName = specialData.DisplayName,
			Color = specialData.Color,
			Icon = specialData.Icon
		}
	end

	if titleData then
		if titleName == "Pengunjung" then
			titleBadge.Visible = false
			-- Reset stroke to default
			if mainStroke then
				mainStroke.Color = Color3.fromRGB(80, 90, 110)
				mainStroke.Thickness = 2
			end
		else
			-- Update title badge
			titleLabel.Text = titleData.Icon .. " " .. titleData.DisplayName
			titleBadge.BackgroundColor3 = titleData.Color
			titleBadge.Visible = true
			
			-- ✅ UPDATE MAIN FRAME STROKE to match title color (creates unique vibes)
			if mainStroke then
				mainStroke.Color = titleData.Color
				mainStroke.Thickness = 2
				mainStroke.Transparency = 0.2
			end
			
			-- Update badge stroke to lighter version of title color
			local badgeStroke = titleBadge:FindFirstChild("BadgeStroke")
			if badgeStroke then
				-- Make stroke slightly lighter than badge color
				local h, s, v = titleData.Color:ToHSV()
				badgeStroke.Color = Color3.fromHSV(h, s * 0.3, math.min(v * 1.5, 1))
				badgeStroke.Transparency = 0.5
			end
		end
	else
		-- Fallback if title not found
		warn(string.format("[TITLE CLIENT] Unknown title: %s", tostring(titleName)))
		titleBadge.Visible = false
		if mainStroke then
			mainStroke.Color = Color3.fromRGB(80, 90, 110)
		end
	end

	print(string.format("✅ [TITLE CLIENT] Updated title display for %s: %s", character.Name, tostring(titleName)))
end


-- Update money display (NEW STRUCTURE)
local function updateMoneyDisplay(character, money)
	local head = character:FindFirstChild("Head")
	if not head then return end

	local billboard = head:FindFirstChild("TitleBillboard")
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local leftContainer = mainFrame:FindFirstChild("LeftContainer")
	if not leftContainer then return end

	local moneyRow = leftContainer:FindFirstChild("MoneyRow")
	if not moneyRow then return end

	local moneyLabel = moneyRow:FindFirstChild("MoneyLabel")
	if not moneyLabel then return end

	local formattedMoney = "$" .. tostring(money)
	if money >= 1000000 then
		formattedMoney = "$" .. string.format("%.1fm", money / 1000000)
	elseif money >= 1000 then
		formattedMoney = "$" .. string.format("%.1fk", money / 1000)
	end

	moneyLabel.Text = formattedMoney
end

-- Get player country (NEW STRUCTURE)
local function getPlayerCountry(targetPlayer)
	if playerCountries[targetPlayer] then
		return playerCountries[targetPlayer]
	end

	task.spawn(function()
		local success, result = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(targetPlayer)
		end)

		if success and result then
			local flagEmojis = {
				US = "🇺🇸", ID = "🇮🇩", GB = "🇬🇧", JP = "🇯🇵",
				CN = "🇨🇳", KR = "🇰🇷", FR = "🇫🇷", DE = "🇩🇪",
				BR = "🇧🇷", IN = "🇮🇳", AU = "🇦🇺", CA = "🇨🇦",
				MY = "🇲🇾", SG = "🇸🇬", PH = "🇵🇭", TH = "🇹🇭",
				VN = "🇻🇳", RU = "🇷🇺", ES = "🇪🇸", IT = "🇮🇹",
			}
			local flag = flagEmojis[result] or "🌍"
			playerCountries[targetPlayer] = flag

			if targetPlayer.Character then
				local head = targetPlayer.Character:FindFirstChild("Head")
				if head then
					local billboard = head:FindFirstChild("TitleBillboard")
					if billboard then
						local mainFrame = billboard:FindFirstChild("MainFrame")
						if mainFrame then
							local leftContainer = mainFrame:FindFirstChild("LeftContainer")
							if leftContainer then
								local moneyRow = leftContainer:FindFirstChild("MoneyRow")
								if moneyRow then
									local flagLabel = moneyRow:FindFirstChild("FlagLabel")
									if flagLabel then
										flagLabel.Text = flag
									end
								end
							end
						end
					end
				end
			end
		else
			playerCountries[targetPlayer] = "🌍"
		end
	end)

	return "🌍"
end

-- Setup player title (SIMPLIFIED - no more flag)
local function setupPlayerTitle(targetPlayer)
	local function onCharacterAdded(character)
		local billboard = createTitleBillboard(character)
		if not billboard then return end

		-- Update money
		local moneyValue = targetPlayer:FindFirstChild("Money")
		if moneyValue then
			updateMoneyDisplay(character, moneyValue.Value)
			moneyValue:GetPropertyChangedSignal("Value"):Connect(function()
				updateMoneyDisplay(character, moneyValue.Value)
			end)
		end

		-- Request title from server
		task.spawn(function()
			task.wait(2)

			local success, title = pcall(function()
				return getTitleFunc:InvokeServer(targetPlayer)
			end)

			if success and title and title ~= "" then
				playerTitles[targetPlayer] = title
				if character and character.Parent then
					updateTitleDisplay(character, title)
				end
				print(string.format("📥 [TITLE CLIENT] Got title for %s: %s", targetPlayer.Name, tostring(title)))
			end
		end)
	end

	targetPlayer.CharacterAdded:Connect(onCharacterAdded)
	if targetPlayer.Character then
		onCharacterAdded(targetPlayer.Character)
	end
end

-- Listen for title updates (self)
updateTitleEvent.OnClientEvent:Connect(function(titleName)
	-- ✅ FIXED: Better nil handling
	local titleStr = titleName and tostring(titleName) or "None"
	print(string.format("📥 [TITLE CLIENT] Received title update for SELF: %s", titleStr))
	
	if titleName and titleName ~= "" then
		playerTitles[player] = titleName
		if player.Character then
			updateTitleDisplay(player.Character, titleName)
		end
	else
		-- Handle unequip (nil title)
		playerTitles[player] = nil
		if player.Character then
			local head = player.Character:FindFirstChild("Head")
			if head then
				local billboard = head:FindFirstChild("TitleBillboard")
				if billboard then
					local mainFrame = billboard:FindFirstChild("MainFrame")
					if mainFrame then
						local titleBadge = mainFrame:FindFirstChild("TitleBadge")
						if titleBadge then
							titleBadge.Visible = false
						end
						local mainStroke = mainFrame:FindFirstChild("MainStroke")
						if mainStroke then
							mainStroke.Color = Color3.fromRGB(80, 90, 110)
						end
					end
				end
			end
		end
	end
end)


-- Listen for other players' title updates
updateOtherPlayerTitleEvent.OnClientEvent:Connect(function(targetPlayer, titleName)
	-- ✅ FIXED: Comprehensive nil checks to prevent string.format error
	if not targetPlayer then
		warn("[TITLE CLIENT] Received nil targetPlayer in title update")
		return
	end
	
	-- ✅ FIXED: Ensure targetPlayer is still valid (not left the game)
	if not targetPlayer:IsA("Player") or not targetPlayer.Parent then
		warn("[TITLE CLIENT] Target player is invalid or left the game")
		return
	end
	
	local titleStr = titleName and tostring(titleName) or "None"
	print(string.format("📥 [TITLE CLIENT] Received title update for %s: %s", targetPlayer.Name, titleStr))

	if targetPlayer ~= player then
		if titleName and titleName ~= "" then
			playerTitles[targetPlayer] = titleName
			if targetPlayer.Character then
				updateTitleDisplay(targetPlayer.Character, titleName)
			end
		else
			-- Handle unequip (nil title) for other player
			playerTitles[targetPlayer] = nil
			if targetPlayer.Character then
				local head = targetPlayer.Character:FindFirstChild("Head")
				if head then
					local billboard = head:FindFirstChild("TitleBillboard")
					if billboard then
						local mainFrame = billboard:FindFirstChild("MainFrame")
						if mainFrame then
							local titleBadge = mainFrame:FindFirstChild("TitleBadge")
							if titleBadge then
								titleBadge.Visible = false
							end
							local mainStroke = mainFrame:FindFirstChild("MainStroke")
							if mainStroke then
								mainStroke.Color = Color3.fromRGB(80, 90, 110)
							end
						end
					end
				end
			end
		end
	end
end)

-- Setup for all players
for _, targetPlayer in ipairs(Players:GetPlayers()) do
	setupPlayerTitle(targetPlayer)
end

Players.PlayerAdded:Connect(setupPlayerTitle)

print("✅ [TITLE CLIENT] System loaded")