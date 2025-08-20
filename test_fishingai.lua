-- test_fishingai.lua
-- Simple test script for FishingAI module only

print("🧪 Testing FishingAI Module...")

-- Load Rayfield UI Framework
local Rayfield
local success, error_msg = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/yohansevta/itu_ikan/refs/heads/main/framework/rayfield.lua'))()
end)

if not success then
    warn("Failed to load Rayfield UI Framework:", error_msg)
    return
end

-- Load FishingAI Module
local FishingAI
local success, error_msg = pcall(function()
    FishingAI = loadstring(game:HttpGet('https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/modules/FishingAI.lua'))()
end)

if not success then
    warn("Failed to load FishingAI Module:", error_msg)
    return
end

-- Simple notification function
local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 4
    })
    print("[TEST]", title, "-", text)
end

-- Mock remotes for testing
local mockRemotes = {
    rod = nil,
    miniGame = nil,
    finish = nil,
    equip = nil,
    fishCaught = nil,
    autoFishState = nil,
    unequip = nil,
    unequipItem = nil
}

-- Mock config for testing
local testConfig = {
    enabled = false,
    mode = "smart",
    autoRecastDelay = 0.4,
    safeModeChance = 70,
    autoModeEnabled = false,
    secure_max_actions_per_minute = 12000000,
    secure_detection_cooldown = 5
}

-- Initialize FishingAI
FishingAI.init(testConfig, mockRemotes, Notify)

-- Create simple test UI
local Window = Rayfield:CreateWindow({
    Name = "🧪 FishingAI Test",
    LoadingTitle = "Testing FishingAI...",
    LoadingSubtitle = "by yohansevta",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local Tab = Window:CreateTab("🎣 FishingAI Test", nil)

local Section = Tab:CreateSection("Test Controls")

-- Test toggle
local TestToggle = Tab:CreateToggle({
    Name = "🤖 Test Auto Fishing",
    CurrentValue = false,
    Callback = function(Value)
        testConfig.enabled = Value
        if Value then
            FishingAI.start()
            Notify("🎣 Test", "FishingAI Started!")
        else
            FishingAI.stop()
            Notify("🎣 Test", "FishingAI Stopped!")
        end
    end,
})

-- Test Auto Mode
local AutoModeToggle = Tab:CreateToggle({
    Name = "🔥 Test Auto Mode",
    CurrentValue = false,
    Callback = function(Value)
        testConfig.autoModeEnabled = Value
        if Value then
            FishingAI.startAutoMode()
            Notify("🔥 Test", "Auto Mode Started!")
        else
            FishingAI.stopAutoMode()
            Notify("🔥 Test", "Auto Mode Stopped!")
        end
    end,
})

-- Test rod fix
local FixRodButton = Tab:CreateButton({
    Name = "🔧 Test Rod Fix",
    Callback = function()
        FishingAI.fixRodOrientation()
        Notify("🔧 Test", "Rod fix executed!")
    end,
})

-- Test unequip
local UnequipButton = Tab:CreateButton({
    Name = "📤 Test Unequip",
    Callback = function()
        local success = FishingAI.unequipRod()
        if success then
            Notify("📤 Test", "Unequip successful!")
        else
            Notify("📤 Test", "No rod to unequip")
        end
    end,
})

-- Get stats
local StatsButton = Tab:CreateButton({
    Name = "📊 Get Stats",
    Callback = function()
        local stats = FishingAI.getStats()
        print("🧪 FishingAI Stats:")
        print("   - State:", stats.currentState)
        print("   - Running:", stats.isRunning)
        print("   - Auto Mode:", stats.autoModeRunning)
        print("   - Location:", stats.currentLocation)
        print("   - Security Status:", stats.securityStatus.isInCooldown and "Cooldown" or "Active")
        
        Notify("📊 Stats", "Check console for details")
    end,
})

-- Cleanup button
local CleanupButton = Tab:CreateButton({
    Name = "🧹 Cleanup",
    Callback = function()
        FishingAI.cleanup()
        Notify("🧹 Test", "Cleanup completed!")
    end,
})

-- Status section
local StatusSection = Tab:CreateSection("Status")
local StatusLabel = Tab:CreateLabel("Status: Ready for testing")

-- Update status
local function UpdateStatus()
    if FishingAI then
        local stats = FishingAI.getStats()
        StatusLabel:Set("Status: " .. (stats.isRunning and "🟢 Running" or "🔴 Stopped") .. 
                       " | State: " .. stats.currentState .. 
                       " | Location: " .. stats.currentLocation)
    end
end

-- Status update loop
task.spawn(function()
    while true do
        UpdateStatus()
        task.wait(1)
    end
end)

Notify("🧪 Test Ready", "FishingAI module loaded and ready for testing!")
print("🧪 FishingAI Test: Ready!")
print("   - Module: ✅ Loaded")
print("   - UI: ✅ Created")
print("   - Status: ✅ Ready for testing")
