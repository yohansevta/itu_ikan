-- example_usage.lua
-- Contoh penggunaan ITU IKAN FISHING BOT

-- ===== BASIC USAGE =====

-- Load the bot
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()

-- Wait for bot to load
wait(5)

-- ===== QUICK START EXAMPLE =====

-- Start auto fishing
_G.ITU_IKAN.StartFishing()

-- Change fishing mode
_G.ITU_IKAN.AutoFishing:SetMode("smart") -- or "secure" or "fast"

-- Teleport to good fishing spot
_G.ITU_IKAN.TeleportTo("🏝️ Kohana Volcano")

-- Enable auto sell
_G.ITU_IKAN.ToggleAutoSell()

-- ===== ADVANCED USAGE EXAMPLES =====

-- Custom fishing setup
local function setupCustomFishing()
    -- Enable rod fix for better performance
    _G.ITU_IKAN.RodFix:Enable()
    
    -- Configure auto fishing
    _G.ITU_IKAN.AutoFishing:UpdateSettings({
        mode = "smart",
        autoRecastDelay = 0.3,
        safeModeChance = 90
    })
    
    -- Configure auto sell
    _G.ITU_IKAN.AutoSell:UpdateSettings({
        enabled = true,
        threshold = 75,
        sellCommon = true,
        sellUncommon = true,
        sellRare = false, -- Keep rare fish
        autoReturn = true
    })
    
    -- Start fishing
    _G.ITU_IKAN.StartFishing()
    
    print("🎣 Custom fishing setup complete!")
end

-- Player enhancement setup
local function setupPlayerEnhancements()
    -- Set custom speed
    _G.ITU_IKAN.PlayerMods:SetWalkSpeed(50)
    _G.ITU_IKAN.PlayerMods:SetJumpPower(100)
    
    -- Enable float for better mobility
    _G.ITU_IKAN.PlayerMods:EnableFloat()
    _G.ITU_IKAN.PlayerMods:SetFloatHeight(20)
    
    -- Enable auto spinner for random direction
    _G.ITU_IKAN.PlayerMods:EnableSpinner()
    _G.ITU_IKAN.PlayerMods:SetSpinnerSpeed(3)
    
    print("🚀 Player enhancements enabled!")
end

-- Statistics monitoring
local function monitorStats()
    while true do
        local stats = _G.ITU_IKAN.GetStats()
        
        print(string.format(
            "📊 Stats: %d fish caught, %d rare fish, %.1f fish/hour",
            stats.fishCount,
            stats.rareCount,
            stats.fishPerHour
        ))
        
        -- Check if we should move to better location
        local locationStats = _G.ITU_IKAN.Dashboard:GetLocationStats()
        if #locationStats > 0 then
            local bestLocation = locationStats[1]
            print("🏆 Best location:", bestLocation.location, "with", bestLocation.efficiency .. "% rare rate")
        end
        
        wait(60) -- Update every minute
    end
end

-- Auto location switching based on time
local function smartLocationSwitching()
    local lastHour = -1
    
    while true do
        local currentHour = tonumber(os.date("%H"))
        
        if currentHour ~= lastHour then
            lastHour = currentHour
            
            -- Get best fishing spot for current time
            local success = _G.ITU_IKAN.Teleport:TeleportToBestFishingSpot(currentHour)
            
            if success then
                print("🕐 Switched to optimal location for hour", currentHour)
            end
        end
        
        wait(300) -- Check every 5 minutes
    end
end

-- ===== AUTOMATION SCRIPTS =====

-- Complete automation setup
local function setupFullAutomation()
    print("🤖 Setting up full automation...")
    
    -- Setup fishing
    setupCustomFishing()
    
    -- Setup player enhancements
    setupPlayerEnhancements()
    
    -- Enable anti-AFK
    _G.ITU_IKAN.ToggleAntiAFK()
    
    -- Start monitoring
    spawn(monitorStats)
    spawn(smartLocationSwitching)
    
    print("✅ Full automation active!")
end

-- Safe fishing mode (for when you want to be extra careful)
local function safeFishingMode()
    print("🛡️ Activating safe fishing mode...")
    
    -- Use secure mode
    _G.ITU_IKAN.AutoFishing:SetMode("secure")
    
    -- Conservative settings
    _G.ITU_IKAN.AutoFishing:UpdateSettings({
        autoRecastDelay = 1.0,
        safeModeChance = 95,
        maxActionsPerMinute = 60
    })
    
    -- Only sell common fish
    _G.ITU_IKAN.AutoSell:UpdateSettings({
        sellCommon = true,
        sellUncommon = false,
        sellRare = false,
        sellLegendary = false,
        sellMythical = false,
        threshold = 100
    })
    
    _G.ITU_IKAN.StartFishing()
    print("🛡️ Safe mode activated!")
end

-- Grinding mode (for maximum fish/hour)
local function grindingMode()
    print("⚡ Activating grinding mode...")
    
    -- Use fast mode
    _G.ITU_IKAN.AutoFishing:SetMode("fast")
    
    -- Aggressive settings
    _G.ITU_IKAN.AutoFishing:UpdateSettings({
        autoRecastDelay = 0.15,
        safeModeChance = 80,
        maxActionsPerMinute = 200
    })
    
    -- Sell everything except legendary/mythical
    _G.ITU_IKAN.AutoSell:UpdateSettings({
        sellCommon = true,
        sellUncommon = true,
        sellRare = true,
        sellLegendary = false,
        sellMythical = false,
        threshold = 30
    })
    
    _G.ITU_IKAN.StartFishing()
    print("⚡ Grinding mode activated!")
end

-- ===== UTILITY FUNCTIONS =====

-- Quick teleport menu
local function quickTeleportMenu()
    local locations = {
        "🏝️ Kohana",
        "🏝️ Kohana Volcano", 
        "🏝️ Stingray Shores",
        "🏝️ Esoteric Depths",
        "🏝️ Coral Reefs",
        "🏝️ Tropical Grove"
    }
    
    print("📍 Quick Teleport Locations:")
    for i, location in pairs(locations) do
        print(i .. ". " .. location)
    end
    
    print("Usage: _G.ITU_IKAN.TeleportTo('" .. locations[1] .. "')")
end

-- Status report
local function statusReport()
    print("📊 === ITU IKAN STATUS REPORT ===")
    
    -- Auto Fishing Status
    local fishingStatus = _G.ITU_IKAN.AutoFishing:GetStatus()
    print("🎣 Auto Fishing:", fishingStatus.enabled and "ON" or "OFF", "| Mode:", fishingStatus.mode)
    
    -- Auto Sell Status
    local sellStatus = _G.ITU_IKAN.AutoSell:GetStatus()
    print("💰 Auto Sell:", sellStatus.enabled and "ON" or "OFF", "| Threshold:", sellStatus.threshold)
    
    -- Statistics
    local stats = _G.ITU_IKAN.GetStats()
    print("📈 Fish Caught:", stats.fishCount, "| Rare:", stats.rareCount)
    print("⏱️ Session Time:", stats.formattedDuration)
    print("🎯 Fish/Hour:", string.format("%.1f", stats.fishPerHour))
    
    -- Current Location
    local currentLocation = _G.ITU_IKAN.Teleport:GetCurrentLocation()
    print("📍 Current Location:", currentLocation)
    
    print("=== END REPORT ===")
end

-- Emergency functions
local function emergencyStop()
    print("🚨 EMERGENCY STOP ACTIVATED!")
    _G.ITU_IKAN.EmergencyStop()
end

-- ===== EXPORTED FUNCTIONS =====

-- Export functions to global scope for easy access
_G.ITU_IKAN_EXAMPLES = {
    setupCustomFishing = setupCustomFishing,
    setupPlayerEnhancements = setupPlayerEnhancements,
    setupFullAutomation = setupFullAutomation,
    safeFishingMode = safeFishingMode,
    grindingMode = grindingMode,
    quickTeleportMenu = quickTeleportMenu,
    statusReport = statusReport,
    emergencyStop = emergencyStop
}

print("📘 Example functions loaded! Use _G.ITU_IKAN_EXAMPLES to access them.")
print("💡 Try: _G.ITU_IKAN_EXAMPLES.statusReport()")

-- ===== USAGE EXAMPLES =====

--[[

EXAMPLES OF HOW TO USE:

1. Basic Setup:
   _G.ITU_IKAN_EXAMPLES.setupCustomFishing()

2. Full Automation:
   _G.ITU_IKAN_EXAMPLES.setupFullAutomation()

3. Safe Mode:
   _G.ITU_IKAN_EXAMPLES.safeFishingMode()

4. Grinding Mode:
   _G.ITU_IKAN_EXAMPLES.grindingMode()

5. Check Status:
   _G.ITU_IKAN_EXAMPLES.statusReport()

6. Quick Teleport:
   _G.ITU_IKAN_EXAMPLES.quickTeleportMenu()

7. Emergency Stop:
   _G.ITU_IKAN_EXAMPLES.emergencyStop()

8. Manual Control Examples:
   
   -- Start/Stop fishing
   _G.ITU_IKAN.StartFishing()
   _G.ITU_IKAN.StopFishing()
   
   -- Change settings
   _G.ITU_IKAN.AutoFishing:SetMode("fast")
   _G.ITU_IKAN.AutoSell:SetThreshold(50)
   
   -- Teleport
   _G.ITU_IKAN.TeleportTo("🏝️ Kohana Volcano")
   
   -- Player mods
   _G.ITU_IKAN.PlayerMods:SetWalkSpeed(100)
   _G.ITU_IKAN.PlayerMods:EnableFloat()
   
   -- Get statistics
   local stats = _G.ITU_IKAN.GetStats()
   print("Fish caught:", stats.fishCount)

]]--
