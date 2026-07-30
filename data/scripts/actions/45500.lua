local fornalha = Action()

function fornalha.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- If the map item forces a recipe, call craft directly
    if item and item.getAttribute then
        local ok, forced = pcall(function() return item:getAttribute("forge_recipe") end)
        if ok and type(forced) == "number" and forced > 0 then
            local succ, crafted = pcall(function() return DuskForge.craft(player, forced) end)
            if not succ or not crafted then
                player:sendTextMessage(MESSAGE_STATUS_SMALL, "Failed to forge. Check materials, inventory space and server logs.")
                return false
            end
            local name = "(item)"
            if crafted.getName then
                local s, n = pcall(function() return crafted:getName() end)
                if s and type(n) == "string" then name = n end
            end
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Forged successfully: " .. name)
            return true
        end
    end

    -- Build a modal window with available recipes
    local mw = ModalWindow()
    mw:setTitle("Forge - Choose a recipe")
    mw:setMessage("Select the item you want to forge:\n")

    if not DuskForgeRecipes or type(DuskForgeRecipes) ~= "table" then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "No forge recipes available on the server.")
        return false
    end

    -- Add a choice for each recipe (format: "ID <id> - result=<itemid> - materials: ...")
    for id, r in pairs(DuskForgeRecipes) do
        local parts = {}
        if r.materials and type(r.materials) == "table" then
            for _, m in ipairs(r.materials) do
                table.insert(parts, tostring(m[2]) .. "x" .. tostring(m[1]))
            end
        end
        local label = string.format("[%d] item=%d (materials: %s)", id, r.result or 0, table.concat(parts, ", "))
        -- capture recipe id for the callback
        mw:addChoice(label, function(player, button, choice)
            local ok, crafted = pcall(function() return DuskForge.craft(player, id) end)
            if not ok or not crafted then
                player:sendTextMessage(MESSAGE_STATUS_SMALL, "Failed to forge. Check materials, inventory space and server logs.")
                return true
            end
            local name = "(item)"
            if crafted.getName then
                local s, n = pcall(function() return crafted:getName() end)
                if s and type(n) == "string" then name = n end
            end
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Forged successfully: " .. name)
            return true
        end)
    end

    -- Add a cancel button
    mw:addButton("Cancel", function(player, button, choice)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Forge canceled.")
        return true
    end)

    -- Send the modal to player
    mw:sendToPlayer(player)
    return true
end

fornalha:aid(45500)
fornalha:register()
