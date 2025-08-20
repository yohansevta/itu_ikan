-- rodfix.lua
-- Rod Orientation Fix Module

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local RodFix = {}
RodFix.__index = RodFix

-- Constructor
function RodFix.new(settings)
    local self = setmetatable({}, RodFix)
    
    self.settings = settings or {}
    self.enabled = self.settings.enabled or true
    self.continuousMode = self.settings.continuousMode or true
    self.fixDuringCharging = self.settings.fixDuringCharging or true
    self.fixInterval = self.settings.fixInterval or 0.05
    
    self.lastFixTime = 0
    self.isCharging = false
    self.chargingConnection = nil
    self.characterConnection = nil
    
    self:Initialize()
    
    return self
end

-- Initialize the rod fix system
function RodFix:Initialize()
    self:SetupCharacterEvents()
    
    -- Fix current tool if character already exists
    if LocalPlayer.Character then
        self:CheckCurrentTool()
    end
end

-- Setup character added/removed events
function RodFix:SetupCharacterEvents()
    -- Clean up existing connection
    if self.characterConnection then
        self.characterConnection:Disconnect()
    end
    
    self.characterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    -- Setup for current character if exists
    if LocalPlayer.Character then
        self:OnCharacterAdded(LocalPlayer.Character)
    end
end

-- Handle character added
function RodFix:OnCharacterAdded(character)
    -- Tool added event
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1) -- Wait for tool to fully load
            self:FixRodOrientation()
            self:StartChargingMonitor()
        end
    end)
    
    -- Tool removed event
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            self:StopChargingMonitor()
        end
    end)
    
    -- Check if rod is already equipped
    self:CheckCurrentTool()
end

-- Check current equipped tool
function RodFix:CheckCurrentTool()
    if Helpers.IsRodEquipped() then
        self:FixRodOrientation()
        self:StartChargingMonitor()
    end
end

-- Start monitoring charging phase
function RodFix:StartChargingMonitor()
    if not self.enabled or not self.fixDuringCharging then return end
    
    self:StopChargingMonitor() -- Clean up existing connection
    
    -- Monitor every frame during charging for real-time fixes
    self.chargingConnection = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Detect charging animation
        local isCurrentlyCharging = false
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            local animName = track.Name:lower()
            if animName:find("charge") or animName:find("cast") or animName:find("rod") then
                isCurrentlyCharging = true
                break
            end
        end
        
        -- If in charging phase, apply fix more frequently
        if isCurrentlyCharging then
            self.isCharging = true
            self:FixRodOrientation() -- Fix every frame during charging
        else
            if self.isCharging then
                -- After charging ends, do final fix
                self.isCharging = false
                task.wait(0.1)
                self:FixRodOrientation()
            end
        end
    end)
end

-- Stop charging monitor
function RodFix:StopChargingMonitor()
    if self.chargingConnection then
        self.chargingConnection:Disconnect()
        self.chargingConnection = nil
    end
    self.isCharging = false
end

-- Main rod orientation fix function
function RodFix:FixRodOrientation()
    if not self.enabled then return end
    
    local now = tick()
    if now - self.lastFixTime < self.fixInterval then return end -- Throttle fixes
    self.lastFixTime = now
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Ensure this is a fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return end
    
    -- Method 1: Fix Motor6D during charging phase (most effective)
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            -- Normal orientation for rod facing forward during charging
            -- C0 controls position/orientation at right arm
            -- C1 controls position/orientation at handle
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
            return
        end
    end
    
    -- Method 2: Fix Tool Grip Value (for tools with custom grip)
    local handle = equippedTool:FindFirstChild("Handle")
    if handle then
        -- Fix existing grip value
        local toolGrip = equippedTool:FindFirstChild("Grip")
        if toolGrip and toolGrip:IsA("CFrameValue") then
            -- Grip value for rod facing forward
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            return
        end
        
        -- If no grip value exists, create one
        if not toolGrip then
            toolGrip = Instance.new("CFrameValue")
            toolGrip.Name = "Grip"
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            toolGrip.Parent = equippedTool
        end
    end
end

-- Force fix rod orientation
function RodFix:ForceFix()
    self.lastFixTime = 0 -- Reset throttle
    self:FixRodOrientation()
end

-- Enable rod fix
function RodFix:Enable()
    self.enabled = true
    self:ForceFix()
    if Helpers.IsRodEquipped() then
        self:StartChargingMonitor()
    end
    Helpers.Notify("Rod Fix", "🎣 Rod orientation fix enabled")
end

-- Disable rod fix
function RodFix:Disable()
    self.enabled = false
    self:StopChargingMonitor()
    Helpers.Notify("Rod Fix", "🎣 Rod orientation fix disabled")
end

-- Toggle rod fix
function RodFix:Toggle()
    if self.enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.enabled
end

-- Update settings
function RodFix:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
    self.enabled = self.settings.enabled
    self.continuousMode = self.settings.continuousMode
    self.fixDuringCharging = self.settings.fixDuringCharging
    self.fixInterval = self.settings.fixInterval
    
    if self.enabled and Helpers.IsRodEquipped() then
        self:StartChargingMonitor()
    elseif not self.enabled then
        self:StopChargingMonitor()
    end
end

-- Get status
function RodFix:GetStatus()
    return {
        enabled = self.enabled,
        isCharging = self.isCharging,
        hasRodEquipped = Helpers.IsRodEquipped(),
        lastFixTime = self.lastFixTime,
        settings = self.settings
    }
end

-- Cleanup
function RodFix:Destroy()
    self:StopChargingMonitor()
    if self.characterConnection then
        self.characterConnection:Disconnect()
    end
    
    setmetatable(self, nil)
end

return RodFix
