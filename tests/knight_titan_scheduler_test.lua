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

print("Knight + Titan attack scheduler tests passed.")
