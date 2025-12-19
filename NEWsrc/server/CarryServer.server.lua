-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes
local REMOTE_NAME = "CarryRemote"
local CarryRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or Instance.new("RemoteEvent")
CarryRemote.Name = REMOTE_NAME
CarryRemote.Parent = ReplicatedStorage

-- Config
local PENDING_TIMEOUT = 8
local MAX_DISTANCE = 20
local MAX_CARRY = 30
local DEBUG = true  -- ✅ Enable debug logging

-- Formation
local BASE_Z = 1.6
local SPACING_Z = 1.1
local Y_OFFSET = 0.9
local SLOT1_ADJ_Z = -0.2
local SLOT2_ADJ_Z = 0.2
local STEP_Y_FIRST = 0.55
local STEP_Y_NEXT = 0.30
local MAX_EXTRA_Y = 6.0

local function slotOffset(i: number): CFrame
	local z = BASE_Z + (i - 1) * SPACING_Z
	if i == 1 then z += SLOT1_ADJ_Z elseif i == 2 then z += SLOT2_ADJ_Z end
	local elevIndex = math.max(0, i - 1)
	local extraY = (elevIndex > 0) and (STEP_Y_FIRST + (elevIndex - 1) * STEP_Y_NEXT) or 0
	extraY = math.min(extraY, MAX_EXTRA_Y)
	return CFrame.new(0, Y_OFFSET + extraY, z)
end

-- State
local pending: {[number]: {requester: Player, target: Player, time: number, requestType: string, originator: Player}} = {}
local carryingByCarrier: {[number]: {[number]: Player}} = {}
local carriedByTarget: {[number]: Player} = {}
local slotByCarrier: {[number]: {[number]: number}} = {}
local lockMap: {[number]: boolean} = {}
local detachGuard: {[number]: boolean} = {}

-- Save/Restore
local savedProps: {[number]: {[BasePart]: {cc:boolean, ml:boolean}}} = {}
local savedHum: {[number]: {ws:number, useJP:boolean, jp:number, jh:number, autoRotate:boolean, jumpEnabled:boolean, platformStand:boolean}} = {}

-- Helpers
local function getCharHRP(p: Player)
	local char = p.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end
	return char, hrp, hum
end

-- ✅ FIX: Add timeout to prevent infinite lock wait (deadlock prevention)
local function acquireLock(uid: number)
	local startTime = tick()
	local timeout = 5 -- 5 seconds max wait
	while lockMap[uid] do
		if tick() - startTime > timeout then
			warn(string.format("[CARRY] Lock timeout for user %d - forcing release", uid))
			lockMap[uid] = nil
			break
		end
		task.wait(0.1)
	end
	lockMap[uid] = true
end
local function releaseLock(uid: number) lockMap[uid] = nil end
local function acquireLocks(a: number, b: number)
	if a == b then acquireLock(a) return end
	if a < b then acquireLock(a); acquireLock(b) else acquireLock(b); acquireLock(a) end
end
local function releaseLocks(a: number, b: number)
	releaseLock(a); if b ~= a then releaseLock(b) end
end

local function getCarryMap(carrier: Player)
	local m = carryingByCarrier[carrier.UserId]
	if not m then m = {}; carryingByCarrier[carrier.UserId] = m end
	return m
end
local function getSlotMap(carrier: Player)
	local m = slotByCarrier[carrier.UserId]
	if not m then m = {}; slotByCarrier[carrier.UserId] = m end
	return m
end
local function countCarried(carrier: Player)
	local m = carryingByCarrier[carrier.UserId]; if not m then return 0 end
	local n = 0; for _ in pairs(m) do n += 1 end
	return n
end
local function isBeingCarried(p: Player) return carriedByTarget[p.UserId] ~= nil end
local function canCarrierRequest(p: Player) return not isBeingCarried(p) end
local function targetAvailable(p: Player) return not isBeingCarried(p) end

-- Save/Restore Humanoid
local function saveHumState(uid: number, hum: Humanoid)
	savedHum[uid] = {
		ws = hum.WalkSpeed,
		useJP = hum.UseJumpPower,
		jp = hum.JumpPower,
		jh = hum.JumpHeight,
		autoRotate = hum.AutoRotate,
		jumpEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping),
		platformStand = hum.PlatformStand,
	}
end
local function restoreHumState(uid: number, hum: Humanoid)
	local st = savedHum[uid]
	if st then
		hum.WalkSpeed = st.ws
		hum.AutoRotate = st.autoRotate
		if st.useJP then hum.JumpPower = st.jp else hum.JumpHeight = st.jh end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, st.jumpEnabled)
		hum.PlatformStand = st.platformStand
		savedHum[uid] = nil
	else
		hum.AutoRotate = true
		hum.WalkSpeed = 16
		if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hum.PlatformStand = false
	end
end

-- Lighten carried
local function makeCarriedLight(char: Model, userId: number)
	local map: {[BasePart]: {cc:boolean, ml:boolean}} = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			map[d] = { cc = d.CanCollide, ml = d.Massless }
			d.CanCollide = false
			d.Massless = true
		end
	end
	savedProps[userId] = map
end
local function restoreCarriedLight(userId: number)
	local map = savedProps[userId]; if not map then return end
	for part, st in pairs(map) do
		if part and part.Parent then
			part.CanCollide = st.cc
			part.Massless = st.ml
		end
	end
	savedProps[userId] = nil
end

-- Network ownership
local function setHRPOwnerTo(p: Player, owner: Player?)
	local _, hrp = getCharHRP(p)
	if not hrp then return end
	pcall(function()
		if owner then
			hrp:SetNetworkOwner(owner)
		else
			hrp:SetNetworkOwnershipAuto()
		end
	end)
end
local function giveSelfOwnership(p: Player) setHRPOwnerTo(p, p) end
local function giveCarrierOwnership(target: Player, carrier: Player) setHRPOwnerTo(target, carrier) end

-- Weld helpers
local function clearCarryWeldsForChar(char: Model)
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, w in ipairs(hrp:GetChildren()) do
			if w:IsA("WeldConstraint") and w.Name == "CarryWeld" then
				w:Destroy()
			end
		end
	end
end
local function findCarryWeldBetween(targetHRP: BasePart, carrierHRP: BasePart): WeldConstraint?
	for _, w in ipairs(targetHRP:GetChildren()) do
		if w:IsA("WeldConstraint") and w.Name == "CarryWeld" and w.Part0 == carrierHRP and w.Part1 == targetHRP then
			return w
		end
	end
	return nil
end
local function ensureCarryWeldBetween(carrierHRP: BasePart, targetHRP: BasePart): WeldConstraint
	local w = findCarryWeldBetween(targetHRP, carrierHRP)
	if not w then
		w = Instance.new("WeldConstraint")
		w.Name = "CarryWeld"
		w.Part0 = carrierHRP
		w.Part1 = targetHRP
		w.Parent = targetHRP
	end
	return w
end
local function removeCarryWeldBetween(carrierHRP: BasePart, targetHRP: BasePart)
	local w = findCarryWeldBetween(targetHRP, carrierHRP)
	if w then w:Destroy() end
end

-- UI Snapshot
local function buildCarriedList(carrier: Player)
	local list = {}
	local cmap = carryingByCarrier[carrier.UserId]
	if cmap then
		for tid, t in pairs(cmap) do table.insert(list, {id=tid, name=t.DisplayName}) end
		table.sort(list, function(a,b) return a.name < b.name end)
	end
	return list
end
local function sendCarrierList(carrier: Player)
	CarryRemote:FireClient(carrier, "CarrierList", {list = buildCarriedList(carrier)})
end

-- Reindex slots
local function reindexSlots(carrier: Player)
	acquireLock(carrier.UserId)
	local ok = pcall(function()
		local _, cHRP = getCharHRP(carrier); if not cHRP then return end
		local smap = slotByCarrier[carrier.UserId]; if not smap then return end
		local temp = {}
		for tid, s in pairs(smap) do
			local t = Players:GetPlayerByUserId(tid)
			if t then table.insert(temp, {p=t, s=s}) end
		end
		table.sort(temp, function(a,b) return a.s < b.s end)
		for i, e in ipairs(temp) do
			local tChar, tHRP = getCharHRP(e.p)
			if tHRP then
				if e.s ~= i then
					removeCarryWeldBetween(cHRP, tHRP)
					tHRP.CFrame = cHRP.CFrame * slotOffset(i)
					ensureCarryWeldBetween(cHRP, tHRP)
					slotByCarrier[carrier.UserId][e.p.UserId] = i
				else
					ensureCarryWeldBetween(cHRP, tHRP)
				end
			end
		end
	end)
	releaseLock(carrier.UserId)
end

-- Notify
local function sendStart(carrier: Player, target: Player)
	local total = countCarried(carrier)
	CarryRemote:FireClient(carrier, "Start", {
		carrierId=carrier.UserId, carrierName=carrier.DisplayName,
		targetId=target.UserId, targetName=target.DisplayName,
		youAreCarrier=true, carrierActiveCount=total
	})
	CarryRemote:FireClient(target, "Start", {
		carrierId=carrier.UserId, carrierName=carrier.DisplayName,
		targetId=target.UserId, targetName=target.DisplayName,
		youAreCarrier=false
	})
end
local function sendEndForCarrierOnly(carrier: Player, removedTarget: Player, reason: string?)
	local total = countCarried(carrier)
	CarryRemote:FireClient(carrier, "End", {
		reason = reason or "end",
		youAreCarrier = true,
		carrierActiveCount = total,
		removedId = removedTarget.UserId,
		removedName = removedTarget.DisplayName,
	})
end
local function sendEndPair(carrier: Player, target: Player, reason: string?)
	local total = countCarried(carrier)
	CarryRemote:FireClient(carrier, "End", {
		reason = reason or "end",
		youAreCarrier = true,
		carrierActiveCount = total,
		removedId = target.UserId,
		removedName = target.DisplayName,
	})
	local still = countCarried(target)
	CarryRemote:FireClient(target, "End", {reason = reason or "end", youAreCarrier = false, yourCarryCount = still})
end

-- Detach
local function detachPair(carrier: Player, target: Player, reason: string?)
	local cUID = carrier.UserId
	local tUID = target.UserId

	acquireLock(cUID)
	local cChar, cHRP = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)

	if cHRP and tHRP then
		removeCarryWeldBetween(cHRP, tHRP)
	end

	if tHum then
		restoreHumState(tUID, tHum)
		tHum.Sit = false
		tHum.Jump = false
		tHum:ChangeState(Enum.HumanoidStateType.Running)
	end

	if tHRP then
		pcall(function()
			tHRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
			tHRP.AssemblyAngularVelocity = Vector3.new(0,0,0)
		end)
		giveSelfOwnership(target)
	end

	restoreCarriedLight(tUID)

	local cmap = carryingByCarrier[cUID]
	if cmap then
		cmap[tUID] = nil
		if not next(cmap) then carryingByCarrier[cUID] = nil end
	end
	if slotByCarrier[cUID] then slotByCarrier[cUID][tUID] = nil end
	carriedByTarget[tUID] = nil

	releaseLock(cUID)

	sendEndPair(carrier, target, reason)

	task.defer(function()
		if carryingByCarrier[cUID] then reindexSlots(carrier) end
		sendCarrierList(carrier)
	end)
end

local function detachAllForCarrier(carrier: Player, reason: string?)
	local cmap = carryingByCarrier[carrier.UserId]; if not cmap then return end
	local list = {}
	for _, t in pairs(cmap) do table.insert(list, t) end
	for _, t in ipairs(list) do detachPair(carrier, t, reason) end
end

local function detachIfAny(p: Player, reason: string?)
	if carriedByTarget[p.UserId] then
		detachPair(carriedByTarget[p.UserId], p, reason)
	elseif carryingByCarrier[p.UserId] then
		detachAllForCarrier(p, reason)
	end
end

local function safeDetachIfAny(p: Player, reason: string?)
	if detachGuard[p.UserId] then return end
	detachGuard[p.UserId] = true
	task.defer(function()
		detachIfAny(p, reason)
		detachGuard[p.UserId] = nil
	end)
end

-- Transfer
local function transferPassengersToAtomic(newCarrier: Player, oldCarrier: Player)
	local oldMap = carryingByCarrier[oldCarrier.UserId]; if not oldMap then return end
	local smapOld = slotByCarrier[oldCarrier.UserId] or {}
	local arr = {}
	for tid, t in pairs(oldMap) do table.insert(arr, {t=t, s=smapOld[tid] or 999}) end
	table.sort(arr, function(a,b) return a.s < b.s end)

	local _, newHRP = getCharHRP(newCarrier)
	local _, oldHRP = getCharHRP(oldCarrier)
	if not newHRP or not oldHRP then return end

	acquireLocks(newCarrier.UserId, oldCarrier.UserId)

	for _, entry in ipairs(arr) do
		local t: Player = entry.t
		local tChar, tHRP, tHum = getCharHRP(t)
		if tChar and tHRP and tHum then
			local used, smNew = {}, getSlotMap(newCarrier)
			for _, idx in pairs(smNew) do used[idx] = true end
			local slotIdx
			for i = 1, MAX_CARRY do if not used[i] then slotIdx = i break end end
			if slotIdx then
				removeCarryWeldBetween(oldHRP, tHRP)
				tHRP.CFrame = newHRP.CFrame * slotOffset(slotIdx)
				ensureCarryWeldBetween(newHRP, tHRP)

				tHum.AutoRotate = false
				tHum.WalkSpeed = 0
				if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end
				tHum.Sit = true
				tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				tHum.Jump = false

				giveCarrierOwnership(t, newCarrier)

				local oldMap2 = carryingByCarrier[oldCarrier.UserId]
				if oldMap2 then
					oldMap2[t.UserId] = nil
					if not next(oldMap2) then carryingByCarrier[oldCarrier.UserId] = nil end
				end
				if slotByCarrier[oldCarrier.UserId] then slotByCarrier[oldCarrier.UserId][t.UserId] = nil end
				getCarryMap(newCarrier)[t.UserId] = t
				getSlotMap(newCarrier)[t.UserId] = slotIdx
				carriedByTarget[t.UserId] = newCarrier

				sendEndForCarrierOnly(oldCarrier, t, "transfer")
				sendStart(newCarrier, t)
			end
		end
	end

	releaseLocks(newCarrier.UserId, oldCarrier.UserId)

	if carryingByCarrier[oldCarrier.UserId] then reindexSlots(oldCarrier) end
	sendCarrierList(newCarrier)
	sendCarrierList(oldCarrier)
end

-- Pending cleanup loop
task.spawn(function()
	while true do
		task.wait(2)
		local now = os.clock()
		for targetId, info in pairs(pending) do
			if now - info.time > PENDING_TIMEOUT then
				if info.requester and info.requester.Parent == Players then
					CarryRemote:FireClient(info.originator or info.requester, "RequestExpired", {targetId = targetId})
					if info.target then CarryRemote:FireClient(info.target, "PromptExpire", {}) end
				end
				pending[targetId] = nil
			end
		end
	end
end)

local function hasPendingIncoming(p: Player)
	for _, info in pairs(pending) do
		if info.target == p then
			return true
		end
	end
	return false
end
local function hasPendingOutgoing(p: Player)
	for _, info in pairs(pending) do
		if info.originator == p then
			return true
		end
	end
	return false
end

-- Start Carry
local function startCarry(carrier: Player, target: Player)
	if DEBUG then print(string.format("[CARRY DEBUG] startCarry called: carrier=%s, target=%s", carrier.Name, target.Name)) end

	local cChar, cHRP = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if not (cChar and cHRP and tChar and tHRP and tHum) then 
		if DEBUG then print("[CARRY DEBUG] startCarry FAILED: missing character parts") end
		return false, "character missing" 
	end

	acquireLock(carrier.UserId)
	local ok, err = pcall(function()
		if (cHRP.Position - tHRP.Position).Magnitude > MAX_DISTANCE then error("too far") end
		if not canCarrierRequest(carrier) then error("busy") end
		if not targetAvailable(target) then error("busy") end

		local extra = countCarried(target)
		if (countCarried(carrier) + 1 + extra) > MAX_CARRY then error("limit_transfer") end

		local used, sm = {}, getSlotMap(carrier)
		for _, idx in pairs(sm) do used[idx] = true end
		local slotIdx
		for i = 1, MAX_CARRY do if not used[i] then slotIdx = i break end end
		if not slotIdx then error("limit") end

		tHRP.CFrame = cHRP.CFrame * slotOffset(slotIdx)
		ensureCarryWeldBetween(cHRP, tHRP)

		-- ✅ AUTO-UNEQUIP: Unequip tools before carry
		if tHum then
			tHum:UnequipTools()  -- Triggers Unequipped event
			task.wait()  -- ✅ FIX: Wait for tool scripts (like SpeedCoil) to finish onUnequip
		end
		
		-- ✅ Cleanup flying effects (FlyingSpeed, AdminWing)
		local FlyingToolCleanup = nil
		pcall(function()
			FlyingToolCleanup = require(script.Parent.FlyingToolCleanup)
		end)
		if FlyingToolCleanup then
			FlyingToolCleanup:CleanupAll(target)
		end

		-- ✅ FIX: Reset WalkSpeed to default BEFORE saving, to prevent speed exploits
		-- This ensures any boosted speed from tools is cleared
		local currentSpeed = tHum.WalkSpeed
		if currentSpeed > 16 then
			tHum.WalkSpeed = 16  -- Reset to default before saving
		end

		saveHumState(target.UserId, tHum)
		tHum.AutoRotate = false
		tHum.WalkSpeed = 0
		if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end
		tHum.Sit = true
		tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		tHum.Jump = false

		makeCarriedLight(tChar, target.UserId)

		giveCarrierOwnership(target, carrier)

		getCarryMap(carrier)[target.UserId] = target
		getSlotMap(carrier)[target.UserId] = slotIdx
		carriedByTarget[target.UserId] = carrier

		local function bindCleanupForCharacter(char: Instance, p: Player, isCarrier: boolean)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Died:Connect(function()
					if isCarrier then
						local carriedPlayers = carryingByCarrier[p.UserId]
						if carriedPlayers then
							for _, carried in pairs(carriedPlayers) do
								local ch = carried.Character
								if ch then
									local chHum = ch:FindFirstChildOfClass("Humanoid")
									if chHum and chHum.Health > 0 then
										chHum.Health = 0
									end
								end
							end
						end
					end
					safeDetachIfAny(p, "death")
				end)
			end
			char.AncestryChanged:Connect(function(_, parent)
				if not parent then safeDetachIfAny(p, "character removed") end
			end)
		end
		bindCleanupForCharacter(cChar, carrier, true)
		bindCleanupForCharacter(tChar, target, false)

		sendStart(carrier, target)
		if DEBUG then print(string.format("[CARRY DEBUG] startCarry SUCCESS: %s carrying %s", carrier.Name, target.Name)) end
	end)
	releaseLock(carrier.UserId)
	if not ok then 
		if DEBUG then print(string.format("[CARRY DEBUG] startCarry FAILED: %s", tostring(err))) end
		return false, tostring(err) 
	end

	if countCarried(target) > 0 then transferPassengersToAtomic(carrier, target) end
	sendCarrierList(carrier)
	return true
end

-- ==================== REMOTE HANDLERS (FULLY FIXED WITH DEBUG) ====================
CarryRemote.OnServerEvent:Connect(function(player: Player, action: string, data)
	if action == "Request" then
		local targetId = data and data.targetId
		local requestType = data and data.requestType or "carry"

		if DEBUG then print(string.format("\n[CARRY DEBUG] === REQUEST START ===")) end
		if DEBUG then print(string.format("[CARRY DEBUG] Requester: %s (ID: %d)", player.Name, player.UserId)) end
		if DEBUG then print(string.format("[CARRY DEBUG] TargetId: %s", tostring(targetId))) end
		if DEBUG then print(string.format("[CARRY DEBUG] RequestType: %s", requestType)) end

		if type(targetId) ~= "number" then return end
		local target = Players:GetPlayerByUserId(targetId)
		if not target or target == player then return end

		-- ✅ FIX: Track originator (player who clicked button)
		local actualCarrier, actualTarget, promptReceiver, promptMessage, originator

		if requestType == "be_carried" then
			actualCarrier = target  -- B becomes carrier
			actualTarget = player   -- A becomes target
			promptReceiver = target -- Prompt to B
			originator = player     -- ✅ A is originator!
			promptMessage = string.format("%s wants you to carry them. Accept?", player.DisplayName)

			if DEBUG then print(string.format("[CARRY DEBUG] Mode: BE_CARRIED")) end
			if DEBUG then print(string.format("[CARRY DEBUG] Originator: %s (who clicked)", originator.Name)) end
			if DEBUG then print(string.format("[CARRY DEBUG] ActualCarrier: %s (who will carry)", actualCarrier.Name)) end
			if DEBUG then print(string.format("[CARRY DEBUG] ActualTarget: %s (who will be carried)", actualTarget.Name)) end
			if DEBUG then print(string.format("[CARRY DEBUG] PromptReceiver: %s", promptReceiver.Name)) end
		else
			actualCarrier = player  -- A becomes carrier
			actualTarget = target   -- B becomes target
			promptReceiver = target -- Prompt to B
			originator = player     -- ✅ A is originator!
			promptMessage = string.format("%s wants to carry you. Accept?", player.DisplayName)

			if DEBUG then print(string.format("[CARRY DEBUG] Mode: CARRY")) end
			if DEBUG then print(string.format("[CARRY DEBUG] Originator: %s", originator.Name)) end
			if DEBUG then print(string.format("[CARRY DEBUG] ActualCarrier: %s", actualCarrier.Name)) end
			if DEBUG then print(string.format("[CARRY DEBUG] ActualTarget: %s", actualTarget.Name)) end
			if DEBUG then print(string.format("[CARRY DEBUG] PromptReceiver: %s", promptReceiver.Name)) end
		end

		local _, cHRP = getCharHRP(actualCarrier)
		local _, tHRP = getCharHRP(actualTarget)
		if not (cHRP and tHRP) then 
			if DEBUG then print("[CARRY DEBUG] REJECTED: Missing HRP") end
			return 
		end

		if (cHRP.Position - tHRP.Position).Magnitude > MAX_DISTANCE then
			if DEBUG then print("[CARRY DEBUG] REJECTED: Too far") end
			CarryRemote:FireClient(player, "TooFar", {targetId=targetId})
			return
		end

		local extra = countCarried(actualTarget)
		if (countCarried(actualCarrier) + 1 + extra) > MAX_CARRY then
			if DEBUG then print("[CARRY DEBUG] REJECTED: Limit exceeded") end
			CarryRemote:FireClient(player, "Limit", {max = MAX_CARRY, reason = "transfer"})
			return
		end

		if not canCarrierRequest(actualCarrier) or not targetAvailable(actualTarget) then
			if DEBUG then print("[CARRY DEBUG] REJECTED: Busy") end
			CarryRemote:FireClient(player, "Busy", {})
			return
		end

		if hasPendingIncoming(promptReceiver) or hasPendingOutgoing(originator) then
			if DEBUG then print("[CARRY DEBUG] REJECTED: Pending exists") end
			CarryRemote:FireClient(player, "Busy", {})
			return
		end

		-- ✅ FIX: Store with promptReceiver as key (who needs to accept)
		pending[promptReceiver.UserId] = {
			requester = actualCarrier,      -- Who will be carrier
			target = actualTarget,           -- Who will be carried
			time = os.clock(),
			requestType = requestType,
			originator = originator          -- ✅ Who clicked the button
		}

		if DEBUG then print(string.format("[CARRY DEBUG] Pending stored: pending[%d (%s)]", promptReceiver.UserId, promptReceiver.Name)) end
		if DEBUG then print(string.format("[CARRY DEBUG]   - requester (carrier): %s", actualCarrier.Name)) end
		if DEBUG then print(string.format("[CARRY DEBUG]   - target (carried): %s", actualTarget.Name)) end
		if DEBUG then print(string.format("[CARRY DEBUG]   - originator (clicked): %s", originator.Name)) end

		-- ✅ FIX: Send originator ID for avatar, not carrier ID!
		CarryRemote:FireClient(promptReceiver, "Prompt", {
			fromId = originator.UserId,           -- ✅ Show originator's avatar!
			fromName = originator.DisplayName,
			customMessage = promptMessage
		})

		if DEBUG then print(string.format("[CARRY DEBUG] Prompt sent to %s", promptReceiver.Name)) end
		if DEBUG then print(string.format("[CARRY DEBUG] Avatar will show: %s (ID: %d)", originator.Name, originator.UserId)) end
		if DEBUG then print(string.format("[CARRY DEBUG] === REQUEST END ===\n")) end

	elseif action == "Response" then
		local accept = data and data.accept == true
		local requesterId = data and data.requesterId

		if DEBUG then print(string.format("\n[CARRY DEBUG] === RESPONSE START ===")) end
		if DEBUG then print(string.format("[CARRY DEBUG] Responder: %s (ID: %d)", player.Name, player.UserId)) end
		if DEBUG then print(string.format("[CARRY DEBUG] RequesterId: %s", tostring(requesterId))) end
		if DEBUG then print(string.format("[CARRY DEBUG] Accept: %s", tostring(accept))) end

		if type(requesterId) ~= "number" then 
			if DEBUG then print("[CARRY DEBUG] FAILED: Invalid requesterId type") end
			return 
		end

		-- ✅ FIX: Check pending[player.UserId] since prompt was sent to player
		local pend = pending[player.UserId]

		if DEBUG then print(string.format("[CARRY DEBUG] Checking pending[%d (%s)]", player.UserId, player.Name)) end
		if DEBUG then 
			if pend then
				print(string.format("[CARRY DEBUG] Pending found!"))
				print(string.format("[CARRY DEBUG]   - requester: %s", pend.requester and pend.requester.Name or "nil"))
				print(string.format("[CARRY DEBUG]   - target: %s", pend.target and pend.target.Name or "nil"))
				print(string.format("[CARRY DEBUG]   - originator: %s", pend.originator and pend.originator.Name or "nil"))
			else
				print(string.format("[CARRY DEBUG] NO PENDING FOUND!"))
				print(string.format("[CARRY DEBUG] Current pending table:"))
				for uid, info in pairs(pending) do
					local p = Players:GetPlayerByUserId(uid)
					print(string.format("[CARRY DEBUG]   pending[%d] = %s", uid, p and p.Name or "unknown"))
				end
			end
		end

		if not pend then 
			if DEBUG then print("[CARRY DEBUG] FAILED: No pending request") end
			return 
		end

		-- ✅ Validate that requesterId matches
		if pend.originator and pend.originator.UserId ~= requesterId then
			if DEBUG then print(string.format("[CARRY DEBUG] FAILED: RequesterId mismatch (expected %d, got %d)", pend.originator.UserId, requesterId)) end
			return
		end

		pending[player.UserId] = nil
		if DEBUG then print("[CARRY DEBUG] Pending cleared") end

		if not accept then
			if DEBUG then print("[CARRY DEBUG] Request declined") end
			CarryRemote:FireClient(pend.originator, "Declined", {targetId = player.UserId})
			CarryRemote:FireClient(player, "PromptClose", {})
			if DEBUG then print(string.format("[CARRY DEBUG] === RESPONSE END ===\n")) end
			return
		end

		if DEBUG then print(string.format("[CARRY DEBUG] Executing startCarry(%s, %s)", pend.requester.Name, pend.target.Name)) end
		local ok2, err2 = startCarry(pend.requester, pend.target)

		if not ok2 then
			if DEBUG then print(string.format("[CARRY DEBUG] startCarry FAILED: %s", tostring(err2))) end
			if tostring(err2) == "limit_transfer" then
				CarryRemote:FireClient(pend.originator, "Limit", {max = MAX_CARRY, reason = "transfer"})
				CarryRemote:FireClient(player, "Failed", {reason="limit_transfer"})
			else
				CarryRemote:FireClient(pend.originator, "Failed", {reason=err2})
				CarryRemote:FireClient(player, "Failed", {reason=err2})
			end
		else
			if DEBUG then print("[CARRY DEBUG] startCarry SUCCESS!") end
		end

		if DEBUG then print(string.format("[CARRY DEBUG] === RESPONSE END ===\n")) end

	elseif action == "Stop" then
		local targetId = data and data.targetId

		if type(targetId) == "number" then
			local t = Players:GetPlayerByUserId(targetId)
			if t and carryingByCarrier[player.UserId] and carryingByCarrier[player.UserId][targetId] then
				detachPair(player, t, "stop")
				return
			end
		else
			if carryingByCarrier[player.UserId] then
				detachAllForCarrier(player, "stop")
				return
			end
		end

		detachIfAny(player, "stop")
	end
end)

-- Respawn - FORCE CLEANUP ALL STATES
local function onCharacterAdded(p: Player, char: Model)
	task.defer(function()
		local uid = p.UserId
		
		-- ✅ FIX: Force clear ALL locks and states for this player
		lockMap[uid] = nil
		detachGuard[uid] = nil
		
		clearCarryWeldsForChar(char)
		
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			-- ✅ FIX: Force reset ALL humanoid properties
			hum.Sit = false
			hum.AutoRotate = true
			hum.WalkSpeed = 16
			if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			hum.PlatformStand = false
			hum.Jump = false
			
			-- ✅ FIX: Force change state to Running
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
		
		-- ✅ FIX: Clear ALL cached data for this player
		savedProps[uid] = nil
		savedHum[uid] = nil
		carriedByTarget[uid] = nil  -- Player is no longer being carried
		
		giveSelfOwnership(p)
		safeDetachIfAny(p, "respawn")
		
		print(string.format("✅ [CARRY] Character respawn cleanup complete for %s", p.Name))
	end)
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(char) onCharacterAdded(p, char) end)
end)

Players.PlayerRemoving:Connect(function(p: Player)
	local uid = p.UserId
	
	-- Clear any pending where this player is involved
	for pendingUid, info in pairs(pending) do
		if info.originator == p or info.requester == p or info.target == p then
			pending[pendingUid] = nil
		end
	end
	
	detachIfAny(p, "left")
	
	-- ✅ FIX: Cleanup all remaining caches for this player
	savedProps[uid] = nil
	savedHum[uid] = nil
	lockMap[uid] = nil
	detachGuard[uid] = nil
	carryingByCarrier[uid] = nil
	carriedByTarget[uid] = nil
	slotByCarrier[uid] = nil
end)

print("✅ [CARRY SERVER] Loaded with FULL DEBUG + ALL FIXES")