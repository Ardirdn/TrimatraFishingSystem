--[[
    FISHING ROD CONFIG
    Place in ReplicatedStorage/Modules/FishingRod.config.lua
    
    Configuration for each fishing rod's stats and LINE STYLE
    LineStyle: Color, Neon, Width settings for fishing line customization
]]

local FishingRodConfig = {}

-- Default Line Style (used if not specified per rod)
FishingRodConfig.DefaultLineStyle = {
	Color = Color3.fromRGB(0, 255, 255),
	Width = 0.16,
	Transparency = 0.12,
	LightEmission = 10,
	IsNeon = true
}

FishingRodConfig.Rods = {
	-- ==================== STARTER RODS ====================
	["FishingRod_Wood1"] = {
		ToolName = "FishingRod_Wood1",
		ToolObject = "FishingRod_Wood1",
		FloaterObject = "Floater_Doll",
		MaxThrowDistance = 35,
		ThrowHeight = 9,
		BobSpeed = 2.5,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(139, 90, 43), -- Brown (wooden)
			Width = 0.12,
			Transparency = 0.2,
			LightEmission = 0,
			IsNeon = false
		}
	},
	["FishingRod_Bamboo"] = {
		ToolName = "FishingRod_Bamboo",
		ToolObject = "FishingRod_Bamboo",
		FloaterObject = "Floater_Doll",
		MaxThrowDistance = 40,
		ThrowHeight = 10,
		BobSpeed = 2.2,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(107, 142, 35), -- Olive green (bamboo)
			Width = 0.12,
			Transparency = 0.2,
			LightEmission = 0,
			IsNeon = false
		}
	},

	-- ==================== BASIC RODS ====================
	["FishingRod_Copper"] = {
		ToolName = "FishingRod_Copper",
		ToolObject = "FishingRod_Copper",
		FloaterObject = "Floater_Cooper",
		MaxThrowDistance = 55,
		ThrowHeight = 16,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(184, 115, 51), -- Copper orange
			Width = 0.14,
			Transparency = 0.15,
			LightEmission = 2,
			IsNeon = false
		}
	},
	["FishingRod_Anchor"] = {
		ToolName = "FishingRod_Anchor",
		ToolObject = "FishingRod_Anchor",
		FloaterObject = "Floater_Cooper",
		MaxThrowDistance = 45,
		ThrowHeight = 12,
		BobSpeed = 2.5,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(70, 70, 80), -- Dark steel
			Width = 0.18,
			Transparency = 0.1,
			LightEmission = 0,
			IsNeon = false
		}
	},
	["FishingRod_Tribe"] = {
		ToolName = "FishingRod_Tribe",
		ToolObject = "FishingRod_Tribe",
		FloaterObject = "Floater_skeleton",
		MaxThrowDistance = 46,
		ThrowHeight = 12,
		BobSpeed = 2.2,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(139, 69, 19), -- Saddle brown
			Width = 0.16,
			Transparency = 0.15,
			LightEmission = 1,
			IsNeon = false
		}
	},

	-- ==================== THEMED RODS ====================
	["FishingRod_Banana"] = {
		ToolName = "FishingRod_Banana",
		ToolObject = "FishingRod_Banana",
		FloaterObject = "Floater_Candy",
		MaxThrowDistance = 48,
		ThrowHeight = 13,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 225, 53), -- Bright yellow
			Width = 0.14,
			Transparency = 0.12,
			LightEmission = 3,
			IsNeon = true
		}
	},
	["FishingRod_Bacon"] = {
		ToolName = "FishingRod_Bacon",
		ToolObject = "FishingRod_Bacon",
		FloaterObject = "Floater_Candy",
		MaxThrowDistance = 50,
		ThrowHeight = 14,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(200, 80, 60), -- Bacon red-brown
			Width = 0.14,
			Transparency = 0.15,
			LightEmission = 2,
			IsNeon = false
		}
	},
	["FishingRod_Love"] = {
		ToolName = "FishingRod_Love",
		ToolObject = "FishingRod_Love",
		FloaterObject = "Floater_Candy",
		MaxThrowDistance = 54,
		ThrowHeight = 15,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(255, 105, 180), -- Hot pink
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 8,
			IsNeon = true
		}
	},
	["FishingRod_Bat"] = {
		ToolName = "FishingRod_Bat",
		ToolObject = "FishingRod_Bat",
		FloaterObject = "Floater_skeleton",
		MaxThrowDistance = 52,
		ThrowHeight = 15,
		BobSpeed = 2.3,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(75, 0, 130), -- Dark purple
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 5,
			IsNeon = true
		}
	},
	["FishingRod_Crab"] = {
		ToolName = "FishingRod_Crab",
		ToolObject = "FishingRod_Crab",
		FloaterObject = "Floater_Fish_Bone",
		MaxThrowDistance = 50,
		ThrowHeight = 14,
		BobSpeed = 2.1,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 99, 71), -- Tomato red (crab)
			Width = 0.15,
			Transparency = 0.12,
			LightEmission = 3,
			IsNeon = false
		}
	},

	-- ==================== ADVANCED RODS ====================
	["FishingRod_Seal"] = {
		ToolName = "FishingRod_Seal",
		ToolObject = "FishingRod_Seal",
		FloaterObject = "Floater_Pinguin",
		MaxThrowDistance = 52,
		ThrowHeight = 14,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(176, 224, 230), -- Powder blue (arctic)
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 5,
			IsNeon = true
		}
	},
	["FishingRod_Mercusuar"] = {
		ToolName = "FishingRod_Mercusuar",
		ToolObject = "FishingRod_Mercusuar",
		FloaterObject = "Floater_Pinguin",
		MaxThrowDistance = 56,
		ThrowHeight = 16,
		BobSpeed = 2.1,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 255, 0), -- Bright yellow (lighthouse)
			Width = 0.18,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Knight"] = {
		ToolName = "FishingRod_Knight",
		ToolObject = "FishingRod_Knight",
		FloaterObject = "Floater_Cooper",
		MaxThrowDistance = 58,
		ThrowHeight = 16,
		BobSpeed = 2.2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(192, 192, 192), -- Silver (armor)
			Width = 0.18,
			Transparency = 0.1,
			LightEmission = 3,
			IsNeon = false
		}
	},
	["FishingRod_Dryad"] = {
		ToolName = "FishingRod_Dryad",
		ToolObject = "FishingRod_Dryad",
		FloaterObject = "Floater_Doll",
		MaxThrowDistance = 60,
		ThrowHeight = 17,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(34, 139, 34), -- Forest green
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 6,
			IsNeon = true
		}
	},
	["FishingRod_Dryad2"] = {
		ToolName = "FishingRod_Dryad2",
		ToolObject = "FishingRod_Dryad2",
		FloaterObject = "Floater_Doll",
		MaxThrowDistance = 62,
		ThrowHeight = 17,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(0, 255, 127), -- Spring green
			Width = 0.16,
			Transparency = 0.08,
			LightEmission = 8,
			IsNeon = true
		}
	},
	["FishingRod_Scorpio"] = {
		ToolName = "FishingRod_Scorpio",
		ToolObject = "FishingRod_Scorpio",
		FloaterObject = "Floater_Scorpio",
		MaxThrowDistance = 64,
		ThrowHeight = 18,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(128, 0, 0), -- Maroon (scorpion)
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 5,
			IsNeon = true
		}
	},
	["FishingRod_Alien"] = {
		ToolName = "FishingRod_Alien",
		ToolObject = "FishingRod_Alien",
		FloaterObject = "Floater_Fantasy",
		MaxThrowDistance = 65,
		ThrowHeight = 18,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(0, 255, 0), -- Alien green
			Width = 0.18,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Marlin"] = {
		ToolName = "FishingRod_Marlin",
		ToolObject = "FishingRod_Marlin",
		FloaterObject = "Floater_Fish_Bone",
		MaxThrowDistance = 68,
		ThrowHeight = 19,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(0, 191, 255), -- Deep sky blue (ocean)
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 6,
			IsNeon = true
		}
	},

	-- ==================== LEGENDARY RODS ====================
	["FishingRod_Angel"] = {
		ToolName = "FishingRod_Angel",
		ToolObject = "FishingRod_Angel",
		FloaterObject = "Floater_Fantasy",
		MaxThrowDistance = 70,
		ThrowHeight = 22,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(255, 255, 255), -- Pure white (divine)
			Width = 0.18,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Angel2"] = {
		ToolName = "FishingRod_Angel2",
		ToolObject = "FishingRod_Angel2",
		FloaterObject = "Floater_Fantasy",
		MaxThrowDistance = 72,
		ThrowHeight = 22,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(255, 250, 205), -- Golden white
			Width = 0.18,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Angel3"] = {
		ToolName = "FishingRod_Angel3",
		ToolObject = "FishingRod_Angel3",
		FloaterObject = "Floater_Fantasy",
		MaxThrowDistance = 75,
		ThrowHeight = 23,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(255, 215, 0), -- Golden
			Width = 0.20,
			Transparency = 0.03,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Robot"] = {
		ToolName = "FishingRod_Robot",
		ToolObject = "FishingRod_Robot",
		FloaterObject = "Floater_Space",
		MaxThrowDistance = 70,
		ThrowHeight = 20,
		BobSpeed = 1.9,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(0, 255, 255), -- Cyan (electric)
			Width = 0.18,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Shark"] = {
		ToolName = "FishingRod_Shark",
		ToolObject = "FishingRod_Shark",
		FloaterObject = "Floater_Shark",
		MaxThrowDistance = 75,
		ThrowHeight = 21,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(70, 130, 180), -- Steel blue (shark)
			Width = 0.20,
			Transparency = 0.08,
			LightEmission = 5,
			IsNeon = true
		}
	},
	["FishingRod_Space"] = {
		ToolName = "FishingRod_Space",
		ToolObject = "FishingRod_Space",
		FloaterObject = "Floater_Space",
		MaxThrowDistance = 80,
		ThrowHeight = 24,
		BobSpeed = 1.7,
		BobHeight = 0.7,
		LineStyle = {
			Color = Color3.fromRGB(138, 43, 226), -- Blue violet (cosmic)
			Width = 0.20,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true
		}
	},
	["FishingRod_Dragon"] = {
		ToolName = "FishingRod_Dragon",
		ToolObject = "FishingRod_Dragon",
		FloaterObject = "Floater_Fantasy",
		MaxThrowDistance = 85,
		ThrowHeight = 25,
		BobSpeed = 1.5,
		BobHeight = 0.7,
		LineStyle = {
			Color = Color3.fromRGB(255, 69, 0), -- Orange red (dragon fire)
			Width = 0.22,
			Transparency = 0.03,
			LightEmission = 10,
			IsNeon = true
		}
	}
}

-- Helper function to get LineStyle for a rod
function FishingRodConfig.GetLineStyle(rodName)
	local rodConfig = FishingRodConfig.Rods[rodName]
	if rodConfig and rodConfig.LineStyle then
		return rodConfig.LineStyle
	end
	return FishingRodConfig.DefaultLineStyle
end

return FishingRodConfig
