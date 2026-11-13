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
    expect(#definitions.titan >= 2, true, mode .. " has at least two Titan moves")
    expect(#definitions.knight >= 2, true, mode .. " has at least two Knight moves")
    expect(#definitions.combo, 1, mode .. " has a combined attack")

    for _, group_name in ipairs({"titan", "knight", "combo"}) do
        for _, attack in ipairs(definitions[group_name]) do
            expect(type(attack.id), "string", mode .. " " .. group_name .. " attack ID")
            expect(type(attack.pattern), "string", mode .. " " .. group_name .. " pattern contract")
            expect(attack.source, group_name, mode .. " " .. group_name .. " source")
            expect(type(attack.mechanic), "string", mode .. " " .. group_name .. " mechanic description")
            expect(type(attack.phases), "table", mode .. " " .. group_name .. " phase availability")
            expect(type(attack.weight), "number", mode .. " " .. group_name .. " scheduler weight")
        end
    end

    local state = CombatState.new()
    expect(state.soul_mode, nil, "legacy scheduler remains default before Vessel mode selection")
    expect(state:setSoulMode(mode), true, mode .. " mode selection")

    local attack, frozen = state:chooseEnemyAttack()
    local function contains(group, id)
        for _, entry in ipairs(group) do if entry.id == id then return true end end
        return false
    end
    expect(contains(definitions.titan, attack.id), true, mode .. " starts with a Titan move")
    expect(attack.soul_mode, mode, mode .. " attack records active SOUL mode")
    expect(frozen, false, mode .. " normal Titan turn is not frozen")

    attack = state:chooseEnemyAttack()
    expect(contains(definitions.knight, attack.id), true, mode .. " alternates to a Knight move")

    state:chooseEnemyAttack()
    attack = state:chooseEnemyAttack()
    expect(contains(definitions.combo, attack.id), true, mode .. " schedules the combined attack on turn four")
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
expect(attack.source, "titan", "frozen turn uses active-mode Titan attack")

expect(state:setSoulMode(nil), true, "clearing Vessel mode succeeds")
expect(state.soul_mode, nil, "clearing mode restores legacy attack selection")

print("Vessel SOUL-mode Knight/Titan scheduler tests passed.")
