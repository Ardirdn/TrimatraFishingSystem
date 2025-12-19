--[[
    FLY ABILITY CLIENT INITIALIZER
    Place in StarterPlayerScripts
    
    Script ini me-require FlyAbility module untuk menginisialisasi
    client-side listeners (click detection dan flight control)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[FLY ABILITY INIT] Client initializer starting...")

-- Wait for Modules folder
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
    warn("[FLY ABILITY INIT] Modules folder not found!")
    return
end

-- Wait for FlyAbility module
local FlyAbilityModule = Modules:WaitForChild("FlyAbility", 10)
if not FlyAbilityModule then
    warn("[FLY ABILITY INIT] FlyAbility module not found!")
    return
end

-- Require the module to initialize client-side code
local FlyAbility = require(FlyAbilityModule)

print("[FLY ABILITY INIT] Client initialization complete!")
