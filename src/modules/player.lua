-- player.lua
-- Player Modifications Module

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local PlayerMods = {}
PlayerMods.__index = PlayerMods

-- Constructor
function PlayerMods.new(settings)
    local self = setmetatable({}, PlayerMods)
    
    self.settings = settings or {}
    self.originalValues = {}
    self.connections = {}
    
    -- States
    self.floatEnabled = false
    self.noClipEnabled = false
    self.spinnerEnabled = false
    
    -- Values
    self.walkSpeed = self.settings.walkSpeed or 16
    self.jumpPower = self.settings.jumpPower or 50
    self.floatHeight = self.settings.floatHeight or 16
    self.spinnerSpeed = self.settings.spinnerSpeed or 2
    self.spinnerDirection = self.settings.spinnerDirection or 1
    
    -- Float system
    self.floatBodyVelocity = nil
    self.floatBodyPosition = nil
    
    -- No-clip system
    self.noClipParts = {}
    
    self:Initialize()
    
    return self
end

-- Initialize the player modifications
function PlayerMods:Initialize()
    self:SaveOriginalValues()
    self:SetupCharacterEvents()
    
    -- Apply to current character if exists
    if LocalPlayer.Character then
        self:OnCharacterAdded(LocalPlayer.Character)
    end
end

-- Save original player values
function PlayerMods:SaveOriginalValues()
    if Helpers.IsCharacterValid() then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            self.originalValues.walkSpeed = humanoid.WalkSpeed
            self.originalValues.jumpPower = humanoid.JumpPower
        end
    end
end

-- Setup character events
function PlayerMods:SetupCharacterEvents()
    -- Clean up existing connection
    if self.connections.characterAdded then
        self.connections.characterAdded:Disconnect()
    end
    
    self.connections.characterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    -- Setup for current character
    if LocalPlayer.Character then
        self:OnCharacterAdded(LocalPlayer.Character)
    end
end

-- Handle character added
function PlayerMods:OnCharacterAdded(character)
    -- Wait for humanoid
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    -- Save original values
    self.originalValues.walkSpeed = humanoid.WalkSpeed
    self.originalValues.jumpPower = humanoid.JumpPower
    
    -- Apply current settings
    self:ApplyCurrentSettings()
    
    -- Re-enable features if they were enabled
    if self.floatEnabled then
        self:EnableFloat()
    end
    
    if self.noClipEnabled then
        self:EnableNoClip()
    end
    
    if self.spinnerEnabled then
        self:EnableSpinner()
    end
end

-- Apply current settings to character
function PlayerMods:ApplyCurrentSettings()
    if not Helpers.IsCharacterValid() then return end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = self.walkSpeed
        humanoid.JumpPower = self.jumpPower
    end
end

-- Set walk speed
function PlayerMods:SetWalkSpeed(speed)
    speed = Helpers.Clamp(speed, 0, 500)
    self.walkSpeed = speed
    
    if Helpers.IsCharacterValid() then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end
    
    return true, "Walk speed set to " .. speed
end

-- Set jump power
function PlayerMods:SetJumpPower(power)
    power = Helpers.Clamp(power, 0, 500)
    self.jumpPower = power
    
    if Helpers.IsCharacterValid() then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = power
        end
    end
    
    return true, "Jump power set to " .. power
end

-- Enable float
function PlayerMods:EnableFloat()
    if not Helpers.IsCharacterValid() then
        return false, "Character not valid"
    end
    
    local character = LocalPlayer.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false, "HumanoidRootPart not found"
    end
    
    -- Clean up existing float objects
    self:DisableFloat()
    
    -- Create BodyVelocity for movement
    self.floatBodyVelocity = Instance.new("BodyVelocity")
    self.floatBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    self.floatBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    self.floatBodyVelocity.Parent = rootPart
    
    -- Create BodyPosition for floating
    self.floatBodyPosition = Instance.new("BodyPosition")
    self.floatBodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
    self.floatBodyPosition.Position = rootPart.Position + Vector3.new(0, self.floatHeight, 0)
    self.floatBodyPosition.D = 500
    self.floatBodyPosition.P = 10000
    self.floatBodyPosition.Parent = rootPart
    
    -- Setup float controls
    self:SetupFloatControls()
    
    self.floatEnabled = true
    Helpers.Notify("Player Mods", "🚀 Float enabled")
    return true, "Float enabled"
end

-- Disable float
function PlayerMods:DisableFloat()
    if self.floatBodyVelocity then
        self.floatBodyVelocity:Destroy()
        self.floatBodyVelocity = nil
    end
    
    if self.floatBodyPosition then
        self.floatBodyPosition:Destroy()
        self.floatBodyPosition = nil
    end
    
    -- Clean up float connections
    if self.connections.floatHeartbeat then
        self.connections.floatHeartbeat:Disconnect()
        self.connections.floatHeartbeat = nil
    end
    
    self.floatEnabled = false
    Helpers.Notify("Player Mods", "🚀 Float disabled")
    return true, "Float disabled"
end

-- Setup float controls
function PlayerMods:SetupFloatControls()
    if self.connections.floatHeartbeat then
        self.connections.floatHeartbeat:Disconnect()
    end
    
    self.connections.floatHeartbeat = RunService.Heartbeat:Connect(function()
        if not self.floatEnabled or not Helpers.IsCharacterValid() then return end
        
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not self.floatBodyVelocity or not self.floatBodyPosition then return end
        
        -- Get camera direction
        local camera = workspace.CurrentCamera
        local cameraCFrame = camera.CFrame
        
        -- Calculate movement vector
        local moveVector = Vector3.new(0, 0, 0)
        
        -- WASD movement
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + (cameraCFrame.LookVector * 50)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - (cameraCFrame.LookVector * 50)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - (cameraCFrame.RightVector * 50)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + (cameraCFrame.RightVector * 50)
        end
        
        -- Vertical movement
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, 50, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - Vector3.new(0, 50, 0)
        end
        
        -- Apply movement
        self.floatBodyVelocity.Velocity = moveVector
        
        -- Update float height
        if moveVector.Y == 0 then
            self.floatBodyPosition.Position = Vector3.new(
                rootPart.Position.X,
                rootPart.Position.Y,
                rootPart.Position.Z
            )
        end
    end)
end

-- Set float height
function PlayerMods:SetFloatHeight(height)
    height = Helpers.Clamp(height, 5, 100)
    self.floatHeight = height
    
    if self.floatEnabled and self.floatBodyPosition then
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            self.floatBodyPosition.Position = rootPart.Position + Vector3.new(0, height, 0)
        end
    end
    
    return true, "Float height set to " .. height
end

-- Enable no-clip
function PlayerMods:EnableNoClip()
    if not Helpers.IsCharacterValid() then
        return false, "Character not valid"
    end
    
    local character = LocalPlayer.Character
    
    -- Disable collisions for all parts
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = false
            table.insert(self.noClipParts, part)
        end
    end
    
    -- Setup no-clip monitoring
    if self.connections.noClipHeartbeat then
        self.connections.noClipHeartbeat:Disconnect()
    end
    
    self.connections.noClipHeartbeat = RunService.Heartbeat:Connect(function()
        if not self.noClipEnabled then return end
        
        for _, part in pairs(self.noClipParts) do
            if part and part.Parent then
                part.CanCollide = false
            end
        end
    end)
    
    self.noClipEnabled = true
    Helpers.Notify("Player Mods", "👻 No-clip enabled")
    return true, "No-clip enabled"
end

-- Disable no-clip
function PlayerMods:DisableNoClip()
    -- Re-enable collisions
    for _, part in pairs(self.noClipParts) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end
    
    self.noClipParts = {}
    
    -- Clean up connection
    if self.connections.noClipHeartbeat then
        self.connections.noClipHeartbeat:Disconnect()
        self.connections.noClipHeartbeat = nil
    end
    
    self.noClipEnabled = false
    Helpers.Notify("Player Mods", "👻 No-clip disabled")
    return true, "No-clip disabled"
end

-- Enable spinner
function PlayerMods:EnableSpinner()
    if not Helpers.IsCharacterValid() then
        return false, "Character not valid"
    end
    
    -- Clean up existing spinner
    self:DisableSpinner()
    
    self.connections.spinnerHeartbeat = RunService.Heartbeat:Connect(function()
        if not self.spinnerEnabled or not Helpers.IsCharacterValid() then return end
        
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- Rotate the character
        local rotation = CFrame.Angles(0, math.rad(self.spinnerSpeed * self.spinnerDirection), 0)
        rootPart.CFrame = rootPart.CFrame * rotation
    end)
    
    self.spinnerEnabled = true
    Helpers.Notify("Player Mods", "🌪️ Auto spinner enabled")
    return true, "Auto spinner enabled"
end

-- Disable spinner
function PlayerMods:DisableSpinner()
    if self.connections.spinnerHeartbeat then
        self.connections.spinnerHeartbeat:Disconnect()
        self.connections.spinnerHeartbeat = nil
    end
    
    self.spinnerEnabled = false
    Helpers.Notify("Player Mods", "🌪️ Auto spinner disabled")
    return true, "Auto spinner disabled"
end

-- Set spinner speed
function PlayerMods:SetSpinnerSpeed(speed)
    speed = Helpers.Clamp(speed, 0.1, 10)
    self.spinnerSpeed = speed
    return true, "Spinner speed set to " .. speed
end

-- Toggle spinner direction
function PlayerMods:ToggleSpinnerDirection()
    self.spinnerDirection = self.spinnerDirection * -1
    local direction = self.spinnerDirection > 0 and "clockwise" or "counter-clockwise"
    return true, "Spinner direction: " .. direction
end

-- Reset to original values
function PlayerMods:Reset()
    if not Helpers.IsCharacterValid() then
        return false, "Character not valid"
    end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid and self.originalValues.walkSpeed and self.originalValues.jumpPower then
        humanoid.WalkSpeed = self.originalValues.walkSpeed
        humanoid.JumpPower = self.originalValues.jumpPower
        
        self.walkSpeed = self.originalValues.walkSpeed
        self.jumpPower = self.originalValues.jumpPower
    end
    
    -- Disable all features
    self:DisableFloat()
    self:DisableNoClip()
    self:DisableSpinner()
    
    Helpers.Notify("Player Mods", "🔄 Reset to original values")
    return true, "Reset successful"
end

-- Toggle float
function PlayerMods:ToggleFloat()
    if self.floatEnabled then
        return self:DisableFloat()
    else
        return self:EnableFloat()
    end
end

-- Toggle no-clip
function PlayerMods:ToggleNoClip()
    if self.noClipEnabled then
        return self:DisableNoClip()
    else
        return self:EnableNoClip()
    end
end

-- Toggle spinner
function PlayerMods:ToggleSpinner()
    if self.spinnerEnabled then
        return self:DisableSpinner()
    else
        return self:EnableSpinner()
    end
end

-- Get status
function PlayerMods:GetStatus()
    return {
        walkSpeed = self.walkSpeed,
        jumpPower = self.jumpPower,
        floatEnabled = self.floatEnabled,
        floatHeight = self.floatHeight,
        noClipEnabled = self.noClipEnabled,
        spinnerEnabled = self.spinnerEnabled,
        spinnerSpeed = self.spinnerSpeed,
        spinnerDirection = self.spinnerDirection,
        originalValues = self.originalValues
    }
end

-- Update settings
function PlayerMods:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
    
    if newSettings.walkSpeed then
        self:SetWalkSpeed(newSettings.walkSpeed)
    end
    
    if newSettings.jumpPower then
        self:SetJumpPower(newSettings.jumpPower)
    end
    
    if newSettings.floatHeight then
        self:SetFloatHeight(newSettings.floatHeight)
    end
    
    if newSettings.spinnerSpeed then
        self:SetSpinnerSpeed(newSettings.spinnerSpeed)
    end
end

-- Cleanup
function PlayerMods:Destroy()
    self:Reset()
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    setmetatable(self, nil)
end

return PlayerMods
