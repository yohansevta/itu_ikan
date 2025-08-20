-- autofishing.lua
-- Auto Fishing Module

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local AutoFishing = {}
AutoFishing.__index = AutoFishing

-- Constructor
function AutoFishing.new(settings, rodFix)
    local self = setmetatable({}, AutoFishing)
    
    self.settings = settings or {}
    self.rodFix = rodFix
    
    -- State
    self.enabled = false
    self.mode = self.settings.mode or "smart"
    self.sessionId = 0
    self.currentCycle = 0
    self.isRunning = false
    
    -- Security
    self.security = {
        actionsThisMinute = 0,
        lastMinuteReset = tick(),
        suspicion = 0,
        isInCooldown = false
    }
    
    -- Animation monitoring
    self.animationMonitor = {
        isMonitoring = false,
        currentState = "idle",
        lastAnimationTime = 0,
        fishingSuccess = false
    }
    
    -- Statistics
    self.stats = {
        fishCaught = 0,
        rareFishCaught = 0,
        startTime = 0,
        totalRuntime = 0,
        successfulCasts = 0,
        failedCasts = 0
    }
    
    -- Get remotes
    self:InitializeRemotes()
    
    return self
end

-- Initialize game remotes
function AutoFishing:InitializeRemotes()
    self.remotes = {
        rod = Helpers.ResolveRemote("RF/ChargeFishingRod"),
        miniGame = Helpers.ResolveRemote("RF/RequestFishingMinigameStarted"),
        finish = Helpers.ResolveRemote("RE/FishingCompleted"),
        equip = Helpers.ResolveRemote("RE/EquipToolFromHotbar"),
        fishCaught = Helpers.ResolveRemote("RE/FishCaught"),
        baitSpawned = Helpers.ResolveRemote("RE/BaitSpawned"),
        fishingStopped = Helpers.ResolveRemote("RE/FishingStopped"),
        cancel = Helpers.ResolveRemote("RF/CancelFishingInputs")
    }
    
    -- Setup event listeners
    self:SetupEventListeners()
end

-- Setup remote event listeners
function AutoFishing:SetupEventListeners()
    if self.remotes.fishCaught then
        self.remotes.fishCaught.OnClientEvent:Connect(function(fishData)
            self:OnFishCaught(fishData)
        end)
    end
    
    if self.remotes.baitSpawned then
        self.remotes.baitSpawned.OnClientEvent:Connect(function()
            -- Good time for rod orientation fix
            task.wait(0.1)
            if self.rodFix then
                self.rodFix:ForceFix()
            end
        end)
    end
    
    if self.remotes.fishingStopped then
        self.remotes.fishingStopped.OnClientEvent:Connect(function()
            -- Reset animation state
            self.animationMonitor.currentState = "idle"
            self.animationMonitor.fishingSuccess = false
        end)
    end
end

-- Handle fish caught event
function AutoFishing:OnFishCaught(fishData)
    if not fishData then return end
    
    self.stats.fishCaught = self.stats.fishCaught + 1
    self.stats.successfulCasts = self.stats.successfulCasts + 1
    self.animationMonitor.fishingSuccess = true
    
    local fishName = fishData.name or "Unknown Fish"
    local rarity = Helpers.GetFishRarity(fishName)
    
    if rarity == "Rare" or rarity == "Legendary" or rarity == "Mythical" then
        self.stats.rareFishCaught = self.stats.rareFishCaught + 1
        Helpers.Notify("Auto Fishing", "🎣 Caught " .. rarity .. " fish: " .. fishName)
    end
    
    -- Trigger callback if exists
    if self.onFishCaught then
        self.onFishCaught(fishData, rarity)
    end
end

-- Check if in cooldown
function AutoFishing:InCooldown()
    local now = tick()
    if now - self.security.lastMinuteReset > 60 then
        self.security.actionsThisMinute = 0
        self.security.lastMinuteReset = now
    end
    
    if self.security.actionsThisMinute >= (self.settings.maxActionsPerMinute or 120) then
        self.security.isInCooldown = true
        return true
    end
    
    return self.security.isInCooldown
end

-- Secure remote invoke
function AutoFishing:SecureInvoke(remote, ...)
    if self:InCooldown() then 
        return false, "cooldown" 
    end
    
    self.security.actionsThisMinute = self.security.actionsThisMinute + 1
    task.wait(0.01 + math.random() * 0.05) -- Anti-detection delay
    
    local success, result = Helpers.SafeInvoke(remote, ...)
    if not success then
        self.security.suspicion = self.security.suspicion + 1
        if self.security.suspicion > 8 then
            self.security.isInCooldown = true
            task.spawn(function()
                Helpers.Notify("Auto Fishing", "Entering cooldown due to repeated errors")
                task.wait(self.settings.detectionCooldown or 30)
                self.security.suspicion = 0
                self.security.isInCooldown = false
            end)
        end
    end
    
    return success, result
end

-- Smart fishing cycle
function AutoFishing:DoSmartCycle()
    self.animationMonitor.fishingSuccess = false
    self.animationMonitor.currentState = "starting"
    
    -- Phase 1: Equip and prepare
    if self.rodFix then
        self.rodFix:ForceFix()
    end
    
    if self.settings.autoEquipRod and self.remotes.equip then
        pcall(function() 
            self.remotes.equip:FireServer(self.settings.rodSlot or 1) 
        end)
        task.wait(Helpers.GetRealisticTiming("charging"))
    end
    
    -- Phase 2: Charge rod
    self.animationMonitor.currentState = "charging"
    if self.rodFix then
        self.rodFix:ForceFix()
    end
    
    local usePerfect = math.random(1, 100) <= (self.settings.safeModeChance or 85)
    local timestamp = usePerfect and Helpers.GetServerTime() or 
                     Helpers.GetServerTime() + math.random() * 0.5
    
    if self.remotes.rod then
        pcall(function() 
            self.remotes.rod:InvokeServer(timestamp) 
        end)
    end
    
    -- Fix orientation during charging
    local chargeStart = tick()
    local chargeDuration = Helpers.GetRealisticTiming("charging")
    while tick() - chargeStart < chargeDuration do
        if self.rodFix then
            self.rodFix:ForceFix()
        end
        task.wait(0.02)
    end
    
    -- Phase 3: Cast (mini-game)
    self.animationMonitor.currentState = "casting"
    if self.rodFix then
        self.rodFix:ForceFix()
    end
    
    local x = usePerfect and -1.238 or (math.random(-1000, 1000) / 1000)
    local y = usePerfect and 0.969 or (math.random(0, 1000) / 1000)
    
    if self.remotes.miniGame then
        pcall(function() 
            self.remotes.miniGame:InvokeServer(x, y) 
        end)
    end
    
    task.wait(Helpers.GetRealisticTiming("casting"))
    
    -- Phase 4: Wait for fish
    self.animationMonitor.currentState = "waiting"
    task.wait(Helpers.GetRealisticTiming("waiting"))
    
    -- Phase 5: Complete fishing
    self.animationMonitor.currentState = "completing"
    if self.rodFix then
        self.rodFix:ForceFix()
    end
    
    if self.remotes.finish then
        pcall(function() 
            self.remotes.finish:FireServer() 
        end)
    end
    
    task.wait(Helpers.GetRealisticTiming("reeling"))
    self.animationMonitor.currentState = "idle"
end

-- Secure fishing cycle
function AutoFishing:DoSecureCycle()
    if self:InCooldown() then 
        task.wait(1)
        return 
    end
    
    -- Equip rod
    if self.settings.autoEquipRod and self.remotes.equip then
        local success = pcall(function() 
            self.remotes.equip:FireServer(self.settings.rodSlot or 1) 
        end)
        if not success then 
            print("[Secure Mode] Failed to equip") 
        end
    end
    
    -- Safe charge
    local usePerfect = math.random(1, 100) <= (self.settings.safeModeChance or 85)
    local timestamp = usePerfect and 9999999999 or (tick() + math.random())
    
    if self.remotes.rod then
        local success = pcall(function() 
            self.remotes.rod:InvokeServer(timestamp) 
        end)
        if not success then 
            print("[Secure Mode] Failed to charge") 
        end
    end
    
    task.wait(0.1)
    
    -- Mini-game with safe values
    local x = usePerfect and -1.238 or (math.random(-1000, 1000) / 1000)
    local y = usePerfect and 0.969 or (math.random(0, 1000) / 1000)
    
    if self.remotes.miniGame then
        local success = pcall(function() 
            self.remotes.miniGame:InvokeServer(x, y) 
        end)
        if not success then 
            print("[Secure Mode] Failed minigame") 
        end
    end
    
    task.wait(1.3)
    
    -- Complete fishing
    if self.remotes.finish then
        local success = pcall(function() 
            self.remotes.finish:FireServer() 
        end)
        if not success then 
            print("[Secure Mode] Failed to finish") 
        end
    end
end

-- Fast fishing cycle
function AutoFishing:DoFastCycle()
    if self:InCooldown() then 
        task.wait(0.3)
        return 
    end
    
    -- Safety check
    if not Helpers.IsCharacterValid() then return end
    local character = LocalPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid and humanoid.Health < 20 then
        warn("⚠️ [Fast Mode] Low health detected! Stopping for safety.")
        task.wait(3)
        return
    end
    
    -- Random skip for natural behavior
    if math.random(1, 10) == 1 then
        task.wait(Helpers.GetRandomDelay(0.5, 1.0))
        return
    end
    
    task.wait(Helpers.GetRandomDelay())
    
    -- Check if rod is equipped
    if not Helpers.IsRodEquipped() then
        if self.remotes.cancel then
            pcall(function() self.remotes.cancel:InvokeServer() end)
        end
        task.wait(Helpers.GetRandomDelay())
        
        if self.remotes.equip then
            local success = pcall(function() 
                self.remotes.equip:FireServer(self.settings.rodSlot or 1) 
            end)
            if not success then return end
        end
        task.wait(Helpers.GetRandomDelay() * 2)
    end
    
    task.wait(Helpers.GetRandomDelay())
    
    -- Fast charge
    if self.remotes.rod then
        local success = pcall(function() 
            self.remotes.rod:InvokeServer(workspace:GetServerTimeNow()) 
        end)
        if not success then return end
    end
    
    task.wait(Helpers.GetRandomDelay() + 0.05)
    
    -- Cast with slight variations
    if self.remotes.miniGame then
        local baseX = -1.2379989624023438
        local baseY = 0.9800224985802423
        
        local varX = baseX + (math.random(-5, 5) / 10000)
        local varY = baseY + (math.random(-5, 5) / 10000)
        
        local success = pcall(function() 
            self.remotes.miniGame:InvokeServer(varX, varY) 
        end)
        if not success then return end
    end
    
    task.wait(0.3 + Helpers.GetRandomDelay())
    
    -- Complete
    if self.remotes.finish then
        local success = pcall(function() 
            self.remotes.finish:FireServer() 
        end)
        if not success then return end
    end
    
    self.stats.fishCaught = self.stats.fishCaught + 1
    task.wait(Helpers.GetRandomDelay())
end

-- Main fishing runner
function AutoFishing:FishingRunner(sessionId)
    self.stats.startTime = tick()
    self.stats.fishCaught = 0
    self.stats.rareFishCaught = 0
    
    self.animationMonitor.isMonitoring = true
    
    if self.rodFix then
        self.rodFix:ForceFix()
    end
    
    Helpers.Notify("Auto Fishing", "Started fishing (mode: " .. self.mode .. ")")
    
    while self.enabled and self.sessionId == sessionId do
        local success, err = pcall(function()
            if self.rodFix then
                self.rodFix:ForceFix()
            end
            
            if self.mode == "secure" then
                self:DoSecureCycle()
            elseif self.mode == "fast" then
                self:DoFastCycle()
            else
                self:DoSmartCycle()
            end
        end)
        
        if not success then
            warn("Auto Fishing cycle error:", err)
            Helpers.Notify("Auto Fishing", "Cycle error: " .. tostring(err))
            task.wait(0.4 + math.random() * 0.5)
        end
        
        -- Smart delay based on mode
        local baseDelay = self.settings.autoRecastDelay or 0.2
        local delay = baseDelay
        
        if self.mode == "secure" then
            delay = 0.6 + math.random() * 0.4
        elseif self.mode == "fast" then
            delay = 0.15 + math.random() * 0.1
        else
            local smartDelay = baseDelay + Helpers.GetRealisticTiming("waiting") * 0.3
            delay = smartDelay + (math.random() * 0.2 - 0.1)
        end
        
        if delay < 0.15 then delay = 0.15 end
        
        local elapsed = 0
        while elapsed < delay do
            if not self.enabled or self.sessionId ~= sessionId then break end
            task.wait(0.05)
            elapsed = elapsed + 0.05
        end
        
        self.currentCycle = self.currentCycle + 1
    end
    
    self.animationMonitor.isMonitoring = false
    self.isRunning = false
    Helpers.Notify("Auto Fishing", "Stopped fishing")
end

-- Start auto fishing
function AutoFishing:Start()
    if self.enabled then return false, "Already running" end
    
    self.enabled = true
    self.sessionId = self.sessionId + 1
    self.isRunning = true
    self.currentCycle = 0
    
    task.spawn(function()
        self:FishingRunner(self.sessionId)
    end)
    
    return true, "Started successfully"
end

-- Stop auto fishing
function AutoFishing:Stop()
    if not self.enabled then return false, "Not running" end
    
    self.enabled = false
    self.sessionId = self.sessionId + 1
    self.isRunning = false
    
    return true, "Stopped successfully"
end

-- Toggle auto fishing
function AutoFishing:Toggle()
    if self.enabled then
        return self:Stop()
    else
        return self:Start()
    end
end

-- Set mode
function AutoFishing:SetMode(mode)
    if mode == "smart" or mode == "secure" or mode == "fast" then
        self.mode = mode
        return true, "Mode set to " .. mode
    end
    return false, "Invalid mode"
end

-- Get statistics
function AutoFishing:GetStats()
    local runtime = self.isRunning and (tick() - self.stats.startTime) or self.stats.totalRuntime
    
    return {
        fishCaught = self.stats.fishCaught,
        rareFishCaught = self.stats.rareFishCaught,
        runtime = runtime,
        currentCycle = self.currentCycle,
        fishPerHour = runtime > 0 and (self.stats.fishCaught / (runtime / 3600)) or 0,
        successfulCasts = self.stats.successfulCasts,
        failedCasts = self.stats.failedCasts,
        successRate = (self.stats.successfulCasts + self.stats.failedCasts) > 0 and 
                     (self.stats.successfulCasts / (self.stats.successfulCasts + self.stats.failedCasts)) * 100 or 0
    }
end

-- Get status
function AutoFishing:GetStatus()
    return {
        enabled = self.enabled,
        mode = self.mode,
        isRunning = self.isRunning,
        sessionId = self.sessionId,
        currentCycle = self.currentCycle,
        stats = self:GetStats(),
        security = self.security,
        animationState = self.animationMonitor.currentState
    }
end

-- Update settings
function AutoFishing:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
    if newSettings.mode then
        self.mode = newSettings.mode
    end
end

-- Set fish caught callback
function AutoFishing:SetFishCaughtCallback(callback)
    self.onFishCaught = callback
end

-- Cleanup
function AutoFishing:Destroy()
    self:Stop()
    setmetatable(self, nil)
end

return AutoFishing
