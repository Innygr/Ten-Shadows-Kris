-- The old 800 DEF formula subtracted 2,400 from ordinary hits, causing misses.
local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local BossPhase = dofile("scripts/ten_shadows/boss_phase.lua")

local function expect(actual, expected, label)
    if actual ~= expected then error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end

EnemyBattler = {
    init = function(self) self.health = 0 end,
    setActor = function() end,
    registerAct = function() end,
    onHurt = function(self) self.base_hurt_count = (self.base_hurt_count or 0) + 1 end,
    hurt = function(self, amount, battler)
        self.health = self.health - amount
        self:onHurt(amount, battler)
        if self.health <= 0 then self.health = 0; self:onDefeat(amount, battler) end
    end,
    onDefeat = function(self) self.defeated = true end,
}
function Class(base)
    local class = {}; class.__index = class; setmetatable(class, {__index = base})
    return class, base
end
function modRequire(path)
    if path == "scripts/ten_shadows/combat_state" then return CombatState end
    if path == "scripts/ten_shadows/boss_phase" then return BossPhase end
    error("Unexpected module: " .. tostring(path))
end
Game = {battle = {current_processing_action = nil}}
local Titan = dofile("scripts/battle/enemies/roaring_knight_titan.lua")

local function freshTitan()
    local enemy = setmetatable({}, Titan)
    enemy:init()
    enemy.status_messages = {}
    enemy.statusMessage = function(self, kind, value)
        self.status_messages[#self.status_messages + 1] = {kind, value}
    end
    return enemy
end

local enemy = freshTitan()
local user = {chara = {getStat = function() return 24 end}}
local normal_attack = enemy:getAttackDamage(0, user, 100)
assert(normal_attack > 0, "normal attack timing must produce a positive hit against the Titan")
local shield_before = enemy.ten_shadows_state.titan.shield_hp
enemy:hurt(normal_attack, user)
expect(enemy.health, enemy.max_health, "normal attack damages only shield while it exists")
expect(enemy.ten_shadows_state.titan.shield_hp, shield_before - math.floor(normal_attack * 0.35 + 0.5),
    "normal attacks deal reduced shield damage")

local function testSpell(id, damage, multiplier, label)
    local target = freshTitan()
    Game.battle.current_processing_action = {action = "SPELL", data = {id = id}}
    target:hurt(damage, user)
    local expected = CombatState.TITAN_SHIELD_MAX_HP
        - math.min(CombatState.TITAN_SHIELD_MAX_HP, math.floor(damage * multiplier + 0.5))
    expect(target.ten_shadows_state.titan.shield_hp, expected, label)
    expect(target.health, target.max_health, label .. " does not bypass shield")
end
testSpell("rude_buster", 100, 3.5, "Rude Buster breaks shield quickly")
testSpell("ts_ice_shock", 18, 5.0, "Ice Shock damages shield heavily")
testSpell("ts_fire_shock", 28, 4.0, "Fire Shock damages shield heavily")
Game.battle.current_processing_action = nil

local breaking = freshTitan()
breaking.ten_shadows_state.titan.shield_hp = 5
breaking:hurt(100, user)
expect(breaking.ten_shadows_state.titan.shield_hp, 0, "shield reaches zero")
expect(breaking.health, breaking.max_health, "shield overflow does not spill into Titan HP")
expect(type(breaking:getEncounterText()), "string", "shield break is announced")
breaking:hurt(50, user)
expect(breaking.health, breaking.max_health - 50, "subsequent attacks hit Titan HP")
assert(table.concat(breaking:getCheckText(), " "):find("shield is broken", 1, true),
    "Titan CHECK reports broken shield")
print("Titan shield interception, multipliers, break, and post-break HP tests passed.")
