--[[
    FISHING REWARD SERVER (UPDATED - USES DATAHANDLER)
    Place in ServerScriptService
    
    Handles fish catching rewards using centralized DataHandler
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))
local DataHandler = require(script.Parent.DataHandler)

-- Create RemoteEvents
local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
if not FishingSuccessEvent then
	FishingSuccessEvent = Instance.new("RemoteEvent")
	FishingSuccessEvent.Name = "FishingSuccessEvent"
	FishingSuccessEvent.Parent = ReplicatedStorage
end

local FishCaughtEvent = ReplicatedStorage:FindFirstChild("FishCaughtEvent")
if not FishCaughtEvent then
	FishCaughtEvent = Instance.new("RemoteEvent")
	FishCaughtEvent.Name = "FishCaughtEvent"
	FishCaughtEvent.Parent = ReplicatedStorage
end

local GetFishInventoryFunc = ReplicatedStorage:FindFirstChild("GetFishInventory")
if not GetFishInventoryFunc then
	GetFishInventoryFunc = Instance.new("RemoteFunction")
	GetFishInventoryFunc.Name = "GetFishInventory"
	GetFishInventoryFunc.Parent = ReplicatedStorage
end

print("✅ [FISHING REWARD SERVER] Initialized")

-- ============================================
-- FISH TOOL CREATION
-- ============================================

local function createFishTool(player, fishId, fishData)
	print("🎣 [TOOL] Creating fish tool for:", fishData.Name)
	
	-- Create Tool
	local fishTool = Instance.new("Tool")
	fishTool.Name = fishData.Name
	fishTool.CanBeDropped = true
	fishTool.RequiresHandle = true
	fishTool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	
	local handle = nil
	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels") 
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
	
	-- Try to load 3D model
	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishId)
		if fishModel then
			print("✅ [TOOL] Found 3D model, preparing for tool...")
			
			if fishModel:IsA("Model") then
				local primaryPart = fishModel.PrimaryPart or fishModel:FindFirstChildWhichIsA("BasePart")
				
				if primaryPart then
					-- Clone and flatten model
					local clonedModel = fishModel:Clone()
					
					-- Create container handle
					handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 0.5, 2)
					handle.Transparency = 1
					handle.CanCollide = false
					handle.Anchored = false
					
					-- Weld all parts to handle
					for _, part in pairs(clonedModel:GetDescendants()) do
						if part:IsA("BasePart") then
							local weld = Instance.new("WeldConstraint")
							weld.Part0 = handle
							weld.Part1 = part
							weld.Parent = part
							part.CanCollide = false
							part.Anchored = false
							part.Parent = handle
						end
					end
					
					clonedModel:Destroy()
				end
			elseif fishModel:IsA("BasePart") then
				handle = fishModel:Clone()
				handle.Name = "Handle"
			end
		end
	end
	
	-- Fallback: create placeholder
	if not handle then
		print("⚠️ [TOOL] No model found, creating placeholder...")
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(0.8, 0.4, 1.5)
		handle.Material = Enum.Material.SmoothPlastic
		
		local rarityColors = {
			Common = Color3.fromRGB(180, 180, 180),
			Uncommon = Color3.fromRGB(100, 200, 100),
			Rare = Color3.fromRGB(80, 150, 255),
			Epic = Color3.fromRGB(180, 80, 220),
			Legendary = Color3.fromRGB(255, 170, 30),
		}
		handle.Color = rarityColors[fishData.Rarity] or Color3.fromRGB(200, 200, 200)
		
		-- Add glow for legendary
		if fishData.Rarity == "Legendary" then
			local pointLight = Instance.new("PointLight")
			pointLight.Color = handle.Color
			pointLight.Brightness = 1.5
			pointLight.Range = 6
			pointLight.Parent = handle
			
			local sparkles = Instance.new("Sparkles")
			sparkles.Parent = handle
		end
	end
	
	-- Ensure handle properties
	handle.CanCollide = false
	handle.Anchored = false
	handle.Massless = true
	handle.Parent = fishTool
	
	-- Add to player's backpack
	local backpack = player:WaitForChild("Backpack")
	fishTool.Parent = backpack
	
	print("✅ [TOOL] Fish tool added to", player.Name, "'s backpack:", fishData.Name)
	return fishTool
end

-- ============================================
-- FISH REWARD SYSTEM
-- ============================================

local function giveFishReward(player, success)
	print("🔍 [DEBUG] giveFishReward called for", player.Name, "| Success:", success)

	local data = DataHandler:GetData(player)
	if not data then 
		warn("⚠️ No player data for", player.Name)
		return 
	end

	if not success then
		print("❌", player.Name, "failed to catch fish")
		return
	end

	-- Get random fish
	print("🎲 [DEBUG] Getting random fish...")
	local fishId, fishData = FishConfig.GetRandomFish()

	if not fishId or not fishData then
		warn("⚠️ No fish data available from FishConfig!")
		return
	end

	print("🐟 [DEBUG] Fish selected:", fishId, "-", fishData.Name)

	-- ═══════════════════════════════════════
	-- UPDATE DATA VIA DATAHANDLER
	-- ═══════════════════════════════════════
	
	-- ✅ NEW: Add fish to FishInventory (NOT money!)
	local fishInventory = DataHandler:Get(player, "FishInventory") or {}
	fishInventory[fishId] = (fishInventory[fishId] or 0) + 1
	DataHandler:Set(player, "FishInventory", fishInventory)
	
	-- Increment fish caught counter (for stats)
	DataHandler:Increment(player, "TotalFishCaught", 1)
	
	-- Check if new discovery
	local discoveredFish = DataHandler:Get(player, "DiscoveredFish") or {}
	local isNewDiscovery = not discoveredFish[fishId]
	
	if isNewDiscovery then
		discoveredFish[fishId] = true
		DataHandler:Set(player, "DiscoveredFish", discoveredFish)
	end
	
	-- Save data
	DataHandler:SavePlayer(player)

	-- ═══════════════════════════════════════
	-- CREATE FISH TOOL (visual feedback)
	-- ═══════════════════════════════════════
	pcall(function()
		createFishTool(player, fishId, fishData)
	end)

	-- Get current fish count for this type
	local fishCount = fishInventory[fishId]

	print("🎣", player.Name, "caught", fishData.Name, "(", fishData.Rarity, ")", 
		"Count:", fishCount,
		isNewDiscovery and "- NEW DISCOVERY!" or "")

	-- Notify client (no money given, fish goes to inventory)
	FishCaughtEvent:FireClient(player, {
		FishID = fishId,
		FishData = fishData,
		IsNewDiscovery = isNewDiscovery,
		Quantity = 1,
		FishCount = fishCount, -- How many of this fish player now has
		Price = fishData.Price or 0 -- For display purposes only
	})
	
	print("✅ [DEBUG] Fish added to inventory!")
end

-- ============================================
-- REMOTE HANDLERS
-- ============================================

-- Client calls this when fishing success/fail
FishingSuccessEvent.OnServerEvent:Connect(function(player, success)
	print("📞 [DEBUG] FishingSuccessEvent received from", player.Name, "| Success:", success)
	giveFishReward(player, success)
end)

-- Get fish inventory (for display purposes)
GetFishInventoryFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if data then
		return {
			DiscoveredFish = data.DiscoveredFish or {},
			TotalFishCaught = data.TotalFishCaught or 0,
			Money = data.Money or 0
		}
	end
	return nil
end

print("✅ [FISHING REWARD SERVER] System loaded (using DataHandler)")
