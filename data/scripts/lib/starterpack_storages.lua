--[[
    STARTER PACK SYSTEM - Storages
    ================================
    Range seguro 51000-51007 — verificado que NÃO colide com nenhuma
    storage existente no projeto (arena usa 50001-50008, TibiaDrome usa 64000+).

    Este arquivo é carregado via dofile() no topo de todo script que precisa
    dessas constantes, então a ordem de carregamento dos scripts pelo
    Revscriptsys NÃO importa.
]]

STORAGE_HYPER_XP_BONUS         = 51000 -- % de bônus de exp ativo no momento (0 = sem buff)
STORAGE_HYPER_XP_TIME_LEFT     = 51001 -- segundos restantes do buff
STORAGE_HYPER_XP_PAUSED        = 51002 -- 1 = pausado, 0/-1 = rodando
STORAGE_HYPER_XP_COOLDOWN      = 51003 -- os.time() em que o player pode ativar de novo
STORAGE_HYPER_XP_LAST_UNPAUSE  = 51004 -- os.time() do último "resume", usado na regra anti-abuso de 3 min

-- Cooldown "base" usado pelo Arcane Travel Compass (1 minuto)
STORAGE_ARCANE_COMPASS_COOLDOWN = 51006

-- Contador de Feathers of Lightness usadas (histórico)
STORAGE_FEATHERS_USED           = 51007
