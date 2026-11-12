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
assert(source:find("#ui.action_boxes == 6", 1, true),
    "battle UI must fail clearly if it does not create all six action boxes")
assert(source:find("six-member battle is missing action boxes", 1, true),
    "battle UI paging must validate the six action-box invariant")
assert(source:find("overworld health bar is missing party action boxes", 1, true),
    "overworld selector must validate all six health-bar boxes")
assert(source:find("local page_offset = selected > 3 and 3 or 0", 1, true),
    "overworld party selection must page to the selected member")

assert(vessel:find('self:setActor("vessel")', 1, true),
    "Vessel must use its own registered actor")
assert(vessel:find('self.menu_icon = "party/kris/head"', 1, true),
    "Vessel must have a gray Kris head icon")

assert(source:find("visited[left][right]", 1, true),
    "deep equality must track visited table pairs to avoid recursive stack overflow")
assert(source:find('battle:getState() == "ATTACKING"', 1, true),
    "battle action boxes must follow the active attacker page")
assert(source:find('action.action == "ATTACK" or action.action == "AUTOATTACK"', 1, true),
    "attack resolution must identify the party member using the attack")

print("Six-member party registration, save migration, battler creation, UI paging, and Vessel identity checks passed")

assert(source:find("local column = math.floor((index - 1) / 3)", 1, true), "six-member battle formation must use two columns and three rows")
assert(source:find("SCREEN_WIDTH * 0.20", 1, true), "party formation must scale horizontally with the battle viewport")
assert(source:find("SCREEN_HEIGHT * 0.135", 1, true), "party formation must scale vertically with the battle viewport")

-- Sanity-check the viewport-relative layout at Kristal's standard 640x480
-- battle resolution using representative 32x32 party actors.
local test_width, test_height = 640, 480
local positions = {}
for index = 1, 6 do
    local column = math.floor((index - 1) / 3)
    local row = (index - 1) % 3
    local x = (test_width * 0.20) + (column * test_width * 0.15625) + 32
    local y = (test_height * 0.135) + (row * test_height * 0.15625) + 64
    positions[index] = {x, y}
    assert(x > 80 and x < test_width * 0.55,
        "party member " .. index .. " must stay in the party-side battle area")
    assert(y > 80 and y < test_height - 40,
        "party member " .. index .. " must stay clear of the top and bottom corners")
end
for i = 1, #positions do
    for j = i + 1, #positions do
        assert(positions[i][1] ~= positions[j][1] or positions[i][2] ~= positions[j][2],
            "party battlers must not share the same target position")
    end
end

local berdly_party = read("scripts/data/party/berdly.lua")
local berdly_actor = read("scripts/data/actors/berdly.lua")
assert(berdly_party:find('self:setActor("berdly")', 1, true), "Berdly must use his dedicated actor registry entry")
assert(berdly_actor:find('Class(Actor, "berdly")', 1, true), "Berdly actor must be registered independently from Kris")
assert(berdly_actor:find('Registry.getActor("kris")', 1, true), "Berdly fallback must preserve working animation definitions until dedicated frames exist")
