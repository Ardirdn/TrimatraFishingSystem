--[[
    DANCE CONFIG
    Letakkan di ReplicatedStorage
]]

local DanceConfig = {}

-- List animasi dance dengan ID dari Roblox
DanceConfig.Animations = {
	-- Kategori: Random / Special (Berdasarkan prefix '💀-')
	{
		Title = "Sturdy Ice Emote",
		AnimationId = "rbxassetid://94645570070319",
		Category = "Dance"
	},
	{
		Title = "Belly Dance V3",
		AnimationId = "rbxassetid://76469748300919",
		Category = "Dance"
	},
	{
		Title = "Belly Dance V2",
		AnimationId = "rbxassetid://127937972794586",
		Category = "Dance"
	},
	{
		Title = "Ride It",
		AnimationId = "rbxassetid://112574745144411",
		Category = "Dance"
	},
	{
		Title = "Festive Dance",
		AnimationId = "rbxassetid://81673529947974",
		Category = "Dance"
	},
	{
		Title = "Greedy",
		AnimationId = "rbxassetid://106420554842766",
		Category = "Dance"
	},
	{
		Title = "Vibes",
		AnimationId = "rbxassetid://118321857676881",
		Category = "Dance"
	},
	{
		Title = "congocongo",
		AnimationId = "rbxassetid://124862537051710",
		Category = "Dance"
	},
	{
		Title = "Love Stick",
		AnimationId = "rbxassetid://129282148330907",
		Category = "Dance"
	},
	{
		Title = "Quick Step",
		AnimationId = "rbxassetid://139677857323311",
		Category = "Dance"
	},
	{
		Title = "Shimmy",
		AnimationId = "rbxassetid://120794284590574",
		Category = "Dance"
	},
	{
		Title = "Snoop",
		AnimationId = "rbxassetid://93087629495763",
		Category = "Dance"
	},
	{
		Title = "Stepback",
		AnimationId = "rbxassetid://103254619562184",
		Category = "Dance"
	},
	{
		Title = "Berdiri 1",
		AnimationId = "rbxassetid://91990676588972",
		Category = "Pose"
	},
	{
		Title = "Berdiri 2",
		AnimationId = "rbxassetid://82780478844164",
		Category = "Pose"
	},
	{
		Title = "Berdiri 3",
		AnimationId = "rbxassetid://89599183668718",
		Category = "Pose"
	},
	{
		Title = "Berdiri 4",
		AnimationId = "rbxassetid://139572521673144",
		Category = "Pose"
	},
	{
		Title = "Berdiri 5",
		AnimationId = "rbxassetid://89022208692007",
		Category = "Pose"
	},
	{
		Title = "Berdiri 6",
		AnimationId = "rbxassetid://91568569006725",
		Category = "Pose"
	},
	{
		Title = "Berdiri 7",
		AnimationId = "rbxassetid://100436598732828",
		Category = "Pose"
	},
	{
		Title = "Berdiri 8",
		AnimationId = "rbxassetid://91838294196252",
		Category = "Pose"
	},
	{
		Title = "Tidur 1",
		AnimationId = "rbxassetid://123669155597634",
		Category = "Pose"
	},
	{
		Title = "Tidur 2",
		AnimationId = "rbxassetid://74172066376471",
		Category = "Pose"
	},
	{
		Title = "Tidur 3",
		AnimationId = "rbxassetid://108148229644145",
		Category = "Pose"
	},
	{
		Title = "Kuda Kuda",
		AnimationId = "rbxassetid://108446592146110",
		Category = "Pose"
	},
	{
		Title = "Duduk 1",
		AnimationId = "rbxassetid://98918734469197",
		Category = "Pose"
	},
	{
		Title = "Duduk 2",
		AnimationId = "rbxassetid://125290564543511",
		Category = "Pose"
	},
	{
		Title = "Duduk 3",
		AnimationId = "rbxassetid://105991020943850",
		Category = "Pose"
	},
	{
		Title = "Lompat 1",
		AnimationId = "rbxassetid://100141238829993",
		Category = "Pose"
	},
	{
		Title = "Lompat 2",
		AnimationId = "rbxassetid://139103694394433",
		Category = "Pose"
	},
	{
		Title = "Lompat 3",
		AnimationId = "rbxassetid://125581531972259",
		Category = "Pose"
	},
	{
		Title = "Lompat 4",
		AnimationId = "rbxassetid://119739790036438",
		Category = "Pose"
	},
	{
		Title = "Lompat 5",
		AnimationId = "rbxassetid://98634930082012",
		Category = "Pose"
	},
	{
		Title = "Pasangan 1 Kiri",
		AnimationId = "rbxassetid://86534186335033",
		Category = "Pose"
	},
	{
		Title = "Pasangan 2 Kiri",
		AnimationId = "rbxassetid://76020597666848",
		Category = "Pose"
	},
	{
		Title = "Pasangan 3 Kiri",
		AnimationId = "rbxassetid://136547261876811",
		Category = "Pose"
	},
	{
		Title = "Pasangan 4 Kiri",
		AnimationId = "rbxassetid://137296749355135",
		Category = "Pose"
	},
	{
		Title = "Pasangan 5 Kiri",
		AnimationId = "rbxassetid://106556831481648",
		Category = "Pose"
	},
	{
		Title = "Pasangan 6 Kiri",
		AnimationId = "rbxassetid://90087090610541",
		Category = "Pose"
	},
	{
		Title = "Pasangan 7 Kiri",
		AnimationId = "rbxassetid://107550226399132",
		Category = "Pose"
	},
	{
		Title = "Pasangan 8 Kiri",
		AnimationId = "rbxassetid://84080237523032",
		Category = "Pose"
	},
	{
		Title = "Pasangan 1 Kanan",
		AnimationId = "rbxassetid://111871760147996",
		Category = "Pose"
	},
	{
		Title = "Pasangan 2 Kanan",
		AnimationId = "rbxassetid://84742360023926",
		Category = "Pose"
	},
	{
		Title = "Pasangan 3 Kanan",
		AnimationId = "rbxassetid://82532062490765",
		Category = "Pose"
	},
	{
		Title = "Pasangan 4 Kanan",
		AnimationId = "rbxassetid://114418189634886",
		Category = "Pose"
	},
	{
		Title = "Pasangan 5 Kanan",
		AnimationId = "rbxassetid://129626202388963",
		Category = "Pose"
	},
	{
		Title = "Pasangan 6 Kanan",
		AnimationId = "rbxassetid://137275046023158",
		Category = "Pose"
	},
	{
		Title = "Pasangan 7 Kanan",
		AnimationId = "rbxassetid://117172007809394",
		Category = "Pose"
	},
	{
		Title = "Pasangan 8 Kanan",
		AnimationId = "rbxassetid://97031364148200",
		Category = "Pose"
	},
	---- Kategori: Pose / Emote (Semua yang memiliki Category = "Emote" di config asli)
	--{
	--	Title = "Salute",
	--	AnimationId = "rbxassetid://92109492488561",
	--	Category = "Pose / Emote"
	--},
	--{
	--	Title = "Stance1",
	--	AnimationId = "rbxassetid://86241476099446",
	--	Category = "Pose / Emote"
	--},
	--{
	--	Title = "Stance2",
	--	AnimationId = "rbxassetid://131789866699144",
	--	Category = "Pose / Emote"
	--},
	--{
	--	Title = "Stance3",
	--	AnimationId = "rbxassetid://99541980916506",
	--	Category = "Pose / Emote"
	--},
	--{
	--	Title = "Stance4",
	--	AnimationId = "rbxassetid://105042771831542",
	--	Category = "Pose / Emote"
	--},
	--{
	--	Title = "Stance5",
	--	AnimationId = "rbxassetid://109853326508333",
	--	Category = "Pose / Emote"
	--},
	
}

return DanceConfig