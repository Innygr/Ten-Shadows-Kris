local Effects = dofile("scripts/ten_shadows/runtime_spells.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local enemy = {
    damage = 0,
    hurt = function(self, amount, user) self.damage = self.damage + amount end,
}
Effects.damage({}, enemy, 18)
expect(enemy.damage, 18, "normal spell damage")
enemy.ten_shadows_exposed_turns = 1
Effects.damage({}, enemy, 10)
expect(enemy.damage, 32, "exposed damage uses 1.4 multiplier")

expect(Effects.addChill(enemy, 1), false, "first chill stack")
expect(Effects.addChill(enemy, 1), false, "second chill stack")
expect(Effects.addChill(enemy, 1), true, "third chill freezes")
expect(enemy.ten_shadows_frozen_turns, 1, "frozen turn is recorded")
expect(enemy.ten_shadows_exposed_turns, 1, "freeze exposes target")

Effects.disrupt(enemy)
expect(enemy.ten_shadows_disrupted, true, "tornado disruption flag")

local healed = 0
local ally = {
    is_down = false,
    heal = function(self, amount) healed = healed + amount end,
}
expect(Effects.heal(ally, 22), true, "living ally can be healed")
expect(healed, 22, "heal amount")

local health = -25
local max_health = 50
local revived = false
local downed = {
    is_down = true,
    chara = {
        getStat = function() return max_health end,
        getHealth = function() return health end,
        setHealth = function(_, value) health = value end,
    },
    checkHealth = function(self) self.is_down = false; revived = true end,
    statusMessage = function() end,
}
expect(Effects.revive(downed), true, "downed ally can be revived")
expect(health, 25, "revive restores half max HP")
expect(revived, true, "revive clears down state")

local buffed = 0
Game = {
    battle = {
        party = {
            {isActive = function() return true end, chara = {id = "kris", addStatBuff = function(_, stat, amount, cap)
                expect(stat, "defense", "brighten stat")
                expect(amount, 1, "brighten amount")
                expect(cap, 1, "brighten cap")
                buffed = buffed + 1
            end}},
            {isActive = function() return true end, chara = {id = "susie", addStatBuff = function() buffed = buffed + 1 end}},
            {isActive = function() return true end, chara = {id = "ralsei", addStatBuff = function() buffed = buffed + 1 end}},
            {isActive = function() return true end, chara = {id = "noelle", addStatBuff = function() error("Noelle must not be buffed") end}},
            {isActive = function() return true end, chara = {id = "berdly", addStatBuff = function() error("Berdly must not be buffed") end}},
            {isActive = function() return true end, chara = {id = "vessel", addStatBuff = function() error("Vessel must not be buffed") end}},
        },
    },
}
expect(Effects.brighten(), true, "brighten succeeds in battle")
expect(buffed, 3, "brighten buffs Kris, Susie, and Ralsei only")
expect(Game.battle.ten_shadows_brightened, true, "brighten state flag")

print("Runtime spell effect tests passed.")
