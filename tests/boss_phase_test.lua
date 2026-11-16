local BossPhase = dofile("scripts/ten_shadows/boss_phase.lua")

local phase, message = BossPhase.advance(21000, 1)
assert(phase == 1 and message == nil, "phase one must remain active above 14000 HP")

phase, message = BossPhase.advance(14000, phase)
assert(phase == 2 and message == BossPhase.TEXT[2], "14000 HP must trigger phase two")

local same_phase
same_phase, message = BossPhase.advance(10000, phase)
assert(same_phase == 2 and message == nil, "phase two must remain active above 7000 HP")

phase, message = BossPhase.advance(7000, same_phase)
assert(phase == 3 and message == BossPhase.TEXT[3], "7000 HP must trigger phase three")

local unchanged
unchanged, message = BossPhase.advance(0, phase)
assert(unchanged == 3 and message == nil, "phase three must not advance again")

-- One hit may cross both thresholds; the boss must land directly in its
-- final phase and announce the final state rather than waiting for another hit.
local burst_phase, burst_message = BossPhase.advance(6000, 1)
assert(burst_phase == 3 and burst_message == BossPhase.TEXT[3],
    "a single hit crossing both thresholds must advance directly to phase three")

local boundary_phase, boundary_message = BossPhase.advance(14000, 1)
assert(boundary_phase == 2 and boundary_message == BossPhase.TEXT[2],
    "exactly reaching the first threshold must advance only to phase two")

local function checkContains(phase_number, health, needle, label)
    local actual = table.concat(BossPhase.checkText(phase_number, health, 21000), "\\n")
    assert(actual:find(needle, 1, true), label)
end
checkContains(1, 21000, "21,000 / 21,000", "phase one CHECK must show full Titan HP")
checkContains(1, 12345, "12,345 / 21,000", "phase one CHECK must show current Titan HP")
checkContains(2, 14000, "14,000 / 21,000", "phase two CHECK must show current Titan HP")
checkContains(2, 14000, "second phase", "phase two CHECK must update")
checkContains(3, 0, "0 / 21,000", "phase three CHECK must show defeated Titan HP")
checkContains(3, 0, "final phase", "phase three CHECK must update")

print("Knight + Titan phase progression tests passed.")
