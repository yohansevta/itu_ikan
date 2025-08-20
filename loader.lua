-- loader.lua
-- ITU IKAN FISHING BOT Loader
-- Simple loader script untuk load main bot

local function loadItuIkan()
    print("🎣 Loading ITU IKAN FISHING BOT...")
    
    -- Check if already loaded
    if _G.ITU_IKAN and _G.ITU_IKAN.instance then
        warn("⚠️ ITU IKAN already loaded! Use _G.ITU_IKAN.EmergencyStop() to stop and reload.")
        return
    end
    
    -- Load main script
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/main.lua"))()
    end)
    
    if success then
        print("✅ ITU IKAN loaded successfully!")
        print("📘 Use _G.ITU_IKAN for API access")
        print("🎮 UI should appear shortly...")
    else
        warn("❌ Failed to load ITU IKAN:", result)
        print("💡 Try again or check your internet connection")
    end
end

-- Execute loader
loadItuIkan()
