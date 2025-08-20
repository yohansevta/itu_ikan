-- main_modular_fixed.lua
-- ITU IKAN FISHING BOT - Self-contained Modular Version
-- by YohanSevta - Semua fitur dari fishit.lua dalam 1 file self-contained

print("🎣 ITU IKAN FISHING BOT - Self-contained Modular Loading...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Client check
if not RunService:IsClient() then
    warn("ITU IKAN: must run as LocalScript on client. Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("ITU IKAN: LocalPlayer missing. Run as LocalScript while in game.")
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

-- Load Rayfield UI
print("🔄 Loading Rayfield UI...")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
print("✅ Rayfield loaded!")

-- Utility functions
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
    print("🔔 " .. title .. ": " .. text)
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("ITU IKAN Error:", result)
    end
    return success, result
end

-- Remote resolver
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

-- Resolve remotes
local equipRemote = ResolveRemote("RE/EquipToolFromHotbar")
local catchRemote = ResolveRemote("RF/CatchFish")
local autoFishStateRemote = ResolveRemote("RF/UpdateAutoFishingState")
local castRemote = ResolveRemote("RF/CastRod")
local sellRemote = ResolveRemote("RF/SellFish")

-- Global config
local Config = {
    autoFishingEnabled = false,
    fishingMode = "smart",
    autoRecastDelay = 0.4,
    safeCastChance = 85,
    perfectCastChance = 15,
    rodFixEnabled = true,
    walkSpeed = 16,
    jumpPower = 50,
    currentLocation = "Unknown"
}

-- Location data
local Locations = {
    ["Spawn"] = Vector3.new(447, 150, 229),
    ["Moosewood"] = Vector3.new(389, 135, 1037),
    ["Roslit Bay"] = Vector3.new(-1505, 130, 688),
    ["Snowcap Island"] = Vector3.new(2649, 140, 2522),
    ["Mushgrove Swamp"] = Vector3.new(2501, 125, -721),
    ["The Depths"] = Vector3.new(980, -815, 1260),
    ["Vertigo"] = Vector3.new(-113, -515, 1040),
    ["Sunstone Island"] = Vector3.new(-943, 125, -1123),
    ["Forsaken Shores"] = Vector3.new(-2895, 125, 1716),
    ["Ancient Isles"] = Vector3.new(5906, 125, 4829),
    ["Coral Reefs"] = Vector3.new(-3018, 125, 3042),
    ["Stingray Shores"] = Vector3.new(-740, 130, 1567),
    ["Kohana Volcano"] = Vector3.new(-1888, 139, 329)
}

-- ===============================
-- ROD FIX MODULE
-- ===============================
local RodFix = {
    enabled = false,
    lastFixTime = 0,
    connection = nil
}

function RodFix.fixOrientation()
    if not RodFix.enabled then return end
    
    local now = tick()
    if now - RodFix.lastFixTime < 0.1 then return end
    RodFix.lastFixTime = now
    
    safeCall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local equippedTool = character:FindFirstChildOfClass("Tool")
        if not equippedTool then return end
        
        local isRod = equippedTool.Name:lower():find("rod") or 
                      equippedTool:FindFirstChild("Rod") or
                      equippedTool:FindFirstChild("Handle")
        if not isRod then return end
        
        local rightArm = character:FindFirstChild("Right Arm")
        if rightArm then
            local rightGrip = rightArm:FindFirstChild("RightGrip")
            if rightGrip and rightGrip:IsA("Motor6D") then
                rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                rightGrip.C1 = CFrame.new(0, 0, 0)
            end
        end
    end)
end

function RodFix.enable()
    RodFix.enabled = true
    Config.rodFixEnabled = true
    
    RodFix.connection = RunService.Heartbeat:Connect(function()
        RodFix.fixOrientation()
    end)
    
    notify("Rod Fix", "🔧 Rod orientation fix enabled!")
end

function RodFix.disable()
    RodFix.enabled = false
    Config.rodFixEnabled = false
    
    if RodFix.connection then
        RodFix.connection:Disconnect()
        RodFix.connection = nil
    end
    
    notify("Rod Fix", "🔧 Rod fix disabled")
end

-- ===============================
-- AUTO FISHING MODULE
-- ===============================
local AutoFishing = {
    isRunning = false,
    currentState = "idle",
    stats = {
        totalCasts = 0,
        successfulCatches = 0,
        sessionStart = tick()
    }
}

function AutoFishing.getRealisticTiming(action)
    local timings = {
        charging = math.random(8, 15) / 10,
        casting = math.random(3, 7) / 10,
        waiting = math.random(15, 35) / 10,
        reeling = math.random(5, 12) / 10
    }
    return timings[action] or 1
end

function AutoFishing.safeInvoke(remote, ...)
    if not remote then return false end
    return safeCall(function(...) 
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        else
            remote:FireServer(...)
            return true
        end
    end, ...)
end

function AutoFishing.fishingCycle()
    if not AutoFishing.isRunning then return end
    
    AutoFishing.currentState = "charging"
    AutoFishing.stats.totalCasts = AutoFishing.stats.totalCasts + 1
    
    -- Equip rod
    if equipRemote then
        AutoFishing.safeInvoke(equipRemote, 1)
    end
    wait(AutoFishing.getRealisticTiming("charging"))
    
    -- Charge rod
    if autoFishStateRemote then
        local chargeTime = workspace:GetServerTimeNow()
        AutoFishing.safeInvoke(autoFishStateRemote, chargeTime)
    end
    wait(AutoFishing.getRealisticTiming("charging"))
    
    -- Cast rod
    AutoFishing.currentState = "casting"
    local x, y = 0, 0
    
    if Config.fishingMode == "smart" then
        local usePerfect = math.random(1, 100) <= Config.perfectCastChance
        if usePerfect then
            x, y = -1.238, 0.969
        else
            local useSafe = math.random(1, 100) <= Config.safeCastChance
            if useSafe then
                x = math.random(-800, 800) / 1000
                y = math.random(600, 1000) / 1000
            else
                x = math.random(-1000, 1000) / 1000
                y = math.random(0, 1000) / 1000
            end
        end
    elseif Config.fishingMode == "secure" then
        x = math.random(-600, 600) / 1000
        y = math.random(700, 900) / 1000
    elseif Config.fishingMode == "fast" then
        local usePerfect = math.random(1, 100) <= 35
        if usePerfect then
            x, y = -1.238, 0.969
        else
            x = math.random(-1000, 1000) / 1000
            y = math.random(0, 1000) / 1000
        end
    end
    
    if castRemote then
        local success = AutoFishing.safeInvoke(castRemote, x, y)
        if success then
            notify("Fishing", "🎣 Cast successful! Mode: " .. Config.fishingMode)
        end
    end
    
    wait(AutoFishing.getRealisticTiming("casting"))
    
    -- Wait for fish
    AutoFishing.currentState = "waiting"
    wait(AutoFishing.getRealisticTiming("waiting"))
    
    -- Catch fish
    AutoFishing.currentState = "reeling"
    if catchRemote then
        local success = AutoFishing.safeInvoke(catchRemote)
        if success then
            AutoFishing.stats.successfulCatches = AutoFishing.stats.successfulCatches + 1
            notify("Fishing", "✅ Fish caught!")
        end
    end
    
    wait(AutoFishing.getRealisticTiming("reeling"))
    
    AutoFishing.currentState = "idle"
    wait(Config.autoRecastDelay)
end

function AutoFishing.start()
    if AutoFishing.isRunning then
        notify("Auto Fishing", "⚠️ Already running!")
        return
    end
    
    AutoFishing.isRunning = true
    Config.autoFishingEnabled = true
    
    notify("Auto Fishing", "🎣 Started! Mode: " .. Config.fishingMode)
    
    spawn(function()
        while AutoFishing.isRunning and Config.autoFishingEnabled do
            AutoFishing.fishingCycle()
            wait(0.1)
        end
    end)
end

function AutoFishing.stop()
    AutoFishing.isRunning = false
    Config.autoFishingEnabled = false
    AutoFishing.currentState = "idle"
    
    notify("Auto Fishing", "🛑 Stopped")
end

-- ===============================
-- TELEPORT MODULE
-- ===============================
local Teleport = {}

function Teleport.to(locationName)
    local targetPos = Locations[locationName]
    if not targetPos then
        notify("Teleport", "❌ Location not found: " .. locationName)
        return
    end
    
    safeCall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        humanoidRootPart.CFrame = CFrame.new(targetPos)
        notify("Teleport", "📍 Teleported to " .. locationName)
        Config.currentLocation = locationName
    end)
end

function Teleport.getLocationList()
    local list = {}
    for name, _ in pairs(Locations) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- ===============================
-- PLAYER MODULE
-- ===============================
local Player = {}

function Player.setWalkSpeed(speed)
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speed
                Config.walkSpeed = speed
                notify("Player", "🏃 Speed set to " .. speed)
            end
        end
    end)
end

function Player.setJumpPower(power)
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpPower = power
                Config.jumpPower = power
                notify("Player", "🦘 Jump set to " .. power)
            end
        end
    end)
end

-- ===============================
-- AUTO SELL MODULE
-- ===============================
local AutoSell = {
    isRunning = false
}

function AutoSell.sellNow()
    if sellRemote then
        local success = safeCall(function() sellRemote:FireServer("all") end)
        if success then
            notify("Auto Sell", "💰 Fish sold!")
        else
            notify("Auto Sell", "❌ Failed to sell")
        end
    else
        notify("Auto Sell", "❌ Sell remote not found")
    end
end

function AutoSell.start()
    AutoSell.isRunning = true
    notify("Auto Sell", "💰 Auto sell enabled")
end

function AutoSell.stop()
    AutoSell.isRunning = false
    notify("Auto Sell", "💰 Auto sell disabled")
end

-- ===============================
-- MAIN ITU IKAN CLASS
-- ===============================
local ITU_IKAN = {
    loaded = true,
    version = "2.0 Self-Contained Modular",
    config = Config,
    Window = nil,
    connections = {}
}

-- Create UI
function ITU_IKAN.createUI()
    print("🎮 Creating Self-contained Modular UI...")
    
    ITU_IKAN.Window = Rayfield:CreateWindow({
        Name = "🎣 ITU IKAN - Self-contained Modular",
        LoadingTitle = "ITU IKAN Loading...",
        LoadingSubtitle = "by YohanSevta - Modular dari fishit.lua",
        Theme = "Ocean",
        DisableRayfieldPrompts = false,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "ITU_IKAN_SelfContained",
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
            if Value then
                AutoFishing.start()
            else
                AutoFishing.stop()
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
        CurrentValue = false,
        Flag = "RodFix",
        Callback = function(Value)
            if Value then
                RodFix.enable()
            else
                RodFix.disable()
            end
        end,
    })
    
    -- Teleport Tab
    local TeleportTab = ITU_IKAN.Window:CreateTab("📍 Teleport", 4483362458)
    
    local TeleportSection = TeleportTab:CreateSection("Fishing Locations")
    
    local locations = Teleport.getLocationList()
    
    local LocationDropdown = TeleportTab:CreateDropdown({
        Name = "🏝️ Select Location",
        Options = locations,
        CurrentOption = locations[1],
        Flag = "TeleportLocation",
        Callback = function(Value)
            Teleport.to(Value)
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
            Player.setWalkSpeed(Value)
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
            Player.setJumpPower(Value)
        end,
    })
    
    -- Auto Sell Tab
    local SellTab = ITU_IKAN.Window:CreateTab("💰 Auto Sell", 4483362458)
    
    local SellSection = SellTab:CreateSection("Auto Sell Settings")
    
    local ManualSellButton = SellTab:CreateButton({
        Name = "💸 Manual Sell",
        Callback = function()
            AutoSell.sellNow()
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
                local sessionTime = tick() - AutoFishing.stats.sessionStart
                local hours = math.floor(sessionTime / 3600)
                local minutes = math.floor((sessionTime % 3600) / 60)
                local seconds = math.floor(sessionTime % 60)
                
                local statsText = string.format(
                    "🎣 Total Casts: %d\n" ..
                    "✅ Successful Catches: %d\n" ..
                    "⏱️ Session: %02d:%02d:%02d\n" ..
                    "🎯 Current State: %s\n" ..
                    "📍 Location: %s\n" ..
                    "🎮 Fishing Mode: %s",
                    AutoFishing.stats.totalCasts,
                    AutoFishing.stats.successfulCatches,
                    hours, minutes, seconds,
                    AutoFishing.currentState,
                    Config.currentLocation,
                    Config.fishingMode
                )
                StatsLabel:Set(statsText)
            end
        end
    end)
    
    -- Settings Tab
    local SettingsTab = ITU_IKAN.Window:CreateTab("⚙️ Settings", 4483362458)
    
    local SettingsSection = SettingsTab:CreateSection("Bot Settings")
    
    local TestButton = SettingsTab:CreateButton({
        Name = "🧪 Test Notification",
        Callback = function()
            notify("Test", "Self-contained modular system working! 🎣")
        end,
    })
    
    local InfoSection = SettingsTab:CreateSection("Information")
    
    local InfoLabel = SettingsTab:CreateLabel(
        "🎣 ITU IKAN " .. ITU_IKAN.version .. "\n" ..
        "👨‍💻 Created by YohanSevta\n" ..
        "📁 Self-contained modular dari fishit.lua\n" ..
        "🎮 All modules in one file!"
    )
    
    print("✅ Self-contained Modular UI created successfully!")
end

-- Cleanup
function ITU_IKAN.cleanup()
    print("🧹 Cleaning up ITU IKAN Self-contained...")
    
    AutoFishing.stop()
    RodFix.disable()
    AutoSell.stop()
    
    for name, connection in pairs(ITU_IKAN.connections) do
        if connection and connection.Disconnect then
            pcall(function() connection:Disconnect() end)
        end
    end
    
    ITU_IKAN.loaded = false
    print("✅ ITU IKAN Self-contained cleaned up")
end

-- Initialize
function ITU_IKAN.init()
    notify("ITU IKAN", "Initializing self-contained modular system...")
    ITU_IKAN.createUI()
    notify("ITU IKAN", "Self-contained modular system ready! 🎣")
end

-- Store globally
_G.ITU_IKAN_MODULAR = ITU_IKAN

-- Initialize
ITU_IKAN.init()

-- Success notification
notify("ITU IKAN", "Self-contained modular loaded! UI should appear! 🎉")

print("✅ ========================================")
print("   ITU IKAN SELF-CONTAINED MODULAR READY!")
print("========================================") 
print("📘 Access: _G.ITU_IKAN_MODULAR")
print("🎮 UI: Rayfield interface should be visible")
print("📁 Structure: Self-contained modular")
print("🔧 Features: All from fishit.lua")
print("✅ Ready for fishing!")

return ITU_IKAN
