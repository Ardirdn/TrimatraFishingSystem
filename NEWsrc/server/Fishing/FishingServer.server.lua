--[[
	FISHING SERVER (COMBINED)
	Combines: FishingRewardServer + FishingReplicationServer + ToolGiver
	Place in ServerScriptService > Fishing
	
	Handles:
	- Fish catching rewards and inventory
	- Fish tool creation
	- Replication of fishing states to other players
	- Tool giving on spawn (rods and fish)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))
local DataHandler = require(script.Parent.Parent.DataHandler)

-- Fish Area System for area-based fish rewards
local FishAreaSystem = nil
pcall(function()
	FishAreaSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishAreaSystem"))
end)

local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods")
local RodsFolder = FishingRodsFolder:WaitForChild("Rods")

-- ================================================================================
--                         SECTION: REMOTE EVENTS CREATION
-- ================================================================================

-- Fish Reward Remotes
local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
if not FishingSuccessEvent then
	FishingSuccessEvent = Instance.new("RemoteEvent")
	FishingSuccessEvent.Name = "FishingSuccessEvent"
	FishingSuccessEvent.Parent = ReplicatedStorage
end

local FishCaughtEvent = ReplicatedStorage:FindFirstChild("FishCaughtEvent")
if not FishCaughtEvent then
	FishCaughtEvent = Instance.new("RemoteEvent")
	FishCaughtEvent.Name = "FishCaughtEvent"
	FishCaughtEvent.Parent = ReplicatedStorage
end

local GetFishInventoryFunc = ReplicatedStorage:FindFirstChild("GetFishInventory")
if not GetFishInventoryFunc then
	GetFishInventoryFunc = Instance.new("RemoteFunction")
	GetFishInventoryFunc.Name = "GetFishInventory"
	GetFishInventoryFunc.Parent = ReplicatedStorage
end

-- Replication Remotes
local FishingRemotes = ReplicatedStorage:FindFirstChild("FishingRemotes")
if not FishingRemotes then
	FishingRemotes = Instance.new("Folder")
	FishingRemotes.Name = "FishingRemotes"
	FishingRemotes.Parent = ReplicatedStorage
end

local function createRemote(name)
	local existing = FishingRemotes:FindFirstChild(name)
	if existing then return existing end
	
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = FishingRemotes
	return remote
end

-- Client -> Server (player actions)
local StartFishingEvent = createRemote("StartFishing")
local ThrowFloaterEvent = createRemote("ThrowFloater")
local StartPullingEvent = createRemote("StartPulling")
local StopFishingEvent = createRemote("StopFishing")

-- Server -> Client (broadcast to others)
local PlayerStartedFishingEvent = createRemote("PlayerStartedFishing")
local PlayerThrewFloaterEvent = createRemote("PlayerThrewFloater")
local PlayerStartedPullingEvent = createRemote("PlayerStartedPulling")
local PlayerStoppedFishingEvent = createRemote("PlayerStoppedFishing")

print("✅ [FISHING SERVER] RemoteEvents created")

-- ================================================================================
--                         SECTION: FISH TOOL CREATION
-- ================================================================================

local function createFishTool(player, fishId, fishData)
	if not fishData then return nil end
	
	-- Create Tool
	local fishTool = Instance.new("Tool")
	fishTool.Name = fishData.Name
	fishTool.CanBeDropped = false
	fishTool.RequiresHandle = true
	fishTool.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))
	
	local handle = nil
	
	-- Search multiple locations for fish models
	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels") 
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FishModels"))
		or workspace:FindFirstChild("FishModels")
	
	-- Try to load 3D model
	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishId)
		if fishModel then
			if fishModel:IsA("Model") then
				local primaryPart = fishModel.PrimaryPart or fishModel:FindFirstChildWhichIsA("BasePart")
				
				if primaryPart then
					local clonedModel = fishModel:Clone()
					
					if clonedModel:IsA("Model") then
						clonedModel:PivotTo(CFrame.new(0, 0, 0))
					end
					
					handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(0.5, 0.3, 1)
					handle.Transparency = 1
					handle.CanCollide = false
					handle.Anchored = false
					handle.Massless = true
					handle.CanQuery = false
					handle.CanTouch = false
					handle.CFrame = CFrame.new(0, 0, 0)
					
					local partsToWeld = {}
					for _, part in pairs(clonedModel:GetDescendants()) do
						if part:IsA("BasePart") then
							table.insert(partsToWeld, part)
						end
					end
					
					for _, part in ipairs(partsToWeld) do
						part.CanCollide = false
						part.CanQuery = false
						part.CanTouch = false
						part.Massless = true
						part.Anchored = false
						
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = handle
						weld.Part1 = part
						weld.Parent = part
						
						part.Parent = handle
					end
					
					clonedModel:Destroy()
				end
			elseif fishModel:IsA("BasePart") then
				handle = fishModel:Clone()
				handle.Name = "Handle"
				handle.CanCollide = false
				handle.CanQuery = false
				handle.CanTouch = false
				handle.Massless = true
			end
		end
	end
	
	-- Fallback: create placeholder
	if not handle then
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(0.6, 0.3, 1)
		handle.Material = Enum.Material.SmoothPlastic
		
		local rarityColors = {
			Common = Color3.fromRGB(180, 180, 180),
			Uncommon = Color3.fromRGB(100, 200, 100),
			Rare = Color3.fromRGB(80, 150, 255),
			Epic = Color3.fromRGB(180, 80, 220),
			Legendary = Color3.fromRGB(255, 170, 30),
		}
		handle.Color = rarityColors[fishData.Rarity] or Color3.fromRGB(200, 200, 200)
		
		if fishData.Rarity == "Legendary" then
			local pointLight = Instance.new("PointLight")
			pointLight.Color = handle.Color
			pointLight.Brightness = 1.5
			pointLight.Range = 6
			pointLight.Parent = handle
		end
	end
	
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Anchored = false
	handle.Massless = true
	handle.Parent = fishTool
	
	for _, part in pairs(fishTool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	
	return fishTool
end

-- ================================================================================
--                         SECTION: FISH REWARD SYSTEM
-- ================================================================================

local function giveFishReward(player, success, floaterPosition)
	local data = DataHandler:GetData(player)
	if not data then 
		warn("⚠️ No player data for", player.Name)
		return 
	end

	if not success then
		return
	end

	-- Get random fish (with area modifiers if available)
	local fishId, fishData, areaName
	
	if FishAreaSystem and floaterPosition then
		-- Use area-based fish selection
		fishId, fishData, areaName = FishAreaSystem.GetRandomFishInArea(floaterPosition)
		if areaName then
			print(string.format("🎣 [FISHING SERVER] Player %s fishing in %s area!", player.Name, areaName))
		end
	else
		-- Fallback to normal random fish
		fishId, fishData = FishConfig.GetRandomFish()
	end

	if not fishId or not fishData then
		warn("⚠️ No fish data available from FishConfig!")
		return
	end

	-- Update data via DataHandler
	local fishInventory = DataHandler:Get(player, "FishInventory") or {}
	fishInventory[fishId] = (fishInventory[fishId] or 0) + 1
	DataHandler:Set(player, "FishInventory", fishInventory)
	
	DataHandler:Increment(player, "TotalFishCaught", 1)
	
	-- Check if new discovery
	local discoveredFish = DataHandler:Get(player, "DiscoveredFish") or {}
	local isNewDiscovery = not discoveredFish[fishId]
	
	if isNewDiscovery then
		discoveredFish[fishId] = true
		DataHandler:Set(player, "DiscoveredFish", discoveredFish)
	end
	
	DataHandler:SavePlayer(player)

	-- Create fish tool (visual feedback)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		pcall(function()
			local fishTool = createFishTool(player, fishId, fishData)
			if fishTool then
				fishTool.Parent = backpack
			end
		end)
	end

	local fishCount = fishInventory[fishId]

	-- Notify client
	print(string.format("🐟 [FISHING SERVER] Sending FishCaughtEvent to %s: %s (%s) | New Discovery: %s | Area: %s", 
		player.Name, fishData.Name, fishId, tostring(isNewDiscovery), areaName or "Open Waters"))
	
	FishCaughtEvent:FireClient(player, {
		FishID = fishId,
		FishData = fishData,
		IsNewDiscovery = isNewDiscovery,
		Quantity = 1,
		FishCount = fishCount,
		Price = fishData.Price or 0,
		AreaName = areaName -- Include area name for client display
	})
	
	-- Global notification for SECRET fish catches
	if fishData.Rarity == "Secret" then
		-- Broadcast to all players that someone caught a Secret fish
		local message = string.format("🌟 %s telah menangkap ikan Secret: %s!", player.Name, fishData.Name)
		
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			-- Send notification to all players (including the catcher)
			FishCaughtEvent:FireClient(otherPlayer, {
				IsGlobalNotification = true,
				Message = message,
				FishName = fishData.Name,
				PlayerName = player.Name,
				Rarity = "Secret"
			})
		end
		
		print(string.format("🌟 [FISHING SERVER] GLOBAL NOTIFICATION: %s caught SECRET fish: %s", player.Name, fishData.Name))
	end
end

-- Remote handler for fishing success (now receives floater position)
FishingSuccessEvent.OnServerEvent:Connect(function(player, success, floaterPosition)
	giveFishReward(player, success, floaterPosition)
end)

-- Get fish inventory
GetFishInventoryFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if data then
		return {
			DiscoveredFish = data.DiscoveredFish or {},
			TotalFishCaught = data.TotalFishCaught or 0,
			Money = data.Money or 0
		}
	end
	return nil
end

-- ================================================================================
--                         SECTION: REPLICATION SYSTEM
-- ================================================================================

local PlayerFishingStates = {}

local function getPlayerState(player)
	if not PlayerFishingStates[player] then
		PlayerFishingStates[player] = {
			IsFishing = false,
			IsFloating = false,
			IsPulling = false,
			FloaterTargetPos = nil,
			RodId = nil,
			FloaterId = nil,
		}
	end
	return PlayerFishingStates[player]
end

local function broadcastToOthers(sourcePlayer, eventToFire, data)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= sourcePlayer then
			eventToFire:FireClient(player, sourcePlayer, data)
		end
	end
end

-- Player equipped rod
StartFishingEvent.OnServerEvent:Connect(function(player, rodId, floaterId)
	local state = getPlayerState(player)
	state.IsFishing = true
	state.RodId = rodId
	state.FloaterId = floaterId
	
	
	broadcastToOthers(player, PlayerStartedFishingEvent, {
		RodId = rodId,
		FloaterId = floaterId,
	})
end)

-- Player threw floater
ThrowFloaterEvent.OnServerEvent:Connect(function(player, startPos, targetPos, rodId, floaterId, lineStyle, throwHeight)
	local state = getPlayerState(player)
	state.IsFloating = true
	state.FloaterTargetPos = targetPos
	state.FloaterStartPos = startPos
	state.ThrowHeight = throwHeight or 8
	
	
	broadcastToOthers(player, PlayerThrewFloaterEvent, {
		StartPos = startPos,
		TargetPos = targetPos,
		RodId = rodId,
		FloaterId = floaterId,
		LineStyle = lineStyle,
		ThrowHeight = throwHeight or 8,
	})
end)

-- Player started pulling
StartPullingEvent.OnServerEvent:Connect(function(player)
	local state = getPlayerState(player)
	state.IsPulling = true
	state.IsFloating = false
	
	
	broadcastToOthers(player, PlayerStartedPullingEvent, {})
end)

-- Player stopped fishing
StopFishingEvent.OnServerEvent:Connect(function(player)
	local state = getPlayerState(player)
	state.IsFishing = false
	state.IsFloating = false
	state.IsPulling = false
	state.FloaterTargetPos = nil
	
	
	broadcastToOthers(player, PlayerStoppedFishingEvent, {})
end)

-- ================================================================================
--                         SECTION: TOOL GIVER
-- ================================================================================

local function giveFishTools(player, backpack)
	local data = DataHandler:GetData(player)
	if not data or not data.FishInventory then return end
	
	-- Clear existing fish tools first
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and not tool.Name:find("FishingRod") and not tool.Name:find("Rod") then
			for fishId, fishData in pairs(FishConfig.Fish) do
				if fishData.Name == tool.Name then
					tool:Destroy()
					break
				end
			end
		end
	end
	
	-- Give fish tools for each fish in inventory
	local fishCount = 0
	for fishId, count in pairs(data.FishInventory) do
		if count and count > 0 then
			local fishData = FishConfig.Fish[fishId]
			if fishData then
				local fishTool = createFishTool(player, fishId, fishData)
				if fishTool then
					fishTool.Parent = backpack
					fishCount = fishCount + 1
				end
			end
		end
	end
end

local function giveEquippedRod(player)
	task.wait(0.5)

	local character = player.Character
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack or not humanoid then return end
	
	-- Get equipped rod from DataHandler
	local equippedRodId = nil
	
	local data = DataHandler:GetData(player)
	if data then
		equippedRodId = data.EquippedRod
	end
	
	-- Default to starter rod if no equipped rod found
	if not equippedRodId or equippedRodId == "" then
		equippedRodId = "WoodRod"
	end
	
	-- Remove any existing fishing rod tools from backpack and character
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:find("FishingRod") or tool.Name:find("Rod")) then
			tool:Destroy()
		end
	end
	
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:find("FishingRod") or tool.Name:find("Rod")) then
			tool:Destroy()
		end
	end
	
	-- Give the equipped rod
	local rod = RodsFolder:FindFirstChild(equippedRodId)
	if rod and rod:IsA("Tool") then
		local rodClone = rod:Clone()
		rodClone.Parent = backpack
		
		-- Auto-equip rod
		task.delay(0.2, function()
			if humanoid and humanoid.Health > 0 and rodClone and rodClone.Parent then
				humanoid:EquipTool(rodClone)
			end
		end)
	else
		warn("⚠️ [TOOL GIVER] Equipped rod not found:", equippedRodId)
	end
	
	-- Also give fish tools
	giveFishTools(player, backpack)
end

-- ================================================================================
--                         SECTION: PLAYER CONNECTIONS
-- ================================================================================

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		giveEquippedRod(player)
	end)

	if player.Character then
		giveEquippedRod(player)
	end
	
	-- New player sync for replication
	task.wait(3)
	
	for plr, state in pairs(PlayerFishingStates) do
		if plr ~= player and state.IsFishing and state.FloaterTargetPos then
			PlayerThrewFloaterEvent:FireClient(player, plr, {
				TargetPos = state.FloaterTargetPos,
				RodId = state.RodId,
				FloaterId = state.FloaterId,
				LineStyle = nil,
			})
			
			if state.IsPulling then
				task.wait(0.1)
				PlayerStartedPullingEvent:FireClient(player, plr, {})
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	broadcastToOthers(player, PlayerStoppedFishingEvent, {})
	PlayerFishingStates[player] = nil
end)

-- For players already in game when server script loads
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			giveEquippedRod(player)
		end)
	end
end

print("✅ [FISHING SERVER] Loaded (Combined Reward + Replication + ToolGiver)")
