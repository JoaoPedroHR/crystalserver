--[[
    Condensed Elixirs (60004 - 60009)
    ==================================
    Cada elixir cura como a poção equivalente, mas tem 100 "doses" (charges)
    dentro do mesmo item.

    Atualizado:
    - Removidas mensagens de texto redundantes no meio da tela (cura registrada nativamente).
    - Adicionado requerimento de nível mínimo (Level 50 para Strongs e Level 80 para Greats).
]]

local config = {
    [60004] = { name = "condensed health elixir",        type = "health", min = 40,  max = 70,   level = 1   }, -- like Health Potion
    [60005] = { name = "condensed mana elixir",           type = "mana",   min = 30,  max = 70,   level = 1   }, -- like Mana Potion
    [60006] = { name = "condensed strong health elixir",  type = "health", min = 80,  max = 150,  level = 50  }, -- like Strong Health Potion
    [60007] = { name = "condensed strong mana elixir",    type = "mana",   min = 60,  max = 130,  level = 50  }, -- like Strong Mana Potion
    [60008] = { name = "condensed great health elixir",   type = "health", min = 200, max = 400,  level = 80  }, -- like Great Health Potion
    [60009] = { name = "condensed great mana elixir",     type = "mana",   min = 150, max = 300,  level = 80  }, -- like Great Mana Potion
}

local condensedElixir = Action()

function condensedElixir.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local data = config[item:getId()]
    if not data then
        return false
    end

    -- Verifica requerimento de nível mínimo do elixir
    if player:getLevel() < data.level then
        player:sendTextMessage(MESSAGE_FAILURE, string.format("You must be at least level %d to use this elixir.", data.level))
        return true
    end

    local charges = item:getSubType()
    if charges <= 0 then
        item:remove(1)
        return true
    end

    local amount = math.random(data.min, data.max)

    if data.type == "health" then
        if player:getHealth() >= player:getMaxHealth() then
            player:sendTextMessage(MESSAGE_FAILURE, "You are already at full health.")
            return true
        end
        player:addHealth(amount)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    else
        if player:getMana() >= player:getMaxMana() then
            player:sendTextMessage(MESSAGE_FAILURE, "You already have full mana.")
            return true
        end
        player:addMana(amount)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    end

    -- Desconta 1 carga do elixir condensado
    if charges - 1 <= 0 then
        item:remove(1)
    else
        item:transform(item:getId(), charges - 1)
    end

    return true
end

for itemId in pairs(config) do
    condensedElixir:id(itemId)
end

condensedElixir:register()