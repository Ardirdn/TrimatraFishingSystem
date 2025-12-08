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
local SoundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))
local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods")
local FloatersFolder = FishingRodsFolder:WaitForChild("Floaters")

-- Module Loader for optimized systems
local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientModuleLoader"))
local LineRenderer = ModuleLoader.GetLineRenderer()
local AnimController = ModuleLoader.GetAnimationController()
local WaterDetect = ModuleLoader.GetWaterDetection()

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
-- REPLICATION HELPERS (SIMPLIFIED)
-- Server only receives STATE changes, not position updates
-- All animation runs locally on each client
-- ============================================
local function notifyReplication(method, ...)
	local args = {...}
	task.spawn(function()
		if _G.FishingReplication and _G.FishingReplication[method] then
			pcall(function()
				_G.FishingReplication[method](table.unpack(args))
			end)
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



assert(fillBar, "ERROR: Fillbar not found! Periksa struktur dan penamaan GUI")



local initialScale = 0.4
local maxScale = 1
local tapIncrease = 0.08  -- Original value
local decayRate = 0.3 -- per detik
local timeLimit = 7 -- detik
local progress = initialScale
local isPulling = false
local lastTapTime = tick()
local startTime = 0


local cameraShakeEnabled = true      -- untuk enable/disable global, bisa ubah di UI/config
local shakeMagnitude = 0.15          -- besar getaran (misal 0.2, dicoba-coba)
local shakeSpeed = 20               -- kecepatan getaran (misal 20)
local isShaking = false           -- Untuk menyimpan posisi awal camera
local pullCam = false
local pullCamConn = nil


local TweenService = game:GetService("TweenService")

local function rotatePlayerToFloater()
	if not HRP or not currentFloater then return end
	local target = (currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater).Position

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

function startThrowCameraLookAt(targetPos)
	if throwCamActive then return end
	throwCamActive = true
	throwCamTargetPos = targetPos
	
	-- ✅ SAVE current camera CFrame (FULL) - for restoring later
	throwCamSavedCFrame = camera.CFrame
	throwCamSavedPosition = camera.CFrame.Position
	
	print("📷 [CAMERA] Starting throw look-at (locked position)")
	
	-- Set camera to Scriptable so player can't move it
	camera.CameraType = Enum.CameraType.Scriptable
	
	if throwCamConn then throwCamConn:Disconnect() end
	
	throwCamConn = RunService.RenderStepped:Connect(function()
		if not throwCamActive then return end
		if not throwCamSavedPosition then return end
		
		local floaterPart = currentFloater and (currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater)
		
		-- Use floater position if available, otherwise use target position
		local lookTarget
		if floaterPart then
			lookTarget = floaterPart.Position
		elseif throwCamTargetPos then
			lookTarget = throwCamTargetPos
		else
			return
		end
		
		-- Create CFrame: LOCKED SAVED POSITION, looking at floater
		local targetCFrame = CFrame.new(throwCamSavedPosition, lookTarget)
		
		-- Smoothly rotate camera towards floater
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.12)
	end)
end

function stopThrowCameraLookAt()
	if not throwCamActive then return end
	throwCamActive = false
	throwCamTargetPos = nil
	
	print("📷 [CAMERA] Stopping throw look-at effect (smooth transition)")
	
	if throwCamConn then
		throwCamConn:Disconnect()
		throwCamConn = nil
	end
	
	-- ✅ SMOOTH TRANSITION: Lerp camera back to ORIGINAL position (before throw)
	local humanoid = Character and Character:FindFirstChild("Humanoid")
	local savedCFrame = throwCamSavedCFrame
	
	if savedCFrame then
		-- Start smooth transition using RenderStepped
		local transitionStartTime = tick()
		local transitionDuration = 0.5 -- Duration in seconds
		local startCFrame = camera.CFrame
		
		local transitionConn
		transitionConn = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - transitionStartTime
			local alpha = math.min(elapsed / transitionDuration, 1)
			
			-- Use smooth easing (EaseOutQuad)
			local easedAlpha = 1 - (1 - alpha) * (1 - alpha)
			
			-- Lerp from current position back to saved original CFrame
			camera.CFrame = startCFrame:Lerp(savedCFrame, easedAlpha)
			
			-- Transition complete
			if alpha >= 1 then
				transitionConn:Disconnect()
				transitionConn = nil
				
				-- Ensure final CFrame matches saved exactly
				camera.CFrame = savedCFrame
				
				-- Now switch to Custom mode for player control
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = humanoid
				
				print("📷 [CAMERA] Smooth transition complete, restored to original position")
			end
		end)
	else
		-- Fallback: No saved CFrame, just restore immediately
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end
	
	throwCamSavedCFrame = nil
	throwCamSavedPosition = nil
end

function startPullCamera(offsetDistance, offsetSide)
	-- SIMPAN camera state sebelum cinematic!
	previousCameraCFrame = camera.CFrame
	previousCameraSubject = camera.CameraSubject
	previousMinZoom = Players.LocalPlayer.CameraMinZoomDistance
	previousMaxZoom = Players.LocalPlayer.CameraMaxZoomDistance

	pullCam = true
	camera.CameraType = Enum.CameraType.Scriptable
	Players.LocalPlayer.CameraMinZoomDistance = offsetDistance
	Players.LocalPlayer.CameraMaxZoomDistance = offsetDistance

	if pullCamConn then pullCamConn:Disconnect() end
	pullCamConn = RunService.RenderStepped:Connect(function()
		if not pullCam then return end
		local root = Character and Character:FindFirstChild("HumanoidRootPart")
		local floaterPart = currentFloater and (currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater)
		if not root or not floaterPart then return end

		local toFloater = (floaterPart.Position - root.Position).Unit
		local perp = Vector3.new(-toFloater.Z, 0, toFloater.X)
		local campos = root.Position - toFloater * offsetDistance + perp * offsetSide + Vector3.new(0, 3, 0)
		camera.CFrame = CFrame.new(campos, floaterPart.Position + Vector3.new(0,2,0))
	end)
end


function stopPullCamera()
	pullCam = false
	if pullCamConn then pullCamConn:Disconnect() end

	-- Restore zoom setting lebih awal
	Players.LocalPlayer.CameraMinZoomDistance = previousMinZoom or 0.5
	Players.LocalPlayer.CameraMaxZoomDistance = previousMaxZoom or 14

	-- Tween balik ke previousCameraCFrame selama 2 detik
	camera.CameraType = Enum.CameraType.Scriptable
	local tween = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = previousCameraCFrame})
	tween:Play()
	tween.Completed:Connect(function()
		-- Pastikan di-set hanya setelah tween selesai
		camera.CFrame = previousCameraCFrame
		camera.CameraSubject = previousCameraSubject or Character:FindFirstChild("Humanoid") or Character
		camera.CameraType = Enum.CameraType.Custom
	end)
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

local function cameraShake(deltaTime)
	if not isShaking then return end -- extra safety
	local time = tick()
	local offsetX = math.sin(time * shakeSpeed) * shakeMagnitude
	local offsetY = math.cos(time * shakeSpeed * 1.1) * shakeMagnitude
	local shakeOffset = Vector3.new(offsetX, offsetY, 0)
	local cam = workspace.CurrentCamera
	cam.CFrame = cam.CFrame * CFrame.new(shakeOffset)
end

local function startCameraShake()
	if not cameraShakeEnabled then return end
	if isShaking then return end
	isShaking = true
	RunService:BindToRenderStep(shakeName, Enum.RenderPriority.Camera.Value + 1, cameraShake)
end

local function stopCameraShake()
	if not isShaking then return end
	isShaking = false
	pcall(function()
		RunService:UnbindFromRenderStep(shakeName)
	end)
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
local THROW_ANIM_ID = "rbxassetid://133129909348247"  -- Animasi lempar
local IDLE_ANIM_ID = "rbxassetid://134300443852886" 
local PULLING_ANIM_ID = "rbxassetid://96970910308257"  -- TAMBAH INI - Animasi pulling (loop)
local CATCH_ANIM_ID = "rbxassetid://96970910308257"  -- TAMBAH INI - Animasi catch (1x)

-- Line renderer variables (HANYA 1x DECLARE)
local middlePoints = {}
local beamSegments = {}
local numMiddlePoints = 30

-- ========================================
-- FORWARD DECLARATIONS
-- ========================================
local cleanupBaitLine
local createBaitLine
local updateBaitLine
local startBobbing
local retrieveFloater
local startPulling


-- ========================================
-- WIND ANIMATION CONFIG (Delegated to Module)
-- ========================================
local function getWindSettings()
	if LineRenderer and LineRenderer.GetWindSettings then
		return LineRenderer.GetWindSettings()
	end
	-- Fallback default
	return { SwayStrength = 0.3, WindSpeed1 = 1.2, WindSpeed2 = 0.8, WaveCount = 2 }
end


-- ========================================
-- HELPER FUNCTIONS (Using Optimized Modules)
-- ========================================

-- Water Detection: Delegates to optimized module
local function isPositionInWater(position)
	if WaterDetect and WaterDetect.IsPositionInWater then
		return WaterDetect.IsPositionInWater(position)
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


local function cleanupBaitLine()
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


-- Create bait line using optimized module
local function createBaitLine()
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


local function retrieveFloater()
	isRetrieving = true  -- START LOCK

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


local function startPulling()
	-- Performance throttle check
	if _getSM() < 0.5 then return end
	
	if isPulling or not currentFloater then
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
	
	-- ✅ Play fish bite sound at floater position (3D)
	local floaterPos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
	SoundConfig.PlaySoundAtPosition("FishBite", floaterPos)
	
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

	local pullStartPos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
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

	local windConfig = getWindSettings()
	local windTime = 0

	beamUpdateConnection = RunService.Heartbeat:Connect(function(dt)
		if not edgePart or not currentFloater or not isPulling then return end
		if #middlePoints == 0 then return end
		if not beamAttachment0 or not beamAttachment1 then return end

		windTime = windTime + dt

		local startPos = beamAttachment0.WorldPosition
		local endPos = beamAttachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude

		local baseSag = math.clamp(totalDist * 0.25, 3, 18)
		local currentSag = baseSag * (1 - currentTensionLevel)

		local ropeDir = (endPos - startPos).Unit
		local windDir = ropeDir:Cross(Vector3.new(0, 1, 0))
		if windDir.Magnitude > 0.01 then windDir = windDir.Unit else windDir = Vector3.new(1, 0, 0) end

		for i, point in ipairs(middlePoints) do
			if point and point.Parent then
				local alpha = i / (numMiddlePoints + 1)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = currentSag * parabolaFactor

				local windStrength = windConfig.SwayStrength * (1 - currentTensionLevel * 0.7)
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

	pullConnection = RunService.Heartbeat:Connect(function(dt)
		if not currentFloater then
			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end
			isPulling = false
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

			-- FIRE TO SERVER (RemoteEvent)
			local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
			if FishingSuccessEvent then
				print("📡 [DEBUG CLIENT] Firing FishingSuccessEvent to server (FAIL)")
				FishingSuccessEvent:FireServer(false) -- FireServer, bukan Fire!
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

			-- FIRE TO SERVER (RemoteEvent)
			local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
			if FishingSuccessEvent then
				print("📡 [DEBUG CLIENT] Firing FishingSuccessEvent to server (SUCCESS)")
				FishingSuccessEvent:FireServer(true) -- FireServer, bukan Fire!
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




local function startBobbing()
	-- Optimization: skip if resources not ready
	if _getSM() < 0.5 then return end
	if not currentFloater then return end

	local basePos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
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
		
		-- Get current floater position
		local currentPos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
		
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

local function throwFloater()
	-- Frame rate limiter check
	if _getSM() < 0.5 then return end
	
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

	-- CALCULATE TARGET POSITION
	local startPos = edgePart.Position
	local lookDirection = Character.PrimaryPart.CFrame.LookVector
	local horizontalTarget = startPos + (lookDirection * currentConfig.MaxThrowDistance)

	-- RAYCAST untuk cari ground/water surface
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayOrigin = Vector3.new(horizontalTarget.X, horizontalTarget.Y + 200, horizontalTarget.Z)
	local rayDirection = Vector3.new(0, -300, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	local targetPos
	if rayResult then
		print("✅ Surface detected at Y:", rayResult.Position.Y)
		local debugPart = Instance.new("Part")
		debugPart.Size = Vector3.new(2, 0.5, 2)
		debugPart.Position = rayResult.Position
		debugPart.Anchored = true
		debugPart.CanCollide = false
		debugPart.Color = Color3.new(0, 1, 0)
		debugPart.Material = Enum.Material.Neon
		debugPart.Parent = workspace
		task.delay(5, function() debugPart:Destroy() end)
		targetPos = Vector3.new(horizontalTarget.X, rayResult.Position.Y + 0.5, horizontalTarget.Z)
	else
		warn("⚠️ No surface found!")
		isFishing = false
		isThrowing = false
		return
	end

	-- CLONE FLOATER (Use equipped floater from player data, fallback to rod config)
	print("🎈 [FISHING DEBUG] equippedFloaterId:", equippedFloaterId or "nil")
	print("🎈 [FISHING DEBUG] currentConfig.FloaterObject:", currentConfig.FloaterObject)
	
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
	
	-- Fallback to rod config floater
	if not floaterTemplate then
		floaterTemplate = FloatersFolder:FindFirstChild(currentConfig.FloaterObject)
		if floaterTemplate then
			floaterToUse = currentConfig.FloaterObject
			print("🎈 [FISHING] Using DEFAULT floater from rod config:", currentConfig.FloaterObject)
		else
			print("⚠️ [FISHING] Rod config floater not found:", currentConfig.FloaterObject)
		end
	end
	
	if not floaterTemplate then 
		warn("Floater tidak ditemukan! Equipped:", equippedFloaterId or "nil", "| Default:", currentConfig.FloaterObject)
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

local function onMouseClick()

	-- ✅ NEW: Block throwing if any UI is open
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

	-- ✅ FIXED: If floater exists, handle retrieval
	if currentFloater then
		if not isPulling then
			warn("Player klik, ada floater aktif - RETRIEVE!")
			isFloating = false
			isFishing = false
			if bobConnection then
				bobConnection:Disconnect()
				bobConnection = nil
			end
			retrieveFloater()
			return
		end
	end
	
	-- ✅ FIXED: Reset stuck state - if isFloating but no currentFloater, reset state
	if isFloating and not currentFloater then
		warn("State stuck - isFloating true tapi tidak ada floater, reset...")
		isFloating = false
	end
	
	if isFishing and not currentFloater then
		warn("State stuck - isFishing true tapi tidak ada floater, reset...")
		isFishing = false
	end

	if isThrowing or isPulling then
		warn("Klik diabaikan: Sedang proses lempar/pulling")
		return
	end

	if not currentTool or not currentConfig then return end


	throwFloater()
end





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
	if gameProcessed then return end

	-- ✅ FIX: Support both Mouse AND Touch for Android
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		onMouseClick()
	end
end)

-- ✅ FIX #4: Complete state reset on respawn/death
Player.CharacterAdded:Connect(function(newCharacter)
	print("🔄 [FISHING] Character respawned, resetting all state...")
	
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
	local uiChecks = {
		-- Existing UIs
		{gui = "EquipmentGUI", panel = "MainPanel"},
		{gui = "FishCollectionGUI", panel = "MainPanel"},
		{gui = "FishermanShopGUI", panel = "ShopPanel"},
		{gui = "RodShopGUI", panel = "MainPanel"},
		{gui = "InventoryGUI", panel = "MainPanel"},
		{gui = "InventoryGUI_V3", panel = "MainPanel"}, -- ✅ Correct inventory name
		{gui = "SettingsGUI", panel = "MainPanel"},
		-- ✅ NEW: Additional UIs
		{gui = "RedeemGui", panel = "MainPanel"},
		{gui = "DonateGUI", panel = "MainPanel"},
		{gui = "DonateGui", panel = "MainPanel"}, -- Alternative name
		{gui = "Shop", panel = "MainPanel"}, -- Shop with auras
		{gui = "ShopGUI", panel = "MainPanel"},
		{gui = "MusicPlayer", panel = "MainPanel"},
		{gui = "InventorySystemGUI", panel = "MainPanel"},
	}
	
	for _, check in ipairs(uiChecks) do
		local ui = playerGui:FindFirstChild(check.gui)
		if ui then
			local panel = ui:FindFirstChild(check.panel) or ui:FindFirstChild("Frame") or ui:FindFirstChild("ShopPanel")
			if panel and panel:IsA("GuiObject") and panel.Visible then
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
local FishCaughtEvent = ReplicatedStorage:FindFirstChild("FishCaughtEvent")

if FishCaughtEvent then
	FishCaughtEvent.OnClientEvent:Connect(function(data)
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