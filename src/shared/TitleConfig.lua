--[[
    TITLE CONFIG (REFACTORED WITH FISHERMAN TITLES + ACCESS CONTROL)
    Place in ReplicatedStorage/TitleConfig
]]

local TitleConfig = {}

-- ==================== FISHERMAN TITLES ====================
-- Title yang didapat berdasarkan jumlah ikan yang ditangkap (Total Fish Caught)
-- Urutan dari bawah ke atas (priority otomatis berdasarkan requirement)
-- 20 non-special titles

TitleConfig.FishermanTitles = {
	{
		Name = "Pemula",
		DisplayName = "PEMULA",
		MinFishCaught = 0,
		Color = Color3.fromRGB(180, 180, 185),
		Icon = "👤"
	},
	{
		Name = "Nelayan Baru",
		DisplayName = "NELAYAN BARU",
		MinFishCaught = 100,
		Color = Color3.fromRGB(200, 200, 200),
		Icon = "🐟"
	},
	{
		Name = "Nelayan Pemula",
		DisplayName = "NELAYAN PEMULA",
		MinFishCaught = 250,
		Color = Color3.fromRGB(139, 195, 74),
		Icon = "🎣"
	},
	{
		Name = "Nelayan Terampil",
		DisplayName = "NELAYAN TERAMPIL",
		MinFishCaught = 500,
		Color = Color3.fromRGB(100, 180, 100),
		Icon = "🐠"
	},
	{
		Name = "Nelayan Handal",
		DisplayName = "NELAYAN HANDAL",
		MinFishCaught = 1000,
		Color = Color3.fromRGB(33, 150, 243),
		Icon = "💪"
	},
	{
		Name = "Nelayan Berbakat",
		DisplayName = "NELAYAN BERBAKAT",
		MinFishCaught = 2000,
		Color = Color3.fromRGB(64, 196, 255),
		Icon = "⭐"
	},
	{
		Name = "Nelayan Ahli",
		DisplayName = "NELAYAN AHLI",
		MinFishCaught = 3500,
		Color = Color3.fromRGB(156, 39, 176),
		Icon = "🏆"
	},
	{
		Name = "Nelayan Profesional",
		DisplayName = "NELAYAN PROFESIONAL",
		MinFishCaught = 5000,
		Color = Color3.fromRGB(103, 58, 183),
		Icon = "🎖️"
	},
	{
		Name = "Master Nelayan",
		DisplayName = "MASTER NELAYAN",
		MinFishCaught = 7500,
		Color = Color3.fromRGB(255, 152, 0),
		Icon = "🏅"
	},
	{
		Name = "Grandmaster Nelayan",
		DisplayName = "GRANDMASTER NELAYAN",
		MinFishCaught = 10000,
		Color = Color3.fromRGB(255, 193, 7),
		Icon = "🥇"
	},
	{
		Name = "Kapten Nelayan",
		DisplayName = "KAPTEN NELAYAN",
		MinFishCaught = 15000,
		Color = Color3.fromRGB(255, 87, 34),
		Icon = "⚓"
	},
	{
		Name = "Admiral Nelayan",
		DisplayName = "ADMIRAL NELAYAN",
		MinFishCaught = 20000,
		Color = Color3.fromRGB(244, 67, 54),
		Icon = "🚢"
	},
	{
		Name = "Raja Laut",
		DisplayName = "RAJA LAUT",
		MinFishCaught = 30000,
		Color = Color3.fromRGB(0, 188, 212),
		Icon = "🌊"
	},
	{
		Name = "Penguasa Samudra",
		DisplayName = "PENGUASA SAMUDRA",
		MinFishCaught = 40000,
		Color = Color3.fromRGB(0, 150, 136),
		Icon = "🔱"
	},
	{
		Name = "Dewa Laut",
		DisplayName = "DEWA LAUT",
		MinFishCaught = 50000,
		Color = Color3.fromRGB(63, 81, 181),
		Icon = "⚡"
	},
	{
		Name = "Legenda Nelayan",
		DisplayName = "LEGENDA NELAYAN",
		MinFishCaught = 60000,
		Color = Color3.fromRGB(233, 30, 99),
		Icon = "🔥"
	},
	{
		Name = "Mitos Laut",
		DisplayName = "MITOS LAUT",
		MinFishCaught = 75000,
		Color = Color3.fromRGB(156, 39, 176),
		Icon = "🐉"
	},
	{
		Name = "Immortal Fisherman",
		DisplayName = "IMMORTAL FISHERMAN",
		MinFishCaught = 85000,
		Color = Color3.fromRGB(121, 85, 72),
		Icon = "♾️"
	},
	{
		Name = "Poseidon",
		DisplayName = "POSEIDON",
		MinFishCaught = 95000,
		Color = Color3.fromRGB(0, 191, 255),
		Icon = "🌀"
	},
	{
		Name = "Sang Legenda",
		DisplayName = "SANG LEGENDA",
		MinFishCaught = 100000,
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "👑"
	},
}

-- ==================== SPECIAL TITLES ====================
-- Title khusus yang override fisherman titles
-- Didapat dari gamepass, donation, atau admin grant

TitleConfig.SpecialTitles = {
	VIP = {
		DisplayName = "VIP",
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⭐",
		Priority = 100, -- Higher priority = override fisherman titles
		GamepassId = 0, -- GANTI DENGAN GAMEPASS ID VIP
		Givable = true, -- Can be given by admin
		-- Tools yang diberikan saat equip title ini
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	VVIP = {
		DisplayName = "VVIP",
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "💎",
		Priority = 200,
		GamepassId = 0, -- GANTI DENGAN GAMEPASS ID VVIP
		Givable = true, -- Can be given by admin
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	Donatur = {
		DisplayName = "DONATUR",
		Color = Color3.fromRGB(67, 181, 129),
		Icon = "💰",
		Priority = 150,
		Givable = true -- Can be given by admin
	},
	Akamsi = {
		DisplayName = "AKAMSI",
		Color = Color3.fromRGB(255, 165, 0), -- Orange
		Icon = "🎯",
		Priority = 250,
		Givable = true, -- Can be given by admin
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	SahabatAdmin = {
		DisplayName = "SAHABAT ADMIN",
		Color = Color3.fromRGB(237, 66, 69), -- Merah
		Icon = "❤️",
		Priority = 300,
		Givable = true -- Can be given by admin
	},
	Owner = {
		DisplayName = "OWNER",
		Color = Color3.fromRGB(237, 66, 69), -- Merah
		Icon = "👑",
		Priority = 1000, -- Highest priority
		Givable = false, -- Cannot be given, owner only
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun", "AdminWing"}
		}
	},
	Admin = {
		DisplayName = "ADMIN",
		Color = Color3.fromRGB(237, 66, 69),
		Icon = "👑",
		Priority = 999,
		Givable = false, -- Cannot be given, admin only
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun", "AdminWing"}
		}
	},
	["EVOS TEAM"] = {
		DisplayName = "EVOS TEAM",
		Color = Color3.fromRGB(255, 0, 0),
		Icon = "🔥",
		Priority = 998,
		Givable = true -- Can be given by admin
	},
	Trimatra = {
		DisplayName = "TRIMATRA",
		Color = Color3.fromRGB(0, 150, 255),
		Icon = "🛡️",
		Priority = 998,
		Givable = true -- Can be given by admin
	}
}

-- ==================== ACCESS CONTROL RULES ====================
-- Folder name di Workspace/Colliders/ → Allowed titles

TitleConfig.AccessRules = {
	-- Admin zones: Only admin
	["AdminZones"] = {"Admin", "Owner"},

	-- Premium zones: VIP hierarchy
	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin"}, -- VVIP + Community
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"}, -- VIP+

	-- Community/Clan zones: Exact match only (+ admin)
	["EVOSZones"] = {"EVOS TEAM", "Admin", "Owner"}, -- Only EVOS members
	["TrimatraZones"] = {"Trimatra", "Admin", "Owner"}, -- Only Trimatra members
	["AkamsiZones"] = {"Akamsi", "Admin", "Owner"}, -- Only Akamsi members
	["BoatAccess"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"},
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
-- Primary Admin: Full access to all features
-- Secondary Admin: Limited access (cannot use Notifications)
-- Both have the same "Admin" title

TitleConfig.PrimaryAdminIds = {
	8714136305,
	8578879617,
	8592664252,
}

TitleConfig.SecondaryAdminIds = {
    4680144719,
    3539387444,
    5670874280,
	9378557196,
	9099778359,
	9515803542,
	9288548837,
	9164623064,
}

-- Combine semua admin IDs (untuk compatibility dengan existing code)
TitleConfig.AdminIds = {}
for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end
for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

-- Helper functions
function TitleConfig.IsPrimaryAdmin(userId)
	for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
		if userId == id then
			return true
		end
	end
	return false
end

function TitleConfig.IsSecondaryAdmin(userId)
	for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
		if userId == id then
			return true
		end
	end
	return false
end

function TitleConfig.IsAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId) or TitleConfig.IsSecondaryAdmin(userId)
end

-- ==================== DONATION THRESHOLD ====================
-- Minimum donation untuk mendapat title "Donatur"

TitleConfig.DonationThreshold = 5000

-- ==================== HELPER: Get title based on fish caught ====================
function TitleConfig.GetFishermanTitle(totalFishCaught)
	local bestTitle = TitleConfig.FishermanTitles[1]
	
	for _, title in ipairs(TitleConfig.FishermanTitles) do
		if totalFishCaught >= title.MinFishCaught then
			bestTitle = title
		end
	end
	
	return bestTitle
end

return TitleConfig
