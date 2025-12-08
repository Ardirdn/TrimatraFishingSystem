--[[
	BoatSpawnerServer - Server-side boat spawning handler
	Place in ServerScriptService
	
	Handles:
	- Spawning boats for players
	- Despawning previous boats
	- Finding water position near player
	
	Required Structure:
	ServerStorage/
	└── BoatTemplates/
	    ├── BasicBoat (Model)
	    └── SpeedBoat (Model) etc...
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local BoatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BoatConfig"))

-- ==================== REMOTE EVENTS ====================
local BoatSpawnerFolder = Instance.new("Folder")
BoatSpawnerFolder.Name = "BoatSpawner"
BoatSpawnerFolder.Parent = ReplicatedStorage

local SpawnBoatEvent = Instance.new("RemoteEvent")
SpawnBoatEvent.Name = "SpawnBoat"
SpawnBoatEvent.Parent = BoatSpawnerFolder

local GetBoatsEvent = Instance.new("RemoteFunction")
GetBoatsEvent.Name = "GetBoats"
GetBoatsEvent.Parent = BoatSpawnerFolder

-- ==================== STATE ====================
local playerBoats = {} -- [player] = boatModel

-- ==================== UTILITY ====================

local BOAT_LENGTH = 15 -- Boat length for grid check
local BOAT_WIDTH = 8   -- Boat width for grid check  
local SAFETY_MARGIN = 30 -- Extra margin around boat
local MIN_SPAWN_DISTANCE = 20 -- Minimum distance from player
local MAX_SEARCH_RADIUS = 150 -- Maximum search radius

-- Check if a point is on water (returns isWater, waterHeight)
local function isPointOnWater(x, z)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if not terrain then return false, BoatConfig.Physics.DefaultWaterHeight end
	
	local rayOrigin = Vector3.new(x, 200, z)
	local rayDirection = Vector3.new(0, -400, 0)
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = {terrain}
	
	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result and result.Material == Enum.Material.Water then
		return true, result.Position.Y
	end
	
	return false, nil
end

-- Check spawn area using a 5x5 grid (25 points total)
local function checkSpawnAreaGrid(centerX, centerZ)
	local halfLength = (BOAT_LENGTH + SAFETY_MARGIN) / 2
	local halfWidth = (BOAT_WIDTH + SAFETY_MARGIN) / 2
	
	local waterCount = 0
	local totalHeight = 0
	local totalPoints = 25  -- 5x5 grid
	
	-- Check 5x5 grid of points
	for i = -2, 2 do
		for j = -2, 2 do
			local checkX = centerX + (i * halfLength / 2)
			local checkZ = centerZ + (j * halfWidth / 2)
			
			local isWater, waterY = isPointOnWater(checkX, checkZ)
			if isWater then
				waterCount = waterCount + 1
				totalHeight = totalHeight + waterY
			end
		end
	end
	
	-- Calculate score (0-100%)
	local score = waterCount / totalPoints
	local avgHeight = waterCount > 0 and (totalHeight / waterCount) or BoatConfig.Physics.DefaultWaterHeight
	
	return score, avgHeight, waterCount
end

-- Find the best water spawn position
local function findWaterPositionNear(playerPosition)
	local bestPosition = nil
	local bestScore = 0
	local bestHeight = BoatConfig.Physics.DefaultWaterHeight
	
	-- Search in expanding circles
	for radius = MIN_SPAWN_DISTANCE, MAX_SEARCH_RADIUS, 8 do
		for angle = 0, 345, 15 do
			local rad = math.rad(angle)
			local testX = playerPosition.X + math.cos(rad) * radius
			local testZ = playerPosition.Z + math.sin(rad) * radius
			
			local score, avgHeight, waterPoints = checkSpawnAreaGrid(testX, testZ)
			
			-- We need 100% water coverage (all 25 points)
			if score >= 1.0 then
				-- Perfect spot found!
				return Vector3.new(testX, avgHeight, testZ), true
			end
			
			-- Track best spot so far (for fallback)
			if score > bestScore then
				bestScore = score
				bestPosition = Vector3.new(testX, avgHeight, testZ)
				bestHeight = avgHeight
			end
		end
	end
	
	-- If no perfect spot, use best available (must have at least 80% water)
	if bestScore >= 0.8 and bestPosition then
		warn(string.format("⚠️ [BOAT SPAWNER] Using backup spot with %.0f%% water coverage", bestScore * 100))
		return bestPosition, false
	end
	
	-- Last resort - search further out
	for radius = MAX_SEARCH_RADIUS, MAX_SEARCH_RADIUS + 50, 10 do
		for angle = 0, 345, 30 do
			local rad = math.rad(angle)
			local testX = playerPosition.X + math.cos(rad) * radius
			local testZ = playerPosition.Z + math.sin(rad) * radius
			
			local isWater, waterY = isPointOnWater(testX, testZ)
			if isWater then
				return Vector3.new(testX, waterY, testZ), false
			end
		end
	end
	
	-- Absolute fallback
	warn("⚠️ [BOAT SPAWNER] No water found! Using default position")
	return Vector3.new(
		playerPosition.X + MIN_SPAWN_DISTANCE, 
		BoatConfig.Physics.DefaultWaterHeight, 
		playerPosition.Z + MIN_SPAWN_DISTANCE
	), false
end

-- Get boat templates folder
local function getBoatTemplates()
	local templates = ServerStorage:FindFirstChild("BoatTemplates")
	if not templates then
		templates = Instance.new("Folder")
		templates.Name = "BoatTemplates"
		templates.Parent = ServerStorage
		warn("⚠️ [BOAT SPAWNER] Created BoatTemplates folder in ServerStorage - add boat models there!")
	end
	return templates
end

-- Get boats folder in workspace
local function getBoatsFolder()
	local folder = workspace:FindFirstChild(BoatConfig.Folders.BoatsFolder)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = BoatConfig.Folders.BoatsFolder
		folder.Parent = workspace
	end
	return folder
end

-- ==================== SPAWN LOGIC ====================

local function despawnBoat(player)
	local existingBoat = playerBoats[player]
	if existingBoat and existingBoat.Parent then
		existingBoat:Destroy()
	end
	playerBoats[player] = nil
end

local function spawnBoat(player, boatName)
	-- Despawn existing boat first
	despawnBoat(player)
	
	-- Get template
	local templates = getBoatTemplates()
	local template = templates:FindFirstChild(boatName)
	
	if not template then
		warn(string.format("⚠️ [BOAT SPAWNER] Template '%s' not found!", boatName))
		return false, "Boat template not found"
	end
	
	-- Get player position
	local character = player.Character
	if not character then
		return false, "Character not found"
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false, "HumanoidRootPart not found"
	end
	
	-- Find water position
	local waterPos = findWaterPositionNear(humanoidRootPart.Position)
	
	-- Get boat stats for offset
	local stats = BoatConfig.GetBoatStats(boatName)
	local floatOffset = stats.FloatOffset or 3
	
	-- Clone and position boat
	local newBoat = template:Clone()
	newBoat.Name = boatName
	
	-- Find VehicleSeat to position correctly
	local driverSeat = newBoat:FindFirstChild(BoatConfig.Folders.DriverSeatName)
	if driverSeat then
		-- Position boat above water
		local spawnY = waterPos.Y + floatOffset
		local spawnPos = Vector3.new(waterPos.X, spawnY, waterPos.Z)
		
		-- Face away from player
		local dirFromPlayer = (spawnPos - humanoidRootPart.Position).Unit
		local lookAt = spawnPos + Vector3.new(dirFromPlayer.X, 0, dirFromPlayer.Z)
		
		newBoat:PivotTo(CFrame.new(spawnPos, lookAt))
	else
		-- Fallback positioning
		newBoat:PivotTo(CFrame.new(waterPos.X, waterPos.Y + floatOffset, waterPos.Z))
	end
	
	-- Parent to Boats folder
	newBoat.Parent = getBoatsFolder()
	
	-- Store reference
	playerBoats[player] = newBoat
	
	-- Add owner attribute for tracking
	newBoat:SetAttribute("Owner", player.UserId)
	
	print(string.format("🚤 [BOAT SPAWNER] %s spawned %s", player.Name, boatName))
	
	return true, "Boat spawned!"
end

-- ==================== REMOTE HANDLERS ====================

SpawnBoatEvent.OnServerEvent:Connect(function(player, boatName)
	if typeof(boatName) ~= "string" then return end
	
	local success, message = spawnBoat(player, boatName)
	-- Could send back result via another remote if needed
end)

GetBoatsEvent.OnServerInvoke = function(player)
	local templates = getBoatTemplates()
	local boatList = {}
	
	for _, template in ipairs(templates:GetChildren()) do
		if template:IsA("Model") then
			local stats = BoatConfig.GetBoatStats(template.Name)
			table.insert(boatList, {
				Name = template.Name,
				DisplayName = stats.DisplayName or template.Name,
				Price = stats.Price or 0,
				MaxSpeed = stats.MaxSpeed or 15,
				Acceleration = stats.Acceleration or 0.1,
			})
		end
	end
	
	return boatList
end

-- ==================== CLEANUP ====================

Players.PlayerRemoving:Connect(function(player)
	despawnBoat(player)
end)

print("🚤 [BOAT SPAWNER SERVER] Initialized")
