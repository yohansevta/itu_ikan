-- loader.lua
-- ITU IKAN FISHING BOT Loader
-- Optimized loader with complete version priority

print("🎣 Loading ITU IKAN FISHING BOT...")

-- Check if already loaded
if (_G.ITU_IKAN_COMPLETE and _G.ITU_IKAN_COMPLETE.loaded) or 
   (_G.ITU_IKAN_SIMPLE and _G.ITU_IKAN_SIMPLE.loaded) or
   (_G.ITU_IKAN and _G.ITU_IKAN.loaded) then
    warn("⚠️ ITU IKAN already loaded! Use cleanup() to stop and reload.")
    return
end

-- Repository base URL
local REPO_URL = "https://raw.githubusercontent.com/yohansevta/itu_ikan/main"

-- Loading methods with priority order
local loadingMethods = {
    {
        name = "Complete Version (All Features)",
        url = REPO_URL .. "/complete.lua",
        description = "Full fishing bot with all features"
    },
    {
        name = "Simple Version (Reliable)",
        url = REPO_URL .. "/simple.lua", 
        description = "Basic but stable fishing bot"
    },
    {
        name = "Original Script (Proven)",
        url = REPO_URL .. "/fishit.lua",
        description = "Original working script"
    }
}

local function attemptLoad(method)
    print("🔄 Attempting: " .. method.name)
    print("   " .. method.description)
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(method.url))()
    end)
    
    if success then
        print("✅ SUCCESS: " .. method.name .. " loaded!")
        return true
    else
        warn("❌ FAILED: " .. method.name)
        warn("   Error: " .. tostring(result))
        return false
    end
end

-- Try loading methods in order
local loaded = false
for i, method in ipairs(loadingMethods) do
    print(string.format("\n🚀 Method %d/%d: %s", i, #loadingMethods, method.name))
    
    if attemptLoad(method) then
        loaded = true
        print("\n🎉 LOADING SUCCESSFUL!")
        print("========================================")
        
        -- Check which version loaded
        if _G.ITU_IKAN_COMPLETE then
            print("📦 Version: Complete (Full Features)")
            print("📘 Access: _G.ITU_IKAN_COMPLETE")
            print("🎮 UI: Complete Rayfield interface")
            print("🎣 Features: Auto Fishing, Teleport, Player Mods, Auto Sell, Stats, Anti-AFK")
        elseif _G.ITU_IKAN_SIMPLE then
            print("📦 Version: Simple (Reliable)")
            print("📘 Access: _G.ITU_IKAN_SIMPLE")
            print("🎮 UI: Basic Rayfield interface")
            print("🎣 Features: Auto Fishing, Basic Player Mods, Anti-AFK")
        elseif _G.ITU_IKAN then
            print("📦 Version: Original Script")
            print("📘 Access: _G.ITU_IKAN")
            print("🎮 UI: Original interface")
            print("🎣 Features: All original features")
        end
        
        print("✅ Ready to fish!")
        break
    else
        print("⚠️ Trying next method...")
        wait(1)
    end
end

if not loaded then
    print("\n❌ =======================================")
    print("    ALL LOADING METHODS FAILED!")
    print("=======================================")
    print("🔧 Possible issues:")
    print("   • Internet connection problems")
    print("   • Executor compatibility issues")
    print("   • Game restrictions")
    print("")
    print("💡 Manual loading options:")
    print("   1. Complete: loadstring(game:HttpGet('" .. REPO_URL .. "/complete.lua'))()")
    print("   2. Simple:   loadstring(game:HttpGet('" .. REPO_URL .. "/simple.lua'))()")
    print("   3. Original: loadstring(game:HttpGet('" .. REPO_URL .. "/fishit.lua'))()")
    print("")
    print("🧪 Test Rayfield: loadstring(game:HttpGet('https://sirius.menu/rayfield'))()")
end

