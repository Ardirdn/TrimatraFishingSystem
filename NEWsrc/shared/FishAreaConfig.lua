--[[
    FISH AREA CONFIG
    Place in ReplicatedStorage/Modules/FishAreaConfig.lua
    
    Konfigurasi untuk Fish Area System.
    
    STRUKTUR DI WORKSPACE (sesuai setup Anda):
    workspace/
    └── Location/                    <- Model
        ├── Area1/                   <- Folder (= DeepSea, River)
        │   ├── Part
        │   ├── Part
        │   └── Part
        ├── Area2/                   <- Folder (= Lake, CoralReef)
        │   ├── Part
        │   ├── Part
        │   └── Part
        ├── Area3/                   <- Folder (= Swamp)
        │   ├── Part
        │   ├── Part
        │   └── Part
        └── Area4/                   <- Folder (= Cave, Arctic, Antarctic)
            ├── Part
            ├── Part
            ├── Part
            └── Part
    
    MAPPING:
    - Area1 = DeepSea + River (ikan laut dalam dan sungai)
    - Area2 = Lake + CoralReef (ikan danau dan terumbu karang)
    - Area3 = Swamp (ikan rawa)
    - Area4 = Cave + Arctic + Antarctic (ikan gua dan kutub)
    
    Jika floater di LUAR semua area = "Anywhere" (hanya dapat ikan Anywhere)
]]

local FishAreaConfig = {}

-- ==================== AREA TO LOCATION MAPPING ====================
-- Maps workspace folder names to FishConfig locations
-- One area can contain multiple locations!
FishAreaConfig.AreaToLocations = {
	["Area1"] = {"DeepSea", "River"},
	["Area2"] = {"Lake", "CoralReef"},
	["Area3"] = {"Swamp"},
	["Area4"] = {"Cave", "Arctic", "Antarctic"},
}

-- Reverse mapping: Location -> Area (for quick lookup)
FishAreaConfig.LocationToArea = {}
for areaName, locations in pairs(FishAreaConfig.AreaToLocations) do
	for _, location in ipairs(locations) do
		FishAreaConfig.LocationToArea[location] = areaName
	end
end

-- ==================== RARITY MULTIPLIERS ====================
FishAreaConfig.DefaultRarityMultipliers = {
	Common = 1,
	Uncommon = 1,
	Rare = 1,
	Epic = 1,
	Legendary = 1,
	Mythic = 1,
	Secret = 1
}

-- ==================== AREA CONFIGURATIONS ====================
FishAreaConfig.Areas = {
	-- ==================== AREA 1 (DeepSea + River) ====================
	["Area1"] = {
		DisplayName = "Deep Waters",
		Description = "Deep sea and river waters with rare fish!",
		Color = Color3.fromRGB(30, 80, 150),
		
		-- Locations included in this area
		Locations = {"DeepSea", "River"},
		
		RarityMultipliers = {
			Common = 0.7,
			Uncommon = 0.9,
			Rare = 1.5,
			Epic = 2.0,
			Legendary = 2.5,
			Mythic = 3.0,
			Secret = 2.0
		},
		
		-- Bonus for fish that belong to this area's locations
		FishChanceBonus = {
			-- DeepSea fish
			["Light_Fish"] = 10,
			["Eclipse Tail"] = 15,
			["Abyss Shadow"] = 20,
			["Void Piranha"] = 20,
			["Pewter Swimmer"] = 25,
			["Grimus Scaler"] = 30,
			["DunkyB"] = 35,
			["Shadow Tentacle"] = 35,
			-- River fish
			["Channa striata"] = 10,
			["Catfish"] = 15,
			["Bluearwana"] = 25,
			["RedArwana"] = 25,
		},
		
		ExclusiveFish = {}
	},
	
	-- ==================== AREA 2 (Lake + CoralReef) ====================
	["Area2"] = {
		DisplayName = "Tropical Waters",
		Description = "Lake and coral reef with beautiful fish!",
		Color = Color3.fromRGB(100, 200, 220),
		
		Locations = {"Lake", "CoralReef"},
		
		RarityMultipliers = {
			Common = 1.0,
			Uncommon = 1.3,
			Rare = 1.3,
			Epic = 2.0,
			Legendary = 1.5,
			Mythic = 1.5,
			Secret = 1.5
		},
		
		FishChanceBonus = {
			-- Lake fish
			["White_Spotted"] = 15,
			["Thunder Mist"] = 20,
			["Purple_axollote"] = 30,
			["Red_axollote"] = 30,
			-- CoralReef fish
			["Spinefoot"] = 15,
			["Star_Fish"] = 15,
			["Glass Fin"] = 35,
		},
		
		ExclusiveFish = {}
	},
	
	-- ==================== AREA 3 (Swamp) ====================
	["Area3"] = {
		DisplayName = "Swamp",
		Description = "Murky swamp waters with dangerous creatures!",
		Color = Color3.fromRGB(80, 120, 60),
		
		Locations = {"Swamp"},
		
		RarityMultipliers = {
			Common = 0.8,
			Uncommon = 1.0,
			Rare = 1.3,
			Epic = 2.5,
			Legendary = 3.0,
			Mythic = 4.0,
			Secret = 2.0
		},
		
		FishChanceBonus = {
			["Eal"] = 15,
			["Liquid Phantom"] = 20,
			["Parasite Fin"] = 20,
			["Crocodile"] = 35,
			["King_Frog"] = 40,
			["BabyCrocodile"] = 50,
		},
		
		ExclusiveFish = {}
	},
	
	-- ==================== AREA 4 (Cave + Arctic + Antarctic) ====================
	["Area4"] = {
		DisplayName = "Extreme Waters",
		Description = "Cave and polar waters with the rarest fish!",
		Color = Color3.fromRGB(60, 40, 100),
		
		Locations = {"Cave", "Arctic", "Antarctic"},
		
		RarityMultipliers = {
			Common = 0.5,
			Uncommon = 0.7,
			Rare = 1.8,
			Epic = 2.5,
			Legendary = 3.5,
			Mythic = 4.0,
			Secret = 5.0
		},
		
		FishChanceBonus = {
			-- Cave fish
			["Artifact Fin"] = 25,
			["Vampire_Fish"] = 30,
			["Sarcophagus"] = 40,
			["Zircon Heart"] = 60,
			-- Arctic fish
			["Fossil Ice Fish"] = 40,
			["North Star Drifter"] = 60,
			-- Antarctic fish
			["South Star Drifter"] = 70,
		},
		
		ExclusiveFish = {}
	},
}

-- ==================== HELPER FUNCTIONS ====================

function FishAreaConfig.GetAreaConfig(areaName)
	return FishAreaConfig.Areas[areaName]
end

function FishAreaConfig.GetAllAreaNames()
	local names = {}
	for name, _ in pairs(FishAreaConfig.Areas) do
		table.insert(names, name)
	end
	return names
end

-- Get all locations available in an area
function FishAreaConfig.GetLocationsInArea(areaName)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.Locations then
		return areaConfig.Locations
	end
	return {}
end

-- Check if a location is in a specific area
function FishAreaConfig.IsLocationInArea(location, areaName)
	local locations = FishAreaConfig.GetLocationsInArea(areaName)
	for _, loc in ipairs(locations) do
		if loc == location then
			return true
		end
	end
	return false
end

function FishAreaConfig.IsFishExclusive(fishId)
	for areaName, areaConfig in pairs(FishAreaConfig.Areas) do
		if areaConfig.ExclusiveFish then
			for _, exclusiveFishId in ipairs(areaConfig.ExclusiveFish) do
				if exclusiveFishId == fishId then
					return true, areaName
				end
			end
		end
	end
	return false, nil
end

function FishAreaConfig.GetRarityMultiplier(areaName, rarity)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.RarityMultipliers then
		return areaConfig.RarityMultipliers[rarity] or 1
	end
	return 1
end

function FishAreaConfig.GetFishChanceBonus(areaName, fishId)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.FishChanceBonus then
		return areaConfig.FishChanceBonus[fishId] or 0
	end
	return 0
end

return FishAreaConfig
