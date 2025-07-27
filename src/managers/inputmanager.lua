-- Input Manager for responsive controls
-- Handles keyboard, gamepad, and touch input with proper abstraction

local Config = require("src.config")

local InputManager = {}
InputManager.__index = InputManager

function InputManager:new()
    local manager = {
        -- Input states
        keyboard = {},
        gamepad = {},
        touch = {},
        
        -- Input repeat handling
        keyRepeatTimers = {},
        keyRepeatStates = {},
        
        -- Touch state
        touches = {},
        lastTouchTime = 0,
        
        -- Gamepad state
        gamepads = {},
        activeGamepad = nil,
        
        -- Input mapping
        bindings = {
            -- Movement
            up = {"w", "up"},
            down = {"s", "down"},
            left = {"a", "left"},
            right = {"d", "right"},
            
            -- Actions
            bomb = {"space", "return"},
            pause = {"escape", "p"},
            restart = {"r"},
            
            -- Gamepad
            gamepad_move_up = {"dpup", "lefty-", "righty-"},
            gamepad_move_down = {"dpdown", "lefty+", "righty+"},
            gamepad_move_left = {"dpleft", "leftx-", "rightx-"},
            gamepad_move_right = {"dpright", "leftx+", "rightx+"},
            gamepad_bomb = {"a", "b"},
            gamepad_pause = {"start"},
            gamepad_restart = {"back"}
        },
        
        -- Touch controls
        touchControls = {
            dpad = {
                active = false,
                centerX = 0,
                centerY = 0,
                radius = 0,
                deadzone = 0
            },
            action = {
                active = false,
                x = 0,
                y = 0,
                radius = 0
            }
        },
        
        -- Screen dimensions for responsive positioning
        screenWidth = 0,
        screenHeight = 0
    }
    
    setmetatable(manager, self)
    return manager
end

function InputManager:resize(w, h)
    self.screenWidth = w
    self.screenHeight = h
    
    -- Update touch control positions
    self:updateTouchControls()
end

function InputManager:updateTouchControls()
    -- Position touch controls responsively
    local margin = math.min(self.screenWidth, self.screenHeight) * 0.1
    
    -- D-pad on left side
    self.touchControls.dpad.centerX = margin + 75
    self.touchControls.dpad.centerY = self.screenHeight - margin - 75
    self.touchControls.dpad.radius = 75
    self.touchControls.dpad.deadzone = 20
    
    -- Action button on right side
    self.touchControls.action.x = self.screenWidth - margin - 75
    self.touchControls.action.y = self.screenHeight - margin - 75
    self.touchControls.action.radius = 50
end

function InputManager:update(dt)
    -- Update key repeat timers
    for key, timer in pairs(self.keyRepeatTimers) do
        self.keyRepeatTimers[key] = timer + dt
        
        if self.keyRepeatStates[key] then
            local delay = Config.INPUT.KEY_REPEAT_DELAY
            local interval = Config.INPUT.KEY_REPEAT_INTERVAL
            
            if timer >= delay then
                local repeatCount = math.floor((timer - delay) / interval)
                if repeatCount > self.keyRepeatStates[key].repeats then
                    self.keyRepeatStates[key].repeats = repeatCount
                    self.keyRepeatStates[key].justRepeated = true
                end
            end
        end
    end
    
    -- Update gamepad state
    self:updateGamepadState()
end

function InputManager:updateGamepadState()
    self.gamepads = love.joystick.getJoysticks()
    if #self.gamepads > 0 then
        self.activeGamepad = self.gamepads[1]
    else
        self.activeGamepad = nil
    end
end

-- Keyboard input
function InputManager:isKeyDown(action)
    local keys = self.bindings[action]
    if not keys then return false end
    
    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end
    return false
end

function InputManager:isKeyPressed(action)
    -- This would need to be called from love.keypressed
    -- For now, we'll use a simple approach
    return self:isKeyDown(action) and not self.keyRepeatStates[action]
end

-- Gamepad input
function InputManager:isGamepadDown(action)
    if not self.activeGamepad then return false end
    
    local buttons = self.bindings["gamepad_" .. action]
    if not buttons then return false end
    
    for _, button in ipairs(buttons) do
        if string.find(button, "dp") == 1 then
            -- D-pad buttons
            if self.activeGamepad:isGamepadDown(button) then
                return true
            end
        elseif string.find(button, "[xy][+-]") then
            -- Axis input
            local axis = string.sub(button, 1, -2)
            local direction = string.sub(button, -1)
            local value = self.activeGamepad:getGamepadAxis(axis)
            
            if direction == "+" and value > Config.INPUT.GAMEPAD_DEADZONE then
                return true
            elseif direction == "-" and value < -Config.INPUT.GAMEPAD_DEADZONE then
                return true
            end
        else
            -- Regular buttons
            if self.activeGamepad:isGamepadDown(button) then
                return true
            end
        end
    end
    return false
end

-- Touch input
function InputManager:getTouchInput()
    local input = {
        up = false,
        down = false,
        left = false,
        right = false,
        bomb = false
    }
    
    -- Check D-pad touches
    for _, touch in pairs(self.touches) do
        -- D-pad input
        local dx = touch.x - self.touchControls.dpad.centerX
        local dy = touch.y - self.touchControls.dpad.centerY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance <= self.touchControls.dpad.radius then
            if distance > self.touchControls.dpad.deadzone then
                -- Determine direction
                local angle = math.atan2(dy, dx)
                if angle >= -math.pi/4 and angle < math.pi/4 then
                    input.right = true
                elseif angle >= math.pi/4 and angle < 3*math.pi/4 then
                    input.down = true
                elseif angle >= 3*math.pi/4 or angle < -3*math.pi/4 then
                    input.left = true
                else
                    input.up = true
                end
            end
        end
        
        -- Action button
        local actionDx = touch.x - self.touchControls.action.x
        local actionDy = touch.y - self.touchControls.action.y
        local actionDistance = math.sqrt(actionDx * actionDx + actionDy * actionDy)
        
        if actionDistance <= self.touchControls.action.radius then
            input.bomb = true
        end
    end
    
    return input
end

-- Combined input checking
function InputManager:getMovement()
    local moveX = 0
    local moveY = 0
    
    -- Keyboard
    if self:isKeyDown("up") then moveY = moveY - 1 end
    if self:isKeyDown("down") then moveY = moveY + 1 end
    if self:isKeyDown("left") then moveX = moveX - 1 end
    if self:isKeyDown("right") then moveX = moveX + 1 end
    
    -- Gamepad
    if self:isGamepadDown("move_up") then moveY = moveY - 1 end
    if self:isGamepadDown("move_down") then moveY = moveY + 1 end
    if self:isGamepadDown("move_left") then moveX = moveX - 1 end
    if self:isGamepadDown("move_right") then moveX = moveX + 1 end
    
    -- Touch
    local touchInput = self:getTouchInput()
    if touchInput.up then moveY = moveY - 1 end
    if touchInput.down then moveY = moveY + 1 end
    if touchInput.left then moveX = moveX - 1 end
    if touchInput.right then moveX = moveX + 1 end
    
    -- Normalize diagonal movement
    if moveX ~= 0 and moveY ~= 0 then
        local length = math.sqrt(moveX * moveX + moveY * moveY)
        moveX = moveX / length
        moveY = moveY / length
    end
    
    return moveX, moveY
end

function InputManager:isActionPressed(action)
    -- Keyboard
    if self:isKeyDown(action) then
        if not self.keyRepeatStates[action] then
            self.keyRepeatStates[action] = {repeats = 0}
            self.keyRepeatTimers[action] = 0
            return true
        elseif self.keyRepeatStates[action].justRepeated then
            self.keyRepeatStates[action].justRepeated = false
            return true
        end
    else
        self.keyRepeatStates[action] = nil
        self.keyRepeatTimers[action] = nil
    end
    
    -- Gamepad
    if self:isGamepadDown(action) then
        return true
    end
    
    -- Touch
    local touchInput = self:getTouchInput()
    if action == "bomb" and touchInput.bomb then
        return true
    end
    
    return false
end

-- Love2D callbacks
function InputManager:keypressed(key)
    -- Reset key repeat for this key
    self.keyRepeatStates[key] = {repeats = 0}
    self.keyRepeatTimers[key] = 0
end

function InputManager:keyreleased(key)
    self.keyRepeatStates[key] = nil
    self.keyRepeatTimers[key] = nil
end

function InputManager:touchpressed(id, x, y, dx, dy, pressure)
    self.touches[id] = {x = x, y = y, dx = dx, dy = dy, pressure = pressure}
    self.lastTouchTime = love.timer.getTime()
end

function InputManager:touchreleased(id, x, y, dx, dy, pressure)
    self.touches[id] = nil
end

function InputManager:touchmoved(id, x, y, dx, dy, pressure)
    if self.touches[id] then
        self.touches[id].x = x
        self.touches[id].y = y
        self.touches[id].dx = dx
        self.touches[id].dy = dy
        self.touches[id].pressure = pressure
    end
end

function InputManager:drawTouchControls()
    if not (love.system and love.system.hasTouchScreen and love.system.hasTouchScreen()) then return end
    
    love.graphics.setColor(1, 1, 1, 0.3)
    
    -- Draw D-pad
    love.graphics.circle("line", 
        self.touchControls.dpad.centerX, 
        self.touchControls.dpad.centerY, 
        self.touchControls.dpad.radius)
    
    -- Draw D-pad directions
    local centerX = self.touchControls.dpad.centerX
    local centerY = self.touchControls.dpad.centerY
    local radius = self.touchControls.dpad.radius
    
    love.graphics.line(centerX - radius, centerY, centerX + radius, centerY)
    love.graphics.line(centerX, centerY - radius, centerX, centerY + radius)
    
    -- Draw action button
    love.graphics.circle("line", 
        self.touchControls.action.x, 
        self.touchControls.action.y, 
        self.touchControls.action.radius)
    
    love.graphics.print("BOMB", 
        self.touchControls.action.x - 20, 
        self.touchControls.action.y - 7)
end

return InputManager