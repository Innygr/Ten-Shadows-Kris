local CombatState = dofile("scripts/ten_shadows/combat_state.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local expected_modes = {"red", "blue", "green", "yellow", "purple", "orange", "cyan"}

for _, mode in ipairs(expected_modes) do
    local definitions = CombatState.SOUL_MODE_ATTACKS[mode]
    expect(type(definitions), "table", mode .. " mode exists")
    expect(#definitions.titan, 1, mode .. " has a Titan attack")
    expect(#definitions.knight, 1, mode .. " has a Knight attack")
    expect(#definitions.combo, 1, mode .. " has a combined attack")

    for _, group_name in ipairs({"titan", "knight", "combo"}) do
        local attack = definitions[group_name][1]
        expect(type(attack.id), "string", mode .. " " .. group_name .. " attack ID")
        expect(type(attack.pattern), "string", mode .. " " .. group_name .. " pattern contract")
        expect(attack.source, group_name, mode .. " " .. group_name .. " source")
        expect(attack.phases[1], 1, mode .. " " .. group_name .. " phase one")
        expect(attack.phases[2], 2, mode .. " " .. group_name .. " phase two")
        expect(attack.phases[3], 3, mode .. " " .. group_name .. " phase three")
    end

    local state = CombatState.new()
    expect(state.soul_mode, nil, "legacy scheduler remains default before Vessel mode selection")
    expect(state:setSoulMode(mode), true, mode .. " mode selection")

    local attack, frozen = state:chooseEnemyAttack()
    expect(attack.id, definitions.titan[1].id, mode .. " starts with Titan attack")
    expect(attack.soul_mode, mode, mode .. " attack records active SOUL mode")
    expect(attack.pattern, definitions.titan[1].pattern, mode .. " Titan pattern is selected")
    expect(frozen, false, mode .. " normal Titan turn is not frozen")

    attack = state:chooseEnemyAttack()
    expect(attack.id, definitions.knight[1].id, mode .. " alternates to Knight attack")

    state:chooseEnemyAttack()
    attack = state:chooseEnemyAttack()
    expect(attack.id, definitions.combo[1].id, mode .. " schedules the combined attack on turn four")
end

local state = CombatState.new()
expect(state:setSoulMode("yellow"), true, "yellow mode can be enabled")
local changed, reason = state:setSoulMode("ultraviolet")
expect(changed, false, "unknown SOUL mode is rejected")
expect(state.soul_mode, "yellow", "invalid mode does not replace current mode")
expect(type(reason), "string", "invalid mode returns a reason")

state.boss.frozen_turns = 1
local attack, frozen = state:chooseEnemyAttack()
expect(frozen, true, "frozen Knight turn is reported")
expect(attack.source, "titan", "Titan still attacks while Knight is frozen")
expect(attack.id, CombatState.SOUL_MODE_ATTACKS.yellow.titan[1].id, "frozen turn uses active-mode Titan attack")

expect(state:setSoulMode(nil), true, "clearing Vessel mode succeeds")
expect(state.soul_mode, nil, "clearing mode restores legacy attack selection")

print("Vessel SOUL-mode Knight/Titan scheduler tests passed.")
