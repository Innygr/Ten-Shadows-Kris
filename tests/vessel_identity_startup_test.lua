local Startup = dofile("scripts/ten_shadows/vessel_identity_startup.lua")
local starts = {}
local game = {
    encounter = function(self, encounter, transition)
        starts[#starts + 1] = {encounter = encounter, transition = transition}
    end,
}

local mod = {
    info = {encounter = "knight_titan_preview"},
    vessel_identity = {
        hasSavedProfile = function() return false end,
    },
}
local deferred = Startup.deferEncounter(mod, true)
assert(deferred == "knight_titan_preview")
assert(mod.info.encounter == nil, "Default encounter must be suppressed during identity setup")
assert(mod._pending_first_run_encounter == deferred)
Startup.restoreEncounter(mod, deferred)
assert(mod.info.encounter == "knight_titan_preview", "Manifest options must be restored after Game:load")
assert(Startup.startPendingEncounter(mod, game))
assert(#starts == 1 and starts[1].encounter == "knight_titan_preview" and starts[1].transition == false)
assert(mod._pending_first_run_encounter == nil)
assert(not Startup.startPendingEncounter(mod, game), "The deferred encounter must only start once")

-- First-run setup must open CONFIG and then the installed Vessel Identity editor.
local identity_opened = false
local config_menu = {
    buttons = {{}, {}, {}, {}},
    onButtonSelect = function(self, index)
        assert(index == 4, "Startup must choose the CONFIG button")
        self.box = {
            openVesselIdentity = function(_, setup)
                assert(setup == true, "Startup must request first-run setup mode")
                identity_opened = true
            end,
        }
    end,
}
local setup_world = {
    openMenu = function()
        return config_menu
    end,
}
assert(Startup.openIdentitySetup(setup_world))
assert(identity_opened, "First-run setup must open the Vessel Identity editor")

local broken_world = {openMenu = function() return {buttons = {}} end}
assert(not Startup.openIdentitySetup(broken_world),
    "A missing CONFIG menu API must be reported instead of silently skipping setup")

-- Returning players keep Kristal's normal new-file preview behavior.
local returning = {
    info = {encounter = "knight_titan_preview"},
    vessel_identity = {hasSavedProfile = function() return true end},
}
assert(Startup.deferEncounter(returning, true) == nil)
assert(returning.info.encounter == "knight_titan_preview")

-- Loading an existing save never defers the default encounter.
assert(Startup.deferEncounter(mod, false) == nil)
print("Vessel first-run encounter ordering tests passed")
