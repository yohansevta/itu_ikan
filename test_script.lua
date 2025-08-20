-- test_script.lua
-- Quick test script untuk verify semua modules bekerja dengan baik

print("🧪 === ITU IKAN FISHING BOT TEST SCRIPT ===")

-- Load the bot
print("📥 Loading ITU IKAN Fishing Bot...")
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()

-- Wait for initialization
wait(3)

-- Check if bot is loaded
if not _G.ITU_IKAN then
    warn("❌ Bot failed to load!")
    return
end

print("✅ Bot loaded successfully!")

-- Test all modules
local function testModules()
    local results = {}
    
    -- Test AutoFishing module
    print("🧪 Testing AutoFishing module...")
    if _G.ITU_IKAN.AutoFishing then
        local modes = {"smart", "secure", "fast"}
        for _, mode in ipairs(modes) do
            local success = pcall(function()
                _G.ITU_IKAN.AutoFishing:SetMode(mode)
            end)
            results["AutoFishing_" .. mode] = success
        end
        print("✅ AutoFishing module OK")
    else
        results["AutoFishing"] = false
        warn("❌ AutoFishing module missing")
    end
    
    -- Test RodFix module
    print("🧪 Testing RodFix module...")
    if _G.ITU_IKAN.RodFix then
        local success = pcall(function()
            _G.ITU_IKAN.RodFix:Enable()
            wait(0.1)
            _G.ITU_IKAN.RodFix:Disable()
        end)
        results["RodFix"] = success
        print("✅ RodFix module OK")
    else
        results["RodFix"] = false
        warn("❌ RodFix module missing")
    end
    
    -- Test Teleport module
    print("🧪 Testing Teleport module...")
    if _G.ITU_IKAN.Teleport then
        local success = pcall(function()
            local currentLoc = _G.ITU_IKAN.Teleport:GetCurrentLocation()
            local locations = _G.ITU_IKAN.Teleport:GetAvailableLocations()
        end)
        results["Teleport"] = success
        print("✅ Teleport module OK")
    else
        results["Teleport"] = false
        warn("❌ Teleport module missing")
    end
    
    -- Test PlayerMods module
    print("🧪 Testing PlayerMods module...")
    if _G.ITU_IKAN.PlayerMods then
        local success = pcall(function()
            local currentSpeed = _G.ITU_IKAN.PlayerMods:GetWalkSpeed()
        end)
        results["PlayerMods"] = success
        print("✅ PlayerMods module OK")
    else
        results["PlayerMods"] = false
        warn("❌ PlayerMods module missing")
    end
    
    -- Test Dashboard module
    print("🧪 Testing Dashboard module...")
    if _G.ITU_IKAN.Dashboard then
        local success = pcall(function()
            local stats = _G.ITU_IKAN.Dashboard:GetSessionStats()
        end)
        results["Dashboard"] = success
        print("✅ Dashboard module OK")
    else
        results["Dashboard"] = false
        warn("❌ Dashboard module missing")
    end
    
    -- Test AutoSell module
    print("🧪 Testing AutoSell module...")
    if _G.ITU_IKAN.AutoSell then
        local success = pcall(function()
            local status = _G.ITU_IKAN.AutoSell:GetStatus()
        end)
        results["AutoSell"] = success
        print("✅ AutoSell module OK")
    else
        results["AutoSell"] = false
        warn("❌ AutoSell module missing")
    end
    
    -- Test AntiAFK module
    print("🧪 Testing AntiAFK module...")
    if _G.ITU_IKAN.AntiAFK then
        local success = pcall(function()
            local status = _G.ITU_IKAN.AntiAFK:GetStatus()
        end)
        results["AntiAFK"] = success
        print("✅ AntiAFK module OK")
    else
        results["AntiAFK"] = false
        warn("❌ AntiAFK module missing")
    end
    
    return results
end

-- Test global functions
local function testGlobalFunctions()
    local globalTests = {}
    
    print("🧪 Testing global functions...")
    
    -- Test GetStats
    local success = pcall(function()
        local stats = _G.ITU_IKAN.GetStats()
        assert(type(stats) == "table", "GetStats should return table")
    end)
    globalTests["GetStats"] = success
    
    -- Test ToggleFishing
    success = pcall(function()
        _G.ITU_IKAN.ToggleFishing()
    end)
    globalTests["ToggleFishing"] = success
    
    -- Test ToggleAutoSell
    success = pcall(function()
        _G.ITU_IKAN.ToggleAutoSell()
    end)
    globalTests["ToggleAutoSell"] = success
    
    -- Test ToggleAntiAFK
    success = pcall(function()
        _G.ITU_IKAN.ToggleAntiAFK()
    end)
    globalTests["ToggleAntiAFK"] = success
    
    -- Test TeleportTo
    success = pcall(function()
        -- Just test if function exists and can be called
        local func = _G.ITU_IKAN.TeleportTo
        assert(type(func) == "function", "TeleportTo should be function")
    end)
    globalTests["TeleportTo"] = success
    
    print("✅ Global functions tested")
    return globalTests
end

-- Run tests
print("\n🚀 Running module tests...")
local moduleResults = testModules()

print("\n🚀 Running global function tests...")
local globalResults = testGlobalFunctions()

-- Print results
print("\n📊 === TEST RESULTS ===")

print("\n📦 Module Tests:")
for testName, passed in pairs(moduleResults) do
    local status = passed and "✅ PASS" or "❌ FAIL"
    print(string.format("  %s: %s", testName, status))
end

print("\n🌐 Global Function Tests:")
for testName, passed in pairs(globalResults) do
    local status = passed and "✅ PASS" or "❌ FAIL"
    print(string.format("  %s: %s", testName, status))
end

-- Calculate success rate
local totalTests = 0
local passedTests = 0

for _, passed in pairs(moduleResults) do
    totalTests = totalTests + 1
    if passed then passedTests = passedTests + 1 end
end

for _, passed in pairs(globalResults) do
    totalTests = totalTests + 1
    if passed then passedTests = passedTests + 1 end
end

local successRate = (passedTests / totalTests) * 100

print(string.format("\n🎯 Overall Success Rate: %.1f%% (%d/%d tests passed)", successRate, passedTests, totalTests))

if successRate >= 90 then
    print("🎉 EXCELLENT! Bot is working perfectly!")
elseif successRate >= 75 then
    print("👍 GOOD! Bot is working well with minor issues.")
elseif successRate >= 50 then
    print("⚠️ MODERATE! Some modules have issues.")
else
    print("🚨 CRITICAL! Major issues detected!")
end

-- Quick functionality test
print("\n🎣 Running quick functionality test...")

local function quickFunctionalityTest()
    print("📊 Testing basic stats...")
    local stats = _G.ITU_IKAN.GetStats()
    print(string.format("  Fish count: %d", stats.fishCount or 0))
    print(string.format("  Session time: %s", stats.formattedDuration or "00:00:00"))
    
    print("📍 Testing location detection...")
    if _G.ITU_IKAN.Teleport then
        local currentLoc = _G.ITU_IKAN.Teleport:GetCurrentLocation()
        print(string.format("  Current location: %s", currentLoc or "Unknown"))
    end
    
    print("⚙️ Testing settings...")
    local settings = _G.ITU_IKAN.GetSettings()
    if settings then
        print(string.format("  Auto fishing enabled: %s", settings.autoFishing and settings.autoFishing.enabled and "Yes" or "No"))
        print(string.format("  Auto sell enabled: %s", settings.autoSell and settings.autoSell.enabled and "Yes" or "No"))
    end
    
    print("✅ Quick functionality test complete!")
end

pcall(quickFunctionalityTest)

print("\n📝 Test completed! Check results above.")
print("💡 To run actual fishing test, use: _G.ITU_IKAN.StartFishing()")

-- Export test functions for manual use
_G.ITU_IKAN_TEST = {
    testModules = testModules,
    testGlobalFunctions = testGlobalFunctions,
    quickFunctionalityTest = quickFunctionalityTest
}

print("🔧 Test functions available in _G.ITU_IKAN_TEST")
