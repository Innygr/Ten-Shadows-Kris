local Startup = {}

function Startup.deferEncounter(mod, is_new_file)
    if not is_new_file or type(mod) ~= "table" or type(mod.info) ~= "table" then
        return nil
    end
    if not mod.vessel_identity or mod.vessel_identity.hasSavedProfile() then
        return nil
    end

    local encounter = mod.info.encounter
    if encounter == nil then
        return nil
    end

    mod._pending_first_run_encounter = encounter
    mod.info.encounter = nil
    return encounter
end

function Startup.restoreEncounter(mod, encounter)
    if encounter ~= nil and mod and mod.info then
        mod.info.encounter = encounter
    end
end

function Startup.startPendingEncounter(mod, game)
    local encounter = mod and mod._pending_first_run_encounter
    if not encounter then return false end

    mod._pending_first_run_encounter = nil
    if game and type(game.encounter) == "function" then
        game:encounter(encounter, false)
        return true
    end
    return false
end

return Startup
