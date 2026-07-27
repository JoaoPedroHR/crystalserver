--[[
    Class Outfit Box (60014)
    ============================
    Consumível. Abre modal window com opções de classes. Ao escolher, concede o
    outfit base + AMBOS os addons (bitmask 3) e já veste o player nele.

    Atualizado com os lookTypes oficiais do outfits.xml do servidor.
    Opções de Knight divididas por classe de armas (Sword, Axe, Club).
]]

local MODAL_ID_OUTFIT_BOX = 6002

-- lookType mapeado diretamente do outfits.xml do servidor
local CLASS_OUTFITS = {
    { key = "knight_sword", label = "Knight - Champion (Sword)",      male = 633,  female = 632 },
    { key = "knight_axe",   label = "Knight - Mercenary (Axe)",       male = 1056, female = 1057 },
    { key = "knight_club",  label = "Knight - Siege Master (Club)",   male = 1051, female = 1050 },
    { key = "mage",         label = "Sorcerer - Necromancer",         male = 1845, female = 1846 },
    { key = "druid",        label = "Druid - Forest Warden",          male = 1415, female = 1416 },
    { key = "paladin",      label = "Paladin - Arbalester",           male = 1449, female = 1450 },
    { key = "monk",         label = "Monk - Martial Artist",          male = 1837, female = 1838 },
}

local outfitBox = Action()

function outfitBox.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local window = ModalWindow(MODAL_ID_OUTFIT_BOX, "Class Outfit Box", "Choose your starting outfit:")
    for index, class in ipairs(CLASS_OUTFITS) do
        window:addChoice(index - 1, class.label)
    end
    window:addButton(1, "Confirm")
    window:addButton(0, "Cancel")
    window:setDefaultEnterButton(1)
    window:setDefaultEscapeButton(0)
    window:sendToPlayer(player)

    return true
end

outfitBox:id(60014)
outfitBox:register()

local outfitBoxModal = CreatureEvent("ClassOutfitBoxModal")

function outfitBoxModal.onModalWindow(player, modalWindowId, buttonId, choiceId)
    if modalWindowId ~= MODAL_ID_OUTFIT_BOX then
        return true
    end

    if buttonId ~= 1 then
        return true
    end

    local class = CLASS_OUTFITS[choiceId + 1]
    if not class then
        return true
    end

    local outfitId = player:getSex() == 0 and class.female or class.male

    player:addOutfitAddon(outfitId, 3) -- 3 = bitmask para ambos addons
    player:setOutfit({
        lookType = outfitId,
        lookAddons = 3,
    })

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You are now wearing the %s outfit!", class.label))
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)

    local boxItem = player:getItemById(60014, true)
    if boxItem then
        boxItem:remove(1)
    end

    return true
end

outfitBoxModal:type("modalwindow")
outfitBoxModal:register()