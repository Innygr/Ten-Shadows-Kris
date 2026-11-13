local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local Patterns = dofile("scripts/ten_shadows/attack_wave_patterns.lua")

local arena = {left = 250, right = 390, top = 150, bottom = 292}
local target = {x = 320, y = 230}
local families = {radial = true, wall = true, aimed = true, crossfire = true, falling = true, sweep = true}

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

local base_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, false)
local domain_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, true)
assert(#domain_shots == #base_shots + 2, "Knight domain must layer two extra falling blades")
assert(domain_shots[#domain_shots].warning.kind == "falling",
    "Knight domain blades must telegraph their diagonal travel")

print("Knight + Titan wave pattern coverage and telegraph tests passed.")
