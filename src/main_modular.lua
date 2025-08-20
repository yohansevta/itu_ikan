-- main_modular.lua
-- ITU IKAN FISHING BOT - Modularized dari fishit.lua dengan Rayfield UI
-- by YohanSevta - Mengambil SEMUA fitur dari fishit.lua original

print("🎣 ITU IKAN FISHING BOT - Modular Version (dari fishit.lua)")
print("⚡ Loading semua fitur dari fishit.lua original...")

-- Services (exact dari fishit.lua)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Client check (dari fishit.lua)
if not RunService:IsClient() then
    warn("ITU IKAN: must run as a LocalScript on the client (StarterPlayerScripts). Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("ITU IKAN: LocalPlayer missing. Run as LocalScript while in Play mode.")
    return
end

-- Check if already loaded
if _G.ITU_IKAN_MODULAR then
    warn("⚠️ ITU IKAN Modular already loaded! Cleaning up...")
    if _G.ITU_IKAN_MODULAR.cleanup then
        _G.ITU_IKAN_MODULAR.cleanup()
    end
    wait(1)
end

-- Load Rayfield UI (ganti UI lama dari fishit.lua)
print("🔄 Loading Rayfield UI...")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
print("✅ Rayfield loaded!")

-- Simple notifier function (dari fishit.lua)
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
    print("🔔 " .. title .. ": " .. text)
end

-- Remote resolver (dari fishit.lua)
local function ResolveRemote(path)
    local remote = ReplicatedStorage:FindFirstChild(path)
    if not remote then
        local parts = path:split("/")
        local current = ReplicatedStorage
        for _, part in ipairs(parts) do
            current = current:FindFirstChild(part)
            if not current then break end
        end
        remote = current
    end
    return remote
end

-- Resolve all remotes from fishit.lua
local equipRemote = ResolveRemote("RE/EquipToolFromHotbar")
local catchRemote = ResolveRemote("RF/CatchFish")
local autoFishStateRemote = ResolveRemote("RF/UpdateAutoFishingState")
local releaseRemote = ResolveRemote("RF/ReleaseFish")
local castRemote = ResolveRemote("RF/CastRod")
local sellRemote = ResolveRemote("RF/SellFish")
local teleportRemote = ResolveRemote("RF/TeleportToLocation")
local unequipRemote = ResolveRemote("RE/UnequipToolFromHotbar")
local unequipItemRemote = ResolveRemote("RE/UnequipItem")
local reconnectPlayerRemote = ResolveRemote("RE/ReconnectPlayer")
local rollRemote = ResolveRemote("RF/RollEnchant")
local purchaseRemote = ResolveRemote("RF/PurchaseItem")

-- Global config from fishit.lua
local Config = {
    -- Auto Fishing Settings
    autoFishingEnabled = false,
    fishingMode = "smart", -- smart, secure, fast
    autoRecastDelay = 0.4,
    safeCastChance = 85,
    perfectCastChance = 15,
    
    -- Rod Fix
    rodFixEnabled = true,
    
    -- Auto Features
    autoReconnectEnabled = false,
    autoModeEnabled = false,
    autoSellEnabled = false,
    sellThreshold = 75,
    
    -- Enchant Features
    autoActivateAltar = false,
    autoRollEnchant = false,
    enchantAttempts = 5,
    autoPurchase = false,
    
    -- Player Mods
    walkSpeed = 16,
    jumpPower = 50,
    floatEnabled = false,
    spinnerEnabled = false,
    
    -- Current states
    currentLocation = "Unknown"
}

-- Load modules dari folder modules/
local RodFixModule = require(script.Parent.modules.rodfix)
local AutoFishingModule = require(script.Parent.modules.autofishing) 
local TeleportModule = require(script.Parent.modules.teleport)
local PlayerModule = require(script.Parent.modules.player)
local AutoSellModule = require(script.Parent.modules.autosell)
local AntiAFKModule = require(script.Parent.modules.antiafk)

-- Main ITU IKAN class
local ITU_IKAN = {
    loaded = true,
    version = "2.0 Modular (dari fishit.lua)",
    config = Config,
    
    -- Modules
    modules = {
        rodfix = RodFixModule,
        autofishing = AutoFishingModule,
        teleport = TeleportModule,
        player = PlayerModule,
        autosell = AutoSellModule,
        antiafk = AntiAFKModule
    },
    
    -- UI References
    Window = nil,
    tabs = {},
    
    -- Connections
    connections = {},
    
    -- Remotes (dari fishit.lua)
    remotes = {
        equip = equipRemote,
        catch = catchRemote,
        autoFishState = autoFishStateRemote,
        release = releaseRemote,
        cast = castRemote,
        sell = sellRemote,
        teleport = teleportRemote,
        unequip = unequipRemote,
        unequipItem = unequipItemRemote,
        reconnect = reconnectPlayerRemote,
        roll = rollRemote,
        purchase = purchaseRemote
    },
    
    -- Stats dari fishit.lua
    stats = {
        fishCaught = 0,
        rareFish = 0,
        sessionStart = tick(),
        lastCatch = 0,
        enchantAttempts = 0,
        reconnectCount = 0
    }
}

-- Initialize modules dengan config dan remotes
function ITU_IKAN.init()
    notify("ITU IKAN", "Initializing modular system...")
    
    -- Initialize setiap module dengan dependency yang dibutuhkan
    for name, module in pairs(ITU_IKAN.modules) do
        if module.init then
            module.init(Config, ITU_IKAN.remotes, notify)
            print("✅ Module initialized:", name)
        end
    end
    
    ITU_IKAN.createUI()
    notify("ITU IKAN", "Modular system ready! 🎣")
end

-- Create Rayfield UI
function ITU_IKAN.createUI()
    print("🎮 Creating Rayfield UI...")
    
    ITU_IKAN.Window = Rayfield:CreateWindow({
        Name = "🎣 ITU IKAN FISHING BOT - Modular",
        LoadingTitle = "ITU IKAN Loading...",
        LoadingSubtitle = "by YohanSevta - Modular dari fishit.lua",
        Theme = "Ocean",
        DisableRayfieldPrompts = false,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "ITU_IKAN_Modular",
            FileName = "config"
        }
    })
    
    -- Auto Fishing Tab
    local FishingTab = ITU_IKAN.Window:CreateTab("🎣 Auto Fishing", 4483362458)
    
    local FishingSection = FishingTab:CreateSection("Auto Fishing Controls")
    
    local FishingToggle = FishingTab:CreateToggle({
        Name = "🎣 Enable Auto Fishing",
        CurrentValue = false,
        Flag = "AutoFishing",
        Callback = function(Value)
            Config.autoFishingEnabled = Value
            if Value then
                ITU_IKAN.modules.autofishing.start()
            else
                ITU_IKAN.modules.autofishing.stop()
            end
        end,
    })
    
    local ModeDropdown = FishingTab:CreateDropdown({
        Name = "🎯 Fishing Mode",
        Options = {"smart", "secure", "fast"},
        CurrentOption = "smart",
        Flag = "FishingMode",
        Callback = function(Value)
            Config.fishingMode = Value
            notify("Settings", "Fishing mode: " .. Value)
        end,
    })
    
    local SafeCastSlider = FishingTab:CreateSlider({
        Name = "🛡️ Safe Cast Chance",
        Range = {50, 100},
        Increment = 5,
        Suffix = "%",
        CurrentValue = 85,
        Flag = "SafeCast",
        Callback = function(Value)
            Config.safeCastChance = Value
        end,
    })
    
    local PerfectCastSlider = FishingTab:CreateSlider({
        Name = "⭐ Perfect Cast Chance",
        Range = {0, 50},
        Increment = 5,
        Suffix = "%",
        CurrentValue = 15,
        Flag = "PerfectCast",
        Callback = function(Value)
            Config.perfectCastChance = Value
        end,
    })
    
    local RecastDelaySlider = FishingTab:CreateSlider({
        Name = "⏱️ Recast Delay",
        Range = {0.1, 3},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = 0.4,
        Flag = "RecastDelay",
        Callback = function(Value)
            Config.autoRecastDelay = Value
        end,
    })
    
    -- Rod Fix Section
    local RodSection = FishingTab:CreateSection("Rod Fixes")
    
    local RodFixToggle = FishingTab:CreateToggle({
        Name = "🔧 Rod Orientation Fix",
        CurrentValue = true,
        Flag = "RodFix",
        Callback = function(Value)
            Config.rodFixEnabled = Value
            if Value then
                ITU_IKAN.modules.rodfix.enable()
            else
                ITU_IKAN.modules.rodfix.disable()
            end
        end,
    })
    
    -- Auto Mode Section (dari fishit.lua)
    local AutoSection = FishingTab:CreateSection("Auto Mode Features")
    
    local AutoModeToggle = FishingTab:CreateToggle({
        Name = "🤖 Auto Mode",
        CurrentValue = false,
        Flag = "AutoMode",
        Callback = function(Value)
            Config.autoModeEnabled = Value
            if Value then
                ITU_IKAN.modules.autofishing.startAutoMode()
            else
                ITU_IKAN.modules.autofishing.stopAutoMode()
            end
        end,
    })
    
    local AutoReconnectToggle = FishingTab:CreateToggle({
        Name = "🔄 Auto Reconnect",
        CurrentValue = false,
        Flag = "AutoReconnect",
        Callback = function(Value)
            Config.autoReconnectEnabled = Value
        end,
    })
    
    -- Teleport Tab
    local TeleportTab = ITU_IKAN.Window:CreateTab("📍 Teleport", 4483362458)
    
    local TeleportSection = TeleportTab:CreateSection("Fishing Locations")
    
    -- Get locations dari module teleport
    local locations = ITU_IKAN.modules.teleport.getLocationList()
    
    local LocationDropdown = TeleportTab:CreateDropdown({
        Name = "🏝️ Select Location",
        Options = locations,
        CurrentOption = locations[1],
        Flag = "TeleportLocation",
        Callback = function(Value)
            ITU_IKAN.modules.teleport.to(Value)
            Config.currentLocation = Value
        end,
    })
    
    local BestSpotButton = TeleportTab:CreateButton({
        Name = "🎯 Go to Best Fishing Spot",
        Callback = function()
            local bestSpot = ITU_IKAN.modules.teleport.getBestSpot()
            ITU_IKAN.modules.teleport.to(bestSpot)
        end,
    })
    
    -- Player Mods Tab
    local PlayerTab = ITU_IKAN.Window:CreateTab("👤 Player Mods", 4483362458)
    
    local MovementSection = PlayerTab:CreateSection("Movement Settings")
    
    local SpeedSlider = PlayerTab:CreateSlider({
        Name = "🏃 Walk Speed",
        Range = {16, 200},
        Increment = 1,
        Suffix = "Speed",
        CurrentValue = 16,
        Flag = "WalkSpeed",
        Callback = function(Value)
            Config.walkSpeed = Value
            ITU_IKAN.modules.player.setWalkSpeed(Value)
        end,
    })
    
    local JumpSlider = PlayerTab:CreateSlider({
        Name = "🦘 Jump Power",
        Range = {50, 300},
        Increment = 5,
        Suffix = "Power",
        CurrentValue = 50,
        Flag = "JumpPower",
        Callback = function(Value)
            Config.jumpPower = Value
            ITU_IKAN.modules.player.setJumpPower(Value)
        end,
    })
    
    local FloatToggle = PlayerTab:CreateToggle({
        Name = "🎈 Float Mode",
        CurrentValue = false,
        Flag = "FloatMode",
        Callback = function(Value)
            Config.floatEnabled = Value
            if Value then
                ITU_IKAN.modules.player.enableFloat()
            else
                ITU_IKAN.modules.player.disableFloat()
            end
        end,
    })
    
    local SpinnerToggle = PlayerTab:CreateToggle({
        Name = "🌪️ Auto Spinner",
        CurrentValue = false,
        Flag = "SpinnerMode",
        Callback = function(Value)
            Config.spinnerEnabled = Value
            if Value then
                ITU_IKAN.modules.player.enableSpinner()
            else
                ITU_IKAN.modules.player.disableSpinner()
            end
        end,
    })
    
    -- Auto Sell Tab
    local SellTab = ITU_IKAN.Window:CreateTab("💰 Auto Sell", 4483362458)
    
    local SellSection = SellTab:CreateSection("Auto Sell Settings")
    
    local AutoSellToggle = SellTab:CreateToggle({
        Name = "💰 Enable Auto Sell",
        CurrentValue = false,
        Flag = "AutoSell",
        Callback = function(Value)
            Config.autoSellEnabled = Value
            if Value then
                ITU_IKAN.modules.autosell.start()
            else
                ITU_IKAN.modules.autosell.stop()
            end
        end,
    })
    
    local SellThresholdSlider = SellTab:CreateSlider({
        Name = "📦 Sell Threshold",
        Range = {25, 100},
        Increment = 5,
        Suffix = "%",
        CurrentValue = 75,
        Flag = "SellThreshold",
        Callback = function(Value)
            Config.sellThreshold = Value
        end,
    })
    
    local ManualSellButton = SellTab:CreateButton({
        Name = "💸 Manual Sell",
        Callback = function()
            ITU_IKAN.modules.autosell.sellNow()
        end,
    })
    
    -- Enchant Tab (dari fishit.lua)
    local EnchantTab = ITU_IKAN.Window:CreateTab("✨ Enchants", 4483362458)
    
    local EnchantSection = EnchantTab:CreateSection("Enchant Settings")
    
    local AutoAltarToggle = EnchantTab:CreateToggle({
        Name = "⛩️ Auto Activate Altar",
        CurrentValue = false,
        Flag = "AutoAltar",
        Callback = function(Value)
            Config.autoActivateAltar = Value
        end,
    })
    
    local AutoRollToggle = EnchantTab:CreateToggle({
        Name = "🎲 Auto Roll Enchant",
        CurrentValue = false,
        Flag = "AutoRoll",
        Callback = function(Value)
            Config.autoRollEnchant = Value
        end,
    })
    
    local EnchantAttemptsSlider = EnchantTab:CreateSlider({
        Name = "🔄 Enchant Attempts",
        Range = {1, 20},
        Increment = 1,
        Suffix = "attempts",
        CurrentValue = 5,
        Flag = "EnchantAttempts",
        Callback = function(Value)
            Config.enchantAttempts = Value
        end,
    })
    
    local AutoPurchaseToggle = EnchantTab:CreateToggle({
        Name = "🛒 Auto Purchase",
        CurrentValue = false,
        Flag = "AutoPurchase",
        Callback = function(Value)
            Config.autoPurchase = Value
        end,
    })
    
    -- Statistics Tab
    local StatsTab = ITU_IKAN.Window:CreateTab("📊 Statistics", 4483362458)
    
    local StatsSection = StatsTab:CreateSection("Session Statistics")
    
    local StatsLabel = StatsTab:CreateLabel("📊 Loading statistics...")
    
    -- Update stats display
    spawn(function()
        while ITU_IKAN.loaded do
            wait(3)
            if StatsLabel then
                local sessionTime = tick() - ITU_IKAN.stats.sessionStart
                local hours = math.floor(sessionTime / 3600)
                local minutes = math.floor((sessionTime % 3600) / 60)
                local seconds = math.floor(sessionTime % 60)
                
                local statsText = string.format(
                    "🎣 Fish Caught: %d\n" ..
                    "🌟 Rare Fish: %d\n" ..
                    "⏱️ Session: %02d:%02d:%02d\n" ..
                    "📍 Location: %s\n" ..
                    "🔄 Reconnects: %d\n" ..
                    "✨ Enchant Attempts: %d",
                    ITU_IKAN.stats.fishCaught,
                    ITU_IKAN.stats.rareFish,
                    hours, minutes, seconds,
                    Config.currentLocation,
                    ITU_IKAN.stats.reconnectCount,
                    ITU_IKAN.stats.enchantAttempts
                )
                StatsLabel:Set(statsText)
            end
        end
    end)
    
    -- Settings Tab
    local SettingsTab = ITU_IKAN.Window:CreateTab("⚙️ Settings", 4483362458)
    
    local SettingsSection = SettingsTab:CreateSection("Bot Settings")
    
    local AntiAFKToggle = SettingsTab:CreateToggle({
        Name = "🛡️ Anti-AFK System",
        CurrentValue = false,
        Flag = "AntiAFK",
        Callback = function(Value)
            if Value then
                ITU_IKAN.modules.antiafk.start()
            else
                ITU_IKAN.modules.antiafk.stop()
            end
        end,
    })
    
    local EmergencyStopButton = SettingsTab:CreateButton({
        Name = "🚨 Emergency Stop All",
        Callback = function()
            ITU_IKAN.cleanup()
            notify("Emergency", "All systems stopped!")
        end,
    })
    
    local InfoSection = SettingsTab:CreateSection("Information")
    
    local InfoLabel = SettingsTab:CreateLabel(
        "🎣 ITU IKAN " .. ITU_IKAN.version .. "\n" ..
        "👨‍💻 Created by YohanSevta\n" ..
        "📁 Modular dari fishit.lua original\n" ..
        "🎮 All features working!"
    )
    
    print("✅ Rayfield UI created successfully!")
end

-- Cleanup function
function ITU_IKAN.cleanup()
    print("🧹 Cleaning up ITU IKAN Modular...")
    
    -- Stop all modules
    for name, module in pairs(ITU_IKAN.modules) do
        if module.stop then
            pcall(function() module.stop() end)
        end
        if module.cleanup then
            pcall(function() module.cleanup() end)
        end
    end
    
    -- Clear connections
    for name, connection in pairs(ITU_IKAN.connections) do
        if connection and connection.Disconnect then
            pcall(function() connection:Disconnect() end)
        end
    end
    ITU_IKAN.connections = {}
    
    ITU_IKAN.loaded = false
    print("✅ ITU IKAN Modular cleaned up")
end

-- Store globally
_G.ITU_IKAN_MODULAR = ITU_IKAN

-- Initialize
ITU_IKAN.init()

-- Success notification
notify("ITU IKAN", "Modular version loaded! Semua fitur dari fishit.lua siap! 🎉")

print("✅ ========================================")
print("   ITU IKAN MODULAR VERSION READY!")
print("========================================") 
print("📘 Access: _G.ITU_IKAN_MODULAR")
print("🎮 UI: Rayfield interface loaded")
print("📁 Modules: Loaded dari folder modules/")
print("🔧 Features: Semua dari fishit.lua original")
print("✅ Ready for fishing!")

return ITU_IKAN
