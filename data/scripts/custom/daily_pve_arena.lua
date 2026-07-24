--[[
    Daily PvE Arena System - "Abismo Ecoante" (The Echoing Abyss)
    Dynamic Version: Automatically loads all bestiary monsters from the server!
    Features:
    - Daily 20-hour cooldown.
    - Automatic starting level: (MAX_LEVEL - 10), minimum Level 1.
    - Timer-based Waves inside Levels: Each Level has a random number of waves (3 to 5).
    - Waves trigger every 30 seconds, spawning 3 to 7 creatures of the SAME type (Bestiary focus).
    - Dynamic Level Generation: Every 20 HP of a monster equals 1 Level (e.g. 20 HP = Lvl 1, 65 HP = Lvl 4).
    - 100% Bestiary Accurate: Filters monsters using native getBestiarytoKill() engine check.
    - No resource consumption (Runes & Potions handled in source/potions.lua).
    - Zero death loss (Intercepted via onPrepareDeath).
    - XP Bonus scaling based on current Level (+1% XP per Level).
    - Arena Coins and Respect Points rewards based on completed Levels.
--]]

local config = {
    -- Storages
    STORAGE_IN_ARENA = 50001,       -- 1 inside, -1 outside
    STORAGE_MAX_LEVEL = 50002,      -- Max level reached
    STORAGE_DAILY_COOLDOWN = 50003, -- 20-hour cooldown timestamp
    STORAGE_CURRENT_LEVEL = 50004,  -- Active level tracking
    STORAGE_RESPECT_POINTS = 50005, -- Total Respect Points stored
    STORAGE_CURRENT_WAVE = 50006,   -- Current sub-wave in active level
    STORAGE_TOTAL_WAVES = 50007,    -- Total sub-waves randomized for this level
    STORAGE_START_LEVEL = 50008,    -- The level the player entered at

    -- Settings
    cooldownTime = 20 * 3600,       -- 20 hours in seconds
    waveInterval = 30,              -- 30 seconds per wave
    arenaCoinId = 3043,             -- Custom Item ID for Arena Coins (Default: 3043 Crystal Coin)
    coinsPerLevel = 10,             -- Coins given per COMPLETED Level
    respectPointsPerLevel = 50,     -- Respect points given per COMPLETED Level

    -- Action ID for Entry Portal / Lever
    portalActionId = 45000,

    -- Positions (Modify coordinates here!)
    arenaCenter = Position(32396, 32194, 7),  -- Center of the arena floor
    exitPosition = Position(32369, 32241, 7), -- Temple exit position
    fromPos = Position(32390, 32189, 7),        -- Arena top-left boundary
    toPos = Position(32401, 32200, 7)         -- Arena bottom-right boundary
}

-- Tabela global que armazenará as listas de monstros geradas dinamicamente
local monsterPools = {}
local activeArenaEvents = {}
local isInitialized = false -- Controla se a carga dinâmica já foi feita

-- Função de Inicialização Dinâmica dos Monstros (Lazy Loading)
local function initializeMonsterPools()
    if isInitialized then
        return
    end

    local loadedCount = 0
    local monsterTypes = Game.getMonsterTypes()

    if monsterTypes then
        for name, mType in pairs(monsterTypes) do
            local nameStr = mType:getName() or name
            
            -- CHECAGEM NATIVA EXATA: getBestiarytoKill (com 't' minúsculo)
            local isBestiary = false
            if mType.getBestiarytoKill and mType:getBestiarytoKill() > 0 then
                isBestiary = true
            end

            if isBestiary then
                -- Lê os atributos e garante compatibilidade com variações de engines
                local health = mType.getHealth and mType:getHealth() or (mType.getHealthMax and mType:getHealthMax()) or 0
                local exp = mType.getExperience and mType:getExperience() or 0

                -- Filtra apenas criaturas que dão combate (ignora ovelhas/porcos que dão 0 XP)
                if exp >= 1 and health >= 1 and nameStr ~= "" then
                    -- FÓRMULA: Cada 20 HP equivale a 1 Level
                    local calculatedLevel = math.ceil(health / 20)
                    if calculatedLevel > 0 then
                        if not monsterPools[calculatedLevel] then
                            monsterPools[calculatedLevel] = {}
                        end
                        table.insert(monsterPools[calculatedLevel], nameStr)
                        loadedCount = loadedCount + 1
                    end
                end
            end
        end
    end

    -- Trava de segurança: Caso a carga falhe por alguma limitação da API da engine, carrega fallbacks clássicos
    if loadedCount == 0 then
        print("[Abismo Ecoante] Warning: Dynamic loading yielded 0 monsters. Loading classic fallbacks.")
        monsterPools[1] = {"Rat", "Cave Rat", "Spider", "Poison Spider"}
        monsterPools[4] = {"Dwarf", "Skeleton", "Ghoul", "Rotworm"}
        monsterPools[10] = {"Cyclops", "Minotaur", "Orc Berserker", "Dwarf Soldier"}
        monsterPools[50] = {"Dragon", "Giant Spider", "Hero", "Necromancer"}
        monsterPools[100] = {"Dragon Lord", "Behemoth", "Hydra", "Wyrm"}
        monsterPools[400] = {"Demon", "Grim Reaper", "Destroyer"}
        monsterPools[900] = {"Hellflayer", "Vexclaw", "Grimeleech"}
        loadedCount = 25
    else
        print(string.format("[Abismo Ecoante] Loaded %d official bestiary monsters dynamically.", loadedCount))
    end

    isInitialized = true
end

-- Busca Inteligente de Monstros por Level
local function getMonsterPool(level)
    -- 1. Verifica se o nível exato possui monstros cadastrados
    if monsterPools[level] and #monsterPools[level] > 0 then
        return monsterPools[level]
    end

    -- 2. Se estiver vazio, faz uma busca regressiva para achar monstros um pouco mais fracos
    for l = level - 1, 1, -1 do
        if monsterPools[l] and #monsterPools[l] > 0 then
            return monsterPools[l]
        end
    end

    -- 3. Se ainda assim estiver vazio, busca o menor nível de monstros cadastrados no servidor
    local lowestLevel = math.huge
    for l, pool in pairs(monsterPools) do
        if #pool > 0 and l < lowestLevel then
            lowestLevel = l
        end
    end

    if lowestLevel ~= math.huge then
        return monsterPools[lowestLevel]
    end

    -- 4. Fallback absoluto de emergência
    return {"Rat"}
end

-- Helper: Clean monsters in arena area
local function clearArenaArea()
    for x = config.fromPos.x, config.toPos.x do
        for y = config.fromPos.y, config.toPos.y do
            local tile = Tile(Position(x, y, config.fromPos.z))
            if tile then
                local creatures = tile:getCreatures()
                if creatures then
                    for _, creature in ipairs(creatures) do
                        if creature:isMonster() then
                            local master = creature:getMaster()
                            if not master then
                                creature:remove()
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Wave Scheduler Loop
local function executeArenaWave(playerId)
    local player = Player(playerId)
    if not player or player:getStorageValue(config.STORAGE_IN_ARENA) ~= 1 then
        activeArenaEvents[playerId] = nil
        return
    end

    local currentLevel = math.max(1, player:getStorageValue(config.STORAGE_CURRENT_LEVEL))
    local currentWave = player:getStorageValue(config.STORAGE_CURRENT_WAVE)
    local totalWaves = player:getStorageValue(config.STORAGE_TOTAL_WAVES)

    -- Se a wave atual ultrapassou o total planejado para este nível, avançamos de Level!
    if currentWave > totalWaves then
        currentLevel = currentLevel + 1
        player:setStorageValue(config.STORAGE_CURRENT_LEVEL, currentLevel)
        
        currentWave = 1
        player:setStorageValue(config.STORAGE_CURRENT_WAVE, currentWave)
        
        totalWaves = math.random(3, 5) -- Sorteia de 3 a 5 waves para o novo nível
        player:setStorageValue(config.STORAGE_TOTAL_WAVES, totalWaves)

        -- Atualiza o recorde do jogador caso aplicável
        local maxLevel = math.max(0, player:getStorageValue(config.STORAGE_MAX_LEVEL))
        if currentLevel > maxLevel then
            player:setStorageValue(config.STORAGE_MAX_LEVEL, currentLevel)
        end
    end

    -- Avisa o jogador com formatação RPG
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[Abismo Ecoante] --- LEVEL %d | WAVE %d/%d ---", currentLevel, currentWave, totalWaves))
    config.arenaCenter:sendMagicEffect(CONST_ME_TELEPORT)

    -- Sorteia uma criatura do pool dinâmico correspondente ao nível
    local pool = getMonsterPool(currentLevel)
    local monsterName = pool[math.random(#pool)]
    
    -- Sorteia uma quantidade de 3 a 7 criaturas (Foco em Bestiário)
    local monsterCount = math.random(3, 7)

    for i = 1, monsterCount do
        local spawnPos = Position(
            config.arenaCenter.x + math.random(-5, 5),
            config.arenaCenter.y + math.random(-5, 5),
            config.arenaCenter.z
        )

        -- Invoca as criaturas idênticas
        local monster = Game.createMonster(monsterName, spawnPos, true, true)
        if monster then
            spawnPos:sendMagicEffect(CONST_ME_TELEPORT)
        end
    end

    -- Prepara o próximo passo lógico: incrementa a wave para o próximo ciclo de 30 segundos
    player:setStorageValue(config.STORAGE_CURRENT_WAVE, currentWave + 1)

    -- Agenda o próximo loop de wave em 30 segundos
    activeArenaEvents[playerId] = addEvent(executeArenaWave, config.waveInterval * 1000, playerId)
end

-- Function to handle arena end (death, exit, logout)
local function endArenaSession(player, isDeath)
    local playerId = player:getId()

    if activeArenaEvents[playerId] then
        stopEvent(activeArenaEvents[playerId])
        activeArenaEvents[playerId] = nil
    end

    local currentLevel = math.max(1, player:getStorageValue(config.STORAGE_CURRENT_LEVEL))
    local startLevel = math.max(1, player:getStorageValue(config.STORAGE_START_LEVEL))
    
    -- Se o jogador entrou no Level 1 e morreu no Level 1, completou 0 níveis.
    -- Se ele entrou no Level 1, passou as waves e morreu no Level 2, completou exatamente 1 nível.
    local completedLevels = math.max(0, currentLevel - startLevel)

    -- Calculate Rewards
    local coins = completedLevels * config.coinsPerLevel
    local respect = completedLevels * config.respectPointsPerLevel

    if coins > 0 then
        player:addItem(config.arenaCoinId, coins)
    end

    if respect > 0 then
        local currentRespect = math.max(0, player:getStorageValue(config.STORAGE_RESPECT_POINTS))
        player:setStorageValue(config.STORAGE_RESPECT_POINTS, currentRespect + respect)
    end

    -- Reset arena state
    player:setStorageValue(config.STORAGE_IN_ARENA, -1)
    player:setStorageValue(config.STORAGE_CURRENT_LEVEL, 0)
    player:setStorageValue(config.STORAGE_CURRENT_WAVE, 0)
    player:setStorageValue(config.STORAGE_TOTAL_WAVES, 0)
    player:setStorageValue(config.STORAGE_START_LEVEL, 0)

    -- Clear arena monsters
    clearArenaArea()

    -- Heal and teleport player
    player:addHealth(player:getMaxHealth())
    player:addMana(player:getMaxMana())
    player:removeCondition(CONDITION_POISON)
    player:removeCondition(CONDITION_FIRE)
    player:removeCondition(CONDITION_ENERGY)
    player:removeCondition(CONDITION_BLEEDING)
    player:teleportTo(config.exitPosition)
    config.exitPosition:sendMagicEffect(CONST_ME_TELEPORT)

    -- Status message
    local statusStr = isDeath and "You were defeated" or "Abismo Ecoante session ended"
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[Abismo Ecoante] %s! Completed Levels: %d | Earned: %d Arena Coins & %d Respect Points.", statusStr, completedLevels, coins, respect))
end

--------------------------------------------------------
-- 1. Portal / Lever Entry Action Script
--------------------------------------------------------
local arenaEntryAction = Action()

function arenaEntryAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- LAZY LOADING: Inicializa a lista de monstros quando o primeiro player clica no portal/alavanca
    initializeMonsterPools()

    local cooldown = player:getStorageValue(config.STORAGE_DAILY_COOLDOWN)
    local currentTime = os.time()

    if cooldown > currentTime then
        local remaining = cooldown - currentTime
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        player:sendCancelMessage(string.format("You must wait %dh %dm before entering the Abismo Ecoante again.", hours, minutes))
        return true
    end

    -- Set 20-hour cooldown
    player:setStorageValue(config.STORAGE_DAILY_COOLDOWN, currentTime + config.cooldownTime)

    -- Calculate starting level: (MAX_LEVEL - 10), minimum Level 1
    local maxLevel = math.max(0, player:getStorageValue(config.STORAGE_MAX_LEVEL))
    local startLevel = math.max(1, maxLevel - 10)

    player:setStorageValue(config.STORAGE_IN_ARENA, 1)
    player:setStorageValue(config.STORAGE_START_LEVEL, startLevel)
    player:setStorageValue(config.STORAGE_CURRENT_LEVEL, startLevel)
    player:setStorageValue(config.STORAGE_CURRENT_WAVE, 1)
    player:setStorageValue(config.STORAGE_TOTAL_WAVES, math.random(3, 5)) -- Sorteia de 3 a 5 waves para o primeiro nível

    -- Teleport player to arena center
    clearArenaArea()
    player:teleportTo(config.arenaCenter)
    config.arenaCenter:sendMagicEffect(CONST_ME_TELEPORT)

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[Abismo Ecoante] Welcome! Starting at Level %d. Prepare for combat!", startLevel))

    -- Start wave scheduler
    executeArenaWave(player:getId())
    return true
end

arenaEntryAction:aid(config.portalActionId)
arenaEntryAction:register()

--------------------------------------------------------
-- 2. Zero Death Loss Interceptor (onPrepareDeath)
--------------------------------------------------------
local arenaPrepareDeath = CreatureEvent("DailyArenaPrepareDeath")

function arenaPrepareDeath.onPrepareDeath(creature, killer)
    if not creature or not creature:isPlayer() then
        return true
    end

    local player = Player(creature:getId())
    if player and player:getStorageValue(config.STORAGE_IN_ARENA) == 1 then
        endArenaSession(player, true)
        return false -- Prevent death & death penalty!
    end

    return true
end

arenaPrepareDeath:register()

--------------------------------------------------------
-- 3. Logout / Login Event Listener
--------------------------------------------------------
local arenaPlayerLogin = CreatureEvent("DailyArenaPlayerLogin")

function arenaPlayerLogin.onLogin(player)
    player:registerEvent("DailyArenaPrepareDeath")

    -- Clean up player if logged out inside arena
    if player:getStorageValue(config.STORAGE_IN_ARENA) == 1 then
        player:setStorageValue(config.STORAGE_IN_ARENA, -1)
        player:teleportTo(config.exitPosition)
    end

    return true
end

arenaPlayerLogin:register()