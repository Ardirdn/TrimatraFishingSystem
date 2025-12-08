--[[
	FISHING REPLICATION CLIENT (v3 - BUG FIXES)
	
	FIXES:
	1. Line tegang saat pulling (tidak menggantung ke air)
	2. Exclude semua floater dari surface detection
	3. Animasi ikan bergerak saat pulling
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURATION
-- ============================================
local Config = {
	AnimatedDistance = 300,
	MaxRenderDistance = 500,
	LineWidth = 0.12,
	DefaultLineColor = Color3.fromRGB(0, 255, 255),
	NumLineSegments = 25,
	BobSpeed = 2,
	BobHeight = 0.15,
	ThrowDuration = 1.5,
	
	-- Pulling config
	PullMoveSpeed = 8,
	PullMoveRange = 12,
	PullVerticalSpeed = 6,
	PullVerticalDepth = 2,
}

-- Wind settings
local WindSettings = {
	SwayStrength = 1.2,
	WindSpeed1 = 2.5,
	WindSpeed2 = 1.8,
	WaveCount = 3,
}

-- ============================================
-- WAIT FOR REMOTES
-- ============================================
local FishingRemotes = ReplicatedStorage:WaitForChild("FishingRemotes", 10)
if not FishingRemotes then
	warn("⚠️ [FISHING REPLICATION CLIENT] FishingRemotes not found!")
	return
end

local PlayerStartedFishingEvent = FishingRemotes:WaitForChild("PlayerStartedFishing", 5)
local PlayerThrewFloaterEvent = FishingRemotes:WaitForChild("PlayerThrewFloater", 5)
local PlayerStartedPullingEvent = FishingRemotes:WaitForChild("PlayerStartedPulling", 5)
local PlayerStoppedFishingEvent = FishingRemotes:WaitForChild("PlayerStoppedFishing", 5)

local StartFishingEvent = FishingRemotes:WaitForChild("StartFishing", 5)
local ThrowFloaterEvent = FishingRemotes:WaitForChild("ThrowFloater", 5)
local StartPullingEvent = FishingRemotes:WaitForChild("StartPulling", 5)
local StopFishingEvent = FishingRemotes:WaitForChild("StopFishing", 5)

print("✅ [FISHING REPLICATION CLIENT] RemoteEvents found (v3)")

-- ============================================
-- RESOURCES
-- ============================================
local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods", 5)
local FloatersFolder = FishingRodsFolder and FishingRodsFolder:FindFirstChild("Floaters")

-- ============================================
-- TRACKED OTHER PLAYERS
-- ============================================
local OtherPlayersFishing = {}

local function getPlayerData(player)
	if not OtherPlayersFishing[player] then
		OtherPlayersFishing[player] = {
			Floater = nil,
			LineSegments = {},
			LineBeams = {},
			LineStartPart = nil,
			
			-- State
			IsThrowing = false,
			IsFloating = false,
			IsPulling = false,
			FloaterBasePos = nil,
			ThrowStartPos = nil,
			ThrowTargetPos = nil,
			ThrowHeight = 8,
			ThrowStartTime = 0,
			
			-- Pull animation
			PullStartPos = nil,
			PullTargetPos = nil,
			PullTime = 0,
			
			-- Animation
			AnimationConnection = nil,
			SurfaceCache = {},
			
			LineStyle = nil,
		}
	end
	return OtherPlayersFishing[player]
end

-- ============================================
-- CLEANUP
-- ============================================
local function cleanupPlayerFishing(player)
	local data = OtherPlayersFishing[player]
	if not data then return end
	
	if data.AnimationConnection then
		data.AnimationConnection:Disconnect()
		data.AnimationConnection = nil
	end
	
	if data.Floater then
		pcall(function() data.Floater:Destroy() end)
	end
	
	if data.LineStartPart then
		pcall(function() data.LineStartPart:Destroy() end)
	end
	
	for _, segment in ipairs(data.LineSegments) do
		if segment and segment.Part then
			pcall(function() segment.Part:Destroy() end)
		end
	end
	
	for _, beam in ipairs(data.LineBeams) do
		if beam then
			pcall(function() beam:Destroy() end)
		end
	end
	
	OtherPlayersFishing[player] = nil
	print("🧹 [REPLICATION] Cleaned up", player.Name)
end

-- ============================================
-- GET PLAYER'S ROD TIP POSITION
-- ============================================
local function getPlayerRodTip(player)
	local character = player.Character
	if not character then return nil end
	
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return nil end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then return nil end
	
	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("MeshPart") or child:IsA("Part") then
			local edge = child:FindFirstChild("Edge")
			if edge and edge:IsA("BasePart") then
				return edge.Position
			end
		end
	end
	
	return handle.Position + Vector3.new(0, 2, 3)
end

-- ============================================
-- PARABOLIC POSITION
-- ============================================
local function calculateParabolicPosition(startPos, targetPos, height, alpha)
	local x = startPos.X + (targetPos.X - startPos.X) * alpha
	local z = startPos.Z + (targetPos.Z - startPos.Z) * alpha
	local baseY = startPos.Y + (targetPos.Y - startPos.Y) * alpha
	local arcOffset = 4 * height * alpha * (1 - alpha)
	return Vector3.new(x, baseY + arcOffset, z)
end

-- ============================================
-- CREATE FLOATER
-- ============================================
local function createFloater(player, floaterId, position)
	local data = getPlayerData(player)
	
	if data.Floater then
		pcall(function() data.Floater:Destroy() end)
	end
	
	local floaterTemplate = nil
	if FloatersFolder and floaterId then
		floaterTemplate = FloatersFolder:FindFirstChild(floaterId)
	end
	
	local floater
	if floaterTemplate then
		floater = floaterTemplate:Clone()
		floater.Name = "ReplicatedFloater_" .. player.Name
	else
		floater = Instance.new("Part")
		floater.Size = Vector3.new(0.8, 0.4, 0.8)
		floater.Shape = Enum.PartType.Cylinder
		floater.Material = Enum.Material.SmoothPlastic
		floater.Color = Color3.fromRGB(255, 100, 100)
		floater.Name = "ReplicatedFloater_" .. player.Name
	end
	
	if floater:IsA("Model") then
		for _, part in ipairs(floater:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
		floater.PrimaryPart = floater:FindFirstChildWhichIsA("BasePart")
		if floater.PrimaryPart then
			floater:SetPrimaryPartCFrame(CFrame.new(position))
		end
	else
		floater.Anchored = true
		floater.CanCollide = false
		floater.CFrame = CFrame.new(position)
	end
	
	floater.Parent = workspace
	data.Floater = floater
	
	return floater
end

-- ============================================
-- CREATE FISHING LINE
-- ============================================
local function createFishingLine(player, lineStyle)
	local data = getPlayerData(player)
	
	for _, seg in ipairs(data.LineSegments) do
		if seg and seg.Part then pcall(function() seg.Part:Destroy() end) end
	end
	for _, beam in ipairs(data.LineBeams) do
		if beam then pcall(function() beam:Destroy() end) end
	end
	if data.LineStartPart then
		pcall(function() data.LineStartPart:Destroy() end)
	end
	data.LineSegments = {}
	data.LineBeams = {}
	
	local color = (lineStyle and lineStyle.Color) or Config.DefaultLineColor
	local width = (lineStyle and lineStyle.Width) or Config.LineWidth
	
	data.LineStyle = { Color = color, Width = width }
	
	local startPart = Instance.new("Part")
	startPart.Size = Vector3.new(0.1, 0.1, 0.1)
	startPart.Anchored = true
	startPart.CanCollide = false
	startPart.Transparency = 1
	startPart.Name = "ReplicatedLineStart_" .. player.Name
	startPart.Parent = workspace
	data.LineStartPart = startPart
	
	local startAtt = Instance.new("Attachment")
	startAtt.Parent = startPart
	
	local segments = {}
	for i = 1, Config.NumLineSegments do
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.05, 0.05, 0.05)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Name = "ReplicatedRope_" .. i
		part.Parent = workspace
		
		local att = Instance.new("Attachment")
		att.Parent = part
		
		table.insert(segments, {Part = part, Attachment = att})
	end
	data.LineSegments = segments
	
	local floater = data.Floater
	local endParent = nil
	if floater then
		if floater:IsA("Model") then
			endParent = floater.PrimaryPart or floater:FindFirstChildWhichIsA("BasePart")
		else
			endParent = floater
		end
	end
	
	local endAtt = Instance.new("Attachment")
	if endParent then
		endAtt.Parent = endParent
	end
	
	local allAttachments = {startAtt}
	for _, seg in ipairs(segments) do
		table.insert(allAttachments, seg.Attachment)
	end
	table.insert(allAttachments, endAtt)
	
	local beams = {}
	for i = 1, #allAttachments - 1 do
		local beam = Instance.new("Beam")
		beam.Attachment0 = allAttachments[i]
		beam.Attachment1 = allAttachments[i + 1]
		beam.Width0 = width
		beam.Width1 = width
		beam.Color = ColorSequence.new(color)
		beam.Transparency = NumberSequence.new(0.12)
		beam.FaceCamera = true
		beam.Segments = 1
		beam.CurveSize0 = 0
		beam.CurveSize1 = 0
		beam.LightInfluence = 0
		beam.LightEmission = 0.8
		beam.Parent = startPart
		table.insert(beams, beam)
	end
	data.LineBeams = beams
end

-- ============================================
-- SURFACE DETECTION (FIXED: Exclude ALL floaters AND ALL characters)
-- ============================================
local function getSurfaceY(position, player)
	local data = OtherPlayersFishing[player]
	
	-- Collect ALL objects to exclude
	local excludeList = {}
	
	-- Exclude ALL player characters (not just fishing player)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(excludeList, p.Character)
		end
	end
	
	-- Exclude ALL replicated floaters in workspace
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:find("ReplicatedFloater") or obj.Name == "Floater" then
			table.insert(excludeList, obj)
		end
	end
	
	-- Exclude this player's floater
	if data and data.Floater then
		table.insert(excludeList, data.Floater)
	end
	
	-- Exclude all line parts
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:find("ReplicatedLine") or obj.Name:find("ReplicatedRope") or obj.Name:find("RopePart") then
			table.insert(excludeList, obj)
		end
	end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = excludeList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayOrigin = Vector3.new(position.X, 200, position.Z)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -300, 0), rayParams)
	
	if rayResult then
		return rayResult.Position.Y
	end
	return nil
end

-- ============================================
-- MAIN ANIMATION LOOP
-- ============================================
local function startAnimation(player)
	local data = getPlayerData(player)
	
	if data.AnimationConnection then
		data.AnimationConnection:Disconnect()
	end
	
	local windTime = 0
	local bobTime = 0
	local pullTime = 0
	local frameCount = 0
	
	-- Pull movement variables
	local pullMoveTarget = nil
	local pullMoveStartPos = nil
	
	data.AnimationConnection = RunService.Heartbeat:Connect(function(dt)
		frameCount = frameCount + 1
		
		-- Get current floater position
		local floaterPos = nil
		if data.Floater then
			if data.Floater:IsA("Model") and data.Floater.PrimaryPart then
				floaterPos = data.Floater.PrimaryPart.Position
			elseif data.Floater:IsA("BasePart") then
				floaterPos = data.Floater.Position
			end
		end
		
		if not floaterPos then
			floaterPos = data.FloaterBasePos or data.ThrowTargetPos
		end
		if not floaterPos then return end
		
		-- Distance check
		local camPos = Camera.CFrame.Position
		local distance = (floaterPos - camPos).Magnitude
		
		-- Too far - hide
		if distance > Config.MaxRenderDistance then
			if data.Floater then
				if data.Floater:IsA("Model") then
					for _, part in ipairs(data.Floater:GetDescendants()) do
						if part:IsA("BasePart") then part.Transparency = 1 end
					end
				else
					data.Floater.Transparency = 1
				end
			end
			for _, beam in ipairs(data.LineBeams) do
				if beam then beam.Enabled = false end
			end
			return
		end
		
		-- Show visuals
		if data.Floater then
			if data.Floater:IsA("Model") then
				for _, part in ipairs(data.Floater:GetDescendants()) do
					if part:IsA("BasePart") then part.Transparency = 0 end
				end
			else
				data.Floater.Transparency = 0
			end
		end
		for _, beam in ipairs(data.LineBeams) do
			if beam then beam.Enabled = true end
		end
		
		-- Get rod tip
		local rodTip = getPlayerRodTip(player)
		if not rodTip then
			cleanupPlayerFishing(player)
			return
		end
		
		if data.LineStartPart then
			data.LineStartPart.Position = rodTip
		end
		
		windTime = windTime + dt
		bobTime = bobTime + dt
		pullTime = pullTime + dt
		
		-- === THROWING PHASE ===
		if data.IsThrowing then
			local elapsed = tick() - data.ThrowStartTime
			local alpha = math.min(elapsed / Config.ThrowDuration, 1)
			
			local newPos = calculateParabolicPosition(
				data.ThrowStartPos, 
				data.ThrowTargetPos, 
				data.ThrowHeight, 
				alpha
			)
			
			if data.Floater then
				if data.Floater:IsA("Model") and data.Floater.PrimaryPart then
					data.Floater:SetPrimaryPartCFrame(CFrame.new(newPos))
				else
					data.Floater.CFrame = CFrame.new(newPos)
				end
			end
			
			floaterPos = newPos
			
			if alpha >= 1 then
				data.IsThrowing = false
				data.IsFloating = true
				data.FloaterBasePos = data.ThrowTargetPos
			end
		
		-- === PULLING PHASE (FIX #1 & #3: Animate fish fighting) ===
		elseif data.IsPulling then
			pullTime = pullTime + dt
			
			-- Initialize pull target if needed
			if not pullMoveTarget or not data.PullStartPos then
				data.PullStartPos = data.FloaterBasePos or floaterPos
				pullMoveStartPos = data.PullStartPos
				pullMoveTarget = data.PullStartPos + Vector3.new(
					math.random(-Config.PullMoveRange, Config.PullMoveRange),
					0,
					math.random(-Config.PullMoveRange, Config.PullMoveRange)
				)
			end
			
			-- Move towards target
			local currentPos = floaterPos
			local direction = (pullMoveTarget - currentPos)
			local horizontalDir = Vector3.new(direction.X, 0, direction.Z)
			
			if horizontalDir.Magnitude < 1 then
				-- Reached target, pick new random target
				pullMoveTarget = data.PullStartPos + Vector3.new(
					math.random(-Config.PullMoveRange, Config.PullMoveRange),
					0,
					math.random(-Config.PullMoveRange, Config.PullMoveRange)
				)
			end
			
			-- Move floater
			local moveStep = horizontalDir.Unit * Config.PullMoveSpeed * dt
			if horizontalDir.Magnitude < moveStep.Magnitude then
				moveStep = horizontalDir
			end
			
			-- Vertical bobbing (fish pulling down)
			local verticalOffset = -math.abs(math.sin(pullTime * Config.PullVerticalSpeed)) * Config.PullVerticalDepth
			
			local baseY = data.PullStartPos and data.PullStartPos.Y or floaterPos.Y
			local newPos = Vector3.new(
				currentPos.X + moveStep.X,
				baseY + verticalOffset,
				currentPos.Z + moveStep.Z
			)
			
			if data.Floater then
				if data.Floater:IsA("Model") and data.Floater.PrimaryPart then
					data.Floater:SetPrimaryPartCFrame(CFrame.new(newPos))
				else
					data.Floater.CFrame = CFrame.new(newPos)
				end
			end
			
			floaterPos = newPos
		
		-- === BOBBING PHASE ===
		elseif data.IsFloating and data.FloaterBasePos then
			local bobOffset = math.sin(bobTime * Config.BobSpeed) * Config.BobHeight
			local newPos = data.FloaterBasePos + Vector3.new(0, bobOffset, 0)
			
			if data.Floater then
				if data.Floater:IsA("Model") and data.Floater.PrimaryPart then
					data.Floater:SetPrimaryPartCFrame(CFrame.new(newPos))
				else
					data.Floater.CFrame = CFrame.new(newPos)
				end
			end
			
			floaterPos = newPos
		end
		
		-- === LINE ANIMATION ===
		local startPos = rodTip
		local endPos = floaterPos
		local totalDist = (endPos - startPos).Magnitude
		
		-- FIX #1: Line tension based on state
		local sag
		if data.IsPulling then
			-- TENSE LINE when pulling (minimal sag)
			sag = math.clamp(totalDist * 0.05, 0.3, 2)
		else
			-- Normal sag
			sag = math.clamp(totalDist * 0.25, 2, 15)
		end
		
		local ropeDir = (endPos - startPos).Unit
		local windDir = ropeDir:Cross(Vector3.new(0, 1, 0))
		if windDir.Magnitude > 0.01 then
			windDir = windDir.Unit
		else
			windDir = Vector3.new(1, 0, 0)
		end
		
		-- Update surface cache (less often when pulling)
		local surfaceUpdateInterval = data.IsPulling and 30 or 15
		if frameCount % surfaceUpdateInterval == 0 and not data.IsPulling then
			data.SurfaceCache = {}
			for i = 1, Config.NumLineSegments do
				local alpha = i / (Config.NumLineSegments + 1)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local surfaceY = getSurfaceY(Vector3.new(midX, 0, midZ), player)
				data.SurfaceCache[i] = surfaceY
			end
		end
		
		local useAnimation = distance <= Config.AnimatedDistance
		
		for i, segment in ipairs(data.LineSegments) do
			if segment.Part then
				local alpha = i / (Config.NumLineSegments + 1)
				
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = sag * parabolaFactor
				
				local finalPos
				
				if useAnimation and not data.IsPulling then
					-- Wind animation (only when NOT pulling)
					local swayStrength = math.sin(alpha * math.pi) * WindSettings.SwayStrength
					local combinedWave = 0
					combinedWave = combinedWave + math.sin(windTime * WindSettings.WindSpeed1 + alpha * 3)
					combinedWave = combinedWave + math.sin(windTime * WindSettings.WindSpeed2 + alpha * 5) * 0.6
					if WindSettings.WaveCount >= 3 then
						combinedWave = combinedWave + math.sin(windTime * 2.5 + alpha * 7) * 0.4
					end
					combinedWave = combinedWave * swayStrength
					
					local windOffset = windDir * combinedWave
					local downwardWave = math.abs(math.sin(windTime * 0.8 + alpha * 2)) * 0.15
					
					finalPos = Vector3.new(midX, baseY - yOffset - downwardWave, midZ) + windOffset
				elseif data.IsPulling then
					-- Tense line (minimal sag, slight vibration)
					local vibration = math.sin(pullTime * 20 + alpha * 10) * 0.05
					finalPos = Vector3.new(midX, baseY - yOffset + vibration, midZ)
				else
					finalPos = Vector3.new(midX, baseY - yOffset, midZ)
				end
				
				-- Surface clamping (only when NOT pulling)
				if not data.IsPulling then
					local surfaceY = data.SurfaceCache[i]
					if surfaceY then
						local minY = surfaceY - 0.05
						if finalPos.Y < minY then
							finalPos = Vector3.new(finalPos.X, minY, finalPos.Z)
						end
					end
				end
				
				segment.Part.Position = finalPos
			end
		end
	end)
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

if PlayerStartedFishingEvent then
	PlayerStartedFishingEvent.OnClientEvent:Connect(function(player, eventData)
		print("🎣 [REPLICATION]", player.Name, "started fishing")
		local data = getPlayerData(player)
		data.RodId = eventData.RodId
		data.FloaterId = eventData.FloaterId
	end)
end

if PlayerThrewFloaterEvent then
	PlayerThrewFloaterEvent.OnClientEvent:Connect(function(player, eventData)
		print("🎣 [REPLICATION]", player.Name, "threw floater")
		
		local data = getPlayerData(player)
		
		data.IsThrowing = true
		data.IsFloating = false
		data.IsPulling = false
		data.ThrowStartPos = eventData.StartPos
		data.ThrowTargetPos = eventData.TargetPos
		data.ThrowHeight = eventData.ThrowHeight or 8
		data.ThrowStartTime = tick()
		data.FloaterBasePos = eventData.TargetPos
		data.PullStartPos = nil
		
		createFloater(player, eventData.FloaterId, eventData.StartPos)
		createFishingLine(player, eventData.LineStyle)
		startAnimation(player)
	end)
end

if PlayerStartedPullingEvent then
	PlayerStartedPullingEvent.OnClientEvent:Connect(function(player, eventData)
		print("🎣 [REPLICATION]", player.Name, "started pulling")
		local data = OtherPlayersFishing[player]
		if data then
			data.IsPulling = true
			data.IsFloating = false
			data.PullStartPos = data.FloaterBasePos
		end
	end)
end

if PlayerStoppedFishingEvent then
	PlayerStoppedFishingEvent.OnClientEvent:Connect(function(player, eventData)
		print("🎣 [REPLICATION]", player.Name, "stopped fishing")
		cleanupPlayerFishing(player)
	end)
end

-- ============================================
-- EXPOSE FOR MAIN FISHING HANDLER
-- ============================================
_G.FishingReplication = {
	NotifyStartFishing = function(rodId, floaterId)
		if StartFishingEvent then
			StartFishingEvent:FireServer(rodId, floaterId)
		end
	end,
	
	NotifyThrowFloater = function(startPos, targetPos, rodId, floaterId, lineStyle, throwHeight)
		if ThrowFloaterEvent then
			ThrowFloaterEvent:FireServer(startPos, targetPos, rodId, floaterId, lineStyle, throwHeight)
		end
	end,
	
	NotifyStartPulling = function()
		if StartPullingEvent then
			StartPullingEvent:FireServer()
		end
	end,
	
	NotifyStopFishing = function()
		if StopFishingEvent then
			StopFishingEvent:FireServer()
		end
	end,
	
	NotifyUpdateFloaterPos = function() end,
	NotifyUpdateLineSegments = function() end,
}

Players.PlayerRemoving:Connect(cleanupPlayerFishing)

print("✅ [FISHING REPLICATION CLIENT] Loaded (v3 - fixed pulling & surface)")
