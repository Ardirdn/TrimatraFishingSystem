--[[
    NOTIFICATION CLIENT (FIXED - Color Override)
    Place in StarterPlayerScripts/NotificationClient
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationConfig = require(ReplicatedStorage:WaitForChild("NotificationComm"):WaitForChild("NotificationConfig"))

local notificationComm = ReplicatedStorage:WaitForChild("NotificationComm")
local showNotificationEvent = notificationComm:WaitForChild("ShowNotification")

-- Notification queue
local notificationQueue = {}
local activeNotifications = {}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Container for notifications (top-right)
local container = Instance.new("Frame")
container.Name = "NotificationContainer"
container.Size = UDim2.new(0, 350, 1, -20)
container.Position = UDim2.new(1, -360, 0, 10)
container.BackgroundTransparency = 1
container.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, NotificationConfig.NotificationSpacing)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Parent = container

-- Helper functions
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

local function playSound(soundId)
	if not soundId then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function createNotification(data)
	-- Get notification type config (COPY, tidak reference!)
	local typeConfig = NotificationConfig.Types[data.Type] or NotificationConfig.Types.info

	-- Apply custom color BEFORE creating UI
	local finalColor = typeConfig.Color
	if data.CustomColor then
		if type(data.CustomColor) == "table" then
			finalColor = Color3.new(data.CustomColor[1], data.CustomColor[2], data.CustomColor[3])
		else
			finalColor = data.CustomColor
		end
		print(string.format("🎨 [NOTIFICATION CLIENT] Custom color applied: R=%.2f G=%.2f B=%.2f", 
			finalColor.R, finalColor.G, finalColor.B))
	end

	-- Create notification frame
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.new(1, 0, 0, 70)
	notif.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	notif.BorderSizePixel = 0
	notif.BackgroundTransparency = 1
	notif.ClipsDescendants = true
	notif.Parent = container

	createCorner(10).Parent = notif
	createStroke(finalColor, 2).Parent = notif -- Use finalColor!

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "IconLabel"
	icon.Size = UDim2.new(0, 50, 1, 0)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = data.Icon or typeConfig.Icon
	icon.TextColor3 = finalColor -- Use finalColor!
	icon.TextSize = 28
	icon.Parent = notif

	-- Message
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -60, 1, -10)
	message.Position = UDim2.new(0, 55, 0, 5)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.GothamBold
	message.Text = data.Message
	message.TextColor3 = Color3.fromRGB(255, 255, 255)
	message.TextSize = 14
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Center
	message.Parent = notif

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -10, 0, 3)
	progressBg.Position = UDim2.new(0, 5, 1, -8)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = notif

	createCorner(2).Parent = progressBg

	local progress = Instance.new("Frame")
	progress.Name = "ProgressBar"
	progress.Size = UDim2.new(1, 0, 1, 0)
	progress.BackgroundColor3 = finalColor -- Use finalColor!
	progress.BorderSizePixel = 0
	progress.Parent = progressBg

	createCorner(2).Parent = progress

	return notif, progress, typeConfig
end

local function showNotification(data)
	-- Check max notifications
	if #activeNotifications >= NotificationConfig.MaxNotifications then
		table.insert(notificationQueue, data)
		return
	end

	-- Create notification with color already applied
	local notif, progress, typeConfig = createNotification(data)
	table.insert(activeNotifications, notif)

	-- Add Skip button for global notifications
	if data.Type == "info" and data.Icon == "📢" then
		local skipBtn = Instance.new("TextButton")
		skipBtn.Size = UDim2.new(0, 50, 0, 20)
		skipBtn.Position = UDim2.new(1, -55, 0, 5)
		skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		skipBtn.BorderSizePixel = 0
		skipBtn.Font = Enum.Font.GothamBold
		skipBtn.Text = "SKIP"
		skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		skipBtn.TextSize = 10
		skipBtn.ZIndex = 53
		skipBtn.Parent = notif

		local skipCorner = Instance.new("UICorner")
		skipCorner.CornerRadius = UDim.new(0, 4)
		skipCorner.Parent = skipBtn

		skipBtn.MouseButton1Click:Connect(function()
			-- Immediately remove notification
			local slideOut = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 50, 0, 0)
			})

			slideOut:Play()
			slideOut.Completed:Connect(function()
				notif:Destroy()

				local index = table.find(activeNotifications, notif)
				if index then
					table.remove(activeNotifications, index)
				end

				if #notificationQueue > 0 then
					local nextData = table.remove(notificationQueue, 1)
					showNotification(nextData)
				end
			end)
		end)
	end

	-- Play sound
	playSound(typeConfig.Sound)

	-- Slide in animation
	notif.BackgroundTransparency = 1
	notif.Position = UDim2.new(0, 50, 0, 0)

	TweenService:Create(notif, TweenInfo.new(NotificationConfig.AnimationDuration, Enum.EasingStyle.Back), {
		BackgroundTransparency = 0.1,
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	-- Duration countdown
	local duration = data.Duration or NotificationConfig.DefaultDuration

	TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	-- Remove after duration
	task.delay(duration, function()
		-- Slide out animation
		local slideOut = TweenService:Create(notif, TweenInfo.new(NotificationConfig.AnimationDuration, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 50, 0, 0)
		})

		slideOut:Play()
		slideOut.Completed:Connect(function()
			notif:Destroy()

			-- Remove from active list
			local index = table.find(activeNotifications, notif)
			if index then
				table.remove(activeNotifications, index)
			end

			-- Show next in queue
			if #notificationQueue > 0 then
				local nextData = table.remove(notificationQueue, 1)
				showNotification(nextData)
			end
		end)
	end)
end

-- Listen for notifications
showNotificationEvent.OnClientEvent:Connect(function(data)
	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION CLIENT] Invalid notification data")
		return
	end

	print(string.format("📥 [NOTIFICATION CLIENT] Received: %s (%s)", data.Message, data.Type or "info"))

	-- Debug custom color
	if data.CustomColor then
		print("📥 [NOTIFICATION CLIENT] CustomColor received:", data.CustomColor)
	end

	showNotification(data)
end)

print("✅ [NOTIFICATION CLIENT] Loaded")