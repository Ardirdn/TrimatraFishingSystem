--[[
    TOOL GIVER - FISHING ROD & FISH TOOLS
    Place in ServerScriptService
    
    Memberikan:
    1. Rod yang diequip ke player saat join/respawn (auto-equip)
    2. Fish tools berdasarkan FishInventory
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods")
local RodsFolder = FishingRodsFolder:WaitForChild("Rods")

-- Try to get DataHandler and FishConfig
local DataHandler = nil
local FishConfig = nil

pcall(function()
	DataHandler = require(game:GetService("ServerScriptService"):WaitForChild("DataHandler", 5))
end)

pcall(function()
	FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig", 5))
end)

-- ============================================
-- CREATE FISH TOOL (inline version)
-- ============================================
local function createFishTool(player, fishId, fishData)
	if not fishData then return nil end
	
	-- Create Tool
	local fishTool = Instance.new("Tool")
	fishTool.Name = fishData.Name
	fishTool.CanBeDropped = false
	fishTool.RequiresHandle = true
	fishTool.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	
	local handle = nil
	
	-- ✅ Search multiple locations for fish models (same as NewFishDiscoveryUi)
	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels") 
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FishModels"))
		or workspace:FindFirstChild("FishModels")
	
	-- Debug: Log folder status
	if not FishModelsFolder then
		warn("⚠️ [TOOL GIVER] FishModels folder NOT FOUND in any location!")
	end
	
	-- Try to load 3D model
	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishId)
		if fishModel then
			if fishModel:IsA("Model") then
				local primaryPart = fishModel.PrimaryPart or fishModel:FindFirstChildWhichIsA("BasePart")
				
				if primaryPart then
					local clonedModel = fishModel:Clone()
					
					-- ✅ FIX: Position model at origin first
					if clonedModel:IsA("Model") then
						clonedModel:PivotTo(CFrame.new(0, 0, 0))
					end
					
					-- Create handle at same position as model center
					handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(0.5, 0.3, 1)
					handle.Transparency = 1
					handle.CanCollide = false
					handle.Anchored = false
					handle.Massless = true
					handle.CanQuery = false
					handle.CanTouch = false
					handle.CFrame = CFrame.new(0, 0, 0) -- Same position as model
					
					-- Collect parts first, then weld and parent
					local partsToWeld = {}
					for _, part in pairs(clonedModel:GetDescendants()) do
						if part:IsA("BasePart") then
							table.insert(partsToWeld, part)
						end
					end
					
					-- Weld each part to handle
					for _, part in ipairs(partsToWeld) do
						part.CanCollide = false
						part.CanQuery = false
						part.CanTouch = false
						part.Massless = true
						part.Anchored = false
						
						-- Create weld constraint (maintains relative position)
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = handle
						weld.Part1 = part
						weld.Parent = part
						
						-- Parent to handle
						part.Parent = handle
					end
					
					clonedModel:Destroy()
				end
			elseif fishModel:IsA("BasePart") then
				handle = fishModel:Clone()
				handle.Name = "Handle"
				handle.CanCollide = false
				handle.CanQuery = false
				handle.CanTouch = false
				handle.Massless = true
			end
		end
	end
	
	-- Fallback: create placeholder
	if not handle then
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(0.6, 0.3, 1)
		handle.Material = Enum.Material.SmoothPlastic
		
		local rarityColors = {
			Common = Color3.fromRGB(180, 180, 180),
			Uncommon = Color3.fromRGB(100, 200, 100),
			Rare = Color3.fromRGB(80, 150, 255),
			Epic = Color3.fromRGB(180, 80, 220),
			Legendary = Color3.fromRGB(255, 170, 30),
		}
		handle.Color = rarityColors[fishData.Rarity] or Color3.fromRGB(200, 200, 200)
	end
	
	-- Ensure handle has no collision
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Anchored = false
	handle.Massless = true
	handle.Parent = fishTool
	
	-- Double check all descendants
	for _, part in pairs(fishTool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	
	return fishTool
end

-- ============================================
-- GIVE FISH TOOLS FROM INVENTORY
-- ============================================
local function giveFishTools(player, backpack)
	if not DataHandler or not FishConfig then return end
	
	local data = DataHandler:GetData(player)
	if not data or not data.FishInventory then return end
	
	-- Clear existing fish tools first
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and not tool.Name:find("FishingRod") and not tool.Name:find("Rod") then
			-- Check if this is a fish (exists in FishConfig)
			for fishId, fishData in pairs(FishConfig.Fish) do
				if fishData.Name == tool.Name then
					tool:Destroy()
					break
				end
			end
		end
	end
	
	-- Give fish tools for each fish in inventory
	local fishCount = 0
	for fishId, count in pairs(data.FishInventory) do
		if count and count > 0 then
			local fishData = FishConfig.Fish[fishId]
			if fishData then
				-- Create ONE tool per fish type (not per count)
				local fishTool = createFishTool(player, fishId, fishData)
				if fishTool then
					fishTool.Parent = backpack
					fishCount = fishCount + 1
				end
			end
		end
	end
	

end

-- ============================================
-- GIVE EQUIPPED ROD
-- ============================================
local function giveEquippedRod(player)
	task.wait(0.5) -- Wait for character to load

	local character = player.Character
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack or not humanoid then return end
	
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
	
	-- Remove any existing fishing rod tools from backpack and character
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:find("FishingRod") or tool.Name:find("Rod")) then
			tool:Destroy()
		end
	end
	
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:find("FishingRod") or tool.Name:find("Rod")) then
			tool:Destroy()
		end
	end
	
	-- Give the equipped rod
	local rod = RodsFolder:FindFirstChild(equippedRodId)
	if rod and rod:IsA("Tool") then
		local rodClone = rod:Clone()
		rodClone.Parent = backpack
		
		-- Auto-equip rod ke tangan
		task.delay(0.2, function()
			if humanoid and humanoid.Health > 0 and rodClone and rodClone.Parent then
				humanoid:EquipTool(rodClone)
			end
		end)
		

	else
		warn("⚠️ [TOOL GIVER] Equipped rod not found:", equippedRodId)
	end
	
	-- Also give fish tools
	giveFishTools(player, backpack)
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



