local saved, saves = nil, 0
Kristal = {
    loadData = function(key) assert(key == "vessel_identity"); return saved end,
    saveData = function(key, data) assert(key == "vessel_identity"); saved = data; saves = saves + 1 end,
}
local Identity = dofile("scripts/ten_shadows/vessel_identity.lua")
local defaults = Identity.load()
assert(defaults.name == "Vessel" and defaults.gender == "unspecified")
assert(defaults.pronouns == "they/them" and defaults.presentation == "androgynous")
local profile = Identity.save({name = "  Rowan  ", gender = "nonbinary", pronouns = "they/them", presentation = "androgynous", ignored = "x"})
assert(profile.name == "Rowan" and profile.gender == "nonbinary" and profile.ignored == nil and saves == 1)
Identity.update({name = "A longer-than-twelve-character-name", presentation = "feminine"})
assert(Identity.get().name == "A longer-tha" and Identity.get().presentation == "feminine")
assert(Identity.parseDeltaruneSave("PLAYER NAME\nVESSEL NAME\n0\n") == "PLAYER NAME")
assert(Identity.parseDeltaruneSave("\nempty\n") == nil)
local original_open, reads = io.open, {}
io.open = function(path, mode)
    assert(mode == "rb")
    reads[#reads + 1] = path
    if path:match("filech2_1$") then
        return {read = function() return "Imported Name\nVessel\n" end, close = function() end}
    end
    return nil
end
local name, path = Identity.findDeltaruneName({"/fake/DELTARUNE"})
io.open = original_open
assert(name == "Imported Name" and path == "/fake/DELTARUNE/filech2_1" and #reads > 0)
print("Vessel identity profile and DELTARUNE save-name import tests passed")
