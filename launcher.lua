-- launcher.lua  
-- ITU IKAN Launcher - Loads and executes the main script
-- This is the script you copy-paste into Roblox

print("🐟 ITU IKAN Launcher Starting...")

-- Configuration
local GITHUB_REPO = "https://raw.githubusercontent.com/yohansevta/itu_ikan/main/"
local REQUIRED_FILES = {
    "src/main.lua",
    "src/modules/FishingAI.lua",
    "src/utils/helpers.lua",
    "src/config/settings.lua"
}

-- Progress tracking
local loadedFiles = {}
local totalFiles = #REQUIRED_FILES

-- Download and cache files
local function downloadFile(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        return content
    else
        error("Failed to download: " .. url)
    end
end

-- Load all required files
print("📦 Loading files from GitHub...")

for i, filePath in ipairs(REQUIRED_FILES) do
    local url = GITHUB_REPO .. filePath
    local fileName = filePath:match("([^/]+)$") -- Get filename
    
    print(string.format("📥 [%d/%d] Loading %s...", i, totalFiles, fileName))
    
    local success, content = pcall(function()
        return downloadFile(url)
    end)
    
    if success then
        loadedFiles[filePath] = content
        print("✅ " .. fileName .. " loaded successfully")
    else
        warn("❌ Failed to load " .. fileName .. ": " .. tostring(content))
        
        -- Show notification for failed files
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ITU IKAN Error",
            Text = "Failed to load " .. fileName,
            Duration = 5
        })
    end
end

print("📊 Files loaded: " .. #loadedFiles .. "/" .. totalFiles)

-- Check if critical files are loaded
if not loadedFiles["src/main.lua"] then
    error("❌ Critical file missing: main.lua")
end

if not loadedFiles["src/modules/FishingAI.lua"] then
    error("❌ Critical file missing: FishingAI.lua")
end

-- Create virtual module system
_G.ITU_IKAN_MODULES = {}

-- Load FishingAI module
if loadedFiles["src/modules/FishingAI.lua"] then
    local fishingAI_func = loadstring(loadedFiles["src/modules/FishingAI.lua"])
    if fishingAI_func then
        _G.ITU_IKAN_MODULES.FishingAI = fishingAI_func()
        print("🎣 FishingAI module prepared")
    end
end

-- Load helpers
if loadedFiles["src/utils/helpers.lua"] then
    local helpers_func = loadstring(loadedFiles["src/utils/helpers.lua"]) 
    if helpers_func then
        _G.ITU_IKAN_MODULES.Helpers = helpers_func()
        print("🛠️ Helpers module prepared")
    end
end

-- Load settings
if loadedFiles["src/config/settings.lua"] then
    local settings_func = loadstring(loadedFiles["src/config/settings.lua"])
    if settings_func then
        _G.ITU_IKAN_MODULES.Settings = settings_func()
        print("⚙️ Settings module prepared")
    end
end

-- Success notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🐟 ITU IKAN",
    Text = "All files loaded! Starting main script...",
    Duration = 4
})

print("🚀 Launching main script...")

-- Execute main script
local main_func = loadstring(loadedFiles["src/main.lua"])
if main_func then
    -- Set up environment
    _G.ITU_IKAN_LAUNCHED = true
    
    local success, error_msg = pcall(main_func)
    if success then
        print("✅ ITU IKAN started successfully!")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🐟 ITU IKAN",
            Text = "✅ Started successfully!",
            Duration = 5
        })
    else
        warn("❌ Error starting ITU IKAN:", error_msg)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ITU IKAN Error", 
            Text = "Failed to start: " .. tostring(error_msg),
            Duration = 8
        })
    end
else
    error("❌ Failed to load main script")
end
