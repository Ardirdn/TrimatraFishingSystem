-- AdminConfig
-- Letakkan di ReplicatedStorage

local AdminConfig = {}

-- Daftar User ID admin
AdminConfig.Admins = {
	8714136305, -- Ganti dengan User ID kamu
	987654321, -- Tambahkan admin lain di sini
}

-- Fungsi untuk cek apakah player adalah admin
function AdminConfig:IsAdmin(player)
	for _, adminId in pairs(self.Admins) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

-- Daftar banned users (bisa dikembangkan dengan DataStore)
AdminConfig.BannedUsers = {}

function AdminConfig:IsBanned(userId)
	return table.find(self.BannedUsers, userId) ~= nil
end

function AdminConfig:BanUser(userId)
	if not self:IsBanned(userId) then
		table.insert(self.BannedUsers, userId)
		return true
	end
	return false
end

function AdminConfig:UnbanUser(userId)
	local index = table.find(self.BannedUsers, userId)
	if index then
		table.remove(self.BannedUsers, index)
		return true
	end
	return false
end

return AdminConfig