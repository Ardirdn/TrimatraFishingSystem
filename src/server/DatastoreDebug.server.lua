local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerFishingData_v1")

-- Command untuk check data player
Players.PlayerAdded:Connect(function(player)
	-- Check jika player adalah kamu (ganti dengan username kamu)
	if player.Name == "YourUsername" then -- GANTI INI
		task.wait(2)

		print("========================================")
		print("🔍 DEBUG DATA FOR:", player.Name)
		print("========================================")

		local success, data = pcall(function()
			return PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			print("💾 DataStore Contents:")
			print("   Money:", data.Money)
			print("   Owned Rods:")
			for rodName, owned in pairs(data.OwnedRods or {}) do
				print("      -", rodName, ":", owned)
			end
			print("   Inventory Items:", data.Inventory and #vim.tbl_keys(data.Inventory) or 0)
			print("   Discovered Fish:", data.DiscoveredFish and #vim.tbl_keys(data.DiscoveredFish) or 0)
		else
			warn("❌ Failed to load data:", data)
		end

		print("========================================")
	end
end)
