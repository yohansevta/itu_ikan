-- main.lua
-- ITU IKAN FISHING BOT - Main Entry Point
-- by YohanSevta

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Check if running on client
if not RunService:IsClient() then
    warn("ITU IKAN: Must run as LocalScript on client. Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("ITU IKAN: LocalPlayer missing. Run as LocalScript while in game.")
    return
end

-- Global debug flag
_G.ITU_IKAN_DEBUG = true

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Load settings
local Settings = require(script.config.settings)

-- Load utilities
local Helpers = require(script.utils.helpers)

-- Load modules
local RodFix = require(script.modules.rodfix)
local AutoFishing = require(script.modules.autofishing)
local Teleport = require(script.modules.teleport)
local PlayerMods = require(script.modules.player)
local Dashboard = require(script.modules.dashboard)
local AutoSell = require(script.modules.autosell)
local AntiAFK = require(script.modules.antiafk)

-- Main ITU IKAN class
local ITU_IKAN = {}
ITU_IKAN.__index = ITU_IKAN

function ITU_IKAN.new()
    local self = setmetatable({}, ITU_IKAN)
    
    -- Initialize modules
    self.settings = Settings
    self.dashboard = Dashboard.new(self.settings.Dashboard)
    self.rodFix = RodFix.new(self.settings.RodFix)
    self.autoFishing = AutoFishing.new(self.settings.AutoFishing, self.rodFix)
    self.teleport = Teleport.new({locations = self.settings.Locations})
    self.playerMods = PlayerMods.new(self.settings.Player)
    self.autoSell = AutoSell.new(self.settings.AutoSell)
    self.antiAFK = AntiAFK.new(self.settings.AntiAFK)
    
    -- Set up fish caught callback
    self.autoFishing:SetFishCaughtCallback(function(fishData, rarity)
        self.dashboard:LogFishCatch(fishData.name, nil, rarity)
        self.autoSell:AddFish(fishData.name, rarity)
    end)
    
    -- UI components
    self.window = nil
    self.tabs = {}
    self.updateLoop = nil
    
    self:CreateUI()
    self:StartUpdateLoop()
    
    return self
end

function ITU_IKAN:CreateUI()
    -- Create main window
    self.window = Rayfield:CreateWindow({
        Name = self.settings.UI.name,
        LoadingTitle = self.settings.UI.loadingTitle,
        LoadingSubtitle = self.settings.UI.loadingSubtitle,
        ConfigurationSaving = self.settings.UI.configurationSaving,
        Discord = self.settings.UI.discordInvite,
        KeySystem = self.settings.UI.keyBindSettings.useKeySystemForRoblox,
        KeySettings = self.settings.UI.keyBindSettings
    })
    
    -- Create tabs
    self:CreateAutoFishingTab()
    self:CreateAutoSellTab()
    self:CreateTeleportTab()
    self:CreatePlayerTab()
    self:CreateDashboardTab()
    self:CreateSettingsTab()
end

function ITU_IKAN:CreateAutoFishingTab()
    local tab = self.window:CreateTab("🎣 Auto Fishing", nil)
    self.tabs.autoFishing = tab
    
    -- Auto Fishing Toggle
    local autoFishToggle = tab:CreateToggle({
        Name = "Enable Auto Fishing",
        CurrentValue = false,
        Flag = "AutoFishingEnabled",
        Callback = function(value)
            if value then
                local success, message = self.autoFishing:Start()
                if not success then
                    Helpers.Notify("Auto Fishing", "Failed to start: " .. message)
                end
            else
                self.autoFishing:Stop()
            end
        end,
    })
    
    -- Fishing Mode
    local modeDropdown = tab:CreateDropdown({
        Name = "Fishing Mode",
        Options = {"smart", "secure", "fast"},
        CurrentOption = self.autoFishing.mode,
        Flag = "FishingMode",
        Callback = function(option)
            self.autoFishing:SetMode(option)
            Helpers.Notify("Auto Fishing", "Mode set to: " .. option)
        end,
    })
    
    -- Rod Fix Section
    tab:CreateSection("Rod Orientation Fix")
    
    local rodFixToggle = tab:CreateToggle({
        Name = "Enable Rod Fix",
        CurrentValue = self.rodFix.enabled,
        Flag = "RodFixEnabled",
        Callback = function(value)
            if value then
                self.rodFix:Enable()
            else
                self.rodFix:Disable()
            end
        end,
    })
    
    local forceFixButton = tab:CreateButton({
        Name = "Force Fix Rod Orientation",
        Callback = function()
            self.rodFix:ForceFix()
            Helpers.Notify("Rod Fix", "Force fix applied")
        end,
    })
    
    -- Auto Fishing Settings
    tab:CreateSection("Auto Fishing Settings")
    
    local delaySlider = tab:CreateSlider({
        Name = "Recast Delay",
        Range = {0.1, 2.0},
        Increment = 0.1,
        CurrentValue = self.settings.AutoFishing.autoRecastDelay,
        Flag = "RecastDelay",
        Callback = function(value)
            self.settings.AutoFishing.autoRecastDelay = value
            self.autoFishing:UpdateSettings({autoRecastDelay = value})
        end,
    })
    
    local perfectCastSlider = tab:CreateSlider({
        Name = "Perfect Cast Chance (%)",
        Range = {0, 100},
        Increment = 5,
        CurrentValue = self.settings.AutoFishing.safeModeChance,
        Flag = "PerfectCastChance",
        Callback = function(value)
            self.settings.AutoFishing.safeModeChance = value
            self.autoFishing:UpdateSettings({safeModeChance = value})
        end,
    })
    
    -- Status Display
    tab:CreateSection("Status")
    
    local statusLabel = tab:CreateLabel("Status: Stopped")
    local statsLabel = tab:CreateLabel("Fish Caught: 0 | Rare: 0")
    
    -- Store references for updates
    self.ui = {
        autoFishing = {
            statusLabel = statusLabel,
            statsLabel = statsLabel
        }
    }
end

function ITU_IKAN:CreateAutoSellTab()
    local tab = self.window:CreateTab("💰 Auto Sell", nil)
    self.tabs.autoSell = tab
    
    -- Auto Sell Toggle
    local autoSellToggle = tab:CreateToggle({
        Name = "Enable Auto Sell",
        CurrentValue = self.autoSell.enabled,
        Flag = "AutoSellEnabled",
        Callback = function(value)
            if value then
                self.autoSell:Enable()
            else
                self.autoSell:Disable()
            end
        end,
    })
    
    -- Threshold Setting
    local thresholdSlider = tab:CreateSlider({
        Name = "Sell Threshold (Fish Count)",
        Range = {10, 200},
        Increment = 5,
        CurrentValue = self.autoSell.threshold,
        Flag = "SellThreshold",
        Callback = function(value)
            self.autoSell:SetThreshold(value)
        end,
    })
    
    -- Sell Filters
    tab:CreateSection("Sell Filters")
    
    local commonToggle = tab:CreateToggle({
        Name = "Sell Common Fish",
        CurrentValue = self.autoSell.sellFilters.common,
        Flag = "SellCommon",
        Callback = function(value)
            self.autoSell:SetSellFilter("common", value)
        end,
    })
    
    local uncommonToggle = tab:CreateToggle({
        Name = "Sell Uncommon Fish",
        CurrentValue = self.autoSell.sellFilters.uncommon,
        Flag = "SellUncommon",
        Callback = function(value)
            self.autoSell:SetSellFilter("uncommon", value)
        end,
    })
    
    local rareToggle = tab:CreateToggle({
        Name = "Sell Rare Fish",
        CurrentValue = self.autoSell.sellFilters.rare,
        Flag = "SellRare",
        Callback = function(value)
            self.autoSell:SetSellFilter("rare", value)
        end,
    })
    
    local legendaryToggle = tab:CreateToggle({
        Name = "Sell Legendary Fish",
        CurrentValue = self.autoSell.sellFilters.legendary,
        Flag = "SellLegendary",
        Callback = function(value)
            self.autoSell:SetSellFilter("legendary", value)
        end,
    })
    
    local mythicalToggle = tab:CreateToggle({
        Name = "Sell Mythical Fish",
        CurrentValue = self.autoSell.sellFilters.mythical,
        Flag = "SellMythical",
        Callback = function(value)
            self.autoSell:SetSellFilter("mythical", value)
        end,
    })
    
    -- Settings
    tab:CreateSection("Auto Sell Settings")
    
    local autoReturnToggle = tab:CreateToggle({
        Name = "Auto Return to Fishing Spot",
        CurrentValue = self.autoSell.autoReturn,
        Flag = "AutoReturn",
        Callback = function(value)
            self.autoSell.autoReturn = value
        end,
    })
    
    local sellDelaySlider = tab:CreateSlider({
        Name = "Sell Delay (seconds)",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = self.autoSell.sellDelay,
        Flag = "SellDelay",
        Callback = function(value)
            self.autoSell.sellDelay = value
        end,
    })
    
    -- Manual Controls
    tab:CreateSection("Manual Controls")
    
    local manualSellButton = tab:CreateButton({
        Name = "Sell All Fish Now",
        Callback = function()
            local success, message = self.autoSell:ManualSell()
            if not success then
                Helpers.Notify("Auto Sell", message)
            end
        end,
    })
    
    local resetCountsButton = tab:CreateButton({
        Name = "Reset Fish Counts",
        Callback = function()
            self.autoSell:ResetSellCounts()
            Helpers.Notify("Auto Sell", "Fish counts reset")
        end,
    })
    
    -- Status Display
    tab:CreateSection("Status")
    
    local sellStatusLabel = tab:CreateLabel("Status: Disabled")
    local fishCountsLabel = tab:CreateLabel("Fish Ready: 0")
    local estimatedValueLabel = tab:CreateLabel("Estimated Value: $0")
    
    -- Store references
    self.ui.autoSell = {
        sellStatusLabel = sellStatusLabel,
        fishCountsLabel = fishCountsLabel,
        estimatedValueLabel = estimatedValueLabel
    }
end

function ITU_IKAN:CreateTeleportTab()
    local tab = self.window:CreateTab("🚀 Teleport", nil)
    self.tabs.teleport = tab
    
    -- Current Location
    local locationLabel = tab:CreateLabel("Current Location: " .. self.teleport.currentLocation)
    
    -- Quick Teleports
    tab:CreateSection("Quick Teleports")
    
    local quickTeleports = {
        {name = "🏝️ Kohana (Home)", location = "🏝️ Kohana"},
        {name = "🎲 Enchant Altar", location = "🎲 ENCHANT STONE"},
        {name = "⚙️ Weather Machine", location = "⚙️ MACHINE"},
        {name = "🌋 Volcano", location = "🏝️ Kohana Volcano"},
        {name = "🌊 Depths", location = "🏝️ Esoteric Depths"}
    }
    
    for _, teleport in pairs(quickTeleports) do
        tab:CreateButton({
            Name = teleport.name,
            Callback = function()
                local success, message = self.teleport:TeleportToLocation(teleport.location)
                if not success then
                    Helpers.Notify("Teleport", message)
                end
            end,
        })
    end
    
    -- All Locations
    tab:CreateSection("All Locations")
    
    local locationDropdown = tab:CreateDropdown({
        Name = "Select Location",
        Options = self:GetLocationNames(),
        CurrentOption = "🏝️ Kohana",
        Flag = "SelectedLocation",
        Callback = function(option)
            -- Store selected location
        end,
    })
    
    local teleportButton = tab:CreateButton({
        Name = "Teleport to Selected Location",
        Callback = function()
            local selected = locationDropdown.CurrentOption
            if selected then
                local success, message = self.teleport:TeleportToLocation(selected)
                if not success then
                    Helpers.Notify("Teleport", message)
                end
            end
        end,
    })
    
    -- Best Spot Teleport
    tab:CreateSection("Smart Teleport")
    
    local bestSpotButton = tab:CreateButton({
        Name = "Teleport to Best Fishing Spot",
        Callback = function()
            local success, message = self.teleport:TeleportToBestFishingSpot()
            if not success then
                Helpers.Notify("Teleport", message)
            end
        end,
    })
    
    -- Player Teleport
    tab:CreateSection("Player Teleport")
    
    local playerDropdown = tab:CreateDropdown({
        Name = "Select Player",
        Options = self:GetPlayerNames(),
        CurrentOption = "None",
        Flag = "SelectedPlayer",
        Callback = function(option)
            -- Store selected player
        end,
    })
    
    local teleportToPlayerButton = tab:CreateButton({
        Name = "Teleport to Player",
        Callback = function()
            local selected = playerDropdown.CurrentOption
            if selected and selected ~= "None" then
                local success, message = self.teleport:TeleportToPlayer(selected)
                if not success then
                    Helpers.Notify("Teleport", message)
                end
            end
        end,
    })
    
    -- Store references
    self.ui.teleport = {
        locationLabel = locationLabel,
        playerDropdown = playerDropdown
    }
end

function ITU_IKAN:CreatePlayerTab()
    local tab = self.window:CreateTab("👤 Player", nil)
    self.tabs.player = tab
    
    -- Movement Speed
    tab:CreateSection("Movement Settings")
    
    local walkSpeedSlider = tab:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 200},
        Increment = 1,
        CurrentValue = self.playerMods.walkSpeed,
        Flag = "WalkSpeed",
        Callback = function(value)
            self.playerMods:SetWalkSpeed(value)
        end,
    })
    
    local jumpPowerSlider = tab:CreateSlider({
        Name = "Jump Power",
        Range = {50, 200},
        Increment = 1,
        CurrentValue = self.playerMods.jumpPower,
        Flag = "JumpPower",
        Callback = function(value)
            self.playerMods:SetJumpPower(value)
        end,
    })
    
    local resetButton = tab:CreateButton({
        Name = "Reset to Original Values",
        Callback = function()
            self.playerMods:Reset()
        end,
    })
    
    -- Movement Features
    tab:CreateSection("Movement Features")
    
    local floatToggle = tab:CreateToggle({
        Name = "Enable Float (WASD + Space/Shift)",
        CurrentValue = false,
        Flag = "FloatEnabled",
        Callback = function(value)
            if value then
                self.playerMods:EnableFloat()
            else
                self.playerMods:DisableFloat()
            end
        end,
    })
    
    local floatHeightSlider = tab:CreateSlider({
        Name = "Float Height",
        Range = {5, 100},
        Increment = 1,
        CurrentValue = self.playerMods.floatHeight,
        Flag = "FloatHeight",
        Callback = function(value)
            self.playerMods:SetFloatHeight(value)
        end,
    })
    
    local noClipToggle = tab:CreateToggle({
        Name = "Enable No-Clip",
        CurrentValue = false,
        Flag = "NoClipEnabled",
        Callback = function(value)
            if value then
                self.playerMods:EnableNoClip()
            else
                self.playerMods:DisableNoClip()
            end
        end,
    })
    
    -- Auto Spinner
    tab:CreateSection("Auto Spinner")
    
    local spinnerToggle = tab:CreateToggle({
        Name = "Enable Auto Spinner",
        CurrentValue = false,
        Flag = "SpinnerEnabled",
        Callback = function(value)
            if value then
                self.playerMods:EnableSpinner()
            else
                self.playerMods:DisableSpinner()
            end
        end,
    })
    
    local spinnerSpeedSlider = tab:CreateSlider({
        Name = "Spinner Speed",
        Range = {0.1, 10},
        Increment = 0.1,
        CurrentValue = self.playerMods.spinnerSpeed,
        Flag = "SpinnerSpeed",
        Callback = function(value)
            self.playerMods:SetSpinnerSpeed(value)
        end,
    })
    
    local spinnerDirectionButton = tab:CreateButton({
        Name = "Toggle Spinner Direction",
        Callback = function()
            self.playerMods:ToggleSpinnerDirection()
        end,
    })
end

function ITU_IKAN:CreateDashboardTab()
    local tab = self.window:CreateTab("📊 Dashboard", nil)
    self.tabs.dashboard = tab
    
    -- Session Stats
    tab:CreateSection("Session Statistics")
    
    local sessionLabel = tab:CreateLabel("Session Time: 0s")
    local fishCountLabel = tab:CreateLabel("Fish Caught: 0")
    local rareCountLabel = tab:CreateLabel("Rare Fish: 0")
    local fishPerHourLabel = tab:CreateLabel("Fish/Hour: 0")
    local currentLocationLabel = tab:CreateLabel("Location: Unknown")
    
    -- Controls
    tab:CreateSection("Controls")
    
    local resetStatsButton = tab:CreateButton({
        Name = "Reset Statistics",
        Callback = function()
            self.dashboard:Reset()
            Helpers.Notify("Dashboard", "Statistics reset")
        end,
    })
    
    local exportStatsButton = tab:CreateButton({
        Name = "Export Statistics",
        Callback = function()
            local data = self.dashboard:ExportStats()
            if data then
                Helpers.Notify("Dashboard", "Statistics exported to clipboard")
                -- Copy to clipboard if available
                pcall(function()
                    if setclipboard then
                        setclipboard(game:GetService("HttpService"):JSONEncode(data))
                    end
                end)
            end
        end,
    })
    
    -- Location Stats
    tab:CreateSection("Location Statistics")
    local locationStatsLabel = tab:CreateLabel("Loading location data...")
    
    -- Time Analytics
    tab:CreateSection("Best Fishing Times")
    local timeAnalyticsLabel = tab:CreateLabel("Loading time data...")
    
    -- Store references
    self.ui.dashboard = {
        sessionLabel = sessionLabel,
        fishCountLabel = fishCountLabel,
        rareCountLabel = rareCountLabel,
        fishPerHourLabel = fishPerHourLabel,
        currentLocationLabel = currentLocationLabel,
        locationStatsLabel = locationStatsLabel,
        timeAnalyticsLabel = timeAnalyticsLabel
    }
end

function ITU_IKAN:CreateSettingsTab()
    local tab = self.window:CreateTab("⚙️ Settings", nil)
    self.tabs.settings = tab
    
    -- Debug Settings
    tab:CreateSection("Debug Settings")
    
    local debugToggle = tab:CreateToggle({
        Name = "Enable Debug Mode",
        CurrentValue = _G.ITU_IKAN_DEBUG,
        Flag = "DebugMode",
        Callback = function(value)
            _G.ITU_IKAN_DEBUG = value
            self.settings.Debug.enabled = value
        end,
    })
    
    local notificationsToggle = tab:CreateToggle({
        Name = "Show Notifications",
        CurrentValue = self.settings.Debug.showNotifications,
        Flag = "ShowNotifications",
        Callback = function(value)
            self.settings.Debug.showNotifications = value
        end,
    })
    
    -- Security Settings
    tab:CreateSection("Security Settings")
    
    local randomDelaysToggle = tab:CreateToggle({
        Name = "Use Random Delays",
        CurrentValue = self.settings.Security.useRandomDelays,
        Flag = "RandomDelays",
        Callback = function(value)
            self.settings.Security.useRandomDelays = value
        end,
    })
    
    local antiKickToggle = tab:CreateToggle({
        Name = "Anti-Kick Protection",
        CurrentValue = self.settings.Security.antiKick,
        Flag = "AntiKick",
        Callback = function(value)
            self.settings.Security.antiKick = value
        end,
    })
    
    -- Performance Settings
    tab:CreateSection("Performance Settings")
    
    local autoSaveToggle = tab:CreateToggle({
        Name = "Auto-Save Statistics",
        CurrentValue = self.settings.Dashboard.autoSaveStats,
        Flag = "AutoSaveStats",
        Callback = function(value)
            self.settings.Dashboard.autoSaveStats = value
            self.dashboard:UpdateSettings({autoSaveStats = value})
        end,
    })
    
    -- About Section
    tab:CreateSection("About")
    
    tab:CreateLabel("ITU IKAN FISHING BOT")
    tab:CreateLabel("Version: 2.0.0")
    tab:CreateLabel("Created by: YohanSevta")
    tab:CreateLabel("Powered by Rayfield UI")
    
    local githubButton = tab:CreateButton({
        Name = "Open GitHub Repository",
        Callback = function()
            Helpers.Notify("ITU IKAN", "GitHub repository link copied to clipboard")
            pcall(function()
                if setclipboard then
                    setclipboard("https://github.com/yohansevta/itu_ikan")
                end
            end)
        end,
    })
    
    -- Emergency Stop
    tab:CreateSection("Emergency")
    
    local emergencyStopButton = tab:CreateButton({
        Name = "🚨 EMERGENCY STOP ALL",
        Callback = function()
            self:EmergencyStop()
        end,
    })
end

function ITU_IKAN:StartUpdateLoop()
    self.updateLoop = task.spawn(function()
        while true do
            self:UpdateUI()
            task.wait(1) -- Update every second
        end
    end)
end

function ITU_IKAN:UpdateUI()
    -- Update Auto Fishing tab
    if self.ui and self.ui.autoFishing then
        local status = self.autoFishing:GetStatus()
        local stats = self.autoFishing:GetStats()
        
        self.ui.autoFishing.statusLabel:Set("Status: " .. (status.enabled and "Running" or "Stopped") .. 
                                           " | Mode: " .. status.mode)
        self.ui.autoFishing.statsLabel:Set(string.format("Fish: %s | Rare: %s | Rate: %.1f/hr", 
                                          Helpers.FormatNumber(stats.fishCaught),
                                          Helpers.FormatNumber(stats.rareFishCaught),
                                          stats.fishPerHour))
    end
    
    -- Update Auto Sell tab
    if self.ui and self.ui.autoSell then
        local sellStatus = self.autoSell:GetStatus()
        local sellSummary = sellStatus.sellSummary
        
        self.ui.autoSell.sellStatusLabel:Set("Status: " .. (sellStatus.enabled and "Enabled" or "Disabled") .. 
                                            " | Threshold: " .. sellStatus.threshold)
        self.ui.autoSell.fishCountsLabel:Set("Ready to Sell: " .. sellSummary.totalSellableFish .. 
                                            (sellSummary.readyToSell and " ✅" or " ❌"))
        self.ui.autoSell.estimatedValueLabel:Set("Estimated Value: $" .. Helpers.FormatNumber(sellSummary.estimatedValue))
    end
    
    -- Update Teleport tab
    if self.ui and self.ui.teleport then
        self.ui.teleport.locationLabel:Set("Current Location: " .. self.teleport.currentLocation)
        
        -- Update player dropdown
        local players = self:GetPlayerNames()
        -- Note: Rayfield doesn't have dynamic dropdown update, so we'll skip this for now
    end
    
    -- Update Dashboard tab
    if self.ui and self.ui.dashboard then
        local sessionStats = self.dashboard:GetSessionStats()
        local locationStats = self.dashboard:GetLocationStats()
        local bestTimes = self.dashboard:GetBestFishingTimes(3)
        
        self.ui.dashboard.sessionLabel:Set("Session Time: " .. sessionStats.formattedDuration)
        self.ui.dashboard.fishCountLabel:Set("Fish Caught: " .. Helpers.FormatNumber(sessionStats.fishCount))
        self.ui.dashboard.rareCountLabel:Set("Rare Fish: " .. Helpers.FormatNumber(sessionStats.rareCount))
        self.ui.dashboard.fishPerHourLabel:Set(string.format("Fish/Hour: %.1f", sessionStats.fishPerHour))
        self.ui.dashboard.currentLocationLabel:Set("Location: " .. sessionStats.currentLocation)
        
        -- Location stats summary
        if #locationStats > 0 then
            local best = locationStats[1]
            self.ui.dashboard.locationStatsLabel:Set(string.format("Best Location: %s (%.1f%% rare rate)", 
                                                    best.location, best.efficiency))
        end
        
        -- Time analytics summary
        if #bestTimes > 0 then
            local best = bestTimes[1]
            self.ui.dashboard.timeAnalyticsLabel:Set(string.format("Best Time: %s (%.1f%% rare rate)", 
                                                    best.formattedHour, best.efficiency))
        end
    end
end

function ITU_IKAN:GetLocationNames()
    local names = {}
    for name, _ in pairs(self.settings.Locations) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function ITU_IKAN:GetPlayerNames()
    local names = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    table.sort(names)
    table.insert(names, 1, "None") -- Add "None" option at the beginning
    return names
end

function ITU_IKAN:EmergencyStop()
    -- Stop all systems
    self.autoFishing:Stop()
    self.playerMods:Reset()
    
    -- Show notification
    Helpers.Notify("ITU IKAN", "🚨 EMERGENCY STOP - All systems disabled")
    
    -- Optionally destroy UI
    if self.window then
        self.window:Destroy()
    end
end

function ITU_IKAN:Destroy()
    -- Stop update loop
    if self.updateLoop then
        task.cancel(self.updateLoop)
    end
    
    -- Destroy modules
    if self.autoFishing then self.autoFishing:Destroy() end
    if self.rodFix then self.rodFix:Destroy() end
    if self.teleport then self.teleport:Destroy() end
    if self.playerMods then self.playerMods:Destroy() end
    if self.dashboard then self.dashboard:Destroy() end
    if self.autoSell then self.autoSell:Destroy() end
    if self.antiAFK then self.antiAFK:Destroy() end
    
    -- Destroy UI
    if self.window then
        self.window:Destroy()
    end
    
    setmetatable(self, nil)
end

-- Initialize and start
local ituIkan = ITU_IKAN.new()

-- Global API
_G.ITU_IKAN = {
    instance = ituIkan,
    
    -- Quick access functions
    StartFishing = function() return ituIkan.autoFishing:Start() end,
    StopFishing = function() return ituIkan.autoFishing:Stop() end,
    ToggleFishing = function() return ituIkan.autoFishing:Toggle() end,
    
    TeleportTo = function(location) return ituIkan.teleport:TeleportToLocation(location) end,
    
    GetStats = function() return ituIkan.dashboard:GetSessionStats() end,
    ResetStats = function() return ituIkan.dashboard:Reset() end,
    
    -- Auto Sell functions
    ToggleAutoSell = function() return ituIkan.autoSell:Toggle() end,
    SellNow = function() return ituIkan.autoSell:ManualSell() end,
    
    -- Anti-AFK functions
    ToggleAntiAFK = function() return ituIkan.antiAFK:Toggle() end,
    
    EmergencyStop = function() return ituIkan:EmergencyStop() end,
    
    -- Module access
    AutoFishing = ituIkan.autoFishing,
    RodFix = ituIkan.rodFix,
    Teleport = ituIkan.teleport,
    PlayerMods = ituIkan.playerMods,
    Dashboard = ituIkan.dashboard,
    AutoSell = ituIkan.autoSell,
    AntiAFK = ituIkan.antiAFK,
    Settings = ituIkan.settings
}

Helpers.Notify("ITU IKAN", "🎣 Fishing Bot loaded successfully!")
print("🎣 ITU IKAN FISHING BOT by YohanSevta - Ready!")
print("📘 Use _G.ITU_IKAN for API access")

return ituIkan
