-- standalone.lua
-- ITU IKAN FISHING BOT - Standalone Version
-- All-in-one script dengan UI Rayfield

print("🎣 Loading ITU IKAN FISHING BOT - Standalone Version")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Check if running on client
if not RunService:IsClient() then
    warn("ITU IKAN: Must run as LocalScript on client")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("ITU IKAN: LocalPlayer missing. Run while in game.")
    return
end

-- Check if already loaded
if _G.ITU_IKAN and _G.ITU_IKAN.loaded then
    warn("⚠️ ITU IKAN already loaded! Reloading...")
    if _G.ITU_IKAN.cleanup then
        _G.ITU_IKAN.cleanup()
    end
end

-- Load Rayfield UI
print("🔄 Loading Rayfield UI...")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

if not Rayfield then
    error("❌ Failed to load Rayfield UI")
end

-- ITU IKAN Main Class
local ITU_IKAN = {
    loaded = true,
    autoFishingEnabled = false,
    rodFixEnabled = false,
    autoSellEnabled = false,
    antiAFKEnabled = false,
    playerModsEnabled = false,
    
    -- Stats
    fishCaught = 0,
    startTime = tick(),
    
    -- Settings
    settings = {
        fishingMode = "smart",
        walkSpeed = 16,
        jumpPower = 50,
        sellThreshold = 75,
        floatHeight = 20
    },
    
    -- Connections
    connections = {},
    
    -- UI References
    Window = nil,
    Notifications = {}
}

-- Utility Functions
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("ITU IKAN Error:", result)
    end
    return success, result
end

local function notify(title, content, duration)
    if ITU_IKAN.Window then
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3,
            Image = 4483362458
        })
    end
    print("🔔 " .. title .. ": " .. content)
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Auto Fishing Module
local AutoFishing = {}

function AutoFishing.start()
    ITU_IKAN.autoFishingEnabled = true
    notify("Auto Fishing", "Started fishing bot!", 3)
    
    -- Simple fishing logic
    ITU_IKAN.connections.autoFishing = RunService.Heartbeat:Connect(function()
        if not ITU_IKAN.autoFishingEnabled then return end
        
        safeCall(function()
            -- Basic fishing detection and casting
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local tool = character:FindFirstChildOfClass("Tool")
                
                if tool and humanoid then
                    -- Simple fishing logic here
                    -- This would be expanded with actual fishing game logic
                    wait(1) -- Prevent spam
                end
            end
        end)
    end)
end

function AutoFishing.stop()
    ITU_IKAN.autoFishingEnabled = false
    if ITU_IKAN.connections.autoFishing then
        ITU_IKAN.connections.autoFishing:Disconnect()
        ITU_IKAN.connections.autoFishing = nil
    end
    notify("Auto Fishing", "Stopped fishing bot", 3)
end

-- Player Mods Module
local PlayerMods = {}

function PlayerMods.setWalkSpeed(speed)
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speed
                ITU_IKAN.settings.walkSpeed = speed
                notify("Player Mods", "Walk speed set to " .. speed, 2)
            end
        end
    end)
end

function PlayerMods.setJumpPower(power)
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpPower = power
                ITU_IKAN.settings.jumpPower = power
                notify("Player Mods", "Jump power set to " .. power, 2)
            end
        end
    end)
end

function PlayerMods.enableFloat()
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = rootPart
                
                ITU_IKAN.floatBody = bodyVelocity
                notify("Player Mods", "Float mode enabled", 2)
            end
        end
    end)
end

function PlayerMods.disableFloat()
    if ITU_IKAN.floatBody then
        ITU_IKAN.floatBody:Destroy()
        ITU_IKAN.floatBody = nil
        notify("Player Mods", "Float mode disabled", 2)
    end
end

-- Teleport Module
local Teleport = {}
local fishingLocations = {
    "🏝️ Spawn",
    "🏝️ Moosewood",
    "🏝️ Roslit Bay", 
    "🏝️ Snowcap Island",
    "🏝️ Mushgrove Swamp",
    "🏝️ The Depths",
    "🏝️ Vertigo",
    "🏝️ Sunstone Island",
    "🏝️ Forsaken Shores",
    "🏝️ Ancient Isles"
}

function Teleport.to(locationName)
    safeCall(function()
        -- This would contain actual teleportation logic for the specific game
        notify("Teleport", "Teleporting to " .. locationName, 3)
        -- Placeholder - would implement game-specific teleport logic
    end)
end

-- Statistics Module
local Stats = {}

function Stats.update()
    local sessionTime = tick() - ITU_IKAN.startTime
    local fishPerHour = ITU_IKAN.fishCaught > 0 and (ITU_IKAN.fishCaught / (sessionTime / 3600)) or 0
    
    return {
        fishCaught = ITU_IKAN.fishCaught,
        sessionTime = formatTime(sessionTime),
        fishPerHour = math.floor(fishPerHour * 10) / 10
    }
end

-- Anti-AFK Module
local AntiAFK = {}

function AntiAFK.start()
    ITU_IKAN.antiAFKEnabled = true
    
    ITU_IKAN.connections.antiAFK = RunService.Heartbeat:Connect(function()
        if not ITU_IKAN.antiAFKEnabled then return end
        
        -- Simple anti-AFK movement every 30 seconds
        if tick() % 30 < 0.1 then
            safeCall(function()
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid:Move(Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)))
                        wait(0.1)
                        humanoid:Move(Vector3.new(0, 0, 0))
                    end
                end
            end)
        end
    end)
    
    notify("Anti-AFK", "Anti-AFK system started", 3)
end

function AntiAFK.stop()
    ITU_IKAN.antiAFKEnabled = false
    if ITU_IKAN.connections.antiAFK then
        ITU_IKAN.connections.antiAFK:Disconnect()
        ITU_IKAN.connections.antiAFK = nil
    end
    notify("Anti-AFK", "Anti-AFK system stopped", 3)
end

-- Create UI
print("🎮 Creating UI...")

ITU_IKAN.Window = Rayfield:CreateWindow({
    Name = "🎣 ITU IKAN FISHING BOT v2.0",
    LoadingTitle = "ITU IKAN Loading...",
    LoadingSubtitle = "by YohanSevta - Standalone Version",
    Theme = "Ocean",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ITU_IKAN",
        FileName = "config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- Auto Fishing Tab
local FishingTab = ITU_IKAN.Window:CreateTab("🎣 Auto Fishing", 4483362458)

local FishingSection = FishingTab:CreateSection("Fishing Controls")

local FishingToggle = FishingTab:CreateToggle({
    Name = "Enable Auto Fishing",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            AutoFishing.start()
        else
            AutoFishing.stop()
        end
    end,
})

local ModeDropdown = FishingTab:CreateDropdown({
    Name = "Fishing Mode",
    Options = {"Smart", "Secure", "Fast"},
    CurrentOption = "Smart",
    Callback = function(Value)
        ITU_IKAN.settings.fishingMode = Value:lower()
        notify("Settings", "Fishing mode set to " .. Value, 2)
    end,
})

-- Player Mods Tab
local PlayerTab = ITU_IKAN.Window:CreateTab("👤 Player Mods", 4483362458)

local PlayerSection = PlayerTab:CreateSection("Movement Settings")

local SpeedSlider = PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        PlayerMods.setWalkSpeed(Value)
    end,
})

local JumpSlider = PlayerTab:CreateSlider({
    Name = "Jump Power", 
    Range = {50, 300},
    Increment = 5,
    Suffix = "Power",
    CurrentValue = 50,
    Callback = function(Value)
        PlayerMods.setJumpPower(Value)
    end,
})

local FloatToggle = PlayerTab:CreateToggle({
    Name = "Float Mode",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            PlayerMods.enableFloat()
        else
            PlayerMods.disableFloat()
        end
    end,
})

-- Teleport Tab
local TeleportTab = ITU_IKAN.Window:CreateTab("📍 Teleport", 4483362458)

local TeleportSection = TeleportTab:CreateSection("Fishing Locations")

local LocationDropdown = TeleportTab:CreateDropdown({
    Name = "Select Location",
    Options = fishingLocations,
    CurrentOption = fishingLocations[1],
    Callback = function(Value)
        Teleport.to(Value)
    end,
})

-- Stats Tab
local StatsTab = ITU_IKAN.Window:CreateTab("📊 Statistics", 4483362458)

local StatsSection = StatsTab:CreateSection("Session Statistics")

local StatsLabel = StatsTab:CreateLabel("Initializing stats...")

-- Update stats every 5 seconds
spawn(function()
    while ITU_IKAN.loaded do
        wait(5)
        if StatsLabel then
            local stats = Stats.update()
            StatsLabel:Set(string.format(
                "🎣 Fish Caught: %d\n⏱️ Session Time: %s\n📈 Fish/Hour: %.1f",
                stats.fishCaught,
                stats.sessionTime,
                stats.fishPerHour
            ))
        end
    end
end)

-- Settings Tab
local SettingsTab = ITU_IKAN.Window:CreateTab("⚙️ Settings", 4483362458)

local SettingsSection = SettingsTab:CreateSection("General Settings")

local AntiAFKToggle = SettingsTab:CreateToggle({
    Name = "Anti-AFK System",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            AntiAFK.start()
        else
            AntiAFK.stop()
        end
    end,
})

local EmergencyButton = SettingsTab:CreateButton({
    Name = "🚨 Emergency Stop",
    Callback = function()
        ITU_IKAN.cleanup()
        notify("Emergency", "All systems stopped!", 5)
    end,
})

-- Global Functions
function ITU_IKAN.cleanup()
    print("🧹 Cleaning up ITU IKAN...")
    
    -- Stop all systems
    ITU_IKAN.autoFishingEnabled = false
    ITU_IKAN.antiAFKEnabled = false
    
    -- Disconnect all connections
    for name, connection in pairs(ITU_IKAN.connections) do
        if connection and connection.Disconnect then
            pcall(function() connection:Disconnect() end)
        end
    end
    ITU_IKAN.connections = {}
    
    -- Remove float body
    if ITU_IKAN.floatBody then
        pcall(function() ITU_IKAN.floatBody:Destroy() end)
        ITU_IKAN.floatBody = nil
    end
    
    -- Clear UI reference (don't destroy Rayfield window)
    ITU_IKAN.Window = nil
    
    ITU_IKAN.loaded = false
    print("✅ ITU IKAN cleaned up")
end

function ITU_IKAN.reload()
    ITU_IKAN.cleanup()
    wait(1)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/itu_ikan/main/standalone.lua"))()
end

-- Store globally
_G.ITU_IKAN = ITU_IKAN

-- Final setup
notify("ITU IKAN", "Successfully loaded! UI is ready.", 5)
print("✅ ITU IKAN FISHING BOT loaded successfully!")
print("📘 Access via _G.ITU_IKAN")
print("🎮 UI should be visible now")
print("🔧 Use _G.ITU_IKAN.cleanup() to stop everything")

return ITU_IKAN
