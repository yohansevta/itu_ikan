-- simple.lua
-- ITU IKAN FISHING BOT - Simple & Reliable Version
-- Minimal script dengan UI yang pasti jalan

print("🎣 ITU IKAN FISHING BOT - Simple Version Loading...")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Check if already loaded
if _G.ITU_IKAN_SIMPLE then
    warn("⚠️ ITU IKAN Simple already loaded!")
    return
end

-- Load Rayfield UI
print("🔄 Loading Rayfield UI...")
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    error("❌ Failed to load Rayfield UI. Check internet connection.")
end

print("✅ Rayfield loaded successfully!")

-- Simple ITU IKAN
local ITU_IKAN = {
    loaded = true,
    autoFishing = false,
    antiAFK = false,
    playerMods = false,
    
    -- Stats
    fishCount = 0,
    startTime = tick(),
    
    -- Settings
    walkSpeed = 16,
    jumpPower = 50,
    floatHeight = 20,
    fishingMode = "smart"
}

-- Utility Functions
local function safeWrap(func)
    return function(...)
        local success, result = pcall(func, ...)
        if not success then
            warn("ITU IKAN Error:", result)
        end
        return success, result
    end
end

local function notify(title, content)
    if Rayfield then
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 3,
            Image = 4483362458
        })
    end
    print("🔔 " .. title .. ": " .. content)
end

-- Auto Fishing Functions
local function startAutoFishing()
    ITU_IKAN.autoFishing = true
    notify("Auto Fishing", "Started!")
    
    -- Simple fishing loop
    spawn(function()
        while ITU_IKAN.autoFishing do
            safeWrap(function()
                local character = LocalPlayer.Character
                if character then
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool then
                        -- Basic fishing logic would go here
                        -- For now, just increment counter for demo
                        wait(5)
                        ITU_IKAN.fishCount = ITU_IKAN.fishCount + 1
                    end
                end
            end)()
            wait(1)
        end
    end)
end

local function stopAutoFishing()
    ITU_IKAN.autoFishing = false
    notify("Auto Fishing", "Stopped!")
end

-- Player Mod Functions
local function setWalkSpeed(speed)
    safeWrap(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speed
                ITU_IKAN.walkSpeed = speed
                notify("Player Mods", "Speed set to " .. speed)
            end
        end
    end)()
end

local function setJumpPower(power)
    safeWrap(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpPower = power
                ITU_IKAN.jumpPower = power
                notify("Player Mods", "Jump set to " .. power)
            end
        end
    end)()
end

-- Anti-AFK Functions
local function startAntiAFK()
    ITU_IKAN.antiAFK = true
    notify("Anti-AFK", "Started!")
    
    spawn(function()
        while ITU_IKAN.antiAFK do
            wait(30 + math.random(1, 30)) -- Random 30-60 seconds
            
            safeWrap(function()
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        -- Small random movement
                        humanoid:Move(Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)))
                        wait(0.1)
                        humanoid:Move(Vector3.new(0, 0, 0))
                    end
                end
            end)()
        end
    end)
end

local function stopAntiAFK()
    ITU_IKAN.antiAFK = false
    notify("Anti-AFK", "Stopped!")
end

-- Create UI
print("🎮 Creating UI...")

local Window = Rayfield:CreateWindow({
    Name = "🎣 ITU IKAN SIMPLE v2.0",
    LoadingTitle = "ITU IKAN Loading...",
    LoadingSubtitle = "by YohanSevta - Simple & Reliable",
    Theme = "Ocean",
    DisableRayfieldPrompts = false,
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("🎣 Main", 4483362458)

local MainSection = MainTab:CreateSection("Fishing Controls")

local FishingToggle = MainTab:CreateToggle({
    Name = "🎣 Auto Fishing",
    CurrentValue = false,
    Flag = "AutoFishing",
    Callback = function(Value)
        if Value then
            startAutoFishing()
        else
            stopAutoFishing()
        end
    end,
})

local ModeDropdown = MainTab:CreateDropdown({
    Name = "Fishing Mode",
    Options = {"Smart", "Secure", "Fast"},
    CurrentOption = "Smart",
    Flag = "FishingMode",
    Callback = function(Value)
        ITU_IKAN.fishingMode = Value:lower()
        notify("Settings", "Mode: " .. Value)
    end,
})

-- Player Tab  
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

local PlayerSection = PlayerTab:CreateSection("Movement")

local SpeedSlider = PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        setWalkSpeed(Value)
    end,
})

local JumpSlider = PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300}, 
    Increment = 5,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        setJumpPower(Value)
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

local SettingsSection = SettingsTab:CreateSection("Bot Settings")

local AntiAFKToggle = SettingsTab:CreateToggle({
    Name = "🛡️ Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        if Value then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end,
})

-- Stats Tab
local StatsTab = Window:CreateTab("📊 Stats", 4483362458)

local StatsSection = StatsTab:CreateSection("Statistics")

local StatsLabel = StatsTab:CreateLabel("Loading stats...")

-- Update stats
spawn(function()
    while ITU_IKAN.loaded do
        wait(5)
        local sessionTime = tick() - ITU_IKAN.startTime
        local hours = math.floor(sessionTime / 3600)
        local minutes = math.floor((sessionTime % 3600) / 60)
        local seconds = math.floor(sessionTime % 60)
        local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        
        local fishPerHour = ITU_IKAN.fishCount > 0 and (ITU_IKAN.fishCount / (sessionTime / 3600)) or 0
        
        if StatsLabel then
            StatsLabel:Set(string.format(
                "🎣 Fish: %d\n⏱️ Time: %s\n📈 Fish/Hour: %.1f\n🎮 Status: %s",
                ITU_IKAN.fishCount,
                timeStr,
                fishPerHour,
                ITU_IKAN.autoFishing and "Fishing" or "Idle"
            ))
        end
    end
end)

-- Test Button
local TestButton = SettingsTab:CreateButton({
    Name = "🧪 Test Notification",
    Callback = function()
        notify("Test", "ITU IKAN is working perfectly! 🎣")
    end,
})

-- Stop Button
local StopButton = SettingsTab:CreateButton({
    Name = "🛑 Stop All",
    Callback = function()
        ITU_IKAN.autoFishing = false
        ITU_IKAN.antiAFK = false
        notify("Stop", "All systems stopped!")
    end,
})

-- Store globally
_G.ITU_IKAN_SIMPLE = ITU_IKAN
_G.ITU_IKAN_SIMPLE.Window = Window

-- Functions for external access
_G.ITU_IKAN_SIMPLE.startFishing = startAutoFishing
_G.ITU_IKAN_SIMPLE.stopFishing = stopAutoFishing
_G.ITU_IKAN_SIMPLE.setSpeed = setWalkSpeed
_G.ITU_IKAN_SIMPLE.setJump = setJumpPower
_G.ITU_IKAN_SIMPLE.startAntiAFK = startAntiAFK
_G.ITU_IKAN_SIMPLE.stopAntiAFK = stopAntiAFK

-- Success notification
notify("ITU IKAN", "Simple version loaded successfully! 🎉")

print("✅ ========================================")
print("   ITU IKAN SIMPLE VERSION READY!")
print("========================================")
print("📘 Access: _G.ITU_IKAN_SIMPLE")
print("🎮 UI: Should be visible now")
print("🔧 Commands:")
print("   _G.ITU_IKAN_SIMPLE.startFishing()")
print("   _G.ITU_IKAN_SIMPLE.stopFishing()")
print("   _G.ITU_IKAN_SIMPLE.setSpeed(100)")
print("✅ Ready to fish!")

return ITU_IKAN
