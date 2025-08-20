-- main.lua
-- ITU IKAN Main Script - Module Loader & UI Manager
-- Uses Rayfield UI Framework & Modular Architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Must run on client
if not RunService:IsClient() then
    warn("ITU IKAN: must run as a LocalScript on the client. Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("ITU IKAN: LocalPlayer missing. Run as LocalScript while in Play mode.")
    return
end

-- ====================================================================
-- INITIALIZATION & SETUP
-- ====================================================================

print("🐟 ITU IKAN - Advanced Fishing Bot Loading...")
print("   Version: 2.0.0")
print("   Author: yohansevta")
print("   Framework: Rayfield UI")

-- Load Rayfield UI Framework
local Rayfield
local success, error_msg = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/yohansevta/itu_ikan/refs/heads/main/framework/rayfield.lua'))()
end)

if not success then
    warn("Failed to load Rayfield UI Framework:", error_msg)
    -- Fallback notification
    StarterGui:SetCore("SendNotification", {
        Title = "ITU IKAN Error",
        Text = "Failed to load UI Framework",
        Duration = 5
    })
    return
end

-- ====================================================================
-- REMOTE DETECTION & SETUP
-- ====================================================================

-- Simple notifier
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, 
            Text = text, 
            Duration = duration or 4
        })
    end)
    print("[ITU IKAN]", title, "-", text)
end

-- Remote helper (best-effort)
local function FindNet()
    local ok, net = pcall(function()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if not packages then return nil end
        local idx = packages:FindFirstChild("_Index")
        if not idx then return nil end
        local sleit = idx:FindFirstChild("sleitnick_net@0.2.0")
        if not sleit then return nil end
        return sleit:FindFirstChild("net")
    end)
    return ok and net or nil
end

local net = FindNet()
local function ResolveRemote(name)
    if not net then return nil end
    local ok, rem = pcall(function() return net:FindFirstChild(name) end)
    return ok and rem or nil
end

-- Detect game remotes
local gameRemotes = {
    -- Core fishing remotes
    rod = ResolveRemote("RF/ChargeFishingRod"),
    miniGame = ResolveRemote("RF/RequestFishingMinigameStarted"),
    finish = ResolveRemote("RE/FishingCompleted"),
    equip = ResolveRemote("RE/EquipToolFromHotbar"),
    fishCaught = ResolveRemote("RE/FishCaught"),
    autoFishState = ResolveRemote("RF/UpdateAutoFishingState"),
    
    -- Additional remotes
    baitSpawned = ResolveRemote("RE/BaitSpawned"),
    fishingStopped = ResolveRemote("RE/FishingStopped"),
    newFishNotification = ResolveRemote("RE/ObtainedNewFishNotification"),
    playFishingEffect = ResolveRemote("RE/PlayFishingEffect"),
    fishingMinigameChanged = ResolveRemote("RE/FishingMinigameChanged"),
    
    -- Equipment remotes
    unequip = ResolveRemote("RE/UnequipToolFromHotbar"),
    unequipItem = ResolveRemote("RE/UnequipItem"),
    cancelFishingInputs = ResolveRemote("RF/CancelFishingInputs"),
    
    -- AutoSell remotes
    sellAll = ResolveRemote("RF/SellAllItems"),
    updateAutoSellThreshold = ResolveRemote("RF/UpdateAutoSellThreshold"),
    
    -- Network remotes
    reconnectPlayer = ResolveRemote("RE/ReconnectPlayer"),
    
    -- Enhancement remotes
    activateEnchantingAltar = ResolveRemote("RE/ActivateEnchantingAltar"),
    updateEnchantState = ResolveRemote("RE/UpdateEnchantState"),
    rollEnchant = ResolveRemote("RE/RollEnchant"),
    
    -- Weather remotes
    purchaseWeatherEvent = ResolveRemote("RF/PurchaseWeatherEvent")
}

-- Check remote availability
local remoteCount = 0
for name, remote in pairs(gameRemotes) do
    if remote then
        remoteCount = remoteCount + 1
    end
end

print("🔗 Game Remotes Detected:", remoteCount, "/ 20")
if remoteCount < 5 then
    Notify("ITU IKAN Warning", "⚠️ Limited remotes detected. Some features may not work.", 6)
end

-- ====================================================================
-- CONFIGURATION
-- ====================================================================

local Config = {
    -- Main settings
    enabled = false,
    mode = "smart",  -- smart, secure, fast
    autoRecastDelay = 0.4,
    safeModeChance = 70,
    
    -- Security settings
    secure_max_actions_per_minute = 12000000,
    secure_detection_cooldown = 5,
    
    -- Feature toggles
    autoModeEnabled = false,
    antiAfkEnabled = false,
    enhancementEnabled = false,
    autoReconnectEnabled = false,
    autoSellEnabled = false,
    
    -- AutoSell settings
    autoSellThreshold = 50,
    sellRarities = {
        COMMON = true,
        UNCOMMON = true,
        RARE = false,
        EPIC = false,
        LEGENDARY = false,
        MYTHIC = false
    }
}

-- ====================================================================
-- MODULE LOADER
-- ====================================================================

local Modules = {}

-- Module loader function
local function LoadModule(moduleName)
    -- First try to load from global modules (set by launcher)
    if _G.ITU_IKAN_MODULES and _G.ITU_IKAN_MODULES[moduleName] then
        print("✅ Module loaded from global:", moduleName)
        return _G.ITU_IKAN_MODULES[moduleName]
    end
    
    -- Fallback for local development
    local success, module = pcall(function()
        if moduleName == "FishingAI" then
            return require(script.Parent.modules.FishingAI)
        elseif moduleName == "Helpers" then
            return require(script.Parent.utils.helpers)
        elseif moduleName == "Settings" then
            return require(script.Parent.config.settings)
        end
        return nil
    end)
    
    if success and module then
        print("✅ Module loaded locally:", moduleName)
        return module
    else
        warn("❌ Failed to load module:", moduleName)
        Notify("Module Error", "Failed to load " .. moduleName, 5)
        return nil
    end
end

-- Load modules
print("📦 Loading modules...")

-- Load FishingAI module (testing first)
Modules.FishingAI = LoadModule("FishingAI")
if Modules.FishingAI then
    Modules.FishingAI.init(Config, gameRemotes, Notify)
    print("🎣 FishingAI Module: Initialized")
else
    warn("🎣 FishingAI Module: Failed to load!")
end

-- Load other modules (will be enabled after FishingAI test)
--[[
Modules.AntiAFK = LoadModule("antiafk")
Modules.AutoSell = LoadModule("autosell") 
Modules.Dashboard = LoadModule("dashboard")
Modules.Player = LoadModule("player")
Modules.RodFix = LoadModule("rodfix")
Modules.Teleport = LoadModule("teleport")

-- Initialize other modules
if Modules.AntiAFK then Modules.AntiAFK.init(Config, gameRemotes, Notify) end
if Modules.AutoSell then Modules.AutoSell.init(Config, gameRemotes, Notify) end
if Modules.Dashboard then Modules.Dashboard.init(Config, gameRemotes, Notify) end
if Modules.Player then Modules.Player.init(Config, gameRemotes, Notify) end
if Modules.RodFix then Modules.RodFix.init(Config, gameRemotes, Notify) end
if Modules.Teleport then Modules.Teleport.init(Config, gameRemotes, Notify) end
--]]

-- ====================================================================
-- UI CREATION
-- ====================================================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 ITU IKAN - Advanced Fishing Bot",
    LoadingTitle = "ITU IKAN Loading...",
    LoadingSubtitle = "by yohansevta",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ITU_IKAN_Config",
        FileName = "FishingBot"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false
})

-- ====================================================================
-- FISHING AI TAB
-- ====================================================================

local FishingTab = Window:CreateTab("🎣 Fishing AI", nil)

-- Main fishing controls
local FishingSection = FishingTab:CreateSection("Main Controls")

local AutoFishToggle = FishingTab:CreateToggle({
    Name = "🤖 Enable Auto Fishing",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(Value)
        Config.enabled = Value
        if Value then
            if Modules.FishingAI then
                Modules.FishingAI.start()
                Notify("🎣 Fishing AI", "Started! Mode: " .. Config.mode)
            else
                Notify("❌ Error", "FishingAI module not loaded!")
                AutoFishToggle:Set(false)
            end
        else
            if Modules.FishingAI then
                Modules.FishingAI.stop()
                Notify("🎣 Fishing AI", "Stopped")
            end
        end
    end,
})

local ModeDropdown = FishingTab:CreateDropdown({
    Name = "🎯 Fishing Mode",
    Options = {"smart", "secure", "fast"},
    CurrentOption = "smart",
    Flag = "FishingMode",
    Callback = function(Option)
        Config.mode = Option
        Notify("🎯 Mode", "Changed to: " .. Option)
    end,
})

local AutoModeToggle = FishingTab:CreateToggle({
    Name = "🔥 Auto Mode (Loop Complete)",
    CurrentValue = false,
    Flag = "AutoModeToggle",
    Callback = function(Value)
        Config.autoModeEnabled = Value
        if Value then
            if Modules.FishingAI then
                Modules.FishingAI.startAutoMode()
                Notify("🔥 Auto Mode", "Started! Looping FishingCompleted")
            else
                Notify("❌ Error", "FishingAI module not loaded!")
                AutoModeToggle:Set(false)
            end
        else
            if Modules.FishingAI then
                Modules.FishingAI.stopAutoMode()
                Notify("🔥 Auto Mode", "Stopped")
            end
        end
    end,
})

-- Rod controls
local RodSection = FishingTab:CreateSection("Rod Controls")

local FixRodButton = FishingTab:CreateButton({
    Name = "🔧 Fix Rod Orientation",
    Callback = function()
        if Modules.FishingAI then
            Modules.FishingAI.fixRodOrientation()
            Notify("🔧 Rod Fix", "Rod orientation fixed!")
        else
            Notify("❌ Error", "FishingAI module not loaded!")
        end
    end,
})

local UnequipRodButton = FishingTab:CreateButton({
    Name = "📤 Unequip Rod", 
    Callback = function()
        if Modules.FishingAI then
            local success = Modules.FishingAI.unequipRod()
            if success then
                Notify("📤 Unequip", "Rod unequipped successfully!")
            else
                Notify("📤 Unequip", "No rod equipped or failed to unequip")
            end
        else
            Notify("❌ Error", "FishingAI module not loaded!")
        end
    end,
})

-- Settings section
local SettingsSection = FishingTab:CreateSection("Settings")

local RecastDelaySlider = FishingTab:CreateSlider({
    Name = "⏱️ Recast Delay",
    Range = {0.1, 2.0},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.4,
    Flag = "RecastDelay",
    Callback = function(Value)
        Config.autoRecastDelay = Value
    end,
})

local SafeModeSlider = FishingTab:CreateSlider({
    Name = "🛡️ Safe Mode Chance",
    Range = {10, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 70,
    Flag = "SafeModeChance", 
    Callback = function(Value)
        Config.safeModeChance = Value
    end,
})

-- ====================================================================
-- STATUS TAB
-- ====================================================================

local StatusTab = Window:CreateTab("📊 Status", nil)

local StatusSection = StatusTab:CreateSection("Current Status")

local StatusLabel = StatusTab:CreateLabel("Status: Initializing...")
local LocationLabel = StatusTab:CreateLabel("Location: Unknown")
local ModeLabel = StatusTab:CreateLabel("Mode: " .. Config.mode)

-- Update status every 2 seconds
local function UpdateStatus()
    if Modules.FishingAI then
        local stats = Modules.FishingAI.getStats()
        StatusLabel:Set("Status: " .. (stats.isRunning and "🟢 Running" or "🔴 Stopped") .. " | State: " .. stats.currentState)
        LocationLabel:Set("Location: " .. (stats.currentLocation or "Unknown"))
        ModeLabel:Set("Mode: " .. Config.mode .. " | Auto Mode: " .. (stats.autoModeRunning and "🟢 On" or "🔴 Off"))
    else
        StatusLabel:Set("Status: ❌ FishingAI Module Not Loaded")
    end
end

-- Update status loop
task.spawn(function()
    while true do
        UpdateStatus()
        task.wait(2)
    end
end)

-- ====================================================================
-- TESTING TAB
-- ====================================================================

local TestTab = Window:CreateTab("🧪 Testing", nil)

local TestSection = TestTab:CreateSection("Module Testing")

local TestFishingAIButton = TestTab:CreateButton({
    Name = "🧪 Test FishingAI Module",
    Callback = function()
        if Modules.FishingAI then
            local stats = Modules.FishingAI.getStats()
            local testResults = {
                "🧪 FishingAI Test Results:",
                "- Module Status: ✅ Loaded",
                "- Current State: " .. stats.currentState,
                "- Running: " .. tostring(stats.isRunning),
                "- Auto Mode: " .. tostring(stats.autoModeRunning),
                "- Location: " .. stats.currentLocation,
                "- Security Status: " .. (stats.securityStatus.isInCooldown and "🔴 Cooldown" or "🟢 Active"),
                "- Actions/Min: " .. stats.securityStatus.actionsThisMinute
            }
            
            for _, result in ipairs(testResults) do
                print(result)
            end
            
            Notify("🧪 Test Complete", "Check console for detailed results", 8)
        else
            Notify("❌ Test Failed", "FishingAI module not loaded!")
        end
    end,
})

local TestRemotesButton = TestTab:CreateButton({
    Name = "🔗 Test Game Remotes",
    Callback = function()
        local workingRemotes = 0
        local totalRemotes = 0
        
        for name, remote in pairs(gameRemotes) do
            totalRemotes = totalRemotes + 1
            if remote then
                workingRemotes = workingRemotes + 1
                print("✅", name, ":", remote.Name)
            else
                print("❌", name, ": Not found")
            end
        end
        
        local percentage = math.floor((workingRemotes / totalRemotes) * 100)
        Notify("🔗 Remote Test", workingRemotes .. "/" .. totalRemotes .. " (" .. percentage .. "%) working", 6)
    end,
})

-- ====================================================================
-- UTILITIES TAB
-- ====================================================================

local UtilsTab = Window:CreateTab("⚙️ Utils", nil)

local UtilsSection = UtilsTab:CreateSection("Utilities")

local ReloadButton = UtilsTab:CreateButton({
    Name = "🔄 Reload Script",
    Callback = function()
        Notify("🔄 Reloading", "Restarting script in 2 seconds...")
        task.wait(2)
        
        -- Clean shutdown
        if Modules.FishingAI then
            Modules.FishingAI.cleanup()
        end
        
        -- Destroy UI
        if Window then
            Window:Destroy()
        end
        
        task.wait(0.5)
        loadstring(readfile("src/main.lua"))()
    end,
})

local CleanupButton = UtilsTab:CreateButton({
    Name = "🧹 Cleanup & Stop All",
    Callback = function()
        Config.enabled = false
        Config.autoModeEnabled = false
        
        if Modules.FishingAI then
            Modules.FishingAI.cleanup()
        end
        
        Notify("🧹 Cleanup", "All systems stopped and cleaned up")
    end,
})

-- ====================================================================
-- INITIALIZATION COMPLETE
-- ====================================================================

Notify("🐟 ITU IKAN", "Loaded successfully! FishingAI ready for testing.", 6)
print("🐟 ITU IKAN: Initialization complete!")
print("   - UI: Rayfield ✅")
print("   - Modules: FishingAI ✅")
print("   - Remotes: " .. remoteCount .. "/20 ✅")
print("   - Ready for testing! 🧪")

-- Final status update
UpdateStatus()
