local BossPhase = dofile("scripts/ten_shadows/boss_phase.lua")

local phase, message = BossPhase.advance(260, 1)
assert(phase == 1 and message == nil, "phase one must remain active above 175 HP")

phase, message = BossPhase.advance(175, phase)
assert(phase == 2 and message == BossPhase.TEXT[2], "175 HP must trigger phase two")

local same_phase
same_phase, message = BossPhase.advance(100, phase)
assert(same_phase == 2 and message == nil, "phase two must remain active above 78 HP")

phase, message = BossPhase.advance(78, same_phase)
assert(phase == 3 and message == BossPhase.TEXT[3], "78 HP must trigger phase three")

local unchanged
unchanged, message = BossPhase.advance(0, phase)
assert(unchanged == 3 and message == nil, "phase three must not advance again")

-- One hit may cross both thresholds; the boss must land directly in its
-- final phase and announce the final state rather than waiting for another hit.
local burst_phase, burst_message = BossPhase.advance(40, 1)
assert(burst_phase == 3 and burst_message == BossPhase.TEXT[3],
    "a single hit crossing both thresholds must advance directly to phase three")

local boundary_phase, boundary_message = BossPhase.advance(175, 1)
assert(boundary_phase == 2 and boundary_message == BossPhase.TEXT[2],
    "exactly reaching the first threshold must advance only to phase two")

assert(BossPhase.checkText(1):find("One shared health pool", 1, true), "phase one CHECK must explain shared HP")
assert(BossPhase.checkText(2):find("second phase", 1, true), "phase two CHECK must update")
assert(BossPhase.checkText(3):find("final phase", 1, true), "phase three CHECK must update")

print("Knight + Titan phase progression tests passed.")
