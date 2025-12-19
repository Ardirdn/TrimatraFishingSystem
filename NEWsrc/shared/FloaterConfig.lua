--[[
    FLOATER CONFIG
    Place in ReplicatedStorage/Modules/FloaterConfig.lua
    
    SINGLE SOURCE OF TRUTH untuk semua data floater.
    Semua script lain (shop, fishing, client) harus ambil data dari sini.
    
    Setiap floater memiliki:
    - FloaterId: ID unik floater (harus sama dengan nama model di FishingRods/Floaters)
    - DisplayName: Nama yang ditampilkan di UI
    - Description: Deskripsi item
    - Price: Harga dalam game currency (0 = gratis)
    - Category: Kategori floater (Basic, Epic, Legendary)
    - Rarity: Rarity floater (Common, Uncommon, Rare, Epic, Legendary)
    - LuckBonus: Bonus luck dalam persen
    - ImageId: Asset ID untuk thumbnail
    - IsPremium: Apakah item premium (beli dengan Robux)
    - ProductId: Developer Product ID jika premium
    
    NOTE: Rod dan Floater adalah INDEPENDENT - player bebas mix-and-match!
    Equipment disimpan terpisah di DataHandler (EquippedRod & EquippedFloater)
]]

local FloaterConfig = {}

-- Rarity colors (untuk reference)
FloaterConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

-- Default floater ID (gratis untuk semua pemain baru)
FloaterConfig.DefaultFloater = "FloaterDoll"

-- ==================== FLOATER DATA ====================
FloaterConfig.Floaters = {
	-- ==================== BASIC FLOATERS ====================
	["FloaterDoll"] = {
		FloaterId = "FloaterDoll",
		DisplayName = "Doll Floater",
		Description = "Cute doll-shaped floater. Perfect for beginners!",
		Price = 0, -- Free starter
		Category = "Basic",
		Rarity = "Common",
		LuckBonus = 0,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	-- ==================== EPIC FLOATERS ====================
	["BoneFloater"] = {
		FloaterId = "BoneFloater",
		DisplayName = "Bone Floater",
		Description = "Skeletal floater crafted from ancient bones. Attracts undead sea creatures!",
		Price = 110000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 30,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["DevilFloater"] = {
		FloaterId = "DevilFloater",
		DisplayName = "Devil Floater",
		Description = "Forged in hellfire, this demonic floater attracts the most sinister catches!",
		Price = 750000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 35,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["IcedFloater"] = {
		FloaterId = "IcedFloater",
		DisplayName = "Iced Floater",
		Description = "Frozen in eternal ice, perfect for catching arctic creatures!",
		Price = 500000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 30,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["InfernoFloater"] = {
		FloaterId = "InfernoFloater",
		DisplayName = "Inferno Floater",
		Description = "Burns with eternal flames! Fish are drawn to its warmth and light.",
		Price = 250000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 40,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["KnightFloater"] = {
		FloaterId = "KnightFloater",
		DisplayName = "Knight Floater",
		Description = "Medieval armored floater for honorable fishing! For the realm!",
		Price = 1000000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 45,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["WolfFloater"] = {
		FloaterId = "WolfFloater",
		DisplayName = "Wolf Floater",
		Description = "Hunt your prey with the instincts of a wolf. Howl at the moon!",
		Price = 70000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 35,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	-- ==================== LEGENDARY FLOATERS ====================
	["ReaperFloater"] = {
		FloaterId = "ReaperFloater",
		DisplayName = "Reaper Floater",
		Description = "The ultimate floater. Harvest souls from the deep abyss!",
		Price = 1500000,
		Category = "Legendary",
		Rarity = "Legendary",
		LuckBonus = 75,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},
}

-- ==================== HELPER FUNCTIONS ====================

-- Get floater by ID
function FloaterConfig.GetFloaterById(floaterId)
	return FloaterConfig.Floaters[floaterId]
end

-- Get all floaters as array (for shop display, ordered by price)
function FloaterConfig.GetFloatersArray()
	local floatersArray = {}
	for floaterId, floaterData in pairs(FloaterConfig.Floaters) do
		-- Add FloaterId field for consistency
		local floaterWithId = {}
		for k, v in pairs(floaterData) do
			floaterWithId[k] = v
		end
		floaterWithId.FloaterId = floaterId
		table.insert(floatersArray, floaterWithId)
	end
	
	-- Sort by price
	table.sort(floatersArray, function(a, b)
		return a.Price < b.Price
	end)
	
	return floatersArray
end

-- Get floaters by category
function FloaterConfig.GetFloatersByCategory(category)
	local result = {}
	for floaterId, floaterData in pairs(FloaterConfig.Floaters) do
		if floaterData.Category == category then
			local floaterWithId = {}
			for k, v in pairs(floaterData) do
				floaterWithId[k] = v
			end
			floaterWithId.FloaterId = floaterId
			table.insert(result, floaterWithId)
		end
	end
	return result
end

-- Get floater price
function FloaterConfig.GetPrice(floaterId)
	local floater = FloaterConfig.Floaters[floaterId]
	return floater and floater.Price or 0
end

-- Get floater luck bonus
function FloaterConfig.GetLuckBonus(floaterId)
	local floater = FloaterConfig.Floaters[floaterId]
	return floater and floater.LuckBonus or 0
end

-- Check if floater exists
function FloaterConfig.Exists(floaterId)
	return FloaterConfig.Floaters[floaterId] ~= nil
end

-- Get rarity color
function FloaterConfig.GetRarityColor(floaterId)
	local floater = FloaterConfig.Floaters[floaterId]
	if floater then
		return FloaterConfig.RarityColors[floater.Rarity] or FloaterConfig.RarityColors.Common
	end
	return FloaterConfig.RarityColors.Common
end

return FloaterConfig
