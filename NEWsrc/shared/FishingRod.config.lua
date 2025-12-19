--[[
    FISHING ROD CONFIG
    Place in ReplicatedStorage/Modules/FishingRod.config.lua
    
    SINGLE SOURCE OF TRUTH untuk semua data fishing rod.
    Semua script lain (shop, fishing, client) harus ambil data dari sini.
    
    Setiap rod memiliki:
    - FISHING STATS:
      - ToolName, ToolObject: Nama tool
      - MaxThrowDistance, ThrowHeight: Jarak dan tinggi lempar
      - BobSpeed, BobHeight: Animasi bobbing floater
      - LineStyle: Warna dan style tali pancing
    
    - SHOP DATA:
      - DisplayName: Nama yang ditampilkan di UI
      - Description: Deskripsi item
      - Price: Harga dalam game currency (0 = gratis)
      - Category: Kategori rod (Starter, Basic, Epic, Legendary)
      - Rarity: Rarity rod (Common, Uncommon, Rare, Epic, Legendary)
      - CatchBonus: Bonus catch rate dalam persen
      - ImageId: Asset ID untuk thumbnail
      - IsPremium: Apakah item premium (beli dengan Robux)
      - ProductId: Developer Product ID jika premium
    
    NOTE: Rod dan Floater adalah INDEPENDENT - player bebas mix-and-match!
    Equipment floater disimpan terpisah di DataHandler.EquippedFloater
]]

local FishingRodConfig = {}

-- Rarity colors (untuk reference)
FishingRodConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

-- Default rod ID (gratis untuk semua pemain baru)
FishingRodConfig.DefaultRod = "WoodRod"

-- Default Line Style (used if not specified per rod)
FishingRodConfig.DefaultLineStyle = {
	Color = Color3.fromRGB(0, 255, 255),
	Width = 0.16,
	Transparency = 0.12,
	LightEmission = 10,
	IsNeon = true,
}

FishingRodConfig.Rods = {
	-- ==================== STARTER RODS ====================
	["WoodRod"] = {
		-- Fishing Stats
		ToolName = "WoodRod",
		ToolObject = "WoodRod",
		MaxThrowDistance = 35,
		ThrowHeight = 9,
		BobSpeed = 2.5,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(139, 90, 43), -- Brown (wooden)
			Width = 0.12,
			Transparency = 0.2,
			LightEmission = 0,
			IsNeon = false,
		},
		-- Shop Data
		DisplayName = "Wooden Rod",
		Description = "Basic wooden fishing rod. Perfect for beginners!",
		Price = 0, -- Free starter
		Category = "Starter",
		Rarity = "Common",
		CatchBonus = 0,
		ImageId = "rbxassetid://125451066625051",
		IsPremium = false,
		ProductId = nil
	},

	-- ==================== BASIC RODS ====================
	["BambooRod"] = {
		-- Fishing Stats
		ToolName = "BambooRod",
		ToolObject = "BambooRod",
		MaxThrowDistance = 40,
		ThrowHeight = 10,
		BobSpeed = 2.2,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(107, 142, 35), -- Olive green (bamboo)
			Width = 0.12,
			Transparency = 0.2,
			LightEmission = 0,
			IsNeon = false,
		},
		-- Shop Data
		DisplayName = "Bamboo Rod",
		Description = "Lightweight bamboo rod with decent range and flexibility.",
		Price = 50000,
		Category = "Basic",
		Rarity = "Common",
		CatchBonus = 5,
		ImageId = "rbxassetid://114012325195175",
		IsPremium = false,
		ProductId = nil
	},

	["BananaRod"] = {
		-- Fishing Stats
		ToolName = "BananaRod",
		ToolObject = "BananaRod",
		MaxThrowDistance = 55,
		ThrowHeight = 16,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 225, 53), -- Bright yellow
			Width = 0.14,
			Transparency = 0.15,
			LightEmission = 3,
			IsNeon = true,
		},
		-- Shop Data
		DisplayName = "Banana Rod",
		Description = "A-peel-ing rod that's perfect for tropical fishing!",
		Price = 25000,
		Category = "Basic",
		Rarity = "Uncommon",
		CatchBonus = 10,
		ImageId = "rbxassetid://92273519147643",
		IsPremium = false,
		ProductId = nil
	},

	["BaconRod"] = {
		-- Fishing Stats
		ToolName = "BaconRod",
		ToolObject = "BaconRod",
		MaxThrowDistance = 45,
		ThrowHeight = 12,
		BobSpeed = 2.5,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(200, 80, 60), -- Bacon red-brown
			Width = 0.18,
			Transparency = 0.1,
			LightEmission = 2,
			IsNeon = false,
		},
		-- Shop Data
		DisplayName = "Bacon Rod",
		Description = "Crispy and delicious... wait, for fishing?!",
		Price = 10000,
		Category = "Basic",
		Rarity = "Uncommon",
		CatchBonus = 12,
		ImageId = "rbxassetid://136402039436335",
		IsPremium = false,
		ProductId = nil
	},

	-- ==================== EPIC RODS ====================
	["DevilRod"] = {
		-- Fishing Stats
		ToolName = "DevilRod",
		ToolObject = "DevilRod",
		MaxThrowDistance = 48,
		ThrowHeight = 13,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 50, 50), -- Devil red
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 8,
			IsNeon = true,
		},
		-- Shop Data
		DisplayName = "Devil Rod",
		Description = "Forged in hellfire, this rod attracts the most sinister catches.",
		Price = 750000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 25,
		ImageId = "rbxassetid://82705729702042",
		IsPremium = false,
		ProductId = nil
	},

	["WolfRod"] = {
		-- Fishing Stats
		ToolName = "WolfRod",
		ToolObject = "WolfRod",
		MaxThrowDistance = 50,
		ThrowHeight = 14,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(100, 100, 120), -- Wolf gray
			Width = 0.14,
			Transparency = 0.15,
			LightEmission = 2,
			IsNeon = false,
		},
		-- Shop Data
		DisplayName = "Wolf Rod",
		Description = "Hunt your prey with the instincts of a wolf.",
		Price = 85000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 28,
		ImageId = "rbxassetid://101003529130674",
		IsPremium = false,
		ProductId = nil
	},

	["BoneRod"] = {
		-- Fishing Stats
		ToolName = "BoneRod",
		ToolObject = "BoneRod",
		MaxThrowDistance = 54,
		ThrowHeight = 15,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(230, 230, 230), -- Bone white
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 4,
			IsNeon = true,
		},
		-- Shop Data
		DisplayName = "Bone Rod",
		Description = "Crafted from ancient bones, attracts skeletal sea creatures.",
		Price = 175000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 30,
		ImageId = "rbxassetid://93265344164754",
		IsPremium = false,
		ProductId = nil
	},

	["InfernoRod"] = {
		-- Fishing Stats
		ToolName = "InfernoRod",
		ToolObject = "InfernoRod",
		MaxThrowDistance = 52,
		ThrowHeight = 15,
		BobSpeed = 2.3,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 100, 0), -- Inferno orange
			Width = 0.18,
			Transparency = 0.08,
			LightEmission = 10,
			IsNeon = true,
		},
		-- Shop Data
		DisplayName = "Inferno Rod",
		Description = "Burns with eternal flames, perfect for volcanic waters.",
		Price = 250000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 32,
		ImageId = "rbxassetid://119753611564970",
		IsPremium = false,
		ProductId = nil
	},

	["IcedRod"] = {
		-- Fishing Stats
		ToolName = "IcedRod",
		ToolObject = "IcedRod",
		MaxThrowDistance = 50,
		ThrowHeight = 14,
		BobSpeed = 2.1,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(150, 220, 255), -- Ice blue
			Width = 0.15,
			Transparency = 0.1,
			LightEmission = 6,
			IsNeon = true,
		},
		-- Shop Data
		DisplayName = "Iced Rod",
		Description = "Frozen in eternal ice, attracts arctic creatures.",
		Price = 350000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 30,
		ImageId = "rbxassetid://100923661468652",
		IsPremium = false,
		ProductId = nil
	},

	["KnightRod"] = {
		-- Fishing Stats
		ToolName = "KnightRod",
		ToolObject = "KnightRod",
		MaxThrowDistance = 55,
		ThrowHeight = 16,
		BobSpeed = 2.0,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(192, 192, 192), -- Silver armor
			Width = 0.18,
			Transparency = 0.1,
			LightEmission = 3,
			IsNeon = false,
		},
		-- Shop Data
		DisplayName = "Knight Rod",
		Description = "Medieval power for honorable anglers. For the realm!",
		Price = 1500000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 35,
		ImageId = "rbxassetid://123978094818764",
		IsPremium = false,
		ProductId = nil
	},

	-- ==================== LEGENDARY RODS ====================
	["ReaperRod"] = {
		-- Fishing Stats
		ToolName = "ReaperRod",
		ToolObject = "ReaperRod",
		MaxThrowDistance = 65,
		ThrowHeight = 18,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(50, 0, 80), -- Dark purple death
			Width = 0.20,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true,
		},
		-- Shop Data
		DisplayName = "Reaper Rod",
		Description = "The ultimate rod. Harvest souls from the deep abyss.",
		Price = 2500000,
		Category = "Legendary",
		Rarity = "Legendary",
		CatchBonus = 50,
		ImageId = "rbxassetid://107508488863884",
		IsPremium = false,
		ProductId = nil
	},
}

-- ==================== HELPER FUNCTIONS ====================

-- Get rod config by ID
function FishingRodConfig.GetRodById(rodId)
	return FishingRodConfig.Rods[rodId]
end

-- Get LineStyle for a rod
function FishingRodConfig.GetLineStyle(rodName)
	local rodConfig = FishingRodConfig.Rods[rodName]
	if rodConfig and rodConfig.LineStyle then
		return rodConfig.LineStyle
	end
	return FishingRodConfig.DefaultLineStyle
end

-- Get all rods as array (for shop display, ordered by price)
function FishingRodConfig.GetRodsArray()
	local rodsArray = {}
	for rodId, rodData in pairs(FishingRodConfig.Rods) do
		-- Create a copy with RodId field for compatibility
		local rodWithId = {}
		for k, v in pairs(rodData) do
			rodWithId[k] = v
		end
		rodWithId.RodId = rodId
		table.insert(rodsArray, rodWithId)
	end
	
	-- Sort by price
	table.sort(rodsArray, function(a, b)
		return a.Price < b.Price
	end)
	
	return rodsArray
end

-- Get rods by category
function FishingRodConfig.GetRodsByCategory(category)
	local result = {}
	for rodId, rodData in pairs(FishingRodConfig.Rods) do
		if rodData.Category == category then
			local rodWithId = {}
			for k, v in pairs(rodData) do
				rodWithId[k] = v
			end
			rodWithId.RodId = rodId
			table.insert(result, rodWithId)
		end
	end
	return result
end

-- Get rod price
function FishingRodConfig.GetPrice(rodId)
	local rod = FishingRodConfig.Rods[rodId]
	return rod and rod.Price or 0
end

-- Get catch bonus
function FishingRodConfig.GetCatchBonus(rodId)
	local rod = FishingRodConfig.Rods[rodId]
	return rod and rod.CatchBonus or 0
end

-- Check if rod exists
function FishingRodConfig.Exists(rodId)
	return FishingRodConfig.Rods[rodId] ~= nil
end

-- Get rarity color
function FishingRodConfig.GetRarityColor(rodId)
	local rod = FishingRodConfig.Rods[rodId]
	if rod then
		return FishingRodConfig.RarityColors[rod.Rarity] or FishingRodConfig.RarityColors.Common
	end
	return FishingRodConfig.RarityColors.Common
end

return FishingRodConfig
