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
		Title = "Pendukung",
		Description = "Terima kasih atas dukunganmu",
		Amount = 10,
		ProductId = 3477232102, -- ⚠️ GANTI DENGAN PRODUCT ID ASLI
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(100, 149, 237)
	},
	{
		Title = "Supporter",
		Description = "Dukungan yang berarti",
		Amount = 25,
		ProductId = 3477234178,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(205, 127, 50)
	},
	{
		Title = "Dermawan",
		Description = "Kebaikan nyata",
		Amount = 50,
		ProductId = 3477234813,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(192, 192, 192)
	},
	{
		Title = "Donatur",
		Description = "Kontribusi besar",
		Amount = 100,
		ProductId = 3477235073,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(255, 215, 0)
	},
	{
		Title = "Patron",
		Description = "Pendukung setia",
		Amount = 250,
		ProductId = 3477236527,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(229, 228, 226)
	},
	{
		Title = "Sponsor",
		Description = "Dukungan premium",
		Amount = 500,
		ProductId = 3477237448,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(185, 242, 255)
	},
	{
		Title = "Elite",
		Description = "Level elite",
		Amount = 1000,
		ProductId = 3477238669,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(138, 43, 226)
	},
	{
		Title = "VIP",
		Description = "Status VIP",
		Amount = 2500,
		ProductId = 3477239301,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(255, 69, 0)
	},
	{
		Title = "Legend",
		Description = "Tier legendaris",
		Amount = 5000,
		ProductId = 3477240204,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(255, 0, 255)
	},
	{
		Title = "Mythic",
		Description = "Tier mythic",
		Amount = 10000,
		ProductId = 3477240475,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(255, 20, 147)
	},
	{
		Title = "Supreme",
		Description = "Tier supreme",
		Amount = 25000,
		ProductId = 3477240678,
		Thumbnail = "rbxassetid://80414324814070",
		Color = Color3.fromRGB(255, 255, 0)
	},
	{
		Title = "Ultimate",
		Description = "Tier tertinggi",
		Amount = 50000,
		ProductId = 3477240934,
		Thumbnail = "rbxassetid://80414324814070",
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
