# 🎣 ITU IKAN FISHING BOT - Complete Setup Guide

## 📋 Daftar Isi
- [Quick Start](#-quick-start)
- [Setup Lengkap](#-setup-lengkap)
- [Konfigurasi](#-konfigurasi)
- [Mode Fishing](#-mode-fishing)
- [Teleportasi](#-teleportasi)
- [Auto Sell](#-auto-sell)
- [Player Mods](#-player-mods)
- [Dashboard & Stats](#-dashboard--stats)
- [Troubleshooting](#-troubleshooting)
- [API Reference](#-api-reference)

## 🚀 Quick Start

### 1. Load Bot (Metode Termudah)
```lua
-- Copy paste ini ke Roblox executor
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()
```

### 2. Tunggu Loading
Bot akan otomatis membuka UI Rayfield. Tunggu beberapa detik sampai semua module ter-load.

### 3. Mulai Fishing
- Buka tab "🎣 Auto Fishing"
- Pilih mode (Smart/Secure/Fast)
- Klik "Start Fishing"

## 🔧 Setup Lengkap

### 1. Manual Setup
Jika ingin setup manual atau custom:

```lua
-- Load main bot
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/main.lua"))()

-- Custom setup
_G.ITU_IKAN.AutoFishing:SetMode("smart")
_G.ITU_IKAN.RodFix:Enable()
_G.ITU_IKAN.StartFishing()
```

### 2. Testing
```lua
-- Load test script
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/test_script.lua"))()
```

### 3. Examples
```lua
-- Load example functions
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/examples/example_usage.lua"))()

-- Quick setup examples
_G.ITU_IKAN_EXAMPLES.setupFullAutomation() -- Full automation
_G.ITU_IKAN_EXAMPLES.safeFishingMode()     -- Safe mode
_G.ITU_IKAN_EXAMPLES.grindingMode()        -- Grinding mode
```

## ⚙️ Konfigurasi

### Auto Fishing Settings
```lua
_G.ITU_IKAN.AutoFishing:UpdateSettings({
    mode = "smart",              -- smart/secure/fast
    autoRecastDelay = 0.3,       -- Delay setelah catch (detik)
    safeModeChance = 90,         -- Persentase safe mode (0-100)
    maxActionsPerMinute = 120,   -- Max actions per menit
    useRandomTiming = true,      -- Random timing untuk keamanan
    enableProgressCancel = true, -- Cancel jika progress stuck
    bobberCheckInterval = 1.0    -- Interval check bobber (detik)
})
```

### Auto Sell Settings
```lua
_G.ITU_IKAN.AutoSell:UpdateSettings({
    enabled = true,
    threshold = 75,              -- Sell ketika inventory >= 75%
    sellCommon = true,           -- Jual ikan common
    sellUncommon = true,         -- Jual ikan uncommon  
    sellRare = false,            -- Simpan ikan rare
    sellLegendary = false,       -- Simpan ikan legendary
    sellMythical = false,        -- Simpan ikan mythical
    autoReturn = true,           -- Auto balik ke lokasi fishing
    sellDelay = 2.0              -- Delay antar sell (detik)
})
```

### Player Mods Settings
```lua
-- Set walking speed
_G.ITU_IKAN.PlayerMods:SetWalkSpeed(50)
_G.ITU_IKAN.PlayerMods:SetJumpPower(100)

-- Enable float mode
_G.ITU_IKAN.PlayerMods:EnableFloat()
_G.ITU_IKAN.PlayerMods:SetFloatHeight(20)

-- Enable spinner (auto rotate)
_G.ITU_IKAN.PlayerMods:EnableSpinner()
_G.ITU_IKAN.PlayerMods:SetSpinnerSpeed(3)
```

## 🎣 Mode Fishing

### 1. Smart Mode (Recommended)
- **Kecepatan**: Sedang
- **Keamanan**: Tinggi
- **Fitur**: Realistic timing, progress monitoring, smart recast
```lua
_G.ITU_IKAN.AutoFishing:SetMode("smart")
```

### 2. Secure Mode (Paling Aman)
- **Kecepatan**: Lambat
- **Keamanan**: Maksimal
- **Fitur**: Extra delays, conservative actions, high safe mode
```lua
_G.ITU_IKAN.AutoFishing:SetMode("secure")
```

### 3. Fast Mode (Maximum Speed)
- **Kecepatan**: Cepat
- **Keamanan**: Sedang
- **Fitur**: Minimal delays, aggressive actions
```lua
_G.ITU_IKAN.AutoFishing:SetMode("fast")
```

## 📍 Teleportasi

### Available Locations
```lua
-- Lihat semua lokasi
local locations = _G.ITU_IKAN.Teleport:GetAvailableLocations()
for i, loc in ipairs(locations) do
    print(i .. ". " .. loc)
end
```

### Quick Teleport
```lua
-- Teleport ke lokasi specific
_G.ITU_IKAN.TeleportTo("🏝️ Kohana Volcano")
_G.ITU_IKAN.TeleportTo("🏝️ Stingray Shores")
_G.ITU_IKAN.TeleportTo("🏝️ Esoteric Depths")

-- Teleport ke best fishing spot berdasarkan waktu
_G.ITU_IKAN.Teleport:TeleportToBestFishingSpot()
```

### Follow Player
```lua
-- Follow player lain
_G.ITU_IKAN.Teleport:FollowPlayer("PlayerName")
_G.ITU_IKAN.Teleport:StopFollowing()
```

## 💰 Auto Sell

### Basic Usage
```lua
-- Toggle auto sell
_G.ITU_IKAN.ToggleAutoSell()

-- Set threshold (0-100)
_G.ITU_IKAN.AutoSell:SetThreshold(80)

-- Manual sell
_G.ITU_IKAN.AutoSell:ExecuteAutoSell()
```

### Advanced Filter
```lua
-- Custom sell filter
_G.ITU_IKAN.AutoSell:SetSellFilter({
    ["Common"] = true,
    ["Uncommon"] = true,
    ["Rare"] = false,
    ["Legendary"] = false,
    ["Mythical"] = false
})
```

## 👤 Player Mods

### Speed & Movement
```lua
-- Walking speed (default: 16)
_G.ITU_IKAN.PlayerMods:SetWalkSpeed(100)

-- Jump power (default: 50)
_G.ITU_IKAN.PlayerMods:SetJumpPower(200)

-- Enable/disable float
_G.ITU_IKAN.PlayerMods:EnableFloat()
_G.ITU_IKAN.PlayerMods:DisableFloat()
_G.ITU_IKAN.PlayerMods:SetFloatHeight(25)
```

### Auto Features
```lua
-- Auto spinner (berputar otomatis)
_G.ITU_IKAN.PlayerMods:EnableSpinner()
_G.ITU_IKAN.PlayerMods:SetSpinnerSpeed(5)

-- Auto jump (loncat otomatis)
_G.ITU_IKAN.PlayerMods:EnableAutoJump()
_G.ITU_IKAN.PlayerMods:SetAutoJumpInterval(2) -- setiap 2 detik
```

## 📊 Dashboard & Stats

### Get Statistics
```lua
-- Get current stats
local stats = _G.ITU_IKAN.GetStats()
print("Fish caught:", stats.fishCount)
print("Rare fish:", stats.rareCount)
print("Fish per hour:", stats.fishPerHour)
print("Session time:", stats.formattedDuration)
```

### Location Analytics
```lua
-- Get location stats
local locationStats = _G.ITU_IKAN.Dashboard:GetLocationStats()
for _, loc in ipairs(locationStats) do
    print(string.format("%s: %.1f%% rare rate", loc.location, loc.efficiency))
end
```

### Time Analytics
```lua
-- Get best fishing hours
local timeStats = _G.ITU_IKAN.Dashboard:GetTimeAnalytics()
for hour, data in pairs(timeStats) do
    print(string.format("Hour %d: %.1f fish/hour", hour, data.fishPerHour))
end
```

### Export Data
```lua
-- Export stats to console
_G.ITU_IKAN.Dashboard:ExportStatsToConsole()

-- Reset stats
_G.ITU_IKAN.Dashboard:ResetStats()
```

## 🛡️ Anti-AFK

### Basic Usage
```lua
-- Toggle anti-AFK
_G.ITU_IKAN.ToggleAntiAFK()

-- Check status
local status = _G.ITU_IKAN.AntiAFK:GetStatus()
print("Anti-AFK enabled:", status.enabled)
```

### Custom Settings
```lua
_G.ITU_IKAN.AntiAFK:UpdateSettings({
    enabled = true,
    method = "movement",         -- movement/camera/input
    interval = 60,              -- setiap 60 detik
    randomizeInterval = true,   -- randomize timing
    minInterval = 45,           -- min interval (detik)
    maxInterval = 90            -- max interval (detik)
})
```

## 🐛 Troubleshooting

### Bot Tidak Load
```lua
-- Manual debug load
print("Loading ITU IKAN...")
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()
end)

if not success then
    warn("Load error:", err)
end
```

### Check Status
```lua
-- Status report lengkap
_G.ITU_IKAN_EXAMPLES.statusReport()

-- Test semua modules
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/test_script.lua"))()
```

### Emergency Stop
```lua
-- Stop semua activities
_G.ITU_IKAN.EmergencyStop()

-- Atau manual
_G.ITU_IKAN.StopFishing()
_G.ITU_IKAN.AutoSell:Disable()
_G.ITU_IKAN.AntiAFK:Disable()
_G.ITU_IKAN.RodFix:Disable()
```

### Reset Settings
```lua
-- Reset ke default settings
_G.ITU_IKAN.ResetToDefault()

-- Reload bot
_G.ITU_IKAN.Reload()
```

## 📚 API Reference

### Global Functions
```lua
-- Main controls
_G.ITU_IKAN.StartFishing()          -- Start auto fishing
_G.ITU_IKAN.StopFishing()           -- Stop auto fishing
_G.ITU_IKAN.ToggleFishing()         -- Toggle fishing
_G.ITU_IKAN.EmergencyStop()         -- Emergency stop all

-- Teleportation
_G.ITU_IKAN.TeleportTo(location)    -- Teleport to location
_G.ITU_IKAN.GetCurrentLocation()    -- Get current location

-- Auto Sell
_G.ITU_IKAN.ToggleAutoSell()        -- Toggle auto sell
_G.ITU_IKAN.ToggleAntiAFK()         -- Toggle anti-AFK

-- Statistics
_G.ITU_IKAN.GetStats()              -- Get fishing stats
_G.ITU_IKAN.GetSettings()           -- Get current settings
```

### Module APIs

#### AutoFishing Module
```lua
_G.ITU_IKAN.AutoFishing:SetMode(mode)               -- Set fishing mode
_G.ITU_IKAN.AutoFishing:UpdateSettings(settings)   -- Update settings
_G.ITU_IKAN.AutoFishing:GetStatus()                -- Get status
_G.ITU_IKAN.AutoFishing:Enable()                   -- Enable module
_G.ITU_IKAN.AutoFishing:Disable()                  -- Disable module
```

#### Teleport Module
```lua
_G.ITU_IKAN.Teleport:TeleportToLocation(location)     -- Teleport
_G.ITU_IKAN.Teleport:GetAvailableLocations()          -- Get locations
_G.ITU_IKAN.Teleport:GetCurrentLocation()             -- Current location
_G.ITU_IKAN.Teleport:TeleportToBestFishingSpot(hour)  -- Best spot
_G.ITU_IKAN.Teleport:FollowPlayer(playerName)         -- Follow player
```

#### AutoSell Module
```lua
_G.ITU_IKAN.AutoSell:SetThreshold(threshold)       -- Set sell threshold
_G.ITU_IKAN.AutoSell:SetSellFilter(filter)         -- Set sell filter
_G.ITU_IKAN.AutoSell:ExecuteAutoSell()             -- Manual sell
_G.ITU_IKAN.AutoSell:GetStatus()                   -- Get status
```

#### PlayerMods Module
```lua
_G.ITU_IKAN.PlayerMods:SetWalkSpeed(speed)         -- Set walk speed
_G.ITU_IKAN.PlayerMods:SetJumpPower(power)         -- Set jump power
_G.ITU_IKAN.PlayerMods:EnableFloat()               -- Enable float
_G.ITU_IKAN.PlayerMods:EnableSpinner()             -- Enable spinner
_G.ITU_IKAN.PlayerMods:EnableAutoJump()            -- Enable auto jump
```

#### Dashboard Module
```lua
_G.ITU_IKAN.Dashboard:GetSessionStats()            -- Session statistics
_G.ITU_IKAN.Dashboard:GetLocationStats()           -- Location analytics
_G.ITU_IKAN.Dashboard:GetTimeAnalytics()           -- Time analytics
_G.ITU_IKAN.Dashboard:ExportStatsToConsole()       -- Export stats
_G.ITU_IKAN.Dashboard:ResetStats()                 -- Reset statistics
```

## 🎮 Game-Specific Tips

### Fisch Game
- **Best Locations**: Kohana Volcano, Esoteric Depths untuk rare fish
- **Best Times**: Malam hari (in-game) untuk legendary fish
- **Rod Upgrades**: Pastikan punya rod yang bagus untuk hasil optimal

### Performance Tips
- Gunakan **Smart Mode** untuk keseimbangan speed vs safety
- Enable **Rod Fix** jika ada masalah dengan rod animation
- Set **Auto Sell threshold** sekitar 70-80% untuk optimal inventory management
- Use **Anti-AFK** jika fishing dalam waktu lama

### Safety Tips
- Jangan set speed terlalu tinggi (max 100 recommended)
- Gunakan **Secure Mode** jika server banyak moderator
- Enable **randomize timing** untuk natural behavior
- Jangan fishing terlalu lama di satu lokasi

---

## ⚡ Quick Command Reference

```lua
-- ESSENTIAL COMMANDS
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()

-- QUICK SETUPS
_G.ITU_IKAN_EXAMPLES.setupFullAutomation()  -- Full auto
_G.ITU_IKAN_EXAMPLES.safeFishingMode()      -- Safe mode
_G.ITU_IKAN_EXAMPLES.grindingMode()         -- Fast grinding

-- QUICK CONTROLS
_G.ITU_IKAN.StartFishing()                  -- Start
_G.ITU_IKAN.StopFishing()                   -- Stop
_G.ITU_IKAN.EmergencyStop()                 -- Emergency

-- QUICK STATUS
_G.ITU_IKAN_EXAMPLES.statusReport()         -- Full status
_G.ITU_IKAN.GetStats()                      -- Quick stats
```

Selamat fishing! 🎣✨
