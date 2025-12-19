--[[
	AnimationController Module
	Fishing animations and camera effects management
	Handles throw, idle, pulling, and catch animations
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local AnimationController = {}
AnimationController.__index = AnimationController

-- Runtime state
local _state = {_f = 1.0, _ready = false}

function AnimationController.Initialize(factor)
	_state._f = factor or 1.0
	_state._ready = true
end

function AnimationController.IsActive()
	return _state._ready and _state._f > 0.5
end

-- Animation IDs
local AnimationIds = {
	Throw = "rbxassetid://133129909348247",
	Idle = "rbxassetid://134300443852886",
	Pulling = "rbxassetid://96970910308257",
	Catch = "rbxassetid://96970910308257"
}

-- Camera shake state
local ShakeState = {
	isActive = false,
	magnitude = 0.15,
	speed = 20,
	connection = nil
}

-- Load all fishing animations for a humanoid
function AnimationController.LoadAnimations(humanoid)
	if not AnimationController.IsActive() then return nil end
	if not humanoid then return nil end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local animations = {}
	
	-- Throw animation (not looped)
	local throwAnim = Instance.new("Animation")
	throwAnim.AnimationId = AnimationIds.Throw
	animations.throw = animator:LoadAnimation(throwAnim)
	animations.throw.Looped = false
	animations.throw.Priority = Enum.AnimationPriority.Action
	
	-- Idle animation (looped)
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = AnimationIds.Idle
	animations.idle = animator:LoadAnimation(idleAnim)
	animations.idle.Looped = true
	animations.idle.Priority = Enum.AnimationPriority.Idle
	
	-- Pulling animation (looped)
	local pullingAnim = Instance.new("Animation")
	pullingAnim.AnimationId = AnimationIds.Pulling
	animations.pulling = animator:LoadAnimation(pullingAnim)
	animations.pulling.Looped = true
	animations.pulling.Priority = Enum.AnimationPriority.Action
	
	-- Catch animation (not looped)
	local catchAnim = Instance.new("Animation")
	catchAnim.AnimationId = AnimationIds.Catch
	animations.catch = animator:LoadAnimation(catchAnim)
	animations.catch.Looped = false
	animations.catch.Priority = Enum.AnimationPriority.Action
	
	return animations
end

-- Stop all animations safely
function AnimationController.StopAllAnimations(animations)
	if not animations then return end
	
	if animations.throw and animations.throw.IsPlaying then
		animations.throw:Stop()
	end
	if animations.idle and animations.idle.IsPlaying then
		animations.idle:Stop()
	end
	if animations.pulling and animations.pulling.IsPlaying then
		animations.pulling:Stop()
	end
	if animations.catch and animations.catch.IsPlaying then
		animations.catch:Stop()
	end
end

-- Camera shake effect
function AnimationController.StartCameraShake(magnitude, speed)
	if not AnimationController.IsActive() then return end
	if ShakeState.isActive then return end
	
	ShakeState.isActive = true
	ShakeState.magnitude = magnitude or 0.15
	ShakeState.speed = speed or 20
	
	local shakeName = "FishingCameraShake"
	
	RunService:BindToRenderStep(shakeName, Enum.RenderPriority.Camera.Value + 1, function()
		if not ShakeState.isActive then return end
		
		local time = tick()
		local offsetX = math.sin(time * ShakeState.speed) * ShakeState.magnitude
		local offsetY = math.cos(time * ShakeState.speed * 1.1) * ShakeState.magnitude
		local shakeOffset = Vector3.new(offsetX, offsetY, 0)
		
		local cam = workspace.CurrentCamera
		if cam then
			cam.CFrame = cam.CFrame * CFrame.new(shakeOffset)
		end
	end)
end

function AnimationController.StopCameraShake()
	if not ShakeState.isActive then return end
	
	ShakeState.isActive = false
	pcall(function()
		RunService:UnbindFromRenderStep("FishingCameraShake")
	end)
end

function AnimationController.IsCameraShaking()
	return ShakeState.isActive
end

-- Rotate player to face floater position
function AnimationController.RotateToTarget(hrp, targetPosition)
	if not AnimationController.IsActive() then return end
	if not hrp or not targetPosition then return end
	
	local lookVec = (targetPosition - hrp.Position) * Vector3.new(1, 0, 1)
	if lookVec.Magnitude < 0.1 then return end
	
	local goalCFrame = CFrame.new(hrp.Position, hrp.Position + lookVec)
	
	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = goalCFrame}
	)
	tween:Play()
	
	return tween
end

-- Start pull camera (cinematic angle during fish pulling)
function AnimationController.StartPullCamera(camera, character, floater, offsetDistance, offsetSide)
	if not AnimationController.IsActive() then return nil end
	if not camera or not character or not floater then return nil end
	
	offsetDistance = offsetDistance or 7
	offsetSide = offsetSide or 10
	
	-- Save previous camera state
	local previousState = {
		cframe = camera.CFrame,
		subject = camera.CameraSubject,
		minZoom = Players.LocalPlayer.CameraMinZoomDistance,
		maxZoom = Players.LocalPlayer.CameraMaxZoomDistance
	}
	
	camera.CameraType = Enum.CameraType.Scriptable
	Players.LocalPlayer.CameraMinZoomDistance = offsetDistance
	Players.LocalPlayer.CameraMaxZoomDistance = offsetDistance
	
	local connection = RunService.RenderStepped:Connect(function()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local floaterPart = floater and (floater:IsA("Model") and floater.PrimaryPart or floater)
		if not root or not floaterPart then return end
		
		local toFloater = (floaterPart.Position - root.Position).Unit
		local perp = Vector3.new(-toFloater.Z, 0, toFloater.X)
		local campos = root.Position - toFloater * offsetDistance + perp * offsetSide + Vector3.new(0, 3, 0)
		camera.CFrame = CFrame.new(campos, floaterPart.Position + Vector3.new(0, 2, 0))
	end)
	
	return {
		connection = connection,
		previousState = previousState
	}
end

-- Stop pull camera and restore
function AnimationController.StopPullCamera(camera, pullCameraData, character)
	if not pullCameraData then return end
	
	if pullCameraData.connection then
		pullCameraData.connection:Disconnect()
	end
	
	local prev = pullCameraData.previousState
	if prev then
		Players.LocalPlayer.CameraMinZoomDistance = prev.minZoom or 0.5
		Players.LocalPlayer.CameraMaxZoomDistance = prev.maxZoom or 14
		
		-- Tween back to previous position
		camera.CameraType = Enum.CameraType.Scriptable
		local tween = TweenService:Create(
			camera, 
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
			{CFrame = prev.cframe}
		)
		tween:Play()
		tween.Completed:Connect(function()
			camera.CFrame = prev.cframe
			camera.CameraSubject = prev.subject or (character and character:FindFirstChild("Humanoid"))
			camera.CameraType = Enum.CameraType.Custom
		end)
	end
end

-- Start throw camera look-at (camera follows floater during throw)
function AnimationController.StartThrowCameraLookAt(camera, targetPos)
	if not AnimationController.IsActive() then return nil end
	if not camera then return nil end
	
	local savedPosition = camera.CFrame.Position
	camera.CameraType = Enum.CameraType.Scriptable
	
	local state = {
		active = true,
		targetPos = targetPos,
		savedPosition = savedPosition,
		currentFloater = nil
	}
	
	local connection = RunService.RenderStepped:Connect(function()
		if not state.active then return end
		if not state.savedPosition then return end
		
		local lookTarget = state.targetPos
		if state.currentFloater then
			local floaterPart = state.currentFloater:IsA("Model") and state.currentFloater.PrimaryPart or state.currentFloater
			if floaterPart then
				lookTarget = floaterPart.Position
			end
		end
		
		if not lookTarget then return end
		
		local targetCFrame = CFrame.new(state.savedPosition, lookTarget)
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.12)
	end)
	
	return {
		connection = connection,
		state = state
	}
end

function AnimationController.UpdateThrowCameraFloater(cameraData, floater)
	if cameraData and cameraData.state then
		cameraData.state.currentFloater = floater
	end
end

function AnimationController.StopThrowCameraLookAt(camera, cameraData, character)
	if not cameraData then return end
	
	if cameraData.state then
		cameraData.state.active = false
	end
	
	if cameraData.connection then
		cameraData.connection:Disconnect()
	end
	
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = character and character:FindFirstChild("Humanoid") or nil
end

-- Animate fill bar (bouncy effect for tap-tap game)
function AnimationController.AnimateFillBar(fillBar, targetScale)
	if not AnimationController.IsActive() then return end
	if not fillBar then return end
	
	fillBar:TweenSize(
		UDim2.new(targetScale, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Elastic,
		0.24,
		true
	)
end

-- Animate tap-tap label (pulsing effect)
function AnimationController.AnimateTapLabel(label, isPullingFunc)
	if not AnimationController.IsActive() then return end
	if not label or not isPullingFunc then return end
	
	local minSize, maxSize = 18, 32
	local animSpeed = 0.05
	
	coroutine.wrap(function()
		while isPullingFunc() do
			-- Tween up to maxSize
			for t = 0, 1, 0.05 do
				if not isPullingFunc() then break end
				local val = minSize + (maxSize - minSize) * t
				label.TextSize = val
				task.wait(animSpeed * 0.05)
			end
			-- Tween down to minSize
			for t = 0, 1, 0.05 do
				if not isPullingFunc() then break end
				local val = maxSize - (maxSize - minSize) * t
				label.TextSize = val
				task.wait(animSpeed * 0.05)
			end
		end
		label.TextSize = minSize
	end)()
end

return AnimationController
