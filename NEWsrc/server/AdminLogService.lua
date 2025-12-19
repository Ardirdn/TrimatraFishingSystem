--[[
    ADMIN LOG SERVER
    Menyimpan dan mengambil log aktivitas admin
    Menggunakan DataStore untuk sinkronisasi antar server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- DataStore untuk log
local AdminLogStore = DataStoreService:GetDataStore("AdminLogs_v1")
local AdminListStore = DataStoreService:GetDataStore("AdminList_v1")

-- TitleConfig untuk cek admin
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Create RemoteEvents folder
local remoteFolder = ReplicatedStorage:FindFirstChild("AdminRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "AdminRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create Log RemoteFunction
local getLogsFunc = remoteFolder:FindFirstChild("GetAdminLogs")
if not getLogsFunc then
	getLogsFunc = Instance.new("RemoteFunction")
	getLogsFunc.Name = "GetAdminLogs"
	getLogsFunc.Parent = remoteFolder
end

-- Create Admin List RemoteFunction
local getAdminListFunc = remoteFolder:FindFirstChild("GetAdminList")
if not getAdminListFunc then
	getAdminListFunc = Instance.new("RemoteFunction")
	getAdminListFunc.Name = "GetAdminList"
	getAdminListFunc.Parent = remoteFolder
end

-- Create Log Event (for adding logs)
local addLogEvent = remoteFolder:FindFirstChild("AddAdminLog")
if not addLogEvent then
	addLogEvent = Instance.new("BindableEvent")
	addLogEvent.Name = "AddAdminLog"
	addLogEvent.Parent = remoteFolder
end

-- Helper: Check if primary admin
local function isPrimaryAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId)
end

-- ==================== LOG MANAGEMENT ====================

-- Max logs to keep per category
local MAX_LOGS_PER_CATEGORY = 500
local MAX_TOTAL_LOGS = 2000

-- Action types
local ACTION_TYPES = {
	"kick",
	"ban", 
	"freeze",
	"set_title",
	"give_title",
	"set_summit",
	"notification",
	"teleport",
	"kill",
	"give_items",
	"set_speed",
	"set_gravity",
	"delete_data"
}

-- Add log to DataStore
local function addLog(adminUserId, adminName, actionType, targetInfo, details)
	local timestamp = os.time()
	local dateString = os.date("%Y-%m-%d %H:%M:%S", timestamp)
	
	local logEntry = {
		AdminUserId = adminUserId,
		AdminName = adminName,
		ActionType = actionType,
		TargetUserId = targetInfo.UserId or 0,
		TargetName = targetInfo.Name or "N/A",
		Details = details or "",
		Timestamp = timestamp,
		Date = dateString,
		ServerId = game.JobId or "Studio"
	}
	
	-- Save to all logs
	local success, err = pcall(function()
		AdminLogStore:UpdateAsync("AllLogs", function(oldData)
			local logs = oldData or {}
			table.insert(logs, 1, logEntry) -- Insert at beginning (newest first)
			
			-- Trim if too many
			if #logs > MAX_TOTAL_LOGS then
				for i = MAX_TOTAL_LOGS + 1, #logs do
					logs[i] = nil
				end
			end
			
			return logs
		end)
	end)
	
	if not success then
		warn("[ADMIN LOG] Failed to save to AllLogs:", err)
	end
	
	-- Save to action-specific logs
	local actionKey = "Logs_" .. actionType
	local success2, err2 = pcall(function()
		AdminLogStore:UpdateAsync(actionKey, function(oldData)
			local logs = oldData or {}
			table.insert(logs, 1, logEntry)
			
			if #logs > MAX_LOGS_PER_CATEGORY then
				for i = MAX_LOGS_PER_CATEGORY + 1, #logs do
					logs[i] = nil
				end
			end
			
			return logs
		end)
	end)
	
	if not success2 then
		warn("[ADMIN LOG] Failed to save to", actionKey, ":", err2)
	end
	
	-- Save to admin-specific logs
	local adminKey = "Admin_" .. tostring(adminUserId)
	local success3, err3 = pcall(function()
		AdminLogStore:UpdateAsync(adminKey, function(oldData)
			local logs = oldData or {}
			table.insert(logs, 1, logEntry)
			
			if #logs > MAX_LOGS_PER_CATEGORY then
				for i = MAX_LOGS_PER_CATEGORY + 1, #logs do
					logs[i] = nil
				end
			end
			
			return logs
		end)
	end)
	
	if not success3 then
		warn("[ADMIN LOG] Failed to save to", adminKey, ":", err3)
	end
	
	-- Update admin list
	local success4, err4 = pcall(function()
		AdminListStore:UpdateAsync("AdminActivity", function(oldData)
			local adminList = oldData or {}
			
			-- Find or create admin entry
			local found = false
			for _, admin in ipairs(adminList) do
				if admin.UserId == adminUserId then
					admin.LastAction = dateString
					admin.TotalActions = (admin.TotalActions or 0) + 1
					admin.Name = adminName -- Update name in case it changed
					found = true
					break
				end
			end
			
			if not found then
				table.insert(adminList, {
					UserId = adminUserId,
					Name = adminName,
					FirstAction = dateString,
					LastAction = dateString,
					TotalActions = 1,
					IsPrimary = isPrimaryAdmin(adminUserId)
				})
			end
			
			return adminList
		end)
	end)
	
	if not success4 then
		warn("[ADMIN LOG] Failed to update admin list:", err4)
	end
	
	print(string.format("[ADMIN LOG] ✅ %s performed %s on %s", adminName, actionType, targetInfo.Name or "N/A"))
end

-- ==================== REMOTE HANDLERS ====================

-- Get logs (only primary admin)
getLogsFunc.OnServerInvoke = function(player, filter, adminFilter)
	if not isPrimaryAdmin(player.UserId) then
		return { success = false, message = "Access denied" }
	end
	
	local dataKey = "AllLogs"
	
	-- Filter by action type
	if filter and filter ~= "all" then
		dataKey = "Logs_" .. filter
	end
	
	-- Filter by admin
	if adminFilter and adminFilter ~= "" then
		dataKey = "Admin_" .. tostring(adminFilter)
	end
	
	local success, result = pcall(function()
		return AdminLogStore:GetAsync(dataKey) or {}
	end)
	
	if not success then
		warn("[ADMIN LOG] Failed to get logs:", result)
		return { success = false, message = "Failed to retrieve logs" }
	end
	
	return { success = true, logs = result }
end

-- Get admin list (only primary admin)
getAdminListFunc.OnServerInvoke = function(player)
	if not isPrimaryAdmin(player.UserId) then
		return { success = false, message = "Access denied" }
	end
	
	-- Get from DataStore
	local success, result = pcall(function()
		return AdminListStore:GetAsync("AdminActivity") or {}
	end)
	
	if not success then
		warn("[ADMIN LOG] Failed to get admin list:", result)
		return { success = false, message = "Failed to retrieve admin list" }
	end
	
	-- Merge with TitleConfig admins (in case some never did any action)
	local allAdmins = result
	local existingIds = {}
	
	for _, admin in ipairs(allAdmins) do
		existingIds[admin.UserId] = true
		admin.IsPrimary = isPrimaryAdmin(admin.UserId)
	end
	
	-- Add primary admins from config
	for _, userId in ipairs(TitleConfig.PrimaryAdminIds) do
		if not existingIds[userId] then
			local name = "Unknown"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			
			table.insert(allAdmins, {
				UserId = userId,
				Name = name,
				FirstAction = "Never",
				LastAction = "Never",
				TotalActions = 0,
				IsPrimary = true
			})
		end
	end
	
	-- Add secondary admins from config
	for _, userId in ipairs(TitleConfig.SecondaryAdminIds) do
		if not existingIds[userId] then
			local name = "Unknown"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			
			table.insert(allAdmins, {
				UserId = userId,
				Name = name,
				FirstAction = "Never",
				LastAction = "Never",
				TotalActions = 0,
				IsPrimary = false
			})
		end
	end
	
	return { success = true, admins = allAdmins }
end

-- ==================== BINDABLE EVENT LISTENER ====================
-- This allows other scripts (AdminServer) to add logs

addLogEvent.Event:Connect(function(adminUserId, adminName, actionType, targetInfo, details)
	addLog(adminUserId, adminName, actionType, targetInfo, details)
end)

-- Export function for direct calls from same context
local AdminLogService = {}

function AdminLogService:Log(adminUserId, adminName, actionType, targetInfo, details)
	addLog(adminUserId, adminName, actionType, targetInfo, details)
end

-- Make it available globally for server scripts
_G.AdminLogService = AdminLogService

print("✅ [ADMIN LOG SERVER] Initialized")

return AdminLogService
