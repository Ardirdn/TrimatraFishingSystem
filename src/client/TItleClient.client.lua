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
	Background = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.3,
	TextStroke = 0.8,
}

-- Create Title Billboard
local function createTitleBillboard(character)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	-- Remove existing
	local existing = head:FindFirstChild("TitleBillboard")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TitleBillboard"
	billboard.Size = UDim2.new(0, 220, 0, 120)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	-- Container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	-- Title Frame
	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "TitleFrame"
	titleFrame.Size = UDim2.new(0, 0, 0, 22)
	titleFrame.Position = UDim2.new(0.5, 0, 0, 0)
	titleFrame.AnchorPoint = Vector2.new(0.5, 0)
	titleFrame.BackgroundColor3 = COLORS.Background
	titleFrame.BackgroundTransparency = COLORS.BackgroundTransparency
	titleFrame.BorderSizePixel = 0
	titleFrame.Visible = false
	titleFrame.Parent = container

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 6)
	titleCorner.Parent = titleFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -10, 1, 0)
	titleLabel.Position = UDim2.new(0, 5, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = COLORS.TextStroke
	titleLabel.Text = ""
	titleLabel.Parent = titleFrame

	-- Name Frame
	local nameFrame = Instance.new("Frame")
	nameFrame.Name = "NameFrame"
	nameFrame.Size = UDim2.new(0, 0, 0, 26)
	nameFrame.Position = UDim2.new(0.5, 0, 0, 26)
	nameFrame.AnchorPoint = Vector2.new(0.5, 0)
	nameFrame.BackgroundColor3 = COLORS.Background
	nameFrame.BackgroundTransparency = COLORS.BackgroundTransparency
	nameFrame.BorderSizePixel = 0
	nameFrame.Parent = container

	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, 6)
	nameCorner.Parent = nameFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 1, 0)
	nameLabel.Position = UDim2.new(0, 5, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = COLORS.TextStroke
	nameLabel.Text = character.Name
	nameLabel.Parent = nameFrame

	-- Info Frame (Money + Flag)
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "InfoFrame"
	infoFrame.Size = UDim2.new(0, 0, 0, 22)
	infoFrame.Position = UDim2.new(0.5, 0, 0, 56)
	infoFrame.AnchorPoint = Vector2.new(0.5, 0)
	infoFrame.BackgroundColor3 = COLORS.Background
	infoFrame.BackgroundTransparency = COLORS.BackgroundTransparency
	infoFrame.BorderSizePixel = 0
	infoFrame.Parent = container

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 6)
	infoCorner.Parent = infoFrame

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.FillDirection = Enum.FillDirection.Horizontal
	infoLayout.Padding = UDim.new(0, 6)
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.Parent = infoFrame

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingLeft = UDim.new(0, 8)
	infoPadding.PaddingRight = UDim.new(0, 8)
	infoPadding.PaddingTop = UDim.new(0, 2)
	infoPadding.PaddingBottom = UDim.new(0, 2)
	infoPadding.Parent = infoFrame

	-- Flag
	local flagLabel = Instance.new("TextLabel")
	flagLabel.Name = "FlagLabel"
	flagLabel.Size = UDim2.new(0, 20, 0, 18)
	flagLabel.BackgroundTransparency = 1
	flagLabel.Font = Enum.Font.GothamBold
	flagLabel.TextSize = 16
	flagLabel.Text = "🌍"
	flagLabel.LayoutOrder = 1
	flagLabel.Parent = infoFrame

	-- Money
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(0, 60, 0, 18)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextSize = 13
	moneyLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
	moneyLabel.TextStrokeTransparency = COLORS.TextStroke
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = "$0"
	moneyLabel.LayoutOrder = 2
	moneyLabel.Parent = infoFrame

	-- Auto-resize frames
	local function updateFrameSizes()
		if titleFrame.Visible then
			local titleWidth = game:GetService("TextService"):GetTextSize(
				titleLabel.Text, titleLabel.TextSize, titleLabel.Font, Vector2.new(1000, 22)
			).X + 20
			titleFrame.Size = UDim2.new(0, titleWidth, 0, 22)
		end

		local nameWidth = game:GetService("TextService"):GetTextSize(
			nameLabel.Text, nameLabel.TextSize, nameLabel.Font, Vector2.new(1000, 26)
		).X + 20
		nameFrame.Size = UDim2.new(0, nameWidth, 0, 26)

		task.wait(0.05)
		local infoWidth = infoLayout.AbsoluteContentSize.X + 16
		infoFrame.Size = UDim2.new(0, infoWidth, 0, 22)
	end

	task.spawn(updateFrameSizes)

	return billboard
end

-- Update title display
local function updateTitleDisplay(character, titleName)
	local head = character:FindFirstChild("Head")
	if not head then return end

	local billboard = head:FindFirstChild("TitleBillboard")
	if not billboard then return end

	local container = billboard:FindFirstChild("Container")
	if not container then return end

	local titleFrame = container:FindFirstChild("TitleFrame")
	local titleLabel = titleFrame:FindFirstChild("TitleLabel")

	-- ✅ NEW: Get title data from new structure
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
			titleFrame.Visible = false
		else
			titleLabel.Text = titleData.Icon .. " " .. titleData.DisplayName
			titleLabel.TextColor3 = titleData.Color
			titleFrame.Visible = true

			task.spawn(function()
				task.wait(0.05)
				local titleWidth = game:GetService("TextService"):GetTextSize(
					titleLabel.Text, titleLabel.TextSize, titleLabel.Font, Vector2.new(1000, 22)
				).X + 20
				titleFrame.Size = UDim2.new(0, titleWidth, 0, 22)
			end)
		end
	else
		-- Fallback if title not found
		warn(string.format("[TITLE CLIENT] Unknown title: %s", titleName))
		titleFrame.Visible = false
	end

	print(string.format("✅ [TITLE CLIENT] Updated title display for %s: %s", character.Name, titleName))
end


-- Update money display
local function updateMoneyDisplay(character, money)
	local head = character:FindFirstChild("Head")
	if not head then return end

	local billboard = head:FindFirstChild("TitleBillboard")
	if not billboard then return end

	local container = billboard:FindFirstChild("Container")
	if not container then return end

	local infoFrame = container:FindFirstChild("InfoFrame")
	local moneyLabel = infoFrame:FindFirstChild("MoneyLabel")

	local formattedMoney = "$" .. tostring(money)
	if money >= 1000000 then
		formattedMoney = "$" .. string.format("%.1fm", money / 1000000)
	elseif money >= 1000 then
		formattedMoney = "$" .. string.format("%.1fk", money / 1000)
	end

	moneyLabel.Text = formattedMoney

	task.spawn(function()
		task.wait(0.05)
		local infoLayout = infoFrame:FindFirstChildOfClass("UIListLayout")
		if infoLayout then
			local infoWidth = infoLayout.AbsoluteContentSize.X + 16
			infoFrame.Size = UDim2.new(0, infoWidth, 0, 22)
		end
	end)
end

-- Get player country
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
			}
			local flag = flagEmojis[result] or "🌍"
			playerCountries[targetPlayer] = flag

			if targetPlayer.Character then
				local head = targetPlayer.Character:FindFirstChild("Head")
				if head then
					local billboard = head:FindFirstChild("TitleBillboard")
					if billboard then
						local container = billboard:FindFirstChild("Container")
						if container then
							local infoFrame = container:FindFirstChild("InfoFrame")
							local flagLabel = infoFrame:FindFirstChild("FlagLabel")
							flagLabel.Text = flag
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

-- Setup player title
local function setupPlayerTitle(targetPlayer)
	local function onCharacterAdded(character)
		local billboard = createTitleBillboard(character)

		-- Set flag
		local flag = getPlayerCountry(targetPlayer)
		local container = billboard:FindFirstChild("Container")
		if container then
			local infoFrame = container:FindFirstChild("InfoFrame")
			local flagLabel = infoFrame:FindFirstChild("FlagLabel")
			flagLabel.Text = flag
		end

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

			if success and title then
				playerTitles[targetPlayer] = title
				updateTitleDisplay(character, title)
				print(string.format("📥 [TITLE CLIENT] Got title for %s: %s", targetPlayer.Name, title))
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
	print(string.format("📥 [TITLE CLIENT] Received title update for SELF: %s", titleName or "None"))
	playerTitles[player] = titleName
	if player.Character and titleName then -- ✅ Only update if titleName exists
		updateTitleDisplay(player.Character, titleName)
	end
end)


-- Listen for other players' title updates
updateOtherPlayerTitleEvent.OnClientEvent:Connect(function(targetPlayer, titleName)
	print(string.format("📥 [TITLE CLIENT] Received title update for %s: %s", targetPlayer.Name, titleName))

	if targetPlayer and targetPlayer ~= player then
		playerTitles[targetPlayer] = titleName
		if targetPlayer.Character then
			updateTitleDisplay(targetPlayer.Character, titleName)
		end
	end
end)

-- Setup for all players
for _, targetPlayer in ipairs(Players:GetPlayers()) do
	setupPlayerTitle(targetPlayer)
end

Players.PlayerAdded:Connect(setupPlayerTitle)

print("✅ [TITLE CLIENT] System loaded")