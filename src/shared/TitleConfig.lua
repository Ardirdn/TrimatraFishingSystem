--[[
    TITLE CONFIG (REFACTORED WITH SUMMIT INTEGRATION + ACCESS CONTROL)
    Place in ReplicatedStorage/TitleConfig
]]

local TitleConfig = {}

-- ==================== SUMMIT TITLES ====================
-- Title yang didapat berdasarkan jumlah summit
-- Urutan dari bawah ke atas (priority otomatis berdasarkan requirement)

TitleConfig.SummitTitles = {
	{
		Name = "Pengunjung",
		DisplayName = "PENGUNJUNG",
		MinSummits = 0,
		Color = Color3.fromRGB(180, 180, 185),
		Icon = "👤"
	},
	{
		Name = "Pendaki Pemula",
		DisplayName = "PENDAKI PEMULA",
		MinSummits = 10,
		Color = Color3.fromRGB(139, 195, 74),
		Icon = "🥾"
	},
	{
		Name = "Pendaki Terampil",
		DisplayName = "PENDAKI TERAMPIL",
		MinSummits = 50,
		Color = Color3.fromRGB(33, 150, 243),
		Icon = "⛰️"
	},
	{
		Name = "Pendaki Ahli",
		DisplayName = "PENDAKI AHLI",
		MinSummits = 100,
		Color = Color3.fromRGB(156, 39, 176),
		Icon = "🏔️"
	},
	{
		Name = "Master Pendaki",
		DisplayName = "MASTER PENDAKI",
		MinSummits = 500,
		Color = Color3.fromRGB(255, 152, 0),
		Icon = "🏅"
	},
	{
		Name = "Legenda Gunung",
		DisplayName = "LEGENDA GUNUNG",
		MinSummits = 1000,
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "👑"
	},
}

-- ==================== SPECIAL TITLES ====================
-- Title khusus yang override summit titles
-- Didapat dari gamepass, donation, atau admin grant

TitleConfig.SpecialTitles = {
	VIP = {
		DisplayName = "VIP",
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⭐",
		Priority = 100, -- Higher priority = override summit titles
		GamepassId = 0 -- GANTI DENGAN GAMEPASS ID VIP
	},
	VVIP = {
		DisplayName = "VVIP",
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "💎",
		Priority = 200,
		GamepassId = 0 -- GANTI DENGAN GAMEPASS ID VVIP
	},
	Donatur = {
		DisplayName = "DONATUR",
		Color = Color3.fromRGB(67, 181, 129),
		Icon = "💰",
		Priority = 150
	},
	Admin = {
		DisplayName = "ADMIN",
		Color = Color3.fromRGB(237, 66, 69),
		Icon = "👑",
		Priority = 999 -- Highest priority
	},
	["EVOS TEAM"] = {
		DisplayName = "EVOS TEAM",
		Color = Color3.fromRGB(255, 0, 0),
		Icon = "🔥",
		Priority = 998
	},
	Trimatra = {
		DisplayName = "TRIMATRA",
		Color = Color3.fromRGB(0, 150, 255),
		Icon = "🛡️",
		Priority = 998
	}
}

-- ==================== ACCESS CONTROL RULES ====================
-- Folder name di Workspace/Colliders/ → Allowed titles

TitleConfig.AccessRules = {
	-- Admin zones: Only admin
	["AdminZones"] = {"Admin"},

	-- Premium zones: VIP hierarchy
	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin"}, -- VVIP + Community
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin"}, -- VIP+

	-- Community/Clan zones: Exact match only (+ admin)
	["EVOSZones"] = {"EVOS TEAM", "Admin"}, -- Only EVOS members
	["TrimatraZones"] = {"Trimatra", "Admin"}, -- Only Trimatra members
	["BoatAccess"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin"},
}

-- ==================== ZONE COLORS ====================
-- Visual identification untuk zone colliders

TitleConfig.ZoneColors = {
	["AdminZones"] = Color3.fromRGB(237, 66, 69), -- Red
	["VVIPZones"] = Color3.fromRGB(138, 43, 226), -- Purple
	["VIPZones"] = Color3.fromRGB(255, 215, 0), -- Gold
	["EVOSZones"] = Color3.fromRGB(255, 0, 0), -- Bright Red
	["TrimatraZones"] = Color3.fromRGB(0, 150, 255), -- Blue
}



-- ==================== ADMIN IDS ====================
-- User IDs yang mendapat title Admin otomatis

TitleConfig.AdminIds = {
	8714136305, -- GANTI DENGAN USER ID ADMIN
}

-- ==================== DONATION THRESHOLD ====================
-- Minimum donation untuk mendapat title "Donatur"

TitleConfig.DonationThreshold = 5000

return TitleConfig
