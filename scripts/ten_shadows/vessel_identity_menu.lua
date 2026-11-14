local IdentityMenu = {}

local GENDERS = {"unspecified", "male", "female", "nonbinary"}
local PRESENTATIONS = {"androgynous", "masculine", "feminine"}
local PRONOUNS = {
    unspecified = "they/them",
    male = "he/him",
    female = "she/her",
    nonbinary = "they/them",
}

local function copyProfile(profile)
    return {
        name = profile.name,
        gender = profile.gender,
        pronouns = profile.pronouns,
        presentation = profile.presentation,
    }
end

local function cycle(values, current, direction)
    local index = 1
    for i, value in ipairs(values) do
        if value == current then
            index = i
            break
        end
    end
    index = ((index - 1 + direction) % #values) + 1
    return values[index]
end

local function closeIdentity(menu)
    menu._identity_namer = nil
    menu._identity_draft = nil
    menu._identity_imported_name = nil
    menu._identity_setup = false
    menu.state = "MAIN"
    menu.currently_selected = 6
end

local function applyProfile(profile)
    local member = Game:getPartyMember("vessel")
    if member then
        member.name = profile.name
        member.gender = profile.gender
        member.pronouns = profile.pronouns
        member.presentation = profile.presentation
    end

    -- The party member owns the actor instance used by its overworld and
    -- battle sprites. Update that instance instead of the registry prototype.
    local actor = member and member.actor
    if actor then
        actor.name = profile.name
        actor.gender = profile.gender
        actor.pronouns = profile.pronouns
        actor.presentation = profile.presentation
    end
end

local function beginTextEntry(menu, field)
    local title, confirm, limit
    if field == "name" then
        title = "ENTER THE VESSEL'S NAME."
        confirm = "THIS IS THE VESSEL'S NAME."
        limit = 12
    else
        title = "ENTER YOUR PRONOUNS."
        confirm = "THESE ARE YOUR PRONOUNS."
        limit = 32
    end

    local namer
    namer = FileNamer({
        name = menu._identity_draft[field],
        limit = limit,
        name_text = title,
        confirm_text = confirm,
        goner_style = false,
        crash_names = {},
        deny_names = {},
        on_confirm = function(value)
            menu._identity_draft[field] = value
            menu._identity_namer = nil
            if namer then namer:remove() end
        end,
        on_cancel = function()
            menu._identity_namer = nil
            if namer then namer:remove() end
        end,
    })
    namer.layer = 20
    menu._identity_namer = namer
    menu:addChild(namer)
end

local function openIdentity(menu, setup)
    menu._identity_draft = copyProfile(Mod.vessel_identity.get())
    menu._identity_imported_name = nil
    menu._identity_imported_path = nil
    menu._identity_setup = setup == true
    menu._identity_selected = 1
    menu._identity_notice = nil

    -- File access is read-only. The detected name is only copied after the
    -- player explicitly selects the import row.
    local imported_name, imported_path = Mod.vessel_identity.findDeltaruneName()
    menu._identity_imported_name = imported_name
    menu._identity_imported_path = imported_path
    menu.state = "IDENTITY"
end

local function saveIdentity(menu)
    local profile = Mod.vessel_identity.save(menu._identity_draft)
    applyProfile(profile)
    Assets.stopAndPlaySound("ui_select")

    if menu._identity_setup then
        menu._identity_setup = false
        if Game.world then
            Game.world:closeMenu()
        end
        Mod.vessel_identity_startup.startPendingEncounter(Mod, Game)
    else
        closeIdentity(menu)
    end
end

local function leaveIdentity(menu)
    if menu._identity_setup then
        -- First-run setup can be skipped; doing so records the visible defaults
        -- so the player is not prompted again on every new launch.
        saveIdentity(menu)
    else
        Assets.stopAndPlaySound("ui_cancel_small")
        closeIdentity(menu)
    end
end

local function moveIdentitySelection(menu, delta)
    local old = menu._identity_selected
    menu._identity_selected = MathUtils.clamp(old + delta, 1, 7)
    if old ~= menu._identity_selected then
        Assets.stopAndPlaySound("ui_move")
    end
end

local function adjustIdentityValue(menu, direction)
    local selected = menu._identity_selected
    local draft = menu._identity_draft

    if selected == 3 then
        draft.gender = cycle(GENDERS, draft.gender, direction)
        draft.pronouns = PRONOUNS[draft.gender]
        local default_presentation = {
            unspecified = "androgynous",
            male = "masculine",
            female = "feminine",
            nonbinary = "androgynous",
        }
        draft.presentation = default_presentation[draft.gender]
    elseif selected == 5 then
        draft.presentation = cycle(PRESENTATIONS, draft.presentation, direction)
    end
end

local function confirmIdentitySelection(menu)
    local selected = menu._identity_selected
    local draft = menu._identity_draft

    if selected == 1 then
        beginTextEntry(menu, "name")
    elseif selected == 2 then
        if menu._identity_imported_name then
            draft.name = menu._identity_imported_name
            menu._identity_notice = "Deltarune Vessel name imported."
            Assets.stopAndPlaySound("ui_select")
        else
            Assets.stopAndPlaySound("ui_cant_select")
        end
    elseif selected == 3 then
        adjustIdentityValue(menu, 1)
        Assets.stopAndPlaySound("ui_select")
    elseif selected == 4 then
        beginTextEntry(menu, "pronouns")
    elseif selected == 5 then
        adjustIdentityValue(menu, 1)
        Assets.stopAndPlaySound("ui_select")
    elseif selected == 6 then
        saveIdentity(menu)
    elseif selected == 7 then
        leaveIdentity(menu)
    end
end

local function drawRows(menu, title, rows, selected, spacing)
    love.graphics.setFont(menu.font)
    Draw.setColor(PALETTE["world_text"])
    love.graphics.print(title, 188, -12)

    for index, row in ipairs(rows) do
        local y = 38 + ((index - 1) * spacing)
        if row.disabled then
            Draw.setColor(PALETTE["world_text"])
        elseif index == selected then
            Draw.setColor(PALETTE["world_text_hover"])
        else
            Draw.setColor(PALETTE["world_text"])
        end
        love.graphics.print(row[1], 88, y)
        if row[2] then
            love.graphics.print(row[2], 348, y)
        end
    end

    Draw.setColor(Game:getSoulColor())
    Draw.draw(menu.heart_sprite, 63, 48 + ((selected - 1) * spacing))
    Draw.setColor(1, 1, 1, 1)
end

function IdentityMenu.install()
    if DarkConfigMenu._vessel_identity_installed then return end
    DarkConfigMenu._vessel_identity_installed = true

    function DarkConfigMenu:openVesselIdentity(setup)
        openIdentity(self, setup)
    end

    local original_update = DarkConfigMenu.update
    DarkConfigMenu.update = function(menu)
        if menu.state == "MAIN" then
            if Input.pressed("up") or Input.pressed("down") then
                local direction = Input.pressed("up") and -1 or 1
                menu.currently_selected = MathUtils.clamp(menu.currently_selected + direction, 1, 8)
                Assets.stopAndPlaySound("ui_move")
                Object.update(menu)
                return
            elseif Input.pressed("confirm") then
                if menu.currently_selected == 6 then
                    openIdentity(menu, false)
                    Assets.stopAndPlaySound("ui_select")
                    return
                elseif menu.currently_selected == 7 then
                    menu.currently_selected = 6 -- preserve Kristal's Return to Title action
                elseif menu.currently_selected == 8 then
                    menu.currently_selected = 7 -- preserve Kristal's Back action
                end
            end
            return original_update(menu)
        elseif menu.state == "IDENTITY" then
            if menu._identity_namer then
                Object.update(menu)
                return
            end

            if Input.pressed("cancel") then
                leaveIdentity(menu)
                Object.update(menu)
                return
            elseif Input.pressed("up") then
                moveIdentitySelection(menu, -1)
            elseif Input.pressed("down") then
                moveIdentitySelection(menu, 1)
            elseif Input.pressed("left") or Input.pressed("right") then
                local direction = Input.pressed("left") and -1 or 1
                if menu._identity_selected == 3 or menu._identity_selected == 5 then
                    adjustIdentityValue(menu, direction)
                    Assets.stopAndPlaySound("ui_select")
                end
            elseif Input.pressed("confirm") then
                confirmIdentitySelection(menu)
                if menu._identity_namer then
                    return
                end
            end
            Object.update(menu)
            return
        end

        return original_update(menu)
    end

    local original_draw = DarkConfigMenu.draw
    DarkConfigMenu.draw = function(menu)
        if menu.state == "MAIN" then
            local rows = {
                {"Master Volume", MathUtils.round(Kristal.getVolume() * 100) .. "%"},
                {"Controls"},
                {"Simplify VFX", Kristal.Config["simplifyVFX"] and "ON" or "OFF"},
            }
            if Kristal.isForcedFullscreen() then
                rows[#rows + 1] = {"Auto-Run", Kristal.Config["autoRun"] and "ON" or "OFF"}
                rows[#rows + 1] = {"Border", Kristal.getBorderName()}
            else
                rows[#rows + 1] = {"Fullscreen", Kristal.Config["fullscreen"] and "ON" or "OFF"}
                rows[#rows + 1] = {"Auto-Run", Kristal.Config["autoRun"] and "ON" or "OFF"}
            end
            rows[#rows + 1] = {"Vessel Identity"}
            rows[#rows + 1] = {"Return to Title"}
            rows[#rows + 1] = {"Back"}
            drawRows(menu, "CONFIG", rows, menu.currently_selected, 29)
            Object.draw(menu)
            return
        elseif menu.state == "IDENTITY" then
            local draft = menu._identity_draft or Mod.vessel_identity.get()
            local import_value = menu._identity_imported_name or "NOT FOUND"
            if menu._identity_notice then import_value = "IMPORTED" end
            local rows = {
                {"Name", draft.name},
                {"Import Deltarune Vessel Name", import_value},
                {"Gender", draft.gender:upper()},
                {"Pronouns", draft.pronouns},
                {"Presentation", draft.presentation:upper()},
                {menu._identity_setup and "Continue" or "Save"},
                {menu._identity_setup and "Use Defaults" or "Back"},
            }
            drawRows(menu, menu._identity_setup and "VESSEL SETUP" or "VESSEL IDENTITY",
                rows, menu._identity_selected or 1, 31)

            if menu._identity_notice then
                love.graphics.setFont(Assets.getFont("main", 16))
                Draw.setColor(PALETTE["world_text"])
                love.graphics.print(menu._identity_notice, 88, 258)
            end
            Object.draw(menu)
            return
        end

        return original_draw(menu)
    end
end

return IdentityMenu
