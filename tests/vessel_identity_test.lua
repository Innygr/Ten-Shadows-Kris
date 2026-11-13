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
print("Vessel identity profile and DELTARUNE Vessel-name import tests passed")
