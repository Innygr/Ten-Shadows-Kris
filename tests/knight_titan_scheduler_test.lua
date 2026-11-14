local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local state = CombatState.new()

assert(state.boss.hp == 260 and state.boss.phase == 1, "boss state must start at full health and phase one")
assert(state:canSpare() == false, "Knight + Titan must never be spareable")
assert(state:canBecomeTired() == false, "Knight + Titan must never become TIRED")

-- A single damage event that crosses both thresholds must put the scheduler
-- directly into phase three, matching the encounter's phase controller.
local burst_state = CombatState.new()
local burst_damage, burst_changed = burst_state:damageBoss(220)
assert(burst_damage == 220 and burst_changed, "large damage must report a phase change")
assert(burst_state.boss.hp == 40 and burst_state.boss.phase == 3,
    "one hit below 78 HP must advance through both phases")
assert(burst_state.encounter.phase == 3 and burst_state.encounter.turns == 0,
    "phase-crossing damage must reset the scheduler in the final phase")

local boundary_state = CombatState.new()
local _, boundary_changed = boundary_state:damageBoss(85)
assert(boundary_changed and boundary_state.boss.phase == 2,
    "exactly reaching 175 HP must advance only to phase two")

-- Combined attacks become more frequent as the Roaring progresses.
for phase, cadence in pairs(CombatState.COMBO_CADENCE) do
    local cadence_state = CombatState.new()
    cadence_state.boss.phase = phase
    cadence_state.encounter.phase = phase
    for turn = 1, cadence do
        local selected = cadence_state:chooseEnemyAttack()
        local is_combo = selected and selected.id == "titan_knight_combo"
        if turn < cadence then
            assert(not is_combo, "combined attack arrived too early in phase " .. phase)
        else
            assert(is_combo, "combined attack cadence was not reached in phase " .. phase)
        end
    end
end

state.boss.hp = 175
state.boss.phase = 2
local attack = state:chooseEnemyAttack()
assert(attack and attack.id, "phase two must select a registered attack")

state.boss.hp = 78
state.boss.phase = 3
local phase_three_attack = state:chooseEnemyAttack()
assert(phase_three_attack and phase_three_attack.id, "phase three must select a registered attack")

local valid = {}
for _, entry in ipairs(CombatState.KNIGHT_ATTACKS) do valid[entry.id] = true end
assert(valid[attack.id], "phase two attack must belong to the shared Knight/Titan attack registry")
assert(valid[phase_three_attack.id], "phase three attack must belong to the shared Knight/Titan attack registry")

-- Phase three opens with one guaranteed Roaring signature attack on the
-- first Knight-led turn. The phase controller updates boss.phase directly,
-- so the scheduler must detect that transition as well as damageBoss().
local roaring_intro = CombatState.new()
roaring_intro.boss.hp = 78
roaring_intro.boss.phase = 3
local phase_three_titan = roaring_intro:chooseEnemyAttack()
assert(phase_three_titan and string.sub(phase_three_titan.id, 1, 6) == "titan_",
    "phase three must preserve the Titan's opening turn before the Knight's signature")
assert(roaring_intro.encounter.roaring_pending,
    "the phase-three signature must remain pending until a Knight-led slot")
local signature_attack = roaring_intro:chooseEnemyAttack()
assert(signature_attack and signature_attack.id == "black_flash",
    "the first Knight-led phase-three slot must guarantee The Roaring")
assert(not roaring_intro.encounter.roaring_pending,
    "The Roaring intro must only be guaranteed once")

-- A selected custom SOUL mode keeps its own attack pool. The pending Roaring
-- intro survives until the player returns to the ordinary red-SOUL library.
local mode_intro = CombatState.new()
mode_intro.boss.hp = 78
mode_intro.boss.phase = 3
assert(mode_intro:setSoulMode("blue"), "blue SOUL must be selectable before the phase-three intro")
local blue_titan = mode_intro:chooseEnemyAttack("blue")
local blue_knight = mode_intro:chooseEnemyAttack("blue")
assert(blue_titan and blue_knight and blue_knight.soul_mode == "blue",
    "the active blue SOUL must retain its own Titan and Knight attacks")
assert(blue_knight.id ~= "black_flash" and mode_intro.encounter.roaring_pending,
    "the Roaring intro must not override a custom SOUL-mode attack pool")
assert(mode_intro:setSoulMode("red"), "red SOUL must restore the standard attack library")
mode_intro:chooseEnemyAttack()
local restored_signature = mode_intro:chooseEnemyAttack()
assert(restored_signature and restored_signature.id == "black_flash",
    "the pending Roaring intro must trigger when the standard attack pool returns")

-- Disrupting a Knight-led action transfers that action slot to the Titan.
local disrupted_state = CombatState.new()
disrupted_state.encounter.last_source = "titan"
disrupted_state.encounter.turns = 1
disrupted_state:disruptKnight()
local diverted, frozen, domain, was_disrupted = disrupted_state:chooseEnemyAttack()
assert(not frozen and was_disrupted, "a pending Knight disruption must be consumed on a Knight-led slot")
assert(diverted and (diverted.source == "titan" or string.sub(diverted.id, 1, 6) == "titan_"),
    "the Titan must attack when the Knight is disrupted")
assert(disrupted_state.knight_disrupted == 0, "the Knight disruption must be consumed exactly once")

-- A frozen Knight cannot consume its pending disruption; it carries into the
-- next Knight-led slot after the forced Titan-only frozen turn.
local frozen_state = CombatState.new()
frozen_state.boss.frozen_turns = 1
frozen_state:disruptKnight()
local frozen_attack, was_frozen = frozen_state:chooseEnemyAttack()
assert(was_frozen and frozen_attack, "the Titan still attacks while the Knight is frozen")
assert(frozen_state.knight_disrupted == 1, "disruption must remain pending while the Knight is frozen")

-- Kris's domain lasts three turns and asks only its first Wave to play the
-- opening animation. The active field remains available to the next Waves.
local player_domain_state = CombatState.new()
assert(player_domain_state:expandChimeraDomain(true),
    "Kris must be able to activate Chimera Shadow Garden")
assert(player_domain_state.player_domain.active and player_domain_state.player_domain.turns == 3,
    "Chimera Shadow Garden must start with three turns")
assert(player_domain_state.player_domain.visual_pending,
    "the first defending Wave must receive an opening animation")
player_domain_state.player_domain.visual_pending = false
player_domain_state:tickEnemyTurnEffects()
assert(player_domain_state.player_domain.active and player_domain_state.player_domain.turns == 2,
    "Kris's domain must persist through the first enemy turn")
assert(not player_domain_state.player_domain.visual_pending,
    "the opening animation must not replay on later turns")
player_domain_state:tickEnemyTurnEffects()
player_domain_state:tickEnemyTurnEffects()
assert(not player_domain_state.player_domain.active and not player_domain_state.player_domain.visual_pending,
    "Kris's domain and opening animation flag must clear after three enemy turns")

-- The Knight domain lasts exactly three complete enemy turns.
local domain_state = CombatState.new()
domain_state.boss.phase = 3
assert(domain_state:startKnightDomain(), "phase three must allow the Knight domain to start")
domain_state:tickEnemyTurnEffects()
assert(domain_state.knight_domain.active and domain_state.knight_domain.turns == 2,
    "domain must persist for two turns after its first tick")
domain_state:tickEnemyTurnEffects()
assert(domain_state.knight_domain.active and domain_state.knight_domain.turns == 1,
    "domain must persist for its final turn")
domain_state:tickEnemyTurnEffects()
assert(not domain_state.knight_domain.active and domain_state.knight_domain.turns == 0,
    "domain must expire after three enemy turns")

print("Knight + Titan attack scheduler tests passed.")
