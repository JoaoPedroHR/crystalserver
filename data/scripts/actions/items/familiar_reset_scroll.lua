--[[
    Familiar's Reset Scroll (60011)
    ==================================
    Consumível. Reseta o cooldown/exaustão do familiar (summon) da vocação.

    Adaptado para o CrystalServer que usa o sistema KV (Key-Value) para
    controlar o tempo de summon do familiar via player:kv():get/set("familiar-summon-time").

    O que este script faz:
    1. Verifica se o player tem nível 200 ou mais para poder usar o scroll.
    2. Verifica se o player tem vocação com familiar configurado.
    3. Reseta o timer do familiar via KV (seta "familiar-summon-time" para
       os.time() + duração padrão, efetivamente "re-invocando" o familiar).
    4. Remove o scroll.
--]]

local FAMILIAR_DURATION = 15 * 60 -- 15 minutos (duração padrão do familiar no Tibia)

local familiarReset = Action()

function familiarReset.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- FIX: Verifica se o jogador tem nível 200 ou mais para poder usar o scroll
    if player:getLevel() < 200 then
        player:sendTextMessage(MESSAGE_FAILURE, "You must be at least level 200 to use this scroll.")
        return true
    end

    -- Verifica se o player tem vocação com familiar configurado
    local vocationBaseId = player:getVocation():getBaseId()
    if not FAMILIAR_ID or not FAMILIAR_ID[vocationBaseId] then
        player:sendTextMessage(MESSAGE_FAILURE, "Your vocation does not have a familiar.")
        return true
    end

    -- Verifica se o familiar NÃO está ativo (ou seja, está em cooldown)
    local familiarSummonTime = player:kv():get("familiar-summon-time") or 0
    local now = os.time()

    if familiarSummonTime > now then
        -- Familiar ainda está ativo, não precisa resetar
        player:sendTextMessage(MESSAGE_FAILURE, "Your familiar is still active. Wait until it expires first.")
        return true
    end

    -- Reseta o timer do familiar — seta para agora + duração, permitindo
    -- que o sistema de login re-invoque o familiar
    player:kv():set("familiar-summon-time", now + FAMILIAR_DURATION)

    -- Tenta criar o familiar imediatamente
    local familiarData = FAMILIAR_ID[vocationBaseId]
    if familiarData and familiarData.name then
        player:createFamiliar(familiarData.name, FAMILIAR_DURATION)
    end

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your familiar's exhaustion has been reset! It has been re-summoned.")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)

    item:remove(1)
    return true
end

familiarReset:id(60011)
familiarReset:register()