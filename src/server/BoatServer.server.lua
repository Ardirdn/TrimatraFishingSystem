--[[
	BoatServer - Server-side boat physics handler
	Place in ServerScriptService
	
	Handles:
	- Auto-welding boat parts
	- Creating physics BodyMovers
	- Network ownership management
	- Physics simulation (movement, turning, buoyancy)
	- Tilt effects (roll, pitch)
	
	Required Structure in Workspace:
	Workspace/
	└── Boats/
	    ├── BoatModel1/
	    │   ├── BoatArea (Part)
	    │   ├── VehicleSeat (VehicleSeat)
	    │   └── [Other Parts - auto welded]
	    └── BoatModel2/
	        └── ...
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local BoatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BoatConfig"))

-- ==================== CONSTANTS ====================
local PHYSICS = BoatConfig.Physics
local BUOYANCY = BoatConfig.Buoyancy
local MOVERS = BoatConfig.BodyMovers
local FOLDERS = BoatConfig.Folders
local DEBUG = BoatConfig.Debug

-- ==================== STATE ====================
local activeBoats = {} -- [boatModel] = boatData

-- ==================== DEBUG HELPER ====================
local function debugPrint(category, ...)
	if not DEBUG.Enabled then return end
	
	if category == "buoyancy" and not DEBUG.ShowBuoyancy then return end
	if category == "tilt" and not DEBUG.ShowTilt then return end
	if category == "velocity" and not DEBUG.ShowVelocity then return end
	if category == "water" and not DEBUG.ShowWaterHeight then return end
	
	print("[BOAT DEBUG]", ...)
end

-- ==================== UTILITY FUNCTIONS ====================

-- Get water height at position (Terrain-based)
local function getWaterHeightAt(position)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
		local rayDirection = Vector3.new(0, -100, 0)
		
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = {terrain}
		
		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
		if result and result.Material == Enum.Material.Water then
			debugPrint("water", "Water at Y:", result.Position.Y)
			return result.Position.Y
		end
	end
	
	return PHYSICS.DefaultWaterHeight
end

-- Weld all parts in model to the driver seat
local function autoWeldBoat(boatModel, driverSeat)
	local descendants = boatModel:GetDescendants()
	local weldCount = 0
	local partCount = 0
	
	-- First pass: unanchor all parts
	for _, part in ipairs(descendants) do
		if part:IsA("BasePart") and part ~= driverSeat then
			partCount = partCount + 1
			if part.Anchored then
				part.Anchored = false
			end
		end
	end
	
	-- DriverSeat must be unanchored for physics
	if driverSeat.Anchored then
		driverSeat.Anchored = false
	end
	
	-- Second pass: create welds
	for _, part in ipairs(descendants) do
		if part:IsA("BasePart") and part ~= driverSeat then
			local alreadyWelded = false
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("WeldConstraint") then
					if child.Part0 == driverSeat or child.Part1 == driverSeat then
						alreadyWelded = true
						break
					end
				end
			end
			
			if not alreadyWelded then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "BoatWeld"
				weld.Part0 = driverSeat
				weld.Part1 = part
				weld.Parent = part
				weldCount = weldCount + 1
			end
		end
	end
	
	-- Handle passenger seat
	local passengerSeat = driverSeat:FindFirstChild("Seat")
	if passengerSeat and passengerSeat:IsA("BasePart") then
		passengerSeat.Anchored = false
		if not passengerSeat:FindFirstChild("BoatWeld") then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "BoatWeld"
			weld.Part0 = driverSeat
			weld.Part1 = passengerSeat
			weld.Parent = passengerSeat
			weldCount = weldCount + 1
		end
	end
	
	-- Weld complete (silent)
	return true
end

-- Create physics BodyMovers for a boat
local function createBodyMovers(driverSeat)
	-- Cleanup existing
	for _, name in ipairs({"BoatGyro", "BoatVelocity", "BoatPosition"}) do
		local existing = driverSeat:FindFirstChild(name)
		if existing then existing:Destroy() end
	end
	
	-- BodyGyro for rotation (now with X and Z for tilt!)
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "BoatGyro"
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) -- Full control for tilt
	bodyGyro.P = MOVERS.GyroP
	bodyGyro.D = MOVERS.GyroD
	bodyGyro.CFrame = driverSeat.CFrame
	bodyGyro.Parent = driverSeat
	
	-- BodyVelocity for movement
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "BoatVelocity"
	bodyVelocity.MaxForce = MOVERS.VelocityMaxForce
	bodyVelocity.P = MOVERS.VelocityP
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = driverSeat
	
	-- BodyPosition for buoyancy (math.huge to ensure it can always reach target!)
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.Name = "BoatPosition"
	bodyPosition.MaxForce = Vector3.new(0, math.huge, 0) -- Unlimited Y force
	bodyPosition.P = MOVERS.PositionP
	bodyPosition.D = BUOYANCY.BuoyancyDamping
	bodyPosition.Position = driverSeat.Position
	bodyPosition.Parent = driverSeat
	
	return {
		gyro = bodyGyro,
		velocity = bodyVelocity,
		position = bodyPosition
	}
end

-- ==================== BOAT SETUP ====================

local function setupBoat(boatModel)
	if activeBoats[boatModel] then return end
	
	local driverSeat = boatModel:FindFirstChild(FOLDERS.DriverSeatName)
	if not driverSeat or not driverSeat:IsA("VehicleSeat") then
		warn(string.format("⚠️ [BOAT SERVER] %s missing VehicleSeat named '%s'", boatModel.Name, FOLDERS.DriverSeatName))
		return
	end
	
	-- Get per-boat stats
	local stats = BoatConfig.GetBoatStats(boatModel.Name)
	
	-- Auto-weld all parts
	autoWeldBoat(boatModel, driverSeat)
	
	task.wait(0.1) -- Let physics settle
	
	-- Create body movers
	local movers = createBodyMovers(driverSeat)
	
	-- Set model primary part
	boatModel.PrimaryPart = driverSeat
	
	-- Get initial Y rotation only (ignore any pitch/roll)
	local _, yRot, _ = driverSeat.CFrame:ToEulerAnglesYXZ()
	local baseRotation = CFrame.Angles(0, yRot, 0)
	
	-- Create boat data with per-boat stats
	local boatData = {
		model = boatModel,
		driverSeat = driverSeat,
		movers = movers,
		stats = stats, -- Per-boat settings!
		currentSpeed = 0,
		currentDriver = nil,
		baseRotation = baseRotation,
		boatStartTime = tick(),
		lastThrottle = 0,
		smoothRoll = 0,
		smoothPitch = 0,
	}
	
	activeBoats[boatModel] = boatData
	
	-- Setup seat occupancy listener
	driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = driverSeat.Occupant
		
		if occupant then
			local character = occupant.Parent
			local player = Players:GetPlayerFromCharacter(character)
			
			if player then
				boatData.currentDriver = player
				
				-- Reset rotations to current
				local _, y, _ = driverSeat.CFrame:ToEulerAnglesYXZ()
				boatData.baseRotation = CFrame.Angles(0, y, 0)
				boatData.boatStartTime = tick()
				
				pcall(function()
					driverSeat:SetNetworkOwner(player)
				end)
				
				-- Player started driving (silent)
			end
		else
			if boatData.currentDriver then
				-- Player stopped driving (silent)
			end
			
			boatData.currentDriver = nil
			boatData.currentSpeed = 0
			boatData.lastThrottle = 0
			
			if boatData.movers.velocity then
				boatData.movers.velocity.Velocity = Vector3.zero
			end
			
			pcall(function()
				driverSeat:SetNetworkOwnershipAuto()
			end)
		end
	end)
	
	-- Setup complete
end

local function cleanupBoat(boatModel)
	local boatData = activeBoats[boatModel]
	if not boatData then return end
	
	if boatData.movers then
		for _, mover in pairs(boatData.movers) do
			if mover then mover:Destroy() end
		end
	end
	
	activeBoats[boatModel] = nil
	-- Cleanup complete
end

-- ==================== PHYSICS LOOP ====================

local function updateBoatPhysics(boatData, deltaTime)
	local seat = boatData.driverSeat
	local movers = boatData.movers
	local stats = boatData.stats -- Per-boat settings!
	
	if not seat or not seat.Parent then return end
	if not movers or not movers.velocity then return end
	
	local throttle = seat.Throttle
	local steer = seat.Steer
	local currentTime = tick() - boatData.boatStartTime
	
	-- ==================== SPEED CALCULATION (per-boat) ====================
	if throttle == 1 then
		boatData.currentSpeed = boatData.currentSpeed + stats.Acceleration * deltaTime * 60
	elseif throttle == -1 then
		if boatData.currentSpeed > 0 then
			boatData.currentSpeed = boatData.currentSpeed - stats.BrakeForce * deltaTime * 60
		else
			boatData.currentSpeed = boatData.currentSpeed - stats.Acceleration * deltaTime * 60
		end
	else
		if math.abs(boatData.currentSpeed) > 0.1 then
			boatData.currentSpeed = boatData.currentSpeed * (1 - stats.Deceleration * deltaTime * 10)
		else
			boatData.currentSpeed = 0
		end
	end
	
	boatData.currentSpeed = math.clamp(boatData.currentSpeed, -stats.MaxReverseSpeed, stats.MaxSpeed)
	
	-- ==================== TURNING (per-boat) ====================
	if steer ~= 0 and math.abs(boatData.currentSpeed) > 0.5 then
		local speedRatio = math.abs(boatData.currentSpeed) / stats.MaxSpeed
		local turnRate = stats.TurnSpeed + (stats.TurnSpeedAtMax - stats.TurnSpeed) * speedRatio
		local turnDirection = -steer
		boatData.baseRotation = boatData.baseRotation * CFrame.Angles(0, turnDirection * turnRate, 0)
	end

	-- ==================== VELOCITY ====================
	local lookVector = CFrame.new() * boatData.baseRotation * CFrame.new(0, 0, 0)
	movers.velocity.Velocity = lookVector.LookVector * boatData.currentSpeed
	
	-- ==================== BUOYANCY & WAVES ====================
	if BUOYANCY.Enabled then
		local seatPos = seat.Position
		local waterHeight = getWaterHeightAt(seatPos)
		
		-- Wave multiplier (per-boat + speed-based reduction)
		local speedRatio = math.abs(boatData.currentSpeed) / stats.MaxSpeed
		local waveMultiplier = (stats.WaveMultiplier or 1) * (1 - (speedRatio * BUOYANCY.SpeedWaveReduction))
		
		-- Primary wave
		local waveY = 0
		if BUOYANCY.WaveEnabled then
			waveY = math.sin(currentTime * BUOYANCY.WaveFrequency * math.pi * 2) * BUOYANCY.WaveAmplitude * waveMultiplier
		end
		
		-- Secondary wave for natural variation
		if BUOYANCY.SecondaryWaveEnabled then
			waveY = waveY + math.sin(currentTime * BUOYANCY.SecondaryWaveFrequency * math.pi * 2) * BUOYANCY.SecondaryWaveAmplitude * waveMultiplier
		end
		
		-- Target Y position (using per-boat FloatOffset!)
		local floatOffset = stats.FloatOffset or 3
		local targetY = waterHeight + floatOffset + waveY
		movers.position.Position = Vector3.new(seatPos.X, targetY, seatPos.Z)
	end
	
	-- ==================== TILT (ROLL & PITCH) ====================
	local targetRoll = 0
	local targetPitch = 0
	local speedRatio = math.abs(boatData.currentSpeed) / stats.MaxSpeed
	local waveMultiplier = (stats.WaveMultiplier or 1) * (1 - (speedRatio * BUOYANCY.SpeedWaveReduction))
	
	-- Roll from turning
	if BUOYANCY.RollEnabled then
		local turnRoll = steer * BUOYANCY.TurnRollAmount * speedRatio
		
		-- Roll from waves
		local waveRoll = math.sin(currentTime * BUOYANCY.WaveRollFrequency * math.pi * 2) * BUOYANCY.WaveRollAmplitude * waveMultiplier
		
		targetRoll = turnRoll + waveRoll
	end
	
	-- Pitch from acceleration/braking
	if BUOYANCY.PitchEnabled then
		local accelPitch = 0
		
		-- Detect acceleration state
		if throttle == 1 and boatData.currentSpeed > 0 then
			accelPitch = BUOYANCY.AccelPitchAmount * (1 - speedRatio)
		elseif throttle == -1 and boatData.currentSpeed > 0 then
			accelPitch = BUOYANCY.BrakePitchAmount
		end
		
		-- Wave pitch (continuous gentle motion)
		local wavePitch = math.cos(currentTime * BUOYANCY.WavePitchFrequency * math.pi * 2) * BUOYANCY.WavePitchAmplitude * waveMultiplier
		
		-- RANDOM WAVE BUMP (occasional pitch back when moving, like hitting a wave!)
		local bumpPitch = 0
		if BUOYANCY.WaveBumpEnabled then
			-- Initialize bump state if needed
			if not boatData.waveBumpTime then
				boatData.waveBumpTime = 0
				boatData.waveBumpActive = false
			end
			
			-- Check if bump is currently active
			if boatData.waveBumpActive then
				local bumpElapsed = tick() - boatData.waveBumpTime
				if bumpElapsed < BUOYANCY.WaveBumpDuration then
					-- Smooth bump curve (quick up, slow down)
					local bumpProgress = bumpElapsed / BUOYANCY.WaveBumpDuration
					local bumpCurve = math.sin(bumpProgress * math.pi) -- 0 -> 1 -> 0
					bumpPitch = BUOYANCY.WaveBumpAmount * bumpCurve
				else
					boatData.waveBumpActive = false
				end
			else
				-- Random chance to start new bump when moving forward
				if boatData.currentSpeed > (BUOYANCY.WaveBumpMinSpeed or 3) then
					if math.random() < (BUOYANCY.WaveBumpChance or 0.02) then
						boatData.waveBumpActive = true
						boatData.waveBumpTime = tick()
					end
				end
			end
		end
		
		targetPitch = accelPitch + wavePitch + bumpPitch
	end
	
	-- Smooth roll and pitch transitions
	local smoothFactor = deltaTime * 5 -- Adjust for smoother/snappier response
	boatData.smoothRoll = boatData.smoothRoll + (targetRoll - boatData.smoothRoll) * smoothFactor
	boatData.smoothPitch = boatData.smoothPitch + (targetPitch - boatData.smoothPitch) * smoothFactor
	
	debugPrint("tilt", string.format("Roll: %.1f°, Pitch: %.1f°", boatData.smoothRoll, boatData.smoothPitch))
	
	-- Apply rotation with tilt
	local rollRad = math.rad(boatData.smoothRoll)
	local pitchRad = math.rad(boatData.smoothPitch)
	
	-- Combine base Y rotation with roll (Z) and pitch (X)
	local finalCFrame = boatData.baseRotation * CFrame.Angles(pitchRad, 0, rollRad)
	movers.gyro.CFrame = finalCFrame
	
	-- Store throttle for next frame
	boatData.lastThrottle = throttle
end

-- Main physics heartbeat
RunService.Heartbeat:Connect(function(deltaTime)
	for boatModel, boatData in pairs(activeBoats) do
		if boatModel and boatModel.Parent then
			updateBoatPhysics(boatData, deltaTime)
		else
			cleanupBoat(boatModel)
		end
	end
end)

-- ==================== BOAT FOLDER DETECTION ====================

local function scanBoatsFolder()
	local boatsFolder = workspace:FindFirstChild(FOLDERS.BoatsFolder)
	if not boatsFolder then
		warn(string.format("⚠️ [BOAT SERVER] Folder '%s' not found in Workspace!", FOLDERS.BoatsFolder))
		return false
	end
	
	local boats = {}
	for _, child in ipairs(boatsFolder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(boats, child)
		end
	end
	
	print(string.format("🚤 [BOAT SERVER] Found %d boats in '%s' folder", #boats, FOLDERS.BoatsFolder))
	
	for _, boat in ipairs(boats) do
		task.spawn(function()
			setupBoat(boat)
		end)
	end
	
	boatsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.1)
			setupBoat(child)
		end
	end)
	
	boatsFolder.ChildRemoved:Connect(function(child)
		if child:IsA("Model") then
			cleanupBoat(child)
		end
	end)
	
	-- Now monitoring boats folder
	return true
end

-- ==================== INITIALIZATION ====================

local function waitForBoatsFolder()
	local boatsFolder = workspace:FindFirstChild(FOLDERS.BoatsFolder)
	if boatsFolder then
		scanBoatsFolder()
	else
		-- Waiting for boats folder...
		
		local conn
		conn = workspace.ChildAdded:Connect(function(child)
			if child.Name == FOLDERS.BoatsFolder then
				conn:Disconnect()
				task.wait(0.1)
				scanBoatsFolder()
			end
		end)
		
		task.delay(30, function()
			if conn.Connected then
				conn:Disconnect()
				warn(string.format("⚠️ [BOAT SERVER] Timeout waiting for '%s' folder!", FOLDERS.BoatsFolder))
			end
		end)
	end
end

waitForBoatsFolder()

print("🚤 [BOAT SERVER] Initialized")
