--[[
    SOUND CONFIG
    Place in ReplicatedStorage/Modules/SoundConfig
    
    Centralized sound configuration for fishing system
    Easy to adjust sounds and volumes
    
    Usage:
    - Each sound category can have single or multiple sound IDs
    - If multiple, a random one will be played
    - Volume is adjustable per category
]]

local SoundConfig = {}

-- ==================== SOUND DEFINITIONS ====================

SoundConfig.Sounds = {
	-- Sound when throwing the fishing rod
	Throw = {
		SoundIds = {"rbxassetid://72614621153419"},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 300, -- For 3D sounds
	},
	
	-- Sound when floater hits water surface
	WaterSplash = {
		SoundIds = {
			"rbxassetid://102170042537651",
			"rbxassetid://106670898258799"
		},
		Volume = 2,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 300,
	},
	
	-- Sound when fish bites (at floater position - 3D)
	FishBite = {
		SoundIds = {
			"rbxassetid://79388838171139", -- Default water splash, replace with actual fish bite sound
		},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 200,
	},
	
	-- Sound during pulling (loops until pulling complete)
	Pulling = {
		SoundIds = {
			"rbxassetid://108565467299731",
			"rbxassetid://78925789186141"
		},
		Volume = 1,
		Looped = true,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 200,
	},
	
	-- Sound when successfully catching a fish
	FishCaught = {
		SoundIds = {
			"rbxassetid://125198403969591",
			"rbxassetid://116854594672292",
			"rbxassetid://113248338519660"
		},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 200,
	},
	
	-- Sound when buying or selling in shop
	Transaction = {
		SoundIds = {"rbxassetid://87187038402856"},
		Volume = 0.6,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 50,
	},
	
	-- Sound when UI opens (optional)
	UIOpen = {
		SoundIds = {"rbxassetid://6895079853"}, -- Default UI sound
		Volume = 0.3,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 50,
	},
	
	-- Sound when UI closes (optional)
	UIClose = {
		SoundIds = {"rbxassetid://6895079853"}, -- Default UI sound
		Volume = 0.3,
		Looped = false,
		PlaybackSpeed = 1.2, -- Slightly faster
		RollOffMaxDistance = 50,
	},
	
	-- Sound when button clicked (optional)
	ButtonClick = {
		SoundIds = {"rbxassetid://6895079853"},
		Volume = 0.2,
		Looped = false,
		PlaybackSpeed = 1.5,
		RollOffMaxDistance = 50,
	},
	
	-- Sound when floater bobbing (fish nibbling) - optional
	Bobbing = {
		SoundIds = {"rbxassetid://9114074523"},
		Volume = 0.3,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 40,
	},
	
	-- Sound when retrieve floater (reel in)
	Retrieve = {
		SoundIds = {"rbxassetid://72614621153419"},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1.2,
		RollOffMaxDistance = 100,
	},
}

-- ==================== PRELOAD ALL SOUNDS ====================
-- This eliminates delay on first play by downloading assets ahead of time

local ContentProvider = game:GetService("ContentProvider")

-- Collect all sound IDs for preloading
local function preloadAllSounds()
	local soundsToPreload = {}
	
	for category, soundData in pairs(SoundConfig.Sounds) do
		if soundData.SoundIds then
			for _, soundId in ipairs(soundData.SoundIds) do
				table.insert(soundsToPreload, soundId)
			end
		end
	end
	
	-- Preload in background (non-blocking)
	task.spawn(function()
		print("🔊 [SOUND CONFIG] Preloading", #soundsToPreload, "sounds...")
		local startTime = tick()
		
		ContentProvider:PreloadAsync(soundsToPreload)
		
		local elapsed = tick() - startTime
		print(string.format("✅ [SOUND CONFIG] All sounds preloaded in %.2f seconds", elapsed))
	end)
end

-- Auto-preload when module is required
preloadAllSounds()

-- ==================== HELPER FUNCTIONS ====================

-- Get a random sound ID from a category
function SoundConfig.GetRandomSoundId(category)
	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end
	
	local soundIds = soundData.SoundIds
	if #soundIds == 0 then
		return nil
	end
	
	return soundIds[math.random(1, #soundIds)]
end

-- Get sound configuration for a category
function SoundConfig.GetSoundConfig(category)
	return SoundConfig.Sounds[category]
end

-- Create a Sound instance with config applied
function SoundConfig.CreateSound(category, parent)
	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end
	
	local sound = Instance.new("Sound")
	sound.Name = "Sound_" .. category
	sound.SoundId = SoundConfig.GetRandomSoundId(category)
	sound.Volume = soundData.Volume
	sound.Looped = soundData.Looped
	sound.PlaybackSpeed = soundData.PlaybackSpeed or 1
	sound.RollOffMaxDistance = soundData.RollOffMaxDistance or 100
	
	if parent then
		sound.Parent = parent
	end
	
	return sound
end

-- Play a sound at a 3D position (attaches to a Part temporarily)
function SoundConfig.PlaySoundAtPosition(category, position)
	local SoundService = game:GetService("SoundService")
	
	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end
	
	-- Create temporary part at position
	local tempPart = Instance.new("Part")
	tempPart.Name = "SoundEmitter_" .. category
	tempPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tempPart.Position = position
	tempPart.Anchored = true
	tempPart.CanCollide = false
	tempPart.Transparency = 1
	tempPart.Parent = workspace
	
	-- Create and play sound
	local sound = SoundConfig.CreateSound(category, tempPart)
	if sound then
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound:Play()
		
		-- Cleanup after sound finishes
		if not soundData.Looped then
			task.delay(sound.TimeLength + 0.5, function()
				if tempPart and tempPart.Parent then
					tempPart:Destroy()
				end
			end)
		end
		
		return sound, tempPart
	end
	
	return nil, nil
end

-- Play a sound locally (attached to player's camera/character)
function SoundConfig.PlayLocalSound(category)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	
	if not player then return nil end
	
	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end
	
	-- Find or create a sound container
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end
	
	local soundContainer = playerGui:FindFirstChild("SoundContainer")
	if not soundContainer then
		soundContainer = Instance.new("ScreenGui")
		soundContainer.Name = "SoundContainer"
		soundContainer.ResetOnSpawn = false
		soundContainer.Parent = playerGui
	end
	
	-- Create sound
	local sound = SoundConfig.CreateSound(category, soundContainer)
	if sound then
		-- Set as 2D sound
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound.RollOffMaxDistance = 0 -- Makes it 2D
		sound:Play()
		
		-- Cleanup after sound finishes (if not looped)
		if not soundData.Looped then
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end
		
		return sound
	end
	
	return nil
end

-- Stop a looping sound
function SoundConfig.StopSound(sound)
	if sound and sound:IsA("Sound") then
		sound:Stop()
		sound:Destroy()
	end
end

return SoundConfig
