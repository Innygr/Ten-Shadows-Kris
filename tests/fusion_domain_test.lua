local CombatState = dofile("scripts/ten_shadows/combat_state.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local state = CombatState.new()
expect(state:expandFusionDomain(false), false,
    "fusion Domain must not start when the party lacks 60 TP")
expect(state.fusion_domain.used, false, "failed activation must not consume the Domain")
expect(state.player_domain.used, false, "failed activation must not consume Chimera")

state.tp = 100
expect(state:expandFusionDomain(false), true, "Kris and Vessel can create the fusion Domain")
expect(state.tp, 40, "fusion Domain costs 60 TP")
expect(state.fusion_domain.active, true, "fusion Domain barrier is active")
expect(state.player_domain.active, true, "Kris's shadow garden is active")
expect(state.fusion_domain.turns, 3, "fusion Domain lasts three enemy turns")
expect(state.player_domain.turns, 3, "shadow garden shares the Domain duration")

local spell = {
    id = "ice_wave",
    origin_x = 12,
    origin_y = 20,
    target_x = 250,
    target_y = 90,
    damage = 30,
}
local routed = state:routePartySpell(
    spell,
    {x = 30, y = 40},
    {x = 210, y = 75}
)
expect(type(routed), "table", "spell route returns a copied spell descriptor")
expect(routed.origin_x, 210, "spell emerges from the selected exit portal")
expect(routed.origin_y, 75, "spell uses the exit portal's vertical coordinate")
expect(routed.target_x, 250, "spell keeps its original target x")
expect(routed.target_y, 90, "spell keeps its original target y")
expect(routed.redirected_by_shadow_portal, true, "spell is marked as portal-routed")
expect(routed.shadow_portal.entry.x, 30, "entry portal is retained")
expect(routed.shadow_portal.exit.x, 210, "exit portal is retained")
expect(spell.origin_x, 12, "routing does not mutate the original spell")
expect(state.fusion_domain.portal_routes, 1, "portal routing is counted")

local blast = state:createGraniteBlast(
    {x = 12, y = 18},
    {x = 270, y = 110},
    1
)
expect(blast.kind, "granite_blast", "Vessel creates a Granite Blast descriptor")
expect(blast.source, "vessel", "Granite Blast belongs to Vessel")
expect(blast.origin_x, 12, "Granite Blast can originate at a chosen Domain position")
expect(blast.target_x, 270, "Granite Blast keeps its selected target")
expect(blast.output, 1, "100% output is represented as full charge")
expect(blast.redirected_by_shadow_portal, true, "Granite Blast uses the shadow portal network")

local partial = state:createGraniteBlast({x = 0, y = 0}, {x = 1, y = 1}, 2)
expect(partial.output, 1, "Granite Blast output is clamped to 100%")
local low = state:createGraniteBlast({x = 0, y = 0}, {x = 1, y = 1}, -1)
expect(low.output, 0, "Granite Blast output cannot be negative")

for _ = 1, 3 do state:tickEnemyTurnEffects() end
expect(state.fusion_domain.active, false, "fusion Domain expires after three enemy turns")
expect(state.player_domain.active, false, "shadow garden expires with the fusion Domain")
expect(state:expandFusionDomain(true), false, "fusion Domain is once per battle")

local down_vessel = CombatState.new()
down_vessel:getMember("vessel").hp = 0
expect(down_vessel:expandFusionDomain(true), false,
    "Vessel must be standing to maintain the barrier")
expect(down_vessel.player_domain.used, false,
    "failed joint activation must leave the ordinary domain available")

local ordinary = CombatState.new()
ordinary.tp = 100
expect(ordinary:expandChimeraDomain(false), true,
    "Kris can still use the ordinary domain without the fusion")
expect(ordinary.fusion_domain.active, false,
    "ordinary Chimera Shadow Garden does not activate Vessel's barrier")

local inactive = CombatState.new()
local denied = inactive:routePartySpell(spell, {x = 0, y = 0}, {x = 1, y = 1})
expect(denied, false, "shadow portal routing is unavailable outside the fusion Domain")
local denied_blast = inactive:createGraniteBlast({x = 0, y = 0}, {x = 1, y = 1}, 1)
expect(denied_blast, false, "free-position Granite Blast requires the fusion Domain")

local menu_file = assert(io.open("mod.lua", "r"))
local menu_source = menu_file:read("*a")
menu_file:close()
assert(menu_source:find('{"V%-ACT"', 1) or menu_source:find('{"V%-ACT"', 1, true)
    or menu_source:find('{"V-ACT"', 1, true), "Vessel must have a dedicated V-ACT submenu")
assert(menu_source:find('"FUSION DOMAIN"', 1, true),
    "Kris's ACT menu must expose the fusion Domain when Vessel is available")

local enemy_file = assert(io.open("scripts/battle/enemies/roaring_knight_titan.lua", "r"))
local enemy_source = enemy_file:read("*a")
enemy_file:close()
assert(enemy_source:find('name == "FUSION DOMAIN"', 1, true),
    "the enemy ACT handler must activate the fusion Domain")
assert(enemy_source:find('name == "GRANITE BLAST"', 1, true),
    "the enemy ACT handler must resolve Granite Blast")

print("Kris + Vessel fusion Domain and V-ACT tests passed.")
