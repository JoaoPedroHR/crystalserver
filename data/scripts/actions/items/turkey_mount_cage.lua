--[[
    Turkey Mount Cage (60013)
    ============================
    Consumível. Desbloqueia aleatoriamente 1 de 3 mounts de peru.

    AJUSTE: Preencha os IDs corretos dos mounts abaixo — eles ficam em
    data/XML/mounts.xml no seu servidor. Coloquei os nomes certos, mas o
    ID numérico varia dependendo da versão/dat do seu servidor, então
    confira lá antes de usar.
]]

-- AJUSTE: confira os IDs reais em data/XML/mounts.xml
local TURKEY_MOUNTS = {
    { id = 168,  name = "Turkey" },
    { id = 169,  name = "Fat Turkey" },
    { id = 170,  name = "Ornate Turkey" },
}

local turkeyCage = Action()

function turkeyCage.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- Filtra só os mounts que o player ainda não tem, pra não "desperdiçar" o item
    local available = {}
    for _, mount in ipairs(TURKEY_MOUNTS) do
        if not player:hasMount(mount.id) then
            available[#available + 1] = mount
        end
    end

    if #available == 0 then
        player:sendTextMessage(MESSAGE_FAILURE, "You already own all the turkey mounts!")
        return true
    end

    local chosen = available[math.random(1, #available)]
    player:addMount(chosen.id)

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The cage opens and you've unlocked the '%s' mount!", chosen.name))
    player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)

    item:remove(1)
    return true
end

turkeyCage:id(60013)
turkeyCage:register()
