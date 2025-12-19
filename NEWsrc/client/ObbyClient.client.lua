--[[
    OBBY CLIENT
    Client-side handler untuk Obby Replacement System
    
    Setup:
    - Papan pengganti di Workspace > map > ReplaceBoards
    - Setiap papan harus memiliki:
      - ProximityPrompt
      - StringValue bernama "ObbyName" dengan value nama obby
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ✅ WAIT FOR REMOTES
local obbyRemotes = ReplicatedStorage:WaitForChild("ObbyRemotes", 30)
if not obbyRemotes then
    warn("[OBBY CLIENT] ObbyRemotes not found!")
    return
end

local replaceObbyFunc = obbyRemotes:WaitForChild("ReplaceObby", 10)
if not replaceObbyFunc then
    warn("[OBBY CLIENT] ReplaceObby remote not found!")
    return
end

print("✅ [OBBY CLIENT] Remotes loaded")

-- ✅ CONFIGURATION
local CONFIG = {
    PromptReenableDelay = 2,    -- Delay sebelum prompt aktif lagi
}

-- ✅ SETUP BOARD FUNCTION
local function setupBoard(board)
    local prompt = board:FindFirstChildOfClass("ProximityPrompt")
    local obbyNameValue = board:FindFirstChild("ObbyName")
    
    -- Validate board setup
    if not prompt then
        warn(string.format("[OBBY CLIENT] ProximityPrompt not found in board: %s", board.Name))
        return
    end
    
    if not obbyNameValue or not obbyNameValue:IsA("StringValue") then
        warn(string.format("[OBBY CLIENT] ObbyName StringValue not found in board: %s", board.Name))
        return
    end
    
    if obbyNameValue.Value == "" then
        warn(string.format("[OBBY CLIENT] ObbyName is empty in board: %s", board.Name))
        return
    end
    
    print(string.format("✅ [OBBY CLIENT] Setup board: %s -> %s", board.Name, obbyNameValue.Value))
    
    -- ✅ HANDLE PROMPT TRIGGERED
    prompt.Triggered:Connect(function(triggeringPlayer)
        -- Only handle for local player
        if triggeringPlayer ~= player then return end
        
        local obbyName = obbyNameValue.Value
        print(string.format("[OBBY CLIENT] Requesting replace for: %s", obbyName))
        
        -- Disable prompt temporarily to prevent spam
        prompt.Enabled = false
        
        -- Call server
        local status = replaceObbyFunc:InvokeServer(obbyName)
        
        -- Log result
        if status == "Success" then
            print(string.format("[OBBY CLIENT] ✅ Successfully replaced: %s", obbyName))
        elseif status == "Cooldown" then
            print("[OBBY CLIENT] ⏳ Cooldown active")
        elseif status == "InUse" then
            print("[OBBY CLIENT] 🚶 Obby is in use")
        else
            print(string.format("[OBBY CLIENT] ❌ Error: %s", tostring(status)))
        end
        
        -- Re-enable prompt after delay
        task.wait(CONFIG.PromptReenableDelay)
        prompt.Enabled = true
    end)
end

-- ✅ INITIALIZE
local function initialize()
    -- Wait for ReplaceBoards folder
    local mapFolder = Workspace:WaitForChild("map", 30)
    if not mapFolder then
        warn("[OBBY CLIENT] Workspace.map not found!")
        return
    end
    
    local replaceBoardsFolder = mapFolder:WaitForChild("ReplaceBoards", 10)
    if not replaceBoardsFolder then
        warn("[OBBY CLIENT] ReplaceBoards folder not found in map!")
        return
    end
    
    print(string.format("[OBBY CLIENT] Found ReplaceBoards folder with %d boards", #replaceBoardsFolder:GetChildren()))
    
    -- Setup existing boards
    for _, board in ipairs(replaceBoardsFolder:GetChildren()) do
        setupBoard(board)
    end
    
    -- Setup future boards (if any are added dynamically)
    replaceBoardsFolder.ChildAdded:Connect(function(board)
        task.wait(0.1) -- Small delay to ensure all properties are set
        setupBoard(board)
    end)
    
    print("✅ [OBBY CLIENT] System loaded")
end

-- Start initialization
initialize()
