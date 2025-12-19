--[[
    NOTIFICATION CLIENT (NEW UI TEMPLATE SYSTEM)
    Uses UI templates from StarterGui.Notification
    
    Template Types:
    - MiddleNotificationTextOnly: Center, text only
    - MidleNotificationWithSender: Center, with sender info
    - SideNotificationTextOnly: Side (default), text only
    - SideNotificationWithSender: Side, with sender info
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🔔 [NOTIFICATION CLIENT] Starting initialization...")

-- Debug: List all ScreenGuis in PlayerGui
print("🔍 [NOTIFICATION CLIENT] Listing PlayerGui children:")
for _, child in ipairs(playerGui:GetChildren()) do
	print(string.format("   - %s (%s)", child.Name, child.ClassName))
	-- Also show children of each ScreenGui
	if child:IsA("ScreenGui") then
		for _, subChild in ipairs(child:GetChildren()) do
			print(string.format("      └─ %s (%s)", subChild.Name, subChild.ClassName))
		end
	end
end

-- Also check StarterGui for debugging
print("🔍 [NOTIFICATION CLIENT] Listing StarterGui children:")
for _, child in ipairs(StarterGui:GetChildren()) do
	print(string.format("   - %s (%s)", child.Name, child.ClassName))
end

-- Wait for Notification ScreenGui (try different possible names)
local notificationGui = playerGui:FindFirstChild("Notification")
	or playerGui:FindFirstChild("NotificationGui")
	or playerGui:FindFirstChild("Notifications")
	or playerGui:FindFirstChild("NotificationGUI") -- camelCase variation

print(string.format("🔍 [DEBUG] Initial search result: %s", notificationGui and notificationGui.Name or "nil"))

-- If not found, wait for it
if not notificationGui then
	print("🔍 [NOTIFICATION CLIENT] Waiting for Notification ScreenGui (15s timeout)...")
	notificationGui = playerGui:WaitForChild("Notification", 15)
	print(string.format("🔍 [DEBUG] After wait result: %s", notificationGui and notificationGui.Name or "nil"))
end

-- Debug: List what's ACTUALLY inside the Notification ScreenGui
if notificationGui then
	print("🔍 [DEBUG] Children of Notification ScreenGui in PlayerGui:")
	local childCount = 0
	for _, child in ipairs(notificationGui:GetChildren()) do
		childCount = childCount + 1
		print(string.format("   - %s (%s) Visible: %s", child.Name, child.ClassName, 
			child:IsA("GuiObject") and tostring(child.Visible) or "N/A"))
	end
	print(string.format("🔍 [DEBUG] Total children: %d", childCount))
	
	-- Also check if templates exist via FindFirstChild (using actual names with typo)
	local templateNames = {"MiddleNotiificationTextOnly", "SideNotiificationTextOnly", "MidleNotiificationWithSender", "SideNotiificationWithSender"}
	print("🔍 [DEBUG] Direct FindFirstChild test:")
	for _, name in ipairs(templateNames) do
		local found = notificationGui:FindFirstChild(name)
		print(string.format("   - %s: %s", name, found and "FOUND" or "NOT FOUND"))
	end
end

if not notificationGui then
	-- Try to find any ScreenGui that might contain notification templates
	print("🔍 [NOTIFICATION CLIENT] Searching for notification templates in all ScreenGuis...")
	local templateNames = {"MiddleNotificationTextOnly", "SideNotificationTextOnly", "MidleNotificationWithSender", "SideNotificationWithSender"}
	
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			print(string.format("   🔍 Checking: %s", gui.Name))
			for _, templateName in ipairs(templateNames) do
				local found = gui:FindFirstChild(templateName)
				if found then
					print(string.format("      ✅ Found template: %s", templateName))
					notificationGui = gui
				end
			end
			if notificationGui then
				print(string.format("✅ [NOTIFICATION CLIENT] Found templates in: %s", gui.Name))
				break
			end
		end
	end
end

local useFallbackContainer = false

if not notificationGui then
	warn("⚠️ [NOTIFICATION CLIENT] Notification ScreenGui not found! Creating fallback system...")
	
	-- Create a fallback notification GUI
	notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "NotificationFallback"
	notificationGui.ResetOnSpawn = false
	notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notificationGui.DisplayOrder = 100
	notificationGui.Parent = playerGui
	useFallbackContainer = true
	
	print("✅ [NOTIFICATION CLIENT] Fallback GUI created")
else
	-- Ensure the existing Notification GUI has proper settings for visibility
	print(string.format("🔍 [DEBUG] NotificationGui properties: Enabled=%s, DisplayOrder=%d", 
		tostring(notificationGui.Enabled), notificationGui.DisplayOrder))
	
	-- Force high DisplayOrder to ensure notifications appear on top
	if notificationGui.DisplayOrder < 90 then
		notificationGui.DisplayOrder = 100
		print("🔧 [NOTIFICATION CLIENT] Increased DisplayOrder to 100 for visibility")
	end
	
	-- Ensure it's enabled
	if not notificationGui.Enabled then
		notificationGui.Enabled = true
		print("🔧 [NOTIFICATION CLIENT] Enabled the Notification ScreenGui")
	end
end

-- Ensure we have a container for fallback notifications
local notificationContainer = notificationGui:FindFirstChild("NotificationContainer")
if not notificationContainer then
	-- Create container for fallback notifications (top-right)
	notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0, 350, 1, -20)
	notificationContainer.Position = UDim2.new(1, -360, 0, 10)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.Parent = notificationGui
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = notificationContainer
	
	print("✅ [NOTIFICATION CLIENT] NotificationContainer created")
end

-- Wait for templates to load (they might not be replicated yet)
print("🔍 [NOTIFICATION CLIENT] Waiting for templates to load...")

local function waitForTemplate(name, timeout)
	local template = notificationGui:FindFirstChild(name)
	if template then return template end
	
	-- Wait a bit for replication
	template = notificationGui:WaitForChild(name, timeout or 3)
	return template
end

-- Get templates with wait (using actual names from StarterGui - note the typo "Notiification")
local templates = {
	MiddleTextOnly = waitForTemplate("MiddleNotiificationTextOnly", 2),  -- Note: "Notiification" typo in StarterGui
	MiddleWithSender = waitForTemplate("MidleNotiificationWithSender", 2), -- Note: "Midle" + "Notiification" typos
	SideTextOnly = waitForTemplate("SideNotiificationTextOnly", 2),  -- Note: "Notiification" typo
	SideWithSender = waitForTemplate("SideNotiificationWithSender", 2)  -- Note: "Notiification" typo
}

-- Debug template status
print("🔍 [NOTIFICATION CLIENT] Template status:")
print(string.format("   📍 NotificationGui: %s", notificationGui.Name))
for name, template in pairs(templates) do
	if template then
		template.Visible = false
		print(string.format("   ✅ %s: Found (Pos: %s, Size: %s, Visible: %s)", 
			name, 
			tostring(template.Position), 
			tostring(template.Size),
			tostring(template.Visible)))
	else
		print(string.format("   ❌ %s: NOT FOUND", name))
	end
end

-- Check if we have at least one template
local hasAnyTemplate = false
for _, template in pairs(templates) do
	if template then
		hasAnyTemplate = true
		break
	end
end

print(string.format("🔍 [NOTIFICATION CLIENT] hasAnyTemplate: %s", tostring(hasAnyTemplate)))

local notificationComm = ReplicatedStorage:WaitForChild("NotificationComm")
local showNotificationEvent = notificationComm:WaitForChild("ShowNotification")

-- Notification queue
local notificationQueue = {}
local activeNotification = nil

-- Helper functions
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

-- Fallback notification function (when templates are not available)
local function showFallbackNotification(data)
	-- Use the pre-created notificationContainer (always a Frame)
	local container = notificationContainer
	
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.new(0, 340, 0, 70)
	notif.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	notif.BorderSizePixel = 0
	notif.BackgroundTransparency = 0.1
	notif.ClipsDescendants = true
	notif.Parent = container
	
	createCorner(10).Parent = notif
	createStroke(Color3.fromRGB(88, 101, 242), 2).Parent = notif
	
	-- Message
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -20, 1, -15)
	message.Position = UDim2.new(0, 10, 0, 5)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.GothamBold
	message.Text = data.Message or "Notification"
	message.TextColor3 = Color3.fromRGB(255, 255, 255)
	message.TextSize = 14
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Center
	message.Parent = notif
	
	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -10, 0, 3)
	progressBg.Position = UDim2.new(0, 5, 1, -8)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = notif

	createCorner(2).Parent = progressBg

	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(1, 0, 1, 0)
	progress.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	progress.BorderSizePixel = 0
	progress.Parent = progressBg

	createCorner(2).Parent = progress
	
	-- Debug position
	print(string.format("🔔 [DEBUG] Fallback notif created in: %s", container:GetFullName()))
	print(string.format("🔔 [DEBUG] Container Position: %s, Size: %s", tostring(container.Position), tostring(container.Size)))
	print(string.format("🔔 [DEBUG] Notif initial Position: %s", tostring(notif.Position)))
	
	-- Slide in animation
	notif.Position = UDim2.new(1, 50, 0, 0)
	local targetPos = UDim2.new(0, 0, 0, 0)
	print(string.format("🔔 [DEBUG] Animating from: %s to: %s", tostring(notif.Position), tostring(targetPos)))
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = targetPos
	}):Play()
	
	-- Duration countdown
	local duration = data.Duration or 5
	TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()
	
	-- Remove after duration
	task.delay(duration, function()
		local slideOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 50, 0, 0)
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			notif:Destroy()
			activeNotification = nil
			
			if #notificationQueue > 0 then
				local nextData = table.remove(notificationQueue, 1)
				showFallbackNotification(nextData)
			end
		end)
	end)
	
	activeNotification = notif
	playSound("rbxassetid://6026984224")
	
	print(string.format("🔔 [NOTIFICATION CLIENT] Fallback notification shown: %s", data.Message))
end

-- Function to animate timer slider
local function animateTimerSlider(timerSlider, duration, onComplete)
	if not timerSlider then 
		task.delay(duration, onComplete)
		return 
	end
	
	local slider = timerSlider:FindFirstChild("Slider")
	local fillBar = slider and slider:FindFirstChild("FillBar")
	
	if fillBar then
		-- Animate fill bar from full to empty
		fillBar.Size = UDim2.new(1, 0, 1, 0)
		
		local tween = TweenService:Create(fillBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0)
		})
		tween:Play()
		tween.Completed:Connect(onComplete)
	else
		-- Fallback if no fill bar
		task.delay(duration, onComplete)
	end
end

-- Function to show notification using template
local function showNotification(data)
	-- Default values
	data.Duration = data.Duration or 5
	data.NotificationType = data.NotificationType or "SideTextOnly" -- Default to side text only
	
	print(string.format("🔔 [NOTIFICATION CLIENT] Showing notification: %s (Type: %s)", 
		data.Message, data.NotificationType))
	
	-- If no templates available, use fallback
	if not hasAnyTemplate then
		showFallbackNotification(data)
		return
	end
	
	-- Get the appropriate template
	local templateName = data.NotificationType
	local template = templates[templateName]
	
	if not template then
		warn(string.format("⚠️ [NOTIFICATION CLIENT] Template not found: %s, using fallback", templateName))
		showFallbackNotification(data)
		return
	end
	
	-- Clone template
	local notif = template:Clone()
	notif.Name = "ActiveNotification"
	notif.Parent = notificationGui
	notif.Visible = true
	
	print(string.format("🔔 [DEBUG] Template cloned: %s -> Parent: %s", template.Name, notif.Parent.Name))
	print(string.format("🔔 [DEBUG] Notif position: %s, Size: %s", tostring(notif.Position), tostring(notif.Size)))
	
	-- Set notification text
	local mainInfo = notif:FindFirstChild("MainInfo")
	print(string.format("🔔 [DEBUG] MainInfo found: %s", tostring(mainInfo ~= nil)))
	
	-- Debug: list children of notif
	print("🔔 [DEBUG] Template children:")
	for _, child in ipairs(notif:GetChildren()) do
		print(string.format("   - %s (%s)", child.Name, child.ClassName))
	end
	
	if mainInfo then
		local notifInfo = mainInfo:FindFirstChild("NotificationInfo")
		local notifText = notifInfo and notifInfo:FindFirstChild("NotificationText")
		
		if notifText then
			notifText.Text = data.Message or "Notification"
		else
			-- Try direct child
			notifText = mainInfo:FindFirstChild("NotificationText")
			if notifText then
				notifText.Text = data.Message or "Notification"
			end
		end
		
		-- Get timer slider
		local timerSlider = notifInfo and notifInfo:FindFirstChild("TimerSlider")
		if not timerSlider then
			timerSlider = mainInfo:FindFirstChild("TimerSlider")
		end
		
		-- Handle sender info if applicable
		local senderInfo = mainInfo:FindFirstChild("SenderInfo")
		if senderInfo and data.Sender then
			-- Set avatar
			local avatar = senderInfo:FindFirstChild("Avatar")
			if avatar then
				avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. (data.Sender.UserId or player.UserId) .. "&w=150&h=150"
			end
			
			-- Set player name and username
			local namePanel = senderInfo:FindFirstChild("SenderNameUsernamePanel")
			if namePanel then
				local playerName = namePanel:FindFirstChild("PlayerName")
				local username = namePanel:FindFirstChild("Username")
				
				if playerName then
					playerName.Text = data.Sender.DisplayName or data.Sender.Name or "Admin"
				end
				if username then
					username.Text = "@" .. (data.Sender.Name or "admin")
				end
			end
		elseif senderInfo then
			-- If no sender data but template has sender info, use current admin
			if data.SenderUserId then
				local avatar = senderInfo:FindFirstChild("Avatar")
				if avatar then
					avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. data.SenderUserId .. "&w=150&h=150"
				end
				
				local namePanel = senderInfo:FindFirstChild("SenderNameUsernamePanel")
				if namePanel then
					local playerName = namePanel:FindFirstChild("PlayerName")
					local username = namePanel:FindFirstChild("Username")
					
					if playerName then
						playerName.Text = data.SenderName or "Admin"
					end
					if username then
						username.Text = "@" .. (data.SenderUsername or "admin")
					end
				end
			end
		end
		
		-- Animate timer slider
		animateTimerSlider(timerSlider, data.Duration, function()
			-- Fade out animation
			local fadeOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			})
			
			-- Fade out all descendants
			for _, desc in ipairs(notif:GetDescendants()) do
				if desc:IsA("Frame") then
					TweenService:Create(desc, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
				elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
					TweenService:Create(desc, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
				elseif desc:IsA("ImageLabel") then
					TweenService:Create(desc, TweenInfo.new(0.3), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
				end
			end
			
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				notif:Destroy()
				activeNotification = nil
				
				-- Show next in queue
				if #notificationQueue > 0 then
					local nextData = table.remove(notificationQueue, 1)
					showNotification(nextData)
				end
			end)
		end)
	else
		-- No MainInfo, use fallback
		notif:Destroy()
		showFallbackNotification(data)
		return
	end
	
	-- Setup close/skip button
	local closeButton = notif:FindFirstChild("CloseButton")
	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			-- Immediately remove notification
			local fadeOut = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			})
			
			for _, desc in ipairs(notif:GetDescendants()) do
				if desc:IsA("Frame") then
					TweenService:Create(desc, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
					TweenService:Create(desc, TweenInfo.new(0.2), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
				elseif desc:IsA("ImageLabel") then
					TweenService:Create(desc, TweenInfo.new(0.2), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
				end
			end
			
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				notif:Destroy()
				activeNotification = nil
				
				if #notificationQueue > 0 then
					local nextData = table.remove(notificationQueue, 1)
					showNotification(nextData)
				end
			end)
		end)
	end
	
	-- Slide in animation based on position type
	if templateName:find("Middle") then
		-- Center animation - scale up
		notif.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = template.Size
		}):Play()
	else
		-- Side animation - slide in from right
		local originalPos = notif.Position
		notif.Position = UDim2.new(originalPos.X.Scale + 0.3, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset)
		TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = originalPos
		}):Play()
	end
	
	activeNotification = notif
	
	-- Play sound
	playSound("rbxassetid://6026984224")
end

-- Listen for notifications
showNotificationEvent.OnClientEvent:Connect(function(data)
	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION CLIENT] Invalid notification data")
		return
	end

	print(string.format("📥 [NOTIFICATION CLIENT] Received: %s (Type: %s)", 
		data.Message, data.NotificationType or "SideTextOnly"))
	
	-- Queue if there's an active notification
	if activeNotification then
		table.insert(notificationQueue, data)
		print(string.format("📥 [NOTIFICATION CLIENT] Queued notification, queue size: %d", #notificationQueue))
	else
		showNotification(data)
	end
end)

print("✅ [NOTIFICATION CLIENT] Loaded with UI templates (fallback enabled)")