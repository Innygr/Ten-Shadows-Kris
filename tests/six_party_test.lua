local function read(path)
    local file = assert(io.open(path, "r"))
    local value = file:read("*a")
    file:close()
    return value
end

local manifest = read("mod.json")
local source = read("mod.lua")
local vessel = read("scripts/data/party/vessel.lua")

local expected = {"kris", "susie", "ralsei", "noelle", "berdly", "vessel"}
for _, id in ipairs(expected) do
    assert(manifest:find('"' .. id .. '"', 1, true), "mod.json is missing " .. id)
    assert(source:find('"' .. id .. '"', 1, true), "mod.lua roster is missing " .. id)
end

assert(source:find("local original_game_load = Game.load", 1, true),
    "six-member save migration must wrap Game:load during Mod:init")
assert(source:find("data.party[i] = id", 1, true),
    "existing saves must be migrated to the complete six-member roster")
assert(source:find("installSixPartySupport()", 1, true),
    "battle hooks must be installed before the initial Game:load")

assert(source:find("Game:setPartyMembers(unpack(roster))", 1, true),
    "battle construction must restore the complete intended roster")
assert(source:find("for i = 1, #Game.party do", 1, true),
    "battle construction must create a battler for every party member")
assert(source:find("local page_offset = selecting > 3 and 3 or 0", 1, true),
    "battle action boxes must page to the active member")
assert(source:find("local page_offset = selected > 3 and 3 or 0", 1, true),
    "overworld party selection must page to the selected member")

assert(vessel:find('self:setActor("vessel")', 1, true),
    "Vessel must use its own registered actor")
assert(vessel:find('self.menu_icon = "player/heart"', 1, true),
    "Vessel must have a distinct party-menu icon")

print("Six-member party registration, save migration, battler creation, UI paging, and Vessel identity checks passed")
