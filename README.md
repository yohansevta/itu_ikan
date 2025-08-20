# ITU IKAN FISHING BOT 🎣

**Version 2.0.0** - Modern Modular Auto Fishing Bot dengan Rayfield UI

Created by **YohanSevta**

[![GitHub release (latest by date- **YohanSevta**: Main developer
- **Rayfield Team**: UI Library  
- **Community**: Testing and feedback

## 🔗 Links & Resources

- **🏠 Repository**: https://github.com/yohansevta/itu_ikan
- **📖 Setup Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **📋 Release Notes**: [RELEASE_NOTES.md](RELEASE_NOTES.md)
- **💡 Examples**: [examples/example_usage.lua](examples/example_usage.lua)
- **🧪 Testing**: [test_script.lua](test_script.lua)

## 🌟 Quick Commands

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

---

**⚠️ Disclaimer**: This script is for educational purposes. Use responsibly and follow game rules.

**🎣 Happy Fishing!** 🐟//img.shields.io/github/v/release/yohansevta/itu_ikan)](https://github.com/yohansevta/itu_ikan/releases)
[![GitHub](https://img.shields.io/github/license/yohansevta/itu_ikan)](https://github.com/yohansevta/itu_ikan/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/yohansevta/itu_ikan)](https://github.com/yohansevta/itu_ikan/stargazers)

## 🚀 Quick Start

```lua
-- One-line loader (Recommended)
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()
```

## 📖 Documentation
- **[Setup Guide](SETUP_GUIDE.md)** - Comprehensive usage guide
- **[Release Notes](RELEASE_NOTES.md)** - What's new in v2.0
- **[Examples](examples/example_usage.lua)** - Usage examples and automation

## ✨ Features

### 🎣 Auto Fishing System
- **Smart Mode**: Realistic fishing dengan timing yang natural
- **Secure Mode**: Mode aman dengan detection avoidance
- **Fast Mode**: Mode cepat untuk grinding maksimal
- **Rod Orientation Fix**: Otomatis memperbaiki orientasi rod
- **Animation Detection**: Deteksi animasi fishing untuk timing optimal

### 💰 Auto Sell System
- **Threshold-based Selling**: Jual otomatis berdasarkan jumlah ikan
- **Rarity Filters**: Pilih rarity ikan mana yang mau dijual
- **Auto Return**: Kembali ke spot fishing setelah jual
- **Server Sync**: Sinkronisasi dengan server untuk konsistensi

### 🚀 Teleport System
- **Quick Teleports**: Teleport cepat ke lokasi populer
- **All Locations**: Semua lokasi fishing yang tersedia
- **Smart Teleport**: Teleport ke spot terbaik berdasarkan waktu
- **Player Teleport**: Teleport ke player lain
- **Best Spot Detection**: Otomatis detect spot terbaik

### 👤 Player Modifications
- **Speed Control**: Atur walk speed dan jump power
- **Float Mode**: Terbang dengan kontrol WASD + Space/Shift
- **No-Clip**: Tembus dinding dan obstacle
- **Auto Spinner**: Rotasi otomatis untuk randomize direction
- **Reset Function**: Kembalikan ke nilai original

### 📊 Advanced Dashboard
- **Real-time Statistics**: Statistik fishing real-time
- **Location Analytics**: Analisis efisiensi per lokasi
- **Time Analytics**: Waktu terbaik untuk fishing
- **Fish Tracking**: Track semua ikan yang ditangkap
- **Export Data**: Export statistik ke clipboard
- **Heatmap**: Visual representation fishing spots

### 🤖 Anti-AFK System
- **Random Movement**: Gerakan random untuk anti-AFK
- **Smart Intervals**: Interval yang bervariasi
- **Mouse Movement**: Gerakan mouse untuk aktivitas
- **Jump Random**: Random jump
- **Camera Rotation**: Rotasi kamera subtle

### ⚙️ Advanced Settings
- **Debug Mode**: Mode debug untuk troubleshooting
- **Security Settings**: Pengaturan keamanan anti-detection
- **Performance Options**: Optimasi performa
- **Auto-Save**: Simpan statistik otomatis

## 🚀 Installation & Usage

### Method 1: One-Line Loader (Recommended)
```lua
-- Copy paste ini ke Roblox executor
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/loader.lua"))()
```

### Method 2: Quick Setup Examples
```lua
-- Load examples dan automation
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/examples/example_usage.lua"))()

-- Full automation setup
_G.ITU_IKAN_EXAMPLES.setupFullAutomation()

-- Safe fishing mode
_G.ITU_IKAN_EXAMPLES.safeFishingMode()

-- Grinding mode (max speed)
_G.ITU_IKAN_EXAMPLES.grindingMode()
```

### Method 3: Testing
```lua
-- Test semua modules
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/test_script.lua"))()
```

### Method 4: Direct Core Loading
```lua
-- Load main bot directly
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/src/main.lua"))()
```

## 📁 File Structure

```
src/
├── main.lua              # Main entry point
├── config/
│   └── settings.lua       # Configuration settings
├── modules/
│   ├── autofishing.lua    # Auto fishing system
│   ├── autosell.lua       # Auto sell system
│   ├── antiafk.lua        # Anti-AFK system
│   ├── dashboard.lua      # Statistics & analytics
│   ├── player.lua         # Player modifications
│   ├── rodfix.lua         # Rod orientation fix
│   └── teleport.lua       # Teleport system
└── utils/
    ├── helpers.lua        # Utility functions
    └── logger.lua         # Logging system
```

## 🎮 Usage

### Quick Start
1. Execute script
2. Wait for Rayfield UI to load
3. Configure settings di Settings tab
4. Enable Auto Fishing
5. Enjoy automated fishing!

### API Access
Script menyediakan global API untuk scripting advanced:

```lua
-- Quick functions
_G.ITU_IKAN.StartFishing()
_G.ITU_IKAN.StopFishing()
_G.ITU_IKAN.TeleportTo("🏝️ Kohana")
_G.ITU_IKAN.SellNow()

-- Module access
local stats = _G.ITU_IKAN.Dashboard:GetSessionStats()
local status = _G.ITU_IKAN.AutoFishing:GetStatus()

-- Emergency stop
_G.ITU_IKAN.EmergencyStop()
```

## ⚡ Key Features

### 🔧 Modular Architecture
- **Independent Modules**: Setiap fitur dalam module terpisah
- **Easy Maintenance**: Mudah update dan maintain
- **Extensible**: Mudah tambah fitur baru
- **Clean Code**: Code yang rapi dan terdokumentasi

### 🎨 Modern UI
- **Rayfield Integration**: UI modern dengan Rayfield library
- **Tabbed Interface**: Interface dengan tabs yang terorganisir
- **Real-time Updates**: Update data real-time
- **Responsive Design**: UI yang responsive dan user-friendly

### 🛡️ Security Features
- **Anti-Detection**: Sistem anti-detection yang sophisticated
- **Random Delays**: Delay random untuk natural behavior
- **Smart Timing**: Timing yang realistis
- **Safe Mode**: Mode aman untuk menghindari detection

### 📈 Analytics
- **Comprehensive Stats**: Statistik lengkap dan detail
- **Location Efficiency**: Analisis efisiensi per lokasi
- **Time Optimization**: Optimasi berdasarkan waktu
- **Performance Tracking**: Track performa fishing

## 🙏 Credits

- **YohanSevta**: Main developer
- **Rayfield Team**: UI Library
- **Community**: Testing and feedback

---

**⚠️ Disclaimer**: This script is for educational purposes. Use responsibly and follow game rules.

**🎣 Happy Fishing!** 🐟