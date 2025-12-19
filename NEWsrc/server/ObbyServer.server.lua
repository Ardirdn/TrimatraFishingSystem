--[[
    OBBY SERVER
    Server-side handler untuk Obby Replacement System
    
    Menangani:
    - Replace obby dengan template baru
    - Cooldown system (server & player)
    - Check apakah ada player di area obby
    
    Setup:
    - Template obby di ServerStorage > Obby > [ObbyName]
    - Active obby di Workspace > map > Obby > [ObbyName]
    - Folder "Areas" di dalam obby untuk detection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Notification Service
local NotificationService = require(script.Parent.NotificationServer)

-- ✅ CREATE REMOTE EVENTS
local remoteFolder = ReplicatedStorage:FindFirstChild("ObbyRemotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "ObbyRemotes"
    remoteFolder.Parent = ReplicatedStorage
end

local replaceObbyFunc = remoteFolder:FindFirstChild("ReplaceObby")
if not replaceObbyFunc then
    replaceObbyFunc = Instance.new("RemoteFunction")
    replaceObbyFunc.Name = "ReplaceObby"
    replaceObbyFunc.Parent = remoteFolder
end

print("✅ [OBBY SERVER] Remote events created")

-- ✅ CONFIGURATION
local CONFIG = {
    ServerCooldown = 60,        -- Global server cooldown (seconds)
    PlayerCooldown = 15,        -- Per-player cooldown (seconds)
    PromptReenableDelay = 2,    -- Delay before prompt is re-enabled
}

-- ✅ STATE
local lastServerReplace = 0
local playerCooldowns = {}

-- ✅ FOLDER REFERENCES
local ObbyTemplates = nil
local ActiveObbys = nil

local function getObbyTemplates()
    if not ObbyTemplates then
        ObbyTemplates = ServerStorage:FindFirstChild("Obby")
        if not ObbyTemplates then
            warn("⚠️ [OBBY SERVER] ServerStorage.Obby folder not found!")
        end
    end
    return ObbyTemplates
end

local function getActiveObbys()
    if not ActiveObbys then
        local mapFolder = Workspace:FindFirstChild("map")
        if mapFolder then
            ActiveObbys = mapFolder:FindFirstChild("Obby")
        end
        if not ActiveObbys then
            warn("⚠️ [OBBY SERVER] Workspace.map.Obby folder not found!")
        end
    end
    return ActiveObbys
end

-- ✅ CHECK IF PLAYER IS IN OBBY AREA
local function isPlayerInObbyArea(obbyName)
    local activeObbys = getActiveObbys()
    if not activeObbys then return true end -- Assume occupied if folder not found
    
    local obbyFolder = activeObbys:FindFirstChild(obbyName)
    if not obbyFolder then
        warn(string.format("⚠️ [OBBY SERVER] Obby folder '%s' not found", obbyName))
        return true -- Assume occupied if folder not found
    end
    
    local areasFolder = obbyFolder:FindFirstChild("Areas")
    if not areasFolder then
        warn(string.format("⚠️ [OBBY SERVER] Areas folder not found in '%s'", obbyName))
        return false -- No areas = no players
    end
    
    -- Check each area part for players
    for _, areaPart in ipairs(areasFolder:GetChildren()) do
        if areaPart:IsA("BasePart") then
            local touchingParts = Workspace:GetPartsInPart(areaPart)
            for _, part in ipairs(touchingParts) do
                local player = Players:GetPlayerFromCharacter(part.Parent)
                if player then
                    print(string.format("🚶 [OBBY SERVER] Player found in obby area: %s", player.Name))
                    return true
                end
            end
        end
    end
    
    return false
end

-- ✅ REPLACE OBBY FUNCTION
local function replaceObby(player, obbyName)
    if not player or not player.Parent then
        return "Error"
    end
    
    if not obbyName or obbyName == "" then
        NotificationService:Send(player, {
            Message = "Nama obby tidak valid!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end
    
    print(string.format("🔧 [OBBY SERVER] %s requesting replace: %s", player.Name, obbyName))
    
    -- 1. Check server cooldown
    local currentTime = os.time()
    if currentTime - lastServerReplace < CONFIG.ServerCooldown then
        local remaining = CONFIG.ServerCooldown - (currentTime - lastServerReplace)
        NotificationService:Send(player, {
            Message = string.format("Server cooldown. Coba lagi dalam %d detik.", remaining),
            Type = "error",
            Duration = 3,
            Icon = "⏳"
        })
        return "Cooldown"
    end
    
    -- 2. Check player cooldown
    if playerCooldowns[player.UserId] and currentTime - playerCooldowns[player.UserId] < CONFIG.PlayerCooldown then
        local remaining = CONFIG.PlayerCooldown - (currentTime - playerCooldowns[player.UserId])
        NotificationService:Send(player, {
            Message = string.format("Coba lagi dalam %d detik.", remaining),
            Type = "error",
            Duration = 3,
            Icon = "⏳"
        })
        return "Cooldown"
    end
    
    -- 3. Check if players are in obby area
    if isPlayerInObbyArea(obbyName) then
        NotificationService:Send(player, {
            Message = "Rintangan sedang dilewati pemain lain.",
            Type = "error",
            Duration = 3,
            Icon = "🚶"
        })
        return "InUse"
    end
    
    -- 4. Get template
    local obbyTemplates = getObbyTemplates()
    if not obbyTemplates then
        NotificationService:Send(player, {
            Message = "Template obby tidak ditemukan!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end
    
    local obbyTemplate = obbyTemplates:FindFirstChild(obbyName)
    if not obbyTemplate then
        warn(string.format("⚠️ [OBBY SERVER] Template '%s' not found in ServerStorage.Obby", obbyName))
        NotificationService:Send(player, {
            Message = "Template rintangan tidak ditemukan!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end
    
    -- 5. Get active obby folder
    local activeObbys = getActiveObbys()
    if not activeObbys then
        NotificationService:Send(player, {
            Message = "Folder obby tidak ditemukan!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end
    
    -- 6. Destroy old obby if exists
    local activeObby = activeObbys:FindFirstChild(obbyName)
    if activeObby then
        activeObby:Destroy()
        print(string.format("🗑️ [OBBY SERVER] Destroyed old obby: %s", obbyName))
    end
    
    -- 7. Clone and place new obby
    local newObby = obbyTemplate:Clone()
    newObby.Parent = activeObbys
    
    print(string.format("✅ [OBBY SERVER] Replaced obby: %s", obbyName))
    
    -- 8. Update cooldowns
    playerCooldowns[player.UserId] = currentTime
    lastServerReplace = currentTime
    
    -- 9. Send success notification
    NotificationService:Send(player, {
        Message = "✅ Rintangan berhasil diperbarui!",
        Type = "success",
        Duration = 3,
        Icon = "🔧"
    })
    
    return "Success"
end

-- ✅ HANDLE REMOTE FUNCTION
replaceObbyFunc.OnServerInvoke = function(player, obbyName)
    return replaceObby(player, obbyName)
end

-- ✅ CLEANUP PLAYER COOLDOWNS ON LEAVE
Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player.UserId] = nil
end)

print("✅ [OBBY SERVER] System loaded")
