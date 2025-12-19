--[[
    VIBE SERVER - MINIMAL (Save/Load Only)
    Only handles saving and loading player's theme preference
    Lighting changes are handled locally by client
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local DataHandler = require(script.Parent.DataHandler)

-- ✅ CREATE REMOTE FOLDER
local remoteFolder = ReplicatedStorage:FindFirstChild("VibeRemotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "VibeRemotes"
    remoteFolder.Parent = ReplicatedStorage
end

-- Remote untuk save theme
local saveThemeEvent = remoteFolder:FindFirstChild("SaveTheme")
if not saveThemeEvent then
    saveThemeEvent = Instance.new("RemoteEvent")
    saveThemeEvent.Name = "SaveTheme"
    saveThemeEvent.Parent = remoteFolder
end

-- Remote untuk get saved theme
local getThemeFunc = remoteFolder:FindFirstChild("GetTheme")
if not getThemeFunc then
    getThemeFunc = Instance.new("RemoteFunction")
    getThemeFunc.Name = "GetTheme"
    getThemeFunc.Parent = remoteFolder
end

print("✅ [VIBE SERVER] Remotes created (Save/Load only)")

-- ✅ HANDLE SAVE THEME REQUEST
saveThemeEvent.OnServerEvent:Connect(function(player, themeKey)
    if not player or not player.Parent then return end
    if not themeKey or type(themeKey) ~= "string" then return end
    
    -- Save to DataHandler
    DataHandler:Set(player, "VibeTheme", themeKey)
    DataHandler:SavePlayer(player)
    
    print(string.format("💾 [VIBE SERVER] Saved theme for %s: %s", player.Name, themeKey))
end)

-- ✅ HANDLE GET THEME REQUEST
getThemeFunc.OnServerInvoke = function(player)
    if not player or not player.Parent then return nil end
    
    local data = DataHandler:GetData(player)
    if data and data.VibeTheme then
        return data.VibeTheme
    end
    
    return nil -- Return nil if no saved theme
end

print("✅ [VIBE SERVER] System loaded (Minimal - Save/Load only)")
