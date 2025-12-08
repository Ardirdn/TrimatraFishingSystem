--[[
	LineRenderer Module
	Advanced fishing line physics and rendering
	Optimized rope simulation with wind dynamics
]]

local RunService = game:GetService("RunService")

local LineRenderer = {}
LineRenderer.__index = LineRenderer

-- Runtime state
local _state = {_f = 1.0, _ready = false}

function LineRenderer.Initialize(factor)
	_state._f = factor or 1.0
	_state._ready = true
end

function LineRenderer.IsActive()
	return _state._ready and _state._f > 0.5
end

-- Wind animation presets
local WindPresets = {
	GENTLE = { SwayStrength = 0.15, WindSpeed1 = 0.8, WindSpeed2 = 0.5, WaveCount = 2, Description = "Angin sepoi-sepoi" },
	MEDIUM = { SwayStrength = 0.3, WindSpeed1 = 1.2, WindSpeed2 = 0.8, WaveCount = 2, Description = "Angin normal" },
	STRONG = { SwayStrength = 0.8, WindSpeed1 = 2.0, WindSpeed2 = 1.5, WaveCount = 3, Description = "Angin kencang" },
	VERY_STRONG = { SwayStrength = 1.2, WindSpeed1 = 2.5, WindSpeed2 = 1.8, WaveCount = 3, Description = "Angin sangat kencang" },
	EXTREME = { SwayStrength = 2.0, WindSpeed1 = 4.0, WindSpeed2 = 3.2, WaveCount = 4, Description = "Badai/topan" },
	CUSTOM = { SwayStrength = 5, WindSpeed1 = 8, WindSpeed2 = 6.4, WaveCount = 8, Description = "Custom" }
}

local CurrentWindPreset = "EXTREME"

function LineRenderer.GetWindSettings()
	local preset = WindPresets[CurrentWindPreset] or WindPresets.MEDIUM
	return preset
end

function LineRenderer.SetWindPreset(presetName)
	if WindPresets[presetName] then
		CurrentWindPreset = presetName
	end
end

-- Create beam segment with line style
function LineRenderer.CreateBeamSegment(attachment0, attachment1, lineStyle)
	if not LineRenderer.IsActive() then return nil end
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Width0 = lineStyle.Width or 0.16
	beam.Width1 = lineStyle.Width or 0.16
	beam.Color = ColorSequence.new(lineStyle.Color or Color3.fromRGB(0, 255, 255))
	beam.Transparency = NumberSequence.new(lineStyle.Transparency or 0.12)
	beam.FaceCamera = lineStyle.FaceCamera ~= false
	beam.Segments = 1
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.LightInfluence = lineStyle.LightInfluence or 0
	beam.LightEmission = lineStyle.LightEmission or 10
	return beam
end

-- Create middle points for rope physics (invisible parts)
function LineRenderer.CreateMiddlePoints(numPoints, parent)
	if not LineRenderer.IsActive() then return {} end
	
	local points = {}
	for i = 1, numPoints do
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.05, 0.05, 0.05)
		part.Transparency = 1
		part.CanCollide = false
		part.Anchored = true
		part.Name = "RopePart_" .. i
		part.Parent = parent or workspace
		table.insert(points, part)
	end
	return points
end

-- Create complete fishing line setup
function LineRenderer.CreateFishingLine(edgePart, floaterPart, lineStyle, numMiddlePoints)
	if not LineRenderer.IsActive() then return nil end
	
	numMiddlePoints = numMiddlePoints or 30
	
	-- Create start attachment on edge
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, 0)
	attachment0.Parent = edgePart
	
	-- Create end attachment on floater
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, 0)
	attachment1.Parent = floaterPart
	
	-- Style the edge and floater connection points
	edgePart.Material = Enum.Material.Neon
	edgePart.Color = lineStyle.Color
	floaterPart.Material = Enum.Material.Neon
	floaterPart.Color = lineStyle.Color
	
	-- Create middle points
	local middlePoints = LineRenderer.CreateMiddlePoints(numMiddlePoints, workspace)
	
	-- Create attachments for all points
	local allAttachments = {attachment0}
	for i, point in ipairs(middlePoints) do
		local att = Instance.new("Attachment")
		att.Parent = point
		table.insert(allAttachments, att)
	end
	table.insert(allAttachments, attachment1)
	
	-- Create beam segments between all points
	local beamSegments = {}
	for i = 1, #allAttachments - 1 do
		local beam = LineRenderer.CreateBeamSegment(allAttachments[i], allAttachments[i + 1], lineStyle)
		if beam then
			beam.Parent = edgePart
			table.insert(beamSegments, beam)
		end
	end
	
	return {
		attachment0 = attachment0,
		attachment1 = attachment1,
		middlePoints = middlePoints,
		beamSegments = beamSegments,
		allAttachments = allAttachments
	}
end

-- Create complete fishing line WITH physics already running - returns all data + connection
function LineRenderer.CreateCompleteFishingLineWithPhysics(edgePart, floaterPart, lineStyle, numMiddlePoints, character, currentFloater)
	if not LineRenderer.IsActive() then return nil end
	
	numMiddlePoints = numMiddlePoints or 30
	
	-- Create start attachment on edge
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, 0)
	attachment0.Parent = edgePart
	
	-- Create end attachment on floater
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, 0)
	attachment1.Parent = floaterPart
	
	-- Style the edge and floater connection points
	pcall(function()
		edgePart.Material = Enum.Material.Neon
		edgePart.Color = lineStyle.Color
		floaterPart.Material = Enum.Material.Neon
		floaterPart.Color = lineStyle.Color
	end)
	
	-- Create middle points
	local middlePoints = {}
	for i = 1, numMiddlePoints do
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.05, 0.05, 0.05)
		part.Transparency = 1
		part.CanCollide = false
		part.Anchored = true
		part.Name = "RopePart_" .. i
		part.Parent = workspace
		table.insert(middlePoints, part)
	end
	
	-- Create attachments for all points
	local allAttachments = {attachment0}
	for i, point in ipairs(middlePoints) do
		local att = Instance.new("Attachment")
		att.Parent = point
		table.insert(allAttachments, att)
	end
	table.insert(allAttachments, attachment1)
	
	-- Create beam segments between all points
	local beamSegments = {}
	for i = 1, #allAttachments - 1 do
		local beam = LineRenderer.CreateBeamSegment(allAttachments[i], allAttachments[i + 1], lineStyle)
		if beam then
			beam.Parent = edgePart
			table.insert(beamSegments, beam)
		end
	end
	
	-- Start physics simulation
	local windConfig = LineRenderer.GetWindSettings()
	local windTime = 0
	local surfaceCache = {}
	local frameCount = 0
	
	local physicsConnection = RunService.Heartbeat:Connect(function(dt)
		if not attachment0 or not attachment0.Parent then return end
		if not attachment1 or not attachment1.Parent then return end
		if #middlePoints == 0 then return end
		
		windTime = windTime + dt
		frameCount = frameCount + 1
		
		local startPos = attachment0.WorldPosition
		local endPos = attachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude
		local sag = math.clamp(totalDist * 0.25, 3, 18)
		
		-- Calculate rope direction and perpendicular wind direction
		local ropeDir = (endPos - startPos).Unit
		local worldUp = Vector3.new(0, 1, 0)
		local windDir = ropeDir:Cross(worldUp)
		
		if windDir.Magnitude > 0.01 then
			windDir = windDir.Unit
		else
			windDir = Vector3.new(1, 0, 0)
		end
		
		-- Update surface cache every 10 frames for performance
		local shouldUpdateSurface = (frameCount % 10 == 0)
		
		if shouldUpdateSurface then
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character, currentFloater}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			
			for i, point in ipairs(middlePoints) do
				if point and point.Parent then
					local alpha = i / (numMiddlePoints + 1)
					local midX = startPos.X + (endPos.X - startPos.X) * alpha
					local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
					
					local rayOrigin = Vector3.new(midX, 200, midZ)
					local rayDirection = Vector3.new(0, -300, 0)
					local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
					
					if rayResult then
						surfaceCache[i] = rayResult.Position.Y
					else
						surfaceCache[i] = nil
					end
				end
			end
		end
		
		-- Update each middle point position with wind physics
		for i, point in ipairs(middlePoints) do
			if point and point.Parent then
				local alpha = i / (numMiddlePoints + 1)
				
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = sag * parabolaFactor
				
				-- Wind animation - horizontal sway
				local swayStrength = math.sin(alpha * math.pi) * windConfig.SwayStrength
				local combinedWave = 0
				
				if windConfig.WaveCount >= 1 then
					combinedWave = combinedWave + math.sin(windTime * windConfig.WindSpeed1 + alpha * 3)
				end
				if windConfig.WaveCount >= 2 then
					combinedWave = combinedWave + math.sin(windTime * windConfig.WindSpeed2 + alpha * 5) * 0.6
				end
				if windConfig.WaveCount >= 3 then
					combinedWave = combinedWave + math.sin(windTime * 2.5 + alpha * 7) * 0.4
				end
				if windConfig.WaveCount >= 4 then
					combinedWave = combinedWave + math.sin(windTime * 5.0 + alpha * 9) * 0.3
				end
				
				combinedWave = combinedWave * swayStrength
				
				-- Wind offset only horizontal
				local windOffset = windDir * combinedWave
				
				-- Subtle downward wave for realism
				local downwardWave = math.abs(math.sin(windTime * 0.8 + alpha * 2)) * 0.15
				
				local basePos = Vector3.new(midX, baseY - yOffset, midZ)
				local calculatedPos = basePos + windOffset - Vector3.new(0, downwardWave, 0)
				
				-- Soft clamp - line can penetrate surface slightly
				if surfaceCache[i] then
					local minY = surfaceCache[i] - 0.05
					calculatedPos = Vector3.new(
						calculatedPos.X,
						math.max(calculatedPos.Y, minY),
						calculatedPos.Z
					)
				end
				
				point.Position = calculatedPos
			end
		end
	end)
	
	-- Return complete bundle with everything
	return {
		attachment0 = attachment0,
		attachment1 = attachment1,
		middlePoints = middlePoints,
		beamSegments = beamSegments,
		allAttachments = allAttachments,
		physicsConnection = physicsConnection,
		fishingBeam = beamSegments[1]
	}
end


-- Start rope physics update loop
function LineRenderer.StartRopePhysics(lineData, character, currentFloater, onUpdate)
	if not LineRenderer.IsActive() or not lineData then return nil end
	
	local windConfig = LineRenderer.GetWindSettings()
	local windTime = 0
	local surfaceCache = {}
	local frameCount = 0
	
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not lineData.attachment0 or not lineData.attachment1 then return end
		if #lineData.middlePoints == 0 then return end
		
		windTime = windTime + dt
		frameCount = frameCount + 1
		
		local startPos = lineData.attachment0.WorldPosition
		local endPos = lineData.attachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude
		local sag = math.clamp(totalDist * 0.25, 3, 18)
		
		-- Calculate rope direction and perpendicular wind direction
		local ropeDir = (endPos - startPos).Unit
		local worldUp = Vector3.new(0, 1, 0)
		local windDir = ropeDir:Cross(worldUp)
		
		if windDir.Magnitude > 0.01 then
			windDir = windDir.Unit
		else
			windDir = Vector3.new(1, 0, 0)
		end
		
		-- Update surface cache every 10 frames for performance
		local shouldUpdateSurface = (frameCount % 10 == 0)
		
		if shouldUpdateSurface then
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character, currentFloater}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			
			for i, point in ipairs(lineData.middlePoints) do
				if point and point.Parent then
					local alpha = i / (#lineData.middlePoints + 1)
					local midX = startPos.X + (endPos.X - startPos.X) * alpha
					local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
					
					local rayOrigin = Vector3.new(midX, 200, midZ)
					local rayDirection = Vector3.new(0, -300, 0)
					local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
					
					if rayResult then
						surfaceCache[i] = rayResult.Position.Y
					else
						surfaceCache[i] = nil
					end
				end
			end
		end
		
		-- Update each middle point position with wind physics
		for i, point in ipairs(lineData.middlePoints) do
			if point and point.Parent then
				local alpha = i / (#lineData.middlePoints + 1)
				
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = sag * parabolaFactor
				
				-- Wind animation - horizontal sway
				local swayStrength = math.sin(alpha * math.pi) * windConfig.SwayStrength
				local combinedWave = 0
				
				if windConfig.WaveCount >= 1 then
					combinedWave = combinedWave + math.sin(windTime * windConfig.WindSpeed1 + alpha * 3)
				end
				if windConfig.WaveCount >= 2 then
					combinedWave = combinedWave + math.sin(windTime * windConfig.WindSpeed2 + alpha * 5) * 0.6
				end
				if windConfig.WaveCount >= 3 then
					combinedWave = combinedWave + math.sin(windTime * 2.5 + alpha * 7) * 0.4
				end
				if windConfig.WaveCount >= 4 then
					combinedWave = combinedWave + math.sin(windTime * 5.0 + alpha * 9) * 0.3
				end
				
				combinedWave = combinedWave * swayStrength
				
				-- Wind offset only horizontal
				local windOffset = windDir * combinedWave
				
				-- Subtle downward wave for realism
				local downwardWave = math.abs(math.sin(windTime * 0.8 + alpha * 2)) * 0.15
				
				local basePos = Vector3.new(midX, baseY - yOffset, midZ)
				local calculatedPos = basePos + windOffset - Vector3.new(0, downwardWave, 0)
				
				-- Soft clamp - line can penetrate surface slightly
				if surfaceCache[i] then
					local minY = surfaceCache[i] - 0.05
					calculatedPos = Vector3.new(
						calculatedPos.X,
						math.max(calculatedPos.Y, minY),
						calculatedPos.Z
					)
				end
				
				point.Position = calculatedPos
			end
		end
		
		if onUpdate then
			onUpdate(windTime, surfaceCache)
		end
	end)
	
	return connection
end

-- Start rope physics during pulling (tighter line, less sag)
function LineRenderer.StartPullingRopePhysics(lineData, tensionLevel)
	if not LineRenderer.IsActive() or not lineData then return nil end
	
	local windConfig = LineRenderer.GetWindSettings()
	local windTime = 0
	
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not lineData.attachment0 or not lineData.attachment1 then return end
		if #lineData.middlePoints == 0 then return end
		
		windTime = windTime + dt
		
		local startPos = lineData.attachment0.WorldPosition
		local endPos = lineData.attachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude
		
		local baseSag = math.clamp(totalDist * 0.25, 3, 18)
		local currentSag = baseSag * (1 - (tensionLevel or 0.7))
		
		local ropeDir = (endPos - startPos).Unit
		local windDir = ropeDir:Cross(Vector3.new(0, 1, 0))
		if windDir.Magnitude > 0.01 then windDir = windDir.Unit else windDir = Vector3.new(1, 0, 0) end
		
		for i, point in ipairs(lineData.middlePoints) do
			if point and point.Parent then
				local alpha = i / (#lineData.middlePoints + 1)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = currentSag * parabolaFactor
				
				-- Reduced wind during tension
				local windStrength = windConfig.SwayStrength * (1 - (tensionLevel or 0.7) * 0.7)
				local swayStrength = math.sin(alpha * math.pi) * windStrength
				local combinedWave = 0
				if windConfig.WaveCount >= 1 then combinedWave = combinedWave + math.sin(windTime * windConfig.WindSpeed1 + alpha * 3) end
				if windConfig.WaveCount >= 2 then combinedWave = combinedWave + math.sin(windTime * windConfig.WindSpeed2 + alpha * 5) * 0.6 end
				combinedWave = combinedWave * swayStrength
				local windOffset = windDir * combinedWave
				
				local basePos = Vector3.new(midX, baseY - yOffset, midZ)
				local calculatedPos = basePos + windOffset
				
				point.Position = calculatedPos
			end
		end
	end)
	
	return connection
end

-- Calculate parabolic throw position
function LineRenderer.CalculateParabolicPosition(startPos, targetPos, height, alpha)
	if not LineRenderer.IsActive() then return startPos end
	
	local x = startPos.X + (targetPos.X - startPos.X) * alpha
	local z = startPos.Z + (targetPos.Z - startPos.Z) * alpha
	local baseY = startPos.Y + (targetPos.Y - startPos.Y) * alpha
	local arcOffset = 4 * height * alpha * (1 - alpha)
	return Vector3.new(x, baseY + arcOffset, z)
end

-- Create straight line (for retrieving)
function LineRenderer.CreateStraightLine(attachment0, attachment1, lineStyle, parent)
	if not LineRenderer.IsActive() then return nil end
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Width0 = lineStyle.Width
	beam.Width1 = lineStyle.Width
	beam.Color = ColorSequence.new(lineStyle.Color)
	beam.Transparency = NumberSequence.new(lineStyle.Transparency)
	beam.FaceCamera = lineStyle.FaceCamera
	beam.Segments = 1
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.LightInfluence = lineStyle.LightInfluence
	beam.LightEmission = lineStyle.LightEmission
	beam.Parent = parent
	return beam
end

-- Create bait line (short line below floater)
function LineRenderer.CreateBaitLine(floaterPart, lineStyle, baitLineLength)
	if not LineRenderer.IsActive() then return nil end
	
	baitLineLength = baitLineLength or 5
	
	-- Attachment under floater
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, -floaterPart.Size.Y/2, 0)
	attachment0.Parent = floaterPart
	
	-- Invisible endpoint part
	local endPart = Instance.new("Part")
	endPart.Size = Vector3.new(0.1, 0.1, 0.1)
	endPart.Transparency = 1
	endPart.CanCollide = false
	endPart.Anchored = true
	endPart.Name = "BaitLineEnd"
	endPart.Parent = workspace
	endPart.Position = floaterPart.Position - Vector3.new(0, baitLineLength, 0)
	
	-- Attachment on endpoint
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, 0)
	attachment1.Parent = endPart
	
	-- Beam with same style as main line
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Width0 = lineStyle.Width
	beam.Width1 = lineStyle.Width
	beam.Color = ColorSequence.new(lineStyle.Color)
	beam.Transparency = NumberSequence.new(lineStyle.Transparency)
	beam.FaceCamera = lineStyle.FaceCamera
	beam.Segments = 1
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.LightInfluence = lineStyle.LightInfluence
	beam.LightEmission = lineStyle.LightEmission
	beam.Parent = workspace
	
	return {
		attachment0 = attachment0,
		attachment1 = attachment1,
		endPart = endPart,
		beam = beam,
		length = baitLineLength
	}
end

-- Update bait line position
function LineRenderer.UpdateBaitLine(baitLineData, floaterPosition)
	if not LineRenderer.IsActive() or not baitLineData then return end
	if not baitLineData.endPart then return end
	
	baitLineData.endPart.Position = floaterPosition - Vector3.new(0, baitLineData.length, 0)
end

-- Cleanup line data
function LineRenderer.CleanupLine(lineData)
	if not lineData then return end
	
	for _, beam in ipairs(lineData.beamSegments or {}) do
		if beam then pcall(function() beam:Destroy() end) end
	end
	
	for _, point in ipairs(lineData.middlePoints or {}) do
		if point then pcall(function() point:Destroy() end) end
	end
	
	if lineData.attachment0 then pcall(function() lineData.attachment0:Destroy() end) end
	if lineData.attachment1 then pcall(function() lineData.attachment1:Destroy() end) end
end

-- Cleanup bait line
function LineRenderer.CleanupBaitLine(baitLineData)
	if not baitLineData then return end
	
	if baitLineData.beam then pcall(function() baitLineData.beam:Destroy() end) end
	if baitLineData.attachment0 then pcall(function() baitLineData.attachment0:Destroy() end) end
	if baitLineData.attachment1 then pcall(function() baitLineData.attachment1:Destroy() end) end
	if baitLineData.endPart then pcall(function() baitLineData.endPart:Destroy() end) end
end

return LineRenderer
