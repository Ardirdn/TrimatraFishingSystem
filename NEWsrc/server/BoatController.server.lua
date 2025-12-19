--[[
	BOAT CONTROLLER SERVER
	Handles boat access based on player titles
	Players without correct titles will be thrown from boats
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent:WaitForChild("DataHandler"))
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Create remotes folder
local boatRemotes = ReplicatedStorage:FindFirstChild("BoatRemotes")
if not boatRemotes then
	boatRemotes = Instance.new("Folder")
	boatRemotes.Name = "BoatRemotes"
	boatRemotes.Parent = ReplicatedStorage
end

local openShopGamepassEvent = boatRemotes:FindFirstChild("OpenShopGamepassTab")
if not openShopGamepassEvent then
	openShopGamepassEvent = Instance.new("RemoteEvent")
	openShopGamepassEvent.Name = "OpenShopGamepassTab"
	openShopGamepassEvent.Parent = boatRemotes
end

-- Find notification system
local notificationComm = ReplicatedStorage:FindFirstChild("NotificationComm")
local showNotificationEvent = notificationComm and notificationComm:FindFirstChild("ShowNotification")

-- Title remotes for listening to title changes
local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
local equipTitleEvent = titleRemotes and titleRemotes:FindFirstChild("EquipTitle")
local unequipTitleEvent = titleRemotes and titleRemotes:FindFirstChild("UnequipTitle")

-- State tracking
local boatInitialPositions = {}
local boatResetTimers = {}
local boatConnections = {}

-- Config
local RESET_DELAY = 5
local THROW_DISTANCE = 5
local THROW_HEIGHT = 3

-- Check if player has boat access based on title
local function hasBoatAccess(player)
	if not player or not player.Parent then
		return false
	end
	
	local allowedTitles = TitleConfig.AccessRules and TitleConfig.AccessRules["BoatAccess"]
	if not allowedTitles then
		return true -- If no access rules defined, allow everyone
	end
	
	local data = DataHandler:GetData(player)
	if not data then
		return false
	end
	
	local playerTitle = data.EquippedTitle or data.Title or "Pengunjung"
	
	for _, title in ipairs(allowedTitles) do
		if playerTitle == title then
			return true
		end
	end
	
	return false
end

-- Send notification to player
local function sendNotification(player, message, notifType, icon)
	if showNotificationEvent and player and player.Parent then
		pcall(function()
			showNotificationEvent:FireClient(player, {
				Message = message,
				Type = notifType or "error",
				Duration = 5,
				Icon = icon or "⛵"
			})
		end)
	end
end

-- Throw player from boat
local function throwPlayer(player, seat)
	if not player or not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then
		return
	end
	
	local throwDirection = rootPart.CFrame.LookVector
	local throwStartPos = rootPart.Position
	
	-- Remove seat weld
	local seatWeld = nil
	for _, obj in ipairs(player.Character:GetDescendants()) do
		if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
			if obj.Name == "SeatWeld" then
				seatWeld = obj
				break
			end
		end
	end
	
	if not seatWeld and seat then
		for _, obj in ipairs(seat:GetChildren()) do
			if (obj:IsA("Weld") or obj:IsA("WeldConstraint")) and obj.Name == "SeatWeld" then
				seatWeld = obj
				break
			end
		end
	end
	
	if seatWeld then
		seatWeld:Destroy()
	end
	
	humanoid.Sit = false
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	
	task.wait()
	if humanoid.SeatPart then
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		
		for _, obj in ipairs(player.Character:GetDescendants()) do
			if (obj:IsA("Weld") or obj:IsA("WeldConstraint")) and obj.Name == "SeatWeld" then
				obj:Destroy()
			end
		end
	end
	
	sendNotification(player, "🚫 Kamu tidak mempunyai akses ke boat! Beli gamepass untuk akses.", "error", "⛵")
	
	-- Open shop gamepass tab
	if openShopGamepassEvent and player and player.Parent then
		pcall(function()
			openShopGamepassEvent:FireClient(player)
		end)
	end
	
	task.wait(0.1)
	
	-- Throw player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		
		local newPosition = throwStartPos + (throwDirection * THROW_DISTANCE) + Vector3.new(0, THROW_HEIGHT, 0)
		hrp.CFrame = CFrame.new(newPosition, newPosition + throwDirection)
		
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = (throwDirection * 30) + Vector3.new(0, 20, 0)
		bv.Parent = hrp
		
		task.delay(0.3, function()
			if bv and bv.Parent then
				bv:Destroy()
			end
		end)
	end
end

-- Save boat initial position
local function saveBoatInitialPosition(boat)
	if boatInitialPositions[boat] then
		return
	end
	
	local primaryPart = boat.PrimaryPart or boat:FindFirstChild("Drive") or boat:FindFirstChild("Body")
	if primaryPart then
		boatInitialPositions[boat] = primaryPart.CFrame
	end
end

-- Reset boat position
local function resetBoatPosition(boat)
	if not boatInitialPositions[boat] then
		return
	end
	
	local driverSeat = boat:FindFirstChild("Drive")
	local passengerSeat = boat:FindFirstChild("Seat")
	
	if (driverSeat and driverSeat.Occupant) or (passengerSeat and passengerSeat.Occupant) then
		return
	end
	
	local primaryPart = boat.PrimaryPart or boat:FindFirstChild("Drive") or boat:FindFirstChild("Body")
	if primaryPart and boat:IsA("Model") then
		local originalCFrame = boatInitialPositions[boat]
		
		if boat.PrimaryPart then
			boat:SetPrimaryPartCFrame(originalCFrame)
		else
			local currentCFrame = primaryPart.CFrame
			local offset = currentCFrame:Inverse() * originalCFrame
			
			for _, part in ipairs(boat:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CFrame = offset * part.CFrame
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end
end

-- Timer management
local function startResetTimer(boat)
	if boatResetTimers[boat] then
		task.cancel(boatResetTimers[boat])
		boatResetTimers[boat] = nil
	end
	
	boatResetTimers[boat] = task.delay(RESET_DELAY, function()
		boatResetTimers[boat] = nil
		resetBoatPosition(boat)
	end)
end

local function cancelResetTimer(boat)
	if boatResetTimers[boat] then
		task.cancel(boatResetTimers[boat])
		boatResetTimers[boat] = nil
	end
end

-- Proximity prompt management
local function setProximityPromptEnabled(boat, enabled)
	local body = boat:FindFirstChild("Body")
	if body then
		local prompt = body:FindFirstChild("ProximityPrompt")
		if prompt then
			prompt.Enabled = enabled
		end
	end
end

-- Seat occupant handler
local function onSeatOccupantChanged(seat, boat)
	return function()
		local occupant = seat.Occupant
		
		if occupant then
			cancelResetTimer(boat)
			
			local player = Players:GetPlayerFromCharacter(occupant.Parent)
			
			if player then
				local hasAccess = hasBoatAccess(player)
				
				if not hasAccess then
					task.defer(function()
						throwPlayer(player, seat)
					end)
				else
					setProximityPromptEnabled(boat, false)
				end
			end
		else
			local driverSeat = boat:FindFirstChild("Drive")
			local passengerSeat = boat:FindFirstChild("Seat")
			
			local driverOccupied = driverSeat and driverSeat.Occupant
			local passengerOccupied = passengerSeat and passengerSeat.Occupant
			
			if not driverOccupied and not passengerOccupied then
				startResetTimer(boat)
				setProximityPromptEnabled(boat, true)
			end
		end
	end
end

-- Setup proximity prompt
local function setupProximityPrompt(boat)
	local body = boat:FindFirstChild("Body")
	if not body then return end
	
	local prompt = body:FindFirstChild("ProximityPrompt")
	if not prompt then return end
	
	local conn = prompt.Triggered:Connect(function(player)
		local hasAccess = hasBoatAccess(player)
		
		if not hasAccess then
			sendNotification(player, "🚫 Kamu tidak mempunyai akses ke boat! Beli gamepass untuk akses.", "error", "⛵")
			
			if openShopGamepassEvent and player and player.Parent then
				pcall(function()
					openShopGamepassEvent:FireClient(player)
				end)
			end
			return
		end
		
		local driverSeat = boat:FindFirstChild("Drive")
		local passengerSeat = boat:FindFirstChild("Seat")
		
		if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
			if driverSeat and not driverSeat.Occupant then
				driverSeat:Sit(player.Character.Humanoid)
			elseif passengerSeat and not passengerSeat.Occupant then
				passengerSeat:Sit(player.Character.Humanoid)
			end
		end
	end)
	
	table.insert(boatConnections[boat], conn)
end

-- Setup boat
local function setupBoat(boat)
	if boatConnections[boat] then
		return
	end
	
	boatConnections[boat] = {}
	
	saveBoatInitialPosition(boat)
	
	local driverSeat = boat:FindFirstChild("Drive")
	local passengerSeat = boat:FindFirstChild("Seat")
	
	if driverSeat then
		local conn = driverSeat:GetPropertyChangedSignal("Occupant"):Connect(onSeatOccupantChanged(driverSeat, boat))
		table.insert(boatConnections[boat], conn)
	end
	
	if passengerSeat then
		local conn = passengerSeat:GetPropertyChangedSignal("Occupant"):Connect(onSeatOccupantChanged(passengerSeat, boat))
		table.insert(boatConnections[boat], conn)
	end
	
	setupProximityPrompt(boat)
	
	local childAddedConn = boat.ChildAdded:Connect(function(child)
		if child.Name == "Drive" or child.Name == "Seat" then
			local conn = child:GetPropertyChangedSignal("Occupant"):Connect(onSeatOccupantChanged(child, boat))
			table.insert(boatConnections[boat], conn)
		elseif child.Name == "Body" then
			setupProximityPrompt(boat)
		end
	end)
	table.insert(boatConnections[boat], childAddedConn)
	
	print("⛵ [BOAT] Setup complete for:", boat.Name)
end

-- Cleanup boat
local function cleanupBoat(boat)
	if boatConnections[boat] then
		for _, conn in ipairs(boatConnections[boat]) do
			conn:Disconnect()
		end
		boatConnections[boat] = nil
	end
	
	cancelResetTimer(boat)
	boatInitialPositions[boat] = nil
end

-- Check player in boat after title change
local function checkPlayerInBoatAfterTitleChange(player)
	if not player or not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.SeatPart then
		return
	end
	
	local seat = humanoid.SeatPart
	if not seat then return end
	
	local boat = seat.Parent
	if not boat then return end
	
	if boat:FindFirstChild("Drive") or boat:FindFirstChild("Seat") then
		local hasAccess = hasBoatAccess(player)
		
		if not hasAccess then
			task.defer(function()
				throwPlayer(player, seat)
			end)
		end
	end
end

-- Initialize boats
local function initializeBoats()
	local boatsFolder = workspace:FindFirstChild("Boats")
	
	if boatsFolder then
		for _, boat in ipairs(boatsFolder:GetChildren()) do
			if boat:IsA("Model") then
				setupBoat(boat)
			end
		end
		
		boatsFolder.ChildAdded:Connect(function(boat)
			if boat:IsA("Model") then
				task.wait(0.1)
				setupBoat(boat)
			end
		end)
		
		boatsFolder.ChildRemoved:Connect(function(boat)
			cleanupBoat(boat)
		end)
		
		print("⛵ [BOAT] Initialized", #boatsFolder:GetChildren(), "boats")
	else
		print("⛵ [BOAT] No Boats folder found in workspace")
	end
end

-- Listen for title changes
if equipTitleEvent then
	equipTitleEvent.OnServerEvent:Connect(function(player, titleName)
		task.delay(0.3, function()
			checkPlayerInBoatAfterTitleChange(player)
		end)
	end)
end

if unequipTitleEvent then
	unequipTitleEvent.OnServerEvent:Connect(function(player)
		task.delay(0.3, function()
			checkPlayerInBoatAfterTitleChange(player)
		end)
	end)
end

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	for boat, _ in pairs(boatInitialPositions) do
		if boat and boat.Parent then
			local driverSeat = boat:FindFirstChild("Drive")
			local passengerSeat = boat:FindFirstChild("Seat")
			
			local hasOtherOccupants = false
			
			if driverSeat and driverSeat.Occupant then
				local occupantPlayer = Players:GetPlayerFromCharacter(driverSeat.Occupant.Parent)
				if occupantPlayer and occupantPlayer ~= player then
					hasOtherOccupants = true
				end
			end
			
			if passengerSeat and passengerSeat.Occupant then
				local occupantPlayer = Players:GetPlayerFromCharacter(passengerSeat.Occupant.Parent)
				if occupantPlayer and occupantPlayer ~= player then
					hasOtherOccupants = true
				end
			end
			
			if not hasOtherOccupants then
				startResetTimer(boat)
			end
		end
	end
end)

-- Initialize after delay
task.spawn(function()
	task.wait(2)
	initializeBoats()
end)

print("✅ [BOAT CONTROLLER] Loaded")
