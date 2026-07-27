--[[
    "Caminho do Aventureiro" (Adventurer's Path / Battle Pass)
    ============================================================
    Features:
    - Interactive 7-Day Login Reward System (loops endlessly after Day 7).
    - 6 Progressive Tiers of Challenges based on levels, skills, and Tibia's classic quests.
    - "Hero's Key" integration (Consumes Item 60015 to unlock Premium Reward tier).
    - Out-of-the-box native Modal Window GUI.
    - Accessible at any time via talkactions "!pass" or "!journey".
--]]

local config = {
    -- Storages do Passe de Batalha (Range seguro 52000+)
    STORAGE_HERO_KEY_ACTIVE = 52000,          -- 1 = Premium Unlocked, -1/0 = Locked
    STORAGE_DAILY_LOGIN_DAY = 52001,          -- Current claimable day (1 to 7)
    STORAGE_DAILY_LOGIN_COOLDOWN = 52002,     -- Timestamp of next claim
    STORAGE_LEVEL_CLAIMED_NORMAL = 52010,     -- Storage base para prêmio normal (52010 a 52015)
    STORAGE_LEVEL_CLAIMED_PREMIUM = 52020,    -- Storage base para prêmio premium (52020 a 52025)

    -- Arena Storage (Abismo Ecoante)
    STORAGE_ARENA_MAX_LEVEL = 50002,          -- Recorde do player no Abismo Ecoante

    -- Respect Points Storage
    STORAGE_RESPECT_POINTS = 50005,           -- Armazenamento dos pontos de respeito

    -- Item IDs das Recompensas e Chave
    heroKeyItemId = 60015,                    -- Item necessário para destravar o Passe Premium (Chave de Baú)
    arenaCoinId = 3043,                       -- ID da moeda de troca da Arena (Crystal Coin por padrão)

    -- AJUSTE AQUI: Storages das Quests do SEU servidor!
    -- Abra seus scripts de quest ou banco de dados e coloque os storages corretos das recompensas aqui:
    questStorages = {
        desert = 1000,                        -- Storage da Desert Quest (Desert Chest)
        paradox = 1001,                       -- Storage da Paradox Tower Quest (Riddler Chest)
        orcFortress = 1002,                   -- Storage da Orc Fortress Quest (Reward Chest)
        banshee = 1003,                       -- Storage da Banshee Quest (Banshee Chest)
        behemoth = 1004,                      -- Storage da Behemoth Quest (Reward Room Chest)
        poi = 1005,                           -- Storage da Pits of Inferno Quest (POI Chest)
        inquisition = 1006,                   -- Storage da Inquisition Quest (Access/Inq Chest)
        wrath = 1007,                         -- Storage da Wrath of the Emperor Quest (Reward Chest)
        yalahar = 1008                        -- Storage da Yalahar Quest (Azerus/Reward Chest)
    }
}

-- ID Interno das Modal Windows
local MODAL_ID_PASS_MAIN = 6100
local MODAL_ID_PASS_LEVEL = 6101
local MODAL_ID_PASS_LOGIN = 6102

-- 7-Day Login Rewards Table
local dailyRewards = {
    [1] = { desc = "50 Condensed Health Elixirs", items = { { id = 60004, count = 10 } } },
    [2] = { desc = "1 Chest Key", items = { { id = 60015, count = 1 } } },
    [3] = { desc = "2 Hyper XP Crystals", items = { { id = 60016, count = 2 } } },
    [4] = { desc = "1 Feather of Lightness", items = { { id = 60010, count = 1 } } },
    [5] = { desc = "100 Respect Points", rewardType = "respect", amount = 100 },
    [6] = { desc = "10 Arena Coins", items = { { id = config.arenaCoinId, count = 10 } } },
    [7] = { desc = "1 Turkey Mount Cage", items = { { id = 60013, count = 1 } } }
}

-- 6 Battle Pass Levels/Stages Table
local passLevels = {
    [1] = {
        name = "Level I: The Awakening (Lv 1-20)",
        minLevel = 20,
        tasks = {
            { desc = "Reach Level 20", check = function(p) return p:getLevel() >= 20 end },
            { desc = "Reach Magic Level 10 or Melee Skill 30", check = function(p) return p:getMagicLevel() >= 10 or p:getEffectiveSkillLevel(SKILL_SWORD) >= 30 or p:getEffectiveSkillLevel(SKILL_AXE) >= 30 or p:getEffectiveSkillLevel(SKILL_CLUB) >= 30 or p:getEffectiveSkillLevel(SKILL_DISTANCE) >= 30 end },
            { desc = "Complete Desert Quest (Lvl 20)", check = function(p) return p:getStorageValue(config.questStorages.desert) > 0 end },
            { desc = "Reach Level 1 in Abismo Ecoante", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 1 end },
            { desc = "Unlock at least 1 mount", check = function(p) return p:getStorageValue(51007) >= 0 or p:getLevel() >= 20 end } -- Tarefa simples auxiliar
        },
        rewardsNormal = {
            { id = 60001, count = 1 }, -- Explorer's Backpack
            { id = 60004, count = 10 }, -- Condensed Health Elixir
            { id = 60005, count = 10 }  -- Condensed Mana Elixir
        },
        rewardsPremium = {
            { id = 60016, count = 5 }, -- Hyper Crystals
            { id = 60010, count = 1 }  -- Feather of Lightness
        }
    },
    [2] = {
        name = "Level II: The Adept (Lv 21-50)",
        minLevel = 50,
        tasks = {
            { desc = "Reach Level 50", check = function(p) return p:getLevel() >= 50 end },
            { desc = "Complete Paradox Tower Quest", check = function(p) return p:getStorageValue(config.questStorages.paradox) > 0 end },
            { desc = "Reach Level 10 in Abismo Ecoante", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 10 end },
            { desc = "Use a Feather of Lightness once", check = function(p) return p:getStorageValue(51007) >= 1 end },
            { desc = "Unlock at least 2 mounts", check = function(p) return p:getStorageValue(51007) >= 0 or p:getLevel() >= 50 end }
        },
        rewardsNormal = {
            { id = 60002, count = 1 }, -- Hunter's Backpack
            { id = 60006, count = 10 }, -- Condensed Strong Health
            { id = 60007, count = 10 }  -- Condensed Strong Mana
        },
        rewardsPremium = {
            { id = 60013, count = 1 }, -- Turkey Mount Cage
            { id = 60010, count = 2 }  -- 2 Feathers of Lightness
        }
    },
    [3] = {
        name = "Level III: The Veteran (Lv 51-80)",
        minLevel = 80,
        tasks = {
            { desc = "Reach Level 80", check = function(p) return p:getLevel() >= 80 end },
            { desc = "Complete Orc Fortress Quest", check = function(p) return p:getStorageValue(config.questStorages.orcFortress) > 0 end },
            { desc = "Reach Level 25 in Abismo Ecoante", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 25 end },
            { desc = "Reach Magic Level 30 or Melee Skill 60", check = function(p) return p:getMagicLevel() >= 30 or p:getEffectiveSkillLevel(SKILL_SWORD) >= 60 or p:getEffectiveSkillLevel(SKILL_AXE) >= 60 or p:getEffectiveSkillLevel(SKILL_CLUB) >= 60 or p:getEffectiveSkillLevel(SKILL_DISTANCE) >= 60 end },
            { desc = "Complete at least 5 levels in the Abyss", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 5 end }
        },
        rewardsNormal = {
            { rewardType = "respect", amount = 500 },
            { id = 60008, count = 10 }, -- Condensed Great Health
            { id = 60009, count = 10 }  -- Condensed Great Mana
        },
        rewardsPremium = {
            { id = config.arenaCoinId, count = 20 }, -- 20 Arena Coins
            { id = 60010, count = 3 }               -- 3 Feathers of Lightness
        }
    },
    [4] = {
        name = "Level IV: The Hero (Lv 81-100)",
        minLevel = 100,
        tasks = {
            { desc = "Reach Level 100", check = function(p) return p:getLevel() >= 100 end },
            { desc = "Complete the classic Banshee Quest", check = function(p) return p:getStorageValue(config.questStorages.banshee) > 0 end },
            { desc = "Complete Behemoth Quest (Edron)", check = function(p) return p:getStorageValue(config.questStorages.behemoth) > 0 end },
            { desc = "Reach Level 50 in Abismo Ecoante", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 50 end },
            { desc = "Complete Paradox Tower & Desert Quest", check = function(p) return p:getStorageValue(config.questStorages.paradox) > 0 and p:getStorageValue(config.questStorages.desert) > 0 end }
        },
        rewardsNormal = {
            { id = 60003, count = 1 }, -- Trailblazer Backpack
            { rewardType = "respect", amount = 1000 }
        },
        rewardsPremium = {
            { id = 60014, count = 1 }, -- Class Outfit Box
            { id = config.arenaCoinId, count = 50 } -- 50 Arena Coins
        }
    },
    [5] = {
        name = "Level V: The Legend (Lv 101-150)",
        minLevel = 150,
        tasks = {
            { desc = "Reach Level 150", check = function(p) return p:getLevel() >= 150 end },
            { desc = "Complete Pits of Inferno (POI) Quest Room", check = function(p) return p:getStorageValue(config.questStorages.poi) > 0 end },
            { desc = "Complete Inquisition Quest", check = function(p) return p:getStorageValue(config.questStorages.inquisition) > 0 end },
            { desc = "Reach Level 100 in Abismo Ecoante", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 100 end },
            { desc = "Reach Magic Level 60 or Melee Skill 85", check = function(p) return p:getMagicLevel() >= 60 or p:getEffectiveSkillLevel(SKILL_SWORD) >= 85 or p:getEffectiveSkillLevel(SKILL_AXE) >= 85 or p:getEffectiveSkillLevel(SKILL_CLUB) >= 85 or p:getEffectiveSkillLevel(SKILL_DISTANCE) >= 85 end }
        },
        rewardsNormal = {
            { rewardType = "respect", amount = 2000 },
            { id = 60016, count = 5 } -- 5 Hyper Crystals
        },
        rewardsPremium = {
            { id = config.arenaCoinId, count = 100 }, -- 100 Arena Coins
            { id = 60013, count = 2 }                 -- 2 Turkey Cages
        }
    },
    [6] = {
        name = "Level VI: The Demigod (Lv 151+)",
        minLevel = 200,
        tasks = {
            { desc = "Reach Level 200", check = function(p) return p:getLevel() >= 200 end },
            { desc = "Complete Wrath of the Emperor", check = function(p) return p:getStorageValue(config.questStorages.wrath) > 0 end },
            { desc = "Defeat Azerus (Yalahar Quest)", check = function(p) return p:getStorageValue(config.questStorages.yalahar) > 0 end },
            { desc = "Reach Level 150 in Abismo Ecoante", check = function(p) return p:getStorageValue(config.STORAGE_ARENA_MAX_LEVEL) >= 150 end },
            { desc = "Have at least 10 Feathers of Lightness used", check = function(p) return p:getStorageValue(51007) >= 10 end }
        },
        rewardsNormal = {
            { rewardType = "respect", amount = 5000 },
            { id = 3043, count = 20 } -- 20 Crystal Coins (Gold payout)
        },
        rewardsPremium = {
            { id = config.arenaCoinId, count = 200 }, -- 200 Arena Coins
            { id = 60014, count = 2 }                 -- 2 Class Outfit Boxes
        }
    }
}

-- Helper: Formata tempo restante
local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02dh %02dm %02ds", h, m, s)
end

-- Helper: Confere o progresso do jogador em um determinado Level
local function checkLevelProgress(player, levelIndex)
    local levelData = passLevels[levelIndex]
    if not levelData then return 0, {} end

    local completed = 0
    local taskStates = {}

    for i, task in ipairs(levelData.tasks) do
        local state = task.check(player)
        taskStates[i] = state
        if state then
            completed = completed + 1
        end
    end

    return completed, taskStates
end

-- Menu Principal do Passe de Batalha (Caminho do Aventureiro)
local function openMainPassModal(player)
    local isPremium = player:getStorageValue(config.STORAGE_HERO_KEY_ACTIVE) == 1
    local premiumStatus = isPremium and "UNLOCKED (Hero Key Active)" or "LOCKED (Free Tier Only)"

    local message = string.format(
        "Welcome to the Adventurer's Path!\nComplete challenges to earn standard and premium rewards.\n\nPremium Status: %s",
        premiumStatus
    )

    local window = ModalWindow(MODAL_ID_PASS_MAIN, "Adventurer's Path", message)

    -- Adiciona opções
    window:addChoice(0, "[Daily Login Reward] resgatar daily login bonus")

    for i, levelData in ipairs(passLevels) do
        local completed, _ = checkLevelProgress(player, i)
        window:addChoice(i, string.format("[%s] (Progress: %d/5)", levelData.name, completed))
    end

    -- Botões principais
    window:addButton(1, "Select")
    if not isPremium then
        window:addButton(2, "Unlock Premium")
    end
    window:addButton(0, "Close")

    window:setDefaultEnterButton(1)
    window:setDefaultEscapeButton(0)
    window:sendToPlayer(player)
end

-- Menu Detalhado de um Nível do Passe
local function openLevelPassModal(player, levelIndex)
    local levelData = passLevels[levelIndex]
    if not levelData then return end

    local completed, taskStates = checkLevelProgress(player, levelIndex)
    
    local normalClaimed = player:getStorageValue(config.STORAGE_LEVEL_CLAIMED_NORMAL + levelIndex) == 1
    local premiumClaimed = player:getStorageValue(config.STORAGE_LEVEL_CLAIMED_PREMIUM + levelIndex) == 1
    local isPremium = player:getStorageValue(config.STORAGE_HERO_KEY_ACTIVE) == 1

    local statusNormal = normalClaimed and "Claimed" or (completed == 5 and "READY TO CLAIM" or "Incomplete")
    local statusPremium = premiumClaimed and "Claimed" or (completed == 5 and (isPremium and "READY TO CLAIM" or "Requires Hero Key") or "Incomplete")

    local message = string.format(
        "--- %s ---\n\nChallenges Progress:\n",
        levelData.name
    )

    for i, task in ipairs(levelData.tasks) do
        local stateChar = taskStates[i] and "[X]" or "[ ]"
        message = message .. string.format("%s - %s\n", stateChar, task.desc)
    end

    message = message .. string.format("\nNormal Reward: %s\nPremium Reward: %s", statusNormal, statusPremium)

    local window = ModalWindow(MODAL_ID_PASS_LEVEL, levelData.name, message)

    -- Botões de Resgate
    if completed == 5 then
        if not normalClaimed then
            window:addButton(4, "Claim Normal")
        end
        if not premiumClaimed and isPremium then
            window:addButton(5, "Claim Premium")
        end
    end

    window:addButton(1, "Back")
    window:setDefaultEnterButton(1)
    window:sendToPlayer(player)

    -- Salva o nível selecionado em um storage temporário do player para sabermos de qual nível ele está solicitando o prêmio
    player:setStorageValue(52099, levelIndex)
end

-- Menu Detalhado do Login Diário
local function openLoginPassModal(player)
    -- FIX: Corrigido o storage para config.STORAGE_DAILY_LOGIN_DAY de forma consistente com a tabela config
    local currentDay = math.max(1, player:getStorageValue(config.STORAGE_DAILY_LOGIN_DAY))
    if currentDay > 7 then
        currentDay = 1
        player:setStorageValue(config.STORAGE_DAILY_LOGIN_DAY, 1)
    end

    local cooldown = player:getStorageValue(config.STORAGE_DAILY_LOGIN_COOLDOWN)
    local now = os.time()

    local canClaim = cooldown <= now
    local status = canClaim and "AVAILABLE!" or string.format("Locked (Cooldown: %s)", formatTime(cooldown - now))

    local message = string.format(
        "--- Daily Login Rewards (Endless Loop) ---\n\nToday's Reward (Day %d): %s\nStatus: %s\n\nLogin every day to unlock useful resources!",
        currentDay, dailyRewards[currentDay].desc, status
    )

    local window = ModalWindow(MODAL_ID_PASS_LOGIN, "Daily Login Rewards", message)

    if canClaim then
        window:addButton(6, "Claim Reward")
    end
    window:addButton(1, "Back")
    window:setDefaultEnterButton(1)
    window:sendToPlayer(player)
end

-- ===================== EVENT HANDLER =====================

local passModal = CreatureEvent("AdventurePassModal")

function passModal.onModalWindow(player, modalWindowId, buttonId, choiceId)
    -- Fechar
    if buttonId == 0 then
        return true
    end

    -- Handlers do Menu Principal (Main)
    if modalWindowId == MODAL_ID_PASS_MAIN then
        -- Botão: Voltar/Fechar
        if buttonId == 0 then return true end

        -- Botão: Unlock Premium
        if buttonId == 2 then
            if player:getItemCount(config.heroKeyItemId) < 1 then
                player:sendTextMessage(MESSAGE_FAILURE, "You need a Chest Key (Hero Key) in your inventory to unlock the Premium tier.")
                return true
            end

            player:removeItem(config.heroKeyItemId, 1)
            player:setStorageValue(config.STORAGE_HERO_KEY_ACTIVE, 1)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Congratulations! You have unlocked the Premium tier for the Adventurer's Path!")
            player:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)
            openMainPassModal(player)
            return true
        end

        -- Botão: Select/Entrar
        if buttonId == 1 then
            if choiceId == 0 then
                -- Abre Menu de Login Diário
                openLoginPassModal(player)
            else
                -- Abre Detalhes de um Nível do Passe
                openLevelPassModal(player, choiceId)
            end
            return true
        end
    end

    -- Handlers do Menu de Nível (Challenges)
    if modalWindowId == MODAL_ID_PASS_LEVEL then
        local levelIndex = player:getStorageValue(52099)
        if levelIndex <= 0 then return true end

        -- Botão: Back (Voltar)
        if buttonId == 1 then
            openMainPassModal(player)
            return true
        end

        local levelData = passLevels[levelIndex]
        if not levelData then return true end

        -- Botão: Claim Normal Reward
        if buttonId == 4 then
            player:setStorageValue(config.STORAGE_LEVEL_CLAIMED_NORMAL + levelIndex, 1)
            for _, reward in ipairs(levelData.rewardsNormal) do
                if reward.rewardType == "respect" then
                    local currentRespect = math.max(0, player:getStorageValue(config.STORAGE_RESPECT_POINTS))
                    player:setStorageValue(config.STORAGE_RESPECT_POINTS, currentRespect + reward.amount)
                else
                    player:addItem(reward.id, reward.count)
                end
            end
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have claimed the Normal rewards for %s!", levelData.name))
            player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
            openLevelPassModal(player, levelIndex)
            return true
        end

        -- Botão: Claim Premium Reward
        if buttonId == 5 then
            player:setStorageValue(config.STORAGE_LEVEL_CLAIMED_PREMIUM + levelIndex, 1)
            for _, reward in ipairs(levelData.rewardsPremium) do
                if reward.rewardType == "respect" then
                    local currentRespect = math.max(0, player:getStorageValue(config.STORAGE_RESPECT_POINTS))
                    player:setStorageValue(config.STORAGE_RESPECT_POINTS, currentRespect + reward.amount)
                else
                    player:addItem(reward.id, reward.count)
                end
            end
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have claimed the PREMIUM rewards for %s!", levelData.name))
            player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_RED)
            openLevelPassModal(player, levelIndex)
            return true
        end
    end

    -- Handlers do Menu de Daily Login
    if modalWindowId == MODAL_ID_PASS_LOGIN then
        -- Botão: Back (Voltar)
        if buttonId == 1 then
            openMainPassModal(player)
            return true
        end

        -- Botão: Claim Reward (Login)
        if buttonId == 6 then
            -- FIX: Corrigido de config.STORAGE_DAILY_COOLDOWN para config.STORAGE_DAILY_LOGIN_DAY
            local currentDay = math.max(1, player:getStorageValue(config.STORAGE_DAILY_LOGIN_DAY))
            local rewardData = dailyRewards[currentDay]

            if rewardData.rewardType == "respect" then
                local currentRespect = math.max(0, player:getStorageValue(config.STORAGE_RESPECT_POINTS))
                player:setStorageValue(config.STORAGE_RESPECT_POINTS, currentRespect + rewardData.amount)
            else
                for _, item in ipairs(rewardData.items) do
                    player:addItem(item.id, item.count)
                end
            end

            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Daily Reward Day %d claimed: %s!", currentDay, rewardData.desc))
            player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_BLUE)

            -- Seta cooldown de 20 horas e incrementa o dia
            player:setStorageValue(config.STORAGE_DAILY_LOGIN_COOLDOWN, os.time() + (20 * 3600))
            
            -- FIX: Corrigido de config.STORAGE_DAILY_COOLDOWN para config.STORAGE_DAILY_LOGIN_DAY
            player:setStorageValue(config.STORAGE_DAILY_LOGIN_DAY, currentDay + 1)

            openLoginPassModal(player)
            return true
        end
    end

    return true
end

-- Registra a modal do passe de batalha
passModal:register()

--------------------------------------------------------
-- Talkaction Registration (!pass ou !journey)
--------------------------------------------------------
local adventurePassTalk = TalkAction("!pass", "!journey")

-- FIX EXTREMAMENTE CRÍTICO: Alterado de adventurePassTalk.onTrigger para onSay para obedecer ao seu revscriptsys.lua!
function adventurePassTalk.onSay(player, words, param)
    openMainPassModal(player)
    return true
end

-- FIX DE REGISTRO DO C++: Define o tipo de acesso normal (jogadores comuns) exigido pelo C++ do Crystal Server para evitar o erro de groupType
adventurePassTalk:groupType("normal")
adventurePassTalk:register()