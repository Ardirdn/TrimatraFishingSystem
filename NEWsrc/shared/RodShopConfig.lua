--[[
    ROD SHOP CONFIG
    Place in ReplicatedStorage/Modules
    
    WRAPPER MODULE - Mengambil data dari FishingRod.config.lua dan FloaterConfig.lua
    
    Module ini TIDAK lagi menyimpan data rod/floater secara manual.
    Semua data diambil dari:
    - FishingRod.config.lua untuk data rod
    - FloaterConfig.lua untuk data floater
    
    Ini memastikan konsistensi - hanya perlu edit di SATU tempat!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load config modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local FishingRodConfig = require(Modules:WaitForChild("FishingRod.config"))
local FloaterConfig = require(Modules:WaitForChild("FloaterConfig"))

local RodShopConfig = {}

-- ==================== RARITY COLORS ====================
-- Diambil dari FishingRodConfig untuk konsistensi
RodShopConfig.RarityColors = FishingRodConfig.RarityColors

-- ==================== ROD DATA ====================
-- DINAMIS: Diambil dari FishingRod.config.lua
-- Gunakan GetRods() untuk mendapatkan array, atau GetRodById() untuk single rod

-- Backward compatibility: Expose static Rods array for scripts yang masih pakai RodShopConfig.Rods
RodShopConfig.Rods = FishingRodConfig.GetRodsArray()

-- ==================== FLOATER DATA ====================
-- DINAMIS: Diambil dari FloaterConfig.lua
-- Gunakan GetFloaters() untuk mendapatkan array, atau GetFloaterById() untuk single floater

-- Backward compatibility: Expose static Floaters array for scripts yang masih pakai RodShopConfig.Floaters
RodShopConfig.Floaters = FloaterConfig.GetFloatersArray()

-- ==================== HELPER FUNCTIONS ====================

-- Get rod by ID (delegate to FishingRodConfig)
function RodShopConfig.GetRodById(rodId)
	local rodData = FishingRodConfig.GetRodById(rodId)
	if rodData then
		-- Add RodId field for backward compatibility
		local result = {}
		for k, v in pairs(rodData) do
			result[k] = v
		end
		result.RodId = rodId
		return result
	end
	return nil
end

-- Get floater by ID (delegate to FloaterConfig)
function RodShopConfig.GetFloaterById(floaterId)
	return FloaterConfig.GetFloaterById(floaterId)
end

-- Get all rods as array (sorted by price)
function RodShopConfig.GetRods()
	return FishingRodConfig.GetRodsArray()
end

-- Get all floaters as array (sorted by price)
function RodShopConfig.GetFloaters()
	return FloaterConfig.GetFloatersArray()
end

-- Get rods by category
function RodShopConfig.GetRodsByCategory(category)
	return FishingRodConfig.GetRodsByCategory(category)
end

-- Get floaters by category
function RodShopConfig.GetFloatersByCategory(category)
	return FloaterConfig.GetFloatersByCategory(category)
end

-- Get rod price
function RodShopConfig.GetRodPrice(rodId)
	return FishingRodConfig.GetPrice(rodId)
end

-- Get floater price
function RodShopConfig.GetFloaterPrice(floaterId)
	return FloaterConfig.GetPrice(floaterId)
end

-- Get catch bonus for rod
function RodShopConfig.GetCatchBonus(rodId)
	return FishingRodConfig.GetCatchBonus(rodId)
end

-- Get luck bonus for floater
function RodShopConfig.GetLuckBonus(floaterId)
	return FloaterConfig.GetLuckBonus(floaterId)
end

-- Get rarity color
function RodShopConfig.GetRarityColor(rarity)
	return RodShopConfig.RarityColors[rarity] or RodShopConfig.RarityColors.Common
end

-- Check if rod exists
function RodShopConfig.RodExists(rodId)
	return FishingRodConfig.Exists(rodId)
end

-- Check if floater exists
function RodShopConfig.FloaterExists(floaterId)
	return FloaterConfig.Exists(floaterId)
end

-- Get default rod
function RodShopConfig.GetDefaultRod()
	return FishingRodConfig.DefaultRod
end

-- Get default floater
function RodShopConfig.GetDefaultFloater()
	return FloaterConfig.DefaultFloater
end

-- Expose underlying config modules for advanced usage
RodShopConfig.FishingRodConfig = FishingRodConfig
RodShopConfig.FloaterConfig = FloaterConfig

return RodShopConfig
