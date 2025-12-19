--[[
	LineRenderer Module (Simplified)
	Basic fishing line rendering with sin wave curve
	No wind effects, no water detection
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

-- Create complete fishing line WITH basic sin wave physics - returns all data + connection
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
	
	-- Start basic sin wave physics simulation
	local waveTime = 0
	local waveSpeed = 1.5  -- Speed of the wave
	local waveAmplitude = 0.3  -- Amplitude of the sin wave
	
	local physicsConnection = RunService.Heartbeat:Connect(function(dt)
		if not attachment0 or not attachment0.Parent then return end
		if not attachment1 or not attachment1.Parent then return end
		if #middlePoints == 0 then return end
		
		waveTime = waveTime + dt
		
		local startPos = attachment0.WorldPosition
		local endPos = attachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude
		
		-- Sag based on distance (catenary curve)
		local sag = math.clamp(totalDist * 0.15, 1, 8)
		
		-- Calculate rope direction
		local ropeDir = (endPos - startPos).Unit
		local worldUp = Vector3.new(0, 1, 0)
		local perpDir = ropeDir:Cross(worldUp)
		
		if perpDir.Magnitude > 0.01 then
			perpDir = perpDir.Unit
		else
			perpDir = Vector3.new(1, 0, 0)
		end
		
		-- Update each middle point position with sin wave curve
		for i, point in ipairs(middlePoints) do
			if point and point.Parent then
				local alpha = i / (numMiddlePoints + 1)
				
				-- Base position (linear interpolation)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				
				-- Parabola sag (catenary-like curve)
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = sag * parabolaFactor
				
				-- Subtle sin wave for natural look (animated)
				local sinWave = math.sin(waveTime * waveSpeed + alpha * math.pi * 2) * waveAmplitude
				local waveOffset = perpDir * sinWave * parabolaFactor  -- Wave strongest at middle
				
				local basePos = Vector3.new(midX, baseY - yOffset, midZ)
				local calculatedPos = basePos + waveOffset
				
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

-- Start rope physics with sin wave (for external calls)
function LineRenderer.StartRopePhysics(lineData, character, currentFloater, onUpdate)
	if not LineRenderer.IsActive() or not lineData then return nil end
	
	local waveTime = 0
	local waveSpeed = 1.5
	local waveAmplitude = 0.3
	
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not lineData.attachment0 or not lineData.attachment1 then return end
		if #lineData.middlePoints == 0 then return end
		
		waveTime = waveTime + dt
		
		local startPos = lineData.attachment0.WorldPosition
		local endPos = lineData.attachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude
		local sag = math.clamp(totalDist * 0.15, 1, 8)
		
		local ropeDir = (endPos - startPos).Unit
		local worldUp = Vector3.new(0, 1, 0)
		local perpDir = ropeDir:Cross(worldUp)
		
		if perpDir.Magnitude > 0.01 then
			perpDir = perpDir.Unit
		else
			perpDir = Vector3.new(1, 0, 0)
		end
		
		for i, point in ipairs(lineData.middlePoints) do
			if point and point.Parent then
				local alpha = i / (#lineData.middlePoints + 1)
				
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = sag * parabolaFactor
				
				local sinWave = math.sin(waveTime * waveSpeed + alpha * math.pi * 2) * waveAmplitude
				local waveOffset = perpDir * sinWave * parabolaFactor
				
				local basePos = Vector3.new(midX, baseY - yOffset, midZ)
				local calculatedPos = basePos + waveOffset
				
				point.Position = calculatedPos
			end
		end
		
		if onUpdate then
			onUpdate(waveTime, nil)
		end
	end)
	
	return connection
end

-- Start rope physics during pulling (STRAIGHT LINE - no curve, no wave)
function LineRenderer.StartPullingRopePhysics(lineData, tensionLevel)
	if not LineRenderer.IsActive() or not lineData then return nil end
	
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not lineData.attachment0 or not lineData.attachment1 then return end
		if #lineData.middlePoints == 0 then return end
		
		local startPos = lineData.attachment0.WorldPosition
		local endPos = lineData.attachment1.WorldPosition
		
		-- During pulling: straight line with minimal sag based on tension
		local totalDist = (endPos - startPos).Magnitude
		local baseSag = math.clamp(totalDist * 0.15, 1, 8)
		local currentSag = baseSag * (1 - (tensionLevel or 0.8))  -- High tension = less sag
		
		for i, point in ipairs(lineData.middlePoints) do
			if point and point.Parent then
				local alpha = i / (#lineData.middlePoints + 1)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				
				-- Minimal parabola sag during tension (almost straight)
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = currentSag * parabolaFactor
				
				-- No wave during pulling - straight line
				local calculatedPos = Vector3.new(midX, baseY - yOffset, midZ)
				
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
