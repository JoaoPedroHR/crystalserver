--[[
    Starter Packs (60017, 60018, 60019)
    ========================================
    Ao usar, distribui os itens da tabela correspondente para a mochila do
    player. Se não houver espaço/capacidade suficiente, avisa o player e
    NÃO consome o pacote.

    Ajustado para injetar as 100 cargas corretas nos elixires condensados ao abrir.
]]

local PACKS = {
    [60017] = { -- Explorer Pack
        name = "Explorer Pack",
        items = {
            { id = 60016, count = 5 },  -- Hyper XP Crystals
            { id = 60001, count = 1 },  -- Explorer's Backpack
            { id = 60015, count = 2 },  -- Chest Keys
            { id = 60005, count = 1 }, -- Condensed Mana Elixirs
            { id = 60004, count = 1 }, -- Condensed Health Elixirs
            { id = 60010, count = 1 },  -- Feather of Lightness
        },
    },
    [60018] = { -- Hunter Pack
        name = "Hunter Pack",
        items = {
            { id = 60016, count = 10 }, -- Hyper XP Crystals
            { id = 60015, count = 2 },  -- Chest Keys
            { id = 60007, count = 1 }, -- Condensed Strong Mana Elixirs
            { id = 60006, count = 1 }, -- Condensed Strong Health Elixirs
            { id = 60013, count = 1 },  -- Turkey Mount Cage
            { id = 60002, count = 1 },  -- Hunter's Backpack
            { id = 60010, count = 2 },  -- Feathers of Lightness
        },
    },
    [60019] = { -- Trailblazer Pack
        name = "Trailblazer Pack",
        items = {
            { id = 60009, count = 1 }, -- Condensed Great Mana Elixirs
            { id = 60008, count = 1 }, -- Condensed Great Health Elixirs
            { id = 60015, count = 2 },  -- Chest Keys
            { id = 60016, count = 10 }, -- Hyper XP Crystals
            { id = 60012, count = 1 },  -- Arcane Travel Compass
            { id = 60003, count = 1 },  -- Trailblazer's Backpack
            { id = 60010, count = 4 },  -- Feathers of Lightness
            { id = 60013, count = 1 },  -- Turkey Mount Cage
            { id = 60011, count = 2 },  -- Familiar's Reset Scrolls
            { id = 60014, count = 1 },  -- Class Outfit Box
        },
    },
}

local starterPack = Action()

function starterPack.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local pack = PACKS[item:getId()]
    if not pack then
        return false
    end

    -- Confere capacidade física antes de abrir
    for _, entry in ipairs(pack.items) do
        if player:getFreeCapacity() < ItemType(entry.id):getWeight() * entry.count then
            player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough capacity to open this pack.")
            return true
        end
    end

    -- Distribui os itens aplicando a carga de 500 nos elixires de forma nativa
    for _, entry in ipairs(pack.items) do
        if entry.id >= 60004 and entry.id <= 60009 then
            -- Elixires Condensados: cria individualmente cada frasco com 500 cargas
            for t = 1, entry.count do
                local elixir = player:addItem(entry.id, 500)
                if not elixir then
                    player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough free slots to open this pack.")
                    return true
                end
            end
        else
            -- Itens normais
            local added = player:addItem(entry.id, entry.count)
            if not added then
                player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough free slots to open this pack.")
                return true
            end
        end
    end

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have received your %s!", pack.name))
    player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
    item:remove(1)
    return true
end

for itemId in pairs(PACKS) do
    starterPack:id(itemId)
end

starterPack:register()