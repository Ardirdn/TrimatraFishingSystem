--[[
    EVENT MANAGER (CROSS-SERVER)
    Place in ServerScriptService/EventManager
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EventConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EventConfig"))
local NotificationService = require(script.Parent.NotificationServer)

-- ✅ CROSS-SERVER DATASTORE
local EventDataStore = DataStoreService:GetDataStore("GlobalEvents_v1")
local EVENT_KEY = "ActiveEvent"

-- Create RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("EventRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "EventRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getActiveEventFunc = remoteFolder:FindFirstChild("GetActiveEvent")
if not getActiveEventFunc then
	getActiveEventFunc = Instance.new("RemoteFunction")
	getActiveEventFunc.Name = "GetActiveEvent"
	getActiveEventFunc.Parent = remoteFolder
end

local setEventRemote = remoteFolder:FindFirstChild("SetEvent")
if not setEventRemote then
	setEventRemote = Instance.new("RemoteEvent")
	setEventRemote.Name = "SetEvent"
	setEventRemote.Parent = remoteFolder
end

local eventChangedRemote = remoteFolder:FindFirstChild("EventChanged")
if not eventChangedRemote then
	eventChangedRemote = Instance.new("RemoteEvent")
	eventChangedRemote.Name = "EventChanged"
	eventChangedRemote.Parent = remoteFolder
end

print("✅ [EVENT MANAGER] Initialized")

-- ==================== GLOBAL STATE ====================

local CurrentActiveEvent = nil -- {Id, Multiplier}

-- ==================== HELPER FUNCTIONS ====================

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local function isAdmin(player)
	local data = require(script.Parent.DataHandler):GetData(player)
	if data and data.EquippedTitle == "Admin" then
		return true
	end

	if TitleConfig.AdminIds then
		for _, adminId in ipairs(TitleConfig.AdminIds) do
			if player.UserId == adminId then
				return true
			end
		end
	end

	return false
end

local function loadEventFromDataStore()
	local success, result = pcall(function()
		return EventDataStore:GetAsync(EVENT_KEY)
	end)

	if success and result then
		-- ✅ Rebuild full event data from EventConfig
		for _, event in ipairs(EventConfig.AvailableEvents) do
			if event.Id == result.Id then
				CurrentActiveEvent = {
					Id = result.Id,
					Name = result.Name,
					Multiplier = result.Multiplier,
					Icon = event.Icon,
					Color = event.Color
				}
				print(string.format("📡 [EVENT MANAGER] Loaded event from DataStore: %s (x%d)", result.Id, result.Multiplier))
				return
			end
		end
	else
		CurrentActiveEvent = nil
		print("📡 [EVENT MANAGER] No active event")
	end
end


local function saveEventToDataStore(eventData)
	-- ✅ Convert to simple table (DataStore hanya terima string/number/table sederhana)
	local simpleData = nil

	if eventData then
		simpleData = {
			Id = eventData.Id,
			Name = eventData.Name,
			Multiplier = eventData.Multiplier,
			-- ❌ JANGAN save Color3 (DataStore tidak support!)
		}
	end

	local success, err = pcall(function()
		EventDataStore:SetAsync(EVENT_KEY, simpleData)
	end)

	if not success then
		warn("⚠️ [EVENT MANAGER] Failed to save event to DataStore:", err)
	end

	return success
end


local function getEventMultiplier()
	if CurrentActiveEvent then
		return CurrentActiveEvent.Multiplier
	end
	return 1 -- Default: no multiplier
end

local function broadcastEventChange()
	for _, player in ipairs(Players:GetPlayers()) do
		eventChangedRemote:FireClient(player, CurrentActiveEvent)
	end
end

-- ==================== ADMIN FUNCTIONS ====================

local function activateEvent(eventId)
	-- Find event
	local eventData = nil
	for _, event in ipairs(EventConfig.AvailableEvents) do
		if event.Id == eventId then
			eventData = {
				Id = event.Id,
				Name = event.Name,
				Multiplier = event.Multiplier,
				Icon = event.Icon,
				Color = event.Color
			}
			break
		end
	end

	if not eventData then
		warn(string.format("⚠️ [EVENT MANAGER] Event not found: %s", eventId))
		return false
	end

	-- Save to DataStore (cross-server)
	CurrentActiveEvent = eventData
	saveEventToDataStore(eventData)

	-- Broadcast to all players
	broadcastEventChange()

	print(string.format("🎉 [EVENT MANAGER] Event activated: %s (x%d)", eventData.Name, eventData.Multiplier))
	return true
end

local function deactivateEvent()
	CurrentActiveEvent = nil
	saveEventToDataStore(nil)

	-- Broadcast to all players
	broadcastEventChange()

	print("🎉 [EVENT MANAGER] Event deactivated")
	return true
end

-- ==================== REMOTE HANDLERS ====================

getActiveEventFunc.OnServerInvoke = function(player)
	return CurrentActiveEvent
end

setEventRemote.OnServerEvent:Connect(function(player, action, eventId)
	if not isAdmin(player) then
		NotificationService:Send(player, {
			Message = "You don't have permission!",
			Type = "error",
			Duration = 3
		})
		return
	end

	if action == "activate" then
		local success = activateEvent(eventId)
		if success then
			NotificationService:Send(player, {
				Message = string.format("Event %s activated!", eventId),
				Type = "success",
				Duration = 5,
				Icon = "🎉"
			})

			-- ✅ PERFORMANCE FIX: Stagger notifications to prevent lag spike
			local otherPlayers = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					table.insert(otherPlayers, p)
				end
			end
			
			for i, p in ipairs(otherPlayers) do
				task.delay(i * 0.1, function()  -- 0.1s between each notification
					if p and p.Parent then
						NotificationService:Send(p, {
							Message = string.format("Event %s is now active!", CurrentActiveEvent.Name),
							Type = "info",
							Duration = 5,
							Icon = CurrentActiveEvent.Icon
						})
					end
				end)
			end
		end
	elseif action == "deactivate" then
		deactivateEvent()
		NotificationService:Send(player, {
			Message = "Event deactivated",
			Type = "info",
			Duration = 3
		})

		-- ✅ PERFORMANCE FIX: Stagger notifications
		local otherPlayers = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				table.insert(otherPlayers, p)
			end
		end
		
		for i, p in ipairs(otherPlayers) do
			task.delay(i * 0.1, function()
				if p and p.Parent then
					NotificationService:Send(p, {
						Message = "Event has ended",
						Type = "info",
						Duration = 3
					})
				end
			end)
		end
	end
end)

-- ==================== INITIALIZE ====================

loadEventFromDataStore()

-- Notify new players about active event
Players.PlayerAdded:Connect(function(player)
	task.wait(5) -- Wait for player to load
	if CurrentActiveEvent then
		NotificationService:Send(player, {
			Message = string.format("%s is active! (x%d Summit)", CurrentActiveEvent.Name, CurrentActiveEvent.Multiplier),
			Type = "info",
			Duration = 7,
			Icon = CurrentActiveEvent.Icon
		})
	end
end)

-- ==================== EXPORT ====================

local EventManager = {}

function EventManager:GetMultiplier()
	return getEventMultiplier()
end

function EventManager:GetActiveEvent()
	return CurrentActiveEvent
end

-- ✅ ADDED: Export via _G so other ServerScripts can access
_G.GetEventMultiplier = function()
	return getEventMultiplier()
end

_G.GetActiveEvent = function()
	return CurrentActiveEvent
end

_G.EventManager = EventManager

print("✅ [EVENT MANAGER] System loaded")
print("✅ [EVENT MANAGER] Exported to _G.EventManager, _G.GetEventMultiplier, _G.GetActiveEvent")

return EventManager

