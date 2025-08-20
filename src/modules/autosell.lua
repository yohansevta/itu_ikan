-- autosell.lua
-- Auto Sell Module

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Helpers = require(script.Parent.Parent.utils.helpers)

local AutoSell = {}
AutoSell.__index = AutoSell

-- Constructor
function AutoSell.new(settings)
    local self = setmetatable({}, AutoSell)
    
    self.settings = settings or {}
    self.enabled = self.settings.enabled or false
    self.threshold = self.settings.threshold or 50
    self.autoReturn = self.settings.autoReturn or true
    self.sellDelay = self.settings.sellDelay or 2.0
    
    -- Sell filters
    self.sellFilters = {
        common = self.settings.sellCommon or true,
        uncommon = self.settings.sellUncommon or true,
        rare = self.settings.sellRare or false,
        legendary = self.settings.sellLegendary or false,
        mythical = self.settings.sellMythical or false
    }
    
    -- State
    self.isCurrentlySelling = false
    self.sellCount = {
        common = 0,
        uncommon = 0,
        rare = 0,
        legendary = 0,
        mythical = 0
    }
    
    -- Server sync
    self.serverThreshold = self.threshold
    self.isThresholdSynced = false
    self.lastSyncTime = 0
    self.syncRetries = 0
    
    -- Get remotes
    self:InitializeRemotes()
    
    return self
end

-- Initialize remotes
function AutoSell:InitializeRemotes()
    self.remotes = {
        sellAll = Helpers.ResolveRemote("RF/SellAllItems"),
        sellItem = Helpers.ResolveRemote("RF/SellItem"),
        getInventory = Helpers.ResolveRemote("RF/GetInventory")
    }
end

-- Add fish to sell count
function AutoSell:AddFish(fishName, rarity)
    rarity = rarity or Helpers.GetFishRarity(fishName)
    local rarityKey = rarity:lower()
    
    if self.sellCount[rarityKey] then
        self.sellCount[rarityKey] = self.sellCount[rarityKey] + 1
    end
    
    -- Check if we should auto sell
    if self.enabled then
        self:CheckAndAutoSell()
    end
end

-- Check if we should auto sell
function AutoSell:CheckAndAutoSell()
    if self.isCurrentlySelling then return end
    
    local totalSellableFish = 0
    
    -- Count sellable fish based on filters
    for rarity, count in pairs(self.sellCount) do
        if self.sellFilters[rarity] then
            totalSellableFish = totalSellableFish + count
        end
    end
    
    if totalSellableFish >= self.threshold then
        self:ExecuteAutoSell()
    end
end

-- Execute auto sell
function AutoSell:ExecuteAutoSell()
    if self.isCurrentlySelling then 
        return false, "Already selling"
    end
    
    if not Helpers.IsCharacterValid() then
        return false, "Character not valid"
    end
    
    self.isCurrentlySelling = true
    
    task.spawn(function()
        local success, message = self:PerformSell()
        if success then
            self:ResetSellCounts()
            Helpers.Notify("Auto Sell", "✅ Auto sell completed successfully!")
        else
            Helpers.Notify("Auto Sell", "❌ Auto sell failed: " .. (message or "Unknown error"))
        end
        self.isCurrentlySelling = false
    end)
    
    return true, "Auto sell started"
end

-- Perform the actual selling
function AutoSell:PerformSell()
    local originalCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    
    -- Try to find NPC or use fallback coordinates
    local sellNpc = self:FindSellNPC()
    local sellLocation = sellNpc and sellNpc.WorldPivot or CFrame.new(-31.10, 4.84, 2899.03)
    
    -- Teleport to seller
    local teleportSuccess = pcall(function()
        LocalPlayer.Character.HumanoidRootPart.CFrame = sellLocation
    end)
    
    if not teleportSuccess then
        return false, "Failed to teleport to shop"
    end
    
    task.wait(self.sellDelay)
    
    -- Count sellable fish before selling
    local totalFishToSell = 0
    for rarity, count in pairs(self.sellCount) do
        if self.sellFilters[rarity] then
            totalFishToSell = totalFishToSell + count
        end
    end
    
    Helpers.Notify("Auto Sell", string.format("🚀 Selling %d fish (Threshold: %d)", totalFishToSell, self.threshold))
    
    -- Execute sell
    local sellSuccess = false
    if self.remotes.sellAll then
        sellSuccess = pcall(function()
            if self.remotes.sellAll:IsA("RemoteFunction") then
                return self.remotes.sellAll:InvokeServer()
            else
                self.remotes.sellAll:FireServer()
                return true
            end
        end)
    end
    
    task.wait(1.5)
    
    -- Return to original position if enabled
    if self.autoReturn then
        local returnSuccess = pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
            end
        end)
        
        if returnSuccess then
            Helpers.Notify("Auto Sell", "🏠 Returned to fishing spot")
        end
    end
    
    return sellSuccess, sellSuccess and "Sell completed" or "Sell failed"
end

-- Find sell NPC
function AutoSell:FindSellNPC()
    local npcContainer = ReplicatedStorage:FindFirstChild("NPC")
    if npcContainer then
        return npcContainer:FindFirstChild("Alex") or npcContainer:FindFirstChild("Shop")
    end
    return nil
end

-- Reset sell counts
function AutoSell:ResetSellCounts()
    for rarity, _ in pairs(self.sellCount) do
        self.sellCount[rarity] = 0
    end
end

-- Manual sell
function AutoSell:ManualSell()
    return self:ExecuteAutoSell()
end

-- Enable auto sell
function AutoSell:Enable()
    self.enabled = true
    Helpers.Notify("Auto Sell", "💰 Auto sell enabled")
    return true, "Auto sell enabled"
end

-- Disable auto sell
function AutoSell:Disable()
    self.enabled = false
    Helpers.Notify("Auto Sell", "💰 Auto sell disabled")
    return true, "Auto sell disabled"
end

-- Toggle auto sell
function AutoSell:Toggle()
    if self.enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

-- Set threshold
function AutoSell:SetThreshold(threshold)
    if threshold < 1 or threshold > 1000 then
        return false, "Threshold must be between 1 and 1000"
    end
    
    self.threshold = threshold
    
    -- Sync with server if available
    task.spawn(function()
        self:SyncWithServer()
    end)
    
    return true, "Threshold set to " .. threshold
end

-- Set sell filter for rarity
function AutoSell:SetSellFilter(rarity, enabled)
    local rarityKey = rarity:lower()
    if self.sellFilters[rarityKey] ~= nil then
        self.sellFilters[rarityKey] = enabled
        return true, rarity .. " fish selling: " .. (enabled and "enabled" or "disabled")
    end
    return false, "Invalid rarity: " .. rarity
end

-- Get sell filters
function AutoSell:GetSellFilters()
    return Helpers.DeepCopy(self.sellFilters)
end

-- Sync with server
function AutoSell:SyncWithServer()
    local syncRemote = Helpers.ResolveRemote("RF/UpdateAutoSellThreshold")
    if not syncRemote then
        return false, "Sync remote not found"
    end
    
    local success = pcall(function()
        if syncRemote:IsA("RemoteFunction") then
            self.serverThreshold = syncRemote:InvokeServer(self.threshold)
        else
            syncRemote:FireServer(self.threshold)
        end
    end)
    
    if success then
        self.isThresholdSynced = (self.serverThreshold == self.threshold)
        self.lastSyncTime = tick()
        self.syncRetries = 0
        return true, "Sync successful"
    else
        self.syncRetries = self.syncRetries + 1
        return false, "Sync failed"
    end
end

-- Get inventory count (if remote available)
function AutoSell:GetInventoryCount()
    if not self.remotes.getInventory then
        return nil, "Inventory remote not available"
    end
    
    local success, inventory = pcall(function()
        return self.remotes.getInventory:InvokeServer()
    end)
    
    if success and inventory then
        local counts = {
            total = 0,
            common = 0,
            uncommon = 0,
            rare = 0,
            legendary = 0,
            mythical = 0
        }
        
        for _, item in pairs(inventory) do
            if item.type == "fish" then
                counts.total = counts.total + (item.quantity or 1)
                local rarity = Helpers.GetFishRarity(item.name):lower()
                if counts[rarity] then
                    counts[rarity] = counts[rarity] + (item.quantity or 1)
                end
            end
        end
        
        return counts, "Inventory retrieved"
    end
    
    return nil, "Failed to get inventory"
end

-- Estimate sell value
function AutoSell:EstimateSellValue()
    local totalValue = 0
    local fishValues = {
        common = 25,
        uncommon = 75,
        rare = 200,
        legendary = 500,
        mythical = 1250
    }
    
    for rarity, count in pairs(self.sellCount) do
        if self.sellFilters[rarity] then
            totalValue = totalValue + (count * (fishValues[rarity] or 0))
        end
    end
    
    return totalValue
end

-- Get sell summary
function AutoSell:GetSellSummary()
    local sellableFish = 0
    local totalValue = 0
    local fishValues = {
        common = 25,
        uncommon = 75,
        rare = 200,
        legendary = 500,
        mythical = 1250
    }
    
    local breakdown = {}
    
    for rarity, count in pairs(self.sellCount) do
        if self.sellFilters[rarity] and count > 0 then
            sellableFish = sellableFish + count
            local value = count * (fishValues[rarity] or 0)
            totalValue = totalValue + value
            
            table.insert(breakdown, {
                rarity = rarity,
                count = count,
                value = value,
                enabled = true
            })
        elseif count > 0 then
            table.insert(breakdown, {
                rarity = rarity,
                count = count,
                value = count * (fishValues[rarity] or 0),
                enabled = false
            })
        end
    end
    
    return {
        totalSellableFish = sellableFish,
        estimatedValue = totalValue,
        threshold = self.threshold,
        readyToSell = sellableFish >= self.threshold,
        breakdown = breakdown
    }
end

-- Get status
function AutoSell:GetStatus()
    return {
        enabled = self.enabled,
        threshold = self.threshold,
        isCurrentlySelling = self.isCurrentlySelling,
        sellCount = Helpers.DeepCopy(self.sellCount),
        sellFilters = Helpers.DeepCopy(self.sellFilters),
        serverThreshold = self.serverThreshold,
        isThresholdSynced = self.isThresholdSynced,
        lastSyncTime = self.lastSyncTime,
        syncRetries = self.syncRetries,
        sellSummary = self:GetSellSummary()
    }
end

-- Update settings
function AutoSell:UpdateSettings(newSettings)
    self.settings = Helpers.MergeTables(self.settings, newSettings)
    
    if newSettings.enabled ~= nil then
        self.enabled = newSettings.enabled
    end
    
    if newSettings.threshold then
        self:SetThreshold(newSettings.threshold)
    end
    
    if newSettings.autoReturn ~= nil then
        self.autoReturn = newSettings.autoReturn
    end
    
    if newSettings.sellDelay then
        self.sellDelay = newSettings.sellDelay
    end
    
    -- Update sell filters
    for rarity, enabled in pairs(newSettings) do
        if self.sellFilters[rarity:lower()] ~= nil then
            self.sellFilters[rarity:lower()] = enabled
        end
    end
end

-- Cleanup
function AutoSell:Destroy()
    setmetatable(self, nil)
end

return AutoSell
