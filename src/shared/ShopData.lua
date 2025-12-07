local ShopData = {}

ShopData.RodShop = {
	-- Starter Rods (Free/Cheap)
	["FishingRod_Wood1"] = {
		DisplayName = "Wooden Rod",
		Price = 0, -- Free starter
		Description = "Basic wooden fishing rod. Perfect for beginners!",
		Category = "Starter",
		Image = "rbxassetid://0",
		Rarity = "Common"
	},
	["FishingRod_Bamboo"] = {
		DisplayName = "Bamboo Rod",
		Price = 250,
		Description = "Lightweight bamboo rod with decent range.",
		Category = "Starter",
		Image = "rbxassetid://0",
		Rarity = "Common"
	},

	-- Basic Rods
	["FishingRod_Copper"] = {
		DisplayName = "Copper Rod",
		Price = 500,
		Description = "Durable copper rod with improved casting.",
		Category = "Basic",
		Image = "rbxassetid://0",
		Rarity = "Uncommon"
	},
	["FishingRod_Anchor"] = {
		DisplayName = "Anchor Rod",
		Price = 750,
		Description = "Heavy-duty rod inspired by ship anchors.",
		Category = "Basic",
		Image = "rbxassetid://0",
		Rarity = "Uncommon"
	},
	["FishingRod_Tribe"] = {
		DisplayName = "Tribal Rod",
		Price = 850,
		Description = "Ancient tribal design with mystical powers.",
		Category = "Basic",
		Image = "rbxassetid://0",
		Rarity = "Uncommon"
	},

	-- Themed Rods
	["FishingRod_Banana"] = {
		DisplayName = "Banana Rod",
		Price = 1200,
		Description = "A-peel-ing rod that's perfect for tropical fishing!",
		Category = "Themed",
		Image = "rbxassetid://0",
		Rarity = "Rare"
	},
	["FishingRod_Bacon"] = {
		DisplayName = "Bacon Rod",
		Price = 1300,
		Description = "Crispy and delicious... wait, for fishing?!",
		Category = "Themed",
		Image = "rbxassetid://0",
		Rarity = "Rare"
	},
	["FishingRod_Love"] = {
		DisplayName = "Love Rod",
		Price = 1500,
		Description = "Spread love while catching fish! ❤️",
		Category = "Themed",
		Image = "rbxassetid://0",
		Rarity = "Rare"
	},
	["FishingRod_Bat"] = {
		DisplayName = "Bat Rod",
		Price = 1600,
		Description = "Perfect for night fishing and spooky vibes.",
		Category = "Themed",
		Image = "rbxassetid://0",
		Rarity = "Rare"
	},
	["FishingRod_Crab"] = {
		DisplayName = "Crab Rod",
		Price = 1800,
		Description = "Pinch your way to victory!",
		Category = "Themed",
		Image = "rbxassetid://0",
		Rarity = "Rare"
	},

	-- Advanced Rods
	["FishingRod_Seal"] = {
		DisplayName = "Seal Rod",
		Price = 2500,
		Description = "Arctic-inspired rod for cold water fishing.",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Mercusuar"] = {
		DisplayName = "Lighthouse Rod",
		Price = 2800,
		Description = "Guide your catches like a beacon in the night.",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Knight"] = {
		DisplayName = "Knight Rod",
		Price = 3000,
		Description = "Medieval power for honorable anglers.",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Dryad"] = {
		DisplayName = "Dryad Rod",
		Price = 3500,
		Description = "Nature's blessing in rod form.",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Dryad2"] = {
		DisplayName = "Dryad Rod II",
		Price = 4000,
		Description = "Enhanced nature magic for experienced anglers.",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Scorpio"] = {
		DisplayName = "Scorpio Rod",
		Price = 4500,
		Description = "Strike with the precision of a scorpion!",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Alien"] = {
		DisplayName = "Alien Rod",
		Price = 5000,
		Description = "Out-of-this-world fishing technology!",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},
	["FishingRod_Marlin"] = {
		DisplayName = "Marlin Rod",
		Price = 5500,
		Description = "Built for catching the biggest marlins.",
		Category = "Advanced",
		Image = "rbxassetid://0",
		Rarity = "Epic"
	},

	-- Legendary Rods
	["FishingRod_Angel"] = {
		DisplayName = "Angel Rod",
		Price = 7000,
		Description = "Divine rod blessed by the heavens.",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	},
	["FishingRod_Angel2"] = {
		DisplayName = "Angel Rod II",
		Price = 8000,
		Description = "Ascended divine power!",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	},
	["FishingRod_Angel3"] = {
		DisplayName = "Angel Rod III",
		Price = 9500,
		Description = "Ultimate celestial fishing power!",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	},
	["FishingRod_Robot"] = {
		DisplayName = "Robot Rod",
		Price = 10000,
		Description = "Cutting-edge robotic fishing technology.",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	},
	["FishingRod_Shark"] = {
		DisplayName = "Shark Rod",
		Price = 12000,
		Description = "Harness the power of the ocean's apex predator!",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	},
	["FishingRod_Space"] = {
		DisplayName = "Space Rod",
		Price = 15000,
		Description = "Fish among the stars with cosmic power!",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	},
	["FishingRod_Dragon"] = {
		DisplayName = "Dragon Rod",
		Price = 20000,
		Description = "The ultimate rod. Legendary dragon power!",
		Category = "Legendary",
		Image = "rbxassetid://0",
		Rarity = "Legendary"
	}
}

-- Rarity colors
ShopData.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

return ShopData
