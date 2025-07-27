-- Sound system for managing audio effects and music

local System = require("src.ecs.system")
local Config = require("src.config")

local SoundSystem = setmetatable({}, {__index = System})
SoundSystem.__index = SoundSystem

function SoundSystem:new()
    local system = System:new()
    setmetatable(system, self)
    
    system.sounds = {}
    system.music = nil
    system.volume = 0.7
    system.musicVolume = 0.5
    
    return system
end

function SoundSystem:load()
    -- Create placeholder sounds using Love2D's audio synthesis
    self.sounds = {
        bomb_place = self:createSound("bomb_place", 200, 0.1, "sine"),
        explosion = self:createSound("explosion", 150, 0.3, "sawtooth"),
        powerup = self:createSound("powerup", 440, 0.2, "sine"),
        box_break = self:createSound("box_break", 300, 0.15, "square"),
        player_move = self:createSound("player_move", 100, 0.05, "sine"),
        game_over = self:createSound("game_over", 100, 0.5, "sawtooth")
    }
    
    -- Create background music (simple looping melody)
    self:createBackgroundMusic()
end

function SoundSystem:createSound(name, frequency, duration, waveType)
    -- Create a simple synthesized sound
    local sampleRate = 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = 0
        
        if waveType == "sine" then
            value = math.sin(2 * math.pi * frequency * t)
        elseif waveType == "square" then
            value = math.sin(2 * math.pi * frequency * t) > 0 and 1 or -1
        elseif waveType == "sawtooth" then
            value = 2 * ((frequency * t) % 1) - 1
        end
        
        -- Apply envelope
        local envelope = 1 - (t / duration)
        value = value * envelope
        
        soundData:setSample(i, value * 0.5)
    end
    
    local source = love.audio.newSource(soundData, "static")
    source:setVolume(self.volume)
    return source
end

function SoundSystem:createBackgroundMusic()
    -- Create a simple background melody
    local sampleRate = 44100
    local duration = 4.0  -- 4 second loop
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    local notes = {261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25} -- C major scale
    local pattern = {1, 3, 5, 3, 1, 5, 8, 5} -- Simple melody pattern
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local beat = (t * 2) % 1  -- 120 BPM
        local noteIndex = math.floor(t * 2) % #pattern + 1
        local frequency = notes[pattern[noteIndex]]
        
        local value = math.sin(2 * math.pi * frequency * t) * 0.1
        value = value * (1 - math.abs(beat - 0.5) * 2) * 0.3  -- Volume envelope
        
        soundData:setSample(i, value)
    end
    
    self.music = love.audio.newSource(soundData, "static")
    self.music:setLooping(true)
    self.music:setVolume(self.musicVolume)
end

function SoundSystem:playSound(name)
    if self.sounds[name] then
        local sound = self.sounds[name]:clone()
        sound:play()
    end
end

function SoundSystem:playMusic()
    if self.music then
        self.music:play()
    end
end

function SoundSystem:stopMusic()
    if self.music then
        self.music:stop()
    end
end

function SoundSystem:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))
    for _, sound in pairs(self.sounds) do
        sound:setVolume(self.volume)
    end
end

function SoundSystem:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    if self.music then
        self.music:setVolume(self.musicVolume)
    end
end

return SoundSystem