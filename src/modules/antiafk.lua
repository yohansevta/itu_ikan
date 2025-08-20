-- antiafk.lua
-- Anti-AFK Module

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local AntiAFK = {}
AntiAFK.__index = AntiAFK

-- Constructor
function AntiAFK.new(settings)
    local self = setmetatable({}, AntiAFK)
    
    self.settings = settings or {}
    self.enabled = self.settings.enabled or true
    self.randomMovement = self.settings.randomMovement or true
    self.jumpRandomly = self.settings.jumpRandomly or true
    self.mouseMovement = self.settings.mouseMovement or true
    self.interval = self.settings.interval or {min = 30, max = 90}
    
    -- State
    self.isRunning = false
    self.sessionId = 0
    self.lastActivity = tick()
    self.totalActivities = 0
    
    -- Movement patterns
    self.movementPatterns = {
        "W", "A", "S", "D", "WA", "WD", "SA", "SD"
    }
    
    self:Start()
    
    return self
end

-- Start anti-AFK system
function AntiAFK:Start()
    if self.isRunning then return false, "Already running" end
    
    self.enabled = true
    self.isRunning = true
    self.sessionId = self.sessionId + 1
    
    task.spawn(function()
        self:AntiAFKRunner(self.sessionId)
    end)
    
    Helpers.Notify("Anti-AFK", "🤖 Anti-AFK started")
    return true, "Anti-AFK started"
end

-- Stop anti-AFK system
function AntiAFK:Stop()
    if not self.isRunning then return false, "Not running" end
    
    self.enabled = false
    self.sessionId = self.sessionId + 1
    self.isRunning = false
    
    Helpers.Notify("Anti-AFK", "🤖 Anti-AFK stopped")
    return true, "Anti-AFK stopped"
end

-- Toggle anti-AFK
function AntiAFK:Toggle()
    if self.isRunning then
        return self:Stop()
    else
        return self:Start()
    end
end

-- Main anti-AFK runner
function AntiAFK:AntiAFKRunner(sessionId)
    while self.enabled and self.sessionId == sessionId do
        -- Wait for random interval
        local waitTime = math.random(self.interval.min, self.interval.max)
        
        local elapsed = 0
        while elapsed < waitTime and self.enabled and self.sessionId == sessionId do
            task.wait(1)
            elapsed = elapsed + 1
        end
        
        if not self.enabled or self.sessionId ~= sessionId then break end
        
        -- Perform anti-AFK activity
        self:PerformAntiAFKActivity()
        
        self.totalActivities = self.totalActivities + 1
        self.lastActivity = tick()
    end
    
    self.isRunning = false
end

-- Perform random anti-AFK activity
function AntiAFK:PerformAntiAFKActivity()
    if not Helpers.IsCharacterValid() then return end
    
    local activities = {}
    
    -- Add movement activities
    if self.randomMovement then
        table.insert(activities, "movement")
    end
    
    -- Add jump activity
    if self.jumpRandomly then
        table.insert(activities, "jump")
    end
    
    -- Add mouse movement
    if self.mouseMovement then
        table.insert(activities, "mouse")
    end
    
    -- Always include camera rotation as fallback
    table.insert(activities, "camera")
    
    if #activities == 0 then return end
    
    -- Select random activity
    local selectedActivity = activities[math.random(1, #activities)]
    
    -- Perform the selected activity
    local success = pcall(function()
        if selectedActivity == "movement" then
            self:DoRandomMovement()
        elseif selectedActivity == "jump" then
            self:DoRandomJump()
        elseif selectedActivity == "mouse" then
            self:DoMouseMovement()
        elseif selectedActivity == "camera" then
            self:DoCameraRotation()
        end
    end)
    
    if success then
        if _G.ITU_IKAN_DEBUG then
            print("[Anti-AFK] Performed activity:", selectedActivity)
        end
    else
        warn("[Anti-AFK] Failed to perform activity:", selectedActivity)
    end
end

-- Perform random movement
function AntiAFK:DoRandomMovement()
    local pattern = self.movementPatterns[math.random(1, #self.movementPatterns)]
    local duration = math.random(100, 500) / 1000 -- 0.1 to 0.5 seconds
    
    -- Press keys
    for i = 1, #pattern do
        local key = pattern:sub(i, i)
        local keyCode = self:GetKeyCode(key)
        if keyCode then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, nil)
        end
    end
    
    task.wait(duration)
    
    -- Release keys
    for i = 1, #pattern do
        local key = pattern:sub(i, i)
        local keyCode = self:GetKeyCode(key)
        if keyCode then
            VirtualInputManager:SendKeyEvent(false, keyCode, false, nil)
        end
    end
end

-- Perform random jump
function AntiAFK:DoRandomJump()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
end

-- Perform mouse movement
function AntiAFK:DoMouseMovement()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local currentPosition = UserInputService:GetMouseLocation()
    
    -- Generate random movement
    local deltaX = math.random(-50, 50)
    local deltaY = math.random(-50, 50)
    
    -- Move mouse
    VirtualInputManager:SendMouseMoveEvent(
        currentPosition.X + deltaX,
        currentPosition.Y + deltaY,
        nil
    )
    
    task.wait(0.1)
    
    -- Move back to approximately original position
    VirtualInputManager:SendMouseMoveEvent(
        currentPosition.X + math.random(-10, 10),
        currentPosition.Y + math.random(-10, 10),
        nil
    )
end

-- Perform camera rotation
function AntiAFK:DoCameraRotation()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local originalCFrame = camera.CFrame
    
    -- Small camera rotation
    local rotationAmount = math.rad(math.random(-15, 15))
    local rotationCFrame = CFrame.Angles(0, rotationAmount, 0)
    
    camera.CFrame = originalCFrame * rotationCFrame
    
    task.wait(0.2)
    
    -- Rotate back (approximately)
    local returnRotation = math.rad(math.random(-5, 5))
    camera.CFrame = originalCFrame * CFrame.Angles(0, returnRotation, 0)
end

-- Get KeyCode from character
function AntiAFK:GetKeyCode(char)
    local keyCodes = {
        W = Enum.KeyCode.W,
        A = Enum.KeyCode.A,
        S = Enum.KeyCode.S,
        D = Enum.KeyCode.D
    }
    return keyCodes[char]
end

-- Set movement enabled
function AntiAFK:SetRandomMovement(enabled)
    self.randomMovement = enabled
    return true, "Random movement: " .. (enabled and "enabled" or "disabled")
end

-- Set jump enabled
function AntiAFK:SetRandomJump(enabled)
    self.jumpRandomly = enabled
    return true, "Random jump: " .. (enabled and "enabled" or "disabled")
end

-- Set mouse movement enabled
function AntiAFK:SetMouseMovement(enabled)
    self.mouseMovement = enabled
    return true, "Mouse movement: " .. (enabled and "enabled" or "disabled")
end

-- Set interval
function AntiAFK:SetInterval(min, max)
    if min < 10 then min = 10 end
    if max > 300 then max = 300 end
    if min > max then min, max = max, min end
    
    self.interval = {min = min, max = max}
    return true, string.format("Interval set to %d-%d seconds", min, max)
end

-- Force activity now
function AntiAFK:ForceActivity()
    if not self.enabled then
        return false, "Anti-AFK disabled"
    end
    
    self:PerformAntiAFKActivity()
    return true, "Activity performed"
end

-- Get time since last activity
function AntiAFK:GetTimeSinceLastActivity()
    return tick() - self.lastActivity
end

-- Get next activity time estimate
function AntiAFK:GetNextActivityTime()
    if not self.isRunning then return nil end
    
    local timeSinceLastActivity = self:GetTimeSinceLastActivity()
    local minWaitTime = self.interval.min
    
    if timeSinceLastActivity >= minWaitTime then
        return "Any moment now"
    else
        local timeRemaining = minWaitTime - timeSinceLastActivity
        return Helpers.FormatTime(timeRemaining)
    end
end

-- Get statistics
function AntiAFK:GetStats()
    return {
        totalActivities = self.totalActivities,
        lastActivity = self.lastActivity,
        timeSinceLastActivity = self:GetTimeSinceLastActivity(),
        nextActivityTime = self:GetNextActivityTime(),
        averageInterval = (self.interval.min + self.interval.max) / 2,
        isRunning = self.isRunning
    }
end

-- Get status
function AntiAFK:GetStatus()
    return {
        enabled = self.enabled,
        isRunning = self.isRunning,
        randomMovement = self.randomMovement,
        jumpRandomly = self.jumpRandomly,
        mouseMovement = self.mouseMovement,
        interval = self.interval,
        stats = self:GetStats()
    }
end

-- Update settings
function AntiAFK:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
    
    if newSettings.randomMovement ~= nil then
        self.randomMovement = newSettings.randomMovement
    end
    
    if newSettings.jumpRandomly ~= nil then
        self.jumpRandomly = newSettings.jumpRandomly
    end
    
    if newSettings.mouseMovement ~= nil then
        self.mouseMovement = newSettings.mouseMovement
    end
    
    if newSettings.interval then
        self.interval = newSettings.interval
    end
    
    if newSettings.enabled ~= nil then
        if newSettings.enabled and not self.isRunning then
            self:Start()
        elseif not newSettings.enabled and self.isRunning then
            self:Stop()
        end
    end
end

-- Cleanup
function AntiAFK:Destroy()
    self:Stop()
    setmetatable(self, nil)
end

return AntiAFK
