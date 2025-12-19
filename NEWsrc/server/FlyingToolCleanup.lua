--[[
    FLYING TOOL CLEANUP MODULE
    Place in ServerScriptService/FlyingToolCleanup
    
    Centralized cleanup for all flying tools:
    - AdminWing (FlyAbility)
    - FlyingSpeed1-8 (Levitation)
    
    This module is called by InventoryServer BEFORE switching tools
    to ensure proper cleanup of physics objects, accessories, and animations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FlyingToolCleanup = {}

-- Import FlyAbility for AdminWing cleanup
local FlyAbility = nil
pcall(function()
    FlyAbility = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FlyAbility"))
end)

-- Constants for FlyingSpeed tools
local FLYING_SPEED_ACCESSORY_NAME = "KudaLumpingReward"
local FLYING_SPEED_BODY_POSITION_NAME = "HeightBodyPosition"
local FLYING_SPEED_ANIMATION_ID = "rbxassetid://111312412597365"

-- Constants for AdminWing
local ADMIN_WING_ACCESSORY_NAME = "FlightAccessory"
local ADMIN_WING_GYRO_NAME = "FlightGyro"
local ADMIN_WING_VELOCITY_NAME = "FlightVelocity"

-- Check if a tool is a flying tool
function FlyingToolCleanup:IsFlyingTool(toolId)
    if not toolId then return false end
    
    -- AdminWing
    if toolId == "AdminWing" then
        return true, "AdminWing"
    end
    
    -- FlyingSpeed1-8
    if string.match(toolId, "^FlyingSpeed%d*$") then
        return true, "FlyingSpeed"
    end
    
    return false, nil
end

-- Cleanup AdminWing effects
function FlyingToolCleanup:CleanupAdminWing(player)
    if not player then return end
    
    print(string.format("[CLEANUP] Cleaning up AdminWing for %s", player.Name))
    
    -- Use FlyAbility's ForceCleanup if available
    if FlyAbility and FlyAbility.ForceCleanup then
        FlyAbility:ForceCleanup(player)
        return
    end
    
    -- Fallback: manual cleanup
    local character = player.Character
    if not character then return end
    
    -- 1. Remove flight physics
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local gyro = hrp:FindFirstChild(ADMIN_WING_GYRO_NAME)
        if gyro then gyro:Destroy() end
        
        local velocity = hrp:FindFirstChild(ADMIN_WING_VELOCITY_NAME)
        if velocity then velocity:Destroy() end
    end
    
    -- 2. Remove flight accessory
    local accessory = character:FindFirstChild(ADMIN_WING_ACCESSORY_NAME)
    if accessory then
        accessory:Destroy()
    end
    
    -- 3. Clear IsFlying attribute
    character:SetAttribute("IsFlying", nil)
    
    -- 4. Restore humanoid state
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    print(string.format("[CLEANUP] AdminWing cleanup complete for %s", player.Name))
end

-- Cleanup FlyingSpeed effects (levitation)
function FlyingToolCleanup:CleanupFlyingSpeed(player)
    if not player then return end
    
    print(string.format("[CLEANUP] Cleaning up FlyingSpeed for %s", player.Name))
    
    local character = player.Character
    if not character then return end
    
    -- 1. Remove BodyPosition (levitation physics)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bp = hrp:FindFirstChild(FLYING_SPEED_BODY_POSITION_NAME)
        if bp then
            bp:Destroy()
            print("[CLEANUP] Removed HeightBodyPosition")
        end
    end
    
    -- 2. Remove wing accessory
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") and child.Name == FLYING_SPEED_ACCESSORY_NAME then
            child:Destroy()
            print("[CLEANUP] Removed FlyingSpeed accessory")
        end
    end
    
    -- 3. Stop levitation animation
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == FLYING_SPEED_ANIMATION_ID then
                    track:Stop()
                    print("[CLEANUP] Stopped levitation animation")
                end
            end
        end
    end
    
    print(string.format("[CLEANUP] FlyingSpeed cleanup complete for %s", player.Name))
end

-- Cleanup any flying tool by ID
function FlyingToolCleanup:CleanupByToolId(player, toolId)
    local isFlying, toolType = self:IsFlyingTool(toolId)
    
    if not isFlying then
        return false
    end
    
    if toolType == "AdminWing" then
        self:CleanupAdminWing(player)
        return true
    elseif toolType == "FlyingSpeed" then
        self:CleanupFlyingSpeed(player)
        return true
    end
    
    return false
end

-- Cleanup ALL flying effects (use when unsure which tool was equipped)
function FlyingToolCleanup:CleanupAll(player)
    if not player then return end
    
    print(string.format("[CLEANUP] Full cleanup for %s", player.Name))
    
    -- Cleanup both types
    self:CleanupAdminWing(player)
    self:CleanupFlyingSpeed(player)
    
    print(string.format("[CLEANUP] Full cleanup complete for %s", player.Name))
end

print("✅ [FLYING TOOL CLEANUP] Module loaded")

return FlyingToolCleanup
