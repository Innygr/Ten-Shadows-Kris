local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local Patterns = dofile("scripts/ten_shadows/attack_wave_patterns.lua")

local arena = {left = 250, right = 390, top = 150, bottom = 292}
local target = {x = 320, y = 230}
local families = {
    radial = true, wall = true, aimed = true, crossfire = true,
    falling = true, sweep = true, twin_slash = true, titan_hands = true,
    big_shot_one = true, big_shot_two = true, big_shot_three = true,
    titan_desperation = true, crystal_barrage = true, knight_titan_collision = true,
    the_roaring = true,
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
        elseif family == "the_roaring" then
            assert(shot.warning and shot.warning.kind == "target",
                "The Roaring spokes need radial trajectory tells")
            assert(shot.mechanic and shot.mechanic.kind == "roaring_shard",
                "The Roaring spokes need their dedicated projectile marker")
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

-- Each Titan Big Shots tier has its own geometry and projectile count.
local big_one, big_one_family = Patterns.build({id = "titan_big_shots"}, 2, 1, arena, target, false)
assert(big_one_family == "big_shot_one" and #big_one == 3,
    "Big Shots 1 must be a three-bolt aimed fan")
for _, shot in ipairs(big_one) do
    assert(shot.mechanic.kind == "titan_big_shot" and shot.mechanic.tier == 1,
        "Big Shots 1 must use heavy Titan projectiles")
    assert(shot.warning.kind == "target", "Big Shots 1 bolts must telegraph their trajectories")
end
assert(big_one[1].direction ~= big_one[2].direction
    and big_one[2].direction ~= big_one[3].direction,
    "Big Shots 1 must have a real spread")

local big_two, big_two_family = Patterns.build({id = "titan_big_shots_2"}, 2, 1, arena, target, false)
local big_two_later = Patterns.build({id = "titan_big_shots_2"}, 2, 2, arena, target, false)
assert(big_two_family == "big_shot_two" and #big_two == 4,
    "Big Shots 2 must be a four-corner crossing pattern")
for _, shot in ipairs(big_two) do
    assert(shot.mechanic.tier == 2 and shot.warning.kind == "target",
        "Big Shots 2 must use tier-two heavy bolts with path tells")
end
assert(big_two[1].direction ~= big_two_later[1].direction
    or big_two[1].warning.length ~= big_two_later[1].warning.length,
    "Big Shots 2 crossing point must shift between volleys")

local big_three, big_three_family = Patterns.build({id = "titan_big_shots_3"}, 3, 1, arena, target, false)
local big_three_later = Patterns.build({id = "titan_big_shots_3"}, 3, 2, arena, target, false)
assert(big_three_family == "big_shot_three" and #big_three == 7,
    "Big Shots 3 must leave one gap in its eight-direction radial burst")
for _, shot in ipairs(big_three) do
    assert(shot.mechanic.tier == 3 and shot.warning.kind == "target",
        "Big Shots 3 must use tier-three heavy bolts with direction tells")
end
assert(big_three[1].direction ~= big_three_later[1].direction,
    "Big Shots 3 radial orientation must rotate between volleys")

-- Knight + Titan Collision synchronizes two Knight diagonals and two Titan lances.
for phase = 1, 3 do
    local collision, family = Patterns.build({id = "titan_knight_combo"}, phase, 1, arena, target, false)
    assert(family == "knight_titan_collision" and #collision == 4,
        "Collision must use its dedicated four-path pattern")
    local knights, titans = 0, 0
    for _, shot in ipairs(collision) do
        assert(shot.mechanic.kind == "knight_titan_collision",
            "Collision paths must carry their coordinated marker")
        assert(shot.warning.kind == "target" and shot.warning.duration <= 0.6,
            "Every converging path needs a readable tell")
        assert(type(shot.mechanic.collision_x) == "number"
            and type(shot.mechanic.collision_y) == "number",
            "All paths must identify the shared collision point")
        assert(math.abs(shot.speed * shot.mechanic.flight_time - shot.warning.length) < 0.001,
            "Each path must reach the shared point at the synchronized arrival time")
        if shot.kind == "knight" then knights = knights + 1 end
        if shot.kind == "titan" then titans = titans + 1 end
    end
    assert(knights == 2 and titans == 2, "Both bosses must contribute two paths")
end
local collision_a = Patterns.build({id = "titan_knight_combo"}, 2, 1, arena, target, false)
local collision_b = Patterns.build({id = "titan_knight_combo"}, 2, 2, arena, target, false)
assert(collision_a[1].mechanic.collision_x ~= collision_b[1].mechanic.collision_x
    or collision_a[1].mechanic.collision_y ~= collision_b[1].mechanic.collision_y,
    "Collision point must shift between volleys")

-- Crystal Barrage is a falling shard curtain with a rotating safe lane.
local crystals, crystal_family = Patterns.build({id = "crystal_barrage"}, 2, 1, arena, target, false)
local crystals_next = Patterns.build({id = "crystal_barrage"}, 2, 2, arena, target, false)
assert(crystal_family == "crystal_barrage" and #crystals == 6,
    "Crystal Barrage must create six shards and leave one of seven lanes open")
for _, shard in ipairs(crystals) do
    assert(shard.kind == "knight" and shard.mechanic.kind == "crystal_shard",
        "Crystal Barrage shards must use their dedicated visual marker")
    assert(shard.direction == math.pi / 2 and shard.warning.kind == "falling",
        "Crystal Barrage shards must descend with vertical telegraphs")
    assert(shard.warning.duration <= 0.6 and shard.warning.length > 0,
        "Crystal Barrage must telegraph each descending lane")
end
local function crystalLanePresent(shots, lane)
    for _, shard in ipairs(shots) do
        if shard.mechanic.lane == lane then return true end
    end
    return false
end
local first_gap, next_gap
for lane = 1, 7 do
    if not crystalLanePresent(crystals, lane) then first_gap = lane end
    if not crystalLanePresent(crystals_next, lane) then next_gap = lane end
end
assert(first_gap ~= next_gap, "Crystal Barrage safe lane must rotate between volleys")

local desperation_target = {x = 330, y = 238, previous = {x = 318, y = 226}}
local desperation, desperation_family = Patterns.build(
    {id = "titan_desperation"}, 3, 1, arena, desperation_target, false
)
assert(desperation_family == "titan_desperation" and #desperation == 5,
    "Desperation Shots must create five dedicated heavy bolts")
for index, shot in ipairs(desperation) do
    assert(shot.kind == "titan" and shot.mechanic.kind == "titan_desperation_shot",
        "Desperation Shots must retain Titan styling and its dedicated marker")
    assert(shot.mechanic.lane == index and shot.mechanic.lead,
        "Each desperation bolt must carry lane and movement-lead metadata")
    assert(shot.warning.kind == "target" and shot.warning.duration <= 0.6,
        "Every desperation bolt must show a readable trajectory tell")
    assert(shot.x < arena.left or shot.x > arena.right,
        "Desperation bolts must enter from the arena edges")
end
local desperation_next = Patterns.build(
    {id = "titan_desperation"}, 3, 2, arena, desperation_target, false
)
assert(desperation[1].x ~= desperation_next[1].x,
    "Desperation launch sides must alternate between volleys")

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

local base_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, false, false)
local knight_domain_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, true, false)
assert(#knight_domain_shots == #base_shots + 2,
    "Knight domain must layer two extra falling blades")
assert(knight_domain_shots[#knight_domain_shots].warning.kind == "falling",
    "Knight domain blades must telegraph their diagonal travel")

-- Kris's domain is independent of the Knight's: two opposing roots launch
-- leaf blades on every volley, rotating through the complete ten-root ring.
local player_domain_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, false, true)
assert(#player_domain_shots == #base_shots + 2,
    "Chimera Shadow Garden must add two root attacks without changing the Knight domain")
local marked_roots = {}
for _, shot in ipairs(player_domain_shots) do
    if shot.mechanic and shot.mechanic.kind == "chimera_domain_blade" then
        assert(shot.kind == "combo" and shot.warning.kind == "target",
            "Kris's root blades must be styled and telegraphed as combined attacks")
        assert(shot.mechanic.root >= 1 and shot.mechanic.root <= 10,
            "each root blade must identify one of the ten garden roots")
        marked_roots[#marked_roots + 1] = shot.mechanic.root
    end
end
assert(#marked_roots == 2, "each garden volley must call exactly two roots")
assert(marked_roots[2] == ((marked_roots[1] + 4) % 10) + 1,
    "the two roots in a volley must be opposite each other")
assert(player_domain_shots[#player_domain_shots].mechanic.kind == "chimera_domain_blade",
    "the final domain root attack must retain its dedicated projectile marker")

local seen_roots = {}
for volley = 1, 10 do
    local shots = Patterns.build({id = "twin_slashes"}, 2, volley, arena, target, false, true)
    local roots = {}
    for _, shot in ipairs(shots) do
        if shot.mechanic and shot.mechanic.kind == "chimera_domain_blade" then
            roots[#roots + 1] = shot
        end
    end
    assert(#roots == 2, "every garden volley must fire two root blades")
    assert(roots[2].mechanic.root == ((roots[1].mechanic.root + 4) % 10) + 1,
        "root pair must remain diametrically opposed")
    assert(not seen_roots[roots[1].mechanic.root],
        "the primary root should not repeat before all ten roots have acted")
    seen_roots[roots[1].mechanic.root] = true

    for _, shot in ipairs(roots) do
        local angle = (shot.mechanic.root - 1) * math.pi * 2 / 10
        local root_radius = math.min(arena.right - arena.left, arena.bottom - arena.top) * 0.43 * 0.72
        local expected_x = (arena.left + arena.right) / 2 + math.cos(angle) * root_radius
        local expected_y = (arena.top + arena.bottom) / 2 + math.sin(angle) * root_radius
        assert(math.abs(shot.x - expected_x) < 0.001 and math.abs(shot.y - expected_y) < 0.001,
            "root blade must launch from the matching garden petal")
        assert(shot.warning.duration <= 0.6 and shot.speed > 0,
            "root blade must have a readable tell and a valid travel speed")
    end
end
for root = 1, 10 do
    assert(seen_roots[root], "all ten garden roots must participate over ten volleys")
end

-- The Roaring is the phase-three signature burst: eight telegraphed
-- spokes leave two opposite safe wedges, and that opening rotates per volley.
local roar_one, roar_family = Patterns.build({id = "black_flash"}, 3, 1, arena, target, false)
local roar_two, roar_family_two = Patterns.build({id = "black_flash"}, 3, 2, arena, target, false)
assert(roar_family == "the_roaring" and roar_family_two == "the_roaring",
    "The Roaring must use its dedicated final-phase pattern")
assert(#roar_one == 8 and #roar_two == 8,
    "The Roaring must fire eight spokes while leaving two opposite gaps")
local function roaringGaps(shots)
    local present = {}
    for _, shot in ipairs(shots) do
        assert(shot.kind == "knight" and shot.mechanic.kind == "roaring_shard",
            "The Roaring must use Knight-styled dedicated shards")
        assert(shot.warning.kind == "target" and shot.warning.duration == 0.40,
            "Every Roaring shard must show a short trajectory tell")
        assert(shot.x == (arena.left + arena.right) / 2
            and shot.y == (arena.top + arena.bottom) / 2,
            "Roaring spokes must radiate from the arena centre")
        assert(shot.warning.length > 0 and shot.speed > 0,
            "Roaring spokes must reach beyond the arena edge")
        present[shot.mechanic.spoke] = true
    end
    local missing = {}
    for spoke = 0, 9 do
        if not present[spoke] then missing[#missing + 1] = spoke end
    end
    assert(#missing == 2, "The Roaring must leave exactly two safe spokes")
    assert((missing[1] + 5) % 10 == missing[2],
        "The Roaring's safe spokes must be opposite")
    return missing
end
local roar_gaps_one = roaringGaps(roar_one)
local roar_gaps_two = roaringGaps(roar_two)
assert(roar_gaps_one[1] ~= roar_gaps_two[1],
    "The Roaring's safe route must rotate between volleys")

print("Knight + Titan wave pattern coverage and telegraph tests passed.")
