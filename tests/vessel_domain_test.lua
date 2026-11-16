local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local function expect(actual, expected, label)
    if actual ~= expected then error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end

local state = CombatState.new()
state.tp = 110
expect(state:expandVesselDomain(false), true, "Vessel activates Domain without Kris")
expect(state.tp, 50, "standalone Vessel Domain costs 60 TP")
expect(state.vessel_domain.active, true, "Vessel barrier becomes active")
expect(state.player_domain.active, false, "standalone barrier has no shadow garden")
expect(state.player_domain.used, false, "standalone barrier leaves Kris Domain use free")
state:tickEnemyTurnEffects()
expect(state.tp, 48, "barrier drains 2 TP after a complete enemy turn")
expect(state.vessel_domain.upkeep_paid_turns, 1, "barrier upkeep is counted")

local broke = CombatState.new()
broke.tp = 60
expect(broke:expandVesselDomain(false), true, "Vessel Domain starts with exactly 60 TP")
local upkeep = broke:tickEnemyTurnEffects()
expect(upkeep.vessel_domain_cancelled, true, "unpayable upkeep cancels solo barrier")
expect(broke.vessel_domain.active, false, "solo barrier is disabled on upkeep failure")
expect(broke.vessel_domain.cancel_reason, "insufficient_tp", "cancellation reason is recorded")

local coexist = CombatState.new()
expect(coexist:expandChimeraDomain(true), true, "Kris can activate shadow garden")
expect(coexist:expandVesselDomain(true), true, "Vessel can separately activate barrier while garden is up")
coexist.tp = 2
coexist:tickEnemyTurnEffects()
expect(coexist.vessel_domain.active, true, "Vessel barrier remains while upkeep is paid")
expect(coexist.player_domain.turns, 2, "Kris garden keeps its three-turn lifetime")
expect(coexist.tp, 0, "upkeep is deducted from the shared TP pool")
expect(coexist.fusion_domain.active, false, "separate expansions are not Fusion Domain")
expect(coexist:expandFusionDomain(true), false, "spent solo Domain uses prevent later fusion")

-- Live Wave upkeep must use TP gained during the Wave, not the stale start snapshot.
Wave = {
    init = function() end,
    onEnd = function() end,
}
function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {
        __index = base,
        __call = function(ctor, ...)
            local instance = setmetatable({}, ctor)
            instance:init(...)
            return instance
        end,
    })
    return class, base
end
local RuntimeWave = dofile("scripts/battle/waves/knight_titan_assault.lua")
local live_state = CombatState.new()
live_state.vessel_domain.active = true
live_state.vessel_domain.used = true
live_state.tp = 1 -- stale value from the start of the Wave
local live_tp = 5 -- latest in-game TP after the player grazed projectiles
local live_enemy = {ten_shadows_state = live_state}
Game = {
    battle = {
        getActiveEnemies = function() return {live_enemy} end,
    },
    getTension = function() return live_tp end,
    setTension = function(_, value) live_tp = value end,
}
modRequire = function(path)
    if path == "scripts/ten_shadows/runtime_shadows" then
        return {onEnemyTurnEnd = function() end}
    end
    error("Unexpected Wave module: " .. tostring(path))
end
local live_wave = RuntimeWave()
live_wave:onEnd(false)
expect(live_state.tp, 3, "Wave end upkeep is charged from latest in-game TP")
expect(live_tp, 3, "Wave end preserves grazed TP then deducts 2 upkeep")

print("Standalone Vessel Domain, independent usage, upkeep, and coexistence tests passed.")
