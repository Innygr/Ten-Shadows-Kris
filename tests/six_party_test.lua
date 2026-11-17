local function read(path)
    local file = assert(io.open(path, "r"))
    local value = file:read("*a")
    file:close()
    return value
end

local manifest = read("mod.json")
local source = read("mod.lua")
local startup = read("scripts/ten_shadows/vessel_identity_startup.lua")
local vessel = read("scripts/data/party/vessel.lua")
local berdly = read("scripts/data/party/berdly.lua")

local expected = {"kris", "susie", "ralsei", "noelle", "berdly", "vessel"}
for _, id in ipairs(expected) do
    assert(manifest:find('"' .. id .. '"', 1, true), "mod.json is missing " .. id)
    assert(source:find('"' .. id .. '"', 1, true), "mod.lua roster is missing " .. id)
end

assert(source:find("installGameLoadHook(Mod, Game, PARTY_ROSTER)", 1, true),
    "Mod:init must install the centralized Game:load hook")
assert(startup:find("local original_game_load = game_class.load", 1, true),
    "the startup helper must wrap Game:load exactly once")
assert(startup:find("data.party[i] = id", 1, true),
    "existing saves must be migrated to the complete six-member roster")
assert(startup:find("mod._vessel_identity_game_load_hook", 1, true),
    "the Game:load wrapper must be guarded against repeated Mod:init calls")
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

assert(berdly:find('self:setActor("berdly")', 1, true),
    "Berdly must use his dedicated Dark World actor")
assert(not berdly:find("setLightActor", 1, true),
    "This project has no Light World actor state")

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

local formation_source = read("scripts/ten_shadows/battle_formation.lua")
local encounter_source = read("scripts/battle/encounters/knight_titan_preview.lua")
assert(source:find('local BattleFormation = modRequire("scripts/ten_shadows/battle_formation")', 1, true),
    "battle hooks must load the shared formation helper")
assert(source:find("BattleFormation.partyPosition(i, SCREEN_WIDTH, SCREEN_HEIGHT", 1, true),
    "fallback party battlers must receive individual formation slots")
assert(source:find("BattleFormation.partyPosition(index, SCREEN_WIDTH, SCREEN_HEIGHT", 1, true),
    "the final six-member formation must use the same position helper")
assert(not source:find("SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2", 1, true),
    "missing followers must not all spawn at one shared point")
assert(encounter_source:find('self:addEnemy("roaring_knight_titan")', 1, true)
    and encounter_source:find('self:addEnemy("roaring_knight")', 1, true),
    "bosses must retain their existing encounter-defined positions")
assert(not formation_source:find("enemyPositions", 1, true),
    "party formation helper must not alter enemy positions")
assert(formation_source:find("function Formation.partyPosition", 1, true),
    "the formation helper must expose party placement")

-- Exercise the actual formation helper across common viewport sizes.
-- Representative 32x32 actors must be separated and stay well inside the box.
for _, dimensions in ipairs({{640, 480}, {800, 600}, {1280, 720}}) do
    local width, height = dimensions[1], dimensions[2]
    local positions = {}
    for index = 1, 6 do
        local x, y = dofile("scripts/ten_shadows/battle_formation.lua").partyPosition(
            index, width, height, 32, 32, 0, 0
        )
        positions[index] = {x, y}
        assert(x > width * 0.10 and x < width * 0.62,
            "party member " .. index .. " must be spread across the center-left formation")
        assert(y > height * 0.22 and y < height * 0.78,
            "party member " .. index .. " must stay away from the top and bottom corners")
    end
    for i = 1, #positions do
        for j = i + 1, #positions do
            local dx = math.abs(positions[i][1] - positions[j][1])
            local dy = math.abs(positions[i][2] - positions[j][2])
            assert(dx >= 64 or dy >= 48,
                "party battlers must have enough separation to avoid sprite overlap")
        end
    end


end

local berdly_party = read("scripts/data/party/berdly.lua")
local berdly_actor = read("scripts/data/actors/berdly.lua")
assert(berdly_party:find('self:setActor("berdly")', 1, true), "Berdly must use his dedicated actor registry entry")
assert(berdly_actor:find('Class(Actor, "berdly")', 1, true), "Berdly actor must be registered independently from Kris")
assert(berdly_actor:find('Registry.getActor("kris")', 1, true), "Berdly fallback must preserve working animation definitions until dedicated frames exist")
