--[[
    FISH AREA SYSTEM
    Place in ReplicatedStorage/Modules/FishAreaSystem.lua
    
    Sistem untuk mendeteksi apakah posisi berada di dalam Fish Area tertentu
    dan memodifikasi chance ikan berdasarkan area tersebut.
    
    CARA PAKAI:
    1. Di FishingServer, saat mau kasih reward ikan:
       local FishAreaSystem = require(path.to.FishAreaSystem)
       local fishId, fishData = FishAreaSystem.GetRandomFishInArea(floaterPosition)
    
    2. Sistem akan otomatis:
       - Deteksi apakah floater ada di area khusus
       - Modifikasi rarity weights berdasarkan area
       - Tambahkan bonus chance untuk ikan tertentu
       - Return ikan yang sudah dimodifikasi chance-nya
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishAreaSystem = {}

-- Lazy load configs to avoid circular dependencies
local _FishConfig = nil
local _FishAreaConfig = nil

local function getFishConfig()
	if not _FishConfig then
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		_FishConfig = require(Modules:WaitForChild("FishConfig"))
	end
	return _FishConfig
end

local function getFishAreaConfig()
	if not _FishAreaConfig then
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		_FishAreaConfig = require(Modules:WaitForChild("FishAreaConfig"))
	end
	return _FishAreaConfig
end

-- ==================== AREA DETECTION ====================

-- Cache untuk FishArea parts (untuk performa)
local areaCache = {}
local cacheValid = false

-- Rebuild area cache dari workspace
local function rebuildAreaCache()
	areaCache = {}
	
	-- Model name di workspace adalah "Location" yang berisi folder Area1, Area2, dll
	local fishAreaModel = workspace:FindFirstChild("Location")
	if not fishAreaModel then
		return
	end
	
	-- Iterate through all area folders
	for _, areaFolder in ipairs(fishAreaModel:GetChildren()) do
		if areaFolder:IsA("Folder") or areaFolder:IsA("Model") then
			local areaName = areaFolder.Name
			areaCache[areaName] = {}
			
			-- Collect all parts in this area folder
			for _, child in ipairs(areaFolder:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(areaCache[areaName], child)
				end
			end
		end
	end
	
	cacheValid = true
end

-- Check if position is inside a part (simplified box check)
local function isPositionInPart(position, part)
	-- Convert position to part's local space
	local localPos = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2
	
	-- Check if within bounds
	return math.abs(localPos.X) <= halfSize.X
		and math.abs(localPos.Y) <= halfSize.Y
		and math.abs(localPos.Z) <= halfSize.Z
end

-- Get the area name that contains this position (if any)
function FishAreaSystem.GetAreaAtPosition(position)
	if not cacheValid then
		rebuildAreaCache()
	end
	
	for areaName, areaParts in pairs(areaCache) do
		for _, part in ipairs(areaParts) do
			if isPositionInPart(position, part) then
				return areaName
			end
		end
	end
	
	return nil -- Not in any special area
end

-- Check if position is in a specific area
function FishAreaSystem.IsPositionInArea(position, areaName)
	if not cacheValid then
		rebuildAreaCache()
	end
	
	local areaParts = areaCache[areaName]
	if not areaParts then return false end
	
	for _, part in ipairs(areaParts) do
		if isPositionInPart(position, part) then
			return true
		end
	end
	
	return false
end

-- ==================== FISH SELECTION WITH AREA MODIFIERS ====================

-- Get modified rarity weights based on area
local function getModifiedRarityWeights(areaName)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()
	
	local modifiedWeights = {}
	
	-- Start with base weights
	for rarity, weight in pairs(FishConfig.RarityWeights) do
		modifiedWeights[rarity] = weight
	end
	
	-- Apply area multipliers if in an area
	if areaName then
		local areaConfig = FishAreaConfig.GetAreaConfig(areaName)
		if areaConfig and areaConfig.RarityMultipliers then
			for rarity, multiplier in pairs(areaConfig.RarityMultipliers) do
				if modifiedWeights[rarity] then
					modifiedWeights[rarity] = modifiedWeights[rarity] * multiplier
				end
			end
		end
	end
	
	return modifiedWeights
end

-- Get fish with bonus weights applied
local function getFishPoolWithBonuses(selectedRarity, areaName)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()
	
	local fishPool = {}
	local totalWeight = 0
	
	-- Get all fish of the selected rarity
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then
			-- Base weight of 1 for each fish
			local weight = 1
			
			-- Add bonus weight if in special area
			if areaName then
				local bonus = FishAreaConfig.GetFishChanceBonus(areaName, fishId)
				weight = weight + bonus
			end
			
			-- Check location restriction
			-- Rules:
			-- 1. "Anywhere" fish can spawn everywhere (Open Waters or any area)
			-- 2. Fish with specific location can ONLY spawn in that matching area
			-- 3. In Open Waters (areaName = nil), ONLY "Anywhere" fish can spawn
			local location = fishData.Location or "Anywhere"
			local canSpawnHere = false
			
			if location == "Anywhere" then
				-- "Anywhere" fish can spawn in any location
				canSpawnHere = true
			elseif areaName and location == areaName then
				-- Fish with specific location can spawn if we're in that area
				canSpawnHere = true
			end
			-- If areaName is nil (Open Waters) and location is NOT "Anywhere", fish cannot spawn
			
			if canSpawnHere then
				table.insert(fishPool, {
					fishId = fishId,
					weight = weight
				})
				totalWeight = totalWeight + weight
			end
		end
	end
	
	return fishPool, totalWeight
end

-- Main function: Get random fish considering area modifiers
function FishAreaSystem.GetRandomFishInArea(position)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()
	
	-- Detect if position is in special area
	local areaName = nil
	if position then
		areaName = FishAreaSystem.GetAreaAtPosition(position)
	end
	
	-- Get modified rarity weights
	local modifiedWeights = getModifiedRarityWeights(areaName)
	
	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(modifiedWeights) do
		totalWeight = totalWeight + weight
	end
	
	-- Random selection for rarity
	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedRarity = "Common"
	
	for rarity, weight in pairs(modifiedWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end
	
	-- Get fish pool with bonuses applied
	local fishPool, poolWeight = getFishPoolWithBonuses(selectedRarity, areaName)
	
	-- ==================== FIXED FALLBACK LOGIC ====================
	-- RULE: If NOT in any specific area (Open Waters), you can ONLY get "Anywhere" fish
	-- If pool is empty in Open Waters, we must re-select to Common/Uncommon which have "Anywhere" fish
	
	if #fishPool == 0 then
		if areaName == nil then
			-- In Open Waters: NO location-specific fish allowed!
			-- Fallback to ANY "Anywhere" fish (Common or Uncommon)
			for fishId, fishData in pairs(FishConfig.Fish) do
				if fishData.Location == "Anywhere" then
					table.insert(fishPool, { fishId = fishId, weight = 1 })
					poolWeight = poolWeight + 1
				end
			end
		else
			-- In specific area but no fish of that rarity in this area
			-- Try to get any "Anywhere" fish of that rarity first
			for fishId, fishData in pairs(FishConfig.Fish) do
				if fishData.Rarity == selectedRarity and fishData.Location == "Anywhere" then
					table.insert(fishPool, { fishId = fishId, weight = 1 })
					poolWeight = poolWeight + 1
				end
			end
			
			-- If still empty, get any Anywhere fish (fallback to common/uncommon)
			if #fishPool == 0 then
				for fishId, fishData in pairs(FishConfig.Fish) do
					if fishData.Location == "Anywhere" then
						table.insert(fishPool, { fishId = fishId, weight = 1 })
						poolWeight = poolWeight + 1
					end
				end
			end
		end
	end
	
	-- Still empty? Use first fish (ultimate fallback)
	if #fishPool == 0 then
		local firstFish = next(FishConfig.Fish)
		return firstFish, FishConfig.Fish[firstFish], areaName
	end
	
	-- Weighted random selection from pool
	local poolRandom = math.random() * poolWeight
	local poolCurrent = 0
	local selectedFishId = fishPool[1].fishId
	
	for _, fishEntry in ipairs(fishPool) do
		poolCurrent = poolCurrent + fishEntry.weight
		if poolRandom <= poolCurrent then
			selectedFishId = fishEntry.fishId
			break
		end
	end
	
	return selectedFishId, FishConfig.Fish[selectedFishId], areaName
end

-- ==================== UTILITY FUNCTIONS ====================

-- Force rebuild cache (call if FishArea model changes at runtime)
function FishAreaSystem.RefreshAreaCache()
	cacheValid = false
	rebuildAreaCache()
end

-- Get info about current area at position
function FishAreaSystem.GetAreaInfo(position)
	local FishAreaConfig = getFishAreaConfig()
	
	local areaName = FishAreaSystem.GetAreaAtPosition(position)
	if not areaName then
		return nil
	end
	
	local areaConfig = FishAreaConfig.GetAreaConfig(areaName)
	return {
		Name = areaName,
		DisplayName = areaConfig and areaConfig.DisplayName or areaName,
		Description = areaConfig and areaConfig.Description or "",
		Color = areaConfig and areaConfig.Color or Color3.fromRGB(100, 100, 100)
	}
end

-- Initialize system
task.spawn(function()
	task.wait(1) -- Wait for workspace to be ready
	rebuildAreaCache()
end)

-- Watch for changes to Location model
task.spawn(function()
	local fishAreaModel = workspace:WaitForChild("Location", 30)
	if fishAreaModel then
		fishAreaModel.ChildAdded:Connect(function()
			task.wait(0.5)
			FishAreaSystem.RefreshAreaCache()
		end)
		fishAreaModel.ChildRemoved:Connect(function()
			task.wait(0.5)
			FishAreaSystem.RefreshAreaCache()
		end)
	end
end)

return FishAreaSystem
