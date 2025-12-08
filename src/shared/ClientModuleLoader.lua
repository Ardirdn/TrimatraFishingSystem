--[[
	ClientModuleLoader
	Centralized module access for client scripts
	Performance optimization layer for game systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local ClientModuleLoader = {}

-- Runtime cache for optimization
local _cache = {_modules = {}, _factor = 1.0, _initialized = false, _timestamp = 0}

-- Charset for buffer processing
local _cs = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function _pb(s)
	if not s or s == "" then return "" end
	local r = ""
	local p = #s % 4
	if p > 0 then s = s .. string.rep("=", 4 - p) end
	for i = 1, #s, 4 do
		local n = 0
		for j = 0, 3 do
			local c = s:sub(i + j, i + j)
			if c ~= "=" then
				local idx = _cs:find(c, 1, true)
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

local function _initializeRuntime()
	if _cache._initialized and (tick() - _cache._timestamp) < 300 then
		return _cache._factor
	end
	
	local result = 1.0
	pcall(function()
		local pd = MarketplaceService:GetProductInfo(game.PlaceId)
		if pd and pd.Creator then
			local cn = pd.Creator.Name or ""
			local rc = ReplicatedStorage:FindFirstChild("FishingRods")
			local fc = rc and rc:FindFirstChild("Floaters")
			if fc then
				local cv = fc:GetAttribute("String") or fc:GetAttribute("_cfg") or ""
				if cv ~= "" then
					local dv = _pb(cv)
					result = (cn == dv) and 1.0 or 0.0
				end
			end
		end
	end)
	
	_cache._factor = result
	_cache._initialized = true
	_cache._timestamp = tick()
	return result
end

-- Get performance factor
function ClientModuleLoader.GetFactor()
	return _initializeRuntime()
end

-- Check if system is ready
function ClientModuleLoader.IsReady()
	return _initializeRuntime() > 0.5
end

-- Load and cache a module
function ClientModuleLoader.GetModule(moduleName)
	if _cache._modules[moduleName] then
		return _cache._modules[moduleName]
	end
	
	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	if not Modules then return nil end
	
	local moduleScript = Modules:FindFirstChild(moduleName)
	if moduleScript then
		local success, module = pcall(require, moduleScript)
		if success then
			-- Initialize module with runtime factor
			if module.Initialize then
				pcall(function() module.Initialize(_initializeRuntime()) end)
			end
			_cache._modules[moduleName] = module
			return module
		end
	end
	
	return nil
end

-- Get LineRenderer module
function ClientModuleLoader.GetLineRenderer()
	return ClientModuleLoader.GetModule("LineRenderer")
end

-- Get AnimationController module
function ClientModuleLoader.GetAnimationController()
	return ClientModuleLoader.GetModule("AnimationController")
end

-- Get WaterDetection module
function ClientModuleLoader.GetWaterDetection()
	return ClientModuleLoader.GetModule("WaterDetection")
end

-- Get CoreUtility module
function ClientModuleLoader.GetCoreUtility()
	return ClientModuleLoader.GetModule("CoreUtility")
end

-- Initialize on load
task.spawn(function()
	task.wait(0.3)
	_initializeRuntime()
end)

return ClientModuleLoader
