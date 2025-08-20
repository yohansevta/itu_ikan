-- logger.lua
-- Logging utility

local Logger = {}
Logger.__index = Logger

-- Log levels
Logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Constructor
function Logger.new(settings)
    local self = setmetatable({}, Logger)
    
    self.settings = settings or {}
    self.logLevel = self.settings.logLevel or "INFO"
    self.showNotifications = self.settings.showNotifications or true
    self.consoleOutput = self.settings.consoleOutput or true
    self.enabled = self.settings.enabled or false
    
    self.logHistory = {}
    self.maxHistorySize = 1000
    
    return self
end

-- Get numeric log level
function Logger:GetNumericLevel(level)
    return self.LEVELS[level:upper()] or self.LEVELS.INFO
end

-- Check if should log based on level
function Logger:ShouldLog(level)
    if not self.enabled then return false end
    
    local numericLevel = self:GetNumericLevel(level)
    local currentLevel = self:GetNumericLevel(self.logLevel)
    
    return numericLevel >= currentLevel
end

-- Log message
function Logger:Log(level, module, message, data)
    if not self:ShouldLog(level) then return end
    
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        timestamp = timestamp,
        level = level:upper(),
        module = module or "UNKNOWN",
        message = message,
        data = data,
        tick = tick()
    }
    
    -- Add to history
    table.insert(self.logHistory, logEntry)
    
    -- Trim history if needed
    if #self.logHistory > self.maxHistorySize then
        table.remove(self.logHistory, 1)
    end
    
    -- Console output
    if self.consoleOutput then
        local prefix = string.format("[%s][%s][%s]", timestamp, level:upper(), module)
        print(prefix, message)
        
        if data and type(data) == "table" then
            for key, value in pairs(data) do
                print("  ", key, "=", tostring(value))
            end
        end
    end
    
    -- Notification for important messages
    if self.showNotifications and (level:upper() == "ERROR" or level:upper() == "WARN") then
        local Helpers = require(script.Parent.helpers)
        if Helpers and Helpers.Notify then
            Helpers.Notify("ITU IKAN " .. level:upper(), message)
        end
    end
end

-- Convenience methods
function Logger:Debug(module, message, data)
    self:Log("DEBUG", module, message, data)
end

function Logger:Info(module, message, data)
    self:Log("INFO", module, message, data)
end

function Logger:Warn(module, message, data)
    self:Log("WARN", module, message, data)
end

function Logger:Error(module, message, data)
    self:Log("ERROR", module, message, data)
end

-- Get log history
function Logger:GetHistory(count, level)
    local history = {}
    local filteredHistory = self.logHistory
    
    -- Filter by level if specified
    if level then
        filteredHistory = {}
        for _, entry in pairs(self.logHistory) do
            if entry.level == level:upper() then
                table.insert(filteredHistory, entry)
            end
        end
    end
    
    -- Get last N entries
    local startIndex = count and math.max(1, #filteredHistory - count + 1) or 1
    for i = startIndex, #filteredHistory do
        table.insert(history, filteredHistory[i])
    end
    
    return history
end

-- Clear history
function Logger:ClearHistory()
    self.logHistory = {}
end

-- Export logs
function Logger:ExportLogs()
    local exportData = {
        exportTime = os.date("%Y-%m-%d %H:%M:%S"),
        totalLogs = #self.logHistory,
        logs = self.logHistory,
        settings = self.settings
    }
    
    return exportData
end

-- Update settings
function Logger:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        if self.settings[key] ~= nil then
            self.settings[key] = value
            self[key] = value
        end
    end
end

-- Get status
function Logger:GetStatus()
    return {
        enabled = self.enabled,
        logLevel = self.logLevel,
        totalLogs = #self.logHistory,
        showNotifications = self.showNotifications,
        consoleOutput = self.consoleOutput
    }
end

return Logger
