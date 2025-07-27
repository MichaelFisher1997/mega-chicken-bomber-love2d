-- Save Manager for handling game persistence

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager:new()
    local manager = {
        saveFile = "bomberman_save.dat",
        settingsFile = "bomberman_settings.dat"
    }
    setmetatable(manager, self)
    return manager
end

function SaveManager:saveGame(gameState)
    local saveData = {
        highScore = gameState.highScore or 0,
        gamesPlayed = gameState.gamesPlayed or 0,
        totalScore = gameState.totalScore or 0,
        lastPlayed = os.time()
    }
    
    local success, message = love.filesystem.write(self.saveFile, 
        love.data.compress("string", "zlib", 
            love.data.encode("string", "base64", 
                love.data.encode("string", "json", saveData))))
    
    return success
end

function SaveManager:loadGame()
    if not love.filesystem.getInfo(self.saveFile) then
        return {
            highScore = 0,
            gamesPlayed = 0,
            totalScore = 0,
            lastPlayed = 0
        }
    end
    
    local data, size = love.filesystem.read(self.saveFile)
    if not data then
        return {
            highScore = 0,
            gamesPlayed = 0,
            totalScore = 0,
            lastPlayed = 0
        }
    end
    
    local decoded = love.data.decode("string", "base64", data)
    local decompressed = love.data.decompress("string", "zlib", decoded)
    local saveData = love.data.decode("string", "json", decompressed)
    
    return saveData
end

function SaveManager:saveSettings(settings)
    local settingsData = {
        volume = settings.volume or 0.7,
        musicVolume = settings.musicVolume or 0.5,
        fullscreen = settings.fullscreen or false,
        showFPS = settings.showFPS or false,
        touchControls = settings.touchControls or true
    }
    
    local success = love.filesystem.write(self.settingsFile, 
        love.data.compress("string", "zlib", 
            love.data.encode("string", "base64", 
                love.data.encode("string", "json", settingsData))))
    
    return success
end

function SaveManager:loadSettings()
    if not love.filesystem.getInfo(self.settingsFile) then
        return {
            volume = 0.7,
            musicVolume = 0.5,
            fullscreen = false,
            showFPS = false,
            touchControls = true
        }
    end
    
    local data = love.filesystem.read(self.settingsFile)
    if not data then
        return {
            volume = 0.7,
            musicVolume = 0.5,
            fullscreen = false,
            showFPS = false,
            touchControls = true
        }
    end
    
    local decoded = love.data.decode("string", "base64", data)
    local decompressed = love.data.decompress("string", "zlib", decoded)
    local settingsData = love.data.decode("string", "json", decompressed)
    
    return settingsData
end

function SaveManager:resetSave()
    love.filesystem.remove(self.saveFile)
    love.filesystem.remove(self.settingsFile)
end

return SaveManager