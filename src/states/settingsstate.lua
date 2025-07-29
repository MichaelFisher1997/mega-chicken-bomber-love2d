-- Settings state for game configuration including character selection
local Config = require("src.config")

local SettingsState = {}
SettingsState.__index = SettingsState

function SettingsState:new(assetManager, inputManager, characterManager)
    local state = {
        assetManager = assetManager,
        inputManager = inputManager,
        characterManager = characterManager,
        shouldTransition = false,
        nextState = nil,
        selectedOption = 1,
        selectedCharacterIndex = 1,
        font = nil,
        titleFont = nil,
        previewAnimation = {
            timer = 0,
            frame = 0,
            frameDuration = 0.3
        },
        transitionAnimation = {
            isTransitioning = false,
            timer = 0,
            duration = 0.5,
            fromIndex = 1,
            toIndex = 1,
            direction = 0 -- -1 for left, 1 for right
        },
        inputCooldown = {
            timer = 0,
            duration = 0.5
        }
    }
    setmetatable(state, self)
    
    -- Find current character index
    self:findCurrentCharacterIndex(state)
    
    return state
end

function SettingsState:findCurrentCharacterIndex(state)
    local characters = state.characterManager:getCharacters()
    local selectedId = state.characterManager:getSelectedCharacter()
    
    for i, character in ipairs(characters) do
        if character.id == selectedId then
            state.selectedCharacterIndex = i
            break
        end
    end
end

function SettingsState:enter()
    -- Create fonts
    local screenHeight = love.graphics.getHeight()
    self.font = love.graphics.newFont(math.floor(screenHeight * 0.04))
    self.titleFont = love.graphics.newFont(math.floor(screenHeight * 0.08))
    
    -- Initialize input
    local w, h = love.graphics.getDimensions()
    self.inputManager:resize(w, h)
end

function SettingsState:exit()
    -- Ensure transition is complete and save character selection
    if self.transitionAnimation.isTransitioning then
        self.selectedCharacterIndex = self.transitionAnimation.toIndex
        self.transitionAnimation.isTransitioning = false
    end
    
    local characters = self.characterManager:getCharacters()
    if characters[self.selectedCharacterIndex] then
        self.characterManager:setSelectedCharacter(characters[self.selectedCharacterIndex].id)
        self.characterManager:loadSelectedCharacterSprite()
        print("[SETTINGS] Saved character selection:", characters[self.selectedCharacterIndex].name)
    end
end

function SettingsState:update(dt)
    -- Update preview animation
    self.previewAnimation.timer = self.previewAnimation.timer + dt
    if self.previewAnimation.timer >= self.previewAnimation.frameDuration then
        self.previewAnimation.timer = 0
        self.previewAnimation.frame = (self.previewAnimation.frame + 1) % 3 -- 3 frames: 0, 1, 2
    end
    
    -- Update transition animation
    if self.transitionAnimation.isTransitioning then
        self.transitionAnimation.timer = self.transitionAnimation.timer + dt
        if self.transitionAnimation.timer >= self.transitionAnimation.duration then
            -- Transition complete
            self.transitionAnimation.isTransitioning = false
            self.transitionAnimation.timer = 0
            self.selectedCharacterIndex = self.transitionAnimation.toIndex
        end
    end
    
    -- Update input cooldown
    if self.inputCooldown.timer > 0 then
        self.inputCooldown.timer = self.inputCooldown.timer - dt
    end
    
    -- Handle input (only if not in cooldown)
    if self.inputCooldown.timer <= 0 then
        self:handleInput()
    end
end

function SettingsState:handleInput()
    local moveX, moveY = self.inputManager:getMovement()
    local characters = self.characterManager:getCharacters()
    
    -- Character selection (left/right) - only if not transitioning
    if not self.transitionAnimation.isTransitioning and #characters > 0 then
        if moveX > 0 then
            self:startTransition(1) -- Move right
        elseif moveX < 0 then
            self:startTransition(-1) -- Move left
        end
    end
    
    -- Confirm selection or go back
    if self.inputManager:isActionPressed("bomb") then -- Space/Enter
        self.shouldTransition = true
        self.nextState = "menu"
    end
    
    if self.inputManager:isActionPressed("restart") then -- R key
        self.shouldTransition = true
        self.nextState = "menu"
    end
end

function SettingsState:startTransition(direction)
    local characters = self.characterManager:getCharacters()
    if #characters <= 1 then return end
    
    -- Calculate target index
    local targetIndex = self.selectedCharacterIndex + direction
    if targetIndex > #characters then
        targetIndex = 1
    elseif targetIndex < 1 then
        targetIndex = #characters
    end
    
    -- Set up transition
    self.transitionAnimation.isTransitioning = true
    self.transitionAnimation.timer = 0
    self.transitionAnimation.fromIndex = self.selectedCharacterIndex
    self.transitionAnimation.toIndex = targetIndex
    self.transitionAnimation.direction = direction
    
    -- Start input cooldown
    self.inputCooldown.timer = self.inputCooldown.duration
end

function SettingsState:draw()
    love.graphics.clear(Config.COLORS.BACKGROUND)
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    local titleText = "Character Selection"
    local titleWidth = self.titleFont:getWidth(titleText)
    love.graphics.print(titleText, screenWidth / 2 - titleWidth / 2, screenHeight * 0.1)
    
    -- Character selection
    love.graphics.setFont(self.font)
    local characters = self.characterManager:getCharacters()
    
    if #characters > 0 then
        local currentCharacter = characters[self.selectedCharacterIndex]
        
        -- Always draw static text info
        self:drawCharacterText(currentCharacter, screenWidth, screenHeight)
        
        -- Draw sprite with animation if transitioning
        if self.transitionAnimation.isTransitioning then
            self:drawTransitionSprites(characters, screenWidth, screenHeight)
        else
            -- Draw static sprite
            self:drawCharacterPreview(currentCharacter, screenWidth / 2, screenHeight * 0.55, 1.0)
        end
    else
        local noCharText = "No characters found!"
        local noCharWidth = self.font:getWidth(noCharText)
        love.graphics.print(noCharText, screenWidth / 2 - noCharWidth / 2, screenHeight * 0.4)
    end
    
    -- Instructions
    love.graphics.setFont(love.graphics.newFont(16))
    local instructions = {
        "Use LEFT/RIGHT arrows to select character",
        "Press SPACE or ENTER to confirm",
        "Press R to go back to menu"
    }
    
    for i, instruction in ipairs(instructions) do
        local instrWidth = love.graphics.getFont():getWidth(instruction)
        love.graphics.print(instruction, screenWidth / 2 - instrWidth / 2, 
                           screenHeight * 0.75 + (i * 25))
    end
end

function SettingsState:drawCharacterText(character, screenWidth, screenHeight)
    love.graphics.setColor(1, 1, 1)
    
    -- Character name
    local nameText = character.name
    local nameWidth = self.font:getWidth(nameText)
    love.graphics.print(nameText, screenWidth / 2 - nameWidth / 2, screenHeight * 0.3)
    
    -- Navigation arrows and indicator
    local navY = screenHeight * 0.4
    love.graphics.print("< Previous", screenWidth * 0.2, navY)
    love.graphics.print("Next >", screenWidth * 0.7, navY)
    
    -- Character counter - use current selected index during transition
    local characters = self.characterManager:getCharacters()
    local currentIndex = self.transitionAnimation.isTransitioning and self.transitionAnimation.toIndex or self.selectedCharacterIndex
    local counterText = currentIndex .. " / " .. #characters
    local counterWidth = self.font:getWidth(counterText)
    love.graphics.print(counterText, screenWidth / 2 - counterWidth / 2, navY)
end

function SettingsState:drawTransitionSprites(characters, screenWidth, screenHeight)
    local progress = self.transitionAnimation.timer / self.transitionAnimation.duration
    -- Use easing function for smooth animation
    local easedProgress = self:easeInOutCubic(progress)
    
    local fromCharacter = characters[self.transitionAnimation.fromIndex]
    local toCharacter = characters[self.transitionAnimation.toIndex]
    
    -- Calculate slide distance for sprites only
    local slideDistance = screenWidth * 0.4 -- Smaller distance for just the sprite
    local direction = self.transitionAnimation.direction
    local spriteY = screenHeight * 0.55
    
    -- Draw outgoing sprite (sliding out)
    local outgoingX = screenWidth / 2 - direction * slideDistance * easedProgress
    local outgoingAlpha = 1.0 - easedProgress
    self:drawCharacterPreview(fromCharacter, outgoingX, spriteY, outgoingAlpha)
    
    -- Draw incoming sprite (sliding in)
    local incomingX = screenWidth / 2 + direction * slideDistance * (1.0 - easedProgress)
    local incomingAlpha = easedProgress
    self:drawCharacterPreview(toCharacter, incomingX, spriteY, incomingAlpha)
end

function SettingsState:easeInOutCubic(t)
    return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
end

function SettingsState:drawCharacterPreview(character, x, y, alpha)
    alpha = alpha or 1.0
    if not character.exists then return end
    
    -- Try to load and draw a preview of the character
    local tempSprite = love.graphics.newImage(character.spritePath)
    if tempSprite then
        local frameWidth = 32
        local frameHeight = 32
        local scale = 4 -- Make preview larger
        
        -- Create quad for current animation frame (down direction, walking animation)
        local frameX = self.previewAnimation.frame * frameWidth
        local frameY = 0 -- Down direction is row 0
        
        local quad = love.graphics.newQuad(frameX, frameY, frameWidth, frameHeight, 
                                         tempSprite:getDimensions())
        
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(tempSprite, quad, 
                          x - (frameWidth * scale) / 2, 
                          y - (frameHeight * scale) / 2, 
                          0, scale, scale)
    end
end

function SettingsState:keypressed(key)
    -- Handle character navigation directly for better responsiveness
    if not self.transitionAnimation.isTransitioning and self.inputCooldown.timer <= 0 then
        if key == "right" or key == "d" then
            self:startTransition(1) -- Move right
        elseif key == "left" or key == "a" then
            self:startTransition(-1) -- Move left
        elseif key == "space" or key == "return" then
            self.shouldTransition = true
            self.nextState = "menu"
        elseif key == "r" then
            self.shouldTransition = true
            self.nextState = "menu"
        end
    end
    
    self.inputManager:keypressed(key)
end

function SettingsState:keyreleased(key)
    self.inputManager:keyreleased(key)
end

function SettingsState:resize(w, h)
    self.inputManager:resize(w, h)
end

return SettingsState