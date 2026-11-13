local CombatState = dofile("scripts/ten_shadows/combat_state.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local expected_modes = {"red", "blue", "green", "yellow", "purple", "orange", "cyan"}

local function contains(group, id)
    for _, entry in ipairs(group) do
        if entry.id == id then return true end
    end
    return false
end

local function isModeAttack(definitions, id)
    return contains(definitions.titan, id)
        or contains(definitions.knight, id)
        or contains(definitions.combo, id)
end

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

    -- Supplying the actual matching SOUL type activates its unique attack set.
    local attack, frozen = state:chooseEnemyAttack(mode)
    expect(contains(definitions.titan, attack.id), true, mode .. " starts with a Titan move")
    expect(attack.soul_mode, mode, mode .. " attack records active SOUL mode")
    expect(frozen, false, mode .. " normal Titan turn is not frozen")

    attack = state:chooseEnemyAttack(mode)
    expect(contains(definitions.knight, attack.id), true, mode .. " alternates to a Knight move")

    state:chooseEnemyAttack(mode)
    attack = state:chooseEnemyAttack(mode)
    expect(contains(definitions.combo, attack.id), true, mode .. " schedules the combined attack on turn four")
end

-- Selecting a mode in the menu must not activate its attack set while a
-- different SOUL is physically active in the arena.
local mismatched = CombatState.new()
expect(mismatched:setSoulMode("yellow"), true, "yellow mode can be selected")
local attack = mismatched:chooseEnemyAttack("red")
expect(attack.soul_mode, nil, "red SOUL does not activate selected yellow attacks")
expect(isModeAttack(CombatState.SOUL_MODE_ATTACKS.yellow, attack.id), false,
    "yellow-specific attacks are blocked while red SOUL is active")

-- A missing/ordinary SOUL type also falls back to the legacy attack pool.
local absent = CombatState.new()
expect(absent:setSoulMode("cyan"), true, "cyan mode can be selected")
attack = absent:chooseEnemyAttack(nil)
expect(attack.soul_mode, nil, "missing SOUL type does not activate mode attacks")
expect(isModeAttack(CombatState.SOUL_MODE_ATTACKS.cyan, attack.id), false,
    "cyan-specific attacks are blocked when no Cyan SOUL is active")

-- Once the player changes to the selected type, the special attack set is enabled.
attack = mismatched:chooseEnemyAttack("yellow")
expect(type(attack.soul_mode), "string", "matching yellow SOUL activates yellow attacks")
expect(isModeAttack(CombatState.SOUL_MODE_ATTACKS.yellow, attack.id), true,
    "matching yellow SOUL selects only yellow-specific attacks")

local invalid = CombatState.new()
expect(invalid:setSoulMode("yellow"), true, "yellow mode can be enabled")
local changed, reason = invalid:setSoulMode("ultraviolet")
expect(changed, false, "unknown SOUL mode is rejected")
expect(invalid.soul_mode, "yellow", "invalid mode does not replace current mode")
expect(type(reason), "string", "invalid mode returns a reason")

local frozen = CombatState.new()
expect(frozen:setSoulMode("yellow"), true, "yellow frozen test mode")
frozen.boss.frozen_turns = 1
local frozen_attack, is_frozen = frozen:chooseEnemyAttack("red")
expect(is_frozen, true, "frozen Knight turn is reported")
assert(type(frozen_attack.id) == "string" and frozen_attack.id:sub(1, 6) == "titan_"
    and frozen_attack.id ~= "titan_knight_combo",
    "frozen Knight turn must select a Titan-only attack from the legacy pool")
expect(frozen_attack.soul_mode, nil, "mismatched Soul stays on the legacy Titan set")
expect(isModeAttack(CombatState.SOUL_MODE_ATTACKS.yellow, frozen_attack.id), false,
    "frozen fallback attack is not yellow-specific")

expect(invalid:setSoulMode(nil), true, "clearing Vessel mode succeeds")
expect(invalid.soul_mode, nil, "clearing mode restores legacy attack selection")

-- The actual preview encounter constructs a coloured Soul tagged with the
-- mode selected by the Vessel; the Wave reads this tag to gate its attack set.
Encounter = {
    createSoul = function(_, x, y, color)
        return {x = x, y = y, color = color, base_soul = true}
    end,
}
function Class(base)
    local class = {}
    setmetatable(class, {__index = base})
    return class, base
end
local Preview = dofile("scripts/battle/encounters/knight_titan_preview.lua")
modRequire = function(path)
    expect(path, "scripts/objects/cyan_soul", "Cyan Soul factory module")
    return function(x, y)
        return {
            x = x, y = y, is_cyan_soul = true,
            ten_shadows_mode = "cyan", color = {0.20, 0.90, 1.0},
        }
    end
end
local mode_state = CombatState.new()
Game = {battle = {enemies = {{ten_shadows_state = mode_state}}}}
for _, mode in ipairs(expected_modes) do
    expect(mode_state:setSoulMode(mode), true, mode .. " Soul factory mode")
    local soul = Preview.createSoul({}, 12, 24, {1, 0, 0})
    if mode == "cyan" then
        expect(soul.is_cyan_soul, true, "Cyan mode creates the special charge Soul")
    else
        expect(soul.base_soul, true, mode .. " uses Kristal's standard Soul movement")
    end
    expect(soul.ten_shadows_mode, mode, mode .. " Soul is tagged with active mode")
    expect(type(soul.color), "table", mode .. " Soul has a distinct colour")
end)

-- Clearing the mode returns the default Kristal SOUL and leaves no stale tag.
mode_state:setSoulMode(nil)
local default_soul = Preview.createSoul({}, 12, 24, {1, 0, 0})
expect(default_soul.ten_shadows_mode, nil, "default SOUL does not retain a mode tag")

local wave_file = assert(io.open("scripts/battle/waves/knight_titan_assault.lua", "r"))
local wave_source = wave_file:read("*a")
wave_file:close()
assert(wave_source:find("soul.ten_shadows_mode", 1, true),
    "Knight + Titan Wave must pass the actual active SOUL type into the scheduler")

print("Vessel SOUL-mode attack gating and factory tests passed.")
