--[[
    INVENTORY SERVER (FIXED)
    Place in ServerScriptService/InventoryServer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)

-- Create RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "InventoryRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getInventoryEvent = remoteFolder:FindFirstChild("GetInventory")
if not getInventoryEvent then
	getInventoryEvent = Instance.new("RemoteFunction")
	getInventoryEvent.Name = "GetInventory"
	getInventoryEvent.Parent = remoteFolder
end

local equipAuraEvent = remoteFolder:FindFirstChild("EquipAura")
if not equipAuraEvent then
	equipAuraEvent = Instance.new("RemoteEvent")
	equipAuraEvent.Name = "EquipAura"
	equipAuraEvent.Parent = remoteFolder
end

local unequipAuraEvent = remoteFolder:FindFirstChild("UnequipAura")
if not unequipAuraEvent then
	unequipAuraEvent = Instance.new("RemoteEvent")
	unequipAuraEvent.Name = "UnequipAura"
	unequipAuraEvent.Parent = remoteFolder
end

local equipToolEvent = remoteFolder:FindFirstChild("EquipTool")
if not equipToolEvent then
	equipToolEvent = Instance.new("RemoteEvent")
	equipToolEvent.Name = "EquipTool"
	equipToolEvent.Parent = remoteFolder
end

local unequipToolEvent = remoteFolder:FindFirstChild("UnequipTool")
if not unequipToolEvent then
	unequipToolEvent = Instance.new("RemoteEvent")
	unequipToolEvent.Name = "UnequipTool"
	unequipToolEvent.Parent = remoteFolder
end

print("✅ [INVENTORY SERVER] Initialized")

-- Get player inventory
getInventoryEvent.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			OwnedAuras = {},
			OwnedTools = {},
			EquippedAura = nil,
			EquippedTool = nil
		}
	end

	return {
		OwnedAuras = data.OwnedAuras or {},
		OwnedTools = data.OwnedTools or {},
		EquippedAura = data.EquippedAura,
		EquippedTool = data.EquippedTool
	}
end

-- Equip Aura
equipAuraEvent.OnServerEvent:Connect(function(player, auraId)
	if not player or not player.Parent then return end

	if not DataHandler:ArrayContains(player, "OwnedAuras", auraId) then
		NotificationService:Send(player, {
			Message = "You don't own this aura!",
			Type = "error",
			Duration = 3
		})
		return
	end

	DataHandler:Set(player, "EquippedAura", auraId)
	DataHandler:SavePlayer(player)

	if player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local oldAura = humanoidRootPart:FindFirstChild("EquippedAura")
			if oldAura then
				oldAura:Destroy()
			end

			local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
			if aurasFolder then
				local auraTemplate = aurasFolder:FindFirstChild(auraId)
				if auraTemplate then
					local auraClone = auraTemplate:Clone()
					auraClone.Name = "EquippedAura"
					auraClone.CFrame = humanoidRootPart.CFrame

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = humanoidRootPart
					weld.Part1 = auraClone
					weld.Parent = auraClone

					auraClone.Parent = humanoidRootPart

					print(string.format("✨ [INVENTORY SERVER] Applied aura visual: %s", auraId))
				else
					warn(string.format("⚠️ [INVENTORY SERVER] Aura template not found: %s", auraId))
				end
			end
		end
	end

	NotificationService:Send(player, {
		Message = string.format("Equipped %s!", auraId),
		Type = "success",
		Duration = 3,
		Icon = "✨"
	})

	print(string.format("✨ [INVENTORY SERVER] %s equipped aura: %s", player.Name, auraId))
end)

-- Unequip Aura
unequipAuraEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	DataHandler:Set(player, "EquippedAura", nil)
	DataHandler:SavePlayer(player)

	if player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local equippedAura = humanoidRootPart:FindFirstChild("EquippedAura")
			if equippedAura then
				equippedAura:Destroy()
				print(string.format("✨ [INVENTORY SERVER] Removed aura visual from %s", player.Name))
			end
		end
	end

	NotificationService:Send(player, {
		Message = "Aura unequipped",
		Type = "info",
		Duration = 3
	})

	print(string.format("✨ [INVENTORY SERVER] %s unequipped aura", player.Name))
end)

-- Equip Tool
equipToolEvent.OnServerEvent:Connect(function(player, toolId)
	if not player or not player.Parent then return end

	if not DataHandler:ArrayContains(player, "OwnedTools", toolId) then
		NotificationService:Send(player, {
			Message = "You don't own this tool!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then
		warn("⚠️ [INVENTORY SERVER] Tools folder not found in ReplicatedStorage")
		return
	end

	local toolTemplate = toolsFolder:FindFirstChild(toolId)
	if not toolTemplate then
		warn(string.format("⚠️ [INVENTORY SERVER] Tool not found: %s", toolId))
		return
	end

	if player.Character then
		-- ✅ TAMBAHKAN INI: Unequip tool lama dulu
		local backpack = player:FindFirstChild("Backpack")

		-- Remove from character
		for _, existingTool in ipairs(player.Character:GetChildren()) do
			if existingTool:IsA("Tool") then
				existingTool.Parent = backpack -- Move to backpack first
				task.wait(0.05) -- Trigger Unequipped event
				existingTool:Destroy()
			end
		end

		-- Remove from backpack
		if backpack then
			for _, existingTool in ipairs(backpack:GetChildren()) do
				if existingTool:IsA("Tool") then
					existingTool:Destroy()
				end
			end
		end

		-- ✅ BARU EQUIP TOOL BARU
		local toolClone = toolTemplate:Clone()
		toolClone.Parent = player.Character
	end

	DataHandler:Set(player, "EquippedTool", toolId)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = string.format("Equipped %s!", toolId),
		Type = "success",
		Duration = 3,
		Icon = "🔧"
	})

	print(string.format("🔧 [INVENTORY SERVER] %s equipped tool: %s", player.Name, toolId))
end)


-- ✅ FIXED: Unequip Tool (trigger Unequipped event)
unequipToolEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	-- ✅ Properly unequip tool BEFORE destroying
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")

		-- Loop through character untuk find tool yang equipped
		for _, tool in ipairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				-- ✅ IMPORTANT: Unequip tool ke backpack dulu (trigger Unequipped event)
				tool.Parent = player:FindFirstChild("Backpack")

				-- Wait sebentar biar event Unequipped sempat execute
				task.wait(0.1)

				-- Baru destroy setelah event triggered
				tool:Destroy()
			end
		end

		-- Double check: hapus juga dari backpack
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") then
					tool:Destroy()
				end
			end
		end
	end

	-- Clear equipped tool data
	DataHandler:Set(player, "EquippedTool", nil)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = "Tool unequipped",
		Type = "info",
		Duration = 3
	})

	print(string.format("🔧 [INVENTORY SERVER] %s unequipped tool", player.Name))
end)


-- ✅ FIXED: Reapply on respawn (combined aura + tool)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)

		local data = DataHandler:GetData(player)
		if not data then return end

		-- Reapply Aura
		if data.EquippedAura then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
				if aurasFolder then
					local auraTemplate = aurasFolder:FindFirstChild(data.EquippedAura)
					if auraTemplate then
						local auraClone = auraTemplate:Clone()
						auraClone.Name = "EquippedAura"
						auraClone.CFrame = humanoidRootPart.CFrame

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = humanoidRootPart
						weld.Part1 = auraClone
						weld.Parent = auraClone

						auraClone.Parent = humanoidRootPart

						print(string.format("✨ [INVENTORY SERVER] Reapplied aura on respawn: %s", data.EquippedAura))
					end
				end
			end
		end

		-- Reapply Tool
		if data.EquippedTool then
			local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
			if toolsFolder then
				local toolTemplate = toolsFolder:FindFirstChild(data.EquippedTool)
				if toolTemplate then
					local toolClone = toolTemplate:Clone()
					toolClone.Parent = character

					print(string.format("🔧 [INVENTORY SERVER] Reapplied tool on respawn: %s", data.EquippedTool))
				end
			end
		end
	end)
end)

print("✅ [INVENTORY SERVER] System loaded")