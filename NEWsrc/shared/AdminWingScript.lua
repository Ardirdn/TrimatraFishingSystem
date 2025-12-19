--[[
    ADMIN WING TOOL SCRIPT
    =======================
    Place this script inside the AdminWing Tool
    
    BEHAVIOR:
    - Equip: Shows UI with On/Off toggle button + speed slider (NOT auto-fly)
    - Toggle ON: Start flying
    - Toggle OFF: Stop flying
    - Unequip: Hide UI and stop flying
    - Re-equip: Shows UI again (toggle reset to OFF)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FlyAbility = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FlyAbility"))

local CONFIG = {
	AccessoryName = "AdminWing",
	BoostSpeed = 16,
	FlightSpeed = 80,  -- Default speed, can be changed via slider
	GyroP = 20000,
	AnimationId = "rbxassetid://111312412597365",
}

local tool = script.Parent
local player = nil
local equipped = false

local function onEquipped()
	if equipped then return end  -- Prevent double-equip
	equipped = true
	
	local character = tool.Parent
	player = Players:GetPlayerFromCharacter(character)

	if player then
		-- Show UI but DON'T start flying automatically
		-- User must click the toggle button to start flying
		FlyAbility:OnEquip(player, CONFIG)
		print(string.format("[%s] Equipped for %s - UI shown", tool.Name, player.Name))
	end
end

local function onUnequipped()
	if not equipped then return end
	equipped = false
	
	if player then
		-- Hide UI and stop flying if was flying
		FlyAbility:OnUnequip(player)
		print(string.format("[%s] Unequipped for %s - UI hidden", tool.Name, player.Name))
	end
	player = nil
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

print(string.format("✅ [%s] Tool loaded (Toggle-based flight)", tool.Name))
