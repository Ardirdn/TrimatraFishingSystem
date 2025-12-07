--[[
    CHAT TITLE SERVER
    Broadcasts title updates to clients
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TitleServer
local TitleServer = require(script.Parent:WaitForChild("TItleServer"))

print("✅ [CHAT TITLE SERVER] Initializing...")

-- Get or create TitleRemotes folder
local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not titleRemotes then
	titleRemotes = Instance.new("Folder")
	titleRemotes.Name = "TitleRemotes"
	titleRemotes.Parent = ReplicatedStorage
	print("✅ [CHAT TITLE SERVER] Created TitleRemotes folder")
end

-- ✅ CREATE ChatTitleUpdate RemoteEvent
local chatTitleUpdate = titleRemotes:FindFirstChild("ChatTitleUpdate")
if not chatTitleUpdate then
	chatTitleUpdate = Instance.new("RemoteEvent")
	chatTitleUpdate.Name = "ChatTitleUpdate"
	chatTitleUpdate.Parent = titleRemotes
	print("✅ [CHAT TITLE SERVER] Created ChatTitleUpdate RemoteEvent")
end

-- Get BroadcastTitle (already created by TitleServer)
local BroadcastTitle = titleRemotes:WaitForChild("BroadcastTitle", 10)
if not BroadcastTitle then
	warn("[CHAT TITLE SERVER] BroadcastTitle not found!")
	return
end

-- Function: Broadcast all players' titles to a client
local function BroadcastAllTitlesToClient(client)
	for _, player in ipairs(Players:GetPlayers()) do
		local titleName = TitleServer:GetPlayerTitle(player)
		chatTitleUpdate:FireClient(client, player.UserId, titleName)
	end
end

-- When player joins
Players.PlayerAdded:Connect(function(player)
	-- Wait for player to load
	task.wait(3)

	-- Send this player's title to all clients
	local titleName = TitleServer:GetPlayerTitle(player)
	chatTitleUpdate:FireAllClients(player.UserId, titleName)
	print(string.format("[CHAT TITLE SERVER] Broadcasted title for %s: %s", player.Name, titleName or "None"))

	-- Send all other players' titles to this player
	BroadcastAllTitlesToClient(player)
end)

-- ✅ Listen for title changes (equip/unequip) from TitleServer
-- TitleServer fires BroadcastTitle:FireAllClients(userId, titleName)
-- We need to relay this to ChatTitleUpdate

-- Connection pattern: Wait for existing BroadcastTitle events
task.spawn(function()
	-- Monitor BroadcastTitle being fired and relay to chat system
	-- This is handled automatically by TitleServer's BroadcastTitle:FireAllClients
	-- which we'll intercept on the client side
end)

print("✅ [CHAT TITLE SERVER] Loaded")
