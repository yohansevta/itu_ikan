-- loader.lua
-- ITU IKAN FISHING BOT Loader
-- Multiple loading methods with fallbacks

print("🎣 Loading ITU IKAN FISHING BOT...")

-- Check if already loaded
if _G.ITU_IKAN and _G.ITU_IKAN.loaded then
    warn("⚠️ ITU IKAN already loaded! Use _G.ITU_IKAN.cleanup() to stop and reload.")
    return
end

-- Repository base URL
local REPO_URL = "https://raw.githubusercontent.com/yohansevta/itu_ikan/main"

-- Loading methods
local function method1_Simple()
    print("🔄 Method 1: Loading simple version (most reliable)...")
    local success, result = pcall(function()
        return loadstring(game:HttpGet(REPO_URL .. "/simple.lua"))()
    end)
    
    if success then
        print("✅ Simple version loaded successfully!")
        return true
    else
        warn("❌ Simple loading failed:", result)
        return false
    end
end

local function method2_Standalone()
    print("🔄 Method 2: Loading standalone version...")
    local success, result = pcall(function()
        return loadstring(game:HttpGet(REPO_URL .. "/standalone.lua"))()
    end)
    
    if success then
        print("✅ Standalone version loaded successfully!")
        return true
    else
        warn("❌ Standalone loading failed:", result)
        return false
    end
end

local function method3_Original()
    print("🔄 Method 3: Loading original fishit.lua...")
    local success, result = pcall(function()
        return loadstring(game:HttpGet(REPO_URL .. "/fishit.lua"))()
    end)
    
    if success then
        print("✅ Original script loaded successfully!")
        return true
    else
        warn("❌ Original loading failed:", result)
        return false
    end
end

local function method4_BasicUI()
    print("🔄 Method 4: Loading basic UI version...")
    local success, result = pcall(function()
        -- Load Rayfield
        local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
        
        if not Rayfield then
            error("Failed to load Rayfield")
        end
        
        -- Create basic ITU IKAN
        local ITU_IKAN = {
            loaded = true,
            autoFishingEnabled = false
        }
        
        -- Create basic UI
        ITU_IKAN.Window = Rayfield:CreateWindow({
            Name = "🎣 ITU IKAN FISHING BOT",
            LoadingTitle = "ITU IKAN Loading...",
            LoadingSubtitle = "by YohanSevta - Emergency Fallback",
            Theme = "Ocean"
        })
        
        -- Basic tab
        local Tab = ITU_IKAN.Window:CreateTab("🎣 Emergency Mode")
        
        Tab:CreateToggle({
            Name = "Enable Auto Fishing",
            CurrentValue = false,
            Callback = function(Value)
                ITU_IKAN.autoFishingEnabled = Value
                print(Value and "🎣 Auto Fishing ON" or "🛑 Auto Fishing OFF")
            end,
        })
        
        Tab:CreateButton({
            Name = "Test Notification",
            Callback = function()
                Rayfield:Notify({
                    Title = "ITU IKAN",
                    Content = "Emergency UI is working!",
                    Duration = 3
                })
            end,
        })
        
        Tab:CreateLabel("This is emergency fallback mode.\nTry reloading for full features.")
        
        -- Store globally
        _G.ITU_IKAN = ITU_IKAN
        
        print("✅ Emergency UI version loaded!")
        return ITU_IKAN
    end)
    
    if success then
        return true
    else
        warn("❌ Emergency UI loading failed:", result)
        return false
    end
end

-- Try loading methods in order
local loadingMethods = {
    {name = "Simple Version (Most Reliable)", func = method1_Simple},
    {name = "Standalone Version", func = method2_Standalone},
    {name = "Original Script", func = method3_Original},
    {name = "Emergency UI Fallback", func = method4_BasicUI}
}

local loaded = false
for i, method in ipairs(loadingMethods) do
    print(string.format("🚀 Attempting %s (%d/%d)...", method.name, i, #loadingMethods))
    
    if method.func() then
        loaded = true
        print("🎉 Success! " .. method.name .. " loaded.")
        break
    else
        print("⚠️ " .. method.name .. " failed, trying next method...")
        wait(1)
    end
end

if loaded then
    print("\n✅ =======================================")
    print("    ITU IKAN FISHING BOT READY!")
    print("=======================================")
    print("📘 Access via: _G.ITU_IKAN")
    print("🎮 UI should be visible")
    print("🛑 Emergency stop: _G.ITU_IKAN.cleanup() or _G.ITU_IKAN_SIMPLE.stopFishing()")
    print("🔄 Reload: _G.ITU_IKAN.reload() or rerun loader")
else
    print("\n❌ =======================================")
    print("    ALL LOADING METHODS FAILED!")
    print("=======================================")
    print("🔧 Please check:")
    print("   • Internet connection")
    print("   • Game compatibility")
    print("   • Executor capabilities")
    print("💡 Try running each method manually:")
    print("   loadstring(game:HttpGet('" .. REPO_URL .. "/simple.lua'))()")
    print("   loadstring(game:HttpGet('" .. REPO_URL .. "/standalone.lua'))()")
    print("   loadstring(game:HttpGet('" .. REPO_URL .. "/fishit.lua'))()")
end
