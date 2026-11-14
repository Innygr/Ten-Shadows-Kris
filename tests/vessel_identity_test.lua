local saved, saves = nil, 0
Kristal = {
    loadData = function(key) assert(key == "vessel_identity"); return saved end,
    saveData = function(key, data) assert(key == "vessel_identity"); saved = data; saves = saves + 1 end,
}
local Identity = dofile("scripts/ten_shadows/vessel_identity.lua")
local defaults = Identity.load()
assert(defaults.name == "Vessel" and defaults.gender == "unspecified")
assert(defaults.pronouns == "they/them" and defaults.presentation == "androgynous")
assert(not Identity.hasSavedProfile(), "A new install must be recognized as an unset identity")
local profile = Identity.save({name = "  Rowan  ", gender = "nonbinary", pronouns = "they/them", presentation = "androgynous", ignored = "x"})
assert(profile.name == "Rowan" and profile.gender == "nonbinary" and profile.ignored == nil and saves == 1)
assert(Identity.hasSavedProfile(), "Saving an identity must mark the profile as existing")
Identity.update({name = "A longer-than-twelve-character-name", presentation = "feminine"})
assert(Identity.get().name == "A longer-tha" and Identity.get().presentation == "feminine")
local pronouns = Identity.getPronouns()
assert(pronouns.subject == "they" and pronouns.object == "them"
    and pronouns.determiner == "their" and pronouns.possessive == "theirs"
    and pronouns.reflexive == "themself", "They/them forms should be resolved consistently")
Identity.update({pronouns = "xe/xem"})
pronouns = Identity.getPronouns()
assert(pronouns.subject == "xe" and pronouns.object == "xem"
    and pronouns.determiner == "xyr" and pronouns.possessive == "xyrs"
    and pronouns.reflexive == "xemself", "Xe/xem forms should be resolved consistently")
Identity.update({pronouns = "it/its"})
pronouns = Identity.getPronouns()
assert(pronouns.subject == "it" and pronouns.object == "it"
    and pronouns.determiner == "its" and pronouns.possessive == "its"
    and pronouns.reflexive == "itself", "It/its forms should be resolved consistently")
Identity.update({name = "Rowan", pronouns = "she/her"})
assert(Identity.format("{vessel_name} said {vessel_subject} would bring {vessel_determiner} own supplies, and {vessel_reflexive} did.") ==
    "Rowan said she would bring her own supplies, and herself did.",
    "Identity placeholders should resolve to the saved Vessel identity")

assert(Identity.parseDeltaruneSave("CREATOR NAME\nVESSEL NAME\n0\n") == "VESSEL NAME",
    "Deltarune import must use the Vessel name on line 2, not the creator name")
assert(Identity.parseDeltaruneSave("CREATOR ONLY\n") == nil)
assert(Identity.parseDeltaruneSave("\nempty\n") == "empty")
local original_open, reads = io.open, {}
io.open = function(path, mode)
    assert(mode == "rb")
    reads[#reads + 1] = path
    if path:match("filech2_9$") then
        return {read = function() return "Creator\nNew Vessel\n0\n" end, close = function() end}
    end
    return nil
end
local name, path = Identity.findDeltaruneName({"/fake/DELTARUNE"})
io.open = original_open
assert(name == "New Vessel" and path == "/fake/DELTARUNE/filech2_9" and #reads > 0)

-- Native Linux ports may place saves in the XDG config directory.
local original_getenv = os.getenv
local searched = {}
os.getenv = function(key)
    if key == "HOME" then return "/home/test-user" end
    return nil
end
io.open = function(path, mode)
    assert(mode == "rb")
    searched[#searched + 1] = path
    return nil
end
Identity.findDeltaruneName()
os.getenv = original_getenv
io.open = original_open
local found_native_path = false
for _, searched_path in ipairs(searched) do
    if searched_path == "/home/test-user/.config/DELTARUNE/filech5_9" then
        found_native_path = true
        break
    end
end
assert(found_native_path, "Native Linux XDG Deltarune save path must be searched")
print("Vessel identity profile and DELTARUNE Vessel-name import tests passed")
