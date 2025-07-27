-- Configuration file for Bomberman Love2D
-- Contains all game constants and settings

local Config = {}

-- Window settings
Config.WINDOW_WIDTH = 1024
Config.WINDOW_HEIGHT = 768
Config.MIN_WINDOW_WIDTH = 800
Config.MIN_WINDOW_HEIGHT = 600

-- Grid settings (responsive - will be calculated based on screen size)
Config.GRID_COLS = 13
Config.GRID_ROWS = 13
Config.TILE_SIZE = 30 -- Base tile size, will be scaled

-- Game settings
Config.PLAYER_START_LIVES = 3
Config.BOMB_TIMER = 3.0 -- seconds
Config.EXPLOSION_DURATION = 0.5 -- seconds
Config.INVINCIBILITY_DURATION = 2.0 -- seconds
Config.POWERUP_DROP_CHANCE = 0.5 -- 50% (adjustable during gameplay with +/- keys)

-- Player settings
Config.PLAYER_SPEED = 4.0 -- tiles per second (increased for responsiveness)
Config.PLAYER_START_BOMBS = 1
Config.PLAYER_START_RANGE = 1
Config.PLAYER_START_HEALTH = 3
Config.PLAYER_MAX_BOMBS = 8
Config.PLAYER_MAX_RANGE = 12
Config.PLAYER_MAX_HEALTH = 5
Config.PLAYER_MAX_SPEED = 6.0
Config.SPEED_POWERUP_INCREASE = 0.5 -- additional tiles per second

-- Colors (RGB normalized 0-1)
Config.COLORS = {
    BACKGROUND = {0.1, 0.1, 0.1},
    FLOOR = {0.2, 0.6, 0.2},
    WALL = {0.0, 0.0, 1.0},
    BOX = {1.0, 1.0, 0.0},
    PLAYER = {1.0, 0.0, 0.0},
    BOMB = {0.8, 0.2, 0.2},
    EXPLOSION = {1.0, 0.8, 0.0},
    POWERUP_HEART = {1.0, 0.2, 0.2},
    POWERUP_SPEED = {0.2, 0.8, 1.0},
    POWERUP_AMMO = {0.8, 0.4, 0.8},
    POWERUP_RANGE = {0.4, 0.8, 0.4},
    TEXT = {1.0, 1.0, 1.0},
    UI_BG = {0.15, 0.15, 0.15},
    UI_BORDER = {0.3, 0.3, 0.3}
}

-- Input settings
Config.INPUT = {
    KEY_REPEAT_DELAY = 0.15, -- seconds
    KEY_REPEAT_INTERVAL = 0.08, -- seconds
    GAMEPAD_DEADZONE = 0.2,
    TOUCH_DEADZONE = 20 -- pixels
}

-- Debug settings
Config.DEBUG = false

-- Asset paths
Config.ASSETS = {
    -- Placeholder for actual asset paths
    -- Will be populated when assets are added
}

return Config