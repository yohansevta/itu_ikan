-- rodfix.lua
-- ITU IKAN Rod Fix Module (extracted dari fishit.lua original)
-- Advanced rod orientation fixing untuk better fishing experience

local RodFix = {}

-- Private variables
local config = nil
local remotes = nil
local notify = nil
local isEnabled = false

-- RodFix state tracking (dari fishit.lua)
local rodFixState = {
    enabled = true,
    lastFixTime = 0,
    isCharging = false,
    chargingConnection = nil,
    monitorConnection = nil
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Monitor charging phase untuk fix yang lebih aktif (dari fishit.lua)
local function monitorChargingPhase()
    if rodFixState.chargingConnection then
        rodFixState.chargingConnection:Disconnect()
    end
    
    -- Monitor setiap frame selama charging untuk fix real-time
    rodFixState.chargingConnection = RunService.Heartbeat:Connect(function()
        if not rodFixState.enabled then return end
        
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
            rodFixState.isCharging = true
            fixRodOrientation() -- Fix setiap frame selama charging
        else
            if rodFixState.isCharging then
                -- Setelah charging selesai, lakukan fix final
                rodFixState.isCharging = false
                task.wait(0.1)
                fixRodOrientation()
            end
        end
    end)
end

-- Main rod orientation fix function (dari fishit.lua)
local function fixRodOrientation()
    if not rodFixState.enabled then return end
    
    local now = tick()
    if now - rodFixState.lastFixTime < 0.05 then return end -- Faster throttle for charging phase
    rodFixState.lastFixTime = now
    
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
            -- C0 mengontrol posisi/orientasi di right arm
            -- C1 mengontrol posisi/orientasi di handle
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
            return
        end
    end
    
    -- Method 2: Fix Tool Grip Value (untuk tools dengan custom grip)
    local handle = equippedTool:FindFirstChild("Handle")
    if handle then
        -- Fix grip value yang ada
        local toolGrip = equippedTool:FindFirstChild("Grip")
        if toolGrip and toolGrip:IsA("CFrameValue") then
            -- Grip value untuk rod menghadap depan
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
    
    -- Method 3: Direct CFrame manipulation for R6/R15 compatibility
    if rightArm then
        local weld = rightArm:FindFirstChild("Weld") 
        if weld then
            weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            weld.C1 = CFrame.new(0, 0, 0)
        end
    end
end

-- Setup tool monitoring (dari fishit.lua)
local function setupToolMonitoring()
    -- Monitor when character gets tools
    local function onCharacterAdded(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1) -- Wait for tool to fully load
                fixRodOrientation()
                monitorChargingPhase() -- Start monitoring charging phase
            end
        end)
        
        character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and rodFixState.chargingConnection then
                rodFixState.chargingConnection:Disconnect()
                rodFixState.chargingConnection = nil
            end
        end)
    end
    
    -- Connect to current and future characters
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
    -- Check if rod is already equipped
    if LocalPlayer.Character then
        local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if currentTool then
            fixRodOrientation()
            monitorChargingPhase()
        end
    end
end

-- Continuous rod monitoring
local function startContinuousMonitoring()
    if rodFixState.monitorConnection then
        rodFixState.monitorConnection:Disconnect()
    end
    
    rodFixState.monitorConnection = RunService.Heartbeat:Connect(function()
        if not rodFixState.enabled then return end
        
        -- Check every few frames untuk efficiency
        if tick() - rodFixState.lastFixTime > 0.1 then
            fixRodOrientation()
        end
    end)
end

-- Module functions
function RodFix.init(gameConfig, gameRemotes, notifyFunc)
    config = gameConfig
    remotes = gameRemotes
    notify = notifyFunc
    
    -- Setup tool monitoring
    setupToolMonitoring()
    
    print("✅ RodFix module initialized")
    print("   - Charging phase monitoring: enabled")
    print("   - Real-time orientation fixing: enabled")
    print("   - Multi-method rod fixing: enabled")
end

function RodFix.enable()
    if isEnabled then
        if notify then notify("Rod Fix", "⚠️ Already enabled!") end
        return
    end
    
    isEnabled = true
    rodFixState.enabled = true
    config.rodFixEnabled = true
    
    -- Start continuous monitoring
    startContinuousMonitoring()
    
    if notify then notify("Rod Fix", "🔧 Rod orientation fix enabled!") end
    
    -- Immediate fix if rod is equipped
    fixRodOrientation()
end

function RodFix.disable()
    isEnabled = false
    rodFixState.enabled = false
    config.rodFixEnabled = false
    
    -- Stop all monitoring connections
    if rodFixState.chargingConnection then
        rodFixState.chargingConnection:Disconnect()
        rodFixState.chargingConnection = nil
    end
    
    if rodFixState.monitorConnection then
        rodFixState.monitorConnection:Disconnect()
        rodFixState.monitorConnection = nil
    end
    
    if notify then notify("Rod Fix", "🔧 Rod orientation fix disabled") end
end

function RodFix.toggle()
    if isEnabled then
        RodFix.disable()
    else
        RodFix.enable()
    end
end

function RodFix.forcefix()
    -- Force immediate rod fix
    fixRodOrientation()
    if notify then notify("Rod Fix", "🔧 Force fix applied!") end
end

function RodFix.isEnabled()
    return isEnabled
end

function RodFix.getStatus()
    return {
        enabled = isEnabled,
        isCharging = rodFixState.isCharging,
        lastFixTime = rodFixState.lastFixTime,
        hasChargingConnection = rodFixState.chargingConnection ~= nil,
        hasMonitorConnection = rodFixState.monitorConnection ~= nil
    }
end

function RodFix.cleanup()
    RodFix.disable()
    
    -- Clean up all connections
    if rodFixState.chargingConnection then
        rodFixState.chargingConnection:Disconnect()
        rodFixState.chargingConnection = nil
    end
    
    if rodFixState.monitorConnection then
        rodFixState.monitorConnection:Disconnect()
        rodFixState.monitorConnection = nil
    end
    
    print("🧹 RodFix module cleaned up")
end

return RodFix
