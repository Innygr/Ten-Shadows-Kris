local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local BossPhase = dofile("scripts/ten_shadows/boss_phase.lua")

EnemyBattler = {
    init = function() end,
    setActor = function() end,
    registerAct = function() end,
    onHurt = function(self, damage) self.health = self.health - damage end,
    onDefeat = function(self) self.defeated = true end,
}
function Class(base)
    local class = {}
    setmetatable(class, {__index = base})
    return class, base
end
function modRequire(path)
    if path == "scripts/ten_shadows/combat_state" then return CombatState end
    if path == "scripts/ten_shadows/boss_phase" then return BossPhase end
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
assert(knight.ten_shadows_role == "knight" and knight.max_health == 1460
    and knight.health == 1460, "Knight must start with 1,460 independent HP")
assert(titan ~= knight and titan.ten_shadows_state == knight.ten_shadows_state,
    "bosses must be separate battlers with one shared scheduler")
assert(titan.waves[1] == knight.waves[1] and knight.waves[1] == "knight_titan_assault",
    "both bosses must select the same coordinated Wave")

local scheduler = titan.ten_shadows_state
knight:onHurt(400)
assert(knight.health == 1060 and titan.health == 21000, "Knight damage must not damage Titan")
assert(scheduler.boss.hp == 21000 and scheduler.boss.phase == 1,
    "Knight damage must not change Titan HP or phase")
titan:onHurt(7000)
assert(titan.health == 14000 and scheduler.boss.hp == 14000,
    "Titan damage must synchronize to scheduler HP")
assert(titan.ten_shadows_phase == 2 and scheduler.boss.phase == 2,
    "Titan must enter phase two at 14,000 HP")
knight:onHurt(500)
assert(knight.health == 560 and titan.health == 14000 and scheduler.boss.hp == 14000,
    "further Knight damage must remain independent")

knight:onDefeat()
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

print("Independent Knight/Titan HP pools and survivor attack scheduling passed.")
