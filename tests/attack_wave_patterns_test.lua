local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local Patterns = dofile("scripts/ten_shadows/attack_wave_patterns.lua")

local arena = {left = 250, right = 390, top = 150, bottom = 292}
local target = {x = 320, y = 230}
local families = {
    radial = true, wall = true, aimed = true, crossfire = true,
    falling = true, sweep = true, twin_slash = true, titan_hands = true,
}

local function validate(attack, phase)
    local shots, family = Patterns.build(attack, phase, 2, arena, target, false)
    assert(families[family], "unknown attack family: " .. tostring(family))
    assert(#shots > 0, "attack produced no projectiles: " .. tostring(attack.id))
    for _, shot in ipairs(shots) do
        assert(type(shot.x) == "number" and type(shot.y) == "number", "shot coordinates must be numeric")
        assert(type(shot.direction) == "number", "shot direction must be numeric")
        assert(type(shot.speed) == "number" and shot.speed > 0, "shot speed must be positive")
        assert(shot.kind == "knight" or shot.kind == "titan" or shot.kind == "combo", "shot source must be styled")

        if family == "wall" then
            assert(shot.warning and shot.warning.kind == "lane", "wall shots need lane telegraphs")
        elseif family == "aimed" then
            assert(shot.warning and shot.warning.kind == "target", "aimed shots need trajectory/target telegraphs")
        elseif family == "falling" then
            assert(shot.warning and shot.warning.kind == "falling", "falling shots need vertical telegraphs")
        elseif family == "titan_hands" then
            assert(shot.warning and shot.warning.kind == "lane", "Titan hand shots need horizontal lane tells")
            assert(shot.mechanic and shot.mechanic.kind == "titan_hand",
                "Titan hand shots need their dedicated visual/collision marker")
        end

        if shot.warning then
            assert(type(shot.warning.duration) == "number" and shot.warning.duration > 0,
                "telegraph duration must be positive")
            assert(type(shot.warning.length) == "number" and shot.warning.length > 0,
                "telegraph length must be positive")
            assert(shot.warning.duration <= 0.6, "telegraphs must remain readable without stalling the attack")
        end
    end
end

for _, attack in ipairs(CombatState.KNIGHT_ATTACKS) do
    validate(attack, attack.phases[1])
end

for _, sets in pairs(CombatState.SOUL_MODE_ATTACKS) do
    for _, group in ipairs({sets.titan, sets.knight, sets.combo}) do
        for _, attack in ipairs(group) do
            validate(attack, attack.phases[1])
        end
    end
end

local wall_shots, wall_family = Patterns.build({id = "box_splitter"}, 1, 1, arena, target, false)
assert(wall_family == "wall" and #wall_shots == 6, "wall patterns must leave one of seven lanes open")
assert(wall_shots[1].warning.kind == "lane", "wall lanes must be visibly telegraphed")

local second_wall_shots = Patterns.build({id = "box_splitter"}, 1, 2, arena, target, false)
local function hasLane(shots, y)
    for _, shot in ipairs(shots) do
        if math.abs(shot.y - y) < 0.001 then return true end
    end
    return false
end
local changed_gap = false
for lane = 1, 7 do
    local y = arena.top + (arena.bottom - arena.top) * (lane - 1) / 6
    if hasLane(wall_shots, y) ~= hasLane(second_wall_shots, y) then
        changed_gap = true
        break
    end
end
assert(changed_gap, "wall safe lane must move between volleys")

local aimed_shots, aimed_family = Patterns.build(
    {id = "test_aimed", pattern = "aimed-projectile-volley", source = "knight"},
    2, 1, arena, target, false
)
assert(aimed_family == "aimed", "aimed pattern should retain its own family")
assert(aimed_shots[1].warning.kind == "target", "aimed shot should mark the predicted target trajectory")

local falling_shots, falling_family = Patterns.build({id = "titan_swarm"}, 2, 1, arena, target, false)
assert(falling_family == "falling", "Titan swarm should use the falling family")
assert(falling_shots[1].warning.kind == "falling", "falling shot should telegraph its descent")

-- Titan's Hands sweeps two offset four-lane bands from opposite sides.
for phase = 1, 3 do
    local hand_shots, hand_family = Patterns.build(
        {id = "titan_hands"},
        phase,
        1,
        arena,
        target,
        false
    )
    assert(hand_family == "titan_hands", "Titan's Hands must use its dedicated family")
    assert(#hand_shots == 6, "Each of the two hands must leave one gap among four lanes")
    local left_count, right_count = 0, 0
    local left_gap, right_gap = {}, {}
    for _, shot in ipairs(hand_shots) do
        assert(shot.kind == "titan", "Titan hands must retain Titan projectile styling")
        assert(shot.warning.duration <= 0.6, "Titan hand tells must remain readable")
        if shot.mechanic.side == "left" then
            left_count = left_count + 1
            assert(shot.x < arena.left and shot.direction == 0,
                "Left hand must sweep inward from the left edge")
            left_gap[shot.mechanic.finger] = false
        else
            right_count = right_count + 1
            assert(shot.x > arena.right and math.abs(shot.direction - math.pi) < 0.001,
                "Right hand must sweep inward from the right edge")
            right_gap[shot.mechanic.finger] = false
        end
    end
    assert(left_count == 3 and right_count == 3,
        "Both hands must fire three knuckles while preserving an opening")
end

local hands_first = Patterns.build({id = "titan_hands"}, 2, 1, arena, target, false)
local hands_second = Patterns.build({id = "titan_hands"}, 2, 2, arena, target, false)
local function missingFinger(shots, side)
    local present = {}
    for _, shot in ipairs(shots) do
        if shot.mechanic.side == side then present[shot.mechanic.finger] = true end
    end
    for finger = 1, 4 do
        if not present[finger] then return finger end
    end
end
assert(missingFinger(hands_first, "left") ~= missingFinger(hands_second, "left"),
    "Left-hand safe gap must move between volleys")
assert(missingFinger(hands_first, "right") ~= missingFinger(hands_second, "right"),
    "Right-hand safe gap must move between volleys")

local execution_shots, execution_family = Patterns.build(
    {id = "cyan_knights_execution", source = "knight", pattern = "cyan-parry-window"},
    2, 3, arena, target, false
)
assert(execution_family == "aimed", "Knight's Execution should remain an aimed slash pattern")
assert(#execution_shots == 1, "Knight's Execution should create one dedicated slash on its marked volley")
assert(execution_shots[1].mechanic and execution_shots[1].mechanic.kind == "execution_slash",
    "Knight's Execution projectile must carry the parry marker")
assert(execution_shots[1].warning and execution_shots[1].warning.kind == "target",
    "Knight's Execution slash must telegraph its path before launching")

-- Twin Slashes is a distinct mirrored attack, not the generic side-sweep fallback.
for phase = 1, 3 do
    local twin_shots, twin_family = Patterns.build(
        {id = "twin_slashes"},
        phase,
        1,
        arena,
        target,
        false
    )
    assert(twin_family == "twin_slash", "Twin Slashes must use its dedicated pattern family")
    assert(#twin_shots == 2, "Twin Slashes must create exactly two crossing blades")
    assert(twin_shots[1].kind == "knight" and twin_shots[2].kind == "knight",
        "Both Twin Slashes blades must retain Knight styling")
    assert(twin_shots[1].warning.kind == "target" and twin_shots[2].warning.kind == "target",
        "Both blades must telegraph their full trajectories")
    assert(twin_shots[1].mechanic.kind == "twin_slash"
        and twin_shots[2].mechanic.kind == "twin_slash",
        "Both blades must be marked as the dedicated Twin Slashes mechanic")
    assert(twin_shots[1].x < arena.left and twin_shots[2].x > arena.right,
        "Twin Slashes must enter from opposite sides")
    assert(math.sin(twin_shots[1].direction) > 0
        and math.sin(twin_shots[2].direction) < 0,
        "The mirrored blades must angle toward each other")
    assert(twin_shots[1].warning.duration <= 0.6,
        "Phase scaling must keep the tell readable")
end

local twin_first = Patterns.build({id = "twin_slashes"}, 2, 1, arena, target, false)
local twin_second = Patterns.build({id = "twin_slashes"}, 2, 2, arena, target, false)
assert(twin_first[1].warning.length ~= twin_second[1].warning.length
    or twin_first[1].direction ~= twin_second[1].direction,
    "Twin Slashes crossing point must shift between volleys")

local base_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, false)
local domain_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, true)
assert(#domain_shots == #base_shots + 2, "Knight domain must layer two extra falling blades")
assert(domain_shots[#domain_shots].warning.kind == "falling",
    "Knight domain blades must telegraph their diagonal travel")

print("Knight + Titan wave pattern coverage and telegraph tests passed.")
