-- Asset Manager for loading and managing game assets
-- Handles images, sounds, fonts, and other resources

local AssetManager = {}
AssetManager.__index = AssetManager

function AssetManager:new()
    local manager = {
        images = {},
        sounds = {},
        fonts = {},
        loaded = false
    }
    setmetatable(manager, self)
    return manager
end

function AssetManager:load()
    self:loadFonts()
    self:loadColors()
    self:loadImages()
    self:loadSounds()
    
    self.loaded = true
end

function AssetManager:loadFonts()
    -- Create basic fonts for different sizes
    self.fonts = {
        small = love.graphics.newFont(12),
        medium = love.graphics.newFont(16),
        large = love.graphics.newFont(24),
        title = love.graphics.newFont(32),
        huge = love.graphics.newFont(48)
    }
end

function AssetManager:loadColors()
    -- Color palette for different game elements
    self.colors = {
        player = {0.2, 0.6, 1.0},
        bomb = {0.8, 0.2, 0.2},
        explosion = {1.0, 0.8, 0.0},
        wall = {0.4, 0.4, 0.4},
        box = {0.6, 0.4, 0.2},
        floor = {0.2, 0.6, 0.2},
        powerup_bomb = {0.8, 0.4, 0.8},
        powerup_range = {0.4, 0.8, 0.4},
        powerup_speed = {0.8, 0.8, 0.4}
    }
end

function AssetManager:loadImages()
    -- Load tile images
    self:loadImage("wall", "assets/images/Tiles/OuterWall.png")
    self:loadImage("box", "assets/images/Tiles/Box.png")
    self:loadImage("floor", "assets/images/Tiles/Leafs.png")
    self:loadImage("indestructible", "assets/images/Tiles/Tree.png")
    
    -- Load SVG sprites
    self:loadImage("player", "assets/images/Chicken.png")
    self:loadImage("bomb", "assets/images/Bomb.png")
    self:loadImage("explosion", "assets/images/Explosion.png")
    self:loadImage("powerup_bomb", "assets/images/Ammo.png")
    self:loadImage("powerup_range", "assets/images/Range.png")
    self:loadImage("powerup_speed", "assets/images/Speed.png")
    self:loadImage("heart", "assets/images/Heart.png")
    self:loadImage("start_button", "assets/images/Start.png")
end

function AssetManager:loadSounds()
    -- Placeholder for sound effects
    -- TODO: Add actual sound files
end

function AssetManager:getFont(size)
    if type(size) == "string" then
        return self.fonts[size] or self.fonts.medium
    elseif size <= 12 then
        return self.fonts.small
    elseif size <= 20 then
        return self.fonts.medium
    elseif size <= 30 then
        return self.fonts.large
    elseif size <= 40 then
        return self.fonts.title
    else
        return self.fonts.huge
    end
end

function AssetManager:getColor(name)
    return self.colors[name] or {1, 1, 1}
end

function AssetManager:getImage(name)
    return self.images[name]
end

function AssetManager:getSound(name)
    return self.sounds[name]
end

function AssetManager:loadImage(name, path)
    if not self.images[name] then
        local success, image = pcall(love.graphics.newImage, path)
        if success then
            self.images[name] = image
        else
            print("Warning: Could not load image: " .. path)
            self.images[name] = nil
        end
    end
    return self.images[name]
end

function AssetManager:loadSound(name, path, soundType)
    soundType = soundType or "static"
    if not self.sounds[name] then
        self.sounds[name] = love.audio.newSource(path, soundType)
    end
    return self.sounds[name]
end

function AssetManager:unload()
    -- Clean up resources
    for _, image in pairs(self.images) do
        image:release()
    end
    
    for _, sound in pairs(self.sounds) do
        sound:release()
    end
    
    self.images = {}
    self.sounds = {}
    self.fonts = {}
    self.loaded = false
end

return AssetManager