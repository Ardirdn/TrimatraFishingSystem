--[[
    REDEEM SERVER (CROSS-SERVER - FIXED)
    Place in ServerScriptService/RedeemServer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TItleServer) -- ✅ ADDED: For broadcasting title after redeem
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))



-- ✅ CROSS-SERVER DATASTORE
local RedeemCodesStore = DataStoreService:GetDataStore("RedeemCodes_v1")

-- Create RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("RedeemRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RedeemRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local createCodeEvent = remoteFolder:FindFirstChild("CreateCode")
if not createCodeEvent then
	createCodeEvent = Instance.new("RemoteEvent")
	createCodeEvent.Name = "CreateCode"
	createCodeEvent.Parent = remoteFolder
end

local redeemCodeEvent = remoteFolder:FindFirstChild("RedeemCode")
if not redeemCodeEvent then
	redeemCodeEvent = Instance.new("RemoteEvent")
	redeemCodeEvent.Name = "RedeemCode"
	redeemCodeEvent.Parent = remoteFolder
end

local getRewardOptionsFunc = remoteFolder:FindFirstChild("GetRewardOptions")
if not getRewardOptionsFunc then
	getRewardOptionsFunc = Instance.new("RemoteFunction")
	getRewardOptionsFunc.Name = "GetRewardOptions"
	getRewardOptionsFunc.Parent = remoteFolder
end

local checkAdminFunc = remoteFolder:FindFirstChild("CheckAdmin")
if not checkAdminFunc then
	checkAdminFunc = Instance.new("RemoteFunction")
	checkAdminFunc.Name = "CheckAdmin"
	checkAdminFunc.Parent = remoteFolder
end

local getAllCodesFunc = remoteFolder:FindFirstChild("GetAllCodes")
if not getAllCodesFunc then
	getAllCodesFunc = Instance.new("RemoteFunction")
	getAllCodesFunc.Name = "GetAllCodes"
	getAllCodesFunc.Parent = remoteFolder
end



-- ==================== HELPER FUNCTIONS ====================

local function isAdmin(player)
	-- ✅ Check 1: Via equipped title
	local data = DataHandler:GetData(player)
	if data and data.EquippedTitle == "Admin" then
		return true
	end

	-- ✅ Check 2: Via TitleConfig.AdminIds (fallback)
	if TitleConfig.AdminIds then
		for _, adminId in ipairs(TitleConfig.AdminIds) do
			if player.UserId == adminId then
				return true
			end
		end
	end

	return false
end

local function getCodeData(codeId)
	local success, result = pcall(function()
		return RedeemCodesStore:GetAsync(codeId)
	end)

	if success and result then
		return result
	end

	return nil
end

local function saveCodeData(codeId, data)
	local success = pcall(function()
		RedeemCodesStore:SetAsync(codeId, data)
	end)

	return success
end

local function getTitleRank(titleId)
	if not titleId then return 0 end

	-- ✅ CHECK SummitTitles
	if TitleConfig.SummitTitles then
		for i, title in ipairs(TitleConfig.SummitTitles) do
			if title.Name == titleId then
				return i
			end
		end
	end

	-- ✅ CHECK SpecialTitles
	if TitleConfig.SpecialTitles and TitleConfig.SpecialTitles[titleId] then
		return TitleConfig.SpecialTitles[titleId].Priority or 999
	end

	return 0
end

-- ==================== CHECK ADMIN ====================

checkAdminFunc.OnServerInvoke = function(player)
	if not player or not player.Parent then return false end
	return isAdmin(player)
end

-- ==================== CREATE CODE ====================

createCodeEvent.OnServerEvent:Connect(function(player, codeString, rewardType, rewardValue, maxUses)
	if not player or not player.Parent then return end

	-- Check if admin
	if not isAdmin(player) then
		NotificationService:Send(player, {
			Message = "You don't have permission to create codes!",
			Type = "error",
			Duration = 3
		})
		return
	end

	-- Validate inputs
	if not codeString or codeString == "" then
		NotificationService:Send(player, {
			Message = "Code cannot be empty!",
			Type = "error",
			Duration = 3
		})
		return
	end

	if not rewardType or not rewardValue then
		NotificationService:Send(player, {
			Message = "Please select a reward!",
			Type = "error",
			Duration = 3
		})
		return
	end

	maxUses = maxUses or 1

	-- Check if code already exists
	local existingCode = getCodeData(codeString)
	if existingCode then
		NotificationService:Send(player, {
			Message = "Code already exists!",
			Type = "error",
			Duration = 3
		})
		return
	end

	-- Create code data
	local codeData = {
		CodeId = codeString,
		RewardType = rewardType,
		RewardValue = rewardValue,
		MaxUses = maxUses,
		CurrentUses = 0,
		CreatedBy = player.UserId,
		CreatedAt = os.time()
	}

	-- Save to DataStore
	local success = saveCodeData(codeString, codeData)

	if success then
		-- ✅ TRACK CODE (save to tracking list)
		local trackingKey = "RedeemCodes_Tracking"
		local success2, existingList = pcall(function()
			return RedeemCodesStore:GetAsync(trackingKey) or {}
		end)

		if success2 then
			if not table.find(existingList, codeString) then
				table.insert(existingList, codeString)
				pcall(function()
					RedeemCodesStore:SetAsync(trackingKey, existingList)
				end)
			end
		end

		NotificationService:Send(player, {
			Message = string.format("Code '%s' created! (%d/%d uses)", codeString, 0, maxUses),
			Type = "success",
			Duration = 5,
			Icon = "🎁"
		})


	else
		NotificationService:Send(player, {
			Message = "Failed to create code. Try again!",
			Type = "error",
			Duration = 3
		})
	end
end)

-- ==================== REDEEM CODE ====================

redeemCodeEvent.OnServerEvent:Connect(function(player, codeString)
	if not player or not player.Parent then return end

	if not codeString or codeString == "" then
		NotificationService:Send(player, {
			Message = "Please enter a code!",
			Type = "error",
			Duration = 3
		})
		return
	end

	-- Get code data
	local codeData = getCodeData(codeString)

	if not codeData then
		NotificationService:Send(player, {
			Message = "Invalid code!",
			Type = "error",
			Duration = 3,
			Icon = "❌"
		})
		return
	end

	-- Check if already redeemed by this player
	if DataHandler:ArrayContains(player, "RedeemedCodes", codeString) then
		NotificationService:Send(player, {
			Message = "You already redeemed this code!",
			Type = "error",
			Duration = 3,
			Icon = "⚠️"
		})
		return
	end

	-- Check if code is still available
	if codeData.CurrentUses >= codeData.MaxUses then
		NotificationService:Send(player, {
			Message = "This code has been fully redeemed!",
			Type = "error",
			Duration = 3,
			Icon = "❌"
		})
		return
	end

	-- ✅ PROCESS REWARD
	local rewardMessage = ""
	local rewardType = codeData.RewardType
	local rewardValue = codeData.RewardValue

	if rewardType == "Title" then
		-- Check if player already has higher title
		local data = DataHandler:GetData(player)
		if not data then
			NotificationService:Send(player, {
				Message = "Failed to load your data!",
				Type = "error",
				Duration = 3
			})
			return
		end

		local currentTitle = data.EquippedTitle
		local currentRank = getTitleRank(currentTitle)
		local rewardRank = getTitleRank(rewardValue)

		if currentRank > rewardRank then
			NotificationService:Send(player, {
				Message = "You already have a higher title!",
				Type = "info",
				Duration = 3
			})
			-- ✅ MASIH MARK AS REDEEMED + UPDATE CODE USES
			DataHandler:AddToArray(player, "RedeemedCodes", codeString)
			DataHandler:SavePlayer(player)

			codeData.CurrentUses = codeData.CurrentUses + 1
			saveCodeData(codeString, codeData)
			return
		end

		-- ✅ FIXED: Give title to UnlockedTitles (TitleServer uses this field, NOT OwnedTitles)
		if not DataHandler:ArrayContains(player, "UnlockedTitles", rewardValue) then
			DataHandler:AddToArray(player, "UnlockedTitles", rewardValue)
		end

		DataHandler:Set(player, "EquippedTitle", rewardValue)
		rewardMessage = string.format("Title: %s", rewardValue)

		-- ✅ ADDED: Broadcast title to update display immediately
		task.spawn(function()
			task.wait(0.5)
			TitleServer:BroadcastTitle(player, rewardValue)
		end)

	elseif rewardType == "Aura" then
		-- Give aura
		if not DataHandler:ArrayContains(player, "OwnedAuras", rewardValue) then
			DataHandler:AddToArray(player, "OwnedAuras", rewardValue)
		end
		rewardMessage = string.format("Aura: %s", rewardValue)

	elseif rewardType == "Tool" then
		-- Give tool
		if not DataHandler:ArrayContains(player, "OwnedTools", rewardValue) then
			DataHandler:AddToArray(player, "OwnedTools", rewardValue)
		end
		rewardMessage = string.format("Tool: %s", rewardValue)

	elseif rewardType == "Money" then
		-- Give money
		DataHandler:Increment(player, "Money", rewardValue)
		rewardMessage = string.format("$%d", rewardValue)

	elseif rewardType == "Summit" then
		-- ✅ Give summit value
		DataHandler:Increment(player, "TotalSummits", rewardValue)

		-- ✅ UPDATE LEADERSTATS (like CheckpointSystem does)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local summitValue = leaderstats:FindFirstChild("Summit")
			if summitValue then
				summitValue.Value = summitValue.Value + rewardValue
			end
		end

		rewardMessage = string.format("+%d Summit Value", rewardValue)

		-- ✅ TRIGGER LEADERBOARD UPDATE (optional but recommended)
		task.spawn(function()
			task.wait(1)
			local CheckpointSystem = require(game.ServerScriptService:WaitForChild("CheckpointSystem"))
			CheckpointSystem.SyncPlayerData(player)
		end)
	end

	-- ✅ UPDATE CODE DATA (INCREMENT USES)
	codeData.CurrentUses = codeData.CurrentUses + 1
	saveCodeData(codeString, codeData)

	-- Mark as redeemed for this player
	DataHandler:AddToArray(player, "RedeemedCodes", codeString)
	DataHandler:SavePlayer(player)

	-- Send success notification
	NotificationService:Send(player, {
		Message = string.format("Code redeemed! You received: %s", rewardMessage),
		Type = "success",
		Duration = 5,
		Icon = "🎁"
	})


end)

-- ==================== GET REWARD OPTIONS ====================

getRewardOptionsFunc.OnServerInvoke = function(player, rewardType)
	if not isAdmin(player) then return {} end



	if rewardType == "Title" then
		local titles = {}

		-- ✅ SummitTitles
		if TitleConfig.SummitTitles then
			for _, title in ipairs(TitleConfig.SummitTitles) do
				table.insert(titles, {
					Id = title.Name,
					Name = title.DisplayName,
					Color = title.Color
				})
			end
		end

		-- ✅ SpecialTitles (kecuali Admin)
		if TitleConfig.SpecialTitles then
			for titleId, titleData in pairs(TitleConfig.SpecialTitles) do
				if titleId ~= "Admin" then
					table.insert(titles, {
						Id = titleId,
						Name = titleData.DisplayName,
						Color = titleData.Color
					})
				end
			end
		end


		return titles

	elseif rewardType == "Aura" or rewardType == "Auras" then
		local auras = {}
		if ShopConfig and ShopConfig.Auras then

			for _, aura in ipairs(ShopConfig.Auras) do
				table.insert(auras, {
					Id = aura.AuraId,
					Name = string.format("%s - $%d", aura.Title, aura.Price),
					Thumbnail = ""
				})
			end
		else
			warn("⚠️ ShopConfig.Auras is nil or empty!")
		end


		return auras

	elseif rewardType == "Tool" or rewardType == "Tools" then
		local tools = {}
		if ShopConfig and ShopConfig.Tools then

			for _, tool in ipairs(ShopConfig.Tools) do
				table.insert(tools, {
					Id = tool.ToolId,
					Name = string.format("%s - $%d", tool.Title, tool.Price),
					Thumbnail = ""
				})
			end
		else
			warn("⚠️ ShopConfig.Tools is nil or empty!")
		end


		return tools

	elseif rewardType == "Money" then
		local RedeemConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RedeemConfig"))
		local money = {}
		for _, amount in ipairs(RedeemConfig.MoneyOptions) do
			table.insert(money, {
				Id = tostring(amount),
				Name = "$" .. amount,
				Value = amount
			})
		end

		return money

	elseif rewardType == "Summit" then
		local RedeemConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RedeemConfig"))
		local summit = {}
		for _, amount in ipairs(RedeemConfig.SummitOptions) do
			table.insert(summit, {
				Id = tostring(amount),
				Name = tostring(amount) .. " Summit",
				Value = amount
			})
		end

		return summit
	end

	warn(string.format("⚠️ [REDEEM] Unknown reward type: %s", rewardType))
	return {}
end

-- ==================== GET ALL CODES (ADMIN ONLY) ====================

getAllCodesFunc.OnServerInvoke = function(player)
	if not isAdmin(player) then return {} end

	local trackingKey = "RedeemCodes_Tracking"
	local success, codeList = pcall(function()
		return RedeemCodesStore:GetAsync(trackingKey) or {}
	end)

	if not success then
		warn("⚠️ [REDEEM] Failed to get tracking list")
		return {}
	end

	local allCodes = {}

	for _, codeString in ipairs(codeList) do
		local codeData = getCodeData(codeString)
		if codeData then
			table.insert(allCodes, {
				Code = codeString,
				Type = codeData.RewardType,
				Reward = codeData.RewardValue,
				CurrentUses = codeData.CurrentUses,
				MaxUses = codeData.MaxUses,
				Remaining = codeData.MaxUses - codeData.CurrentUses
			})
		end
	end


	return allCodes
end


