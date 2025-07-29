-- Character Manager for dynamic character loading and selection
local CharacterManager = {}
CharacterManager.__index = CharacterManager

function CharacterManager:new(assetManager)
    local manager = {
        assetManager = assetManager,
        characters = {},
        selectedCharacter = "character_1", -- Default character
        characterPath = "assets/images/player/"
    }
    setmetatable(manager, self)
    
    -- Discover and load characters
    self:discoverCharacters(manager)
    
    return manager
end

function CharacterManager:discoverCharacters(manager)
    -- Get list of character folders
    local items = love.filesystem.getDirectoryItems(manager.characterPath)
    
    for _, item in ipairs(items) do
        local fullPath = manager.characterPath .. item
        local info = love.filesystem.getInfo(fullPath)
        
        -- Check if it's a directory and starts with "character_"
        if info and info.type == "directory" and item:match("^character_") then
            local characterData = {
                id = item,
                name = item:gsub("_", " "):gsub("^%l", string.upper), -- Convert "character_1" to "Character 1"
                spritePath = fullPath .. "/" .. item .. "_frame32x32.png",
                exists = false
            }
            
            -- Check if the sprite file exists
            local spriteInfo = love.filesystem.getInfo(characterData.spritePath)
            if spriteInfo and spriteInfo.type == "file" then
                characterData.exists = true
                table.insert(manager.characters, characterData)
            end
        end
    end
    
    -- Sort characters by ID for consistent ordering
    table.sort(manager.characters, function(a, b) return a.id < b.id end)
    
    -- Characters discovered
end

function CharacterManager:getCharacters()
    return self.characters
end

function CharacterManager:setSelectedCharacter(characterId)
    -- Validate character exists
    for _, character in ipairs(self.characters) do
        if character.id == characterId then
            self.selectedCharacter = characterId
            -- Character selected
            return true
        end
    end
    return false
end

function CharacterManager:getSelectedCharacter()
    return self.selectedCharacter
end

function CharacterManager:getSelectedCharacterData()
    for _, character in ipairs(self.characters) do
        if character.id == self.selectedCharacter then
            return character
        end
    end
    return nil
end

function CharacterManager:loadSelectedCharacterSprite()
    local character = self:getSelectedCharacterData()
    if character and character.exists then
        -- Load the sprite sheet for the selected character
        self.assetManager:loadImage("player_spritesheet", character.spritePath)
        -- Sprite loaded
        return true
    end
    return false
end

return CharacterManager