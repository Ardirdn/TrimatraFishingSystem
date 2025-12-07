--[[
    MUSIC CONFIG
    Place in ReplicatedStorage/MusicConfig
    
    Format:
    ["Playlist Name"] = {
        Songs = {
            { Title = "Song Name", AssetId = "rbxassetid://123456" },
        }
    }
]]

local MusicConfig = {}

MusicConfig.Playlists = {
	["Indonesian DJ"] = {
		Songs = {
			{ Title = "Workout Mix", AssetId = "rbxassetid://1838457617" },
			{ Title = "Workout Mix 2", AssetId = "rbxassetid://1839638511" },
			{ Title = "Party Vibes", AssetId = "rbxassetid://1837196544" },
		}
	},

	["Chill Vibes"] = {
		Songs = {
			{ Title = "Sunset Dreams", AssetId = "rbxassetid://1848354536" },
			{ Title = "Ocean Waves", AssetId = "rbxassetid://1840684529" },
			{ Title = "Morning Coffee", AssetId = "rbxassetid://9043887091" },
		}
	},

	["Energetic"] = {
		Songs = {
			{ Title = "City Lights", AssetId = "rbxassetid://1838457617" },
			{ Title = "Neon Nights", AssetId = "rbxassetid://9047050075" },
			{ Title = "Electric Pulse", AssetId = "rbxassetid://1848354536" },
		}
	},

	["Study Focus"] = {
		Songs = {
			{ Title = "Focus Flow", AssetId = "rbxassetid://1840684529" },
			{ Title = "Study Beats", AssetId = "rbxassetid://1838457617"},
			{ Title = "Calm Piano", AssetId = "rbxassetid://1840684529" },
		}
	},
}

-- Settings
MusicConfig.Settings = {
	DefaultVolume = 0.5,
	AutoPlayNext = true,
}

return MusicConfig
