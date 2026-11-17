local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local state = CombatState.new()

assert(state.knight_fight.hp == 7300 and state.knight_fight.max_hp == 7300,
    "Knight must use 7,300 internal HP")
assert(state.knight_fight.damage_taken_multiplier == 0.20,
    "Knight must begin at 20% incoming damage")

EnemyBattler = {
    init = function(self) self.width, self.height = 24, 40 end,
    setActor = function() end,
    registerAct = function() end,
    getAttackDamage = function(self, damage, battler, points)
        if damage and damage > 0 then return damage end
        return (battler.chara:getStat("attack") * points) / 20 - self.defense * 3
    end,
    onHurt = function() end,
    hurt = function(self, amount, battler)
        self.health = self.health - amount
        self:onHurt(amount, battler)
    end,
    onDefeat = function(self) self.defeated = true end,
    addChild = function(self, child)
        self.children = self.children or {}
        self.children[#self.children + 1] = child
    end,
    getCheckText = function(self) return self.check end,
}
function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {__index = base})
    return class, base
end
local shieldCtor = function() return {visual_only = true} end
function modRequire(path)
    if path == "scripts/ten_shadows/combat_state" then return CombatState end
    if path == "scripts/battle/objects/knight_shield_visual" then return shieldCtor end
    error("Unexpected module: " .. tostring(path))
end

Game = {
    battle = {
        party = {
            {chara = {id = "susie", health = 100}},
            {chara = {id = "ralsei", health = 100}},
        },
        current_processing_action = nil,
    },
}

local Knight = dofile("scripts/battle/enemies/roaring_knight.lua")
local knight = setmetatable({}, Knight)
knight:init()
knight.ten_shadows_state = state
knight.health = 7300
knight.max_health = 7300
knight.defense = 0

local function attacker(id)
    return {chara = {id = id, getStat = function() return 20 end}}
end
local susie = attacker("susie")
local kris = attacker("kris")

assert(knight:getAttackDamage(100, susie, 100) == 20,
    "ordinary Fight damage must use the 20% multiplier")
assert(knight:getAttackDamage(100, kris, 100) == 20,
    "Kris receives the same Knight damage scaling as every other party member")

Game.battle.party[1].chara.health = 0
Game.battle.party[2].chara.health = 0
assert(knight:getAttackDamage(100, kris, 100) == 20,
    "Kris damage must not change based on Susie or Ralsei status")

Game.battle.party[1].chara.health = 100
Game.battle.party[2].chara.health = 100
Game.battle.current_processing_action = {action = "SPELL", data = {id = "rude_buster"}}
knight:hurt(100, susie)
assert(knight.health == 7257,
    "Rude Buster uses (multiplier + 0.65) / 2 and rounds up")
assert(state.knight_fight.hp == 7257,
    "Knight HP tracking must follow actual damage")

for _ = 1, 20 do state:tickEnemyTurnEffects() end
assert(state.knight_fight.damage_taken_multiplier == 0.35,
    "Knight damage intake rises by 1% each turn and caps at 35%")

print("Knight HP, ATK, incoming damage multiplier, uniform party scaling and Rude Buster formula passed")
