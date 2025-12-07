--[[
    DONATE CONFIG
    Place in ReplicatedStorage/DonateConfig
]]

local DonateConfig = {}

-- Donation threshold untuk unlock title "Donatur"
DonateConfig.DonationThreshold = 1000 -- Robux

-- Donation Packages
DonateConfig.Packages = {
	{
		Title = "Starter",
		Description = "Support kecil",
		Amount = 10,
		ProductId = 3465203706, -- ⚠️ GANTI DENGAN PRODUCT ID ASLI
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(100, 149, 237)
	},
	{
		Title = "Bronze",
		Description = "Dukungan Bronze",
		Amount = 25,
		ProductId = 3465203890,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(205, 127, 50)
	},
	{
		Title = "Silver",
		Description = "Dukungan Silver",
		Amount = 50,
		ProductId = 3465204030,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(192, 192, 192)
	},
	{
		Title = "Gold",
		Description = "Dukungan Gold",
		Amount = 100,
		ProductId = 3465204182,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 215, 0)
	},
	{
		Title = "Platinum",
		Description = "Dukungan Platinum",
		Amount = 250,
		ProductId = 3465204299,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(229, 228, 226)
	},
	{
		Title = "Diamond",
		Description = "Dukungan Diamond",
		Amount = 500,
		ProductId = 3465204387,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(185, 242, 255)
	},
	{
		Title = "Master",
		Description = "Dukungan Master",
		Amount = 1000,
		ProductId = 3465204599,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(138, 43, 226)
	},
	{
		Title = "Champion",
		Description = "Dukungan Champion",
		Amount = 2500,
		ProductId = 3465204761,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 69, 0)
	},
	{
		Title = "Legend",
		Description = "Dukungan Legend",
		Amount = 5000,
		ProductId = 3465204885,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 0, 255)
	},
	{
		Title = "Mythic",
		Description = "Dukungan Mythic",
		Amount = 10000,
		ProductId = 3465205043,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 20, 147)
	},
	{
		Title = "Divine",
		Description = "Dukungan Divine",
		Amount = 25000,
		ProductId = 3465205182,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 255, 0)
	},
	{
		Title = "Supreme",
		Description = "Dukungan Supreme",
		Amount = 50000,
		ProductId = 3465205311,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 0, 0)
	},
}
-- UI Colors
DonateConfig.Colors = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Header = Color3.fromRGB(30, 30, 33),
	Button = Color3.fromRGB(35, 35, 38),
	ButtonHover = Color3.fromRGB(45, 45, 48),
	Accent = Color3.fromRGB(70, 130, 255),
	AccentHover = Color3.fromRGB(90, 150, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Border = Color3.fromRGB(50, 50, 55),
	Success = Color3.fromRGB(67, 181, 129),
	Premium = Color3.fromRGB(255, 215, 0),
}

DonateConfig.AnimationDuration = 0.3

return DonateConfig
