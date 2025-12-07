--[[
    CHAT TITLE CLIENT
    Applies title prefixes to chat messages
]]

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

print("✅ [CHAT TITLE CLIENT] Initializing...")

-- Wait for TitleConfig
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Wait for RemoteEvents
local titleRemotes = ReplicatedStorage:WaitForChild("TitleRemotes", 30)
if not titleRemotes then
	warn("[CHAT TITLE CLIENT] TitleRemotes not found!")
	return
end

local chatTitleUpdate = titleRemotes:WaitForChild("ChatTitleUpdate", 30)
if not chatTitleUpdate then
	warn("[CHAT TITLE CLIENT] ChatTitleUpdate not found!")
	return
end

-- ✅ Also listen to BroadcastTitle (from TitleServer)
local BroadcastTitle = titleRemotes:WaitForChild("BroadcastTitle", 10)

-- Cache player titles
local playerTitles = {}

-- Listen for chat-specific title updates
chatTitleUpdate.OnClientEvent:Connect(function(userId, titleName)
	playerTitles[userId] = titleName
	print(string.format("[CHAT TITLE CLIENT] Updated title for UserID %d: %s", userId, titleName or "None"))
end)

-- ✅ ALSO listen to BroadcastTitle (for immediate equip/unequip)
if BroadcastTitle then
	BroadcastTitle.OnClientEvent:Connect(function(userId, titleName)
		playerTitles[userId] = titleName
		print(string.format("[CHAT TITLE CLIENT] Updated title (broadcast) for UserID %d: %s", userId, titleName or "None"))
	end)
end

-- Function: Create gradient text
local function GradientText(text, colors)
	local result = ""
	local length = #text

	if length == 0 then return "" end

	if #colors < 2 then
		local color = colors[1] or Color3.fromRGB(255, 255, 255)
		return string.format("<font color='rgb(%d,%d,%d)'>%s</font>", 
			math.floor(color.R * 255), 
			math.floor(color.G * 255), 
			math.floor(color.B * 255), 
			text)
	end

	for i = 1, length do
		local ratio = (i - 1) / math.max(length - 1, 1)
		local colorIndex = math.floor(ratio * (#colors - 1)) + 1
		local nextIndex = math.min(colorIndex + 1, #colors)
		local c1, c2 = colors[colorIndex], colors[nextIndex]
		local t = (ratio * (#colors - 1)) % 1

		local r = math.floor(c1.R * 255 * (1 - t) + c2.R * 255 * t)
		local g = math.floor(c1.G * 255 * (1 - t) + c2.G * 255 * t)
		local b = math.floor(c1.B * 255 * (1 - t) + c2.B * 255 * t)

		local char = text:sub(i, i)
		result ..= string.format("<font color='rgb(%d,%d,%d)'>%s</font>", r, g, b, char)
	end

	return result
end

-- Setup TextChatService
task.wait(2)

local textChannels = TextChatService:WaitForChild("TextChannels", 10)
if not textChannels then
	warn("[CHAT TITLE CLIENT] TextChannels not found")
	return
end

local rbxGeneral = textChannels:WaitForChild("RBXGeneral", 10)
if not rbxGeneral then
	warn("[CHAT TITLE CLIENT] RBXGeneral not found")
	return
end

print("[CHAT TITLE CLIENT] Found RBXGeneral channel")

-- Set OnIncomingMessage
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")

	if not message.TextSource then
		return properties
	end

	local userId = message.TextSource.UserId
	local titleName = playerTitles[userId]

	if not titleName then
		return properties
	end

	-- Find title data
	local titleData = nil

	if TitleConfig.SpecialTitles[titleName] then
		titleData = TitleConfig.SpecialTitles[titleName]
	else
		for _, summitTitle in ipairs(TitleConfig.SummitTitles) do
			if summitTitle.Name == titleName then
				titleData = summitTitle
				break
			end
		end
	end

	if titleData then
		local displayName = titleData.DisplayName or titleName
		local icon = titleData.Icon or ""
		local colors = titleData.Colors or {titleData.Color or Color3.fromRGB(255, 255, 255)}

		local tagText = string.format("[%s %s]", icon, displayName)
		local gradientTag = GradientText(tagText, colors)

		properties.PrefixText = gradientTag .. " " .. message.PrefixText

		print(string.format("[CHAT TITLE CLIENT] ✅ Applied title for %s: %s", message.TextSource.Name, displayName))
	end

	return properties
end

print("✅ [CHAT TITLE CLIENT] System active")
