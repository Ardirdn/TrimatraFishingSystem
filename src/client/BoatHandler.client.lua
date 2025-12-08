--[[
	BoatHandler - Client-side boat interaction handler
	Place in StarterPlayerScripts
	
	Handles:
	- ProximityPrompt creation for BoatArea
	- Camera adjustments when driving
	- Local player boat state
	- Boat UI (future)
	
	Required Structure in Workspace:
	Workspace/
	└── Boats/
	    ├── BoatModel1/
	    │   ├── BoatArea (Part) - Proximity trigger
	    │   ├── DriverSeat (VehicleSeat)
	    │   └── [Other Parts]
	    └── BoatModel2/
	        └── ...
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Modules
local BoatConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BoatConfig"))

-- ==================== CONSTANTS ====================
local PROMPT = BoatConfig.Prompt
local FOLDERS = BoatConfig.Folders
local DEBUG = BoatConfig.Debug

-- ==================== STATE ====================
local detectedBoats = {} -- [boatModel] = {prompt, connections}
local currentBoat = nil  -- Boat player is currently driving
local isDriving = false

-- ==================== UTILITY ====================

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- ==================== PROXIMITY PROMPT ====================

local function createProximityPrompt(boatArea, boatModel)
	-- Check if prompt already exists
	local existingPrompt = boatArea:FindFirstChildOfClass("ProximityPrompt")
	if existingPrompt then
		return existingPrompt
	end
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = PROMPT.DriveActionText or "Drive"
	prompt.ObjectText = PROMPT.ObjectText or boatModel.Name
	prompt.HoldDuration = PROMPT.HoldDuration or 0
	prompt.MaxActivationDistance = PROMPT.MaxDistance or 10
	prompt.RequiresLineOfSight = PROMPT.RequiresLineOfSight or false
	prompt.Parent = boatArea
	
	return prompt
end

-- ==================== CAMERA ====================

local originalCameraSettings = nil

local function setupDrivingCamera(seat)
	-- Save original settings
	originalCameraSettings = {
		minZoom = player.CameraMinZoomDistance,
		maxZoom = player.CameraMaxZoomDistance,
		cameraType = camera.CameraType,
		cameraSubject = camera.CameraSubject
	}
	
	-- Adjust for boat driving
	player.CameraMinZoomDistance = 8
	player.CameraMaxZoomDistance = 25
	camera.CameraSubject = seat
end

local function restoreCamera()
	if originalCameraSettings then
		player.CameraMinZoomDistance = originalCameraSettings.minZoom
		player.CameraMaxZoomDistance = originalCameraSettings.maxZoom
		camera.CameraSubject = getHumanoid()
		originalCameraSettings = nil
	end
end

-- ==================== BOAT SETUP ====================

local function setupBoat(boatModel)
	if detectedBoats[boatModel] then return end -- Already setup
	
	-- Wait briefly for parts to load (streaming)
	task.wait(0.1)
	
	-- Try to find BoatArea - might be nested or streaming in
	local boatArea = boatModel:FindFirstChild(FOLDERS.BoatAreaName, true) -- Search descendants
	local driverSeat = boatModel:FindFirstChild(FOLDERS.DriverSeatName, true)
	
	-- If not found, wait a bit more (streaming)
	if not boatArea or not driverSeat then
		task.wait(0.5)
		boatArea = boatModel:FindFirstChild(FOLDERS.BoatAreaName, true)
		driverSeat = boatModel:FindFirstChild(FOLDERS.DriverSeatName, true)
	end
	
	if not boatArea then
		-- Create ProximityPrompt on driverSeat instead if BoatArea doesn't exist
		if driverSeat then
			boatArea = driverSeat -- Fallback to driverSeat
			if DEBUG.Enabled then
				print(string.format("📝 [BOAT CLIENT] %s using DriverSeat as prompt location (no BoatArea)", boatModel.Name))
			end
		else
			if DEBUG.Enabled then
				warn(string.format("⚠️ [BOAT CLIENT] %s has no BoatArea or DriverSeat", boatModel.Name))
			end
			return
		end
	end
	
	if not driverSeat or not driverSeat:IsA("VehicleSeat") then
		if DEBUG.Enabled then
			warn(string.format("⚠️ [BOAT CLIENT] %s missing VehicleSeat '%s'", boatModel.Name, FOLDERS.DriverSeatName))
		end
		return
	end
	
	-- Create proximity prompt
	local prompt = createProximityPrompt(boatArea, boatModel)
	
	-- Store connections for cleanup
	local connections = {}
	
	-- Prompt triggered - sit player in boat
	table.insert(connections, prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player then return end
		
		-- Check if seat is available
		if not driverSeat.Occupant then
			local humanoid = getHumanoid()
			if humanoid then
				driverSeat:Sit(humanoid)
			end
		end
	end))
	
	-- Update prompt based on seat availability
	local function updatePromptState()
		if driverSeat.Occupant then
			-- Seat occupied - hide prompt
			prompt.Enabled = false
		else
			-- Seat available
			prompt.ActionText = PROMPT.DriveActionText or "Drive"
			prompt.Enabled = true
		end
	end
	
	table.insert(connections, driverSeat:GetPropertyChangedSignal("Occupant"):Connect(updatePromptState))
	
	-- Initial state
	updatePromptState()
	
	-- Store boat data
	detectedBoats[boatModel] = {
		prompt = prompt,
		connections = connections,
		driverSeat = driverSeat,
		boatArea = boatArea
	}
	
	if DEBUG.Enabled then
		print(string.format("✅ [BOAT CLIENT] Setup complete for %s", boatModel.Name))
	end
end

local function cleanupBoat(boatModel)
	local boatData = detectedBoats[boatModel]
	if not boatData then return end
	
	-- Disconnect all connections
	for _, conn in ipairs(boatData.connections) do
		if conn then conn:Disconnect() end
	end
	
	-- Destroy prompt if we created it
	if boatData.prompt then
		boatData.prompt:Destroy()
	end
	
	detectedBoats[boatModel] = nil
	
	if DEBUG.Enabled then
		print(string.format("🚤 [BOAT CLIENT] Cleaned up %s", boatModel.Name))
	end
end

-- ==================== PLAYER SEATED DETECTION ====================

local function onSeated(isSeated, seatPart)
	if isSeated and seatPart then
		-- Check if this is a boat VehicleSeat
		for boatModel, boatData in pairs(detectedBoats) do
			if seatPart == boatData.driverSeat then
				-- Player is driving this boat
				currentBoat = boatModel
				isDriving = true
				setupDrivingCamera(seatPart)
				break
			end
		end
	else
		-- Player got up
		if currentBoat then
			restoreCamera()
			currentBoat = nil
			isDriving = false
		end
	end
end

-- ==================== BOATS FOLDER DETECTION ====================

local function scanBoatsFolder()
	local boatsFolder = workspace:FindFirstChild(FOLDERS.BoatsFolder)
	if not boatsFolder then
		if DEBUG.Enabled then
			warn(string.format("⚠️ [BOAT CLIENT] Folder '%s' not found in Workspace", FOLDERS.BoatsFolder))
		end
		return
	end
	
	-- Setup existing boats
	for _, child in ipairs(boatsFolder:GetChildren()) do
		if child:IsA("Model") then
			setupBoat(child)
		end
	end
	
	-- Listen for new boats (streaming)
	boatsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait() -- Wait for children to load
			setupBoat(child)
		end
	end)
	
	-- Listen for removed boats
	boatsFolder.ChildRemoved:Connect(function(child)
		if child:IsA("Model") then
			cleanupBoat(child)
		end
	end)
	
	-- Monitoring boats folder
end

-- ==================== CHARACTER SETUP ====================

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Seated:Connect(onSeated)
	end
end

-- Setup current character
local character = player.Character
if character then
	setupCharacter(character)
end

-- Setup future characters (respawn)
player.CharacterAdded:Connect(setupCharacter)

-- ==================== INITIALIZATION ====================

-- Wait for boats folder to exist (streaming)
local function waitForBoatsFolder()
	local boatsFolder = workspace:FindFirstChild(FOLDERS.BoatsFolder)
	if boatsFolder then
		scanBoatsFolder()
	else
		-- Wait for it to be added
		local conn
		conn = workspace.ChildAdded:Connect(function(child)
			if child.Name == FOLDERS.BoatsFolder then
				conn:Disconnect()
				scanBoatsFolder()
			end
		end)
		
		-- Timeout after 30 seconds
		task.delay(30, function()
			if conn and conn.Connected then
				conn:Disconnect()
				if DEBUG.Enabled then
					warn(string.format("⚠️ [BOAT CLIENT] Timeout waiting for '%s' folder", FOLDERS.BoatsFolder))
				end
			end
		end)
	end
end

waitForBoatsFolder()

print("🚤 [BOAT CLIENT] Initialized")

-- ==================== PUBLIC API (for other scripts) ====================

-- Expose state to other client scripts via _G (optional)
_G.BoatHandler = {
	GetCurrentBoat = function()
		return currentBoat
	end,
	
	IsDriving = function()
		return isDriving
	end,
	
	GetDetectedBoats = function()
		return detectedBoats
	end
}
