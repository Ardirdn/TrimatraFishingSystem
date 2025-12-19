--[[
    CARRY CLIENT (DRAGGABLE + 2 REQUEST MODES)
    Place in StarterPlayerScripts/CarryClient
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Remotes
local CarryRemote = ReplicatedStorage:WaitForChild("CarryRemote")

-- Config
local SIT_R15_ID = 109869231937807
local SIT_R6_ID  = 116296618982747
local CARRY_R15_ID = 101810098714973
local CARRY_R6_ID  = 116589668947573
local REQUEST_TIMEOUT = 8
local HIDE_ON_PENDING = true
local MAX_CLICK_DISTANCE = 20

-- Player/UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ==================== COLORS ====================
local COLORS = {
	Background = Color3.fromRGB(25, 25, 30),
	Panel = Color3.fromRGB(30, 30, 35),
	Header = Color3.fromRGB(35, 35, 40),
	Button = Color3.fromRGB(45, 45, 50),
	ButtonHover = Color3.fromRGB(55, 55, 60),
	Accent = Color3.fromRGB(88, 101, 242),
	AccentHover = Color3.fromRGB(108, 121, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Success = Color3.fromRGB(67, 181, 129),
	SuccessHover = Color3.fromRGB(77, 191, 139),
	Danger = Color3.fromRGB(237, 66, 69),
	DangerHover = Color3.fromRGB(255, 86, 89),
	Border = Color3.fromRGB(50, 50, 55),
	Close = Color3.fromRGB(200, 60, 60),
	CloseHover = Color3.fromRGB(220, 80, 80),
}

-- ==================== HELPERS ====================
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

local function tweenButton(button, property, endValue, duration)
	local tween = TweenService:Create(button, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), {[property] = endValue})
	tween:Play()
	return tween
end

local function headshotUrl(userId, size)
	size = size or 180
	return ("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d"):format(userId, size, size)
end

local function getHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getAnimator(hum)
	return hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
end

local function rigIsR15(hum) 
	return hum and hum.RigType == Enum.HumanoidRigType.R15 
end

local function getHRP()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function targetIsCarried(pTarget)
	local char = pTarget.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp:FindFirstChild("CarryWeld") ~= nil
end

-- ==================== DRAGGABLE FUNCTION ====================
local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		local viewportSize = camera.ViewportSize

		-- Convert to scale
		local newX = startPos.X.Scale + (delta.X / viewportSize.X)
		local newY = startPos.Y.Scale + (delta.Y / viewportSize.Y)

		-- Clamp to screen bounds
		newX = math.clamp(newX, 0, 1 - frame.Size.X.Scale)
		newY = math.clamp(newY, 0, 1 - frame.Size.Y.Scale)

		frame.Position = UDim2.new(newX, 0, newY, 0)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- ==================== CREATE SCREEN GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GendongGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50
screenGui.Parent = playerGui

-- ==================== FRAME 1: SELECT/PROMPT/STATUS ====================
local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.Size = UDim2.new(0.156, 0, 0.278, 0) -- ~300x300 on 1920x1080
frame.Position = UDim2.new(0.75, 0, 0.35, 0) -- Kanan tengah agak atas
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = COLORS.Background
frame.BorderSizePixel = 0
frame.Visible = false
frame.Active = true -- Enable dragging
frame.Parent = screenGui

createCorner(12).Parent = frame
createStroke(COLORS.Border, 2).Parent = frame
makeDraggable(frame)

-- Drag indicator (optional visual cue)
local dragIndicator = Instance.new("Frame")
dragIndicator.Size = UDim2.new(0.15, 0, 0.015, 0)
dragIndicator.Position = UDim2.new(0.5, 0, 0.02, 0)
dragIndicator.AnchorPoint = Vector2.new(0.5, 0)
dragIndicator.BackgroundColor3 = COLORS.Border
dragIndicator.BorderSizePixel = 0
dragIndicator.Parent = frame

createCorner(10).Parent = dragIndicator

-- Close Button
local btnClose = Instance.new("TextButton")
btnClose.Name = "CloseButton"
btnClose.Size = UDim2.new(0.1, 0, 0.1, 0)
btnClose.Position = UDim2.new(0.88, 0, 0.02, 0)
btnClose.BackgroundColor3 = COLORS.Close
btnClose.BorderSizePixel = 0
btnClose.Text = "✕"
btnClose.Font = Enum.Font.GothamBold
btnClose.TextScaled = true
btnClose.TextColor3 = COLORS.Text
btnClose.AutoButtonColor = false
btnClose.Parent = frame

createCorner(6).Parent = btnClose

-- Avatar Image
local imgAvatar = Instance.new("ImageLabel")
imgAvatar.Name = "AvatarImage"
imgAvatar.Size = UDim2.new(0.267, 0, 0.267, 0)
imgAvatar.Position = UDim2.new(0.5, 0, 0.12, 0)
imgAvatar.AnchorPoint = Vector2.new(0.5, 0)
imgAvatar.BackgroundColor3 = COLORS.Panel
imgAvatar.BorderSizePixel = 0
imgAvatar.Image = ""
imgAvatar.Parent = frame

createCorner(40).Parent = imgAvatar
createStroke(COLORS.Border, 2).Parent = imgAvatar

-- Name Label
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0.933, 0, 0.083, 0)
nameLabel.Position = UDim2.new(0.5, 0, 0.41, 0)
nameLabel.AnchorPoint = Vector2.new(0.5, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = "Player Name"
nameLabel.TextColor3 = COLORS.Text
nameLabel.TextScaled = true
nameLabel.TextWrapped = true
nameLabel.TextXAlignment = Enum.TextXAlignment.Center
nameLabel.Parent = frame

-- Request to Carry Button
local btnCarry = Instance.new("TextButton")
btnCarry.Name = "CarryButton"
btnCarry.Size = UDim2.new(0.9, 0, 0.12, 0)
btnCarry.Position = UDim2.new(0.5, 0, 0.52, 0)
btnCarry.AnchorPoint = Vector2.new(0.5, 0)
btnCarry.BackgroundColor3 = COLORS.Accent
btnCarry.BorderSizePixel = 0
btnCarry.Text = "Request to Carry"
btnCarry.Font = Enum.Font.GothamBold
btnCarry.TextScaled = true
btnCarry.TextColor3 = COLORS.Text
btnCarry.AutoButtonColor = false
btnCarry.Parent = frame

createCorner(8).Parent = btnCarry

-- Request to be Carried Button
local btnBeCarried = Instance.new("TextButton")
btnBeCarried.Name = "BeCarriedButton"
btnBeCarried.Size = UDim2.new(0.9, 0, 0.12, 0)
btnBeCarried.Position = UDim2.new(0.5, 0, 0.66, 0)
btnBeCarried.AnchorPoint = Vector2.new(0.5, 0)
btnBeCarried.BackgroundColor3 = COLORS.Success
btnBeCarried.BorderSizePixel = 0
btnBeCarried.Text = "Request to be Carried"
btnBeCarried.Font = Enum.Font.GothamBold
btnBeCarried.TextScaled = true
btnBeCarried.TextColor3 = COLORS.Text
btnBeCarried.AutoButtonColor = false
btnBeCarried.Parent = frame

createCorner(8).Parent = btnBeCarried

-- Get Down Button
local btnDown = Instance.new("TextButton")
btnDown.Name = "TurunButton"
btnDown.Size = UDim2.new(0.9, 0, 0.12, 0)
btnDown.Position = UDim2.new(0.5, 0, 0.52, 0)
btnDown.AnchorPoint = Vector2.new(0.5, 0)
btnDown.BackgroundColor3 = COLORS.Danger
btnDown.BorderSizePixel = 0
btnDown.Text = "Get Down"
btnDown.Font = Enum.Font.GothamBold
btnDown.TextScaled = true
btnDown.TextColor3 = COLORS.Text
btnDown.AutoButtonColor = false
btnDown.Visible = false
btnDown.Parent = frame

createCorner(8).Parent = btnDown

-- Add Friend Button
local btnAdd = Instance.new("TextButton")
btnAdd.Name = "AddButton"
btnAdd.Size = UDim2.new(0.9, 0, 0.1, 0)
btnAdd.Position = UDim2.new(0.5, 0, 0.66, 0)
btnAdd.AnchorPoint = Vector2.new(0.5, 0)
btnAdd.BackgroundColor3 = COLORS.Accent
btnAdd.BorderSizePixel = 0
btnAdd.Text = "Add Friend"
btnAdd.Font = Enum.Font.Gotham
btnAdd.TextScaled = true
btnAdd.TextColor3 = COLORS.Text
btnAdd.AutoButtonColor = false
btnAdd.Visible = false
btnAdd.Active = false
btnAdd.Parent = frame

createCorner(8).Parent = btnAdd

-- ==================== FRAME 2: CARRIER UI ====================
local frame2 = Instance.new("Frame")
frame2.Name = "Frame2"
frame2.Size = UDim2.new(0.146, 0, 0.185, 0) -- ~280x200
frame2.Position = UDim2.new(0.5, 0, 0.85, 0)
frame2.AnchorPoint = Vector2.new(0.5, 0.5)
frame2.BackgroundColor3 = COLORS.Background
frame2.BorderSizePixel = 0
frame2.Visible = false
frame2.Active = true
frame2.Parent = screenGui

createCorner(12).Parent = frame2
createStroke(COLORS.Border, 2).Parent = frame2
makeDraggable(frame2)

-- Drag indicator
local dragIndicator2 = Instance.new("Frame")
dragIndicator2.Size = UDim2.new(0.15, 0, 0.02, 0)
dragIndicator2.Position = UDim2.new(0.5, 0, 0.02, 0)
dragIndicator2.AnchorPoint = Vector2.new(0.5, 0)
dragIndicator2.BackgroundColor3 = COLORS.Border
dragIndicator2.BorderSizePixel = 0
dragIndicator2.Parent = frame2

createCorner(10).Parent = dragIndicator2

-- Carrier Avatar
local cAvatar = Instance.new("ImageLabel")
cAvatar.Name = "AvatarImage"
cAvatar.Size = UDim2.new(0.214, 0, 0.3, 0)
cAvatar.Position = UDim2.new(0.5, 0, 0.08, 0)
cAvatar.AnchorPoint = Vector2.new(0.5, 0)
cAvatar.BackgroundColor3 = COLORS.Panel
cAvatar.BorderSizePixel = 0
cAvatar.Image = ""
cAvatar.Parent = frame2

createCorner(30).Parent = cAvatar
createStroke(COLORS.Border, 2).Parent = cAvatar

-- Carrier Name
local cName = Instance.new("TextLabel")
cName.Name = "NameLabel"
cName.Size = UDim2.new(0.9, 0, 0.1, 0)
cName.Position = UDim2.new(0.5, 0, 0.4, 0)
cName.AnchorPoint = Vector2.new(0.5, 0)
cName.BackgroundTransparency = 1
cName.Font = Enum.Font.GothamBold
cName.Text = "Carrying (0/0): Player"
cName.TextColor3 = COLORS.Text
cName.TextScaled = true
cName.TextWrapped = true
cName.TextXAlignment = Enum.TextXAlignment.Center
cName.Parent = frame2

-- Navigation Container
local navContainer = Instance.new("Frame")
navContainer.Size = UDim2.new(0.93, 0, 0.175, 0)
navContainer.Position = UDim2.new(0.5, 0, 0.52, 0)
navContainer.AnchorPoint = Vector2.new(0.5, 0)
navContainer.BackgroundTransparency = 1
navContainer.Parent = frame2

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.Padding = UDim.new(0, 5)
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Parent = navContainer

local btnLeft = Instance.new("TextButton")
btnLeft.Name = "LeftButton"
btnLeft.Size = UDim2.new(0.23, 0, 1, 0)
btnLeft.BackgroundColor3 = COLORS.Button
btnLeft.BorderSizePixel = 0
btnLeft.Text = "<"
btnLeft.Font = Enum.Font.GothamBold
btnLeft.TextScaled = true
btnLeft.TextColor3 = COLORS.Text
btnLeft.AutoButtonColor = false
btnLeft.LayoutOrder = 1
btnLeft.Parent = navContainer

createCorner(6).Parent = btnLeft

local btnPut = Instance.new("TextButton")
btnPut.Name = "LepasButton"
btnPut.Size = UDim2.new(0.44, 0, 1, 0)
btnPut.BackgroundColor3 = COLORS.Danger
btnPut.BorderSizePixel = 0
btnPut.Text = "Put Down"
btnPut.Font = Enum.Font.GothamBold
btnPut.TextScaled = true
btnPut.TextColor3 = COLORS.Text
btnPut.AutoButtonColor = false
btnPut.LayoutOrder = 2
btnPut.Parent = navContainer

createCorner(6).Parent = btnPut

local btnRight = Instance.new("TextButton")
btnRight.Name = "RightButton"
btnRight.Size = UDim2.new(0.23, 0, 1, 0)
btnRight.BackgroundColor3 = COLORS.Button
btnRight.BorderSizePixel = 0
btnRight.Text = ">"
btnRight.Font = Enum.Font.GothamBold
btnRight.TextScaled = true
btnRight.TextColor3 = COLORS.Text
btnRight.AutoButtonColor = false
btnRight.LayoutOrder = 3
btnRight.Parent = navContainer

createCorner(6).Parent = btnRight

-- Drop All Button
local btnDropAll = Instance.new("TextButton")
btnDropAll.Name = "DropAllButton"
btnDropAll.Size = UDim2.new(0.93, 0, 0.175, 0)
btnDropAll.Position = UDim2.new(0.5, 0, 0.77, 0)
btnDropAll.AnchorPoint = Vector2.new(0.5, 0)
btnDropAll.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
btnDropAll.BorderSizePixel = 0
btnDropAll.Text = "Drop All"
btnDropAll.Font = Enum.Font.GothamBold
btnDropAll.TextScaled = true
btnDropAll.TextColor3 = COLORS.Text
btnDropAll.AutoButtonColor = false
btnDropAll.Parent = frame2

createCorner(6).Parent = btnDropAll

-- ==================== HOVER EFFECTS ====================
local function setupButtonHover(button, normalColor, hoverColor)
	button.MouseEnter:Connect(function()
		tweenButton(button, "BackgroundColor3", hoverColor)
	end)
	button.MouseLeave:Connect(function()
		tweenButton(button, "BackgroundColor3", normalColor)
	end)
end

setupButtonHover(btnClose, COLORS.Close, COLORS.CloseHover)
setupButtonHover(btnCarry, COLORS.Accent, COLORS.AccentHover)
setupButtonHover(btnBeCarried, COLORS.Success, COLORS.SuccessHover)
setupButtonHover(btnDown, COLORS.Danger, COLORS.DangerHover)
setupButtonHover(btnAdd, COLORS.Accent, COLORS.AccentHover)
setupButtonHover(btnLeft, COLORS.Button, COLORS.ButtonHover)
setupButtonHover(btnRight, COLORS.Button, COLORS.ButtonHover)
setupButtonHover(btnPut, COLORS.Danger, COLORS.DangerHover)
setupButtonHover(btnDropAll, Color3.fromRGB(180, 50, 50), Color3.fromRGB(200, 70, 70))

-- ==================== REST OF LOGIC ====================

local function pointOverOurGui(px, py)
	local list = playerGui:GetGuiObjectsAtPosition(px, py)
	for _, o in ipairs(list) do
		if o == frame or o:IsDescendantOf(frame) or o == frame2 or o:IsDescendantOf(frame2) then 
			return true 
		end
	end
	return false
end

local function pickPlayerAt(px, py)
	if pointOverOurGui(px, py) then return nil end
	local ray = camera:ViewportPointToRay(px, py)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	if player.Character then table.insert(ignore, player.Character) end
	params.FilterDescendantsInstances = ignore
	local rc = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if not rc then return nil end
	local model = rc.Instance:FindFirstAncestorOfClass("Model")
	if not model then return nil end
	local hum = model:FindFirstChildOfClass("Humanoid"); if not hum then return nil end
	local pTarget = Players:GetPlayerFromCharacter(model)
	if not pTarget or pTarget == player then return nil end

	local myHRP = getHRP()
	local tHRP = pTarget.Character and pTarget.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP or not tHRP then return nil end
	if (myHRP.Position - tHRP.Position).Magnitude > MAX_CLICK_DISTANCE then
		return nil
	end

	return pTarget
end

-- Animation
local sitTrack, carryTrack
local function playSit()
	local hum = getHumanoid(); if not hum then return end
	hum.Sit = true
	local useId = rigIsR15(hum) and SIT_R15_ID or SIT_R6_ID
	if useId == 0 then return end
	local animator = getAnimator(hum)
	if sitTrack then sitTrack:Stop(0.15) end
	local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..tostring(useId)
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if ok and track then
		sitTrack = track; sitTrack.Priority = Enum.AnimationPriority.Action; sitTrack.Looped = true; sitTrack:Play(0.2)
	end
end
local function stopSit() 
	local hum = getHumanoid(); 
	if sitTrack then sitTrack:Stop(0.2); sitTrack = nil end 
	if hum then hum.Sit = false end 
end
local function playCarry()
	local hum = getHumanoid(); if not hum then return end
	local useId = rigIsR15(hum) and CARRY_R15_ID or CARRY_R6_ID
	if useId == 0 then return end
	local animator = getAnimator(hum)
	if carryTrack then carryTrack:Stop(0.1) end
	local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..tostring(useId)
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if ok and track then
		carryTrack = track; carryTrack.Priority = Enum.AnimationPriority.Action; carryTrack.Looped = true; carryTrack:Play(0.2)
	end
end
local function stopCarry() if carryTrack then carryTrack:Stop(0.2); carryTrack = nil end end

-- State
local uiMode = "idle"
local selectedTargetId, selectedTargetName, lastRequesterId, currentOtherId = nil, nil, nil, nil
local carriedList, carriedIndex = {}, 1
local overlayFromStatus, isCarried = false, false
local waitingForApproval, waitToken = false, 0
local addBtnMode = "friend"
local currentCarrierId, currentCarrierName = nil, nil
local keepUiConn = nil

-- Block jump AND trigger Get Down when pressed
local jumpBlockConn = nil
local function startBlockingJump()
	if jumpBlockConn then jumpBlockConn:Disconnect() end
	jumpBlockConn = UserInputService.JumpRequest:Connect(function()
		local h = getHumanoid()
		if h then h.Jump = false end
		
		-- ✅ Trigger Get Down when jump is pressed while being carried
		if isCarried then
			CarryRemote:FireServer("Stop", {})
		end
	end)
end
local function stopBlockingJump()
	if jumpBlockConn then jumpBlockConn:Disconnect(); jumpBlockConn = nil end
end

-- Add/Decline
local function hideAddBtn() 
	addBtnMode="friend"
	btnAdd.Visible=false
	btnAdd.Active=false
	btnAdd.AutoButtonColor=false
	btnAdd.BackgroundColor3=COLORS.Accent
end
local function setAddBtnEnabled(text) 
	addBtnMode="friend"
	btnAdd.Visible=true
	btnAdd.Text=text or "Add Friend"
	btnAdd.Active=true
	btnAdd.AutoButtonColor=true
	btnAdd.BackgroundColor3=COLORS.Accent
end
local function setAddBtnDecline() 
	addBtnMode="decline"
	btnAdd.Visible=true
	btnAdd.Text="No"
	btnAdd.Active=true
	btnAdd.AutoButtonColor=true
	btnAdd.BackgroundColor3=COLORS.Danger
end
local function setAddButtonFor(userId)
	if addBtnMode=="decline" then return end
	currentOtherId = userId
	if not userId or userId == player.UserId then hideAddBtn(); return end
	local okFriend, isFriend = pcall(function() return player:IsFriendsWith(userId) end)
	if okFriend and isFriend then hideAddBtn(); return end
	local other = Players:GetPlayerByUserId(userId)
	if other then
		local okStatus, status = pcall(function() return player:GetFriendStatus(other) end)
		if okStatus then
			if status == Enum.FriendStatus.Friend then hideAddBtn(); return end
			if HIDE_ON_PENDING and (status == Enum.FriendStatus.FriendRequestSent or status == Enum.FriendStatus.FriendRequestReceived) then hideAddBtn(); return end
		end
	end
	setAddBtnEnabled("Add Friend")
end
local function requestFriend(userId)
	if not userId then return end
	local t = Players:GetPlayerByUserId(userId); if not t then hideAddBtn(); return end
	local ok = pcall(function() player:RequestFriendship(t) end)
	if ok and HIDE_ON_PENDING then hideAddBtn()
	else btnAdd.Text = ok and "Request sent" or "Request failed"; btnAdd.Active=false; btnAdd.AutoButtonColor=false; task.delay(1.4, function() if currentOtherId and frame.Visible then setAddButtonFor(currentOtherId) end end) end
end

task.spawn(function()
	while true do task.wait(2); if frame.Visible and currentOtherId and addBtnMode~="decline" then setAddButtonFor(currentOtherId) end end
end)

-- Modes
local function setModeSelect(pTarget)
	uiMode = "select"
	selectedTargetId = pTarget.UserId
	selectedTargetName = pTarget.DisplayName
	lastRequesterId = nil
	addBtnMode = "friend"
	nameLabel.Text = ("Target: %s"):format(selectedTargetName)
	imgAvatar.Image = headshotUrl(pTarget.UserId, 180)

	-- Show both buttons
	btnCarry.Text = "Request to Carry"
	btnCarry.Visible = true
	btnCarry.Active = true
	btnCarry.AutoButtonColor = true
	btnCarry.BackgroundColor3 = COLORS.Accent

	btnBeCarried.Visible = true
	btnBeCarried.Active = true
	btnBeCarried.AutoButtonColor = true

	btnClose.Visible = true
	btnDown.Visible = false
	btnAdd.Visible = false
	frame.Visible = true
end

local function setModePrompt(fromId, messageOrName)
	uiMode = "prompt"
	selectedTargetId, selectedTargetName = nil, nil
	lastRequesterId = fromId

	-- Check if messageOrName is full message or just name
	if messageOrName and messageOrName:find("Accept%?") then
		-- It's a full message
		nameLabel.Text = messageOrName
	else
		-- It's just a name, use default template
		nameLabel.Text = ("%s wants to carry you. Accept?"):format(messageOrName or "Someone")
	end

	imgAvatar.Image = headshotUrl(fromId, 180)

	btnCarry.Text = "Yes"
	btnCarry.Visible = true
	btnCarry.Active = true
	btnCarry.AutoButtonColor = true
	btnCarry.BackgroundColor3 = COLORS.Success

	btnBeCarried.Visible = false
	btnClose.Visible = true
	btnDown.Visible = false
	setAddBtnDecline()
	frame.Visible = true
end


local function ensureStatusVisible()
	if not isCarried or not currentCarrierId then return end
	if uiMode ~= "status" then uiMode = "status" end
	nameLabel.Text = "Carried by: " .. (currentCarrierName or "Player")
	imgAvatar.Image = headshotUrl(currentCarrierId, 180)
	btnDown.Visible = true
	btnDown.Text = "Get Down"
	btnCarry.Visible = false
	btnBeCarried.Visible = false
	btnClose.Visible = false
	setAddButtonFor(currentCarrierId)
	frame.Visible = true
end

local function startKeepUi()
	if keepUiConn then return end
	keepUiConn = RunService.Heartbeat:Connect(function()
		if isCarried then
			ensureStatusVisible()
		else
			if keepUiConn then keepUiConn:Disconnect(); keepUiConn = nil end
		end
	end)
end
local function stopKeepUi()
	if keepUiConn then keepUiConn:Disconnect(); keepUiConn = nil end
end

local function setModeStatusCarried(carrierName, carrierId)
	currentCarrierId = carrierId
	currentCarrierName = carrierName
	isCarried = true
	ensureStatusVisible()
	startKeepUi()
	startBlockingJump()
end

local function resetFrame()
	uiMode = "idle"
	selectedTargetId, selectedTargetName, lastRequesterId, currentOtherId = nil, nil, nil, nil
	waitingForApproval = false
	btnDown.Visible = false
	hideAddBtn()
	frame.Visible = false
end

-- World Tap
local function handleWorldTap(px, py)
	if uiMode == "prompt" or waitingForApproval then return end
	if pointOverOurGui(px, py) then return end
	if isCarried then ensureStatusVisible(); return end
	local pTarget = pickPlayerAt(px, py)
	if pTarget then overlayFromStatus = frame2.Visible; setModeSelect(pTarget) end
end

-- Waiting
local function stopWaitTimer()
	waitingForApproval = false
	waitToken += 1
	if uiMode == "select" then
		btnCarry.Text = "Request to Carry"
		btnCarry.Active = true
		btnCarry.AutoButtonColor = true
		btnCarry.BackgroundColor3 = COLORS.Accent
		btnBeCarried.Active = true
		btnBeCarried.AutoButtonColor = true
		if selectedTargetName then nameLabel.Text = ("Target: %s"):format(selectedTargetName) end
	end
end
local function startWaitTimer()
	waitingForApproval = true
	btnCarry.Text = "Waiting (...)"
	btnCarry.Active = false
	btnCarry.AutoButtonColor = false
	btnCarry.BackgroundColor3 = COLORS.Button
	btnBeCarried.Active = false
	btnBeCarried.AutoButtonColor = false
	local myToken = waitToken + 1; waitToken = myToken
	local endTime = os.clock() + REQUEST_TIMEOUT
	task.spawn(function()
		while waitingForApproval and waitToken == myToken do
			local left = math.max(0, math.ceil(endTime - os.clock()))
			if uiMode == "select" then
				btnCarry.Text = string.format("Waiting (%ds)", left)
				if selectedTargetName then
					nameLabel.Text = ("Awaiting %s's approval (%ds)"):format(selectedTargetName, left)
				end
			end
			if left <= 0 then break end
			task.wait(0.2)
		end
	end)
end
local function flashAndClose(msg)
	stopWaitTimer()
	if uiMode == "select" then
		btnCarry.Text = msg
		task.delay(0.8, function()
			if overlayFromStatus then
				overlayFromStatus = false
				frame2.Visible = (#carriedList > 0 and not isCarried)
				frame.Visible = false
			else
				frame.Visible = false
			end
		end)
	else
		if overlayFromStatus then
			overlayFromStatus = false
			frame2.Visible = (#carriedList > 0 and not isCarried)
		end
		frame.Visible = false
	end
end

-- Carrier UI
local function ensureCarrierAnim()
	if (#carriedList > 0) and (not isCarried) then 
		if not carryTrack then playCarry() end 
	else 
		stopCarry() 
	end
end
local function refreshCarrierUI()
	local count = #carriedList
	if count <= 0 then frame2.Visible = false; stopCarry(); return end
	if carriedIndex < 1 then carriedIndex = 1 end
	if carriedIndex > count then carriedIndex = count end
	local item = carriedList[carriedIndex]
	cName.Text = string.format("Carrying (%d/%d): %s", carriedIndex, count, item.name or "Player")
	cAvatar.Image = headshotUrl(item.id, 180)
	frame2.Visible = not isCarried
	ensureCarrierAnim()
end
local function addCarried(id, name)
	for _, it in ipairs(carriedList) do 
		if it.id == id then 
			it.name = name
			refreshCarrierUI()
			return 
		end 
	end
	table.insert(carriedList, {id=id, name=name})
	carriedIndex = #carriedList
	refreshCarrierUI()
end
local function removeCarried(id)
	local idx
	for i, it in ipairs(carriedList) do 
		if it.id == id then idx = i break end 
	end
	if idx then table.remove(carriedList, idx) end
	if carriedIndex > #carriedList then carriedIndex = #carriedList end
	refreshCarrierUI()
end
local function setCarriedListFromSnapshot(list)
	carriedList = {}
	for _, it in ipairs(list or {}) do 
		table.insert(carriedList, {id = it.id, name = it.name}) 
	end
	if carriedIndex > #carriedList then carriedIndex = #carriedList end
	if carriedIndex < 1 then carriedIndex = 1 end
	refreshCarrierUI()
end

-- Input
UserInputService.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = UserInputService:GetMouseLocation()
		handleWorldTap(pos.X, pos.Y)
	end
end)
UserInputService.TouchTap:Connect(function(positions, processedByUI)
	if processedByUI then return end
	local pos = positions and positions[1]
	if not pos then return end
	handleWorldTap(pos.X, pos.Y)
end)
UserInputService.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.Touch then
		if gp then return end
		local pos = input.Position
		if pos then handleWorldTap(pos.X, pos.Y) end
	end
end)

-- UPDATE BUTTON HANDLERS (GANTI YANG LAMA)

btnCarry.MouseButton1Click:Connect(function()
	if uiMode == "select" then
		if not selectedTargetId then return end
		startWaitTimer()
		-- Request to CARRY target (we become carrier)
		CarryRemote:FireServer("Request", {
			targetId = selectedTargetId,
			requestType = "carry"  -- NEW FLAG
		})
	elseif uiMode == "prompt" then
		if not lastRequesterId then return end
		CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = true})
		resetFrame()
	end
end)

btnBeCarried.MouseButton1Click:Connect(function()
	if uiMode == "select" then
		if not selectedTargetId then return end
		startWaitTimer()
		-- Request to BE CARRIED by target (target becomes carrier)
		CarryRemote:FireServer("Request", {
			targetId = selectedTargetId,
			requestType = "be_carried"  -- NEW FLAG
		})
	end
end)


btnClose.MouseButton1Click:Connect(function()
	if uiMode == "prompt" and lastRequesterId then
		CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = false})
	end
	if overlayFromStatus then
		overlayFromStatus = false
		frame2.Visible = (#carriedList > 0 and not isCarried)
		frame.Visible = false
	else
		resetFrame()
	end
end)

btnDown.MouseButton1Click:Connect(function() 
	CarryRemote:FireServer("Stop", {}) 
end)

btnAdd.MouseButton1Click:Connect(function()
	if addBtnMode == "decline" then
		if uiMode == "prompt" and lastRequesterId then 
			CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = false})
			resetFrame() 
		end
	else
		if currentOtherId then requestFriend(currentOtherId) end
	end
end)

btnRight.MouseButton1Click:Connect(function() 
	if #carriedList == 0 then return end 
	carriedIndex += 1
	if carriedIndex > #carriedList then carriedIndex = 1 end 
	refreshCarrierUI() 
end)

btnLeft.MouseButton1Click:Connect(function() 
	if #carriedList == 0 then return end 
	carriedIndex -= 1
	if carriedIndex < 1 then carriedIndex = #carriedList end 
	refreshCarrierUI() 
end)

btnPut.MouseButton1Click:Connect(function() 
	if #carriedList == 0 then return end 
	local item = carriedList[carriedIndex]
	if item and item.id then 
		CarryRemote:FireServer("Stop", {targetId = item.id}) 
	end 
end)

btnDropAll.MouseButton1Click:Connect(function()
	-- Drop all carried players at once
	CarryRemote:FireServer("Stop", {})
end)

-- Remote Handlers (COMPLETE - WITH START HANDLER)
CarryRemote.OnClientEvent:Connect(function(action, data)
	if action == "Prompt" then
		local customMsg = data.customMessage
		if customMsg then
			-- Use custom message from server
			setModePrompt(data.fromId, customMsg)
		else
			-- Fallback to default message
			setModePrompt(data.fromId, data.fromName)
		end

		-- ✅ CRITICAL FIX: ADD THIS "Start" HANDLER
	elseif action == "Start" then
		stopWaitTimer()
		if data.youAreCarrier then
			-- We are carrying someone
			addCarried(data.targetId, data.targetName)
			if not isCarried then 
				frame2.Visible = true
				frame.Visible = false 
			end
			if #carriedList > 0 and not isCarried then 
				if not carryTrack then playCarry() end 
			end
		else
			-- We are being carried
			setModeStatusCarried(data.carrierName, data.carrierId)
			playSit()
			stopCarry()
			frame2.Visible = false
		end

	elseif action == "End" then
		stopWaitTimer()
		if data.youAreCarrier then
			if data.removedId then removeCarried(data.removedId) end
			if not isCarried then
				if #carriedList > 0 then refreshCarrierUI() else frame2.Visible = false end
			else
				frame2.Visible = false
			end
			if #carriedList > 0 and not isCarried then if not carryTrack then playCarry() end else stopCarry() end
		else
			isCarried = false
			currentCarrierId, currentCarrierName = nil, nil
			stopKeepUi()
			stopSit()
			stopBlockingJump()
			resetFrame()
		end

	elseif action == "CarrierList" then
		setCarriedListFromSnapshot(data.list or {})
		if not isCarried then 
			frame2.Visible = (#carriedList > 0)
			if #carriedList > 0 then if not carryTrack then playCarry() end else stopCarry() end
		else 
			frame2.Visible = false
			stopCarry() 
		end

	elseif action == "Declined" then flashAndClose("Declined")
	elseif action == "TooFar" then flashAndClose("Too far")
	elseif action == "Busy" then flashAndClose("Busy")
	elseif action == "Failed" then flashAndClose("Failed")
	elseif action == "RequestExpired" then flashAndClose("Timed out")
	elseif action == "PromptExpire" or action == "PromptClose" then
		if overlayFromStatus then 
			overlayFromStatus=false
			frame.Visible=false
			frame2.Visible=(#carriedList>0 and not isCarried) 
		else 
			resetFrame() 
		end
	elseif action == "Limit" then flashAndClose("Limit")
	end
end)


-- Respawn Reset
player.CharacterAdded:Connect(function()
	if sitTrack then sitTrack:Stop(0.1); sitTrack = nil end
	if carryTrack then carryTrack:Stop(0.1); carryTrack = nil end
	stopKeepUi()
	stopBlockingJump()
	isCarried = false
	waitingForApproval = false
	overlayFromStatus = false
	currentCarrierId, currentCarrierName = nil, nil
	carriedList = {}
	carriedIndex = 1
	frame.Visible = false
	frame2.Visible = false
	btnCarry.Text = "Request to Carry"
	btnCarry.Active = true
	btnCarry.AutoButtonColor = true
	btnCarry.BackgroundColor3 = COLORS.Accent
end)

print("✅ [CARRY CLIENT] Loaded with draggable UI & dual request modes")