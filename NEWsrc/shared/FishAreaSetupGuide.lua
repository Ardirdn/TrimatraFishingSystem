--[[
    FISH AREA SETUP GUIDE
    
    Cara Setup Fish Area di Workspace
    ==================================
    
    STRUKTUR YANG DIPERLUKAN:
    
    workspace/
    └── FishArea (Model)                    <- Buat Model bernama "FishArea"
        ├── VolcanoArea (Folder)            <- Folder untuk area Volcano
        │   ├── Zone1 (Part)                <- Part apapun (untuk deteksi zona)
        │   ├── Zone2 (Part)                <- Bisa banyak part
        │   └── Zone3 (Part)
        ├── IceArea (Folder)                <- Folder untuk area Ice
        │   └── Zone1 (Part)
        ├── DeepSeaArea (Folder)            <- Folder untuk area Deep Sea
        │   └── Zone1 (Part)
        └── CoralReefArea (Folder)          <- Folder untuk area Coral Reef
            └── Zone1 (Part)
    
    
    CARA MEMBUAT:
    
    1. Di Workspace, buat Model baru bernama "FishArea"
    
    2. Di dalam FishArea, buat Folder untuk setiap area:
       - VolcanoArea
       - IceArea
       - DeepSeaArea
       - CoralReefArea
       (Nama harus SAMA PERSIS dengan yang ada di FishAreaConfig.lua)
    
    3. Di dalam setiap Folder, buat Part sebagai zona deteksi:
       - Buat Part dengan size sesuai ukuran area yang diinginkan
       - Nama part BEBAS (bisa Zone1, Area, Part, dll)
       - Part akan digunakan untuk deteksi apakah floater ada di dalam area
       - Part bisa di-set ke Transparency 1 (invisible) atau 0.5 (semi-transparent)
       - Set CanCollide = false agar tidak menghalangi pemain
    
    4. Tips untuk Part zona:
       - Gunakan Part biasa (Block) untuk area kotak
       - Bisa pakai beberapa Part untuk membentuk area kompleks
       - Semua Part dalam 1 Folder dihitung sebagai 1 area yang sama
    
    
    CONTOH PROPERTIES PART:
    
    Zone1 (Part):
      - Size: Vector3.new(50, 20, 50)    -- Area 50x50 studs, tinggi 20
      - Position: sesuaikan ke lokasi
      - Transparency: 0.8                 -- Semi-transparent untuk testing
      - CanCollide: false                 -- Agar tidak menghalangi
      - Anchored: true                    -- Jangan bergerak
      - BrickColor: sesuai tema area
    
    
    AREA YANG SUDAH DIKONFIGURASI (di FishAreaConfig.lua):
    
    1. VolcanoArea - Bonus untuk ikan api (Dragon Fish, Lion Fish)
       - 3x Legendary chance
       - 2x Epic chance
    
    2. IceArea - Bonus untuk ikan arctic (Narwhal, Killer Whale)
       - 2.5x Legendary chance
       - 1.8x Epic chance
    
    3. DeepSeaArea - Bonus untuk ikan dalam (Angler Fish, Goblin Shark)
       - 5x Legendary chance! (area terbaik untuk ikan langka)
       - 3x Epic chance
    
    4. CoralReefArea - Bonus untuk ikan tropis (Clown Fish, Blue Tang)
       - 1.5x Uncommon chance
       - Bagus untuk farming ikan uncommon
    
    
    CARA KERJA:
    
    1. Saat pemain berhasil menangkap ikan (tap-tap selesai)
    2. Sistem mengecek posisi floater
    3. Jika floater ada di dalam Part zona area khusus:
       - Rarity weights dimodifikasi sesuai area
       - Ikan tertentu mendapat bonus chance
    4. Jika floater di luar semua area:
       - Menggunakan chance normal (Open Waters)
    
    
    MENAMBAH AREA BARU:
    
    1. Tambahkan konfigurasi di FishAreaConfig.lua
    2. Buat Folder baru di FishArea Model
    3. Tambahkan Part untuk zona deteksi
    
    Done!
]]

-- Script ini hanya untuk dokumentasi
-- Tidak perlu di-require atau dijalankan

return nil
