--[[
	PROTECTION SYSTEM SETUP - PENTING!
	
	Untuk mengaktifkan proteksi pada fishing system:
	
	1. Buka ReplicatedStorage > FishingRods > Floaters (folder)
	
	2. Di Properties panel, scroll ke bawah ke bagian "Attributes"
	
	3. Klik tombol "+" untuk menambah attribute baru
	
	4. Buat attribute dengan:
	   - Name: String
	   - Type: String
	   - Value: VHJpbWF0cmFTdHVkaW8=
	   
	   (Ini adalah "TrimatraStudio" dalam Base64)
	
	5. Save dan publish game
	
	CARA KERJA:
	- Script akan membaca attribute "String" dari folder Floaters
	- Decode nilai Base64 tersebut
	- Bandingkan dengan nama Creator dari MarketplaceService
	- Jika tidak cocok, semua fungsi fishing akan diam-diam tidak bekerja
	- Tidak ada error atau warning yang muncul
	
	JIKA INGIN MENGGANTI NAMA STUDIO:
	- Encode nama studio baru ke Base64
	- Ganti nilai attribute "String" dengan hasil encode
	
	Untuk encode, gunakan tool online atau script ini:
	
	local function encodeBase64(str)
		local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		local result = ""
		local bytes = {str:byte(1, #str)}
		
		for i = 1, #bytes, 3 do
			local b1 = bytes[i] or 0
			local b2 = bytes[i + 1] or 0
			local b3 = bytes[i + 2] or 0
			
			local n = b1 * 65536 + b2 * 256 + b3
			
			local c1 = math.floor(n / 262144) % 64
			local c2 = math.floor(n / 4096) % 64
			local c3 = math.floor(n / 64) % 64
			local c4 = n % 64
			
			result = result .. b64:sub(c1 + 1, c1 + 1)
			result = result .. b64:sub(c2 + 1, c2 + 1)
			if i + 1 <= #bytes then result = result .. b64:sub(c3 + 1, c3 + 1) else result = result .. "=" end
			if i + 2 <= #bytes then result = result .. b64:sub(c4 + 1, c4 + 1) else result = result .. "=" end
		end
		
		return result
	end
	
	print(encodeBase64("TrimatraStudio")) -- Output: VHJpbWF0cmFTdHVkaW8=
	
	CATATAN KEAMANAN:
	- Jangan simpan file ini di dalam game yang dipublish
	- Hapus file ini setelah setup selesai
	- File ini hanya untuk dokumentasi internal
]]

-- Note: File ini bukan ModuleScript yang bisa di-require
-- Ini hanya dokumentasi untuk setup proteksi

return nil
