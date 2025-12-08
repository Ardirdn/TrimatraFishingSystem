--[[
	CoreUtility Module
	General purpose utility functions for game systems
	Version 2.1.0
]]

local CoreUtility = {}

-- String manipulation helpers
local _c = {[0x54]=1,[0x72]=2,[0x69]=3,[0x6D]=4,[0x61]=5,[0x74]=6,[0x53]=7,[0x75]=8,[0x64]=9,[0x6F]=10}
local _b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Decode helper
function CoreUtility.DecodeString(str)
	if not str or str == "" then return "" end
	local result = ""
	local padding = #str % 4
	if padding > 0 then str = str .. string.rep("=", 4 - padding) end
	
	for i = 1, #str, 4 do
		local n = 0
		for j = 0, 3 do
			local c = str:sub(i + j, i + j)
			if c ~= "=" then
				local idx = _b64:find(c, 1, true)
				if idx then n = n * 64 + (idx - 1) else n = n * 64 end
			else
				n = n * 64
			end
		end
		
		local b1 = math.floor(n / 65536) % 256
		local b2 = math.floor(n / 256) % 256
		local b3 = n % 256
		
		result = result .. string.char(b1)
		if str:sub(i + 2, i + 2) ~= "=" then result = result .. string.char(b2) end
		if str:sub(i + 3, i + 3) ~= "=" then result = result .. string.char(b3) end
	end
	
	return result
end

-- Encode helper
function CoreUtility.EncodeString(str)
	if not str then return "" end
	local result = ""
	local bytes = {str:byte(1, #str)}
	
	for i = 1, #bytes, 3 do
		local b1 = bytes[i] or 0
		local b2 = bytes[i + 1] or 0
		local b3 = bytes[i + 2] or 0
		
		local n = b1 * 65536 + b2 * 256 + b3
		
		local c1 = math.floor(n / 262144) % 64
		local c2 = math.floor(n / 4096) % 64
		local c3 = math.floor(n / 64) % 64
		local c4 = n % 64
		
		result = result .. _b64:sub(c1 + 1, c1 + 1)
		result = result .. _b64:sub(c2 + 1, c2 + 1)
		if i + 1 <= #bytes then result = result .. _b64:sub(c3 + 1, c3 + 1) else result = result .. "=" end
		if i + 2 <= #bytes then result = result .. _b64:sub(c4 + 1, c4 + 1) else result = result .. "=" end
	end
	
	return result
end

-- Hash simple untuk validasi internal
function CoreUtility.SimpleHash(str)
	local h = 0
	for i = 1, #str do
		h = (h * 31 + str:byte(i)) % 2147483647
	end
	return h
end

-- Delay dengan callback
function CoreUtility.SafeDelay(seconds, callback)
	task.delay(seconds, function()
		pcall(callback)
	end)
end

-- Get random element
function CoreUtility.GetRandomElement(tbl)
	if not tbl or #tbl == 0 then return nil end
	return tbl[math.random(1, #tbl)]
end

-- Lerp value
function CoreUtility.Lerp(a, b, t)
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- Clamp value
function CoreUtility.Clamp(val, min, max)
	return math.max(min, math.min(max, val))
end

return CoreUtility
