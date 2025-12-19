--[[
    MUSIC SERVER
    Place in ServerScriptService/MusicServer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)

-- Create RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "MusicRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local toggleFavoriteEvent = remoteFolder:FindFirstChild("ToggleFavorite")
if not toggleFavoriteEvent then
	toggleFavoriteEvent = Instance.new("RemoteEvent")
	toggleFavoriteEvent.Name = "ToggleFavorite"
	toggleFavoriteEvent.Parent = remoteFolder
end

local getFavoritesFunc = remoteFolder:FindFirstChild("GetFavorites")
if not getFavoritesFunc then
	getFavoritesFunc = Instance.new("RemoteFunction")
	getFavoritesFunc.Name = "GetFavorites"
	getFavoritesFunc.Parent = remoteFolder
end

print("✅ [MUSIC SERVER] Initialized")

-- Toggle favorite
toggleFavoriteEvent.OnServerEvent:Connect(function(player, songId)
	if not player or not songId then return end

	local isFavorite = DataHandler:ArrayContains(player, "FavoriteMusic", songId)

	if isFavorite then
		-- Remove from favorites
		DataHandler:RemoveFromArray(player, "FavoriteMusic", songId)
		print(string.format("🎵 [MUSIC] %s removed favorite: %s", player.Name, songId))
	else
		-- Add to favorites
		DataHandler:AddToArray(player, "FavoriteMusic", songId)
		print(string.format("🎵 [MUSIC] %s added favorite: %s", player.Name, songId))
	end

	-- Save
	DataHandler:SavePlayer(player)
end)

-- Get favorites
getFavoritesFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)

	if data then
		return data.FavoriteMusic or {}
	end

	return {}
end

print("✅ [MUSIC SERVER] System loaded")
