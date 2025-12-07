--[[
    TOOL GIVER - FISHING ROD ONLY
    Place in ServerScriptService
    
    Hanya memberikan ROD YANG DIEQUIP ke player saat join/respawn.
    Tidak lagi memberikan semua owned rods ke backpack.
    Player harus equip rod via Inventory UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods")
local RodsFolder = FishingRodsFolder:WaitForChild("Rods")

-- Try to get DataHandler (centralized data management)
local DataHandler = nil
pcall(function()
	DataHandler = require(game:GetService("ServerScriptService"):WaitForChild("DataHandler", 5))
end)

local function giveEquippedRod(player)
	task.wait(0.5) -- Wait for character to load

	local character = player.Character
	if not character then return end

	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then return end
	
	-- Get equipped rod from DataHandler
	local equippedRodId = nil
	
	if DataHandler then
		local data = DataHandler:GetData(player)
		if data then
			equippedRodId = data.EquippedRod
		end
	end
	
	-- Default to starter rod if no equipped rod found
	if not equippedRodId or equippedRodId == "" then
		equippedRodId = "FishingRod_Wood1"
	end
	
	-- Check if player already has this rod equipped (in backpack or character)
	local alreadyHasRod = false
	
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == equippedRodId then
			alreadyHasRod = true
			break
		end
	end
	
	if not alreadyHasRod and character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == equippedRodId then
				alreadyHasRod = true
				break
			end
		end
	end
	
	if alreadyHasRod then
		print("🎣 [TOOL GIVER]", player.Name, "sudah punya rod:", equippedRodId)
		return
	end
	
	-- Give the equipped rod
	local rod = RodsFolder:FindFirstChild(equippedRodId)
	if rod and rod:IsA("Tool") then
		local rodClone = rod:Clone()
		rodClone.Parent = backpack
		print("🎣 [TOOL GIVER] Gave equipped rod to", player.Name, ":", equippedRodId)
	else
		warn("⚠️ [TOOL GIVER] Equipped rod not found:", equippedRodId)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		giveEquippedRod(player)
	end)

	-- Give rod if character already loaded
	if player.Character then
		giveEquippedRod(player)
	end
end)

-- For players already in game when server script loads
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			giveEquippedRod(player)
		end)
	end
end

print("✅ [TOOL GIVER] Script Loaded - Only gives equipped rod, no hotbar!")
