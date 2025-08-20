-- dashboard.lua
-- Dashboard and Statistics Module

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local Dashboard = {}
Dashboard.__index = Dashboard

-- Constructor
function Dashboard.new(settings)
    local self = setmetatable({}, Dashboard)
    
    self.settings = settings or {}
    
    -- Session statistics
    self.sessionStats = {
        startTime = tick(),
        fishCount = 0,
        rareCount = 0,
        totalValue = 0,
        currentLocation = "Unknown",
        sessionDuration = 0,
        bestHour = 0,
        bestHourCount = 0
    }
    
    -- Detailed fish data
    self.fishCaught = {}
    self.rareFishCaught = {}
    
    -- Location statistics
    self.locationStats = {}
    
    -- Time-based analytics
    self.optimalTimes = {}
    
    -- Heat map data
    self.heatmap = {}
    
    -- Real-time tracking
    self.isTracking = false
    self.trackingConnection = nil
    
    self:Initialize()
    
    return self
end

-- Initialize dashboard
function Dashboard:Initialize()
    self:StartTracking()
    self:LoadSavedData()
end

-- Start real-time tracking
function Dashboard:StartTracking()
    if self.isTracking then return end
    
    self.isTracking = true
    self.trackingConnection = RunService.Heartbeat:Connect(function()
        self:UpdateSessionDuration()
        self:UpdateCurrentLocation()
    end)
end

-- Stop tracking
function Dashboard:StopTracking()
    if not self.isTracking then return end
    
    self.isTracking = false
    if self.trackingConnection then
        self.trackingConnection:Disconnect()
        self.trackingConnection = nil
    end
end

-- Update session duration
function Dashboard:UpdateSessionDuration()
    self.sessionStats.sessionDuration = tick() - self.sessionStats.startTime
end

-- Update current location
function Dashboard:UpdateCurrentLocation()
    local newLocation = Helpers.DetectCurrentLocation()
    if newLocation ~= self.sessionStats.currentLocation then
        self.sessionStats.currentLocation = newLocation
    end
end

-- Log fish catch
function Dashboard:LogFishCatch(fishName, location, rarity, value)
    location = location or self.sessionStats.currentLocation
    rarity = rarity or Helpers.GetFishRarity(fishName)
    value = value or self:EstimateFishValue(fishName, rarity)
    
    -- Update session stats
    self.sessionStats.fishCount = self.sessionStats.fishCount + 1
    self.sessionStats.totalValue = self.sessionStats.totalValue + (value or 0)
    
    -- Create fish entry
    local fishEntry = {
        name = fishName,
        rarity = rarity,
        value = value,
        location = location,
        timestamp = tick(),
        time = os.date("%H:%M:%S"),
        date = os.date("%Y-%m-%d")
    }
    
    -- Add to fish caught list
    table.insert(self.fishCaught, fishEntry)
    
    -- Track rare fish
    if rarity == "Rare" or rarity == "Legendary" or rarity == "Mythical" then
        self.sessionStats.rareCount = self.sessionStats.rareCount + 1
        table.insert(self.rareFishCaught, fishEntry)
    end
    
    -- Update location stats
    self:UpdateLocationStats(location, rarity)
    
    -- Update time analytics
    self:UpdateTimeAnalytics(rarity)
    
    -- Update heatmap
    self:UpdateHeatmap(location, rarity)
    
    -- Auto-save if enabled
    if self.settings.autoSaveStats then
        self:SaveData()
    end
    
    return fishEntry
end

-- Update location statistics
function Dashboard:UpdateLocationStats(location, rarity)
    if not self.locationStats[location] then
        self.locationStats[location] = {
            total = 0,
            common = 0,
            uncommon = 0,
            rare = 0,
            legendary = 0,
            mythical = 0,
            bestTime = 0,
            efficiency = 0
        }
    end
    
    local stats = self.locationStats[location]
    stats.total = stats.total + 1
    
    if rarity then
        local rarityKey = rarity:lower()
        if stats[rarityKey] then
            stats[rarityKey] = stats[rarityKey] + 1
        end
    end
    
    -- Calculate efficiency (rare fish percentage)
    stats.efficiency = ((stats.rare + stats.legendary + stats.mythical) / stats.total) * 100
end

-- Update time analytics
function Dashboard:UpdateTimeAnalytics(rarity)
    local hour = tonumber(os.date("%H"))
    
    if not self.optimalTimes[hour] then
        self.optimalTimes[hour] = {
            total = 0,
            rare = 0,
            efficiency = 0
        }
    end
    
    local timeData = self.optimalTimes[hour]
    timeData.total = timeData.total + 1
    
    if rarity == "Rare" or rarity == "Legendary" or rarity == "Mythical" then
        timeData.rare = timeData.rare + 1
    end
    
    -- Calculate efficiency
    timeData.efficiency = (timeData.rare / timeData.total) * 100
    
    -- Update best hour
    if timeData.efficiency > self.sessionStats.bestHourCount then
        self.sessionStats.bestHour = hour
        self.sessionStats.bestHourCount = timeData.efficiency
    end
end

-- Update heatmap data
function Dashboard:UpdateHeatmap(location, rarity)
    if not self.heatmap[location] then
        self.heatmap[location] = {
            intensity = 0,
            rareIntensity = 0,
            lastUpdate = tick()
        }
    end
    
    local heatData = self.heatmap[location]
    heatData.intensity = heatData.intensity + 1
    heatData.lastUpdate = tick()
    
    if rarity == "Rare" or rarity == "Legendary" or rarity == "Mythical" then
        heatData.rareIntensity = heatData.rareIntensity + 1
    end
end

-- Estimate fish value based on name and rarity
function Dashboard:EstimateFishValue(fishName, rarity)
    local baseValues = {
        Common = {min = 10, max = 50},
        Uncommon = {min = 40, max = 120},
        Rare = {min = 100, max = 300},
        Legendary = {min = 250, max = 800},
        Mythical = {min = 500, max = 2000}
    }
    
    local range = baseValues[rarity] or baseValues.Common
    return math.random(range.min, range.max)
end

-- Get session statistics
function Dashboard:GetSessionStats()
    self:UpdateSessionDuration()
    
    local stats = Helpers.DeepCopy(self.sessionStats)
    
    -- Calculate rates
    local hours = stats.sessionDuration / 3600
    stats.fishPerHour = hours > 0 and (stats.fishCount / hours) or 0
    stats.rarePerHour = hours > 0 and (stats.rareCount / hours) or 0
    stats.valuePerHour = hours > 0 and (stats.totalValue / hours) or 0
    
    -- Calculate percentages
    stats.rarePercentage = stats.fishCount > 0 and (stats.rareCount / stats.fishCount) * 100 or 0
    
    -- Format duration
    stats.formattedDuration = Helpers.FormatTime(stats.sessionDuration)
    
    return stats
end

-- Get location statistics
function Dashboard:GetLocationStats()
    local stats = {}
    
    for location, data in pairs(self.locationStats) do
        local locationStat = Helpers.DeepCopy(data)
        locationStat.location = location
        locationStat.rareCount = data.rare + data.legendary + data.mythical
        locationStat.rarePercentage = data.total > 0 and (locationStat.rareCount / data.total) * 100 or 0
        table.insert(stats, locationStat)
    end
    
    -- Sort by efficiency
    table.sort(stats, function(a, b) return a.efficiency > b.efficiency end)
    
    return stats
end

-- Get time analytics
function Dashboard:GetTimeAnalytics()
    local analytics = {}
    
    for hour, data in pairs(self.optimalTimes) do
        local timeData = Helpers.DeepCopy(data)
        timeData.hour = hour
        timeData.formattedHour = string.format("%02d:00", hour)
        table.insert(analytics, timeData)
    end
    
    -- Sort by hour
    table.sort(analytics, function(a, b) return a.hour < b.hour end)
    
    return analytics
end

-- Get best fishing times
function Dashboard:GetBestFishingTimes(count)
    count = count or 5
    local analytics = self:GetTimeAnalytics()
    
    -- Sort by efficiency
    table.sort(analytics, function(a, b) return a.efficiency > b.efficiency end)
    
    local bestTimes = {}
    for i = 1, math.min(count, #analytics) do
        table.insert(bestTimes, analytics[i])
    end
    
    return bestTimes
end

-- Get recent catches
function Dashboard:GetRecentCatches(count)
    count = count or 20
    local recentCatches = {}
    
    local startIndex = math.max(1, #self.fishCaught - count + 1)
    for i = startIndex, #self.fishCaught do
        table.insert(recentCatches, self.fishCaught[i])
    end
    
    -- Reverse to show newest first
    local reversed = {}
    for i = #recentCatches, 1, -1 do
        table.insert(reversed, recentCatches[i])
    end
    
    return reversed
end

-- Get rare fish summary
function Dashboard:GetRareFishSummary()
    local summary = {
        total = #self.rareFishCaught,
        byRarity = {
            Rare = 0,
            Legendary = 0,
            Mythical = 0
        },
        byLocation = {},
        mostRecent = nil
    }
    
    for _, fish in pairs(self.rareFishCaught) do
        -- Count by rarity
        if summary.byRarity[fish.rarity] then
            summary.byRarity[fish.rarity] = summary.byRarity[fish.rarity] + 1
        end
        
        -- Count by location
        if not summary.byLocation[fish.location] then
            summary.byLocation[fish.location] = 0
        end
        summary.byLocation[fish.location] = summary.byLocation[fish.location] + 1
        
        -- Track most recent
        if not summary.mostRecent or fish.timestamp > summary.mostRecent.timestamp then
            summary.mostRecent = fish
        end
    end
    
    return summary
end

-- Get efficiency report
function Dashboard:GetEfficiencyReport()
    local stats = self:GetSessionStats()
    local locationStats = self:GetLocationStats()
    local timeAnalytics = self:GetTimeAnalytics()
    
    return {
        session = stats,
        bestLocation = locationStats[1],
        worstLocation = locationStats[#locationStats],
        bestTime = self:GetBestFishingTimes(1)[1],
        currentEfficiency = stats.rarePercentage,
        recommendations = self:GenerateRecommendations()
    }
end

-- Generate recommendations
function Dashboard:GenerateRecommendations()
    local recommendations = {}
    local stats = self:GetSessionStats()
    local locationStats = self:GetLocationStats()
    local bestTimes = self:GetBestFishingTimes(3)
    
    -- Location recommendations
    if #locationStats > 0 and locationStats[1].efficiency > 20 then
        table.insert(recommendations, {
            type = "location",
            message = "🏝️ " .. locationStats[1].location .. " has the highest rare fish rate (" .. 
                     string.format("%.1f", locationStats[1].efficiency) .. "%)"
        })
    end
    
    -- Time recommendations
    if #bestTimes > 0 and bestTimes[1].efficiency > 15 then
        table.insert(recommendations, {
            type = "time",
            message = "⏰ Best fishing time is " .. bestTimes[1].formattedHour .. 
                     " with " .. string.format("%.1f", bestTimes[1].efficiency) .. "% rare rate"
        })
    end
    
    -- General recommendations
    if stats.fishCount > 100 and stats.rarePercentage < 10 then
        table.insert(recommendations, {
            type = "general",
            message = "🎣 Consider changing locations or fishing times to improve rare fish rate"
        })
    end
    
    if stats.sessionDuration > 3600 and stats.fishPerHour < 30 then
        table.insert(recommendations, {
            type = "general",
            message = "⚡ Consider using faster fishing mode to increase catch rate"
        })
    end
    
    return recommendations
end

-- Reset statistics
function Dashboard:Reset()
    self.sessionStats = {
        startTime = tick(),
        fishCount = 0,
        rareCount = 0,
        totalValue = 0,
        currentLocation = Helpers.DetectCurrentLocation(),
        sessionDuration = 0,
        bestHour = 0,
        bestHourCount = 0
    }
    
    self.fishCaught = {}
    self.rareFishCaught = {}
    self.locationStats = {}
    self.optimalTimes = {}
    self.heatmap = {}
    
    Helpers.Notify("Dashboard", "📊 Statistics reset")
end

-- Export statistics
function Dashboard:ExportStats()
    if not self.settings.exportStats then return nil end
    
    local exportData = {
        sessionStats = self:GetSessionStats(),
        locationStats = self:GetLocationStats(),
        timeAnalytics = self:GetTimeAnalytics(),
        recentCatches = self:GetRecentCatches(50),
        rareFishSummary = self:GetRareFishSummary(),
        exportTime = os.date("%Y-%m-%d %H:%M:%S"),
        totalFishCaught = #self.fishCaught,
        totalRareFish = #self.rareFishCaught
    }
    
    return exportData
end

-- Save data
function Dashboard:SaveData()
    if not self.settings.autoSaveStats then return end
    
    local saveData = {
        fishCaught = self.fishCaught,
        rareFishCaught = self.rareFishCaught,
        locationStats = self.locationStats,
        optimalTimes = self.optimalTimes,
        heatmap = self.heatmap,
        sessionStats = self.sessionStats,
        lastSave = tick()
    }
    
    -- Save using writefile if available
    pcall(function()
        if writefile then
            writefile("itu_ikan_stats.json", game:GetService("HttpService"):JSONEncode(saveData))
        end
    end)
end

-- Load saved data
function Dashboard:LoadSavedData()
    pcall(function()
        if readfile and isfile and isfile("itu_ikan_stats.json") then
            local data = game:GetService("HttpService"):JSONDecode(readfile("itu_ikan_stats.json"))
            
            if data then
                self.fishCaught = data.fishCaught or {}
                self.rareFishCaught = data.rareFishCaught or {}
                self.locationStats = data.locationStats or {}
                self.optimalTimes = data.optimalTimes or {}
                self.heatmap = data.heatmap or {}
                
                Helpers.Notify("Dashboard", "📊 Loaded saved statistics")
            end
        end
    end)
end

-- Update settings
function Dashboard:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
end

-- Get status
function Dashboard:GetStatus()
    return {
        isTracking = self.isTracking,
        totalFishCaught = #self.fishCaught,
        totalRareFish = #self.rareFishCaught,
        totalLocations = Helpers.TableLength(self.locationStats),
        sessionDuration = self.sessionStats.sessionDuration,
        currentLocation = self.sessionStats.currentLocation
    }
end

-- Cleanup
function Dashboard:Destroy()
    self:StopTracking()
    if self.settings.autoSaveStats then
        self:SaveData()
    end
    setmetatable(self, nil)
end

return Dashboard
