--[[
    Feather of Lightness (60010)
    ==============================
    Consumível. Aumenta a capacidade (Cap) do jogador permanentemente em +100.

    No CrystalServer, a capacidade interna é armazenada em "centésimos"
    (1 cap no client = 100 unidades internas), então +100 cap = +10000 unidades.

    Usa uma storage própria para registrar quantas penas o player já usou,
    tanto pra fins de log quanto caso você queira futuramente colocar um
    limite máximo de usos (hoje está ilimitado, como pedido na spec).
]]

dofile('data/scripts/lib/starterpack_storages.lua')

local CAP_BONUS_PER_FEATHER = 100 -- 100 cap visíveis no client
local CAP_INTERNAL_MULTIPLIER = 100 -- 1 cap = 100 unidades internas

local feather = Action()

function feather.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    player:setCapacity(player:getCapacity() + (CAP_BONUS_PER_FEATHER * CAP_INTERNAL_MULTIPLIER))

    local used = player:getStorageValue(STORAGE_FEATHERS_USED)
    if used < 0 then
        used = 0
    end
    player:setStorageValue(STORAGE_FEATHERS_USED, used + 1)

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You feel lighter! Your capacity increased by %d.", CAP_BONUS_PER_FEATHER))
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)

    item:remove(1)
    return true
end

feather:id(60010)
feather:register()
