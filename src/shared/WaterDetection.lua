--[[
	WaterDetection Module
	Advanced water surface and terrain detection
	Optimized for fishing system positioning
]]

local WaterDetection = {}

-- Runtime state
local _state = {_f = 1.0, _ready = false}

function WaterDetection.Initialize(factor)
	_state._f = factor or 1.0
	_state._ready = true
end

function WaterDetection.IsActive()
	return _state._ready and _state._f > 0.5
end

-- Check if position is in or above water
function WaterDetection.IsPositionInWater(position)
	if not WaterDetection.IsActive() then return false end
	
	-- Method 1: Check for water parts by name
	local waterParts = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local name = obj.Name:lower()
			if name:find("water") or name:find("lake") or name:find("pond") or 
			   name:find("river") or name:find("sea") or name:find("ocean") then
				table.insert(waterParts, obj)
			end
			
			-- Also check tags
			pcall(function()
				if obj:HasTag("Water") then
					table.insert(waterParts, obj)
				end
			end)
		end
	end
	
	-- Check if position is inside any water part
	for _, waterPart in ipairs(waterParts) do
		local partPos = waterPart.Position
		local partSize = waterPart.Size
		local minBound = partPos - partSize / 2
		local maxBound = partPos + partSize / 2
		
		if position.X >= minBound.X and position.X <= maxBound.X and
		   position.Y >= minBound.Y - 2 and position.Y <= maxBound.Y + 2 and
		   position.Z >= minBound.Z and position.Z <= maxBound.Z then
			return true
		end
	end
	
	-- Raycast down to check water parts
	if #waterParts > 0 then
		local waterParams = RaycastParams.new()
		waterParams.FilterType = Enum.RaycastFilterType.Include
		waterParams.FilterDescendantsInstances = waterParts
		local rayResult = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -6, 0), waterParams)
		if rayResult then
			return true
		end
	end
	
	-- Method 2: Check Terrain water with proper grid alignment
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local checkPositions = {
			position,
			position + Vector3.new(0, -1, 0),
			position + Vector3.new(0, -2, 0),
		}
		
		for _, checkPos in ipairs(checkPositions) do
			-- Align to 4-stud grid (voxel resolution)
			local resolution = 4
			local alignedMin = Vector3.new(
				math.floor(checkPos.X / resolution) * resolution,
				math.floor(checkPos.Y / resolution) * resolution,
				math.floor(checkPos.Z / resolution) * resolution
			)
			local alignedMax = alignedMin + Vector3.new(resolution, resolution, resolution)
			
			local region = Region3.new(alignedMin, alignedMax)
			
			local success, result = pcall(function()
				local materials, _ = terrain:ReadVoxels(region, resolution)
				local size = materials.Size
				
				for x = 1, size.X do
					for y = 1, size.Y do
						for z = 1, size.Z do
							if materials[x][y][z] == Enum.Material.Water then
								return true
							end
						end
					end
				end
				return false
			end)
			
			if success and result then
				return true
			end
		end
	end
	
	return false
end

-- Get surface height at horizontal position
function WaterDetection.GetSurfaceHeight(position, excludeInstances)
	if not WaterDetection.IsActive() then return nil end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = excludeInstances or {}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayOrigin = Vector3.new(position.X, 200, position.Z)
	local rayDirection = Vector3.new(0, -300, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	
	if rayResult then
		return rayResult.Position.Y
	end
	
	return nil
end

-- Find target position for throw (raycast to find surface)
function WaterDetection.FindThrowTarget(startPos, direction, maxDistance, excludeInstances)
	if not WaterDetection.IsActive() then return nil end
	
	local horizontalTarget = startPos + (direction * maxDistance)
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = excludeInstances or {}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayOrigin = Vector3.new(horizontalTarget.X, horizontalTarget.Y + 200, horizontalTarget.Z)
	local rayDirection = Vector3.new(0, -300, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	
	if rayResult then
		return Vector3.new(horizontalTarget.X, rayResult.Position.Y + 0.5, horizontalTarget.Z)
	end
	
	return nil
end

-- Check horizontal distance between two positions
function WaterDetection.GetHorizontalDistance(pos1, pos2)
	if not WaterDetection.IsActive() then return 0 end
	
	return (Vector3.new(pos1.X, 0, pos1.Z) - Vector3.new(pos2.X, 0, pos2.Z)).Magnitude
end

-- Create debug visualization (optional)
function WaterDetection.CreateDebugMarker(position, color, duration)
	if not WaterDetection.IsActive() then return nil end
	
	local debugPart = Instance.new("Part")
	debugPart.Size = Vector3.new(2, 0.5, 2)
	debugPart.Position = position
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.Color = color or Color3.new(0, 1, 0)
	debugPart.Material = Enum.Material.Neon
	debugPart.Parent = workspace
	
	if duration then
		task.delay(duration, function()
			if debugPart and debugPart.Parent then
				debugPart:Destroy()
			end
		end)
	end
	
	return debugPart
end

-- Cache surface heights for multiple positions (performance optimization)
function WaterDetection.UpdateSurfaceCache(positions, character, floater)
	if not WaterDetection.IsActive() then return {} end
	
	local cache = {}
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character, floater}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	for i, pos in ipairs(positions) do
		local rayOrigin = Vector3.new(pos.X, 200, pos.Z)
		local rayDirection = Vector3.new(0, -300, 0)
		local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
		
		if rayResult then
			cache[i] = rayResult.Position.Y
		end
	end
	
	return cache
end

return WaterDetection
