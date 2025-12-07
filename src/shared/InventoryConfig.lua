--[[
    INVENTORY CONFIG
    Place in ReplicatedStorage/InventoryConfig
]]

local InventoryConfig = {}

-- UI Colors (match dengan sistem lain)
InventoryConfig.Colors = {
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
	Equipped = Color3.fromRGB(90, 200, 120)
}

-- Panel Settings
InventoryConfig.PanelSize = UDim2.new(0, 700, 0, 400)
InventoryConfig.AnimationDuration = 0.3

-- Grid Settings
InventoryConfig.GridCellSize = UDim2.new(0, 90, 0, 90)
InventoryConfig.GridCellPadding = UDim2.new(0, 10, 0, 10) -- ✅ FIXED: UDim2, bukan UDim!

-- Categories
InventoryConfig.Categories = {
	"All",
	"Auras",
	"Tools"
}

return InventoryConfig