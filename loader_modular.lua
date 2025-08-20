-- loader_modular.lua
-- ITU IKAN Loader untuk Modular Version (dari fishit.lua original)
-- Loader untuk mengakses sistem modular yang sebenarnya

print("🎣 ITU IKAN MODULAR LOADER")
print("📁 Loading modular system dari fishit.lua...")

-- Function untuk mencoba load script
local function attemptLoad(name, url, description)
    print("🔄 Trying " .. name .. ": " .. description)
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success then
        print("✅ " .. name .. " loaded successfully!")
        return true, result
    else
        print("❌ " .. name .. " failed: " .. tostring(result))
        return false, result
    end
end

-- Focused modular loading - ONLY modular system
local loadingMethods = {
    {
        name = "Modular Main",
        url = "https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/main_modular.lua",
        description = "Full modular system dengan semua modules dari fishit.lua"
    }
}

-- Try to load modular system only
local loaded = false
local loadedScript = nil

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📥 Loading: Modular Main System")

local success, result = attemptLoad("Modular Main", 
    "https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/main_modular.lua",
    "Full modular system dengan semua modules dari fishit.lua")

if success then
    loaded = true
    loadedScript = result
    print("🎉 Successfully loaded: Modular System!")
else
    print("❌ Failed to load modular system")
end

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

if loaded then
    print("✅ ========================================")
    print("   ITU IKAN MODULAR LOADER SUCCESS!")
    print("========================================")
    print("🎮 Status: Script loaded and running")
    print("📁 Type: Modular system dari fishit.lua")
    print("🎣 Features: Semua fitur original + Rayfield UI")
    print("📊 Access: Check _G variables untuk control")
    print("")
    print("🚀 CARA PENGGUNAAN:")
    print("   1. Buka Rayfield UI yang muncul")
    print("   2. Enable Auto Fishing di tab pertama")
    print("   3. Pilih mode fishing (smart/secure/fast)")
    print("   4. Atur teleport location sesuai kebutuhan")
    print("   5. Enable rod fix untuk orientasi optimal")
    print("")
    print("✨ FITUR LENGKAP DARI FISHIT.LUA:")
    print("   🎣 Auto Fishing (smart/secure/fast modes)")
    print("   🤖 Auto Mode (dari fishit.lua)")
    print("   🔧 Rod Fix (charging phase monitoring)")
    print("   📍 Teleportasi (semua lokasi)")
    print("   👤 Player Mods (speed/jump/float/spinner)")
    print("   💰 Auto Sell (threshold management)")
    print("   ✨ Enchant Features (altar/roll/purchase)")
    print("   🛡️ Anti-AFK & Auto Reconnect")
    print("   📊 Statistics tracking")
    print("")
    print("🎯 Ready for fishing dengan sistem modular!")
else
    print("❌ ========================================")
    print("   ITU IKAN MODULAR LOADER FAILED!")
    print("========================================")
    print("🚨 Error: Tidak bisa load modular system")
    print("📡 Check: Koneksi internet dan GitHub access")
    print("🔄 Solution: Coba lagi dalam beberapa saat")
    print("")
    print("🆘 MANUAL LOADING MODULAR SYSTEM:")
    print("loadstring(game:HttpGet('https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/main_modular.lua'))()")
    print("")
    print("📁 Focus: ONLY MODULAR SYSTEM - No fallbacks")
    print("🎯 Reason: Dedicated modular experience only")
end

return loadedScript
