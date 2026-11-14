local saved = {name = "Vessel", gender = "unspecified", pronouns = "they/them", presentation = "androgynous"}
local saves = 0
local actor = {}
local member = {actor = actor}
local key_pressed
local child_added

function Class() return {} end
DarkConfigMenu = {
    update = function() end,
    draw = function() end,
}
Object = {
    update = function() end,
    draw = function() end,
}
Input = {
    pressed = function(key) return key_pressed == key end,
}
MathUtils = {
    clamp = function(value, minimum, maximum)
        return math.max(minimum, math.min(maximum, value))
    end,
}
Assets = {
    stopAndPlaySound = function() end,
}
PALETTE = {world_text = {1, 1, 1}, world_text_hover = {1, 1, 0}}
Draw = {setColor = function() end, draw = function() end}
love = {graphics = {
    setFont = function() end,
    print = function() end,
}}
Game = {
    getPartyMember = function(_, id)
        assert(id == "vessel")
        return member
    end,
    world = {closeMenu = function() end},
    getSoulColor = function() return 1, 0, 0 end,
}
Registry = {getActor = function()
    error("Identity editor must update the party member's live actor instance")
end}
Mod = {
    vessel_identity_startup = {
        startPendingEncounter = function() return false end,
    },
    vessel_identity = {
        get = function()
            local copy = {}
            for k, v in pairs(saved) do copy[k] = v end
            return copy
        end,
        save = function(data)
            saved = {
                name = data.name,
                gender = data.gender,
                pronouns = data.pronouns,
                presentation = data.presentation,
            }
            saves = saves + 1
            return saved
        end,
        findDeltaruneName = function()
            return "Imported", "/fake/filech2_9"
        end,
    },
}
function FileNamer(options)
    return {
        options = options,
        remove = function(self) self.removed = true end,
    }
end

local IdentityMenu = dofile("scripts/ten_shadows/vessel_identity_menu.lua")
IdentityMenu.install()

local menu = setmetatable({
    state = "MAIN",
    currently_selected = 6,
    font = {},
    heart_sprite = {},
    addChild = function(self, child) child_added = child end,
}, {__index = DarkConfigMenu})

menu:openVesselIdentity(false)
assert(menu.state == "IDENTITY" and menu._identity_selected == 1)
assert(menu._identity_imported_name == "Imported")

local function press(key)
    key_pressed = key
    menu:update()
    key_pressed = nil
end

-- Import is explicit: opening the menu detects a name but does not apply it.
assert(menu._identity_draft.name == "Vessel")
menu._identity_selected = 2
press("confirm")
assert(menu._identity_draft.name == "Imported", "Import row should copy the detected Vessel name")

-- Gender selection updates the default pronoun set.
menu._identity_selected = 3
press("right")
assert(menu._identity_draft.gender == "male" and menu._identity_draft.pronouns == "he/him"
    and menu._identity_draft.presentation == "masculine")

-- Custom pronouns are accepted through Kristal's native FileNamer control.
menu._identity_selected = 4
press("confirm")
assert(menu._identity_namer and child_added == menu._identity_namer)
menu._identity_namer.options.on_confirm("xe/xem")
assert(menu._identity_draft.pronouns == "xe/xem" and menu._identity_namer == nil)

-- Visual presentation is a separate editable setting.
menu._identity_selected = 5
press("right")
assert(menu._identity_draft.presentation == "feminine",
    "Manual presentation selection should remain independent after gender defaults are applied")

-- Saving persists and immediately updates the party member and actor.
menu._identity_selected = 6
press("confirm")
assert(saves == 1 and saved.name == "Imported")
assert(member.name == "Imported" and actor.name == "Imported")
assert(member.gender == "male" and actor.gender == "male")
assert(member.pronouns == "xe/xem" and actor.pronouns == "xe/xem")
assert(member.presentation == "feminine" and actor.presentation == "feminine")
assert(menu.state == "MAIN" and menu.currently_selected == 6)

-- First-run setup can be skipped, but doing so writes a profile and closes it.
menu:openVesselIdentity(true)
menu._identity_selected = 7
press("confirm")
assert(saves == 2 and saved.name == "Imported")
print("Vessel identity menu navigation, import, text entry, save, and first-run flow passed")
