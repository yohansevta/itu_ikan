-- teleport.lua
-- Teleport Module

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local Teleport = {}
Teleport.__index = Teleport

-- Constructor
function Teleport.new(settings)
    local self = setmetatable({}, Teleport)
    
    self.settings = settings or {}
    self.locations = self.settings.locations or {}
    self.currentLocation = "Unknown"
    self.lastTeleportTime = 0
    self.teleportCooldown = 1 -- seconds
    
    -- Auto-detect current location
    self:UpdateCurrentLocation()
    
    -- Start location tracking
    self:StartLocationTracking()
    
    return self
end

-- Update current location
function Teleport:UpdateCurrentLocation()
    self.currentLocation = Helpers.DetectCurrentLocation()
end

-- Start location tracking
function Teleport:StartLocationTracking()
    task.spawn(function()
        while true do
            self:UpdateCurrentLocation()
            task.wait(5) -- Update every 5 seconds
        end
    end)
end

-- Teleport to location by name
function Teleport:TeleportToLocation(locationName)
    local now = tick()
    if now - self.lastTeleportTime < self.teleportCooldown then
        return false, "Teleport on cooldown"
    end
    
    local cframe = self.locations[locationName]
    if not cframe then
        return false, "Location not found: " .. locationName
    end
    
    local success, message = Helpers.TeleportTo(cframe)
    if success then
        self.lastTeleportTime = now
        self.currentLocation = locationName:gsub("🏝️", ""):gsub("🦈 ", ""):gsub("🎣 ", ""):gsub("❄️ ", ""):gsub("🌋 ", ""):gsub("🌴 ", ""):gsub("🗿 ", ""):gsub("⚙️ ", ""):gsub("🎲 ", ""):trim()
        Helpers.Notify("Teleport", "Teleported to " .. locationName)
        return true, "Teleported successfully"
    else
        return false, message
    end
end

-- Teleport to CFrame directly
function Teleport:TeleportToCFrame(cframe, locationName)
    local now = tick()
    if now - self.lastTeleportTime < self.teleportCooldown then
        return false, "Teleport on cooldown"
    end
    
    local success, message = Helpers.TeleportTo(cframe)
    if success then
        self.lastTeleportTime = now
        if locationName then
            self.currentLocation = locationName
        end
        Helpers.Notify("Teleport", "Teleported to " .. (locationName or "custom location"))
        return true, "Teleported successfully"
    else
        return false, message
    end
end

-- Teleport to player
function Teleport:TeleportToPlayer(player)
    if type(player) == "string" then
        player = Players:FindFirstChild(player)
    end
    
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false, "Player not found or invalid"
    end
    
    if player == LocalPlayer then
        return false, "Cannot teleport to yourself"
    end
    
    local now = tick()
    if now - self.lastTeleportTime < self.teleportCooldown then
        return false, "Teleport on cooldown"
    end
    
    local targetCFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    local success, message = Helpers.TeleportTo(targetCFrame)
    
    if success then
        self.lastTeleportTime = now
        self.currentLocation = "Near " .. player.DisplayName
        Helpers.Notify("Teleport", "Teleported to " .. player.DisplayName)
        return true, "Teleported successfully"
    else
        return false, message
    end
end

-- Get available locations
function Teleport:GetLocations()
    local locationList = {}
    for name, cframe in pairs(self.locations) do
        table.insert(locationList, {
            name = name,
            cframe = cframe,
            isCurrent = name:find(self.currentLocation) ~= nil
        })
    end
    return locationList
end

-- Add custom location
function Teleport:AddLocation(name, cframe)
    if type(cframe) ~= "userdata" or not cframe.X then
        return false, "Invalid CFrame"
    end
    
    self.locations[name] = cframe
    return true, "Location added: " .. name
end

-- Remove location
function Teleport:RemoveLocation(name)
    if not self.locations[name] then
        return false, "Location not found: " .. name
    end
    
    self.locations[name] = nil
    return true, "Location removed: " .. name
end

-- Save current position as location
function Teleport:SaveCurrentPosition(name)
    if not Helpers.IsCharacterValid() then
        return false, "Character not valid"
    end
    
    local currentCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    return self:AddLocation(name, currentCFrame)
end

-- Get current position
function Teleport:GetCurrentPosition()
    if not Helpers.IsCharacterValid() then
        return nil, "Character not valid"
    end
    
    return LocalPlayer.Character.HumanoidRootPart.CFrame
end

-- Get current location name
function Teleport:GetCurrentLocation()
    return self.currentLocation
end

-- Teleport to best fishing spot based on time
function Teleport:TeleportToBestFishingSpot(timeOfDay)
    timeOfDay = timeOfDay or os.date("%H")
    local hour = tonumber(timeOfDay)
    
    -- Best fishing spots by time
    local bestSpots = {
        [0] = "🏝️ Esoteric Depths",   -- Midnight
        [1] = "🏝️ Esoteric Depths",
        [2] = "🏝️ Lost Isle",
        [3] = "🏝️ Lost Isle",
        [4] = "🏝️ Lost Isle",
        [5] = "🏝️ Stingray Shores",   -- Dawn
        [6] = "🏝️ Stingray Shores",
        [7] = "🏝️ Coral Reefs",
        [8] = "🏝️ Coral Reefs",
        [9] = "🏝️ Tropical Grove",
        [10] = "🏝️ Tropical Grove",
        [11] = "🏝️ Kohana",          -- Morning
        [12] = "🏝️ Kohana",          -- Noon
        [13] = "🏝️ Kohana Volcano",
        [14] = "🏝️ Kohana Volcano",
        [15] = "🏝️ Crater Island",
        [16] = "🏝️ Crater Island",
        [17] = "🏝️ Tropical Grove",   -- Evening
        [18] = "🏝️ Coral Reefs",
        [19] = "🏝️ Stingray Shores",
        [20] = "🏝️ Lost Isle",
        [21] = "🏝️ Lost Isle",       -- Night
        [22] = "🏝️ Esoteric Depths",
        [23] = "🏝️ Esoteric Depths"
    }
    
    local bestSpot = bestSpots[hour] or "🏝️ Kohana"
    return self:TeleportToLocation(bestSpot)
end

-- Quick teleport to common locations
function Teleport:QuickTeleport(location)
    local quickLocations = {
        home = "🏝️ Kohana",
        shop = "🏝️ Kohana",
        altar = "🎲 ENCHANT STONE",
        machine = "⚙️ MACHINE",
        volcano = "🏝️ Kohana Volcano",
        depths = "🏝️ Esoteric Depths",
        shores = "🏝️ Stingray Shores",
        reefs = "🏝️ Coral Reefs",
        grove = "🏝️ Tropical Grove",
        crater = "🏝️ Crater Island",
        isle = "🏝️ Lost Isle"
    }
    
    local targetLocation = quickLocations[location:lower()]
    if targetLocation then
        return self:TeleportToLocation(targetLocation)
    else
        return false, "Quick location not found: " .. location
    end
end

-- Teleport to random location
function Teleport:TeleportToRandom()
    local locationNames = {}
    for name, _ in pairs(self.locations) do
        table.insert(locationNames, name)
    end
    
    if #locationNames == 0 then
        return false, "No locations available"
    end
    
    local randomLocation = locationNames[math.random(1, #locationNames)]
    return self:TeleportToLocation(randomLocation)
end

-- Get distance to location
function Teleport:GetDistanceToLocation(locationName)
    if not Helpers.IsCharacterValid() then
        return nil, "Character not valid"
    end
    
    local targetCFrame = self.locations[locationName]
    if not targetCFrame then
        return nil, "Location not found"
    end
    
    local currentPosition = LocalPlayer.Character.HumanoidRootPart.Position
    local targetPosition = targetCFrame.Position
    
    return (currentPosition - targetPosition).Magnitude
end

-- Get nearest location
function Teleport:GetNearestLocation()
    if not Helpers.IsCharacterValid() then
        return nil, "Character not valid"
    end
    
    local nearestLocation = nil
    local shortestDistance = math.huge
    
    for name, cframe in pairs(self.locations) do
        local distance = self:GetDistanceToLocation(name)
        if distance and distance < shortestDistance then
            shortestDistance = distance
            nearestLocation = name
        end
    end
    
    return nearestLocation, shortestDistance
end

-- Teleport history
function Teleport:GetTeleportHistory()
    return self.teleportHistory or {}
end

-- Update settings
function Teleport:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
    if newSettings.locations then
        self.locations = newSettings.locations
    end
end

-- Get status
function Teleport:GetStatus()
    return {
        currentLocation = self.currentLocation,
        totalLocations = #self:GetLocations(),
        lastTeleportTime = self.lastTeleportTime,
        cooldownRemaining = math.max(0, self.teleportCooldown - (tick() - self.lastTeleportTime))
    }
end

-- Cleanup
function Teleport:Destroy()
    setmetatable(self, nil)
end

return Teleport
