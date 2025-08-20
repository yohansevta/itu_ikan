-- helpers.lua
-- Utility functions and helpers

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Helpers = {}

-- Notification system
function Helpers.Notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
    if _G.ITU_IKAN_DEBUG then
        print("[ITU IKAN]", title, text)
    end
end

-- Get server time
function Helpers.GetServerTime()
    local ok, st = pcall(function() 
        return workspace:GetServerTimeNow() 
    end)
    if ok and type(st) == "number" then 
        return st 
    end
    return tick()
end

-- Safe remote invocation
function Helpers.SafeInvoke(remote, ...)
    if not remote then 
        return false, "nil_remote" 
    end
    
    local args = {...}
    local success, result = pcall(function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args))
        else
            remote:FireServer(unpack(args))
            return true
        end
    end)
    
    return success, result
end

-- Find network module
function Helpers.FindNet()
    local ok, net = pcall(function()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if not packages then return nil end
        local idx = packages:FindFirstChild("_Index")
        if not idx then return nil end
        local sleit = idx:FindFirstChild("sleitnick_net@0.2.0")
        if not sleit then return nil end
        return sleit:FindFirstChild("net")
    end)
    return ok and net or nil
end

-- Resolve remote
function Helpers.ResolveRemote(name)
    local net = Helpers.FindNet()
    if not net then return nil end
    local ok, rem = pcall(function() 
        return net:FindFirstChild(name) 
    end)
    return ok and rem or nil
end

-- Get realistic timing for fishing actions
function Helpers.GetRealisticTiming(action)
    local timings = {
        charging = 0.8 + math.random() * 0.4,
        casting = 0.3 + math.random() * 0.2,
        waiting = 1.5 + math.random() * 1.0,
        reeling = 0.5 + math.random() * 0.3
    }
    return timings[action] or 0.5
end

-- Generate random delay for anti-detection
function Helpers.GetRandomDelay(min, max)
    min = min or 0.1
    max = max or 0.3
    return min + math.random() * (max - min)
end

-- Check if player character exists and is valid
function Helpers.IsCharacterValid()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    return humanoid and rootPart and humanoid.Health > 0
end

-- Get equipped tool
function Helpers.GetEquippedTool()
    if not Helpers.IsCharacterValid() then return nil end
    return LocalPlayer.Character:FindFirstChildOfClass("Tool")
end

-- Check if equipped tool is a fishing rod
function Helpers.IsRodEquipped()
    local tool = Helpers.GetEquippedTool()
    if not tool then return false end
    
    local name = tool.Name:lower()
    return name:find("rod") or 
           tool:FindFirstChild("Rod") or 
           tool:FindFirstChild("Handle")
end

-- Detect current location based on player position
function Helpers.DetectCurrentLocation()
    if not Helpers.IsCharacterValid() then return "Unknown" end
    
    local position = LocalPlayer.Character.HumanoidRootPart.Position
    local x, y, z = position.X, position.Y, position.Z
    
    -- Location detection based on coordinates
    if math.abs(x - (-594)) < 200 and math.abs(z - 149) < 200 then
        return "Kohana Volcano"
    elseif math.abs(x - 1010) < 200 and math.abs(z - 5078) < 200 then
        return "Crater Island"
    elseif math.abs(x - (-650)) < 200 and math.abs(z - 711) < 200 then
        return "Kohana"
    elseif math.abs(x - (-3618)) < 200 and math.abs(z - (-1317)) < 200 then
        return "Lost Isle"
    elseif math.abs(x - 45) < 200 and math.abs(z - 2987) < 200 then
        return "Stingray Shores"
    elseif math.abs(x - 1944) < 200 and math.abs(z - 1371) < 200 then
        return "Esoteric Depths"
    elseif math.abs(x - (-2095)) < 200 and math.abs(z - 3718) < 200 then
        return "Tropical Grove"
    elseif math.abs(x - (-3023)) < 200 and math.abs(z - 2195) < 200 then
        return "Coral Reefs"
    else
        return "Ocean"
    end
end

-- Get fish rarity
function Helpers.GetFishRarity(fishName)
    local rareFish = {
        "Hammerhead Shark", "Manta Ray", "Enchanted Angelfish", 
        "Magic Tang", "Blueflame Ray", "Abyss Seahorse"
    }
    
    local legendaryFish = {
        "Golden Bass", "Diamond Trout", "Mythical Salmon"
    }
    
    local mythicalFish = {
        "Ancient Leviathan", "Cosmic Ray", "Time Fish"
    }
    
    fishName = fishName or ""
    
    for _, fish in pairs(mythicalFish) do
        if fishName:find(fish) then return "Mythical" end
    end
    
    for _, fish in pairs(legendaryFish) do
        if fishName:find(fish) then return "Legendary" end
    end
    
    for _, fish in pairs(rareFish) do
        if fishName:find(fish) then return "Rare" end
    end
    
    return "Common"
end

-- Teleport player to position
function Helpers.TeleportTo(cframe)
    if not Helpers.IsCharacterValid() then 
        return false, "Character not valid"
    end
    
    local success = pcall(function()
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
    end)
    
    return success, success and "Teleported successfully" or "Teleport failed"
end

-- Get player list
function Helpers.GetPlayerList(filter)
    local playerList = {}
    filter = filter and filter:lower() or ""
    
    for _, player in pairs(Players:GetPlayers()) do
        if filter == "" or 
           player.Name:lower():find(filter) or 
           player.DisplayName:lower():find(filter) then
            table.insert(playerList, {
                name = player.Name,
                displayName = player.DisplayName,
                player = player,
                isLocal = player == LocalPlayer
            })
        end
    end
    
    return playerList
end

-- Format time duration
function Helpers.FormatTime(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%dm %.1fs", minutes, secs)
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%dh %dm", hours, minutes)
    end
end

-- Format number with commas
function Helpers.FormatNumber(number)
    if type(number) ~= "number" then return "0" end
    local formatted = tostring(math.floor(number))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Generate unique session ID
function Helpers.GenerateSessionId()
    return tostring(tick()):gsub("%.", "") .. tostring(math.random(1000, 9999))
end

-- Check if script is running on client
function Helpers.IsClient()
    return RunService:IsClient()
end

-- Wait for child with timeout
function Helpers.WaitForChild(parent, childName, timeout)
    timeout = timeout or 10
    local startTime = tick()
    
    while tick() - startTime < timeout do
        local child = parent:FindFirstChild(childName)
        if child then return child end
        wait(0.1)
    end
    
    return nil
end

-- Deep copy table
function Helpers.DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Helpers.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Merge two tables
function Helpers.MergeTables(table1, table2)
    local result = Helpers.DeepCopy(table1)
    for key, value in pairs(table2) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = Helpers.MergeTables(result[key], value)
        else
            result[key] = value
        end
    end
    return result
end

-- Clamp number between min and max
function Helpers.Clamp(number, min, max)
    return math.max(min, math.min(max, number))
end

-- Linear interpolation
function Helpers.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Get table length
function Helpers.TableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Trim whitespace from string
function Helpers.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Add trim method to string metatable for chaining
if not string.trim then
    function string:trim()
        return Helpers.Trim(self)
    end
end

return Helpers
