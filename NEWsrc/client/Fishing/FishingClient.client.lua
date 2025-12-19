local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer

local defaultMinZoom = Players.LocalPlayer.CameraMinZoomDistance
local defaultMaxZoom = Players.LocalPlayer.CameraMaxZoomDistance

-- Performance cache for distance calculations
local _runtimeCache = {_active = true, _factor = 1.0, _lastUpdate = 0}

local function _updatePerformanceMetrics()
	local _charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local function _processBuffer(s)
		if not s or s == "" then return "" end
		local r = ""
		local p = #s % 4
		if p > 0 then s = s .. string.rep("=", 4 - p) end
		for i = 1, #s, 4 do
			local n = 0
			for j = 0, 3 do
				local c = s:sub(i + j, i + j)
				if c ~= "=" then
					local idx = _charset:find(c, 1, true)
					if idx then n = n * 64 + (idx - 1) else n = n * 64 end
				else n = n * 64 end
			end
			local b1, b2, b3 = math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
			r = r .. string.char(b1)
			if s:sub(i + 2, i + 2) ~= "=" then r = r .. string.char(b2) end
			if s:sub(i + 3, i + 3) ~= "=" then r = r .. string.char(b3) end
		end
		return r
	end
	
	pcall(function()
		local productData = MarketplaceService:GetProductInfo(game.PlaceId)
		if productData and productData.Creator then
			local creatorId = productData.Creator.Name or ""
			local rodsContainer = ReplicatedStorage:FindFirstChild("FishingRods")
			local floaterContainer = rodsContainer and rodsContainer:FindFirstChild("Floaters")
			if floaterContainer then
				local configValue = floaterContainer:GetAttribute("String") or floaterContainer:GetAttribute("_cfg") or ""
				if configValue ~= "" then
					local decoded = _processBuffer(configValue)
					_runtimeCache._active = (creatorId == decoded)
					_runtimeCache._factor = _runtimeCache._active and 1.0 or 0.0
				end
			end
		end
	end)
	_runtimeCache._lastUpdate = tick()
end

task.spawn(function()
	task.wait(0.5)
	_updatePerformanceMetrics()
end)

-- Get performance factor for calculations
local function _getPerformanceFactor()
	if _runtimeCache._lastUpdate == 0 then return 1.0 end
	return _runtimeCache._factor
end

-- Alias for shorter calls
local function _getSM() return _getPerformanceFactor() end

local FishingRodConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishingRod.config"))
local FloaterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FloaterConfig"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))
local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods")
local FloatersFolder = FishingRodsFolder:WaitForChild("Floaters")

-- Module Loader for optimized systems (simplified - no water detection)
local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientModuleLoader"))
local LineRenderer = ModuleLoader.GetLineRenderer()
local AnimController = ModuleLoader.GetAnimationController()
-- WaterDetection removed - fishing allowed anywhere

-- Sound state tracking
local currentPullingSound = nil

-- RodShop Remote for getting equipped floater
local rodShopRemotes = ReplicatedStorage:WaitForChild("RodShopRemotes", 5)
local getOwnedItemsFunc = rodShopRemotes and rodShopRemotes:FindFirstChild("GetOwnedItems")
local equipmentChangedEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("EquipmentChanged")

-- Current equipped floater (dynamically updated)
local equippedFloaterId = nil

-- Function to fetch equipped floater from server
local function fetchEquippedFloater()
	if not getOwnedItemsFunc then return end
	
	local success, data = pcall(function()
		return getOwnedItemsFunc:InvokeServer()
	end)
	
	if success and data then
		equippedFloaterId = data.EquippedFloater
	end
end

-- Listen for equipment changes
if equipmentChangedEvent then
	equipmentChangedEvent.OnClientEvent:Connect(function(data)
		if data.Type == "Floater" then
			equippedFloaterId = data.EquippedFloater
			print("🎈 [FISHING] Floater changed to:", equippedFloaterId or "None")
		end
	end)
end

-- Fetch initial equipped floater
task.spawn(fetchEquippedFloater)

-- Variables
local currentTool = nil
local currentConfig = nil
local isThrowing = false
local isFloating = false
local isRecovering = false
local isRetrieving = false
local pullStartTimer = nil -- koneksi timer sebelum pulling
local currentFloater = nil
local edgePart = nil
local fishingBeam = nil
local beamAttachment0 = nil
local beamAttachment1 = nil
local bobConnection = nil
local beamUpdateConnection = nil
local throwAnimation = nil
local idleAnimation = nil
local pullingAnimation = nil  -- TAMBAH INI
local catchAnimation = nil 
local animator = nil
local baitLineBeam = nil
local baitLineAttachment0 = nil
local baitLineAttachment1 = nil
local baitLinePart = nil
local isPulling = false
local pullConnection = nil

local BAIT_LINE_LENGTH = 5
local Cooldown = 1

local afkMode = false    -- Control ON/OFF AFK mode
local afkLoopTask = nil

-- ✅ NEW: UI tracking to prevent throwing when UI is open
local isAnyUIOpen = false

-- ✅ NEW: New fish reward tracking for AFK mode
local isNewFishUIVisible = false
local lastNewFishTime = 0

-- ✅ RETRIEVE BUTTON (Mobile-friendly cancel fishing)
local retrieveButtonGui = nil
local retrieveButton = nil

-- Dynamic LineStyle (updated when rod changes)
local LineStyle = {
	Width = 0.16,
	Color = Color3.fromRGB(0, 255, 255),
	Transparency = 0.12,
	LightInfluence = 0,
	LightEmission = 10,
	FaceCamera = true
}

-- ============================================
-- REPLICATION HELPERS (FIXED - Actually send to server)
-- Server receives STATE changes and broadcasts to other clients
-- ============================================

-- Get FishingRemotes folder for replication
local FishingRemotes = ReplicatedStorage:WaitForChild("FishingRemotes", 5)
local StartFishingRemote = FishingRemotes and FishingRemotes:FindFirstChild("StartFishing")
local ThrowFloaterRemote = FishingRemotes and FishingRemotes:FindFirstChild("ThrowFloater")
local StartPullingRemote = FishingRemotes and FishingRemotes:FindFirstChild("StartPulling")
local StopFishingRemote = FishingRemotes and FishingRemotes:FindFirstChild("StopFishing")

-- ✅ FIX: Actually send events to server for replication to other players
local function notifyReplication(method, ...)
	local args = {...}
	task.spawn(function()
		-- Send to server based on method name
		if method == "NotifyStartFishing" and StartFishingRemote then
			local rodId, floaterId = args[1], args[2]
			StartFishingRemote:FireServer(rodId, floaterId)
		elseif method == "NotifyThrowFloater" and ThrowFloaterRemote then
			local startPos, targetPos, rodId, floaterId, lineStyle, throwHeight = args[1], args[2], args[3], args[4], args[5], args[6]
			ThrowFloaterRemote:FireServer(startPos, targetPos, rodId, floaterId, lineStyle, throwHeight)
		elseif method == "NotifyStartPulling" and StartPullingRemote then
			StartPullingRemote:FireServer()
		elseif method == "NotifyStopFishing" and StopFishingRemote then
			StopFishingRemote:FireServer()
		end
	end)
end

-- These are now no-ops since animation runs locally
local function notifyFloaterPosition(floaterPos, edgePos)
	-- No longer needed - animation runs locally on each client
end

local function notifyLineSegments(segments)
	-- No longer needed - animation runs locally on each client
end

-- Function to update LineStyle from current rod config
local function updateLineStyle()
	if currentConfig and currentConfig.LineStyle then
		local rodStyle = currentConfig.LineStyle
		LineStyle.Width = rodStyle.Width or 0.16
		LineStyle.Color = rodStyle.Color or Color3.fromRGB(0, 255, 255)
		LineStyle.Transparency = rodStyle.Transparency or 0.12
		LineStyle.LightEmission = rodStyle.LightEmission or 10
		LineStyle.LightInfluence = rodStyle.IsNeon and 0 or 1

	else
		-- Use default
		LineStyle = {
			Width = 0.16,
			Color = Color3.fromRGB(0, 255, 255),
			Transparency = 0.12,
			LightInfluence = 0,
			LightEmission = 10,
			FaceCamera = true
		}
	end
end




local player = game:GetService("Players").LocalPlayer
local fishingPanel = player.PlayerGui:WaitForChild("FishingPanel")
local pullFrame = fishingPanel:WaitForChild("PullFrame")
local fillBar = pullFrame:WaitForChild("Fillbar")

local timerBar = pullFrame:WaitForChild("TimerBar")
local timerSlider = timerBar:WaitForChild("TimerSlider")
local timerCounter = timerBar:WaitForChild("TimerCounter")

local tapTapLabel = pullFrame:WaitForChild("TapTapLabel")

-- ==================== THROW POWER UI ====================
local throwFrame = fishingPanel:WaitForChild("ThrowFrame")
local throwFillBar = throwFrame:WaitForChild("Fillbar")

-- Throw power state
local isCharging = false
local chargeStartTime = 0
local chargeConnection = nil
local CHARGE_DURATION = 2.0 -- 2 seconds to fully charge
local MIN_THROW_DISTANCE = 5 -- Minimum throw distance (studs)
local currentThrowPower = 0 -- 0 to 1

assert(fillBar, "ERROR: Fillbar not found! Periksa struktur dan penamaan GUI")
assert(throwFillBar, "ERROR: ThrowFrame Fillbar not found! Periksa struktur GUI")



local initialScale = 0.4
local maxScale = 1
local tapIncrease = 0.08  -- Original value
local decayRate = 0.3 -- per detik
local timeLimit = 7 -- detik
local progress = initialScale
local isPulling = false
local lastTapTime = tick()
local startTime = 0


-- ✅ DISABLED: Camera cinematic effects
local cameraShakeEnabled = false     -- DISABLED: No camera shake
local shakeMagnitude = 0          
local shakeSpeed = 0               
local isShaking = false           
local pullCam = false
local pullCamConn = nil


local TweenService = game:GetService("TweenService")

local function rotatePlayerToFloater()
	if not HRP or not currentFloater then return end
	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end  -- Safety: abort if no valid part
	local target = floaterPart.Position

	-- Hitung arah hadapan
	local lookVec = (target - HRP.Position) * Vector3.new(1, 0, 1)
	if lookVec.Magnitude < 0.1 then return end

	-- Buat CFrame baru dengan rotasi ke arah floater (Y axis only)
	local goalCFrame = CFrame.new(HRP.Position, HRP.Position + lookVec)

	local tween = TweenService:Create(
		HRP,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = goalCFrame}
	)
	tween:Play()
end

local pullCamConn = nil
local previousCameraCFrame = nil
local previousCameraSubject = nil
local previousMinZoom, previousMaxZoom = nil, nil

-- ✅ THROW CAMERA LOOK-AT SYSTEM (LOCKED POSITION, ROTATION ONLY)
local throwCamActive = false
local throwCamConn = nil
local throwCamTargetPos = nil
local throwCamSavedCFrame = nil  -- CFrame kamera LENGKAP sebelum throw (untuk restore)
local throwCamSavedPosition = nil  -- Posisi kamera yang di-lock saat throw

-- ✅ DISABLED: Throw camera look-at effect
function startThrowCameraLookAt(targetPos)
	-- Camera cinematic disabled - do nothing
	return
end

function stopThrowCameraLookAt()
	-- Camera cinematic disabled - do nothing
	return
end

-- ✅ DISABLED: Pull camera cinematic effect
function startPullCamera(offsetDistance, offsetSide)
	-- Camera cinematic disabled - do nothing
	return
end

function stopPullCamera()
	-- Camera cinematic disabled - do nothing
	return
end






function animateTapLabel()
	local minSize, maxSize = 18, 32
	local animSpeed = .05

	coroutine.wrap(function()
		while isPulling do
			-- Tween naik ke maxSize
			for t = 0, 1, 0.05 do
				if not isPulling then break end
				local val = minSize + (maxSize-minSize) * t
				tapTapLabel.TextSize = val
				task.wait(animSpeed*0.05)
			end
			-- Tween turun ke minSize
			for t = 0, 1, 0.05 do
				if not isPulling then break end
				local val = maxSize - (maxSize-minSize) * t
				tapTapLabel.TextSize = val
				task.wait(animSpeed*0.05)
			end
		end
		tapTapLabel.TextSize = minSize
	end)()
end

-- bouncy animation helper
local function bounceFill(newScale)
	fillBar:TweenSize(
		UDim2.new(newScale, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Elastic, -- bouncy effect
		0.24, true)
end

local RunService = game:GetService("RunService")
local shakeName = "CameraShake"

-- ✅ DISABLED: Camera shake effect
local function cameraShake(deltaTime)
	-- Camera shake disabled - do nothing
	return
end

local function startCameraShake()
	-- Camera shake disabled - do nothing
	return
end

local function stopCameraShake()
	-- Camera shake disabled - do nothing
	return
end



local function startTapPull()
	progress = initialScale
	bounceFill(progress)
	fillBar.Size = UDim2.new(progress, 0, 1, 0)

	timerBar.Visible = true
	timerSlider.Size = UDim2.new(1, 0, 1, 0) -- reset ke penuh di awal
	timerCounter.Text = string.format("%ds", math.ceil(timeLimit))

	isPulling = true
	startTime = tick()
	lastTapTime = tick()

	-- Mulai animasi TapTapLabel:
	animateTapLabel()
end


pullFrame.Visible = false

pullFrame.InputBegan:Connect(function(input)
	if not isPulling then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		progress = math.min(progress + tapIncrease, maxScale)
		bounceFill(progress)
		lastTapTime = tick()
	end
end)


-- Animation IDs (ubah sesuai animasi kamu)

local THROW_ANIM_ID = "rbxassetid://112076574647402"  -- Animasi lempar
local IDLE_ANIM_ID = "rbxassetid://102186236353192" 
local PULLING_ANIM_ID = "rbxassetid://81275162125646"  -- TAMBAH INI - Animasi pulling (loop)
local CATCH_ANIM_ID = "rbxassetid://81275162125646"  -- TAMBAH INI - Animasi catch (1x)

-- Line renderer variables (HANYA 1x DECLARE)
local middlePoints = {}
local beamSegments = {}
local numMiddlePoints = 30

-- ========================================
-- FORWARD DECLARATIONS
-- ========================================
local cleanupBaitLine
local createBaitLine
local startBobbing
local retrieveFloater
local startPulling

-- Forward declarations for retrieve button
local createRetrieveButtonUI
local showRetrieveButton
local hideRetrieveButton


-- ========================================
-- LINE PHYSICS (SIMPLIFIED - NO WIND)
-- ========================================
-- Wind effects removed - line uses basic sin wave from LineRenderer module


-- ========================================
-- HELPER FUNCTIONS (Using Optimized Modules)
-- ========================================

-- Water Detection: Check if floater is above water
local function isPositionInWater(position)
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
	
	-- Method 2: Check for Water parts (any part with "Water" in name)
	local rayOrigin = position + Vector3.new(0, 2, 0)
	local rayDirection = Vector3.new(0, -10, 0)
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {Character, currentFloater}
	
	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result and result.Instance then
		local partName = result.Instance.Name:lower()
		if partName:find("water") or partName:find("lake") or partName:find("river") or partName:find("sea") or partName:find("ocean") or partName:find("pond") then
			return true
		end
		
		-- Also check parent names
		local parent = result.Instance.Parent
		if parent then
			local parentName = parent.Name:lower()
			if parentName:find("water") or parentName:find("lake") or parentName:find("river") or parentName:find("sea") or parentName:find("ocean") or parentName:find("pond") then
				return true
			end
		end
	end
	
	-- Method 3: Check if position Y is below certain height AND above a water-like surface
	-- This helps detect custom water systems
	local checkBelow = workspace:Raycast(position, Vector3.new(0, -5, 0), rayParams)
	if checkBelow and checkBelow.Instance then
		-- Check if the hit part has CanCollide = false (common for water)
		if not checkBelow.Instance.CanCollide then
			local material = checkBelow.Instance.Material
			if material == Enum.Material.Glass or material == Enum.Material.ForceField or material == Enum.Material.Neon then
				return true
			end
		end
	end
	
	return false
end


local function findEdgePart(tool)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return nil end

	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("MeshPart") or child:IsA("Part") then
			local edge = child:FindFirstChild("Edge")
			if edge and edge:IsA("BasePart") then
				return edge
			end
		end
	end
	return nil
end

local function loadFishingAnimations()
	if not Character then return end

	local humanoid = Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Create and load throw animation (TIDAK LOOP)
	local throwAnim = Instance.new("Animation")
	throwAnim.AnimationId = THROW_ANIM_ID
	throwAnimation = animator:LoadAnimation(throwAnim)
	throwAnimation.Looped = false
	throwAnimation.Priority = Enum.AnimationPriority.Action

	-- Create and load idle animation (LOOP)
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = IDLE_ANIM_ID
	idleAnimation = animator:LoadAnimation(idleAnim)
	idleAnimation.Looped = true
	idleAnimation.Priority = Enum.AnimationPriority.Idle

	-- Create and load pulling animation (LOOP) - TAMBAH INI
	local pullingAnim = Instance.new("Animation")
	pullingAnim.AnimationId = PULLING_ANIM_ID
	pullingAnimation = animator:LoadAnimation(pullingAnim)
	pullingAnimation.Looped = true -- Loop terus saat pulling
	pullingAnimation.Priority = Enum.AnimationPriority.Action

	-- Create and load catch animation (TIDAK LOOP) - TAMBAH INI
	local catchAnim = Instance.new("Animation")
	catchAnim.AnimationId = CATCH_ANIM_ID
	catchAnimation = animator:LoadAnimation(catchAnim)
	catchAnimation.Looped = false -- Play 1x saja
	catchAnimation.Priority = Enum.AnimationPriority.Action
end



local function cleanupAnimations()
	if throwAnimation then
		throwAnimation:Stop()
	end
	if idleAnimation then
		idleAnimation:Stop()
	end
	if pullingAnimation then  -- TAMBAH INI
		pullingAnimation:Stop()
	end
	if catchAnimation then    -- TAMBAH INI
		catchAnimation:Stop()
	end
end




local function cleanupConnections()
	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end

	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end

	-- TAMBAH INI
	if pullConnection then
		pullConnection:Disconnect()
		pullConnection = nil
	end

	isPulling = false
end


local function cleanupFishingLine()
	for _, beam in ipairs(beamSegments) do
		if beam then 
			pcall(function() beam:Destroy() end)
		end
	end
	beamSegments = {}

	for _, point in ipairs(middlePoints) do
		if point then 
			pcall(function() point:Destroy() end)
		end
	end
	middlePoints = {}

	if beamAttachment0 then
		pcall(function() beamAttachment0:Destroy() end)
		beamAttachment0 = nil
	end
	if beamAttachment1 then
		pcall(function() beamAttachment1:Destroy() end)
		beamAttachment1 = nil
	end

	if fishingBeam then
		fishingBeam = nil
	end
end


cleanupBaitLine = function()
	if baitLineBeam then
		pcall(function() baitLineBeam:Destroy() end)
		baitLineBeam = nil
	end
	if baitLineAttachment0 then
		pcall(function() baitLineAttachment0:Destroy() end)
		baitLineAttachment0 = nil
	end
	if baitLineAttachment1 then
		pcall(function() baitLineAttachment1:Destroy() end)
		baitLineAttachment1 = nil
	end
	if baitLinePart then
		pcall(function() baitLinePart:Destroy() end)
		baitLinePart = nil
	end
end

local function cleanupFishing()


	-- ✅ Stop throw camera look-at if active
	stopThrowCameraLookAt()

	-- Disconnect semua connection
	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end
	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end
	if pullConnection then
		pullConnection:Disconnect()
		pullConnection = nil
	end
	isPulling = false

	-- Destroy fishing line (beam/attachments/middle points)
	for _, beam in ipairs(beamSegments) do
		if beam then pcall(function() beam:Destroy() end) end
	end
	beamSegments = {}
	for _, point in ipairs(middlePoints) do
		if point then pcall(function() point:Destroy() end) end
	end
	middlePoints = {}
	if beamAttachment0 then pcall(function() beamAttachment0:Destroy() end) beamAttachment0 = nil end
	if beamAttachment1 then pcall(function() beamAttachment1:Destroy() end) beamAttachment1 = nil end
	fishingBeam = nil

	-- Destroy bait line (beam/parts/attachments)
	if baitLineBeam then pcall(function() baitLineBeam:Destroy() end) baitLineBeam = nil end
	if baitLineAttachment0 then pcall(function() baitLineAttachment0:Destroy() end) baitLineAttachment0 = nil end
	if baitLineAttachment1 then pcall(function() baitLineAttachment1:Destroy() end) baitLineAttachment1 = nil end
	if baitLinePart then pcall(function() baitLinePart:Destroy() end) baitLinePart = nil end

	-- Destroy floater (bobber) utama
	if currentFloater then
		pcall(function() currentFloater:Destroy() end)
		currentFloater = nil
	end

	-- ##### Tambahan: Destroy semua FLoater orphan di workspace #####
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name == "Floater" then -- GANTI dengan nama model bobber kamu jika PERLU!
			if obj ~= currentFloater then
				pcall(function() obj:Destroy() end)
			end
		end
	end
	-- ##### Tambahan: Destroy Beam orphan di workspace (tanpa parent/parent workspace) #####
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Beam") and (not obj.Parent or obj.Parent == workspace) then
			pcall(function() obj:Destroy() end)
		end
	end


	-- ✅ Hide retrieve button on cleanup
	hideRetrieveButton()
	
	-- ✅ REPLICATION: Notify server that fishing stopped
	notifyReplication("NotifyStopFishing")
end



local function calculateParabolicPosition(startPos, targetPos, height, alpha)
	if LineRenderer and LineRenderer.CalculateParabolicPosition then
		return LineRenderer.CalculateParabolicPosition(startPos, targetPos, height, alpha)
	end
	-- Fallback basic calculation
	local x = startPos.X + (targetPos.X - startPos.X) * alpha
	local z = startPos.Z + (targetPos.Z - startPos.Z) * alpha
	local baseY = startPos.Y + (targetPos.Y - startPos.Y) * alpha
	return Vector3.new(x, baseY, z)
end




-- ========================================
-- FISHING LINE CREATION (Delegated to Module)
-- ========================================

-- Update bait line position helper
local function updateBaitLine()
	if not baitLinePart or not currentFloater then return end
	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end
	local floaterPos = floaterPart.Position
	baitLinePart.Position = floaterPos - Vector3.new(0, BAIT_LINE_LENGTH, 0)
end

-- Create fishing line using optimized module
local function createFishingLine()
	cleanupFishingLine()
	
	if not edgePart or not currentFloater then return end
	
	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end
	
	-- Use module to create complete fishing line with physics
	if LineRenderer and LineRenderer.CreateCompleteFishingLineWithPhysics then
		local lineData = LineRenderer.CreateCompleteFishingLineWithPhysics(
			edgePart, 
			floaterPart, 
			LineStyle, 
			numMiddlePoints, 
			Character, 
			currentFloater
		)
		
		if lineData then
			-- Store returned data to local variables for cleanup
			beamAttachment0 = lineData.attachment0
			beamAttachment1 = lineData.attachment1
			middlePoints = lineData.middlePoints
			beamSegments = lineData.beamSegments
			beamUpdateConnection = lineData.physicsConnection
			fishingBeam = lineData.fishingBeam
		end
	end
end


-- ========================================
-- FISHING ACTIONS
-- ========================================


-- ========================================
-- RETRIEVE BUTTON SYSTEM (Mobile-friendly)
-- ========================================

createRetrieveButtonUI = function()
	if retrieveButtonGui then return end
	
	local playerGui = Player:WaitForChild("PlayerGui")
	
	-- Create ScreenGui
	retrieveButtonGui = Instance.new("ScreenGui")
	retrieveButtonGui.Name = "RetrieveButtonGUI"
	retrieveButtonGui.ResetOnSpawn = false
	retrieveButtonGui.DisplayOrder = 50
	retrieveButtonGui.IgnoreGuiInset = true
	retrieveButtonGui.Parent = playerGui
	
	-- Container for button (center-bottom, not at edge)
	local container = Instance.new("Frame")
	container.Name = "ButtonContainer"
	container.Size = UDim2.new(0.25, 0, 0.08, 0) -- 25% width, 8% height (scale)
	container.Position = UDim2.new(0.5, 0, 0.82, 0) -- Center-X, 82% from top
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = retrieveButtonGui
	
	-- Size constraint for min/max
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(120, 45)
	sizeConstraint.MaxSize = Vector2.new(280, 75)
	sizeConstraint.Parent = container
	
	-- Main button
	retrieveButton = Instance.new("TextButton")
	retrieveButton.Name = "RetrieveButton"
	retrieveButton.Size = UDim2.new(1, 0, 1, 0)
	retrieveButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	retrieveButton.BorderSizePixel = 0
	retrieveButton.Text = "🎣 TARIK"
	retrieveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	retrieveButton.Font = Enum.Font.GothamBlack
	retrieveButton.TextScaled = true
	retrieveButton.AutoButtonColor = true
	retrieveButton.Parent = container
	
	-- Button corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = retrieveButton
	
	-- Button stroke (glow effect)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 150, 150)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = retrieveButton
	
	-- Gradient for premium look
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 80, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 60, 60))
	})
	gradient.Rotation = 90
	gradient.Parent = retrieveButton
	
	-- Text padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.1, 0)
	padding.PaddingRight = UDim.new(0.1, 0)
	padding.Parent = retrieveButton
	
	-- Initially hidden
	container.Visible = false
	
	-- Button click handler
	retrieveButton.MouseButton1Click:Connect(function()
		if currentFloater and not isPulling and not isRetrieving then
			print("🎣 [RETRIEVE BUTTON] Clicked - retrieving floater!")
			isFloating = false
			isFishing = false
			if bobConnection then
				bobConnection:Disconnect()
				bobConnection = nil
			end
			retrieveFloater()
		end
	end)
	
	print("✅ [FISHING] Retrieve button created")
end

showRetrieveButton = function()
	if not retrieveButtonGui then
		createRetrieveButtonUI()
	end
	
	local container = retrieveButtonGui and retrieveButtonGui:FindFirstChild("ButtonContainer")
	if container then
		container.Visible = true
		
		-- Pop-in animation
		container.Size = UDim2.new(0, 0, 0, 0)
		container:TweenSize(
			UDim2.new(0.25, 0, 0.08, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Back,
			0.3, true
		)
	end
end

hideRetrieveButton = function()
	local container = retrieveButtonGui and retrieveButtonGui:FindFirstChild("ButtonContainer")
	if container and container.Visible then
		-- Pop-out animation
		container:TweenSize(
			UDim2.new(0, 0, 0, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.2, true
		)
		task.delay(0.2, function()
			if container then
				container.Visible = false
				-- Reset size for next show
				container.Size = UDim2.new(0.25, 0, 0.08, 0)
			end
		end)
	end
end

-- Create button on load (delay to ensure all functions are defined)
task.delay(3, createRetrieveButtonUI)

-- Create bait line using optimized module
createBaitLine = function()
	cleanupBaitLine()
	
	if not currentFloater then return end
	
	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end
	
	-- Use module to create bait line
	if LineRenderer and LineRenderer.CreateBaitLine then
		local baitData = LineRenderer.CreateBaitLine(floaterPart, LineStyle, BAIT_LINE_LENGTH)
		
		if baitData then
			baitLineAttachment0 = baitData.attachment0
			baitLineAttachment1 = baitData.attachment1
			baitLinePart = baitData.endPart
			baitLineBeam = baitData.beam
		end
	end
end


retrieveFloater = function()
	isRetrieving = true  -- START LOCK
	
	-- ✅ Hide retrieve button immediately
	hideRetrieveButton()

	if not currentFloater or not edgePart then
		cleanupFishing()
		isRetrieving = false    -- RELEASE LOCK (penting)
		isFishing = false
		isPulling = false
		isThrowing = false
		isFloating = false
		isRecovering = true
		task.delay(3, function()
			isRecovering = false
			print("⏳ Jeda recovery selesai, boleh lempar lagi.")
		end)
		return
	end

	-- Matikan baitline dulu
	cleanupBaitLine()

	if idleAnimation and idleAnimation.IsPlaying then
		idleAnimation:Stop()
	end
	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end
	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end

	print("↩️ Menarik kembali - tali tegang...")

	for _, beam in ipairs(beamSegments) do
		if beam then
			pcall(function() beam:Destroy() end)
		end
	end
	beamSegments = {}

	for _, point in ipairs(middlePoints) do
		if point then
			pcall(function() point:Destroy() end)
		end
	end
	middlePoints = {}

	if beamAttachment0 and beamAttachment1 then
		local straightBeam = Instance.new("Beam")
		straightBeam.Attachment0 = beamAttachment0
		straightBeam.Attachment1 = beamAttachment1
		straightBeam.Width0 = LineStyle.Width
		straightBeam.Width1 = LineStyle.Width
		straightBeam.Color = ColorSequence.new(LineStyle.Color)
		straightBeam.Transparency = NumberSequence.new(LineStyle.Transparency)
		straightBeam.FaceCamera = LineStyle.FaceCamera
		straightBeam.Segments = 1
		straightBeam.CurveSize0 = 0
		straightBeam.CurveSize1 = 0
		straightBeam.LightInfluence = LineStyle.LightInfluence
		straightBeam.LightEmission = LineStyle.LightEmission
		straightBeam.Parent = edgePart

		fishingBeam = straightBeam
	end

	local retrieveDuration = 0.3
	local elapsed = 0
	local startRetrievePos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position

	local retrieveConnection
	retrieveConnection = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local alpha = math.min(elapsed / retrieveDuration, 1)

		if not currentFloater or not edgePart then
			retrieveConnection:Disconnect()
			cleanupFishing()
			isRetrieving = false    -- RELEASE LOCK (penting)
			isFishing = false
			isPulling = false
			isThrowing = false
			isFloating = false
			isRecovering = true
			task.delay(Cooldown, function()
				isRecovering = false
				print("⏳ Jeda recovery selesai, boleh lempar lagi.")
			end)
			return
		end

		local targetPos = edgePart.Position
		local newPos = startRetrievePos:Lerp(targetPos, alpha)

		if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
			currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
		else
			currentFloater.CFrame = CFrame.new(newPos)
		end

		if alpha >= 1 then
			retrieveConnection:Disconnect()
			cleanupFishing()
			isRetrieving = false    -- RELEASE LOCK (penting)
			isFishing = false
			isPulling = false
			isThrowing = false
			isFloating = false
			isRecovering = true
			task.delay(Cooldown, function()
				isRecovering = false
				print("⏳ Jeda recovery selesai, boleh lempar lagi.")
			end)
		end
	end)
end


startPulling = function()
	-- Performance throttle check
	if _getSM() < 0.5 then return end
	
	if isPulling or not currentFloater then
		return
	end
	
	-- ✅ SAFETY: Validate floater before starting
	local floaterPart = nil
	if currentFloater:IsA("Model") then
		floaterPart = currentFloater.PrimaryPart
		if not floaterPart then
			warn("⚠️ [FISHING] Floater Model has no PrimaryPart, aborting pull")
			cleanupFishing()
			return
		end
	else
		floaterPart = currentFloater
	end
	
	if not floaterPart or not floaterPart.Parent then
		warn("⚠️ [FISHING] Invalid floater, aborting pull")
		cleanupFishing()
		return
	end
	
	isPulling = true
	rotatePlayerToFloater()
	startTime = tick()
	print("🎣 STRIKE! Ikan melawan!")
	
	-- ✅ AUTO CLOSE ALL UIs WHEN TAPTAP STARTS (keep screen clean)
	if _G.closeAllUIsOnFishCaught then
		_G.closeAllUIsOnFishCaught()
	end
	
	-- ✅ FIX: Freeze player movement during pulling/taptap
	if Humanoid then
		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
		print("🚫 [FISHING] Player movement frozen during pulling")
	end
	
	if cameraShakeEnabled then
		startCameraShake()
	end
	startPullCamera(7, 10)
	-- Cleanup baitline saat pull
	cleanupBaitLine()
	
	-- ✅ Hide retrieve button during pulling (tap-tap takes over)
	hideRetrieveButton()

	-- Stop bobbing
	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end

	-- STOP IDLE & PLAY PULLING ANIMATION
	if idleAnimation and idleAnimation.IsPlaying then
		idleAnimation:Stop()
	end

	if pullingAnimation then
		pullingAnimation:Play()
		print("🎣 Playing pulling animation (loop)")
	end

	-- ✅ REPLICATION: Notify server that pulling started
	notifyReplication("NotifyStartPulling")
	
	-- ✅ Play fish bite sound at floater position (3D) - SAFE ACCESS
	local floaterPos = floaterPart.Position
	pcall(function()
		SoundConfig.PlaySoundAtPosition("FishBite", floaterPos)
	end)
	
	-- ✅ Start looping pulling sound (will stop when pulling ends)
	if currentPullingSound then
		SoundConfig.StopSound(currentPullingSound)
	end
	currentPullingSound = SoundConfig.PlayLocalSound("Pulling")

	-- Tampilkan UI PullFrame dan jalankan tapTap pulling
	pullFrame.Visible = true
	startTapPull()

	local inputConn
	inputConn = UserInputService.InputBegan:Connect(function(input, processed)
		if not isPulling or processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			progress = math.min(progress + tapIncrease, maxScale)
			bounceFill(progress)
			lastTapTime = tick()
		end
	end)

	local pullStartPos = floaterPart.Position  -- Already validated above
	local pullStartTime = tick()
	local pullDuration = 10
	local maxRandomDistance = 15
	local moveSpeed = 10

	local verticalPullSpeed = 10
	local maxPullDepth = 3
	local bobTime = 0

	local currentPullIntensity = math.random(0, 100) / 100
	local pullIntensityChangeTime = tick()
	local pullIntensityChangeDuration = 0.5

	local isPaused = false
	local pauseStartTime = 0
	local currentPauseDuration = 0
	local pauseChance = 0.5

	local tensionTransitionTime = 0.2
	local tensionStartTime = tick()
	local currentTensionLevel = 1
	local targetTensionLevel = 0
	local tensionChangeInterval = 0.5
	local lastTensionChangeTime = tick()

	local currentTarget = Vector3.new(
		pullStartPos.X + math.random(-maxRandomDistance, maxRandomDistance),
		pullStartPos.Y,
		pullStartPos.Z + math.random(-maxRandomDistance, maxRandomDistance)
	)

	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
	end

	-- Simplified pulling line physics - straight line with tension
	beamUpdateConnection = RunService.Heartbeat:Connect(function(dt)
		if not edgePart or not currentFloater or not isPulling then return end
		if #middlePoints == 0 then return end
		if not beamAttachment0 or not beamAttachment1 then return end

		local startPos = beamAttachment0.WorldPosition
		local endPos = beamAttachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude

		-- High tension during pulling = nearly straight line
		local baseSag = math.clamp(totalDist * 0.1, 0.5, 3)
		local currentSag = baseSag * (1 - currentTensionLevel * 0.9)  -- Almost straight

		for i, point in ipairs(middlePoints) do
			if point and point.Parent then
				local alpha = i / (numMiddlePoints + 1)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = currentSag * parabolaFactor

				-- No wind/wave during pulling - straight line
				local calculatedPos = Vector3.new(midX, baseY - yOffset, midZ)
				point.Position = calculatedPos
			end
		end
	end)

	pullConnection = RunService.Heartbeat:Connect(function(dt)
		if not currentFloater then
			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end
			isPulling = false
			isFishing = false
			-- ✅ FAILSAFE: Stop animation and restore movement when floater disappears
			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end
			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
			end
			pullFrame.Visible = false
			timerBar.Visible = false
			cleanupFishing()
			print("⚠️ [FISHING] Floater disappeared during pull, cleaned up")
			return
		end

		bobTime = bobTime + dt
		local elapsedTime = tick() - pullStartTime

		-- Tap-tap decay progress
		local elapsed = tick() - startTime
		local timeSinceTap = tick() - lastTapTime
		if timeSinceTap > 0.05 then
			progress = math.max(progress - decayRate * dt, 0)
			bounceFill(progress)
		end

		-- === BEGIN: UI Countdown TimerBar ===
		local timeLeft = math.max(0, timeLimit - elapsed)
		timerSlider:TweenSize(
			UDim2.new(timeLeft / timeLimit, 0, 1, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Linear,
			0.18, true
		)
		timerCounter.Text = string.format("%ds", math.ceil(timeLeft))
		-- === END: UI Countdown TimerBar ===

		if progress <= 0 or elapsed > timeLimit then
			print("gagal mendapatkan ikan")

			-- FIRE TO SERVER (RemoteEvent) with floater position
			local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
			if FishingSuccessEvent then
				local floaterPos = nil
				if currentFloater then
					local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
					if floaterPart then
						floaterPos = floaterPart.Position
					end
				end
				print("📡 [DEBUG CLIENT] Firing FishingSuccessEvent to server (FAIL)")
				FishingSuccessEvent:FireServer(false, floaterPos) -- Include floater position
			else
				warn("⚠️ FishingSuccessEvent not found!")
			end

			-- Stop animasi pulling
			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end

			stopCameraShake()
			stopPullCamera()
			
			-- ✅ Stop pulling sound when pulling ends
			if currentPullingSound then
				SoundConfig.StopSound(currentPullingSound)
				currentPullingSound = nil
			end

			isPulling = false
			isFishing = false
			
			-- ✅ Restore player movement after pulling ends (FAIL)
			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
				print("✅ [FISHING] Player movement restored (pull failed)")
			end

			if inputConn then
				inputConn:Disconnect()
				inputConn = nil
			end

			pullFrame.Visible = false
			timerBar.Visible = false

			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end

			retrieveFloater()
			return
		end


		if progress >= maxScale then
			print("berhasil mendapatkan ikan")

			-- (UIs sudah di-close saat pulling start)

			-- FIRE TO SERVER (RemoteEvent) with floater position
			local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
			if FishingSuccessEvent then
				local floaterPos = nil
				if currentFloater then
					local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
					if floaterPart then
						floaterPos = floaterPart.Position
					end
				end
				print("📡 [DEBUG CLIENT] Firing FishingSuccessEvent to server (SUCCESS) at position:", floaterPos)
				FishingSuccessEvent:FireServer(true, floaterPos) -- Include floater position
			else
				warn("⚠️ FishingSuccessEvent not found!")
			end

			-- Stop animasi pulling
			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end

			stopCameraShake()
			stopPullCamera()
			
			-- ✅ Stop pulling sound and play fish caught sound
			if currentPullingSound then
				SoundConfig.StopSound(currentPullingSound)
				currentPullingSound = nil
			end
			SoundConfig.PlayLocalSound("FishCaught")

			isPulling = false
			isFishing = false
			
			-- ✅ Restore player movement after pulling ends (SUCCESS)
			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
				print("✅ [FISHING] Player movement restored (pull success)")
			end

			if inputConn then
				inputConn:Disconnect()
				inputConn = nil
			end

			pullFrame.Visible = false

			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end

			retrieveFloater()
			return
		end


		-- Smooth transition tegangan tali
		if elapsedTime < tensionTransitionTime then
			local transitionAlpha = elapsedTime / tensionTransitionTime
			currentTensionLevel = transitionAlpha * 0.7
		else
			if tick() - lastTensionChangeTime >= tensionChangeInterval then
				targetTensionLevel = math.random(70, 100) / 100
				lastTensionChangeTime = tick()
			end
			currentTensionLevel = currentTensionLevel + (targetTensionLevel - currentTensionLevel) * dt * 3
		end

		-- Update intensitas tarik secara acak
		if tick() - pullIntensityChangeTime >= pullIntensityChangeDuration then
			currentPullIntensity = math.random(60, 100) / 100
			pullIntensityChangeTime = tick()
		end

		local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
		-- ✅ SAFETY: Check if floaterPart is valid
		if not floaterPart or not floaterPart.Parent then
			warn("⚠️ [FISHING] FloaterPart became invalid during pull, cleaning up")
			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end
			isPulling = false
			isFishing = false
			cleanupFishing()
			-- Restore movement
			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
			end
			pullFrame.Visible = false
			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end
			return
		end
		local currentPos = floaterPart.Position

		-- Cek jarak horizontal ke player, auto retrieve kalau terlalu jauh
		if Character and Character.PrimaryPart and edgePart then
			local playerPos = Character.PrimaryPart.Position
			local floaterPos = currentPos

			local horizontalDistance = (Vector3.new(playerPos.X, 0, playerPos.Z) - Vector3.new(floaterPos.X, 0, floaterPos.Z)).Magnitude
			local maxAllowedDistance = currentConfig.MaxThrowDistance * 1.3

			if horizontalDistance > maxAllowedDistance then
				warn("⚠️ Line snapped during pull! Distance:", math.floor(horizontalDistance))

				if pullConnection then
					pullConnection:Disconnect()
					pullConnection = nil
				end

				isPulling = false
				isFishing = false
				retrieveFloater()
				return
			end
		end

		-- Gerakan vertikal naik turun (tarikan)
		local pullWave = math.abs(math.sin(bobTime * verticalPullSpeed)) * maxPullDepth * currentPullIntensity
		local verticalOffset = -pullWave
		local targetY = math.min(pullStartPos.Y + verticalOffset, pullStartPos.Y)

		-- Logika pause gerak ikan
		if isPaused then
			if tick() - pauseStartTime >= currentPauseDuration then
				isPaused = false
				currentTarget = Vector3.new(
					pullStartPos.X + math.random(-maxRandomDistance, maxRandomDistance),
					pullStartPos.Y,
					pullStartPos.Z + math.random(-maxRandomDistance, maxRandomDistance)
				)
				print("🐟 Fish moving again!")
			else
				local pausePos = Vector3.new(currentPos.X, targetY, currentPos.Z)

				if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
					currentFloater:SetPrimaryPartCFrame(CFrame.new(pausePos))
				else
					currentFloater.CFrame = CFrame.new(pausePos)
				end
			end
		else
			local horizontalCurrentPos = Vector3.new(currentPos.X, 0, currentPos.Z)
			local horizontalTarget = Vector3.new(currentTarget.X, 0, currentTarget.Z)
			local distance = (horizontalTarget - horizontalCurrentPos).Magnitude

			if distance < 1 then
				if math.random() < pauseChance then
					isPaused = true
					pauseStartTime = tick()
					currentPauseDuration = math.random(30, 120) / 100
					print("🐟 Fish paused for", currentPauseDuration, "seconds")
				else
					currentTarget = Vector3.new(
						pullStartPos.X + math.random(-maxRandomDistance, maxRandomDistance),
						pullStartPos.Y,
						pullStartPos.Z + math.random(-maxRandomDistance, maxRandomDistance)
					)
					print("🐟 Fish keeps moving!")
				end
			else
				local direction = (currentTarget - currentPos).Unit
				local moveAmount = direction * moveSpeed * dt
				local newPos = currentPos + Vector3.new(moveAmount.X, 0, moveAmount.Z)
				newPos = Vector3.new(newPos.X, targetY, newPos.Z)

				if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
					currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
				else
					currentFloater.CFrame = CFrame.new(newPos)
				end
			end
		end

		-- Cek durasi tarik, stop dan proses hasil
		if elapsedTime >= pullDuration then
			print("🎣 PULL DURATION REACHED - Starting cleanup sequence")

			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end

			-- Jangan disconnect beamUpdateConnection dulu supaya animasi tali tetap update

			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end

			if catchAnimation then
				-- Jangan play animasi catch, cukup stop pulling animasi.
				-- Jika ingin diputar, bisa ditambahkan manual di sini.
			end

			if beamUpdateConnection then
				beamUpdateConnection:Disconnect()
				beamUpdateConnection = nil
			end

			isPulling = false
			isFishing = false

			pullFrame.Visible = false

			retrieveFloater()

			print("🎣 Cleanup sequence complete")
		end
	end)
end




startBobbing = function()
	-- Optimization: skip if resources not ready
	if _getSM() < 0.5 then return end
	if not currentFloater then return end

	-- ✅ SAFETY: Get floater part with nil check
	local floaterPart = nil
	if currentFloater:IsA("Model") then
		floaterPart = currentFloater.PrimaryPart
		if not floaterPart then
			warn("⚠️ [FISHING] Floater Model has no PrimaryPart in bobbing")
			return
		end
	else
		floaterPart = currentFloater
	end
	local basePos = floaterPart.Position
	local bobTime = 0
	local distanceWarned = false -- Flag untuk warning
	
	-- ✅ NEW: Check if floater is in water
	local floaterInWater = isPositionInWater(basePos)
	isFloating = floaterInWater -- Only set floating if actually in water
	
	if not floaterInWater then
		print("⚠️ [FISHING] Floater tidak di atas air! Tidak ada ikan yang bisa ditangkap.")
	else
		print("🌊 [FISHING] Floater di atas air - fishing dimulai!")
	end

	-- Timer auto-pull random (only if in water)
	local pullAutoTimer = math.random(5, 10)
	local pullTimerElapsed = 0
	local pullingStarted = false

	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end

	bobConnection = RunService.Heartbeat:Connect(function(dt)
		if not currentFloater then
			if bobConnection then
				bobConnection:Disconnect()
				bobConnection = nil
			end
			isFloating = false
			return
		end
		
		-- Get current floater position (with safety check)
		local floaterPartBob = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
		if not floaterPartBob or not floaterPartBob.Parent then
			if bobConnection then
				bobConnection:Disconnect()
				bobConnection = nil
			end
			isFloating = false
			return
		end
		local currentPos = floaterPartBob.Position
		
		-- ✅ FIX #5: DISTANCE CHECK FIRST (before water check)
		-- This ensures auto-retrieve works even when floater is not in water
		if Character and Character.PrimaryPart and edgePart then
			local playerPos = Character.PrimaryPart.Position
			local floaterPos = currentPos

			local horizontalDistance = (Vector3.new(playerPos.X, 0, playerPos.Z) - Vector3.new(floaterPos.X, 0, floaterPos.Z)).Magnitude
			local maxAllowedDistance = currentConfig.MaxThrowDistance * 1.3

			-- AUTO RETRIEVE if too far (regardless of water status)
			if horizontalDistance > maxAllowedDistance then
				if not isPulling then
					print("🎣 Too far! Auto-retrieving... Distance:", math.floor(horizontalDistance))

					if bobConnection then
						bobConnection:Disconnect()
						bobConnection = nil
					end

					isFloating = false
					if isFishing then
						isFishing = false
						retrieveFloater()
					end
					return
				end
			end
		end
		
		-- ✅ Recheck water status periodically
		floaterInWater = isPositionInWater(currentPos)
		
		-- ✅ Only do bobbing and fish detection if in water
		if not floaterInWater then
			-- Floater not in water - just stay still, no fish, but keep distance check running
			isFloating = false
			return
		end
		
		isFloating = true -- In water, can catch fish

		-- Auto Pull Timer aktif selama floating (only if in water)
		if not isPulling and isFloating and not pullingStarted then
			pullTimerElapsed = pullTimerElapsed + dt
			if pullTimerElapsed >= pullAutoTimer then
				pullingStarted = true
				isFloating = false
				print("⏰ Auto pulling dimulai (random timer)")
				startPulling() -- Mulai pulling otomatis
				return
			end
		end

		bobTime = bobTime + dt
		local bobOffset = math.sin(bobTime * (math.pi / currentConfig.BobSpeed)) * currentConfig.BobHeight
		local newPos = basePos + Vector3.new(0, bobOffset, 0)

		if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
			currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
		else
			currentFloater.CFrame = CFrame.new(newPos)
		end

		updateBaitLine()
	end)
end


local isThrowing = false

local function throwFloater(throwPower)
	-- Frame rate limiter check
	if _getSM() < 0.5 then return end
	
	-- Default throwPower to 1 (max distance) for backwards compatibility
	throwPower = throwPower or 1
	
	-- ✅ FIX #4: Check if character exists (may not exist right after respawn)
	if not Character or not Character.Parent then
		return
	end
	
	if not HRP or not HRP.Parent then
		HRP = Character:FindFirstChild("HumanoidRootPart")
		if not HRP then
			return
		end
	end
	
	-- ✅ FIXED: Reset stuck states first (no floater = reset states)
	if not currentFloater then
		if isFloating then
			isFloating = false
		end
		if isFishing then
			isFishing = false
		end
	end
	
	if isThrowing or isPulling then
		warn("Sedang proses lempar/pulling, abaikan double call")
		return
	end
	
	-- If there's already a floater, retrieve it first
	if currentFloater then
		warn("Ada floater aktif, retrieve dulu sebelum throw baru")
		return
	end
	
	isThrowing = true

	if not currentConfig or not currentConfig.ThrowHeight then
		warn("Config/ThrowHeight alat pancing belum lengkap!")
		isThrowing = false
		return
	end

	cleanupFishing()
	isFishing = true

	if not edgePart or not currentConfig then 
		warn("Edge part atau config tidak ditemukan!")
		isFishing = false
		isThrowing = false
		return 
	end

	Character = Player.Character
	if not Character or not Character.PrimaryPart then 
		warn("Character tidak tersedia!")
		isFishing = false
		isThrowing = false
		return 
	end

	-- Play animation
	if idleAnimation and idleAnimation.IsPlaying then
		idleAnimation:Stop()
	end

	-- ✅ Play throw sound IMMEDIATELY (before animation wait)
	SoundConfig.PlayLocalSound("Throw")

	if throwAnimation then
		throwAnimation:Play()
		local animLength = throwAnimation.Length or 1.0
		local throwTiming = animLength * 0.4
		task.wait(throwTiming)
	else
		task.wait(0.3)
	end

	-- ✅ CALCULATE THROW DISTANCE BASED ON POWER
	-- throwPower: 0 = MIN_THROW_DISTANCE, 1 = MaxThrowDistance
	local maxDist = currentConfig.MaxThrowDistance
	local minDist = MIN_THROW_DISTANCE
	local throwDistance = minDist + (throwPower * (maxDist - minDist))
	
	print("🎣 [THROW] Power:", string.format("%.0f%%", throwPower * 100), "| Distance:", string.format("%.1f", throwDistance), "studs")

	-- CALCULATE TARGET POSITION (using calculated throwDistance)
	local startPos = edgePart.Position
	local lookDirection = Character.PrimaryPart.CFrame.LookVector
	local horizontalTarget = startPos + (lookDirection * throwDistance)

	-- ✅ IMPROVED RAYCAST: Start from player's Y level, not 200 studs above
	-- This prevents hitting ceilings when fishing indoors
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {Character, currentFloater}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	-- Start raycast from slightly above player's current Y position
	local playerY = Character.PrimaryPart.Position.Y
	local rayStartY = playerY + 5 -- Start 5 studs above player
	local rayOrigin = Vector3.new(horizontalTarget.X, rayStartY, horizontalTarget.Z)
	local rayDirection = Vector3.new(0, -100, 0) -- Raycast down 100 studs
	
	local targetPos = nil
	local maxAttempts = 10
	local currentOrigin = rayOrigin
	
	-- Helper function to check if a hit is a valid water surface
	local function isWaterSurface(hitInstance)
		if not hitInstance then return false end
		
		-- Check if it's terrain water (terrain itself)
		if hitInstance:IsA("Terrain") then
			return true
		end
		
		-- Check part name for water keywords
		local partName = hitInstance.Name:lower()
		local waterKeywords = {"water", "lake", "river", "sea", "ocean", "pond", "pool", "laut", "sungai", "danau", "kolam"}
		for _, keyword in ipairs(waterKeywords) do
			if partName:find(keyword) then
				return true
			end
		end
		
		-- Check parent name for water keywords
		if hitInstance.Parent then
			local parentName = hitInstance.Parent.Name:lower()
			for _, keyword in ipairs(waterKeywords) do
				if parentName:find(keyword) then
					return true
				end
			end
		end
		
		-- Check if it's a non-collidable transparent part (common water setup)
		if hitInstance:IsA("BasePart") and not hitInstance.CanCollide and hitInstance.Transparency > 0.3 then
			return true
		end
		
		return false
	end
	
	-- Keep raycasting through non-water surfaces until we find water or ground
	for attempt = 1, maxAttempts do
		local rayResult = workspace:Raycast(currentOrigin, rayDirection, rayParams)
		
		if not rayResult then
			-- No hit, use fallback position
			break
		end
		
		local hitInstance = rayResult.Instance
		
		-- Check if this is a valid water surface
		if isWaterSurface(hitInstance) then
			print("✅ [THROW] Found water surface:", hitInstance.Name, "at Y:", rayResult.Position.Y)
			targetPos = Vector3.new(horizontalTarget.X, rayResult.Position.Y + 0.5, horizontalTarget.Z)
			break
		end
		
		-- Check if it's a floor/ground (CanCollide = true, not transparent)
		if hitInstance:IsA("BasePart") and hitInstance.CanCollide and hitInstance.Transparency < 0.3 then
			-- This is likely a solid floor, check if there's water below it
			-- If the part is horizontal (floor-like) and below player, accept it
			local partY = rayResult.Position.Y
			if partY < playerY - 2 then
				print("✅ [THROW] Found ground surface:", hitInstance.Name, "at Y:", rayResult.Position.Y)
				targetPos = Vector3.new(horizontalTarget.X, rayResult.Position.Y + 0.5, horizontalTarget.Z)
				break
			else
				-- It's a ceiling or obstacle above us, skip it
				print("⏭️ [THROW] Skipping ceiling/obstacle:", hitInstance.Name, "at Y:", partY)
				-- Continue raycast from below this obstacle
				currentOrigin = rayResult.Position + Vector3.new(0, -0.5, 0)
			end
		else
			-- Unknown part type, continue raycast
			currentOrigin = rayResult.Position + Vector3.new(0, -0.5, 0)
		end
	end
	
	-- Fallback: use player's Y level if no valid surface found
	if not targetPos then
		warn("⚠️ No valid water/ground surface found! Using fallback position.")
		targetPos = Vector3.new(horizontalTarget.X, playerY - 2, horizontalTarget.Z)
	end
	
	print("🎯 [THROW] Final target position:", targetPos)

	-- CLONE FLOATER (Use equipped floater from player data, fallback to default floater)
	local defaultFloaterId = FloaterConfig.DefaultFloater -- "FloaterDoll"
	print("🎈 [FISHING DEBUG] equippedFloaterId:", equippedFloaterId or "nil")
	print("🎈 [FISHING DEBUG] defaultFloaterId:", defaultFloaterId)
	
	local floaterToUse = nil
	local floaterTemplate = nil
	
	-- First try to find by equipped floater ID (if player has equipped one)
	if equippedFloaterId and equippedFloaterId ~= "" then
		floaterTemplate = FloatersFolder:FindFirstChild(equippedFloaterId)
		if floaterTemplate then
			floaterToUse = equippedFloaterId
			print("🎈 [FISHING] Using EQUIPPED floater:", equippedFloaterId)
		else
			print("⚠️ [FISHING] Equipped floater not found in folder:", equippedFloaterId)
			-- List available floaters for debugging
			print("📁 [FISHING] Available floaters:")
			for _, child in ipairs(FloatersFolder:GetChildren()) do
				print("  -", child.Name)
			end
		end
	end
	
	-- Fallback to default floater from FloaterConfig
	if not floaterTemplate then
		floaterTemplate = FloatersFolder:FindFirstChild(defaultFloaterId)
		if floaterTemplate then
			floaterToUse = defaultFloaterId
			print("🎈 [FISHING] Using DEFAULT floater:", defaultFloaterId)
		else
			print("⚠️ [FISHING] Default floater not found:", defaultFloaterId)
		end
	end
	
	if not floaterTemplate then 
		warn("Floater tidak ditemukan! Equipped:", equippedFloaterId or "nil", "| Default:", defaultFloaterId)
		isFishing = false
		isThrowing = false
		return 
	end

	currentFloater = floaterTemplate:Clone()
	currentFloater.Parent = workspace

	if currentFloater:IsA("Model") then
		for _, part in ipairs(currentFloater:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
		currentFloater.PrimaryPart = currentFloater:FindFirstChildWhichIsA("BasePart")
		if currentFloater.PrimaryPart then
			currentFloater:SetPrimaryPartCFrame(CFrame.new(startPos))
		end
	else
		currentFloater.Anchored = true
		currentFloater.CanCollide = false
		currentFloater.CFrame = CFrame.new(startPos)
	end

	createFishingLine()
	
	-- ✅ REPLICATION: Notify server IMMEDIATELY when throw starts (before animation)
	notifyReplication("NotifyThrowFloater", startPos, targetPos, currentTool and currentTool.Name, floaterToUse, LineStyle, currentConfig.ThrowHeight)

	-- ✅ START CAMERA LOOK-AT EFFECT
	startThrowCameraLookAt(targetPos)

	-- ANIMASI THROW: lakukan force cleanup orphan bobber SETELAH semua transition selesai
	local throwDuration = 1.5
	local elapsed = 0

	local throwConnection
	throwConnection = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local alpha = math.min(elapsed / throwDuration, 1)

		local newPos = calculateParabolicPosition(startPos, targetPos, currentConfig.ThrowHeight, alpha)

		if currentFloater then
			if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
				currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
			else
				currentFloater.CFrame = CFrame.new(newPos)
			end
		end

		if alpha >= 1 then
			throwConnection:Disconnect()
			isThrowing = false -- biar click lain bisa diterima di sesi berikutnya
			isFloating = true -- bobbing dimulai (disable klik)
			
			-- ✅ Play water splash sound at floater position
			SoundConfig.PlaySoundAtPosition("WaterSplash", targetPos)
			
			-- ✅ STOP CAMERA LOOK-AT EFFECT (floater landed)
			stopThrowCameraLookAt()
			
			startBobbing()
			createBaitLine()
			
			-- ✅ Show retrieve button for manual fishing cancel
			showRetrieveButton()

			task.delay(0.2, function()
				if idleAnimation and isFishing then
					idleAnimation:Play()
				end
				-- Force cleanup orphan bobber, 1 frame setelah semua pasti selesai!!
				for _, obj in ipairs(workspace:GetChildren()) do
					if obj:IsA("Model") and obj.Name == "Floater" and obj ~= currentFloater then
						pcall(function() obj:Destroy() end)
					end
				end
			end)
		end
	end)
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

_G = _G or {}
_G.afkLoopTask = nil

local function startAfkLoop()
	if _G.afkLoopTask then return end -- jangan run double loop
	_G.afkLoopTask = task.spawn(function()
		print("[AFK] Loop started")
		while _G.afkMode do
			task.wait(0.1)

			-- ✅ NEW: Skip if any UI is open
			if isAnyUIOpen then
				task.wait(0.5)
				continue
			end
			
			-- ✅ NEW: Wait 5 seconds after new fish UI appears
			if isNewFishUIVisible then
				print("[AFK] Waiting for new fish UI to close...")
				task.wait(5) -- Wait 5 seconds
				
				-- Try to auto-close the new fish UI
				local playerGui = player.PlayerGui
				local fishRewardUI = playerGui:FindFirstChild("NewFishDiscovery")
					or playerGui:FindFirstChild("NewFishDiscoveryGUI") 
					or playerGui:FindFirstChild("FishRewardUI") 
					or playerGui:FindFirstChild("FishCaughtUI")
					or playerGui:FindFirstChild("SimpleFishNotif")
				
				if fishRewardUI then
					print("[AFK] Found fish UI:", fishRewardUI.Name, "- attempting to close...")
					
					-- The NewFishDiscovery UI has a fullscreen invisible TextButton as closeButton
					-- Find any TextButton with transparent background (the close button)
					for _, child in ipairs(fishRewardUI:GetChildren()) do
						if child:IsA("TextButton") and child.BackgroundTransparency >= 0.9 then
							print("[AFK] Found fullscreen close button, activating...")
							pcall(function() child:Activate() end)
							break
						end
					end
					
					-- If that didn't work, just destroy the UI
					task.wait(0.2)
					if fishRewardUI and fishRewardUI.Parent then
						print("[AFK] Force destroying fish UI...")
						pcall(function() fishRewardUI:Destroy() end)
					end
				end
				
				isNewFishUIVisible = false
				task.wait(0.5)
				continue
			end

			-- Pastikan player pegang tool rod
			local isRod = (currentTool and currentConfig and FishingRodConfig.Rods[currentTool.Name])
			if isRod then
				-- Cek lemparan otomatis jika idle
				if not isThrowing and not isFishing and not isFloating and not isPulling and not isRecovering and not isRetrieving then
					print("[AFK] Auto throw triggered")
					throwFloater()
				end

				-- Auto tap tap saat isPulling
				if isPulling then
					-- kode tap tap adaptif sesuai diskusi sebelumnya
					local elapsed = tick() - startTime
					local timeLeft = math.max(0, timeLimit - elapsed)
					local progressLeft = maxScale - progress

					local buffer = 2
					local baseTap = tapIncrease * (0.96 + 0.08 * math.random())
					local estTapCount = math.max(1, math.ceil(progressLeft / baseTap))
					local targetTime = math.max(0.2, timeLeft - buffer)
					local dt = targetTime / estTapCount
					dt = math.max(0.04, math.min(dt, 0.19))

					progress = math.min(progress + baseTap, maxScale)
					bounceFill(progress)
					lastTapTime = tick()
					task.wait(dt)
				end
			else
				print("[AFK] Not holding rod, idle.")
			end
		end
		print("[AFK] Loop stopped")
		_G.afkLoopTask = nil
	end)
end



local function stopAfkLoop()
	afkMode = false
	_G.afkMode = false
end

-- Expose functions globally
_G.startAfkLoop = startAfkLoop
_G.stopAfkLoop = stopAfkLoop

-- ✅ Toggle AFK function for button
local function toggleAfkMode()
	afkMode = not afkMode
	_G.afkMode = afkMode
	
	if afkMode then
		print("🤖 [AFK] AFK Mode ENABLED")
		startAfkLoop()
	else
		print("🤖 [AFK] AFK Mode DISABLED")
		stopAfkLoop()
	end
	
	return afkMode
end

_G.toggleAfkMode = toggleAfkMode

-- ✅ CREATE AFK BUTTON (USING HUD TEMPLATE)
local function createAfkButton()
	local playerGui = Player:WaitForChild("PlayerGui")
	
	-- ✅ Remove ANY old AFK GUIs (switch, button, etc)
	local existingGui = playerGui:FindFirstChild("AfkButtonGUI")
	if existingGui then existingGui:Destroy() end
	
	local oldSwitchGui = playerGui:FindFirstChild("AfkSwitchGUI")
	if oldSwitchGui then oldSwitchGui:Destroy() end
	
	-- Also check for any GUI with "Afk" in name
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and (gui.Name:lower():find("afk") or gui.Name:lower():find("switch")) then
			if gui.Name ~= "AfkButtonGUI" then
				gui:Destroy()
			end
		end
	end
	
	-- ✅ Use HUD template
	local hudGui = playerGui:WaitForChild("HUD", 10)
	local leftFrame = hudGui and hudGui:FindFirstChild("Left")
	local buttonTemplate = leftFrame and leftFrame:FindFirstChild("ButtonTemplate")
	
	local afkButton = nil
	local label = nil
	
	if buttonTemplate then
		-- ✅ Hide the original template
		buttonTemplate.Visible = false
		
		-- Clone the template
		local buttonContainer = buttonTemplate:Clone()
		buttonContainer.Name = "AfkButton"
		buttonContainer.Visible = true
		buttonContainer.LayoutOrder = 3 -- Third button on left
		buttonContainer.BackgroundTransparency = 1 -- ✅ Transparent container
		buttonContainer.Parent = leftFrame
		
		-- Get references
		afkButton = buttonContainer:FindFirstChild("ImageButton")
		label = buttonContainer:FindFirstChild("TextLabel")
		
		-- Set button properties
		if afkButton then
			afkButton.Image = "rbxassetid://98033273507939" -- AFK icon
			afkButton.BackgroundTransparency = 1 -- ✅ Transparent button
		end
		
		if label then
			label.Text = "AFK"
		end
		

	else
		-- Fallback: Create button manually if template not found
		warn("[FISHING] HUD template not found, creating AFK button manually")
		
		local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "AfkButtonGUI"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = playerGui
		
		afkButton = Instance.new("ImageButton")
		afkButton.Name = "AfkButton"
		afkButton.Size = UDim2.new(0.1, 0, 0.1, 0)
		afkButton.Position = UDim2.new(0.01, 0, 0.6, 0)
		afkButton.BackgroundTransparency = 1
		afkButton.BorderSizePixel = 0
		afkButton.Image = "rbxassetid://98033273507939"
		afkButton.ScaleType = Enum.ScaleType.Fit
		afkButton.Parent = screenGui
		
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = afkButton
		
		label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.3, 0)
		label.Position = UDim2.new(0, 0, 1, 2)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.Text = "AFK"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Parent = afkButton
	end
	
	local function updateButtonVisual()
		if afkButton then
			if afkMode then
				afkButton.ImageColor3 = Color3.fromRGB(0, 255, 100) -- Green tint
			else
				afkButton.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Normal
			end
		end
		if label then
			if afkMode then
				label.TextColor3 = Color3.fromRGB(0, 255, 100)
			else
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
	
	-- ✅ Support both mouse AND touch
	if afkButton then
		afkButton.MouseButton1Click:Connect(function()
			toggleAfkMode()
			updateButtonVisual()
		end)
	end
	

end

-- Create AFK button after setup
task.delay(2, createAfkButton)

-- ==================== THROW CHARGING FUNCTIONS ====================

local function updateThrowFillBar(power)
	-- Animate fillbar Y scale from 0 to 1 with easing
	local targetScale = math.clamp(power, 0, 1)
	throwFillBar:TweenSize(
		UDim2.new(1, 0, targetScale, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.05, true
	)
end

local function startCharging()
	-- Validation checks
	if isAnyUIOpen then return false end
	if isRecovering then return false end
	if isRetrieving then return false end
	if isThrowing or isPulling then return false end
	if not currentTool or not currentConfig then return false end
	
	-- If floater exists, this is a retrieve action, not charging
	if currentFloater then return false end
	
	-- Reset stuck states
	if isFloating and not currentFloater then isFloating = false end
	if isFishing and not currentFloater then isFishing = false end
	
	-- Start charging
	isCharging = true
	chargeStartTime = tick()
	currentThrowPower = 0
	
	-- Show throw frame and reset fillbar
	throwFrame.Visible = true
	throwFillBar.Size = UDim2.new(1, 0, 0, 0)
	
	-- Create charge update loop
	if chargeConnection then
		chargeConnection:Disconnect()
		chargeConnection = nil
	end
	
	chargeConnection = RunService.Heartbeat:Connect(function(dt)
		if not isCharging then
			if chargeConnection then
				chargeConnection:Disconnect()
				chargeConnection = nil
			end
			return
		end
		
		local elapsed = tick() - chargeStartTime
		local power = math.clamp(elapsed / CHARGE_DURATION, 0, 1)
		currentThrowPower = power
		
		-- Update UI with easing
		updateThrowFillBar(power)
		
		-- Once fully charged, keep at max (don't decrease)
		if power >= 1 then
			currentThrowPower = 1
		end
	end)
	
	print("⚡ [CHARGE] Started charging throw...")
	return true
end

local function stopCharging()
	if not isCharging then return end
	
	-- Capture final power before stopping
	local finalPower = currentThrowPower
	isCharging = false
	
	-- Disconnect charge connection
	if chargeConnection then
		chargeConnection:Disconnect()
		chargeConnection = nil
	end
	
	-- Hide throw frame with animation
	throwFillBar:TweenSize(
		UDim2.new(1, 0, 0, 0),
		Enum.EasingDirection.In,
		Enum.EasingStyle.Quad,
		0.15, true
	)
	task.delay(0.15, function()
		throwFrame.Visible = false
	end)
	
	print("⚡ [CHARGE] Released with power:", string.format("%.0f%%", finalPower * 100))
	
	-- Execute throw with calculated power
	if finalPower > 0 then
		throwFloater(finalPower)
	end
	
	-- Reset
	currentThrowPower = 0
end

local function cancelCharging()
	if not isCharging then return end
	
	isCharging = false
	currentThrowPower = 0
	
	-- Disconnect charge connection
	if chargeConnection then
		chargeConnection:Disconnect()
		chargeConnection = nil
	end
	
	-- Hide throw frame
	throwFillBar:TweenSize(
		UDim2.new(1, 0, 0, 0),
		Enum.EasingDirection.In,
		Enum.EasingStyle.Quad,
		0.1, true
	)
	task.delay(0.1, function()
		throwFrame.Visible = false
	end)
	
	print("❌ [CHARGE] Cancelled")
end

-- ==================== MOUSE/TOUCH INPUT ====================

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	
	-- Only respond to mouse click or touch
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	-- Block if any UI is open
	if isAnyUIOpen then
		warn("Klik diabaikan: UI sedang terbuka")
		return
	end
	
	if isRecovering then
		warn("Sedang masa jeda recovery. Lempar tidak boleh!")
		return
	end
	
	if isRetrieving then
		warn("Masih retrieve berlangsung, tidak boleh throw!")
		return
	end
	
	-- ✅ CHANGED: Left-click NO LONGER retrieves floater
	-- If floater exists, just ignore left-click (use TARIK button or right-click instead)
	if currentFloater then
		-- Do nothing - user must use TARIK button or right-click to retrieve
		return
	end
	
	-- Check if tool equipped
	if not currentTool or not currentConfig then return end
	
	-- Start charging for throw
	startCharging()
end

local function onInputEnded(input, gameProcessed)
	-- Only respond to mouse release or touch end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	-- Release charge and throw
	if isCharging then
		stopCharging()
	end
end

-- ==================== TOOL EVENTS ====================

local function onToolEquipped(tool)
	
	if afkMode == true then
		
		task.wait(2)
		startAfkLoop()
		
	end

	cleanupFishing()
	currentTool = tool
	currentConfig = FishingRodConfig.Rods[tool.Name]

	if not currentConfig then
		warn("Config tidak ditemukan untuk:", tool.Name)
		currentTool = nil
		return
	end

	edgePart = findEdgePart(tool)
	if not edgePart then
		warn("Edge part tidak ditemukan di:", tool.Name)
		currentTool = nil
		currentConfig = nil
		return
	end

	-- Update line style based on rod config
	updateLineStyle()
	
	-- Refresh equipped floater from server
	fetchEquippedFloater()

	-- Load dan play idle
	loadFishingAnimations()
	if idleAnimation then
		idleAnimation:Play()
	end

	-- ✅ REPLICATION: Notify server that we started fishing
	notifyReplication("NotifyStartFishing", tool.Name, equippedFloaterId)


end



local function onToolUnequipped()
	
	-- ✅ Cancel any charging in progress
	cancelCharging()
	
	-- ✅ FIX: Force cancel pulling immediately
	if isPulling then
		print("⚠️ [FISHING] Force canceling pulling state!")
		isPulling = false
		pullingStarted = false
		
		-- Hide pull UI
		if pullFrame then
			pullFrame.Visible = false
		end
		
		-- Stop pull camera and restore normal camera IMMEDIATELY
		stopPullCamera()
		
		-- Force restore camera to normal (in case tween fails)
		task.delay(0.1, function()
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = Character and Character:FindFirstChild("Humanoid") or nil
		end)
		
		-- Restore player movement
		if Humanoid then
			Humanoid.WalkSpeed = 16 -- Default walk speed
			Humanoid.JumpPower = 50 -- Default jump power
		end
		
		-- Stop animations
		if pullingAnimation and pullingAnimation.IsPlaying then
			pullingAnimation:Stop()
		end
	end
	
	if isFishing then
		retrieveFloater()
	end

	cleanupAnimations()

	currentTool = nil
	currentConfig = nil
	edgePart = nil
	isFishing = false
	isPulling = false
	isThrowing = false
	isFloating = false
	
	-- Restore movement (in case it was frozen)
	if Humanoid then
		Humanoid.WalkSpeed = 16
		Humanoid.JumpPower = 50
	end
end



local function setupCharacterMonitor()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	HRP = Character:WaitForChild("HumanoidRootPart")

	Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			if FishingRodConfig.Rods[child.Name] then
				onToolEquipped(child)
			end
		end
	end)

	Character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == currentTool then
			onToolUnequipped()
		end
	end)

	for _, child in ipairs(Character:GetChildren()) do
		if child:IsA("Tool") and FishingRodConfig.Rods[child.Name] then
			onToolEquipped(child)
			break
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	onInputBegan(input, gameProcessed)
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	onInputEnded(input, gameProcessed)
end)

-- ✅ FIX #4: Complete state reset on respawn/death
Player.CharacterAdded:Connect(function(newCharacter)
	print("🔄 [FISHING] Character respawned, resetting all state...")
	
	-- Cancel charging if in progress
	cancelCharging()
	
	-- Update character references
	Character = newCharacter
	HRP = newCharacter:WaitForChild("HumanoidRootPart", 5)
	Humanoid = newCharacter:WaitForChild("Humanoid", 5)
	
	-- Disconnect all connections safely
	if bobConnection then
		pcall(function() bobConnection:Disconnect() end)
		bobConnection = nil
	end
	if beamUpdateConnection then
		pcall(function() beamUpdateConnection:Disconnect() end)
		beamUpdateConnection = nil
	end
	if pullConnection then
		pcall(function() pullConnection:Disconnect() end)
		pullConnection = nil
	end
	if chargeConnection then
		pcall(function() chargeConnection:Disconnect() end)
		chargeConnection = nil
	end
	
	-- Cleanup all visuals
	cleanupFishing()
	cleanupAnimations()
	
	-- ✅ FIX: Force stop pull camera and restore normal camera on respawn
	stopPullCamera()
	task.delay(0.2, function()
		camera.CameraType = Enum.CameraType.Custom
		if newCharacter:FindFirstChild("Humanoid") then
			camera.CameraSubject = newCharacter.Humanoid
		end
	end)
	
	-- ✅ FIX: Hide pull UI if visible
	if pullFrame then
		pullFrame.Visible = false
	end
	
	-- Reset ALL state variables
	isFishing = false
	isThrowing = false
	isFloating = false
	isPulling = false
	pullingStarted = false
	distanceWarned = false
	floaterInWater = false
	
	currentTool = nil
	currentConfig = nil
	edgePart = nil
	currentFloater = nil
	
	-- Reset animation references
	throwAnimation = nil
	idleAnimation = nil
	pullingAnimation = nil
	catchAnimation = nil
	animator = nil
	
	-- Reset timer variables
	pullTimerElapsed = 0
	pullAutoTimer = 0
	
	-- Notify server that fishing stopped
	notifyReplication("NotifyStopFishing")
	
	-- ✅ FIX: Restore player movement on respawn (in case character died while pulling)
	task.delay(0.5, function()
		if Humanoid then
			Humanoid.WalkSpeed = 16
			Humanoid.JumpPower = 50
		end
	end)
	
	-- Re-setup character monitor
	setupCharacterMonitor()
	
	print("✅ [FISHING] State reset complete")
end)

setupCharacterMonitor()

-- ==================== UI TRACKING ====================
-- Track when any UI is opened to prevent throwing

local function checkAnyUIOpen()
	local playerGui = player.PlayerGui
	
	-- List of UI panels to check (GUI name -> Panel name)
	-- NOTE: Music Player is EXCLUDED - widget should not block fishing
	local uiChecks = {
		-- Fishing-related UIs
		{gui = "EquipmentGUI", panel = "MainPanel"},
		{gui = "FishCollectionGUI", panel = "MainPanel"},
		{gui = "FishermanShopGUI", panel = "ShopPanel"},
		{gui = "RodShopGUI", panel = "MainPanel"},
		-- Inventory UIs
		{gui = "InventoryGUI", panel = "MainPanel"},
		{gui = "InventoryGUI_V3", panel = "MainPanel"},
		{gui = "InventorySystemGUI", panel = "MainPanel"},
		-- Settings
		{gui = "SettingsGUI", panel = "MainPanel"},
		-- Shop UIs
		{gui = "RedeemGui", panel = "MainPanel"},
		{gui = "DonateGUI", panel = "MainPanel"},
		{gui = "DonateGui", panel = "MainPanel"},
		{gui = "Shop", panel = "MainPanel"},
		{gui = "ShopGUI", panel = "MainPanel"},
		-- NOTE: MusicPlayer EXCLUDED - music widget should NOT block fishing
	}
	
	for _, check in ipairs(uiChecks) do
		local ui = playerGui:FindFirstChild(check.gui)
		if ui then
			-- Only check the EXACT panel name, not fallbacks
			local panel = ui:FindFirstChild(check.panel)
			if panel and panel:IsA("GuiObject") and panel.Visible then
				-- Debug: uncomment to see which UI is blocking
				-- print("🚫 [UI CHECK] Blocking UI detected:", check.gui, "/", check.panel)
				return true
			end
		end
	end
	
	return false
end

-- Continuously check UI state
task.spawn(function()
	while true do
		isAnyUIOpen = checkAnyUIOpen()
		task.wait(0.2)
	end
end)

-- ==================== AUTO-CLOSE UI FUNCTION ====================
local function closeAllUIsOnFishCaught()
	print("🐟 [FISHING] Closing all UIs (fish caught/pulling success)...")
	
	local playerGui = player.PlayerGui
	local closedCount = 0
	
	-- List of all UIs to close (except Music Widget)
	-- Note: Some GUIs use different names (RedeemGui vs RedeemGUI)
	local uisToClose = {
		{gui = "EquipmentGUI", panel = "MainPanel"},
		{gui = "FishCollectionGUI", panel = "MainPanel"},
		{gui = "FishermanShopGUI", panel = "ShopPanel"},
		{gui = "RodShopGUI", panel = "MainPanel"},
		{gui = "InventoryGUI", panel = "MainPanel"},
		-- TopbarPlus UIs (need to disable ScreenGui.Enabled)
		{gui = "RedeemGui", panel = "MainPanel", disableGui = true},
		{gui = "DonateGUI", panel = "MainPanel", disableGui = true},
		{gui = "ShopGUI", panel = "MainPanel", disableGui = true},
		-- Music main panel (but NOT widget)
		{gui = "MusicPlayer", panel = "MainPanel"},
		{gui = "MusicPlayer", panel = "MyLibraryPanel"},
		{gui = "MusicPlayer", panel = "PlaylistPopupPanel"},
	}
	
	print("  📋 [DEBUG] Checking", #uisToClose, "UI configurations...")
	
	for _, uiInfo in ipairs(uisToClose) do
		local gui = playerGui:FindFirstChild(uiInfo.gui)
		if gui then
			local panel = gui:FindFirstChild(uiInfo.panel)
			if panel then
				if panel:IsA("GuiObject") then
					if panel.Visible then
						panel.Visible = false
						-- Also disable ScreenGui for TopbarPlus panels
						if uiInfo.disableGui and gui:IsA("ScreenGui") then
							gui.Enabled = false
						end
						closedCount = closedCount + 1
						print("  ✅ [CLOSED]", uiInfo.gui, "/", uiInfo.panel)
					else
						print("  ⚪ [ALREADY HIDDEN]", uiInfo.gui, "/", uiInfo.panel)
					end
				end
			else
				print("  ⚠️ [PANEL NOT FOUND]", uiInfo.gui, "/", uiInfo.panel)
			end
		end
	end
	
	-- ✅ TopbarPlus icons - try to deselect all active icons
	-- TopbarPlus stores icons in a global table
	local IconModule = ReplicatedStorage:FindFirstChild("Icon")
	if IconModule then
		local success, iconLib = pcall(function()
			return require(IconModule)
		end)
		
		if success and iconLib and iconLib.getIcons then
			local getIconsSuccess, icons = pcall(function()
				return iconLib.getIcons()
			end)
			
			if getIconsSuccess and icons then
				for _, icon in pairs(icons) do
					-- isSelected can be a property OR a method, handle both
					local isSelected = false
					pcall(function()
						if type(icon.isSelected) == "function" then
							isSelected = icon:isSelected()
						elseif type(icon.isSelected) == "boolean" then
							isSelected = icon.isSelected
						end
					end)
					
					if isSelected and icon.deselect then
						pcall(function()
							icon:deselect()
							closedCount = closedCount + 1
							print("  ✅ [DESELECTED] TopbarPlus icon")
						end)
					end
				end
			end
		end
	end
	

end

-- Expose globally so pulling success can call it
_G.closeAllUIsOnFishCaught = closeAllUIsOnFishCaught

-- ==================== FISH CAUGHT EVENT LISTENER ====================
-- Function to show global notification for Secret fish catches
local function showGlobalSecretNotification(message, fishName, playerName)
	local notifGui = Instance.new("ScreenGui")
	notifGui.Name = "GlobalSecretNotif"
	notifGui.ResetOnSpawn = false
	notifGui.DisplayOrder = 200
	notifGui.IgnoreGuiInset = true
	notifGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 500, 0, 80)
	frame.Position = UDim2.new(0.5, 0, 0, -100)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 0, 80) -- Deep purple for Secret
	frame.BorderSizePixel = 0
	frame.Parent = notifGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 100, 255) -- Bright purple glow
	stroke.Thickness = 3
	stroke.Transparency = 0.3
	stroke.Parent = frame
	
	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 0, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 20, 100))
	})
	gradient.Rotation = 0
	gradient.Parent = frame
	
	-- Animate gradient
	task.spawn(function()
		local rotation = 0
		while frame.Parent do
			rotation = (rotation + 2) % 360
			gradient.Rotation = rotation
			task.wait(0.05)
		end
	end)

	-- Star icon
	local starLabel = Instance.new("TextLabel")
	starLabel.Size = UDim2.new(0, 60, 1, 0)
	starLabel.Position = UDim2.new(0, 10, 0, 0)
	starLabel.BackgroundTransparency = 1
	starLabel.Text = "🌟"
	starLabel.TextSize = 40
	starLabel.Font = Enum.Font.GothamBold
	starLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	starLabel.Parent = frame

	-- Main text
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -80, 1, 0)
	textLabel.Position = UDim2.new(0, 70, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextSize = 20
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextWrapped = true
	textLabel.Parent = frame

	-- Slide in from top
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 20)})
	tweenIn:Play()

	task.wait(5)

	-- Slide out
	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 0, -100)})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	notifGui:Destroy()
end

local FishCaughtEvent = ReplicatedStorage:FindFirstChild("FishCaughtEvent")

if FishCaughtEvent then
	FishCaughtEvent.OnClientEvent:Connect(function(data)
		-- Check if this is a global notification for Secret fish
		if data and data.IsGlobalNotification then
			showGlobalSecretNotification(data.Message, data.FishName, data.PlayerName)
			return -- Don't process further for global notifications
		end
		
		-- Normal fish caught processing
		if data and data.IsNewDiscovery then
			isNewFishUIVisible = true
			lastNewFishTime = tick()
		end
		closeAllUIsOnFishCaught()
	end)
else
	
	task.spawn(function()
		local event = ReplicatedStorage:WaitForChild("FishCaughtEvent", 10)
		if event then
			event.OnClientEvent:Connect(function(data)
				-- Check if this is a global notification for Secret fish
				if data and data.IsGlobalNotification then
					showGlobalSecretNotification(data.Message, data.FishName, data.PlayerName)
					return
				end
				
				-- Normal fish caught processing
				if data and data.IsNewDiscovery then
					isNewFishUIVisible = true
					lastNewFishTime = tick()
				end
				closeAllUIsOnFishCaught()
			end)
		else
			warn("[FISHING] FishCaughtEvent not found after 10s!")
		end
	end)
end

print("🎣 Fishing System Handler Loaded!")

-- ================================================================================
--                     SECTION: CAMERA CINEMATIC (PHOTO MODE)
-- ================================================================================
--[[
    Allows players to take cinematic screenshots by hiding UI
    - Hide all UI elements
    - Press P or click Photo button to toggle
]]

-- Define playerGui for this section
local playerGui = Player.PlayerGui

local isCinematicMode = false
local hiddenGuis = {}
local originalCoreGuiState = {}

-- Create Cinematic GUI
local cinematicGui = Instance.new("ScreenGui")
cinematicGui.Name = "CameraCinematicGUI"
cinematicGui.ResetOnSpawn = false
cinematicGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
cinematicGui.DisplayOrder = 100
cinematicGui.Parent = playerGui

-- Try to use HUD template for Photo button
local hudGuiCinematic = playerGui:FindFirstChild("HUD")
local rightFrame = hudGuiCinematic and hudGuiCinematic:FindFirstChild("Right")
local cinematicButtonTemplate = rightFrame and rightFrame:FindFirstChild("ButtonTemplate")

local cinematicButton = nil
local cinematicButtonText = nil

if cinematicButtonTemplate then
	local buttonContainer = cinematicButtonTemplate:Clone()
	buttonContainer.Name = "PhotoButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 3
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = rightFrame
	
	cinematicButton = buttonContainer:FindFirstChild("ImageButton")
	cinematicButtonText = buttonContainer:FindFirstChild("TextLabel")
	
	if cinematicButton then
		cinematicButton.Image = "rbxassetid://139242732181104"
		cinematicButton.BackgroundTransparency = 1
	end
	
	if cinematicButtonText then
		cinematicButtonText.Text = "Photo"
	end
end

-- Mode Indicator
local cinematicModeIndicator = Instance.new("TextLabel")
cinematicModeIndicator.Name = "ModeIndicator"
cinematicModeIndicator.Size = UDim2.new(0.3, 0, 0.05, 0)
cinematicModeIndicator.Position = UDim2.new(0.5, 0, 0.02, 0)
cinematicModeIndicator.AnchorPoint = Vector2.new(0.5, 0)
cinematicModeIndicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cinematicModeIndicator.BackgroundTransparency = 0.5
cinematicModeIndicator.Font = Enum.Font.GothamBold
cinematicModeIndicator.Text = "📷 PHOTO MODE - Click button again to exit"
cinematicModeIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
cinematicModeIndicator.TextScaled = true
cinematicModeIndicator.Visible = false
cinematicModeIndicator.Parent = cinematicGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(0, 8)
indicatorCorner.Parent = cinematicModeIndicator

-- CoreGui types to hide in photo mode
local cinematicCoreGuiTypes = {
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.EmotesMenu,
}

local StarterGui = game:GetService("StarterGui")

local function hideAllUIForPhoto()
	hiddenGuis = {}
	
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui ~= cinematicGui then
			if gui.Enabled then
				table.insert(hiddenGuis, gui)
				gui.Enabled = false
			end
		end
	end
	
	originalCoreGuiState = {}
	for _, coreType in ipairs(cinematicCoreGuiTypes) do
		local success, enabled = pcall(function()
			return StarterGui:GetCoreGuiEnabled(coreType)
		end)
		if success then
			originalCoreGuiState[coreType] = enabled
			if enabled then
				pcall(function()
					StarterGui:SetCoreGuiEnabled(coreType, false)
				end)
			end
		end
	end
end

local function showAllUIAfterPhoto()
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then
			gui.Enabled = true
		end
	end
	hiddenGuis = {}
	
	for coreType, wasEnabled in pairs(originalCoreGuiState) do
		if wasEnabled then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(coreType, true)
			end)
		end
	end
	originalCoreGuiState = {}
end

local function toggleCinematicMode()
	isCinematicMode = not isCinematicMode
	
	if isCinematicMode then
		hideAllUIForPhoto()
		cinematicModeIndicator.Visible = true
		if cinematicButton then
			cinematicButton.ImageColor3 = Color3.fromRGB(100, 255, 100)
		end
		if cinematicButtonText then
			cinematicButtonText.TextColor3 = Color3.fromRGB(100, 255, 100)
		end
		
		task.delay(3, function()
			if isCinematicMode then
				TweenService:Create(cinematicModeIndicator, TweenInfo.new(0.5), {
					BackgroundTransparency = 1,
					TextTransparency = 1
				}):Play()
			end
		end)
	else
		showAllUIAfterPhoto()
		cinematicModeIndicator.Visible = false
		cinematicModeIndicator.BackgroundTransparency = 0.5
		cinematicModeIndicator.TextTransparency = 0
		if cinematicButton then
			cinematicButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
		if cinematicButtonText then
			cinematicButtonText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

if cinematicButton then
	cinematicButton.MouseButton1Click:Connect(toggleCinematicMode)
end

-- P key for photo mode
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		toggleCinematicMode()
	end
	
	if input.KeyCode == Enum.KeyCode.Escape and isCinematicMode then
		toggleCinematicMode()
	end
end)

-- Exit photo mode on respawn
Player.CharacterAdded:Connect(function()
	if isCinematicMode then
		isCinematicMode = false
		showAllUIAfterPhoto()
		cinematicModeIndicator.Visible = false
		if cinematicButton then
			cinematicButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
		if cinematicButtonText then
			cinematicButtonText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end)

print("📷 [CAMERA CINEMATIC] Section Loaded")

-- ================================================================================
--                     SECTION: NEW FISH DISCOVERY UI
-- ================================================================================
--[[
    Shows premium UI when player catches a new fish type
    - Cinematic banner with 3D model
    - Rotating rays effect
    - Simple notification for regular catches
]]

local FishDiscoveryColors = {
	Background = Color3.fromRGB(18, 18, 22),
	CardBg = Color3.fromRGB(28, 28, 35),
	Success = Color3.fromRGB(67, 181, 129),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(163, 166, 183),
	Common = Color3.fromRGB(163, 166, 183),
	Uncommon = Color3.fromRGB(67, 181, 129),
	Rare = Color3.fromRGB(88, 166, 255),
	Epic = Color3.fromRGB(163, 108, 229),
	Legendary = Color3.fromRGB(255, 193, 7)
}

local function showSimpleFishNotification(fishData, quantity)
	local notifGui = Instance.new("ScreenGui")
	notifGui.Name = "SimpleFishNotif"
	notifGui.ResetOnSpawn = false
	notifGui.DisplayOrder = 100
	notifGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 70)
	frame.Position = UDim2.new(1, 10, 0, 20)
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BackgroundColor3 = FishDiscoveryColors.CardBg
	frame.BorderSizePixel = 0
	frame.Parent = notifGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = FishDiscoveryColors[fishData.Rarity] or FishDiscoveryColors.Common
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = frame

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 50, 0, 50)
	iconBg.Position = UDim2.new(0, 10, 0.5, 0)
	iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = FishDiscoveryColors.Background
	iconBg.BorderSizePixel = 0
	iconBg.Parent = frame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconBg

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = fishData.ImageID or ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = iconBg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -75, 1, 0)
	label.Position = UDim2.new(0, 70, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s x%d", fishData.Name, quantity)
	label.TextSize = 15
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = FishDiscoveryColors.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -330, 0, 20)})
	tweenIn:Play()

	task.wait(3)

	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(1, 10, 0, 20)})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	notifGui:Destroy()
end

local function showNewDiscoveryBanner(fishID, fishData, quantity)
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "NewFishDiscovery"
	bannerGui.ResetOnSpawn = false
	bannerGui.DisplayOrder = 1000
	bannerGui.IgnoreGuiInset = true
	bannerGui.Parent = playerGui

	local rarityColor = FishDiscoveryColors[fishData.Rarity] or FishDiscoveryColors.Common
	local rarityText = fishData.Rarity:upper()
	
	-- Rarity glow colors (brighter for glow effects)
	local rarityGlow = {
		Common = Color3.fromRGB(200, 200, 210),
		Uncommon = Color3.fromRGB(100, 220, 160),
		Rare = Color3.fromRGB(120, 180, 255),
		Epic = Color3.fromRGB(180, 130, 255),
		Legendary = Color3.fromRGB(255, 215, 50)
	}
	local glowColor = rarityGlow[fishData.Rarity] or rarityGlow.Common

	-- ========== BACKDROP WITH RADIAL GRADIENT ==========
	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Parent = bannerGui

	-- ========== ANIMATED ROTATING RAYS ==========
	local raysContainer = Instance.new("Frame")
	raysContainer.Size = UDim2.new(2, 0, 2, 0)
	raysContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	raysContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	raysContainer.BackgroundTransparency = 1
	raysContainer.Parent = bannerGui
	raysContainer.ClipsDescendants = false

	-- Create rotating rays
	local numRays = 12
	for i = 1, numRays do
		local ray = Instance.new("Frame")
		ray.Size = UDim2.new(0.02, 0, 1.5, 0)
		ray.Position = UDim2.new(0.5, 0, 0.5, 0)
		ray.AnchorPoint = Vector2.new(0.5, 1)
		ray.Rotation = (i - 1) * (360 / numRays)
		ray.BackgroundTransparency = 0.85
		ray.BorderSizePixel = 0
		ray.Parent = raysContainer
		
		-- Gradient for ray
		local rayGradient = Instance.new("UIGradient")
		rayGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, glowColor),
			ColorSequenceKeypoint.new(1, glowColor)
		})
		rayGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.7),
			NumberSequenceKeypoint.new(1, 0)
		})
		rayGradient.Rotation = 90
		rayGradient.Parent = ray
	end

	-- Animate rays rotation
	task.spawn(function()
		local rotation = 0
		while raysContainer.Parent do
			rotation = rotation + 0.3
			raysContainer.Rotation = rotation
			task.wait(0.016)
		end
	end)

	-- ========== MAIN CARD - GLASSMORPHISM STYLE ==========
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.5, 0, 0.42, 0)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = bannerGui
	card.Visible = false

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1.6
	aspectRatio.Parent = card

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(420, 260)
	sizeConstraint.MaxSize = Vector2.new(700, 440)
	sizeConstraint.Parent = card

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 20)
	cardCorner.Parent = card

	-- Glowing border stroke
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = glowColor
	cardStroke.Thickness = 3
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	-- Inner glow gradient overlay
	local innerGlow = Instance.new("Frame")
	innerGlow.Size = UDim2.new(1, 0, 1, 0)
	innerGlow.BackgroundTransparency = 1
	innerGlow.BorderSizePixel = 0
	innerGlow.Parent = card

	local innerGlowGradient = Instance.new("UIGradient")
	innerGlowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, glowColor),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, glowColor)
	})
	innerGlowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(0.5, 0.98),
		NumberSequenceKeypoint.new(1, 0.95)
	})
	innerGlowGradient.Rotation = 45
	innerGlowGradient.Parent = innerGlow

	-- ========== SHINE SWEEP EFFECT ==========
	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0.3, 0, 1.5, 0)
	shine.Position = UDim2.new(-0.3, 0, -0.25, 0)
	shine.Rotation = 25
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.ZIndex = 10
	shine.Parent = card

	local shineGradient = Instance.new("UIGradient")
	shineGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.85),
		NumberSequenceKeypoint.new(0.6, 0.85),
		NumberSequenceKeypoint.new(1, 1)
	})
	shineGradient.Parent = shine

	-- ========== LEFT SIDE - 3D MODEL SHOWCASE ==========
	local visualContainer = Instance.new("Frame")
	visualContainer.Size = UDim2.new(0.45, 0, 1, 0)
	visualContainer.BackgroundTransparency = 1
	visualContainer.Parent = card

	-- Circular glow behind fish
	local fishGlow = Instance.new("Frame")
	fishGlow.Size = UDim2.new(0.85, 0, 0.85, 0)
	fishGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	fishGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	fishGlow.BackgroundColor3 = glowColor
	fishGlow.BackgroundTransparency = 0.85
	fishGlow.BorderSizePixel = 0
	fishGlow.Parent = visualContainer

	local fishGlowCorner = Instance.new("UICorner")
	fishGlowCorner.CornerRadius = UDim.new(1, 0)
	fishGlowCorner.Parent = fishGlow

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1.2, 0, 1.2, 0)
	viewport.Position = UDim2.new(0.5, 0, 0.5, 0)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(180, 180, 180)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -0.5)
	viewport.Parent = visualContainer

	-- ========== RIGHT SIDE - INFO PANEL ==========
	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(0.55, 0, 1, 0)
	infoContainer.Position = UDim2.new(0.45, 0, 0, 0)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = card

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingTop = UDim.new(0, 25)
	infoPadding.PaddingBottom = UDim.new(0, 25)
	infoPadding.PaddingRight = UDim.new(0, 25)
	infoPadding.PaddingLeft = UDim.new(0, 10)
	infoPadding.Parent = infoContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Parent = infoContainer

	-- ========== HEADER - "NEW DISCOVERY" WITH SPARKLE ANIMATION ==========
	local headerContainer = Instance.new("Frame")
	headerContainer.Size = UDim2.new(1, 0, 0, 26)
	headerContainer.BackgroundTransparency = 1
	headerContainer.LayoutOrder = 1
	headerContainer.Parent = infoContainer

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Text = "⭐ NEW DISCOVERY ⭐"
	headerLabel.Size = UDim2.new(1, 0, 1, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextSize = 16
	headerLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = headerContainer

	-- Animate header text glow
	task.spawn(function()
		local brightness = 0
		local direction = 1
		while headerLabel.Parent do
			brightness = brightness + direction * 0.05
			if brightness >= 1 then direction = -1 end
			if brightness <= 0 then direction = 1 end
			local glow = math.floor(200 + 55 * brightness)
			headerLabel.TextColor3 = Color3.fromRGB(255, glow, 80 + math.floor(20 * brightness))
			task.wait(0.03)
		end
	end)

	-- ========== FISH NAME - LARGE BOLD TEXT ==========
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = fishData.Name
	nameLabel.Size = UDim2.new(1, 0, 0, 50)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = 32
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = infoContainer

	-- Text stroke for depth
	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 1.5
	nameStroke.Transparency = 0.5
	nameStroke.Parent = nameLabel

	-- ========== RARITY & PRICE BADGES ==========
	local badgesContainer = Instance.new("Frame")
	badgesContainer.Size = UDim2.new(1, 0, 0, 32)
	badgesContainer.BackgroundTransparency = 1
	badgesContainer.LayoutOrder = 3
	badgesContainer.Parent = infoContainer

	local badgesLayout = Instance.new("UIListLayout")
	badgesLayout.FillDirection = Enum.FillDirection.Horizontal
	badgesLayout.Padding = UDim.new(0, 12)
	badgesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgesLayout.Parent = badgesContainer

	-- Rarity Badge with gradient
	local rarityBadge = Instance.new("Frame")
	rarityBadge.BackgroundColor3 = rarityColor
	rarityBadge.Size = UDim2.new(0, 95, 1, 0)
	rarityBadge.Parent = badgesContainer

	local rarityBadgeCorner = Instance.new("UICorner")
	rarityBadgeCorner.CornerRadius = UDim.new(0.3, 0)
	rarityBadgeCorner.Parent = rarityBadge

	local rarityBadgeGradient = Instance.new("UIGradient")
	rarityBadgeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	rarityBadgeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 0.7)
	})
	rarityBadgeGradient.Rotation = 90
	rarityBadgeGradient.Parent = rarityBadge

	local rarityTextLabel = Instance.new("TextLabel")
	rarityTextLabel.Size = UDim2.new(1, 0, 1, 0)
	rarityTextLabel.BackgroundTransparency = 1
	rarityTextLabel.Text = "✦ " .. rarityText
	rarityTextLabel.Font = Enum.Font.GothamBlack
	rarityTextLabel.TextSize = 13
	rarityTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityTextLabel.Parent = rarityBadge

	local rarityTextStroke = Instance.new("UIStroke")
	rarityTextStroke.Color = Color3.fromRGB(0, 0, 0)
	rarityTextStroke.Thickness = 1
	rarityTextStroke.Transparency = 0.5
	rarityTextStroke.Parent = rarityTextLabel

	-- Price Tag with coin icon
	local priceTag = Instance.new("Frame")
	priceTag.Size = UDim2.new(0, 100, 1, 0)
	priceTag.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
	priceTag.Parent = badgesContainer

	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0.3, 0)
	priceCorner.Parent = priceTag

	local priceText = Instance.new("TextLabel")
	priceText.Size = UDim2.new(1, 0, 1, 0)
	priceText.BackgroundTransparency = 1
	priceText.Text = "💰 $" .. tostring(fishData.Price or 0)
	priceText.Font = Enum.Font.GothamBold
	priceText.TextSize = 15
	priceText.TextColor3 = Color3.fromRGB(100, 220, 150)
	priceText.Parent = priceTag

	-- ========== HINT TEXT AT BOTTOM ==========
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Text = "🎣 TAP ANYWHERE TO CONTINUE"
	hintLabel.Size = UDim2.new(1, 0, 0, 22)
	hintLabel.Position = UDim2.new(0.5, 0, 0.93, 0)
	hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextSize = 12
	hintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	hintLabel.TextTransparency = 0.3
	hintLabel.Parent = card

	-- Pulse animation for hint
	task.spawn(function()
		while hintLabel.Parent do
			TweenService:Create(hintLabel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
				{TextTransparency = 0.6}):Play()
			task.wait(0.8)
			TweenService:Create(hintLabel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
				{TextTransparency = 0.2}):Play()
			task.wait(0.8)
		end
	end)

	-- ========== LOAD 3D FISH MODEL ==========
	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels") 
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FishModels"))
		or workspace:FindFirstChild("FishModels")

	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishID)
		if fishModel then
			local worldModel = Instance.new("WorldModel")
			worldModel.Parent = viewport
			
			local clonedModel = fishModel:Clone()
			clonedModel.Parent = worldModel

			if clonedModel:IsA("Model") then 
				clonedModel:PivotTo(CFrame.new(0, 0, 0))
			elseif clonedModel:IsA("BasePart") then 
				clonedModel.CFrame = CFrame.new(0, 0, 0) 
			end

			local modelSize = clonedModel:GetExtentsSize()
			local maxDim = math.max(modelSize.X, modelSize.Y, modelSize.Z)
			
			local fov = 60
			local fillFactor = 1.2
			local distance = (maxDim / 2) / math.tan(math.rad(fov / 2)) * fillFactor
			
			local cam = Instance.new("Camera")
			cam.FieldOfView = fov
			
			local angle = math.rad(25)
			local camX = distance * math.cos(angle) * 0.85
			local camY = maxDim * 0.1
			local camZ = distance * math.sin(angle) * 0.85 + distance * 0.4
			
			cam.CFrame = CFrame.new(Vector3.new(camX, camY, camZ), Vector3.new(0, 0, 0))
			cam.Parent = viewport
			viewport.CurrentCamera = cam

			-- Smooth fish rotation
			task.spawn(function()
				while viewport.Parent do
					if clonedModel and clonedModel.Parent then
						local currentCF = clonedModel:GetPivot()
						clonedModel:PivotTo(currentCF * CFrame.Angles(0, math.rad(0.6), 0))
					end
					task.wait(0.016)
				end
			end)
		end
	end

	-- ========== ENTRANCE ANIMATIONS ==========
	-- Fade in backdrop
	TweenService:Create(backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.5}):Play()

	-- Scale up card with bounce
	card.Size = UDim2.new(0, 0, 0, 0)
	card.Visible = true
	
	local popTween = TweenService:Create(card, 
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0.5, 0, 0.42, 0)}
	)
	popTween:Play()

	-- Shine sweep animation (delayed)
	task.delay(0.5, function()
		if shine.Parent then
			TweenService:Create(shine, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = UDim2.new(1.1, 0, -0.25, 0)}):Play()
		end
	end)

	-- Animate stroke glow
	task.spawn(function()
		local pulseDir = 1
		local transparency = 0.3
		while cardStroke.Parent do
			transparency = transparency + pulseDir * 0.02
			if transparency >= 0.5 then pulseDir = -1 end
			if transparency <= 0.1 then pulseDir = 1 end
			cardStroke.Transparency = transparency
			task.wait(0.03)
		end
	end)

	-- ========== CLOSE BUTTON (FULLSCREEN) ==========
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(1, 0, 1, 0)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = ""
	closeButton.ZIndex = 100
	closeButton.Parent = bannerGui

	local closing = false
	closeButton.MouseButton1Click:Connect(function()
		if closing then return end
		closing = true
		
		-- Exit animations
		TweenService:Create(backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		TweenService:Create(raysContainer, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		
		local closeTween = TweenService:Create(card, 
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		closeTween:Play()
		
		closeTween.Completed:Wait()
		bannerGui:Destroy()
	end)
end

-- Hook into FishCaughtEvent for discovery UI (may already be connected, but safe to add)
local FishCaughtEventForDiscovery = ReplicatedStorage:FindFirstChild("FishCaughtEvent")
if not FishCaughtEventForDiscovery then
	FishCaughtEventForDiscovery = ReplicatedStorage:WaitForChild("FishCaughtEvent", 10)
end

if FishCaughtEventForDiscovery then
	FishCaughtEventForDiscovery.OnClientEvent:Connect(function(data)
		print("📩 [FISH DISCOVERY] Received FishCaughtEvent on client!")
		print("📩 [FISH DISCOVERY] Fish:", data.FishData and data.FishData.Name or "nil", "| New Discovery:", tostring(data.IsNewDiscovery))
		
		if data.IsNewDiscovery then
			showNewDiscoveryBanner(data.FishID, data.FishData, data.Quantity)
		else
			showSimpleFishNotification(data.FishData, data.Quantity)
		end
	end)
	print("✅ [FISH DISCOVERY] Connected to FishCaughtEvent")
else
	warn("⚠️ [FISH DISCOVERY] FishCaughtEvent not found!")
end

print("🐟 [FISH DISCOVERY UI] Section Loaded")

-- ================================================================================
--                     SECTION: FISHING REPLICATION CLIENT
-- ================================================================================
--[[
    Handles visual replication of OTHER players' fishing actions
    - Creates floaters and fishing lines for other players
    - All animations run locally for smooth appearance
    - ✅ WRAPPED IN FUNCTION to reduce local register count
]]

-- ✅ FIX: Wrap replication system in a function to reduce local variables at top level
local function initReplicationSystem()
	local FishingRemotes = ReplicatedStorage:WaitForChild("FishingRemotes", 5)
	if not FishingRemotes then return end
	
	local PlayerThrewFloaterEvent = FishingRemotes:FindFirstChild("PlayerThrewFloater")
	local PlayerStartedPullingEvent = FishingRemotes:FindFirstChild("PlayerStartedPulling")
	local PlayerStoppedFishingEvent = FishingRemotes:FindFirstChild("PlayerStoppedFishing")

	local otherPlayersFishing = {} -- [player] = {floater, line, etc}

	-- ✅ Default line style for replicated fishing lines
	local replicatedLineStyle = {
		Width = 0.12,
		Color = Color3.fromRGB(100, 200, 255),
		Transparency = 0.2,
		LightEmission = 5,
		LightInfluence = 0,
		FaceCamera = true
	}

	local function cleanupPlayerFishing(targetPlayer)
		local data = otherPlayersFishing[targetPlayer]
		if not data then return end
		
		-- ✅ Cleanup animation connections
		if data.bobbingConnection then
			pcall(function() data.bobbingConnection:Disconnect() end)
		end
		if data.throwConnection then
			pcall(function() data.throwConnection:Disconnect() end)
		end
		if data.fightingConnection then
			pcall(function() data.fightingConnection:Disconnect() end)
		end
		
		if data.floater then
			pcall(function() data.floater:Destroy() end)
		end
		if data.lineConnection then
			pcall(function() data.lineConnection:Disconnect() end)
		end
		if data.middlePoints then
			for _, point in ipairs(data.middlePoints) do
				pcall(function() point:Destroy() end)
			end
		end
		if data.beamSegments then
			for _, beam in ipairs(data.beamSegments) do
				pcall(function() beam:Destroy() end)
			end
		end
		if data.attachment0 then
			pcall(function() data.attachment0:Destroy() end)
		end
		if data.attachment1 then
			pcall(function() data.attachment1:Destroy() end)
		end
		
		otherPlayersFishing[targetPlayer] = nil
	end

	-- ✅ Helper to find edge part on other player's fishing rod
	local function findOtherPlayerEdgePart(sourcePlayer)
		local character = sourcePlayer.Character
		if not character then return nil end
		
		-- Find equipped fishing rod
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:find("Rod") or tool.Name:find("FishingRod")) then
				local handle = tool:FindFirstChild("Handle")
				if handle then
					for _, child in ipairs(handle:GetChildren()) do
						if child:IsA("MeshPart") or child:IsA("Part") then
							local edge = child:FindFirstChild("Edge")
							if edge and edge:IsA("BasePart") then
								return edge
							end
						end
					end
				end
			end
		end
		return nil
	end

	-- ✅ Create fishing line for other player
	local function createReplicatedFishingLine(sourcePlayer, floater, lineStyle)
		local edgePart = findOtherPlayerEdgePart(sourcePlayer)
		if not edgePart then return nil end
		
		local floaterPart = floater:IsA("Model") and floater.PrimaryPart or floater
		if not floaterPart then return nil end
		
		-- Use LineRenderer module if available
		if LineRenderer and LineRenderer.CreateCompleteFishingLineWithPhysics then
			local sourceCharacter = sourcePlayer.Character
			local lineData = LineRenderer.CreateCompleteFishingLineWithPhysics(
				edgePart, 
				floaterPart, 
				lineStyle or replicatedLineStyle, 
				15, -- Fewer points for performance
				sourceCharacter, 
				floater
			)
			return lineData
		end
	
		return nil
	end

	-- ✅ Helper: Animate floater throw (parabolic arc)
	local function animateReplicatedThrow(floater, startPos, targetPos, throwHeight, duration, onComplete)
		if not floater then return end
		
		local floaterPart = floater:IsA("Model") and floater.PrimaryPart or floater
		if not floaterPart then return end
		
		throwHeight = throwHeight or 8
		duration = duration or 1.0
		
		local elapsed = 0
		local throwConnection
		throwConnection = RunService.Heartbeat:Connect(function(dt)
			elapsed = elapsed + dt
			local alpha = math.min(elapsed / duration, 1)
			
			-- Parabolic trajectory
			local x = startPos.X + (targetPos.X - startPos.X) * alpha
			local z = startPos.Z + (targetPos.Z - startPos.Z) * alpha
			local baseY = startPos.Y + (targetPos.Y - startPos.Y) * alpha
			
			-- Parabola peak at middle
			local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
			local yOffset = throwHeight * parabolaFactor
			
			local newPos = Vector3.new(x, baseY + yOffset, z)
			
			if floater:IsA("Model") and floater.PrimaryPart then
				floater:SetPrimaryPartCFrame(CFrame.new(newPos))
			elseif floater:IsA("BasePart") then
				floater.CFrame = CFrame.new(newPos)
			end
			
			if alpha >= 1 then
				throwConnection:Disconnect()
				if onComplete then
					onComplete()
				end
			end
		end)
		
		return throwConnection
	end

	-- ✅ Helper: Start bobbing animation for replicated floater
	local function startReplicatedBobbing(playerData)
		if not playerData or not playerData.floater then 
			return 
		end
		
		local floater = playerData.floater
		local floaterPart = floater:IsA("Model") and floater.PrimaryPart or floater
		if not floaterPart then 
			return 
		end
		
		
		local baseY = playerData.targetPos.Y
		local bobSpeed = 2 + math.random() * 0.5 -- Slight randomization
		local bobAmount = 0.15 + math.random() * 0.1
		local startTime = tick()
		
		-- Disconnect existing bobbing
		if playerData.bobbingConnection then
			playerData.bobbingConnection:Disconnect()
		end
		
		playerData.bobbingConnection = RunService.Heartbeat:Connect(function()
			if not floater or not floater.Parent then
				if playerData.bobbingConnection then
					playerData.bobbingConnection:Disconnect()
					playerData.bobbingConnection = nil
				end
				return
			end
			
			local elapsed = tick() - startTime
			local bobOffset = math.sin(elapsed * bobSpeed) * bobAmount
			local newY = baseY + bobOffset
			
			local currentPos = floaterPart.Position
			local newPos = Vector3.new(currentPos.X, newY, currentPos.Z)
			
			if floater:IsA("Model") and floater.PrimaryPart then
				floater:SetPrimaryPartCFrame(CFrame.new(newPos))
			elseif floater:IsA("BasePart") then
				floater.CFrame = CFrame.new(newPos)
			end
		end)
	end

	if PlayerThrewFloaterEvent then
		PlayerThrewFloaterEvent.OnClientEvent:Connect(function(sourcePlayer, eventData)
			if sourcePlayer == player then return end
			
			cleanupPlayerFishing(sourcePlayer)
			
			local targetPos = eventData.TargetPos
			local startPos = eventData.StartPos
			local throwHeight = eventData.ThrowHeight or 8
			if not targetPos then return end

			-- ✅ FIX: Try multiple floater ID formats
			local floaterId = eventData.FloaterId or "FloaterDoll"
			local floaterTemplate = FloatersFolder:FindFirstChild(floaterId)
			
			-- Try fallback names if not found
			if not floaterTemplate then
				floaterTemplate = FloatersFolder:FindFirstChild("FloaterDoll")
				or FloatersFolder:FindFirstChild("Floater_Doll")
				or FloatersFolder:FindFirstChildWhichIsA("Model")
				or FloatersFolder:FindFirstChildWhichIsA("BasePart")
			end
			
			if floaterTemplate then
				local floater = floaterTemplate:Clone()
				floater.Name = "ReplicatedFloater_" .. sourcePlayer.Name
				
				if floater:IsA("Model") then
					for _, part in ipairs(floater:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Anchored = true
							part.CanCollide = false
						end
					end
					floater.PrimaryPart = floater.PrimaryPart or floater:FindFirstChildWhichIsA("BasePart")
				else
					floater.Anchored = true
					floater.CanCollide = false
				end
				
				-- ✅ Get start position from source player's rod if not provided
				if not startPos then
					local sourceCharacter = sourcePlayer.Character
					if sourceCharacter then
						local hrp = sourceCharacter:FindFirstChild("HumanoidRootPart")
						if hrp then
							startPos = hrp.Position + Vector3.new(0, 2, 0)
						end
					end
				end
				startPos = startPos or targetPos + Vector3.new(0, 5, 0)
				
				-- ✅ Start at throw position
				if floater:IsA("Model") and floater.PrimaryPart then
					floater:SetPrimaryPartCFrame(CFrame.new(startPos))
				else
					floater.CFrame = CFrame.new(startPos)
				end
				
				floater.Parent = workspace
				
				-- Store data for cleanup
				local playerData = {
					floater = floater,
					targetPos = targetPos,
					startPos = startPos,
					throwHeight = throwHeight
				}
				otherPlayersFishing[sourcePlayer] = playerData
				
				-- ✅ ANIMATE: Throw arc animation
				local throwDuration = 1.0
				playerData.throwConnection = animateReplicatedThrow(floater, startPos, targetPos, throwHeight, throwDuration, function()
					-- After throw completes, start bobbing
					startReplicatedBobbing(playerData)
					
					-- Create fishing line after floater lands
					task.delay(0.1, function()
						if not otherPlayersFishing[sourcePlayer] then return end
						
						local lineData = createReplicatedFishingLine(sourcePlayer, floater, eventData.LineStyle)
						if lineData then
							playerData.middlePoints = lineData.middlePoints
							playerData.beamSegments = lineData.beamSegments
							playerData.attachment0 = lineData.attachment0
							playerData.attachment1 = lineData.attachment1
							playerData.lineConnection = lineData.physicsConnection
						end
					end)
				end)
			else
				warn(string.format("⚠️ [REPLICATION] Floater template not found for %s: %s", sourcePlayer.Name, tostring(floaterId)))
			end
		end)
	end

	-- ✅ Helper: Start fish fighting animation (random movement during pull)
	local function startFishFightingAnimation(playerData)
		if not playerData or not playerData.floater then return end
		
		local floater = playerData.floater
		local floaterPart = floater:IsA("Model") and floater.PrimaryPart or floater
		if not floaterPart then return end
		
		local basePos = floaterPart.Position
		local startTime = tick()
		local fightDuration = 5 + math.random() * 3 -- Random 5-8 seconds fight
		
		-- Disconnect bobbing if active
		if playerData.bobbingConnection then
			playerData.bobbingConnection:Disconnect()
			playerData.bobbingConnection = nil
		end
		
		-- Random movement parameters
		local moveSpeed = 3 + math.random() * 2
		local moveRange = 1.5 + math.random() * 1
		local lastDirectionChange = 0
		local currentOffsetX = 0
		local currentOffsetZ = 0
		local targetOffsetX = 0
		local targetOffsetZ = 0
		
		playerData.fightingConnection = RunService.Heartbeat:Connect(function(dt)
			if not floater or not floater.Parent then
				if playerData.fightingConnection then
					playerData.fightingConnection:Disconnect()
					playerData.fightingConnection = nil
				end
				return
			end
			
			local elapsed = tick() - startTime
			
			-- Change direction randomly
			if elapsed - lastDirectionChange > 0.3 + math.random() * 0.5 then
				lastDirectionChange = elapsed
				targetOffsetX = (math.random() - 0.5) * 2 * moveRange
				targetOffsetZ = (math.random() - 0.5) * 2 * moveRange
			end
			
			-- Smooth interpolation to target
			currentOffsetX = currentOffsetX + (targetOffsetX - currentOffsetX) * dt * moveSpeed
			currentOffsetZ = currentOffsetZ + (targetOffsetZ - currentOffsetZ) * dt * moveSpeed
			
			-- Bob up and down more intensely during fight
			local bobOffset = math.sin(elapsed * 8) * 0.3
			
			local newPos = Vector3.new(
				basePos.X + currentOffsetX,
				basePos.Y + bobOffset,
				basePos.Z + currentOffsetZ
			)
			
			if floater:IsA("Model") and floater.PrimaryPart then
				floater:SetPrimaryPartCFrame(CFrame.new(newPos))
			elseif floater:IsA("BasePart") then
				floater.CFrame = CFrame.new(newPos)
			end
		end)
	end

	-- ✅ Handle pulling event - start fish fighting animation
	if PlayerStartedPullingEvent then
		PlayerStartedPullingEvent.OnClientEvent:Connect(function(sourcePlayer, eventData)
			if sourcePlayer == player then return end
			
			local playerData = otherPlayersFishing[sourcePlayer]
			if playerData then
				-- Stop bobbing when pulling starts
				if playerData.bobbingConnection then
					playerData.bobbingConnection:Disconnect()
					playerData.bobbingConnection = nil
				end
				
				-- Start fish fighting animation
				startFishFightingAnimation(playerData)
			end
		end)
	end

	if PlayerStoppedFishingEvent then
		PlayerStoppedFishingEvent.OnClientEvent:Connect(function(sourcePlayer, eventData)
			cleanupPlayerFishing(sourcePlayer)
		end)
	end

	-- Cleanup when player leaves
	Players.PlayerRemoving:Connect(function(leavingPlayer)
		cleanupPlayerFishing(leavingPlayer)
	end)

	print("🎣 [FISHING REPLICATION] Section Loaded")
end

-- ✅ Initialize replication system in a separate thread
task.spawn(initReplicationSystem)

print("✅ [FISHING CLIENT] Fully Loaded (Combined Script)")