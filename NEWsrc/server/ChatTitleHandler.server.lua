--[[
    CHAT TITLE SERVER (SIMPLIFIED - NO LOOPS)
    Just provides chat title integration - NO broadcasting loops
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TitleServer
local TitleServer = require(script.Parent:WaitForChild("TitleServer"))

print("✅ [CHAT TITLE SERVER] Initializing...")

-- Get or create TitleRemotes folder
local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not titleRemotes then
	titleRemotes = Instance.new("Folder")
	titleRemotes.Name = "TitleRemotes"
	titleRemotes.Parent = ReplicatedStorage
end

-- ✅ CREATE ChatTitleUpdate RemoteEvent
local chatTitleUpdate = titleRemotes:FindFirstChild("ChatTitleUpdate")
if not chatTitleUpdate then
	chatTitleUpdate = Instance.new("RemoteEvent")
	chatTitleUpdate.Name = "ChatTitleUpdate"
	chatTitleUpdate.Parent = titleRemotes
end

-- Get BroadcastTitle (already created by TitleServer)
local BroadcastTitle = titleRemotes:WaitForChild("BroadcastTitle", 10)
if not BroadcastTitle then
	warn("[CHAT TITLE SERVER] BroadcastTitle not found!")
	return
end

-- ✅ SIMPLIFIED: No loops, no bulk broadcasts
-- Client will use GetTitle RemoteFunction to fetch titles when needed
-- Chat system uses TextChatService.OnIncomingMessage which fetches per-message

print("✅ [CHAT TITLE SERVER] Loaded (simplified - no broadcast loops)")
