--[[
    SKIP CHECKPOINT HANDLER
    Place in ServerScriptService/SkipCheckpointHandler
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)

local SKIP_PRODUCT_ID = 3477254962 -- ✅ GANTI dengan Product ID kamu!

-- ✅ Export to global untuk MarketplaceHandler
_G.SKIP_PRODUCT_ID = SKIP_PRODUCT_ID

local checkpointsFolder = workspace:WaitForChild("Checkpoints", 10)  -- 10 second timeout
if not checkpointsFolder then
	warn("❌ [SKIP CHECKPOINT] Checkpoints folder not found!")
	return
end
local checkpoints = {}

-- Load checkpoints
for _, checkpoint in pairs(checkpointsFolder:GetChildren()) do
	if checkpoint:IsA("BasePart") and checkpoint.Name:match("Checkpoint%d+") then
		local number = tonumber(checkpoint.Name:match("%d+"))
		checkpoints[number] = checkpoint
	end
end

print("✅ [SKIP CHECKPOINT] System initialized")

-- Setup ProximityPrompt listeners
for checkpointNum, checkpoint in pairs(checkpoints) do
	-- Skip last checkpoint (summit)
	if checkpointNum >= #checkpoints then
		continue
	end

	local skipBoard = checkpoint:FindFirstChild("SkipBoard")
	if not skipBoard then
		warn("[SKIP] SkipBoard not found in Checkpoint" .. checkpointNum)
		continue
	end

	local proximityPrompt = skipBoard:FindFirstChild("ProximityPrompt")
	if not proximityPrompt then
		warn("[SKIP] ProximityPrompt not found in Checkpoint" .. checkpointNum)
		continue
	end

	print("[SKIP] Setup prompt for Checkpoint" .. checkpointNum)

	proximityPrompt.Triggered:Connect(function(player)
		print(string.format("[SKIP] %s triggered skip at Checkpoint%d", player.Name, checkpointNum))

		-- Validate: player harus ada di checkpoint ini
		local data = DataHandler:GetData(player)
		if not data then
			NotificationService:Send(player, {
				Message = "Data not loaded!",
				Type = "error",
				Duration = 3
			})
			return
		end

		local currentCheckpoint = data.LastCheckpoint

		if currentCheckpoint ~= checkpointNum then
			NotificationService:Send(player, {
				Message = "Kamu harus ada di checkpoint ini untuk skip!",
				Type = "warning",
				Duration = 3
			})
			print(string.format("[SKIP] Player at checkpoint %d, trying to skip %d", currentCheckpoint, checkpointNum))
			return
		end

		-- Prompt purchase
		MarketplaceService:PromptProductPurchase(player, SKIP_PRODUCT_ID)
	end)
end

-- Track pending skips (karena ProcessReceipt bisa delay)
local pendingSkips = {}

-- Create RemoteEvent untuk trigger skip setelah purchase
local remoteFolder = ReplicatedStorage:FindFirstChild("SkipCheckpointRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "SkipCheckpointRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local executeSkipEvent = remoteFolder:FindFirstChild("ExecuteSkip")
if not executeSkipEvent then
	executeSkipEvent = Instance.new("BindableEvent")
	executeSkipEvent.Name = "ExecuteSkip"
	executeSkipEvent.Parent = remoteFolder
end

-- Function to execute skip
local function executeSkip(player)
	local character = player.Character
	if not character then return end

	local data = DataHandler:GetData(player)
	if not data then return end

	local currentCheckpoint = data.LastCheckpoint
	local nextCheckpoint = currentCheckpoint + 1

	-- Validate next checkpoint exists
	if not checkpoints[nextCheckpoint] then
		NotificationService:Send(player, {
			Message = "Tidak ada checkpoint selanjutnya!",
			Type = "error",
			Duration = 3
		})
		return
	end

	-- Teleport to next checkpoint
	local spawnLocation = checkpoints[nextCheckpoint]:FindFirstChild("SpawnLocation")
	if spawnLocation then
		character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
	else
		character:MoveTo(checkpoints[nextCheckpoint].Position + Vector3.new(0, 5, 0))
	end

	-- Update player data
	DataHandler:Set(player, "LastCheckpoint", nextCheckpoint)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = string.format("🚀 Skipped to Checkpoint %d!", nextCheckpoint),
		Type = "success",
		Duration = 3,
		Icon = "⚡"
	})

	print(string.format("[SKIP] ✅ %s skipped from %d to %d", player.Name, currentCheckpoint, nextCheckpoint))
end

-- Listen to execute event
executeSkipEvent.Event:Connect(function(player)
	executeSkip(player)
end)

-- Export for MarketplaceHandler
_G.ExecuteSkipCheckpoint = function(player)
	executeSkip(player)
end

print("✅ [SKIP CHECKPOINT] Handler loaded")
