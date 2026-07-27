--[[
    Hyper XP Crystal System (60016)
    ===================================
    Inspirado no Hyper EXP Card do Perfect World.

    Usar o cristal (ou digitar !hyper / !boost) abre uma modal window:
      - Se o player NÃO tem buff ativo: mostra as 5 opções de ativação.
      - Se o player TEM buff ativo e rodando: mostra tempo restante + botão Pause.
      - Se o player TEM buff ativo e pausado: mostra tempo restante + botão Resume.

    Regra anti-abuso: só pode pausar de novo depois de 3 minutos (180s) desde
    o último resume. Isso evita "pausar micro-segundos antes do monstro morrer".

    O tick (contagem regressiva) roda via addEvent recursivo, 1 vez a cada
    10 segundos, só enquanto o player está online e o buff está ativo e
    NÃO pausado.

    Atualizações de segurança aplicadas:
    - Bloqueio de uso fora da backpack (não funciona no chão).
    - Talkaction !hyper / !boost adicionada para gerenciar o tempo mesmo com 0 cristais.
]]

dofile('data/scripts/lib/starterpack_storages.lua')

local MODAL_ID_HYPERXP = 6001
local TICK_INTERVAL = 10 -- segundos
local PAUSE_LOCK_SECONDS = 180 -- 3 minutos

local OPTIONS = {
    { hours = 1, bonus = 80,  cost = 3, cooldownHours = 20 },
    { hours = 1, bonus = 120, cost = 5, cooldownHours = 20 },
    { hours = 2, bonus = 50,  cost = 3, cooldownHours = 19 },
    { hours = 2, bonus = 60,  cost = 4, cooldownHours = 19 },
    { hours = 3, bonus = 40,  cost = 3, cooldownHours = 18 },
}

-- Guarda quais players já têm um loop de tick rodando, pra nunca duplicar.
HyperXPActiveTicks = HyperXPActiveTicks or {}

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02dh %02dm %02ds", h, m, s)
end

function StartHyperXPTick(playerId)
    if HyperXPActiveTicks[playerId] then
        return -- já tem um loop rodando pra esse player
    end
    HyperXPActiveTicks[playerId] = true

    local function tick()
        local player = Player(playerId)
        if not player then
            HyperXPActiveTicks[playerId] = nil
            return
        end

        if player:getStorageValue(STORAGE_HYPER_XP_PAUSED) == 1 then
            HyperXPActiveTicks[playerId] = nil
            return
        end

        local timeLeft = player:getStorageValue(STORAGE_HYPER_XP_TIME_LEFT)
        if timeLeft <= 0 then
            player:setStorageValue(STORAGE_HYPER_XP_BONUS, 0)
            player:setStorageValue(STORAGE_HYPER_XP_TIME_LEFT, 0)
            player:setStorageValue(STORAGE_HYPER_XP_PAUSED, 0)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your Hyper XP boost has expired.")
            HyperXPActiveTicks[playerId] = nil
            return
        end

        player:setStorageValue(STORAGE_HYPER_XP_TIME_LEFT, timeLeft - TICK_INTERVAL)
        HyperXPActiveTicks[playerId] = addEvent(tick, TICK_INTERVAL * 1000)
    end

    tick()
end

local function buildStateAWindow()
    local window = ModalWindow(MODAL_ID_HYPERXP, "Hyper XP Crystal", "Choose a boost to activate:")
    for index, option in ipairs(OPTIONS) do
        window:addChoice(index - 1, string.format(
            "%dh | +%d%% EXP | Costs %d crystals",
            option.hours, option.bonus, option.cost
        ))
    end
    window:addButton(1, "Activate")
    window:addButton(0, "Cancel")
    window:setDefaultEnterButton(1)
    window:setDefaultEscapeButton(0)
    return window
end

local function buildStateBCWindow(player, paused)
    local timeLeft = player:getStorageValue(STORAGE_HYPER_XP_TIME_LEFT)
    local bonus = player:getStorageValue(STORAGE_HYPER_XP_BONUS)

    local status = paused and "PAUSED" or "RUNNING"
    local message = string.format(
        "Status: %s\nBonus: +%d%% EXP\nTime left: %s",
        status, bonus, formatTime(timeLeft)
    )

    local window = ModalWindow(MODAL_ID_HYPERXP, "Hyper XP Crystal", message)
    if paused then
        window:addButton(3, "Resume Time")
    else
        window:addButton(2, "Pause Time")
    end
    window:addButton(0, "Close")
    window:setDefaultEnterButton(paused and 3 or 2)
    window:setDefaultEscapeButton(0)
    return window
end

-- Centraliza a abertura do menu de Hiper XP para ser usado no item e no comando de texto
local function openHyperXPMenu(player)
    local bonus = player:getStorageValue(STORAGE_HYPER_XP_BONUS)

    if bonus > 0 then
        local paused = player:getStorageValue(STORAGE_HYPER_XP_PAUSED) == 1
        buildStateBCWindow(player, paused):sendToPlayer(player)
    else
        local cooldown = player:getStorageValue(STORAGE_HYPER_XP_COOLDOWN)
        if cooldown > os.time() then
            local remaining = cooldown - os.time()
            player:sendTextMessage(MESSAGE_FAILURE, string.format(
                "You must wait %s before activating another Hyper XP boost.",
                formatTime(remaining)
            ))
            return true
        end
        buildStateAWindow():sendToPlayer(player)
    end
    return true
end

local hyperCrystal = Action()

function hyperCrystal.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- FIX DE SEGURANÇA: Garante que o jogador só use o cristal se ele estiver no seu inventário
    if not item:getTopParent() or item:getTopParent() ~= player then
        player:sendTextMessage(MESSAGE_FAILURE, "You can only use this crystal from your inventory.")
        return true
    end

    openHyperXPMenu(player)
    return true
end

hyperCrystal:id(60016)
hyperCrystal:register()

-- ===================== TALKACTION REGISTRATION =====================
-- Permite abrir o menu digitando !hyper ou !boost, facilitando a pausa mesmo com 0 cristais
local hyperXPCommandLine = TalkAction("!hyper", "!boost")

function hyperXPCommandLine.onSay(player, words, param)
    openHyperXPMenu(player)
    return true
end

hyperXPCommandLine:groupType("normal")
hyperXPCommandLine:register()

-- ===================== MODAL WINDOW HANDLER =====================

local hyperCrystalModal = CreatureEvent("HyperXPModal")

function hyperCrystalModal.onModalWindow(player, modalWindowId, buttonId, choiceId)
    if modalWindowId ~= MODAL_ID_HYPERXP then
        return true
    end

    -- Cancelar / Fechar
    if buttonId == 0 then
        return true
    end

    -- Ativar novo boost (State A)
    if buttonId == 1 then
        local option = OPTIONS[choiceId + 1]
        if not option then
            return true
        end

        if player:getStorageValue(STORAGE_HYPER_XP_BONUS) > 0 then
            player:sendTextMessage(MESSAGE_FAILURE, "You already have an active Hyper XP boost.")
            return true
        end

        local crystalCount = player:getItemCount(60016)
        if crystalCount < option.cost then
            player:sendTextMessage(MESSAGE_FAILURE, string.format(
                "You need %d Hyper XP Crystals to activate this boost (you have %d).",
                option.cost, crystalCount
            ))
            return true
        end

        player:removeItem(60016, option.cost)

        player:setStorageValue(STORAGE_HYPER_XP_BONUS, option.bonus)
        player:setStorageValue(STORAGE_HYPER_XP_TIME_LEFT, option.hours * 3600)
        player:setStorageValue(STORAGE_HYPER_XP_PAUSED, 0)
        player:setStorageValue(STORAGE_HYPER_XP_COOLDOWN, os.time() + (option.cooldownHours * 3600))
        player:setStorageValue(STORAGE_HYPER_XP_LAST_UNPAUSE, os.time())

        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
            "Hyper XP activated! +%d%% EXP for %dh.", option.bonus, option.hours
        ))
        player:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)

        StartHyperXPTick(player:getId())
        return true
    end

    -- Pause (State B)
    if buttonId == 2 then
        local lastUnpause = player:getStorageValue(STORAGE_HYPER_XP_LAST_UNPAUSE)
        if lastUnpause > 0 and os.time() < lastUnpause + PAUSE_LOCK_SECONDS then
            local remaining = (lastUnpause + PAUSE_LOCK_SECONDS) - os.time()
            player:sendTextMessage(MESSAGE_FAILURE, string.format(
                "You must wait %d more second(s) before you can pause again.", remaining
            ))
            return true
        end

        player:setStorageValue(STORAGE_HYPER_XP_PAUSED, 1)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Hyper XP boost paused.")
        return true
    end

    -- Resume (State C)
    if buttonId == 3 then
        player:setStorageValue(STORAGE_HYPER_XP_PAUSED, 0)
        player:setStorageValue(STORAGE_HYPER_XP_LAST_UNPAUSE, os.time())
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Hyper XP boost resumed.")
        StartHyperXPTick(player:getId())
        return true
    end

    return true
end

hyperCrystalModal:type("modalwindow")
hyperCrystalModal:register()