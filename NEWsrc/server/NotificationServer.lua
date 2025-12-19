--[[
    NOTIFICATION SERVER
    Place in ServerScriptService/NotificationServer
    
    Supports 4 notification types:
    - MiddleTextOnly: Center of screen, text only
    - MiddleWithSender: Center of screen, with sender info
    - SideTextOnly: Side of screen, text only (DEFAULT)
    - SideWithSender: Side of screen, with sender info
    
    Notification Targets:
    - Send(player, data): Single player
    - SendToAll(data): All players in THIS server
    - SendToServer(data): All players in THIS server (alias)
    - SendGlobal(data): All players in ALL servers (uses MessagingService)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local NotificationServer = {}

local GLOBAL_NOTIFICATION_TOPIC = "GlobalNotification"

-- Create communication folder
local notificationComm = ReplicatedStorage:FindFirstChild("NotificationComm")
if not notificationComm then
	notificationComm = Instance.new("Folder")
	notificationComm.Name = "NotificationComm"
	notificationComm.Parent = ReplicatedStorage
end

-- Create RemoteEvent
local showNotificationEvent = notificationComm:FindFirstChild("ShowNotification")
if not showNotificationEvent then
	showNotificationEvent = Instance.new("RemoteEvent")
	showNotificationEvent.Name = "ShowNotification"
	showNotificationEvent.Parent = notificationComm
end

print("✅ [NOTIFICATION SERVER] Initialized")

--[[ Send notification to a specific player ]]
function NotificationServer:Send(player, data)
	if not player or not player:IsA("Player") or not player.Parent then
		return
	end

	if not data or not data.Message then
		return
	end

	data.NotificationType = data.NotificationType or "SideTextOnly"
	data.Duration = data.Duration or 5

	pcall(function()
		showNotificationEvent:FireClient(player, data)
	end)
end

--[[ Send notification to all players in THIS SERVER ONLY ]]
function NotificationServer:SendToAll(data, sender)
	if not data or not data.Message then
		return
	end
	
	if sender and (data.NotificationType == "MiddleWithSender" or data.NotificationType == "SideWithSender") then
		data.SenderUserId = sender.UserId
		data.SenderName = sender.Name
		data.SenderUsername = sender.Name
		data.Sender = {
			UserId = sender.UserId,
			Name = sender.Name,
			DisplayName = sender.DisplayName
		}
	end

	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, data)
		count = count + 1
	end

	print(string.format("📢 [NOTIF SERVER] Broadcast to %d players in THIS server", count))
end

-- ✅ ALIAS: SendToServer = SendToAll (only THIS server)
function NotificationServer:SendToServer(data, sender)
	return self:SendToAll(data, sender)
end

--[[ 
    ✅ GLOBAL: Send notification to ALL SERVERS via MessagingService
    This sends the notification to every active server
]]
function NotificationServer:SendGlobal(data, sender)
	if not data or not data.Message then
		return
	end
	
	-- Add sender info if provided
	if sender then
		data.SenderUserId = sender.UserId
		data.SenderName = sender.Name
		data.SenderDisplayName = sender.DisplayName
	end
	
	-- Send to all servers via MessagingService
	local success, err = pcall(function()
		local jsonData = HttpService:JSONEncode(data)
		MessagingService:PublishAsync(GLOBAL_NOTIFICATION_TOPIC, jsonData)
	end)
	
	if success then
		print(string.format("🌍 [NOTIF GLOBAL] Sent '%s' to ALL servers", data.Message))
	else
		warn(string.format("⚠️ [NOTIF GLOBAL] Failed: %s", tostring(err)))
		-- Fallback: at least send to this server
		self:SendToAll(data, sender)
	end
end

-- ✅ LISTEN for incoming global notifications from other servers
pcall(function()
	MessagingService:SubscribeAsync(GLOBAL_NOTIFICATION_TOPIC, function(messageData)
		local success, data = pcall(function()
			return HttpService:JSONDecode(messageData.Data)
		end)
		
		if success and data and data.Message then
			print(string.format("🌍 [NOTIF GLOBAL RECEIVED] '%s'", data.Message))
			
			-- Send to all players in this server
			for _, player in ipairs(Players:GetPlayers()) do
				NotificationServer:Send(player, data)
			end
		end
	end)
	print("✅ [NOTIFICATION SERVER] Global listener ready")
end)

--[[ Send notification to multiple players ]]
function NotificationServer:SendToPlayers(players, data)
	if not players or #players == 0 then
		return
	end

	for _, player in ipairs(players) do
		self:Send(player, data)
	end
end

--[[ Send notification to all admins ]]
function NotificationServer:SendToAdmins(data, adminIds)
	if not adminIds or #adminIds == 0 then
		return
	end

	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if table.find(adminIds, player.UserId) then
			self:Send(player, data)
			count = count + 1
		end
	end

	print(string.format("👑 [NOTIF SERVER] Sent to %d admins", count))
end

return NotificationServer

