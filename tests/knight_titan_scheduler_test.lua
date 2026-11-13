local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local state = CombatState.new()

assert(state.boss.hp == 260 and state.boss.phase == 1, "boss state must start at full health and phase one")
assert(state:canSpare() == false, "Knight + Titan must never be spareable")
assert(state:canBecomeTired() == false, "Knight + Titan must never become TIRED")

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

print("Knight + Titan attack scheduler tests passed.")
