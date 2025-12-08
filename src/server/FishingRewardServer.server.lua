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



-- ============================================
-- FISH TOOL CREATION
-- ============================================

local function createFishTool(player, fishId, fishData)

	
	-- Create Tool
	local fishTool = Instance.new("Tool")
	fishTool.Name = fishData.Name
	fishTool.CanBeDropped = false -- ✅ Can't drop fish
	fishTool.RequiresHandle = true
	fishTool.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	
	local handle = nil
	
	-- ✅ Search multiple locations for fish models (same as NewFishDiscoveryUi)
	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels") 
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FishModels"))
		or workspace:FindFirstChild("FishModels")
	
	-- Try to load 3D model
	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishId)
		if fishModel then
			
			if fishModel:IsA("Model") then
				local primaryPart = fishModel.PrimaryPart or fishModel:FindFirstChildWhichIsA("BasePart")
				
				if primaryPart then
					-- Clone model
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
		
		-- Add glow for legendary
		if fishData.Rarity == "Legendary" then
			local pointLight = Instance.new("PointLight")
			pointLight.Color = handle.Color
			pointLight.Brightness = 1.5
			pointLight.Range = 6
			pointLight.Parent = handle
		end
	end
	
	-- ✅ CRITICAL: Ensure handle has no collision at all
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Anchored = false
	handle.Massless = true
	handle.Parent = fishTool
	
	-- ✅ Double check all descendants
	for _, part in pairs(fishTool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	
	-- Add to player's backpack
	local backpack = player:WaitForChild("Backpack")
	fishTool.Parent = backpack
	

	return fishTool
end

-- ============================================
-- FISH REWARD SYSTEM
-- ============================================

local function giveFishReward(player, success)


	local data = DataHandler:GetData(player)
	if not data then 
		warn("⚠️ No player data for", player.Name)
		return 
	end

	if not success then
		return
	end

	-- Get random fish
	local fishId, fishData = FishConfig.GetRandomFish()

	if not fishId or not fishData then
		warn("⚠️ No fish data available from FishConfig!")
		return
	end



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



	-- Notify client (no money given, fish goes to inventory)
	FishCaughtEvent:FireClient(player, {
		FishID = fishId,
		FishData = fishData,
		IsNewDiscovery = isNewDiscovery,
		Quantity = 1,
		FishCount = fishCount, -- How many of this fish player now has
		Price = fishData.Price or 0 -- For display purposes only
	})
	

end

-- ============================================
-- REMOTE HANDLERS
-- ============================================

-- Client calls this when fishing success/fail
FishingSuccessEvent.OnServerEvent:Connect(function(player, success)

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


