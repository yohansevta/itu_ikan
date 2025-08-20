-- autofishing.lua
-- ITU IKAN Auto Fishing Module (extracted dari fishit.lua original)
-- All fishing logic dan auto mode features

local AutoFishing = {}

-- Private variables
local config = nil
local remotes = nil
local notify = nil
local isRunning = false
local autoModeRunning = false
local autoModeSessionId = 0

-- Fishing states (dari fishit.lua)
local FishingStates = {
    IDLE = "idle",
    CHARGING = "charging", 
    CASTING = "casting",
    WAITING = "waiting",
    REELING = "reeling",
    COMPLETE = "complete"
}

local currentState = FishingStates.IDLE

-- Fishing statistics
local stats = {
    totalCasts = 0,
    successfulCatches = 0,
    failedCasts = 0,
    lastCastTime = 0,
    sessionStart = tick()
}

-- Safe remote invocation (dari fishit.lua)
local function safeInvoke(remote, ...)
    if not remote then return false, "nil_remote" end
    if remote:IsA("RemoteFunction") then
        return pcall(function(...) return remote:InvokeServer(...) end, ...)
    else
        return pcall(function(...) remote:FireServer(...) return true end, ...)
    end
end

-- Get realistic timing untuk human-like behavior
local function getRealisticTiming(action)
    local timings = {
        charging = math.random(8, 15) / 10,  -- 0.8-1.5s
        casting = math.random(3, 7) / 10,    -- 0.3-0.7s
        waiting = math.random(15, 35) / 10,  -- 1.5-3.5s
        reeling = math.random(5, 12) / 10,   -- 0.5-1.2s
        recast = math.random(3, 8) / 10      -- 0.3-0.8s
    }
    return timings[action] or 1
end

-- Equip fishing rod (dari fishit.lua)
local function equipFishingRod()
    if not remotes.equip then 
        return false, "No equip remote"
    end
    
    -- Try to equip rod from hotbar slot 1
    local success, result = safeInvoke(remotes.equip, 1)
    if success then
        wait(0.2) -- Wait for equip
        return true
    end
    
    return false, result
end

-- Smart fishing cycle (dari fishit.lua dengan improvements)
local function smartFishingCycle()
    if not isRunning then return end
    
    currentState = FishingStates.CHARGING
    stats.totalCasts = stats.totalCasts + 1
    
    -- Phase 1: Equip rod
    local equipped, equipError = equipFishingRod()
    if not equipped then
        if notify then notify("Fishing", "⚠️ Failed to equip rod: " .. tostring(equipError)) end
        return false
    end
    
    wait(getRealisticTiming("charging"))
    
    -- Phase 2: Charge rod
    currentState = FishingStates.CHARGING
    local chargeTime = workspace:GetServerTimeNow()
    
    if remotes.autoFishState then
        local chargeSuccess = safeInvoke(remotes.autoFishState, chargeTime)
        if not chargeSuccess then
            if notify then notify("Fishing", "⚠️ Failed to charge rod") end
            return false
        end
    end
    
    wait(getRealisticTiming("charging"))
    
    -- Phase 3: Cast rod
    currentState = FishingStates.CASTING
    
    -- Calculate cast position based on mode
    local x, y = 0, 0
    
    if config.fishingMode == "smart" then
        -- Smart mode: Mix of safe and perfect casts
        local usePerfect = math.random(1, 100) <= config.perfectCastChance
        if usePerfect then
            x, y = -1.238, 0.969  -- Perfect cast position
        else
            local useSafe = math.random(1, 100) <= config.safeCastChance
            if useSafe then
                x = math.random(-800, 800) / 1000
                y = math.random(600, 1000) / 1000
            else
                x = math.random(-1000, 1000) / 1000
                y = math.random(0, 1000) / 1000
            end
        end
    elseif config.fishingMode == "secure" then
        -- Secure mode: Only safe casts
        x = math.random(-600, 600) / 1000
        y = math.random(700, 900) / 1000
    elseif config.fishingMode == "fast" then
        -- Fast mode: More perfect casts
        local usePerfect = math.random(1, 100) <= 35
        if usePerfect then
            x, y = -1.238, 0.969
        else
            x = math.random(-1000, 1000) / 1000  
            y = math.random(0, 1000) / 1000
        end
    end
    
    -- Cast the rod
    if remotes.cast then
        local castSuccess, castResult = safeInvoke(remotes.cast, x, y)
        if castSuccess then
            stats.lastCastTime = tick()
            if notify then notify("Fishing", "🎣 Cast successful! Mode: " .. config.fishingMode) end
        else
            stats.failedCasts = stats.failedCasts + 1
            if notify then notify("Fishing", "⚠️ Cast failed: " .. tostring(castResult)) end
            return false
        end
    end
    
    wait(getRealisticTiming("casting"))
    
    -- Phase 4: Wait for fish
    currentState = FishingStates.WAITING
    wait(getRealisticTiming("waiting"))
    
    -- Phase 5: Reel in / Catch fish
    currentState = FishingStates.REELING
    
    if remotes.catch then
        local catchSuccess, catchResult = safeInvoke(remotes.catch)
        if catchSuccess then
            stats.successfulCatches = stats.successfulCatches + 1
            if notify then notify("Fishing", "✅ Fish caught!") end
        end
    end
    
    wait(getRealisticTiming("reeling"))
    
    -- Phase 6: Release if needed
    if remotes.release then
        safeInvoke(remotes.release)
    end
    
    currentState = FishingStates.COMPLETE
    wait(config.autoRecastDelay or 0.4)
    
    currentState = FishingStates.IDLE
    return true
end

-- Auto Mode (dari fishit.lua)
local function startAutoModeLoop()
    autoModeSessionId = autoModeSessionId + 1
    local mySessionId = autoModeSessionId
    autoModeRunning = true
    
    if notify then notify("Auto Mode", "🤖 Auto Mode started!") end
    
    spawn(function()
        while config.autoModeEnabled and autoModeSessionId == mySessionId do
            if not remotes.autoFishState then
                if notify then notify("Auto Mode", "❌ Auto fishing remote not found!") end
                config.autoModeEnabled = false
                break
            end
            
            -- Perform auto fishing action
            local success = smartFishingCycle()
            if not success then
                wait(2) -- Wait before retry on failure
            end
            
            wait(0.1) -- Small delay between cycles
        end
        
        if autoModeSessionId == mySessionId then
            autoModeRunning = false
            if notify then notify("Auto Mode", "🛑 Auto Mode stopped") end
        end
    end)
end

-- Auto Unequip Rod (dari fishit.lua)
local function autoUnequipRod()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
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

-- Module functions
function AutoFishing.init(gameConfig, gameRemotes, notifyFunc)
    config = gameConfig
    remotes = gameRemotes
    notify = notifyFunc
    
    print("✅ AutoFishing module initialized")
    print("   - Fishing modes: smart, secure, fast")
    print("   - Auto mode support: enabled")
    print("   - Unequip support: enabled")
end

function AutoFishing.start()
    if isRunning then
        if notify then notify("Auto Fishing", "⚠️ Already running!") end
        return
    end
    
    isRunning = true
    config.autoFishingEnabled = true
    
    if notify then notify("Auto Fishing", "🎣 Started! Mode: " .. (config.fishingMode or "smart")) end
    
    -- Start fishing loop
    spawn(function()
        while isRunning and config.autoFishingEnabled do
            local success = smartFishingCycle()
            if not success then
                wait(1) -- Wait before retry on failure
            end
            wait(0.1)
        end
    end)
end

function AutoFishing.stop()
    isRunning = false
    config.autoFishingEnabled = false
    currentState = FishingStates.IDLE
    
    if notify then notify("Auto Fishing", "🛑 Stopped") end
end

function AutoFishing.startAutoMode()
    config.autoModeEnabled = true
    startAutoModeLoop()
end

function AutoFishing.stopAutoMode()
    config.autoModeEnabled = false
    autoModeRunning = false
    if notify then notify("Auto Mode", "🛑 Auto Mode stopped") end
end

function AutoFishing.unequipRod()
    return autoUnequipRod()
end

function AutoFishing.getStats()
    local sessionTime = tick() - stats.sessionStart
    local castsPerHour = stats.totalCasts > 0 and (stats.totalCasts / (sessionTime / 3600)) or 0
    local successRate = stats.totalCasts > 0 and (stats.successfulCatches / stats.totalCasts * 100) or 0
    
    return {
        state = currentState,
        totalCasts = stats.totalCasts,
        successfulCatches = stats.successfulCatches,
        failedCasts = stats.failedCasts,
        successRate = math.floor(successRate * 10) / 10,
        castsPerHour = math.floor(castsPerHour * 10) / 10,
        sessionTime = sessionTime,
        isRunning = isRunning,
        autoModeRunning = autoModeRunning
    }
end

function AutoFishing.getCurrentState()
    return currentState
end

function AutoFishing.isRunning()
    return isRunning
end

function AutoFishing.cleanup()
    AutoFishing.stop()
    AutoFishing.stopAutoMode()
end

return AutoFishing
