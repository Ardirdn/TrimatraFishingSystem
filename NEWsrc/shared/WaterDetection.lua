--[[
	WaterDetection Module
	Detects if a position is above/in water
	
	Water detection methods:
	1. Terrain water (voxel based)
	2. Parts with "Water", "Lake", "River", "Sea", "Ocean", "Pond" in name
	3. Non-collidable parts with glass/forcefield material
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

-- Check if position is in/above water
function WaterDetection.IsPositionInWater(position, excludeInstances)
	excludeInstances = excludeInstances or {}
	
	-- Method 1: Check Terrain water
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		-- Check if position is submerged in terrain water
		local regionSize = Vector3.new(4, 4, 4)
		local region = Region3.new(position - regionSize/2, position + regionSize/2)
		
		-- Use direct terrain water check with pcall for safety
		local success, materials, occupancy = pcall(function()
			return terrain:ReadVoxels(region:ExpandToGrid(4), 4)
		end)
		
		if success and materials then
			-- materials is a 3D array [x][y][z]
			for x = 1, #materials do
				if type(materials[x]) == "table" then
					for y = 1, #materials[x] do
						if type(materials[x][y]) == "table" then
							for z = 1, #materials[x][y] do
								if materials[x][y][z] == Enum.Material.Water then
									return true
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- Method 2: Check for Water parts (any part with water-related name)
	local rayOrigin = position + Vector3.new(0, 2, 0)
	local rayDirection = Vector3.new(0, -10, 0)
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = excludeInstances
	
	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result and result.Instance then
		local partName = result.Instance.Name:lower()
		local waterKeywords = {"water", "lake", "river", "sea", "ocean", "pond", "pool", "laut", "sungai", "danau"}
		
		for _, keyword in ipairs(waterKeywords) do
			if partName:find(keyword) then
				return true
			end
		end
		
		-- Also check parent names
		local parent = result.Instance.Parent
		if parent then
			local parentName = parent.Name:lower()
			for _, keyword in ipairs(waterKeywords) do
				if parentName:find(keyword) then
					return true
				end
			end
		end
	end
	
	-- Method 3: Check for non-collidable surfaces with water-like materials
	local checkBelow = workspace:Raycast(position, Vector3.new(0, -5, 0), rayParams)
	if checkBelow and checkBelow.Instance then
		if not checkBelow.Instance.CanCollide then
			local material = checkBelow.Instance.Material
			if material == Enum.Material.Glass or material == Enum.Material.ForceField or material == Enum.Material.Neon then
				return true
			end
		end
	end
	
	return false
end

-- Get surface height (returns nil if not on water)
function WaterDetection.GetSurfaceHeight(position, excludeInstances)
	excludeInstances = excludeInstances or {}
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = excludeInstances
	
	local result = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), rayParams)
	if result then
		return result.Position.Y
	end
	return nil
end

-- Find target position for throw (simplified - just returns horizontal target)
function WaterDetection.FindThrowTarget(startPos, direction, maxDistance, excludeInstances)
	return startPos + (direction * maxDistance)
end

-- Check horizontal distance between two positions
function WaterDetection.GetHorizontalDistance(pos1, pos2)
	return (Vector3.new(pos1.X, 0, pos1.Z) - Vector3.new(pos2.X, 0, pos2.Z)).Magnitude
end

-- Create debug visualization (disabled - returns nil)
function WaterDetection.CreateDebugMarker(position, color, duration)
	return nil
end

-- Cache surface heights (disabled - returns empty table)
function WaterDetection.UpdateSurfaceCache(positions, character, floater)
	return {}
end

return WaterDetection
