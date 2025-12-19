--[[
    REDEEM CONFIG
    Place in ReplicatedStorage/RedeemConfig
]]

local RedeemConfig = {}

-- UI Colors
RedeemConfig.Colors = {
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
	Danger = Color3.fromRGB(237, 66, 69),
	Selected = Color3.fromRGB(50, 80, 150)
}

RedeemConfig.AnimationDuration = 0.3

-- Reward Options
RedeemConfig.MoneyOptions = {100, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000}
RedeemConfig.SummitOptions = {3, 5, 10, 25, 50, 100}

-- Tab Categories
RedeemConfig.AdminTabs = {"Title", "Auras", "Tools", "Money", "Summit"}
RedeemConfig.PlayerTabs = {"Redeem Codes"}

return RedeemConfig
