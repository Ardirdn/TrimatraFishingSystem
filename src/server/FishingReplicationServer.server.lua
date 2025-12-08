--[[
	FISHING REPLICATION SERVER (OPTIMIZED)
	Server ONLY broadcasts STATE changes, NOT position updates
	
	- Tells other clients WHEN someone starts/stops fishing
	- Sends initial floater position ONCE
	- All animation is handled client-side locally
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
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

print("✅ [FISHING REPLICATION] RemoteEvents created (optimized)")

-- ============================================
-- PLAYER STATE TRACKING (minimal)
-- ============================================
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

-- ============================================
-- BROADCAST TO ALL OTHER PLAYERS
-- ============================================
local function broadcastToOthers(sourcePlayer, eventToFire, data)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= sourcePlayer then
			eventToFire:FireClient(player, sourcePlayer, data)
		end
	end
end

-- ============================================
-- EVENT HANDLERS (STATE CHANGES ONLY)
-- ============================================

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
	
	print("🎣 [REPLICATION]", player.Name, "started fishing")
end)

-- Player threw floater (send start + target position, client animates throw arc locally)
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
	
	print("🎣 [REPLICATION]", player.Name, "threw floater from", startPos, "to", targetPos)
end)

-- Player started pulling
StartPullingEvent.OnServerEvent:Connect(function(player)
	local state = getPlayerState(player)
	state.IsPulling = true
	state.IsFloating = false
	
	broadcastToOthers(player, PlayerStartedPullingEvent, {})
	
	print("🎣 [REPLICATION]", player.Name, "started pulling")
end)

-- Player stopped fishing
StopFishingEvent.OnServerEvent:Connect(function(player)
	local state = getPlayerState(player)
	state.IsFishing = false
	state.IsFloating = false
	state.IsPulling = false
	state.FloaterTargetPos = nil
	
	broadcastToOthers(player, PlayerStoppedFishingEvent, {})
	
	print("🎣 [REPLICATION]", player.Name, "stopped fishing")
end)

-- ============================================
-- CLEANUP ON PLAYER LEAVE
-- ============================================
Players.PlayerRemoving:Connect(function(player)
	broadcastToOthers(player, PlayerStoppedFishingEvent, {})
	PlayerFishingStates[player] = nil
end)

-- ============================================
-- NEW PLAYER SYNC
-- ============================================
Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(3)
	
	-- Tell new player about currently fishing players
	for player, state in pairs(PlayerFishingStates) do
		if player ~= newPlayer and state.IsFishing and state.FloaterTargetPos then
			PlayerThrewFloaterEvent:FireClient(newPlayer, player, {
				TargetPos = state.FloaterTargetPos,
				RodId = state.RodId,
				FloaterId = state.FloaterId,
				LineStyle = nil,
			})
			
			if state.IsPulling then
				task.wait(0.1)
				PlayerStartedPullingEvent:FireClient(newPlayer, player, {})
			end
		end
	end
end)

print("✅ [FISHING REPLICATION SERVER] Loaded (optimized - state only)")
