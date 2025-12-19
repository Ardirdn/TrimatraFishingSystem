--[[
	BoatConfig - Shared configuration for boat system
	Place in ReplicatedStorage/Modules
	
	This module contains all configurable parameters for the boat physics system.
	Each boat can have its own settings via the Boats table.
]]

local BoatConfig = {}

-- ==================== PER-BOAT SETTINGS ====================
-- Each boat model can have custom settings
-- If a boat is not in this list, it uses DefaultBoatStats
BoatConfig.Boats = {
	["BasicBoat"] = {
		DisplayName = "Perahu Nelayan",
		Price = 0,              -- Free starter boat
		
		-- Speed (slow and relaxed fishing boat)
		MaxSpeed = 12,
		MaxReverseSpeed = 5,
		Acceleration = 0.08,
		Deceleration = 0.015,
		BrakeForce = 0.2,
		
		-- Turning (slow turn)
		TurnSpeed = 0.012,
		TurnSpeedAtMax = 0.006,
		
		-- Float offset (how high above water - 3 studs to not sink)
		FloatOffset = 2,
		
		-- Wave response (calm)
		WaveMultiplier = 3,
	},
	
	-- Example for future boats:
	--[[
	["SpeedBoat"] = {
		DisplayName = "Speed Boat",
		Price = 5000,
		MaxSpeed = 45,
		MaxReverseSpeed = 15,
		Acceleration = 0.5,
		Deceleration = 0.02,
		BrakeForce = 0.5,
		TurnSpeed = 0.02,
		TurnSpeedAtMax = 0.01,
		FloatOffset = 2,
		WaveMultiplier = 0.6, -- More stable
	},
	
	["FishingTrawler"] = {
		DisplayName = "Kapal Trawler",
		Price = 15000,
		MaxSpeed = 18,
		MaxReverseSpeed = 8,
		Acceleration = 0.1,
		Deceleration = 0.01,
		BrakeForce = 0.15,
		TurnSpeed = 0.008,
		TurnSpeedAtMax = 0.004,
		FloatOffset = 4,
		WaveMultiplier = 0.8,
	},
	]]
}

-- Default stats for boats not in the list above
BoatConfig.DefaultBoatStats = {
	DisplayName = "Boat",
	Price = 1000,
	MaxSpeed = 15,
	MaxReverseSpeed = 6,
	Acceleration = 0.1,
	Deceleration = 0.02,
	BrakeForce = 0.25,
	TurnSpeed = 0.015,
	TurnSpeedAtMax = 0.008,
	FloatOffset = 3,
	WaveMultiplier = 1.0,
}

-- ==================== GLOBAL PHYSICS (applies to all boats) ====================
BoatConfig.Physics = {
	DefaultWaterHeight = 24,   -- Fallback water Y level if terrain not found
}

-- ==================== BUOYANCY SETTINGS ====================
-- Calm, realistic ocean waves (global - affected by per-boat WaveMultiplier)
BoatConfig.Buoyancy = {
	Enabled = true,
	
	-- Base buoyancy
	BuoyancyForce = 50000,
	BuoyancyDamping = 800,
	
	-- Wave bobbing - CALM AND SLOW
	WaveEnabled = true,
	WaveAmplitude = 0.2,       -- Gentle bob (studs)
	WaveFrequency = 0.12,      -- Very slow (~8 seconds per cycle)
	
	-- Secondary wave
	SecondaryWaveEnabled = true,
	SecondaryWaveAmplitude = 0.08,
	SecondaryWaveFrequency = 0.2,
	
	-- Roll (side-to-side tilt) - GENTLE
	RollEnabled = true,
	WaveRollAmplitude = 0.8,   -- Degrees
	WaveRollFrequency = 0.1,
	TurnRollAmount = 3,        -- Degrees when turning
	
	-- Pitch (front-to-back tilt) - SUBTLE
	PitchEnabled = true,
	AccelPitchAmount = 1.5,    -- Degrees when accelerating
	BrakePitchAmount = -1,     -- Degrees when braking
	WavePitchAmplitude = 0.6,  -- Degrees from continuous wave
	WavePitchFrequency = 0.15,
	
	-- RANDOM WAVE BUMP (occasional pitch back when moving, like hitting a wave!)
	WaveBumpEnabled = true,
	WaveBumpChance = 0.005,     -- 2% chance per frame when moving
	WaveBumpAmount = 3,        -- Degrees to pitch back (nose up)
	WaveBumpDuration = 0.5,    -- Seconds the bump lasts
	WaveBumpMinSpeed = 3,      -- Minimum speed to trigger bumps
	
	-- Speed-based wave reduction
	SpeedWaveReduction = 0.4,
}

-- ==================== BODY MOVERS ====================
BoatConfig.BodyMovers = {
	GyroMaxTorque = Vector3.new(math.huge, math.huge, math.huge),
	GyroP = 5000,
	GyroD = 500,
	VelocityMaxForce = Vector3.new(math.huge, 0, math.huge),
	VelocityP = 1500,
	PositionMaxForce = Vector3.new(0, 50000, 0),
	PositionP = 5000,
	PositionD = 800,
}

-- ==================== FOLDER STRUCTURE ====================
BoatConfig.Folders = {
	BoatsFolder = "Boats",
	BoatAreaName = "BoatArea",
	DriverSeatName = "VehicleSeat",
}

-- ==================== PROMPT SETTINGS ====================
BoatConfig.Prompt = {
	DriveActionText = "Drive",
	ObjectText = "Boat",
	HoldDuration = 0,
	MaxDistance = 10,
	RequiresLineOfSight = false,
}

-- ==================== CAMERA ====================
BoatConfig.Camera = {
	AdjustOnEnter = true,
	MinZoom = 10,
	MaxZoom = 300,
	RestoreOnExit = true,
}

-- ==================== DEBUG ====================
BoatConfig.Debug = {
	Enabled = false,
	ShowVelocity = false,
	ShowWaterHeight = false,
	ShowBuoyancy = false,
	ShowTilt = false,
}

-- ==================== HELPER FUNCTION ====================
-- Get boat stats (per-boat or default)
function BoatConfig.GetBoatStats(boatName)
	return BoatConfig.Boats[boatName] or BoatConfig.DefaultBoatStats
end

return BoatConfig
