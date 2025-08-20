-- FishingAI.lua
-- ITU IKAN Auto Fishing Module (extracted dari orifishit.lua original)
-- Includes: Smart/Secure Cycles, Rod Fix, Animation Monitoring, Security System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local AutoFishing = {}

-- Private variables
local config = nil
local remotes = nil
local notify = nil
local sessionId = 0
local autoModeSessionId = 0

-- Rod Fix System (extracted from original)
local RodFix = {
    enabled = true,
    lastFixTime = 0,
    isCharging = false,
    chargingConnection = nil
}

-- Animation Monitor (extracted from original)
local AnimationMonitor = {
    isMonitoring = false,
    currentState = "idle",
    lastAnimationTime = 0,
    animationSequence = {},
    fishingSuccess = false
}

-- Security System (extracted from original)
local Security = { 
    actionsThisMinute = 0, 
    lastMinuteReset = tick(), 
    isInCooldown = false, 
    suspicion = 0 
}

-- Safe remote invocation (from original)
local function safeInvoke(remote, ...)
    if not remote then return false, "nil_remote" end
    if remote:IsA("RemoteFunction") then
        return pcall(function(...) return remote:InvokeServer(...) end, ...)
    else
        return pcall(function(...) remote:FireServer(...) return true end, ...)
    end
end

-- Get realistic timing (from original)
local function GetRealisticTiming(phase)
    local timings = {
        charging = {min = 0.8, max = 1.5},    -- Rod charging time
        casting = {min = 0.2, max = 0.4},     -- Cast animation
        waiting = {min = 2.0, max = 4.0},     -- Wait for fish
        reeling = {min = 1.0, max = 2.5},     -- Reel animation
        holding = {min = 0.5, max = 1.0}      -- Hold fish animation
    }
    
    local timing = timings[phase] or {min = 0.5, max = 1.0}
    return timing.min + math.random() * (timing.max - timing.min)
end

-- Get Server Time (from original)
local function GetServerTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

-- Rod Orientation Fix (extracted from original)
local function FixRodOrientation()
    if not RodFix.enabled then return end
    
    local now = tick()
    if now - RodFix.lastFixTime < 0.05 then return end -- Faster throttle for charging phase
    RodFix.lastFixTime = now
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Pastikan ini fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return end
    
    -- Method 1: Fix Motor6D during charging phase (paling efektif)
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            -- Orientasi normal untuk rod menghadap depan SELAMA charging
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
            return
        end
    end
    
    -- Method 2: Fix Tool Grip Value (untuk tools dengan custom grip)
    local handle = equippedTool:FindFirstChild("Handle")
    if handle then
        local toolGrip = equippedTool:FindFirstChild("Grip")
        if toolGrip and toolGrip:IsA("CFrameValue") then
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            return
        end
        
        -- Jika tidak ada grip value, buat yang baru
        if not toolGrip then
            toolGrip = Instance.new("CFrameValue")
            toolGrip.Name = "Grip"
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            toolGrip.Parent = equippedTool
        end
    end
end

-- Security functions (from original)
local function inCooldown()
    local now = tick()
    if now - Security.lastMinuteReset > 60 then
        Security.actionsThisMinute = 0
        Security.lastMinuteReset = now
    end
    if Security.actionsThisMinute >= (config.secure_max_actions_per_minute or 12000000) then
        Security.isInCooldown = true
        return true
    end
    return Security.isInCooldown
end

local function secureInvoke(remote, ...)
    if inCooldown() then return false, "cooldown" end
    Security.actionsThisMinute = Security.actionsThisMinute + 1
    task.wait(0.01 + math.random() * 0.05)
    local ok, res = safeInvoke(remote, ...)
    if not ok then
        Security.suspicion = Security.suspicion + 1
        if Security.suspicion > 8 then
            Security.isInCooldown = true
            task.spawn(function()
                if notify then notify("Security", "Entering cooldown due to repeated errors") end
                task.wait(config.secure_detection_cooldown or 5)
                Security.suspicion = 0
                Security.isInCooldown = false
            end)
        end
    end
    return ok, res
end

-- Location detection (from original)
local function DetectCurrentLocation()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return "Unknown"
    end
    
    local pos = LocalPlayer.Character.HumanoidRootPart.Position
    
    -- Location detection based on position ranges
    if pos.Z > 4500 then
        return "Crater Island"
    elseif pos.Z > 2500 then
        return "Stingray Shores"
    elseif pos.Z > 1500 then
        return "Esoteric Depths"
    elseif pos.Z > 700 then
        return "Kohana"
    elseif pos.Z > 3000 and pos.X < -2000 then
        return "Tropical Grove"
    elseif pos.Z > 1800 and pos.X < -3000 then
        return "Coral Reefs"
    elseif pos.X < -3500 then
        return "Lost Isle"
    elseif pos.X < -1400 and pos.Z > 1500 then
        return "Weather Machine"
    elseif pos.Z < 500 and pos.X < -500 then
        return "Kohana Volcano"
    else
        return "Unknown Area"
    end
end

-- Smart Cycle (extracted from original DoSmartCycle)
local function DoSmartCycle()
    AnimationMonitor.fishingSuccess = false
    AnimationMonitor.currentState = "starting"
    
    -- Phase 1: Equip and prepare
    FixRodOrientation() -- Fix rod orientation at start
    if remotes.equip then 
        pcall(function() remotes.equip:FireServer(1) end)
        task.wait(GetRealisticTiming("charging"))
    end
    
    -- Phase 2: Charge rod (with animation-aware timing)
    AnimationMonitor.currentState = "charging"
    FixRodOrientation() -- Fix during charging phase (critical!)
    
    local usePerfect = math.random(1,100) <= (config.safeModeChance or 70)
    local timestamp = usePerfect and GetServerTime() or GetServerTime() + math.random()*0.5
    
    if remotes.rod and remotes.rod:IsA("RemoteFunction") then 
        pcall(function() remotes.rod:InvokeServer(timestamp) end)
    end
    
    -- Fix orientation continuously during charging
    local chargeStart = tick()
    local chargeDuration = GetRealisticTiming("charging")
    while tick() - chargeStart < chargeDuration do
        FixRodOrientation() -- Keep fixing during charge animation
        task.wait(0.02) -- Very frequent fixes during charging
    end
    
    -- Phase 3: Cast (mini-game simulation)
    AnimationMonitor.currentState = "casting"
    FixRodOrientation() -- Fix before casting
    
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if remotes.miniGame and remotes.miniGame:IsA("RemoteFunction") then 
        pcall(function() remotes.miniGame:InvokeServer(x,y) end)
    end
    
    -- Wait for cast animation
    task.wait(GetRealisticTiming("casting"))
    
    -- Phase 4: Wait for fish (realistic waiting time)
    AnimationMonitor.currentState = "waiting"
    task.wait(GetRealisticTiming("waiting"))
    
    -- Phase 5: Complete fishing
    AnimationMonitor.currentState = "completing"
    FixRodOrientation() -- Fix before completion
    
    if remotes.finish then 
        pcall(function() remotes.finish:FireServer() end)
    end
    
    -- Wait for completion and fish catch animations
    task.wait(GetRealisticTiming("reeling"))
    
    -- Check if fish was caught via animation or simulate
    if not AnimationMonitor.fishingSuccess and not remotes.fishCaught then
        -- Fallback: Use location-based simulation
        local fishByLocation = {
            ["Coral Reefs"] = {"Hawks Turtle", "Blue Lobster", "Greenbee Grouper", "Starjam Tang", "Domino Damsel", "Panther Grouper", "Scissortail Dartfish", "White Clownfish", "Maze Angelfish", "Tricolore Butterfly", "Orangy Goby", "Specked Butterfly", "Corazon Damse"},
            ["Stingray Shores"] = {"Dotted Stingray", "Yellowfin Tuna", "Unicorn Tang", "Dorhey Tang", "Darwin Clownfish", "Korean Angelfish", "Flame Angelfish", "Yello Damselfish", "Copperband Butterfly", "Strawberry Dotty", "Azure Damsel", "Clownfish"},
            ["Ocean"] = {"Hammerhead Shark", "Manta Ray", "Chrome Tuna", "Moorish Idol", "Cow Clownfish", "Candy Butterfly", "Jewel Tang", "Vintage Damsel", "Tricolore Butterfly", "Skunk Tilefish", "Yellowstate Angelfish", "Vintage Blue Tang"},
            ["Esoteric Depths"] = {"Abyss Seahorse", "Magic Tang", "Enchanted Angelfish", "Astra Damsel", "Charmed Tang", "Coal Tang", "Ash Basslet"},
            ["Kohana Volcano"] = {"Blueflame Ray", "Lavafin Tuna", "Firecoal Damsel", "Magma Goby", "Volcanic Basslet"},
            ["Kohana"] = {"Prismy Seahorse", "Loggerhead Turtle", "Lobster", "Bumblebee Grouper", "Longnose Butterfly", "Sushi Cardinal", "Kau Cardinal", "Fire Goby", "Banded Butterfly", "Shrimp Goby", "Boa Angelfish", "Jennifer Dottyback", "Reef Chromis"}
        }
        
        local currentLocation = DetectCurrentLocation()
        local locationFish = fishByLocation[currentLocation] or fishByLocation["Ocean"]
        local randomFish = locationFish[math.random(1, #locationFish)]
        print("[Smart Cycle] Simulated catch:", randomFish, "at", currentLocation)
    end
    
    AnimationMonitor.currentState = "idle"
end

-- Secure Cycle (extracted from original DoSecureCycle)
local function DoSecureCycle()
    if inCooldown() then task.wait(1); return end
    
    -- Equip rod first
    if remotes.equip then 
        local ok = pcall(function() remotes.equip:FireServer(1) end)
        if not ok then print("[Secure Mode] Failed to equip") end
    end
    
    -- Safe mode logic: random between perfect and normal cast
    local usePerfect = math.random(1,100) <= (config.safeModeChance or 70)
    
    -- Charge rod with proper timing
    local timestamp = usePerfect and 9999999999 or (tick() + math.random())
    if remotes.rod then
        local ok = pcall(function() remotes.rod:InvokeServer(timestamp) end)
        if not ok then print("[Secure Mode] Failed to charge") end
    end
    
    task.wait(0.1) -- Standard charge wait
    
    -- Minigame with safe mode values
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if remotes.miniGame then
        local ok = pcall(function() remotes.miniGame:InvokeServer(x, y) end)
        if not ok then print("[Secure Mode] Failed minigame") end
    end
    
    task.wait(1.3) -- Standard fishing wait
    
    -- Complete fishing
    if remotes.finish then 
        local ok = pcall(function() remotes.finish:FireServer() end)
        if not ok then print("[Secure Mode] Failed to finish") end
    end
end

-- Auto Mode Runner (extracted from original)
local function AutoModeRunner(mySessionId)
    if notify then notify("Auto Mode", "🔥 Auto Mode Started! Looping FishingCompleted.") end
    while config.autoModeEnabled and autoModeSessionId == mySessionId do
        if remotes.finish then
            pcall(function()
                remotes.finish:FireServer()
            end)
        else
            warn("Auto Mode: finishRemote not found!")
            config.autoModeEnabled = false -- Stop if remote is missing
            break
        end
        task.wait(1) -- Wait for 1 second
    end
    if autoModeSessionId == mySessionId then -- Only notify if it's the same session stopping
        if notify then notify("Auto Mode", "🔥 Auto Mode Stopped.") end
    end
end

-- Main AutoFish Runner (extracted from original)
local function AutofishRunner(mySession)
    if notify then notify("AutoFishing", "Smart AutoFishing started (mode: " .. (config.mode or "smart") .. ")") end
    
    -- Start animation monitoring
    AnimationMonitor.isMonitoring = true
    
    -- Auto-fix rod orientation at start
    FixRodOrientation()
    
    while config.enabled and sessionId == mySession do
        local ok, err = pcall(function()
            -- Fix rod orientation before each cycle
            FixRodOrientation()
            
            if config.mode == "secure" then 
                DoSecureCycle() 
            else 
                DoSmartCycle() -- Default to smart mode
            end
        end)
        if not ok then
            warn("AutoFishing: cycle error:", err)
            if notify then notify("AutoFishing", "Cycle error: " .. tostring(err)) end
            task.wait(0.4 + math.random()*0.5)
        end
        
        -- Smart delay based on mode
        local baseDelay = config.autoRecastDelay or 0.4
        local delay = baseDelay
        
        -- Mode-specific delays
        if config.mode == "secure" then
            delay = 0.6 + math.random()*0.4 -- Variable delay for secure mode
        else
            -- Smart mode with animation-based timing
            local smartDelay = baseDelay + GetRealisticTiming("waiting") * 0.3
            delay = smartDelay + (math.random()*0.2 - 0.1)
        end
        
        if delay < 0.15 then delay = 0.15 end -- Minimum delay
        
        local elapsed = 0
        while elapsed < delay do
            if not config.enabled or sessionId ~= mySession then break end
            task.wait(0.05)
            elapsed = elapsed + 0.05
        end
    end
    
    AnimationMonitor.isMonitoring = false
    if notify then notify("AutoFishing", "Smart AutoFishing stopped") end
end

-- Auto Unequip Rod (from original)
local function AutoUnequipRod()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return false end
    
    -- Check if it's a fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return false end
    
    print("Auto unequipping rod:", equippedTool.Name)
    
    -- Try multiple unequip methods
    local success = false
    
    if remotes.unequip then
        local ok = pcall(function() remotes.unequip:FireServer() end)
        if ok then success = true end
    end
    
    if not success and remotes.unequipItem then
        local ok = pcall(function() remotes.unequipItem:FireServer() end)
        if ok then success = true end
    end
    
    -- Manual unequip as last resort
    if not success then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            pcall(function() humanoid:UnequipTools() end)
        end
    end
    
    return true
end
-- Module Interface Functions
function AutoFishing.init(gameConfig, gameRemotes, notifyFunc)
    config = gameConfig
    remotes = gameRemotes
    notify = notifyFunc
    
    print("✅ AutoFishing module initialized")
    print("   - Smart/Secure cycles: enabled")
    print("   - Rod orientation fix: enabled") 
    print("   - Animation monitoring: enabled")
    print("   - Security system: enabled")
    print("   - Auto mode support: enabled")
end

function AutoFishing.start()
    if config.enabled then
        if notify then notify("Auto Fishing", "⚠️ Already running!") end
        return
    end
    
    config.enabled = true
    sessionId = sessionId + 1
    
    -- Start main fishing runner
    task.spawn(function() 
        AutofishRunner(sessionId) 
    end)
end

function AutoFishing.stop()
    config.enabled = false
    sessionId = sessionId + 1
    AnimationMonitor.isMonitoring = false
    AnimationMonitor.currentState = "idle"
    
    if notify then notify("Auto Fishing", "🛑 Stopped") end
end

function AutoFishing.startAutoMode()
    config.autoModeEnabled = true
    autoModeSessionId = autoModeSessionId + 1
    
    task.spawn(function()
        AutoModeRunner(autoModeSessionId)
    end)
end

function AutoFishing.stopAutoMode()
    config.autoModeEnabled = false
    autoModeSessionId = autoModeSessionId + 1
    if notify then notify("Auto Mode", "🛑 Auto Mode stopped") end
end

function AutoFishing.unequipRod()
    return AutoUnequipRod()
end

function AutoFishing.fixRodOrientation()
    FixRodOrientation()
end

function AutoFishing.getStats()
    return {
        state = AnimationMonitor.currentState,
        isRunning = config.enabled or false,
        autoModeRunning = config.autoModeEnabled or false,
        securityStatus = {
            actionsThisMinute = Security.actionsThisMinute,
            isInCooldown = Security.isInCooldown,
            suspicion = Security.suspicion
        },
        animationMonitor = {
            isMonitoring = AnimationMonitor.isMonitoring,
            currentState = AnimationMonitor.currentState,
            fishingSuccess = AnimationMonitor.fishingSuccess
        },
        currentLocation = DetectCurrentLocation()
    }
end

function AutoFishing.getCurrentState()
    return AnimationMonitor.currentState
end

function AutoFishing.isRunning()
    return config.enabled or false
end

function AutoFishing.isAutoModeRunning()
    return config.autoModeEnabled or false
end

function AutoFishing.cleanup()
    AutoFishing.stop()
    AutoFishing.stopAutoMode()
    
    -- Disconnect rod fix connection if exists
    if RodFix.chargingConnection then
        RodFix.chargingConnection:Disconnect()
        RodFix.chargingConnection = nil
    end
    
    -- Reset all states
    AnimationMonitor.isMonitoring = false
    AnimationMonitor.currentState = "idle"
    AnimationMonitor.fishingSuccess = false
    Security.suspicion = 0
    Security.isInCooldown = false
end

-- Enable rod orientation monitoring (from original)
function AutoFishing.enableRodMonitoring()
    if RodFix.chargingConnection then
        RodFix.chargingConnection:Disconnect()
    end
    
    -- Monitor setiap frame selama charging untuk fix real-time
    RodFix.chargingConnection = RunService.Heartbeat:Connect(function()
        if not RodFix.enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Deteksi charging animation
        local isCurrentlyCharging = false
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            local animName = track.Name:lower()
            if animName:find("charge") or animName:find("cast") or animName:find("rod") then
                isCurrentlyCharging = true
                break
            end
        end
        
        -- Jika dalam phase charging, lakukan fix lebih sering
        if isCurrentlyCharging then
            RodFix.isCharging = true
            FixRodOrientation() -- Fix setiap frame selama charging
        else
            if RodFix.isCharging then
                -- Setelah charging selesai, lakukan fix final
                RodFix.isCharging = false
                task.wait(0.1)
                FixRodOrientation()
            end
        end
    end)
end

function AutoFishing.disableRodMonitoring()
    if RodFix.chargingConnection then
        RodFix.chargingConnection:Disconnect()
        RodFix.chargingConnection = nil
    end
    RodFix.isCharging = false
end

return AutoFishing
