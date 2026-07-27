--[[ 
    Arcane Travel Compass (60012)
    ================================
    Teleporta o player para os magic carpets.
    O item é infinito e possui apenas cooldown de 1 minuto.
]]

dofile('data/scripts/lib/starterpack_storages.lua')

local MODAL_ID_COMPASS = 6003
local COOLDOWN_SECONDS = 60

local DESTINATIONS = {
    { name = "Darashia - Magic Carpet", pos = Position(33270, 32441, 6) },
    { name = "Edron - Magic Carpet", pos = Position(33193, 31784, 3) },
    { name = "Farmine - Magic Carpet", pos = Position(32983, 31539, 1) },
    { name = "Femor Hills - Magic Carpet", pos = Position(32536, 31837, 4) },
    { name = "Svargrond - Magic Carpet", pos = Position(32253, 31097, 4) },    
    { name = "Kazordoon - Magic Carpet", pos = Position(32588, 31941, 0) },
    { name = "Issavi - Magic Carpet", pos = Position(33957, 31515, 0) },
    { name = "Marapur - Magic Carpet", pos = Position(33805, 32767, 2) }, 
}

local compass = Action()

function compass.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cooldown = player:getStorageValue(STORAGE_ARCANE_COMPASS_COOLDOWN)

    if cooldown > os.time() then
        player:sendTextMessage(
            MESSAGE_FAILURE,
            "You must wait 60 seconds before using the compass again."
        )
        return true
    end

    local window = ModalWindow(
        MODAL_ID_COMPASS,
        "Arcane Travel Compass",
        "Choose your destination:"
    )

    for index, destination in ipairs(DESTINATIONS) do
        window:addChoice(index - 1, destination.name)
    end

    window:addButton(1, "Travel")
    window:addButton(0, "Cancel")
    window:setDefaultEnterButton(1)
    window:setDefaultEscapeButton(0)
    window:sendToPlayer(player)

    return true
end

compass:id(60012)
compass:register()


local compassModal = CreatureEvent("ArcaneCompassModal")

function compassModal.onModalWindow(player, modalWindowId, buttonId, choiceId)
    if modalWindowId ~= MODAL_ID_COMPASS then
        return true
    end

    if buttonId ~= 1 then
        return true
    end

    local destination = DESTINATIONS[choiceId + 1]

    if not destination then
        return true
    end

    if player:hasCondition(CONDITION_INFIGHT) then
        player:sendTextMessage(
            MESSAGE_FAILURE,
            "You cannot travel while in battle."
        )
        return true
    end

    if player:getSkull() ~= SKULL_NONE then
        player:sendTextMessage(
            MESSAGE_FAILURE,
            "You cannot travel while marked with a skull."
        )
        return true
    end

    if player:isPzLocked() then
        player:sendTextMessage(
            MESSAGE_FAILURE,
            "You cannot travel while PZ locked."
        )
        return true
    end

    player:teleportTo(destination.pos)
    destination.pos:sendMagicEffect(CONST_ME_TELEPORT)

    player:setStorageValue(
        STORAGE_ARCANE_COMPASS_COOLDOWN,
        os.time() + COOLDOWN_SECONDS
    )

    return true
end

compassModal:type("modalwindow")
compassModal:register()