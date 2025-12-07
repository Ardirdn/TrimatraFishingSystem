local FishConfig = {}

-- Rarity weight untuk random selection
FishConfig.RarityWeights = {
	Common = 50,      -- 50%
	Uncommon = 30,    -- 30%
	Rare = 15,        -- 15%
	Epic = 4,         -- 4%
	Legendary = 1     -- 1%
}

-- Rarity colors
FishConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

-- Base price per rarity (auto-calculated for each fish)
FishConfig.RarityBasePrices = {
	Common = 100,
	Uncommon = 250,
	Rare = 750,
	Epic = 2000,
	Legendary = 5000
}

FishConfig.Fish = {
	["Achilles_Tang"] = {
		Name = "Botana Achilles",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://77473641636506"

	},

	["Anchovy"] = {
		Name = "Teri",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://125299513112100"

	},
	["Angler_Fish"] = {
		Name = "Pemancing",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://85087841821673"

	},
	["Archer_Fish"] = {
		Name = "Pemanah",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://123000937834966"

	},
	["Asfur_Angelfish"] = {
		Name = "Bidadari Asfur",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://135037166184237"

	},
	["Axoltl"] = {
		Name = "Axolotl",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://135037166184237"

	},
	["Bali_Sardinella"] = {
		Name = "Lemuru Bali",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://77166605609520"

	},
	["Balistapus_Undulatus"] = {
		Name = "Kambing Liris",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://80915264987117"

	},
	["Banggai"] = {
		Name = "Capungan Banggai",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://79994325230007"

	},
	["Barracuda"] = {
		Name = "Barakuda",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://112822388882245"

	},
	["Barred_Angelfish"] = {
		Name = "Bidadari Berpita",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://135863037634850"

	},
	["Barred_Hamlet"] = {
		Name = "Kerapu Bandih",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://87102589555080"

	},
	["Bicolor_Pseudochromis"] = {
		Name = "Bicolor Dottyback",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://81500585666300"

	},
	["Bicolour_Angel_Fish"] = {
		Name = "Injel Biru Kuning",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://81500585666300"

	},
	["Big_Eyes_Soldier_Fish"] = {
		Name = "Semadar",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://88661171330572"

	},
	["Bigeye_Trevally"] = {
		Name = "Kuwe Tengkek",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://96964008664589"

	},
	["Black_Barred_konvik"] = {
		Name = "Gerut-Gerut",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://119793685305961"

	},
	["Black_Hamlet"] = {
		Name = "Hamlet Hitam",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://81218122987041"

	},
	["Black_Marlin"] = {
		Name = "Marlin Hitam",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://71080427782346"

	},
	["Black_Pomfret"] = {
		Name = "Bawal Hitam",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://95254445571354v"

	},
	["Black_Snapper"] = {
		Name = "Kakap Hitam",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://123075208520134"

	},
	["Blackstripe_Dottyback"] = {
		Name = "Dottyback Garis Hitam",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://88764395276270"

	},
	["Blacktip_Grouper"] = {
		Name = "Ikan Kerapu Ujung Hitam",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://94165703821831"

	},
	["Blenny"] = {
		Name = "Blennyv",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://120934502354279"

	},
	["Bloop"] = {
		Name = "Bloop",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://89412777445331"

	},
	["Blue_Angel_Fish"] = {
		Name = "Bidadari Biru",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://135863037634850"

	},
	["Blue_Hamlet"] = {
		Name = " Hamlet Biru",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://140634036282061"

	},
	["Blue_lined_Rabbit_Fish"] = {
		Name = " Baronang Garis Biru",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://138679238806304"

	},
	["Blue_Marlin"] = {
		Name = " Marlin Biru",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://123091291461822"

	},
	["Blue_Ring_Angelfish"] = {
		Name = " Injel Cincin Biru",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://110880245110256"

	},
	["Blue_Tang"] = {
		Name = " Botana Biru",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://88338922163974"

	},
	["Bluespotted_Angel_Fish"] = {
		Name = " Bidadari Bintik Biru",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://114360986481166"

	},
	["Bluespotted_Dottyback"] = {
		Name = " Dottyback Bintik Biru",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://114360986481166"

	},
	["Bluestone_Fish"] = {
		Name = " Batu Biru",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://110225545711025"

	},
	["Bodianus_Mesothorax"] = {
		Name = "Blackbelt Hogfish",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://132763509583237"

	},
	["Buter_Hamlet"] = {
		Name = " Hamlet Kuning Mentega",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://90682663971179"

	},
	["Cherry_Dottyback"] = {
		Name = " Dottyback Ceri",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://130514099226091"

	},
	["Clown_Fish"] = {
		Name = "Badut",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://91768340311662"

	},
	["Cobia"] = {
		Name = "Cobia",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://136069499145146"

	},
	["Coelacanth"] = {
		Name = " Coelacanth",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://100035950119909"

	},
	["Copperband"] = {
		Name = " Kuping Tembaga",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://121316920485041"

	},
	["Coral_Beauties"] = {
		Name = " Bidadari Karang",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://115677619686870"

	},
	["Damsel_Fish"] = {
		Name = " Damsel",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://133634530128535"

	},
	["Dartfish"] = {
		Name = " Panah",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://121400653222550"

	},
	["Dilectus_dottyback"] = {
		Name = " Dottyback Dilectus",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://132242323115869"

	},
	["Doctor_Fish"] = {
		Name = " Dokter",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://135178711496795"

	},
	["Dolphin"] = {
		Name = "Lumba-lumba",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://82019479855131"

	},
	["Dragon_Fish"] = {
		Name = "Naga",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://80969558424595"

	},
	["Dugong"] = {
		Name = "Duyung",
		Rarity = "Dugong",
		Price = 0,
		ImageID = "rbxassetid://80344469662511"

	},
	["Duski_Bat_Fish"] = {
		Name = " Kelelawar Abu-Abu",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://133801704512099"

	},
	["Eagle_Stingray"] = {
		Name = "Pari Elang",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://101588963064882"

	},
	["Fish_Injel"] = {
		Name = " Injel",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://116583005925603"

	},
	["Flapjack_Octopus"] = {
		Name = "Gurita Flapjack",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://122160049185466"

	},
	["Flounder"] = {
		Name = " Lidah",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://75449945870941"

	},
	["Flying_Fish"] = {
		Name = " Terbang",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://132943584164568"

	},
	["Freckil_Hawk_Fish"] = {
		Name = " Hawkfish Bintik Hawkfish Bintik",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://115849519626600"

	},
	["GG"] = {
		Name = "Kuwe Rambut",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://103045042248960"

	},
	["Goblin_Shark"] = {
		Name = "Hiu Goblin",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://106283605669981"

	},
	["Golden_Pilot_Fish"] = {
		Name = " Pilot Emas",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://82675541310624"

	},
	["Golden_Trevally"] = {
		Name = " Kuwe Emas",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://119435247134511"

	},
	["Goliath_Grouper"] = {
		Name = " Kerapu Goliath",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://120197685022205"

	},
	["Gray_Fish"] = {
		Name = " Abu-abu",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://87037931136157"

	},
	["Greater_Amberjack"] = {
		Name = " Amberjack Besar",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://113383087091139"

	},
	["Green_Firetail_Dottyback"] = {
		Name = " Dottyback Ekor Api Hijau",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://128154901405328"

	},
	["Griffin_Angel_Fish"] = {
		Name = " Bidadari Griffin",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://73802925323027"

	},
	["Halibut"] = {
		Name = "Halibut",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://92496585050754"

	},
	["Hammerhead_Shark"] = {
		Name = "Hiu Martil",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://135076968932942"

	},
	["Indian_Mackerel"] = {
		Name = " Kembung India",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://90643888921580"

	},
	["Indian_Ocean_Mimic"] = {
		Name = " Peniru Samudra Hindia",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://107964050137168"

	},
	["Indigo_Dottyback"] = {
		Name = " Dottyback Nila",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://127143840045029"

	},
	["Jackfruit_Seed_Fish"] = {
		Name = " Biji Nangka",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://131097301196329"

	},
	["Kerapu"] = {
		Name = " Kerapu",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://100811433863858"

	},
	["Killer_Whale"] = {
		Name = "Paus Pembunuh",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://97856883337811"

	},
	["Kole_Tang"] = {
		Name = " Botana Kole",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://121474224602138"

	},
	["Konvik_Surgeon_fish"] = {
		Name = "Surgeon Konvik",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://121586190180862"

	},
	["Kuro"] = {
		Name = "Kuro",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://83844796376482"

	},
	["Leafy_Sea_Dragon"] = {
		Name = "Naga Laut Berdaun",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://89796584232322"

	},
	["Lion_Fish"] = {
		Name = " Singa",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://101546489431818"

	},
	["Lizardfish"] = {
		Name = " Kadal",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://96970222821923"

	},
	["Longnose_Butterfly_Fish"] = {
		Name = " Kupu-kupu Hidung Panjang",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://80024758771213"

	},
	["Lyretail_Dotty_Back"] = {
		Name = " Dottyback Ekor Panjang",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://128154901405328"

	},
	["Mackerel"] = {
		Name = " Tenggiri",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://136927240781334"

	},
	["Mahi_Mahi"] = {
		Name = "Mahi-Mahi",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://137023355730390"

	},
	["Mandarin_Fish"] = {
		Name = "Mandarin",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://98087171293432"

	},
	["Marlin"] = {
		Name = "Marlin",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://129793451823919"

	},
	["Megalodon"] = {
		Name = "Megalodon",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://104685081852429"

	},
	["Moorish_Idol"] = {
		Name = " Moorish Idol",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://108010668810839"

	},
	["Moray_Eel"] = {
		Name = "Belut Moray",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://121199917662821"

	},
	["Napoleon_Wrasse"] = {
		Name = " Napoleon",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://111809799921599"

	},
	["Narwehal_Whale"] = {
		Name = "Paus Narwhal",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://116400834360855"

	},
	["Neon_Dottyback"] = {
		Name = " Dottyback Neon",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://102323217251608"

	},
	["Oar_Fish"] = {
		Name = " Oar",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://117116787687259"

	},
	["Oblique_Line_Dottyback"] = {
		Name = " Dottyback Garis Miring",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://130106457206720"

	},
	["Octopus"] = {
		Name = "Gurita",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://92988516722961"

	},
	["Opah"] = {
		Name = " Opah",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://107019798102331"

	},
	["Orbiculate_Batfish"] = {
		Name = " Kelelawar Orbikulat",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://129340787160498"

	},
	["Pajama_Cardinalfish"] = {
		Name = " Cardinal Pajama",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://115647705344823"

	},
	["Parrotfish"] = {
		Name = "Kakatua ",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://88938473804032"

	},
	["Pink_Stingray"] = {
		Name = "Pari Merah Muda",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://140531031678781"

	},
	["Pomfret"] = {
		Name = " Bawal",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://136586948872507"

	},
	["Puffer_Fish"] = {
		Name = " Buntal",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://138412057075239"

	},
	["Rabbitfish"] = {
		Name = " Baronang",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://103181399516046"

	},
	["Rainbow_Fish"] = {
		Name = " Pelangi",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://131664926257520"

	},
	["Red_Snapper"] = {
		Name = " Kakap Merah",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://92268152438544"

	},
	["Ribbon_Eel"] = {
		Name = "Belut Pita",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://76230732414972"

	},
	["Saddle_Butterfly_Fish"] = {
		Name = " Kepe-kepe Pelana",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://80024758771213"

	},
	["Sailfin_Dottyback"] = {
		Name = " Dottyback Layar",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://110765013666946"

	},
	["Salmon"] = {
		Name = "Salmon",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://88199736689424"

	},
	["Sardine"] = {
		Name = "Sarden",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://104308024239225"

	},
	["Seahorse"] = {
		Name = "Kuda Laut",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://111271298951056"

	},
	["Sheep_Shead"] = {
		Name = " Kepala Domba",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://134417038241724"

	},
	["Silver_Pomfret"] = {
		Name = " Bawal Perak",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://121535498448590"

	},
	["Skipjack_Tuna"] = {
		Name = "Cakalang",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://102012535423122"

	},
	["Spanish_Mackerel"] = {
		Name = "Tenggiri Spanyol",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://96678748241371"

	},
	["Spinycheek_Scorpion_Fish"] = {
		Name = "Scorpion Pipi Duri",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://79472580279434"

	},
	["Splendid_Dottyback"] = {
		Name = "Dottyback Indah",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://137376548642195"

	},
	["Spotfin_Hogfish"] = {
		Name = " Hogfish Sirip Bercak",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://99077681211695"

	},
	["Springer_Dottyback"] = {
		Name = "Dottyback Springer",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://87084803403220"

	},
	["Squid"] = {
		Name = "Cumi-cumi",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://103601171062147"

	},
	["Star_Fish"] = {
		Name = "Bintang Laut",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://78542634760370"

	},
	["Stingray"] = {
		Name = "Pari",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://88302260465450"

	},
	["Striped_Pufferfish"] = {
		Name = "Buntal Bergaris",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://105582917971189"

	},
	["Sturgeon"] = {
		Name = "Sturgeon",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://81940180920164"

	},
	["Sun_Fish"] = {
		Name = "Matahari",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://132754400890254"

	},
	["Sword_Fish"] = {
		Name = "Pedang",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://101194708871247"

	},
	["Tautog"] = {
		Name = " Tautog",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://116672816223577"

	},
	["Tiger_Fish"] = {
		Name = "Harimau",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://140231330972331"

	},
	["Trevally"] = {
		Name = "Kuwe",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://103045042248960"

	},
	["Tuna"] = {
		Name = "Tuna",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://72039297973344"

	},
	["Watchman_Gobies"] = {
		Name = "Goby Penjaga",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://76907735673179"

	},
	["Whale"] = {
		Name = "Paus",
		Rarity = "Rare",
		Price = 0,
		ImageID = "rbxassetid://125584670090080"

	},
	["Whale_Fantasy1"] = {
		Name = "Paus Fantasi Biru",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://120611196572394"

	},
	["Whale_Fantasy2"] = {
		Name = "Paus Fantasi Pink",
		Rarity = "Legendary",
		Price = 0,
		ImageID = "rbxassetid://140415303296502"

	},
	["White_Snapper"] = {
		Name = "Kakap Putih",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://132911249591063"

	},
	["White_Spotted_Rabbit_fish"] = {
		Name = "Baronang Totol Putih",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://73065442397507"

	},
	["Yellow_Tang"] = {
		Name = "Botana Kuning",
		Rarity = "Uncommon",
		Price = 0,
		ImageID = "rbxassetid://93361906674396"

	},
	["Yellowstripe_Scad"] = {
		Name = "Selar Garis Kuning",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://87970358928959"

	},
	["Yellowtail_Fusilier"] = {
		Name = "Fusilier Ekor Kuning",
		Rarity = "Common",
		Price = 0,
		ImageID = "rbxassetid://131664926257520"

	},
	-- TAMBAHKAN FISH LAINNYA SESUAI DATA KAMU
}

-- Auto-calculate prices untuk semua ikan berdasarkan rarity
function FishConfig.AutoCalculatePrices()
	local count = 0
	for fishId, fishData in pairs(FishConfig.Fish) do
		count = count + 1
		-- Fix typo: Dugong seharusnya Legendary bukan "Dugong"
		if fishData.Rarity == "Dugong" then
			fishData.Rarity = "Legendary"
		end
		
		-- Set price based on rarity if currently 0
		if fishData.Price == 0 then
			local basePrice = FishConfig.RarityBasePrices[fishData.Rarity]
			if basePrice then
				-- Add slight variation (±20%) untuk variety
				local variation = math.random(80, 120) / 100
				fishData.Price = math.floor(basePrice * variation)
			else
				warn("⚠️ Unknown rarity for fish:", fishId, "-", fishData.Rarity)
				fishData.Price = 50 -- Default fallback
			end
		end
	end
	print("✅ Auto-calculated prices for", count, "fish types")
end

-- Function untuk get random fish berdasarkan rarity weight
function FishConfig.GetRandomFish()
	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(FishConfig.RarityWeights) do
		totalWeight = totalWeight + weight
	end

	-- Random selection
	local random = math.random(1, totalWeight)
	local currentWeight = 0
	local selectedRarity = "Common"

	for rarity, weight in pairs(FishConfig.RarityWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end

	-- Get all fish of selected rarity
	local fishPool = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then
			table.insert(fishPool, fishId)
		end
	end

	-- Return random fish from pool
	if #fishPool > 0 then
		local randomFish = fishPool[math.random(1, #fishPool)]
		return randomFish, FishConfig.Fish[randomFish]
	end

	-- Fallback ke ikan pertama
	local firstFish = next(FishConfig.Fish)
	return firstFish, FishConfig.Fish[firstFish]
end

-- Auto-calculate prices saat module di-load
FishConfig.AutoCalculatePrices()

return FishConfig
