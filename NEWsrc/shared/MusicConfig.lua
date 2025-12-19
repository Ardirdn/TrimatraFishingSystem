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
	["Relapse"] = {
		Songs = {
			{ Title = "if there is no tomorrow", AssetId = "rbxassetid://120947955311520" },
			{ Title = "green to blue", AssetId = "rbxassetid://115901490396975" },
			{ Title = "breathe of meadow", AssetId = "rbxassetid://75837716513735" },
			{ Title = "dizzy spell", AssetId = "rbxassetid://98471899963628" },
			{ Title = "my rose", AssetId = "rbxassetid://135357833289983" },
			{ Title = "a quite sleep", AssetId = "rbxassetid://84343830528748" },
			{ Title = "moments x when rose bloom", AssetId = "rbxassetid://139609190858198" },
			{ Title = "the letter", AssetId = "rbxassetid://137988560681890" },
			{ Title = "last goodbye", AssetId = "rbxassetid://119965906813447" },
			{ Title = "walk alone", AssetId = "rbxassetid://113802998844916" },
			{ Title = "the same place", AssetId = "rbxassetid://95701896130339" },
			{ Title = "ballads at sunset", AssetId = "rbxassetid://131333954065168" },
			{ Title = "new home", AssetId = "rbxassetid://114859911033133" },
			{ Title = "twinkle of the lights", AssetId = "rbxassetid://138635422705425" },
			{ Title = "freedom", AssetId = "rbxassetid://126194620349584" },
			{ Title = "elfie", AssetId = "rbxassetid://136864807683462" },
			{ Title = "my darling", AssetId = "rbxassetid://108074190886936" },
			{ Title = "somewhere between", AssetId = "rbxassetid://128841129405401" },
			{ Title = "the french library", AssetId = "rbxassetid://128926839919145" },
			{ Title = "piana muse", AssetId = "rbxassetid://131921366022570" },
			{ Title = "track in time", AssetId = "rbxassetid://108241899445718" },
			{ Title = "lautre valse damelle", AssetId = "rbxassetid://107163095791163" },
			{ Title = "boundless bliss", AssetId = "rbxassetid://111487484027053" },
			{ Title = "this was everything for me", AssetId = "rbxassetid://114092337849217" },
			{ Title = "are we dreaming", AssetId = "rbxassetid://103413535402045" },
			{ Title = "memories of summers", AssetId = "rbxassetid://103869839650408" },
			{ Title = "childhood", AssetId = "rbxassetid://85709946615679" },
			{ Title = "i miss your warm hand", AssetId = "rbxassetid://126931185417056" },
			{ Title = "belonging", AssetId = "rbxassetid://85079800731055" },
			{ Title = "dear cecil", AssetId = "rbxassetid://92596063078923" },
			{ Title = "as i dream", AssetId = "rbxassetid://114185283591675" },
			{ Title = "once upon a time", AssetId = "rbxassetid://81914358807446" },
			{ Title = "the joy and sorrows of life", AssetId = "rbxassetid://76280723968793" },
		},
	},

	["Chill Vibes"] = {
		Songs = {
			{ Title = "a million dream", AssetId = "rbxassetid://118833030989486" },
			{ Title = "a thousand years", AssetId = "rbxassetid://117662577243439" },
			{ Title = "arms", AssetId = "rbxassetid://125342205495697" },
			{ Title = "atlantis", AssetId = "rbxassetid://110619444046928" },
			{ Title = "autumn", AssetId = "rbxassetid://134931587975720" },
			{ Title = "back to firends", AssetId = "rbxassetid://116749791063711" },
			{ Title = "back to you", AssetId = "rbxassetid://129534368405843" },
			{ Title = "balisong", AssetId = "rbxassetid://87255443462150" },
			{ Title = "before it sinks in", AssetId = "rbxassetid://131792987978981" },
			{ Title = "bloom", AssetId = "rbxassetid://124547491946917" },
			{ Title = "blue", AssetId = "rbxassetid://87975133246030" },
			{ Title = "blue jeans", AssetId = "rbxassetid://111443518018548" },
			{ Title = "coastline", AssetId = "rbxassetid://73258523115512" },
			{ Title = "die with smile", AssetId = "rbxassetid://135587963228734" },
			{ Title = "dive", AssetId = "rbxassetid://96864339956746" },
			{ Title = "easy on me", AssetId = "rbxassetid://103022798585820" },
			{ Title = "end of beginning", AssetId = "rbxassetid://124275761557053" },
			{ Title = "fix you", AssetId = "rbxassetid://86138208106082" },
			{ Title = "forgor about us", AssetId = "rbxassetid://82725338848424" },
			{ Title = "golden hour", AssetId = "rbxassetid://76816071707351" },
			{ Title = "haven knows", AssetId = "rbxassetid://81213685758872" },
			{ Title = "here with me", AssetId = "rbxassetid://70614949744164" },
			{ Title = "hey there delilah", AssetId = "rbxassetid://75246445349191" },
			{ Title = "i love you so", AssetId = "rbxassetid://94557475512105" },
			{ Title = "iris", AssetId = "rbxassetid://128801663973593" },
			{ Title = "je te laisserai des mots", AssetId = "rbxassetid://135764972705379" },
			{ Title = "last night on earth", AssetId = "rbxassetid://85692534641817" },
			{ Title = "line without a hook", AssetId = "rbxassetid://81023599207608" },
			{ Title = "little bit better", AssetId = "rbxassetid://135595684186242" },
			{ Title = "lovers oath", AssetId = "rbxassetid://125270179833214" },
			{ Title = "lovesong", AssetId = "rbxassetid://124341362116583" },
			{ Title = "mean it", AssetId = "rbxassetid://135779574362852" },
			{ Title = "number one girl", AssetId = "rbxassetid://131623722051497" },
			{ Title = "ocean & engeneers", AssetId = "rbxassetid://108593109383586" },
			{ Title = "on the train ride home", AssetId = "rbxassetid://123348923044460" },
			{ Title = "only reminds me of you", AssetId = "rbxassetid://130616673464088" },
			{ Title = "photograph", AssetId = "rbxassetid://118257214009397" },
			{ Title = "please never fall in love again", AssetId = "rbxassetid://117573417605066" },
			{ Title = "rises the moon", AssetId = "rbxassetid://129746674613076" },
			{ Title = "romantic homiside", AssetId = "rbxassetid://104767078294583" },
			{ Title = "running up that hill", AssetId = "rbxassetid://119238505598337" },
			{ Title = "sailor song", AssetId = "rbxassetid://70563995821927" },
			{ Title = "say yes to haven", AssetId = "rbxassetid://119238505598337" },
			{ Title = "seasons", AssetId = "rbxassetid://71723658891519" },
			{ Title = "sleep well", AssetId = "rbxassetid://132164079378509" },
			{ Title = "skinny", AssetId = "rbxassetid://135506703659531" },
			{ Title = "take chance with me", AssetId = "rbxassetid://83862861987300" },
			{ Title = "the greatest", AssetId = "rbxassetid://129672553822970" },
			{ Title = "the man who cant be", AssetId = "rbxassetid://78215825467558" },
			{ Title = "the only exception", AssetId = "rbxassetid://70497004593016" },
			{ Title = "thin line between", AssetId = "rbxassetid://91586351052817" },
			{ Title = "till my heartaches", AssetId = "rbxassetid://72912289761652" },
			{ Title = "toxic till the end", AssetId = "rbxassetid://110365030180578" },
			{ Title = "understand", AssetId = "rbxassetid://94289384501177" },
			{ Title = "until found you", AssetId = "rbxassetid://72815560707718" },
			{ Title = "we cant be friends", AssetId = "rbxassetid://124129602614673" },
			{ Title = "wildflower", AssetId = "rbxassetid://81220316770238" },
			{ Title = "you are the reason", AssetId = "rbxassetid://71380955795357" },
			{ Title = "youll be safe here", AssetId = "rbxassetid://103482274738607" },
		},
	},

	["Indonesian"] = {
		Songs = {
			{ Title = "Diatas Awan", AssetId = "rbxassetid://122084576223977" },
			{ Title = "diujung jalan", AssetId = "rbxassetid://107562371279982" },
			{ Title = "istirahat", AssetId = "rbxassetid://138558621922189" },
			{ Title = "mangu", AssetId = "rbxassetid://76190919416432" },
			{ Title = "rasah balih", AssetId = "rbxassetid://82493297152153" },
			{ Title = "semoga ya", AssetId = "rbxassetid://87794666183077" },
			{ Title = "tunjukan cintamu", AssetId = "rbxassetid://89032458364816" },
			{ Title = "ridu aku rindu kamu", AssetId = "rbxassetid://98899384772913" },
			{ Title = "alamak", AssetId = "rbxassetid://80481687237622" },
			{ Title = "nina", AssetId = "rbxassetid://95932585681010" },
			{ Title = "everything you are", AssetId = "rbxassetid://80530783852148" },
			{ Title = "cincin", AssetId = "rbxassetid://75023305459964" },
			{ Title = "o tuan", AssetId = "rbxassetid://75266455233820" },
			{ Title = "terbuang dalam waktu", AssetId = "rbxassetid://113672225041814" },
			{ Title = "kita usahakan lagi", AssetId = "rbxassetid://88750493773620" },
			{ Title = "tarot", AssetId = "rbxassetid://128048020444248" },
			{ Title = "serena", AssetId = "rbxassetid://114812650344143" },
			{ Title = "evaluasi", AssetId = "rbxassetid://103656469303316" },
			{ Title = "tabola bale", AssetId = "rbxassetid://82787172711682" },
			{ Title = "ngapain repot", AssetId = "rbxassetid://78881151167254" },
			{ Title = "tor monitor", AssetId = "rbxassetid://121660039935142" },
		},
	},
	["Other"] = {
		Songs = {
			{ Title = "multo", AssetId = "rbxassetid://133983826539891" },
			{ Title = "ldr", AssetId = "rbxassetid://105260817607920" },
		},
	},
}

-- Settings
MusicConfig.Settings = {
	DefaultVolume = 0.5,
	AutoPlayNext = true,
}

return MusicConfig
