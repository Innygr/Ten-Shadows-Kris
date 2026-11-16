local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local BossPhase = dofile("scripts/ten_shadows/boss_phase.lua")

EnemyBattler = {
    init = function() end,
    setActor = function() end,
    registerAct = function() end,
    onHurt = function(self, damage) self.health = self.health - damage end,
    onDefeat = function(self) self.defeated = true end,
    getCheckText = function(self)
        local lines = {}
        for i, line in ipairs(self.check or {}) do
            lines[#lines + 1] = (i == 1 and "* " .. string.upper(self.name) .. " - " or "* ") .. line
        end
        return lines
    end,
}
function Class(base)
    local class = {}
    setmetatable(class, {__index = base})
    return class, base
end
function modRequire(path)
    if path == "scripts/ten_shadows/combat_state" then return CombatState end
    if path == "scripts/ten_shadows/boss_phase" then return BossPhase end
    if path == "scripts/ten_shadows/runtime_shadows" then
        return dofile("scripts/ten_shadows/runtime_shadows.lua")
    end
    error("Unexpected module: " .. tostring(path))
end

local Titan = dofile("scripts/battle/enemies/roaring_knight_titan.lua")
local Knight = dofile("scripts/battle/enemies/roaring_knight.lua")
local registry = {roaring_knight_titan = Titan, roaring_knight = Knight}
Encounter = {
    init = function(self) self.spawned = {} end,
    addEnemy = function(self, id)
        local class = assert(registry[id], "unexpected enemy: " .. tostring(id))
        local enemy = setmetatable({}, {__index = class})
        enemy:init()
        self.spawned[#self.spawned + 1] = enemy
        return enemy
    end,
}
local Preview = dofile("scripts/battle/encounters/knight_titan_preview.lua")
local function spawnPair()
    local preview = setmetatable({}, {__index = Preview})
    preview:init()
    return preview.spawned[1], preview.spawned[2]
end

local titan, knight = spawnPair()
assert(titan.ten_shadows_role == "titan" and titan.max_health == 21000
    and titan.health == 21000, "Titan must start with 21,000 independent HP")
assert(titan.attack == 40 and titan.defense == 800, "Titan must have 40 ATK and 800 DEF")
assert(titan.disable_mercy and knight.disable_mercy,
    "both bosses must use Kristal's crossed-out Mercy UI")
assert(not titan.auto_spare and not knight.auto_spare,
    "neither boss can be auto-spared")
assert(not titan.can_freeze and not knight.can_freeze,
    "neither boss can be frozen")
assert(titan.tired_percentage == 0 and knight.tired_percentage == 0,
    "neither boss can enter the TIRED state")
assert(table.concat(titan:getCheckText(), " "):find("21,000 / 21,000", 1, true),
    "Titan Inspect must show current HP and maximum HP")
assert(knight.ten_shadows_role == "knight" and knight.max_health == 1460
    and knight.health == 1460, "Knight must start with 1,460 independent HP")
assert(titan ~= knight and titan.ten_shadows_state == knight.ten_shadows_state,
    "bosses must be separate battlers with one shared scheduler")
assert(titan.waves[1] == knight.waves[1] and knight.waves[1] == "knight_titan_assault",
    "both bosses must select the same coordinated Wave")

local scheduler = titan.ten_shadows_state
knight:onHurt(400)
assert(knight.health == 1060 and titan.health == 21000, "Knight damage must not damage Titan")
assert(table.concat(knight:getCheckText(), " "):find("1,060 / 1,460", 1, true),
    "Knight CHECK must show its current independent HP")
assert(table.concat(titan:onAct(nil, "Inspect"), " "):find("21,000 / 21,000", 1, true),
    "Titan Inspect must retain its current independent HP")
assert(scheduler.boss.hp == 21000 and scheduler.boss.phase == 1,
    "Knight damage must not change Titan HP or phase")
titan:onHurt(7000)
assert(titan.health == 14000 and scheduler.boss.hp == 14000,
    "Titan damage must synchronize to scheduler HP")
assert(titan.ten_shadows_phase == 2 and scheduler.boss.phase == 2,
    "Titan must enter phase two at 14,000 HP")
assert(table.concat(titan:onAct(nil, "CHECK"), " "):find("14,000 / 21,000", 1, true),
    "Titan CHECK must refresh after damage, even when the player explicitly inspects")
knight:onHurt(500)
assert(knight.health == 560 and titan.health == 14000 and scheduler.boss.hp == 14000,
    "further Knight damage must remain independent")

knight.health = 0
knight:onDefeat()
assert(table.concat(knight:getCheckText(), " "):find("0 / 1,460", 1, true),
    "defeated Knight CHECK must show zero current HP")
assert(not scheduler.knight_alive, "Knight defeat must remove its attack source")
for _ = 1, 6 do
    local attack = scheduler:chooseEnemyAttack()
    local source = attack and (attack.source
        or (string.sub(attack.id, 1, 6) == "titan_" and "titan" or "knight"))
    assert(attack and source == "titan", "Titan must keep attacking after Knight defeat")
end

local surviving_titan, surviving_knight = spawnPair()
local survivor_state = surviving_titan.ten_shadows_state
surviving_titan:onDefeat()
assert(table.concat(surviving_titan:onAct(nil, "Inspect"), " "):find("0 / 21,000", 1, true),
    "defeated Titan Inspect must show zero current HP")
assert(not survivor_state.titan_alive and survivor_state.knight_alive,
    "Titan defeat must leave Knight alive")
assert(survivor_state.boss.hp == 0 and survivor_state.boss.phase == 3,
    "Titan defeat must close its HP pool and start the final phase")
local survivor_attack = survivor_state:chooseEnemyAttack()
local survivor_source = survivor_attack and (survivor_attack.source
    or (string.sub(survivor_attack.id, 1, 6) == "titan_" and "titan" or "knight"))
assert(survivor_attack and survivor_source == "knight",
    "Knight must continue attacking without Titan actions")
assert(survivor_attack.id == "black_flash",
    "surviving Knight must receive the phase-three Roaring signature")

-- The shared Wave ticks per-enemy statuses on every active boss, but advances
-- encounter-wide timers exactly once after the complete Wave.
Wave = {
    init = function() end,
    onEnd = function() end,
}
local Assault = dofile("scripts/battle/waves/knight_titan_assault.lua")
local status_state = CombatState.new()
status_state.boss.exposed = 2
local state_ticks = 0
function status_state:tickEnemyTurnEffects()
    state_ticks = state_ticks + 1
    self.boss.exposed = math.max(0, self.boss.exposed - 1)
end
local active_titan = {
    ten_shadows_role = "titan",
    ten_shadows_state = status_state,
    ten_shadows_exposed_turns = 2,
}
local active_knight = {
    ten_shadows_role = "knight",
    ten_shadows_state = status_state,
    ten_shadows_exposed_turns = 2,
}
Game = {
    battle = {
        enemies = {active_titan, active_knight},
        getActiveEnemies = function(self) return self.enemies end,
    },
}
local wave = setmetatable({}, {__index = Assault})
wave:onEnd(false)
assert(active_titan.ten_shadows_exposed_turns == 1
    and active_knight.ten_shadows_exposed_turns == 1,
    "each boss's target-specific exposure must tick after the shared Wave")
assert(status_state.boss.exposed == 1 and state_ticks == 1,
    "encounter-wide exposure and domain effects must tick exactly once per Wave")

print("Independent Knight/Titan HP pools, survivor scheduling, and per-target status timers passed.")
