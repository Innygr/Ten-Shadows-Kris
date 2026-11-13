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
    end
end

for _, attack in ipairs(CombatState.KNIGHT_ATTACKS) do
    validate(attack, attack.phases[1])
end

for mode, sets in pairs(CombatState.SOUL_MODE_ATTACKS) do
    for _, group in ipairs({sets.titan, sets.knight, sets.combo}) do
        for _, attack in ipairs(group) do
            validate(attack, attack.phases[1])
        end
    end
end

local wall_shots, wall_family = Patterns.build({id = "box_splitter"}, 1, 1, arena, target, false)
assert(wall_family == "wall" and #wall_shots == 6, "wall patterns must leave one of seven lanes open")

local radial_shots, radial_family = Patterns.build({id = "red_titan_pulse_barrage", pattern = "radial-pulse-barrage", source = "titan"}, 1, 1, arena, target, false)
assert(radial_family == "radial" and #radial_shots == 10, "radial patterns must fan out in all directions")

local base_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, false)
local domain_shots = Patterns.build({id = "twin_slashes"}, 3, 3, arena, target, true)
assert(#domain_shots == #base_shots + 2, "Knight domain must layer two extra falling blades")

print("Knight + Titan wave pattern coverage tests passed.")
