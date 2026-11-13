local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local graphics_calls = {circles = 0}
love = {
    graphics = {
        push = function() end,
        pop = function() end,
        setColor = function() end,
        setLineWidth = function() end,
        circle = function() graphics_calls.circles = graphics_calls.circles + 1 end,
    },
}

local BaseSoul = {}
function BaseSoul:init(x, y, color)
    self.x = x or 0
    self.y = y or 0
    self.color = color
    self.transitioning = false
end
function BaseSoul:update()
    self.base_updates = (self.base_updates or 0) + 1
end
function BaseSoul:draw()
    self.base_draws = (self.base_draws or 0) + 1
end

Soul = BaseSoul
Bullet = {}
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

local held = false
local released = false
Input = {
    down = function(key) return key == "confirm" and held end,
    released = function(key) return key == "confirm" and released end,
}
DT = 0.15

local bullets = {}
Game = {
    battle = {
        state = "DEFENDING",
        enemies = {},
    },
    stage = {
        getObjects = function(_, class)
            expect(class, Bullet, "Cyan purge requests battle bullets")
            return bullets
        end,
    },
    tension = 0,
    giveTension = function(self, amount)
        self.tension = self.tension + amount
    end,
}

local CyanSoul = dofile("scripts/objects/cyan_soul.lua")
local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local state = CombatState.new()
Game.battle.enemies = {{ten_shadows_state = state}}

local function projectile(x, y, execution)
    return {
        x = x,
        y = y,
        armed = true,
        is_execution_slash = execution == true,
        remove = function(self)
            self.removed = true
        end,
    }
end

local soul = CyanSoul(100, 100)
bullets = {
    projectile(112, 100, true),
    projectile(200, 200, false),
}

held = true
for _ = 1, 3 do soul:update() end
expect(soul.cyan_charging, true, "holding confirm starts the Cyan charge")
assert(soul.cyan_charge >= 0.35, "holding confirm builds enough charge to attempt a parry")
held = false
released = true
soul:update()
released = false

expect(soul.cyan_last_parry, true, "releasing near the armed execution slash parries it")
expect(state.boss.counter_ready, true, "successful parry opens the counter ACT")
expect(state.boss.exposed, 2, "successful parry exposes the shared boss")
expect(state.knight_disrupted, 1, "successful parry staggers the Knight")
expect(state.tp, 47, "successful parry awards 12 internal TP")
expect(Game.tension, 12, "successful parry grants 12 battle tension")
expect(bullets[1].removed, true, "parry slash is purified")
expect(bullets[2].removed, true, "all other visible bullets are purified")
expect(soul.cyan_charge, 0, "release resets the charge meter")
assert(soul.cyan_pulse_timer > 0, "release starts the expanding purification pulse")

local ready, counter_damage = state:consumeExecutionCounter()
expect(ready, true, "successful parry grants one counter")
expect(counter_damage, 36, "counter damage is defined")
expect(state.boss.counter_ready, false, "counter is consumed once")
expect(state:consumeExecutionCounter(), false, "counter cannot be reused")

local expiring = CombatState.new()
expiring:parryExecution()
expiring:tickEnemyTurnEffects()
expect(expiring.boss.counter_ready, true, "counter survives through the immediate player action window")
expiring:tickEnemyTurnEffects()
expect(expiring.boss.counter_ready, false, "unused counter expires after its next action window")

-- A short release still purifies bullets, but it cannot parry the Knight.
local missed_state = CombatState.new()
Game.battle.enemies = {{ten_shadows_state = missed_state}}
local miss_soul = CyanSoul(100, 100)
bullets = {
    projectile(106, 100, true),
    projectile(100, 180, false),
}
held = true
miss_soul:update()
held = false
released = true
miss_soul:update()
released = false
expect(miss_soul.cyan_last_parry, false, "undercharged release misses the parry window")
expect(missed_state.boss.counter_ready, false, "mistimed release does not grant a counter")
expect(bullets[1].removed, true, "mistimed release still purifies the slash")
expect(bullets[2].removed, true, "mistimed release still purifies other projectiles")

-- Encounter factory routes Cyan to the special Soul and other modes to base Soul.
Encounter = {
    createSoul = function(_, x, y, color)
        return {base_soul = true, x = x, y = y, color = color}
    end,
}
local Preview = dofile("scripts/battle/encounters/knight_titan_preview.lua")
modRequire = function(path)
    expect(path, "scripts/objects/cyan_soul", "Cyan encounter Soul module")
    return CyanSoul
end
local factory_state = CombatState.new()
Game.battle.enemies = {{ten_shadows_state = factory_state}}
factory_state:setSoulMode("cyan")
local cyan_from_factory = Preview.createSoul({}, 12, 24, {1, 0, 0})
expect(cyan_from_factory.is_cyan_soul, true, "Cyan mode creates the special SOUL")
expect(cyan_from_factory.ten_shadows_mode, "cyan", "Cyan SOUL keeps the scheduler tag")
factory_state:setSoulMode("red")
local normal_from_factory = Preview.createSoul({}, 12, 24, {1, 0, 0})
expect(normal_from_factory.base_soul, true, "other modes use the default Kristal SOUL")

soul:draw()
assert(graphics_calls.circles > 0, "Cyan SOUL draws charge and parry pulse rings")
assert((soul.base_updates or 0) >= 4, "base Soul update is preserved")
expect(soul.base_draws, 1, "base Soul drawing is preserved")

print("Cyan SOUL charge, purge, execution parry, counter, and factory tests passed.")
