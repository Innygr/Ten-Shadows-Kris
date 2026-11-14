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


-- Joint activation also requires Kris; failure must not spend TP or reserve
-- either character's once-per-battle Domain.
local down_kris = CombatState.new()
down_kris.tp = 100
down_kris:getMember("kris").hp = 0
local kris_ok, kris_reason = down_kris:expandFusionDomain(false)
expect(kris_ok, false, "Kris must be standing to supply the shadow garden")
expect(type(kris_reason), "string", "failed activation explains the missing partner")
expect(down_kris.tp, 100, "failed joint activation does not spend TP")
expect(down_kris.fusion_domain.used, false, "failed joint activation does not consume fusion use")
expect(down_kris.player_domain.used, false, "failed joint activation does not consume ordinary domain use")

-- Invalid routing input is rejected without mutating the original spell or
-- incrementing the route counter.
local invalid_spell = {origin_x = 5, origin_y = 6, target_x = 7, target_y = 8}
local invalid_route, route_reason = state:routePartySpell(
    invalid_spell, {x = 1, y = 2}, {x = "not-a-number", y = 4}
)
expect(invalid_route, false, "portal routing rejects malformed coordinates")
expect(type(route_reason), "string", "invalid routing explains the required inputs")
expect(state.fusion_domain.portal_routes, 1, "invalid routing does not count as a successful route")
expect(invalid_spell.origin_x, 5, "invalid routing leaves the spell unchanged")

local bad_blast, blast_reason = state:createGraniteBlast(
    {x = 1, y = 2}, {x = 3, y = false}, 1
)
expect(bad_blast, false, "Granite Blast rejects malformed target coordinates")
expect(type(blast_reason), "string", "invalid Granite Blast explains its inputs")

-- The fusion Domain and ordinary Chimera Domain share one activation slot.
local mutually_exclusive = CombatState.new()
mutually_exclusive.tp = 100
expect(mutually_exclusive:expandChimeraDomain(true), true,
    "ordinary Chimera Domain can be activated first")
local fusion_after_chimera = mutually_exclusive:expandFusionDomain(true)
expect(fusion_after_chimera, false,
    "fusion Domain cannot overlap an already-active Chimera Domain")
expect(mutually_exclusive.fusion_domain.used, false,
    "rejected overlap does not consume the fusion Domain")

print("Kris + Vessel fusion Domain and V-ACT tests passed.")
