--[[
    ROD SHOP CONFIG
    Place in ReplicatedStorage/Modules
    
    Configuration for Fishing Rods and Floaters/Baits
    Updated: FloaterIds now match actual floater objects in ReplicatedStorage/FishingRods/Floaters
]]

local RodShopConfig = {}

-- Rarity colors
RodShopConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

-- Fishing Rods (sama seperti sebelumnya)
RodShopConfig.Rods = {
	-- Starter Rods (Free/Cheap)
	{
		RodId = "FishingRod_Wood1",
		DisplayName = "Wooden Rod",
		Price = 0, -- Free starter
		Description = "Basic wooden fishing rod. Perfect for beginners!",
		Category = "Starter",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Common",
		CatchBonus = 0,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Bamboo",
		DisplayName = "Bamboo Rod",
		Price = 250,
		Description = "Lightweight bamboo rod with decent range.",
		Category = "Starter",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Common",
		CatchBonus = 5,
		IsPremium = false
	},

	-- Basic Rods
	{
		RodId = "FishingRod_Copper",
		DisplayName = "Copper Rod",
		Price = 500,
		Description = "Durable copper rod with improved casting.",
		Category = "Basic",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Uncommon",
		CatchBonus = 10,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Anchor",
		DisplayName = "Anchor Rod",
		Price = 750,
		Description = "Heavy-duty rod inspired by ship anchors.",
		Category = "Basic",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Uncommon",
		CatchBonus = 12,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Tribe",
		DisplayName = "Tribal Rod",
		Price = 850,
		Description = "Ancient tribal design with mystical powers.",
		Category = "Basic",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Uncommon",
		CatchBonus = 15,
		IsPremium = false
	},

	-- Themed Rods
	{
		RodId = "FishingRod_Banana",
		DisplayName = "Banana Rod",
		Price = 1200,
		Description = "A-peel-ing rod that's perfect for tropical fishing!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		CatchBonus = 20,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Bacon",
		DisplayName = "Bacon Rod",
		Price = 1300,
		Description = "Crispy and delicious... wait, for fishing?!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		CatchBonus = 22,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Love",
		DisplayName = "Love Rod",
		Price = 1500,
		Description = "Spread love while catching fish! ❤️",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		CatchBonus = 25,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Bat",
		DisplayName = "Bat Rod",
		Price = 1600,
		Description = "Perfect for night fishing and spooky vibes.",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		CatchBonus = 28,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Crab",
		DisplayName = "Crab Rod",
		Price = 1800,
		Description = "Pinch your way to victory!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		CatchBonus = 30,
		IsPremium = false
	},

	-- Advanced Rods
	{
		RodId = "FishingRod_Seal",
		DisplayName = "Seal Rod",
		Price = 2500,
		Description = "Arctic-inspired rod for cold water fishing.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 35,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Mercusuar",
		DisplayName = "Lighthouse Rod",
		Price = 2800,
		Description = "Guide your catches like a beacon in the night.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 38,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Knight",
		DisplayName = "Knight Rod",
		Price = 3000,
		Description = "Medieval power for honorable anglers.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 40,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Dryad",
		DisplayName = "Dryad Rod",
		Price = 3500,
		Description = "Nature's blessing in rod form.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 45,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Dryad2",
		DisplayName = "Dryad Rod II",
		Price = 4000,
		Description = "Enhanced nature rod with deeper connection.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 48,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Scorpio",
		DisplayName = "Scorpio Rod",
		Price = 4500,
		Description = "Strike with the precision of a scorpion!",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 50,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Alien",
		DisplayName = "Alien Rod",
		Price = 5000,
		Description = "Out-of-this-world fishing technology!",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 55,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Marlin",
		DisplayName = "Marlin Rod",
		Price = 5500,
		Description = "Built for catching the biggest marlins.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		CatchBonus = 58,
		IsPremium = false
	},

	-- Legendary Rods
	{
		RodId = "FishingRod_Angel",
		DisplayName = "Angel Rod",
		Price = 7000,
		Description = "Divine rod blessed by the heavens.",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 65,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Angel2",
		DisplayName = "Angel Rod II",
		Price = 8500,
		Description = "Enhanced divine rod with heavenly power.",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 70,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Angel3",
		DisplayName = "Angel Rod III",
		Price = 9500,
		Description = "Ultimate divine rod, closest to the heavens.",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 75,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Robot",
		DisplayName = "Robot Rod",
		Price = 10000,
		Description = "Cutting-edge robotic fishing technology.",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 80,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Shark",
		DisplayName = "Shark Rod",
		Price = 12000,
		Description = "Harness the power of the ocean's apex predator!",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 85,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Space",
		DisplayName = "Space Rod",
		Price = 15000,
		Description = "Fish among the stars with cosmic power!",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 95,
		IsPremium = false
	},
	{
		RodId = "FishingRod_Dragon",
		DisplayName = "Dragon Rod",
		Price = 20000,
		Description = "The ultimate rod. Legendary dragon power!",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		CatchBonus = 100,
		IsPremium = false
	},
}

-- ==================== FLOATERS ====================
-- FloaterId HARUS SAMA dengan nama model di ReplicatedStorage/FishingRods/Floaters
RodShopConfig.Floaters = {
	-- Basic Floaters (berdasarkan FloaterObject dari FishingRod.config.lua)
	{
		FloaterId = "Floater_Doll",
		DisplayName = "Doll Floater",
		Price = 0, -- Free starter
		Description = "Cute doll floater. Perfect for beginners!",
		Category = "Basic",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Common",
		LuckBonus = 0,
		IsPremium = false
	},
	{
		FloaterId = "Floater_Cooper",
		DisplayName = "Copper Floater",
		Price = 500,
		Description = "Durable copper floater that shines in the water.",
		Category = "Basic",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Uncommon",
		LuckBonus = 10,
		IsPremium = false
	},
	
	-- Themed Floaters
	{
		FloaterId = "Floater_Candy",
		DisplayName = "Candy Floater",
		Price = 800,
		Description = "Sweet candy-shaped floater that fish love!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		LuckBonus = 15,
		IsPremium = false
	},
	{
		FloaterId = "Floater_skeleton",
		DisplayName = "Skeleton Floater",
		Price = 1200,
		Description = "Spooky skeleton floater for Halloween fishing!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		LuckBonus = 20,
		IsPremium = false
	},
	{
		FloaterId = "Floater_Fish_Bone",
		DisplayName = "Fish Bone Floater",
		Price = 1500,
		Description = "Ironic fish bone floater. Fish find it intimidating!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		LuckBonus = 25,
		IsPremium = false
	},
	{
		FloaterId = "Floater_Pinguin",
		DisplayName = "Penguin Floater",
		Price = 2000,
		Description = "Adorable penguin floater for arctic waters!",
		Category = "Themed",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Rare",
		LuckBonus = 30,
		IsPremium = false
	},
	
	-- Advanced Floaters
	{
		FloaterId = "Floater_Fantasy",
		DisplayName = "Fantasy Floater",
		Price = 3000,
		Description = "Magical fantasy floater with mystical properties.",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		LuckBonus = 40,
		IsPremium = false
	},
	{
		FloaterId = "Floater_Scorpio",
		DisplayName = "Scorpio Floater",
		Price = 4000,
		Description = "Zodiac-powered scorpion floater!",
		Category = "Advanced",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Epic",
		LuckBonus = 50,
		IsPremium = false
	},
	
	-- Legendary Floaters
	{
		FloaterId = "Floater_Space",
		DisplayName = "Space Floater",
		Price = 8000,
		Description = "Cosmic space floater from another galaxy!",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		LuckBonus = 75,
		IsPremium = false
	},
	{
		FloaterId = "Floater_Shark",
		DisplayName = "Shark Floater",
		Price = 12000,
		Description = "Fierce shark floater that attracts big fish!",
		Category = "Legendary",
		Thumbnail = "rbxassetid://7733764811",
		Rarity = "Legendary",
		LuckBonus = 100,
		IsPremium = false
	},
}

-- Helper Functions
function RodShopConfig.GetRodById(rodId)
	for _, rod in ipairs(RodShopConfig.Rods) do
		if rod.RodId == rodId then
			return rod
		end
	end
	return nil
end

function RodShopConfig.GetFloaterById(floaterId)
	for _, floater in ipairs(RodShopConfig.Floaters) do
		if floater.FloaterId == floaterId then
			return floater
		end
	end
	return nil
end

return RodShopConfig
