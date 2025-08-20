-- settings.lua
-- Configuration settings for ITU IKAN FISHING BOT

local Settings = {}

-- Rayfield UI Configuration
Settings.UI = {
    name = "ITU IKAN FISHING BOT",
    loadingTitle = "ITU IKAN",
    loadingSubtitle = "by YohanSevta",
    configurationSaving = {
        enabled = true,
        flagName = "ITU_IKAN_CONFIG",
        tableName = "ITU_IKAN_SETTINGS"
    },
    discordInvite = nil,
    keyBindSettings = {
        toggleKeybind = Enum.KeyCode.RightControl,
        useKeySystemForRoblox = false, -- Set to true if you want key system
        keySystemTitle = "ITU IKAN KEY SYSTEM",
        keySystemSubtitle = "Key System",
        keySystemNote = "Join the discord for the key!",
        keySystemFileName = "ITU_IKAN_KEY",
        saveKey = true,
        guildId = "0000000000000000000", -- Replace with your Discord Guild ID
        keys = {"ITU2025", "IKAN123", "FISHBOT"} -- Example keys
    }
}

-- AutoFishing Configuration
Settings.AutoFishing = {
    enabled = false,
    mode = "smart", -- "smart", "secure", "fast"
    autoRecastDelay = 0.2,
    smartDelay = true,
    usePerfectCast = true,
    safeModeChance = 85, -- Persen untuk perfect cast
    maxActionsPerMinute = 120,
    detectionCooldown = 30,
    useAnimationDetection = true,
    autoEquipRod = true,
    rodSlot = 1
}

-- Rod Fix Configuration
Settings.RodFix = {
    enabled = true,
    continuousMode = true,
    fixDuringCharging = true,
    fixInterval = 0.05
}

-- Auto Sell Configuration
Settings.AutoSell = {
    enabled = false,
    threshold = 50,
    sellCommon = true,
    sellUncommon = true,
    sellRare = false,
    sellLegendary = false,
    sellMythical = false,
    autoReturn = true,
    sellDelay = 2.0
}

-- Anti-AFK Configuration
Settings.AntiAFK = {
    enabled = true,
    randomMovement = true,
    jumpRandomly = true,
    mouseMovement = true,
    interval = {min = 30, max = 90}
}

-- Teleport Locations
Settings.Locations = {
    ["🏝️ Kohana Volcano"] = CFrame.new(-594.971252, 396.65213, 149.10907),
    ["🏝️ Crater Island"] = CFrame.new(1010.01001, 252, 5078.45117),
    ["🏝️ Kohana"] = CFrame.new(-650.971191, 208.693695, 711.10907),
    ["🏝️ Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801),
    ["🏝️ Stingray Shores"] = CFrame.new(45.2788086, 252.562927, 2987.10913),
    ["🏝️ Esoteric Depths"] = CFrame.new(1944.77881, 393.562927, 1371.35913),
    ["🏝️ Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298),
    ["🏝️ Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    ["🏝️ Coral Reefs"] = CFrame.new(-3023.97119, 337.812927, 2195.60913),
    ["🏝️ SISYPUS"] = CFrame.new(-3709.75, -96.81, -952.38),
    ["🦈 TREASURE"] = CFrame.new(-3599.90, -275.96, -1640.84),
    ["🎣 STRINGRY"] = CFrame.new(102.05, 29.64, 3054.35),
    ["❄️ ICE LAND"] = CFrame.new(1990.55, 3.09, 3021.91),
    ["🌋 CRATER"] = CFrame.new(990.45, 21.06, 5059.85),
    ["🌴 TROPICAL"] = CFrame.new(-2093.80, 6.26, 3654.30),
    ["🗿 STONE"] = CFrame.new(-2636.19, 124.87, -27.49),
    ["🎲 ENCHANT STONE"] = CFrame.new(3237.61, -1302.33, 1398.04),
    ["⚙️ MACHINE"] = CFrame.new(-1551.25, 2.87, 1920.26)
}

-- Player Modifications
Settings.Player = {
    walkSpeed = 16,
    jumpPower = 50,
    enableFloat = false,
    floatHeight = 16,
    enableNoClip = false,
    enableSpinner = false,
    spinnerSpeed = 2,
    spinnerDirection = 1
}

-- Enhancement System
Settings.Enhancement = {
    enabled = false,
    autoTeleportToAltar = true,
    autoActivateAltar = false,
    autoRollEnchant = false,
    minGemsForRoll = 100,
    targetEnchantments = {"Resilient", "Lucky", "Divine", "Blessed"}
}

-- Weather System
Settings.Weather = {
    enabled = false,
    autoPurchase = false,
    selectedWeather = "Clear",
    availableWeathers = {"Clear", "Rain", "Fog", "Aurora", "Windstorm"}
}

-- Dashboard & Statistics
Settings.Dashboard = {
    trackStats = true,
    showRealTimeStats = true,
    autoSaveStats = true,
    resetStatsOnNewSession = false,
    exportStats = true
}

-- Security Settings
Settings.Security = {
    useRandomDelays = true,
    maxSuspicionLevel = 8,
    cooldownOnDetection = true,
    hideFromOtherPlayers = false,
    antiKick = true
}

-- Debug Settings
Settings.Debug = {
    enabled = false,
    logLevel = "INFO", -- "DEBUG", "INFO", "WARN", "ERROR"
    showNotifications = true,
    consoleOutput = true
}

return Settings
