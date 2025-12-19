--[[
    FISH CONFIG
    Place in ReplicatedStorage/Modules/FishConfig.lua
    
    SINGLE SOURCE OF TRUTH untuk semua data ikan.
    Setiap ikan memiliki:
    - Name: Nama display ikan
    - Rarity: Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret
    - Price: Harga jual (auto-calculated berdasarkan rarity jika 0)
    - Weight: Berat minimum dalam kg
    - MaxWeight: Berat maksimum dalam kg
    - ImageID: Asset ID untuk gambar ikan
    - Location: Area di mana ikan ini bisa muncul
    - Description: Deskripsi singkat ikan
    
    LOCATION SYSTEM RULES:
    =====================
    1. "Anywhere"    : Bisa didapat di SEMUA area (Common & Uncommon fish)
    2. "Area1" - "Area5" : Ikan spesifik lokasi, HANYA bisa didapat di area tersebut
    
    FISHING RULES:
    - Mancing di area manapun: PASTI dapat Common/Uncommon (Anywhere)
    - Mancing di Area1-5: Chance lebih tinggi dapat ikan spesifik area tersebut
    - LocationBonus mengatur seberapa besar boost untuk ikan lokasi spesifik
    
    RARITY & LOCATION:
    - Common & Uncommon  : "Anywhere" (bisa didapat di semua area)
    - Rare, Epic, Legendary, Mythic, Secret : Lokasi spesifik (Area1-Area5)
    
    LOCATION OPTIONS: Anywhere, Area1, Area2, Area3, Area4, Area5
]]

local FishConfig = {}

-- Rarity weight untuk random selection
FishConfig.RarityWeights = {
	Common = 50, -- 50%
	Uncommon = 30, -- 30%
	Rare = 12, -- 12%
	Epic = 5, -- 5%
	Legendary = 2, -- 2%
	Mythic = 0.3, -- 0.75%
	Secret = 0.05, -- 0.25% (1 in 400)
}

-- Rarity colors
FishConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 50, 50), -- Red/Crimson
	Secret = Color3.fromRGB(40, 0, 80), -- Deep Dark Violet
}

-- Base price per rarity (auto-calculated for each fish)
FishConfig.RarityBasePrices = {
	Common = 55,        -- Range: 10-100, mid: 55
	Uncommon = 600,     -- Range: 200-1K, mid: 600
	Rare = 2500,        -- Range: 1.5k-3.5k, mid: 2500
	Epic = 7500,        -- Range: 5k-10k, mid: 7500
	Legendary = 32500,  -- Range: 25k-40k, mid: 32500
	Mythic = 65000,     -- Range: 50k-80k, mid: 65000
	Secret = 350000,    -- Range: 200k-500k, mid: 350000
}

-- Location bonus multipliers (higher = more chance for location-specific fish)
-- Jika mancing di area ini, chance Rare+ fish di-boost dengan multiplier ini
FishConfig.LocationBonus = {
	Anywhere = 1.0,  -- Default, tidak ada bonus
	Area1 = 1.5,     -- 1.5x chance untuk ikan Rare+ jika mancing di Area1
	Area2 = 1.5,     -- 1.5x chance untuk ikan Rare+ jika mancing di Area2
	Area3 = 1.5,     -- 1.5x chance untuk ikan Rare+ jika mancing di Area3
	Area4 = 1.5,     -- 1.5x chance untuk ikan Rare+ jika mancing di Area4
	Area5 = 1.5,     -- 1.5x chance untuk ikan Rare+ jika mancing di Area5
}

-- Configurable: Base chance untuk dapat ikan lokasi spesifik (Rare+)
-- Ini adalah chance TAMBAHAN di atas rarity weight normal
FishConfig.LocationRareBoost = 0.15 -- 15% boost untuk Rare+ di lokasi spesifik

FishConfig.Fish = {
	-- ==================== COMMON ====================
	["Channa striata"] = {
		Name = "Channa striata",
		Rarity = "Common",
		Price = 35,
		Weight = 0.5,
		MaxWeight = 2.3,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Ikan gabus umum yang sering ditemukan di sungai dan sawah.",
	},
	["Eal"] = {
		Name = "Eal",
		Rarity = "Common",
		Price = 15,
		Weight = 0.01,
		MaxWeight = 0.05,
		ImageID = "rbxassetid://136059630261427",
		Location = "Anywhere",
		Description = "Belut kecil yang licin dan sulit ditangkap.",
	},
	["Light_Fish"] = {
		Name = "Light Fish",
		Rarity = "Common",
		Price = 85,
		Weight = 2.5,
		MaxWeight = 45.0,
		ImageID = "rbxassetid://100449732936500",
		Location = "Anywhere",
		Description = "Ikan yang bercahaya dalam kegelapan laut dalam.",
	},
	["Shrimp"] = {
		Name = "Shrimp",
		Rarity = "Common",
		Price = 25,
		Weight = 0.3,
		MaxWeight = 1.0,
		ImageID = "rbxassetid://137322691878285",
		Location = "Anywhere",
		Description = "Udang biasa yang enak dimakan dan mudah didapat.",
	},
	["Spinefoot"] = {
		Name = "Spinefoot",
		Rarity = "Common",
		Price = 45,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://130873879694773",
		Location = "Anywhere",
		Description = "Ikan baronang yang berduri tajam di siripnya.",
	},
	["Squid"] = {
		Name = "Squid",
		Rarity = "Common",
		Price = 55,
		Weight = 0.1,
		MaxWeight = 0.4,
		ImageID = "rbxassetid://104923022964960",
		Location = "Anywhere",
		Description = "Cumi-cumi kecil yang lincah berenang.",
	},
	["Star_Fish"] = {
		Name = "Star Fish",
		Rarity = "Common",
		Price = 70,
		Weight = 0.2,
		MaxWeight = 0.6,
		ImageID = "rbxassetid://131976466299383",
		Location = "Anywhere",
		Description = "Bintang laut cantik yang lambat bergerak.",
	},
	["Threadfin_Bream"] = {
		Name = "Threadfin Bream",
		Rarity = "Common",
		Price = 95,
		Weight = 0.5,
		MaxWeight = 2.0,
		ImageID = "rbxassetid://74313124177174",
		Location = "Anywhere",
		Description = "Ikan kurisi yang sering ditemukan di pasar.",
	},
	["White_Spotted"] = {
		Name = "White Spotted",
		Rarity = "Common",
		Price = 60,
		Weight = 0.3,
		MaxWeight = 1.2,
		ImageID = "rbxassetid://89926743782429",
		Location = "Anywhere",
		Description = "Ikan berbintik putih yang indah dipandang.",
	},

	-- ==================== UNCOMMON ====================
	["Artifact Fin"] = {
		Name = "Artifact Fin",
		Rarity = "Uncommon",
		Price = 350,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://117504179782086",
		Location = "Anywhere",
		Description = "Ikan misterius dengan sirip seperti artefak kuno.",
	},
	["Catfish"] = {
		Name = "Catfish",
		Rarity = "Uncommon",
		Price = 275,
		Weight = 0.2,
		MaxWeight = 0.5,
		ImageID = "rbxassetid://77103108486040",
		Location = "Anywhere",
		Description = "Ikan lele berkumis yang suka bersembunyi di lumpur.",
	},
	["Eclipse Tail"] = {
		Name = "Eclipse Tail",
		Rarity = "Uncommon",
		Price = 520,
		Weight = 0.3,
		MaxWeight = 1.0,
		ImageID = "rbxassetid://125754403618735",
		Location = "Anywhere",
		Description = "Ikan dengan ekor yang bercahaya seperti gerhana.",
	},
	["Liquid Phantom"] = {
		Name = "Liquid Phantom",
		Rarity = "Uncommon",
		Price = 750,
		Weight = 0.5,
		MaxWeight = 1.5,
		ImageID = "rbxassetid://131073642346075",
		Location = "Anywhere",
		Description = "Ikan transparan yang hampir tak terlihat di air.",
	},
	["Parasite Fin"] = {
		Name = "Parasite Fin",
		Rarity = "Uncommon",
		Price = 420,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://103424028658402",
		Location = "Anywhere",
		Description = "Ikan parasit yang menempel pada ikan lain.",
	},
	["Thunder Mist"] = {
		Name = "Thunder Mist",
		Rarity = "Uncommon",
		Price = 900,
		Weight = 0.3,
		MaxWeight = 1.0,
		ImageID = "rbxassetid://130949409164658",
		Location = "Anywhere",
		Description = "Ikan listrik yang bisa menyetrum mangsanya.",
	},

	-- ==================== RARE ====================
	["Abyss Shadow"] = {
		Name = "Abyss Shadow",
		Rarity = "Rare",
		Price = 1800,
		Weight = 0.5,
		MaxWeight = 4.0,
		ImageID = "rbxassetid://73079536548775",
		Location = "Area1",
		Description = "Makhluk misterius dari kedalaman laut yang gelap.",
	},
	["Bluearwana"] = {
		Name = "Bluearwana",
		Rarity = "Rare",
		Price = 2200,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://71796810763920",
		Location = "Area2",
		Description = "Arwana biru langka dengan sisik berkilau.",
	},
	["RedArwana"] = {
		Name = "Red Arwana",
		Rarity = "Rare",
		Price = 3200,
		Weight = 700.0,
		MaxWeight = 1600.0,
		ImageID = "rbxassetid://81020034230061",
		Location = "Area3",
		Description = "Arwana merah legendaris, simbol keberuntungan.",
	},
	["Vampire_Fish"] = {
		Name = "Vampire Fish",
		Rarity = "Rare",
		Price = 2800,
		Weight = 60.0,
		MaxWeight = 600.0,
		ImageID = "rbxassetid://79137640518215",
		Location = "Area4",
		Description = "Ikan predator dengan taring tajam seperti vampir.",
	},
	["Void Piranha"] = {
		Name = "Void Piranha",
		Rarity = "Rare",
		Price = 1650,
		Weight = 0.2,
		MaxWeight = 0.5,
		ImageID = "rbxassetid://102120642126088",
		Location = "Area4",
		Description = "Piranha dari dimensi kekosongan yang mengerikan.",
	},

	-- ==================== EPIC ====================
	["Crocodile"] = {
		Name = "Crocodile",
		Rarity = "Epic",
		Price = 7500,
		Weight = 4000.0,
		MaxWeight = 6000.0,
		ImageID = "rbxassetid://97425888747369",
		Location = "Area1",
		Description = "Buaya besar dan berbahaya dari rawa-rawa.",
	},
	["Fossil Ice Fish"] = {
		Name = "Fossil Ice Fish",
		Rarity = "Epic",
		Price = 9200,
		Weight = 9000.0,
		MaxWeight = 24000.0,
		ImageID = "rbxassetid://129697171862429",
		Location = "Area2",
		Description = "Ikan purba yang membeku dalam es ribuan tahun.",
	},
	["Glass Fin"] = {
		Name = "Glass Fin",
		Rarity = "Epic",
		Price = 8500,
		Weight = 50000.0,
		MaxWeight = 150000.0,
		ImageID = "rbxassetid://135761068873306",
		Location = "Area3",
		Description = "Ikan kristal transparan yang sangat rapuh dan indah.",
	},
	["Pewter Swimmer"] = {
		Name = "Pewter Swimmer",
		Rarity = "Epic",
		Price = 6800,
		Weight = 14000.0,
		MaxWeight = 22000.0,
		ImageID = "rbxassetid://110723866030773",
		Location = "Area3",
		Description = "Ikan logam yang berkilau seperti timah.",
	},
	["Purple_axollote"] = {
		Name = "Purple Axolotl",
		Rarity = "Epic",
		Price = 5500,
		Weight = 20000.0,
		MaxWeight = 32000.0,
		ImageID = "rbxassetid://90122872095438",
		Location = "Area4",
		Description = "Axolotl ungu langka dengan kemampuan regenerasi.",
	},
	["Red_axollote"] = {
		Name = "Red Axolotl",
		Rarity = "Epic",
		Price = 6200,
		Weight = 15000.0,
		MaxWeight = 30000.0,
		ImageID = "rbxassetid://71448049179997",
		Location = "Area4",
		Description = "Axolotl merah yang sangat dicari kolektor.",
	},

	-- ==================== LEGENDARY ====================
	["Aether"] = {
		Name = "Aether",
		Rarity = "Legendary",
		Price = 35000,
		Weight = 19000.0,
		MaxWeight = 42000.0,
		ImageID = "rbxassetid://79988125959649",
		Location = "Area1",
		Description = "Ikan surgawi yang melayang di antara dimensi.",
	},
	["Grimus Scaler"] = {
		Name = "Grimus Scaler",
		Rarity = "Legendary",
		Price = 28000,
		Weight = 9000.0,
		MaxWeight = 24000.0,
		ImageID = "rbxassetid://73922887981721",
		Location = "Area2",
		Description = "Ikan bersisik gelap dengan aura mengerikan.",
	},
	["King_Frog"] = {
		Name = "King Frog",
		Rarity = "Legendary",
		Price = 38000,
		Weight = 3000.0,
		MaxWeight = 9000.0,
		ImageID = "rbxassetid://108640447495421",
		Location = "Area3",
		Description = "Raja dari semua katak, bermahkota emas.",
	},
	["Sarcophagus"] = {
		Name = "Sarcophagus",
		Rarity = "Legendary",
		Price = 32000,
		Weight = 2000,
		MaxWeight = 16000,
		ImageID = "rbxassetid://129423197983298",
		Location = "Area4",
		Description = "Ikan kuno yang menyerupai peti mati firaun.",
	},

	-- ==================== MYTHIC ====================
	["BabyCrocodile"] = {
		Name = "Baby Crocodile",
		Rarity = "Mythic",
		Price = 55000,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://99586723424218",
		Location = "Area1",
		Description = "Bayi buaya ajaib dengan kekuatan magis.",
	},
	["Dawnlight Sprinter"] = {
		Name = "Dawnlight Sprinter",
		Rarity = "Mythic",
		Price = 72000,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://117855555060647",
		Location = "Area2",
		Description = "Ikan secepat cahaya fajar yang hampir mustahil ditangkap.",
	},
	["DunkyB"] = {
		Name = "DunkyB",
		Rarity = "Mythic",
		Price = 65000,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://121399408698056",
		Location = "Area3",
		Description = "Ikan raksasa misterius dari zaman prasejarah.",
	},
	["Shadow Tentacle"] = {
		Name = "Shadow Tentacle",
		Rarity = "Mythic",
		Price = 78000,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://121586992053026",
		Location = "Area4",
		Description = "Makhluk dengan tentakel bayangan dari kegelapan.",
	},

	-- ==================== SECRET ====================
	["CosmicAlan"] = {
		Name = "Cosmic Alan",
		Rarity = "Secret",
		Price = 350000,
		Weight = 49000,
		MaxWeight = 62000,
		ImageID = "rbxassetid://130360710729845",
		Location = "Area1",
		Description = "Ikan kosmik dari galaksi lain. Sangat langka!",
	},
	["North Star Drifter"] = {
		Name = "North Star Drifter",
		Rarity = "Secret",
		Price = 420000,
		Weight = 49000,
		MaxWeight = 62000,
		ImageID = "rbxassetid://113346181133710",
		Location = "Area2",
		Description = "Ikan yang muncul hanya saat bintang utara bersinar.",
	},
	["Zircon Heart"] = {
		Name = "Zircon Heart",
		Rarity = "Secret",
		Price = 275000,
		Weight = 49000,
		MaxWeight = 62000,
		ImageID = "rbxassetid://76367948911086",
		Location = "Area3",
		Description = "Ikan dengan jantung kristal zirkon yang berkilau.",
	},
	["South Star Drifter"] = {
		Name = "South Star Drifter",
		Rarity = "Secret",
		Price = 485000,
		Weight = 59000,
		MaxWeight = 72000,
		ImageID = "rbxassetid://96835703512691",
		Location = "Area4",
		Description = "Ikan dari Kutub Selatan yang sangat misterius.",
	},
}

-- Auto-calculate prices untuk semua ikan berdasarkan rarity
function FishConfig.AutoCalculatePrices()
	local count = 0
	for fishId, fishData in pairs(FishConfig.Fish) do
		count = count + 1
		-- Fix typo: Dugong seharusnya Legendary bukan "Dugong"
		if fishData.Rarity == "Dugong" then
			fishData.Rarity = "Legendary"
		end

		-- Set price based on rarity if currently 0
		if fishData.Price == 0 then
			local basePrice = FishConfig.RarityBasePrices[fishData.Rarity]
			if basePrice then
				-- Add slight variation (±20%) untuk variety
				local variation = math.random(80, 120) / 100
				fishData.Price = math.floor(basePrice * variation)
			else
				warn("⚠️ Unknown rarity for fish:", fishId, "-", fishData.Rarity)
				fishData.Price = 50 -- Default fallback
			end
		end
	end
	print("✅ [FISH CONFIG] Auto-calculated prices for", count, "fish types")
end

-- Function untuk get random fish berdasarkan rarity weight
function FishConfig.GetRandomFish()
	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(FishConfig.RarityWeights) do
		totalWeight = totalWeight + weight
	end

	-- Random selection
	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedRarity = "Common"

	for rarity, weight in pairs(FishConfig.RarityWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end

	-- Get all fish of selected rarity
	local fishPool = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then
			table.insert(fishPool, fishId)
		end
	end

	-- Return random fish from pool
	if #fishPool > 0 then
		local randomFish = fishPool[math.random(1, #fishPool)]
		return randomFish, FishConfig.Fish[randomFish]
	end

	-- Fallback ke ikan pertama
	local firstFish = next(FishConfig.Fish)
	return firstFish, FishConfig.Fish[firstFish]
end

-- Function untuk get random fish berdasarkan location
-- FISHING RULES:
-- 1. Mancing di "Anywhere": HANYA dapat Common/Uncommon (Anywhere fish)
-- 2. Mancing di Area1-5: 
--    - Common/Uncommon tetap dari Anywhere
--    - Rare+ chances di-BOOST berdasarkan LocationBonus
--    - Rare+ fish berasal dari area spesifik tersebut
function FishConfig.GetRandomFishByLocation(location)
	location = location or "Anywhere"
	
	-- Step 1: Calculate rarity weights dengan boost jika di area spesifik
	local adjustedWeights = {}
	local locationBonus = FishConfig.LocationBonus[location] or 1.0
	local rareBoost = FishConfig.LocationRareBoost or 0.15
	
	for rarity, weight in pairs(FishConfig.RarityWeights) do
		if location ~= "Anywhere" and (rarity == "Rare" or rarity == "Epic" or rarity == "Legendary" or rarity == "Mythic" or rarity == "Secret") then
			-- Boost Rare+ chances di area spesifik
			-- Formula: baseWeight * (1 + rareBoost * locationBonus)
			adjustedWeights[rarity] = weight * (1 + rareBoost * locationBonus)
		else
			adjustedWeights[rarity] = weight
		end
	end
	
	-- Step 2: Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(adjustedWeights) do
		totalWeight = totalWeight + weight
	end

	-- Step 3: Random selection for rarity
	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedRarity = "Common"

	for rarity, weight in pairs(adjustedWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end
	
	-- Step 4: Build fish pool berdasarkan location dan rarity
	local fishPool = {}
	
	-- Common & Uncommon selalu dari Anywhere
	if selectedRarity == "Common" or selectedRarity == "Uncommon" then
		for fishId, fishData in pairs(FishConfig.Fish) do
			if fishData.Rarity == selectedRarity and fishData.Location == "Anywhere" then
				table.insert(fishPool, fishId)
			end
		end
	else
		-- Rare+ fish
		if location == "Anywhere" then
			-- Di Anywhere, tidak ada ikan Rare+ (karena semua Rare+ punya lokasi spesifik)
			-- Fallback ke Common/Uncommon
			for fishId, fishData in pairs(FishConfig.Fish) do
				if fishData.Location == "Anywhere" then
					table.insert(fishPool, fishId)
				end
			end
		else
			-- Di Area spesifik, ambil ikan Rare+ dari area tersebut
			for fishId, fishData in pairs(FishConfig.Fish) do
				if fishData.Rarity == selectedRarity and fishData.Location == location then
					table.insert(fishPool, fishId)
				end
			end
			
			-- Jika tidak ada ikan dengan rarity tersebut di area ini, fallback ke Anywhere
			if #fishPool == 0 then
				for fishId, fishData in pairs(FishConfig.Fish) do
					if fishData.Location == "Anywhere" then
						table.insert(fishPool, fishId)
					end
				end
			end
		end
	end

	-- Step 5: Return random fish dari pool
	if #fishPool > 0 then
		local randomFish = fishPool[math.random(1, #fishPool)]
		return randomFish, FishConfig.Fish[randomFish]
	end

	-- Ultimate fallback
	local fallbackPool = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Location == "Anywhere" then
			table.insert(fallbackPool, fishId)
		end
	end
	
	if #fallbackPool > 0 then
		local randomFish = fallbackPool[math.random(1, #fallbackPool)]
		return randomFish, FishConfig.Fish[randomFish]
	end
	
	return FishConfig.GetRandomFish()
end

-- Get fish by ID
function FishConfig.GetFishById(fishId)
	return FishConfig.Fish[fishId]
end

-- Get all fish of a specific rarity
function FishConfig.GetFishByRarity(rarity)
	local result = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == rarity then
			result[fishId] = fishData
		end
	end
	return result
end

-- Get all fish in a specific location
function FishConfig.GetFishByLocation(location)
	local result = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Location == location then
			result[fishId] = fishData
		end
	end
	return result
end

-- Get rarity color
function FishConfig.GetRarityColor(rarity)
	return FishConfig.RarityColors[rarity] or FishConfig.RarityColors.Common
end

-- Get available fishing locations
function FishConfig.GetAvailableLocations()
	return {"Anywhere", "Area1", "Area2", "Area3", "Area4", "Area5"}
end

-- Set location bonus (untuk kustomisasi server)
-- @param location: string - nama lokasi (Area1-Area5)
-- @param bonus: number - multiplier (1.0 = normal, 2.0 = 2x chance, dll)
function FishConfig.SetLocationBonus(location, bonus)
	if FishConfig.LocationBonus[location] then
		FishConfig.LocationBonus[location] = bonus
		print("✅ [FISH CONFIG] Set LocationBonus for", location, "to", bonus)
	else
		warn("⚠️ [FISH CONFIG] Unknown location:", location)
	end
end

-- Get location bonus
function FishConfig.GetLocationBonus(location)
	return FishConfig.LocationBonus[location] or 1.0
end

-- Set location rare boost (0.0 - 1.0)
-- @param boost: number - 0.15 = 15% boost untuk Rare+ di lokasi spesifik
function FishConfig.SetLocationRareBoost(boost)
	FishConfig.LocationRareBoost = math.clamp(boost, 0, 1)
	print("✅ [FISH CONFIG] Set LocationRareBoost to", FishConfig.LocationRareBoost)
end

-- Get location rare boost
function FishConfig.GetLocationRareBoost()
	return FishConfig.LocationRareBoost or 0.15
end

-- Get all fish available in a location (includes Anywhere fish)
function FishConfig.GetAllFishAvailableAt(location)
	local result = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Location == location or fishData.Location == "Anywhere" then
			result[fishId] = fishData
		end
	end
	return result
end

-- Get fish count summary per location
function FishConfig.GetFishCountByLocation()
	local counts = {}
	for _, loc in ipairs(FishConfig.GetAvailableLocations()) do
		counts[loc] = 0
	end
	
	for _, fishData in pairs(FishConfig.Fish) do
		local loc = fishData.Location
		if counts[loc] then
			counts[loc] = counts[loc] + 1
		end
	end
	
	return counts
end

-- Print configuration summary
function FishConfig.PrintSummary()
	print("========== FISH CONFIG SUMMARY ==========")
	print("Location Rare Boost:", FishConfig.LocationRareBoost)
	print("")
	print("Location Bonuses:")
	for loc, bonus in pairs(FishConfig.LocationBonus) do
		print("  -", loc, ":", bonus .. "x")
	end
	print("")
	print("Fish Count by Location:")
	for loc, count in pairs(FishConfig.GetFishCountByLocation()) do
		print("  -", loc, ":", count, "fish")
	end
	print("")
	print("Rarity Weights (base):")
	local total = 0
	for _, w in pairs(FishConfig.RarityWeights) do total = total + w end
	for rarity, weight in pairs(FishConfig.RarityWeights) do
		local percent = string.format("%.2f%%", (weight / total) * 100)
		print("  -", rarity, ":", percent)
	end
	print("==========================================")
end

-- Auto-calculate prices saat module di-load
FishConfig.AutoCalculatePrices()

return FishConfig
