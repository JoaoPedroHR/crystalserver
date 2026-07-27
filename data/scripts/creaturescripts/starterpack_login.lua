--[[
    Starter Pack System - Login Hook
    ====================================
    1. Registra os 3 modal windows (Hyper XP, Class Outfit Box, Arcane
       Compass) para o player que loga — sem isso, os botões da modal
       window não vão disparar as funções onModalWindow correspondentes.
    2. Se o player já tinha um Hyper XP boost ativo e rodando (ex: caiu
       e voltou, ou o servidor reiniciou), re-arma o loop de tick pra
       continuar contando o tempo certinho.
]]

dofile('data/scripts/lib/starterpack_storages.lua')

local starterPackLogin = CreatureEvent("StarterPackLogin")

function starterPackLogin.onLogin(player)
    player:registerEvent("HyperXPModal")
    player:registerEvent("ClassOutfitBoxModal")
    player:registerEvent("ArcaneCompassModal")
    player:registerEvent("AdventurePassModal")

    local bonus = player:getStorageValue(STORAGE_HYPER_XP_BONUS)
    local paused = player:getStorageValue(STORAGE_HYPER_XP_PAUSED) == 1
    local timeLeft = player:getStorageValue(STORAGE_HYPER_XP_TIME_LEFT)

    if bonus > 0 and not paused and timeLeft > 0 then
        StartHyperXPTick(player:getId())
    end

    return true
end

starterPackLogin:type("login")
starterPackLogin:register()
