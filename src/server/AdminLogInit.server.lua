--[[
    ADMIN LOG INITIALIZER
    Memastikan AdminLogService diinisialisasi terlebih dahulu
    sehingga RemoteFunctions tersedia untuk scripts lain
]]

-- Initialize AdminLogService early
local AdminLogService = require(script.Parent.AdminLogService)

print("✅ [ADMIN LOG INIT] AdminLogService initialized")
