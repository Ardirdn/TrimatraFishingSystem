--[[
    EVENT CONFIG
    Place in ReplicatedStorage/EventConfig
]]

local EventConfig = {}

-- Available Events (mudah ditambah di masa depan)
EventConfig.AvailableEvents = {
	{
		Id = "SummitX3",
		Name = "Summit x3 Event",
		Description = "Triple summit value!",
		Multiplier = 3,
		Icon = "⚡",
		Color = Color3.fromRGB(255, 215, 0)
	},
	{
		Id = "SummitX5",
		Name = "Summit x5 Event",
		Description = "5x summit value!",
		Multiplier = 5,
		Icon = "🔥",
		Color = Color3.fromRGB(255, 100, 50)
	},
	{
		Id = "SummitX10",
		Name = "Summit x10 Mega Event",
		Description = "10x summit value!",
		Multiplier = 10,
		Icon = "💎",
		Color = Color3.fromRGB(138, 43, 226)
	},
}

return EventConfig
