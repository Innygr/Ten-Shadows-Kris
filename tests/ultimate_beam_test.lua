-- Exercise Vessel's one-turn ultimate beam charge, target lock, Wave release,
-- and its full-strength presentation.
local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

Object = {}
function Object:init(x, y) self.x, self.y = x or 0, y or 0 end
function Object:update() end
function Object:remove() self.removed = true end
function Object:draw() self.base_draws = (self.base_draws or 0) + 1 end

local graphics = {lines = 0, circles = 0}
love = {
    graphics = {
        push = function() end,
        pop = function() end,
        setColor = function() end,
        setLineWidth = function() end,
        line = function() graphics.lines = graphics.lines + 1 end,
        circle = function() graphics.circles = graphics.circles + 1 end,
    },
}

function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {
        __index = base,
        __call = function(ctor, ...)
            local instance = setmetatable({}, ctor)
            if instance.init then instance:init(...) end
            return instance
        end,
    })
    return class, base
end

local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local UltimateBeam = dofile("scripts/battle/objects/ultimate_beam.lua")
local boss_actions = dofile("scripts/ten_shadows/boss_actions.lua")

local target = {
    health = 4000,
    x = 300, y = 100, width = 30, height = 40,
    hurt = function(self, amount, source)
        self.health = math.max(0, self.health - amount)
        self.total_damage = (self.total_damage or 0) + amount
        self.last_source = source
    end,
    ten_shadows_state = CombatState.new(),
}
local vessel = {chara = {id = "vessel"}}

local result = boss_actions.onAct(target, vessel, "ULTIMATE BEAM", function()
    error("Ultimate Beam must not fall through to the ordinary ACT handler")
end)
expect(type(result), "table", "Vessel receives charge dialogue")
expect(target.ten_shadows_state.ultimate_beam.charging, true,
    "the ultimate beam enters its charge state")
expect(target.ten_shadows_state.ultimate_beam.turns_remaining, 1,
    "the ultimate beam requires one complete enemy turn")
expect(target.ten_shadows_state.ultimate_beam.target, target,
    "the ultimate beam locks the boss selected by Vessel")
expect(target.ten_shadows_state.ultimate_beam.user, vessel,
    "the ultimate beam records Vessel as its source")
expect(target.ten_shadows_state.ultimate_beam.damage, 580,
    "the ultimate beam uses its 580-damage full-power output")

local blocked, reason = target.ten_shadows_state:beginUltimateBeam(target, vessel)
expect(blocked, false, "a second ultimate beam cannot overwrite an active charge")
expect(type(reason), "string", "duplicate charge explains why it was blocked")

-- The actual Wave end hook consumes the charge only after the full enemy turn
-- and applies damage to the original target once.
local state = CombatState.new()
local wave_target = {
    health = 4000,
    x = 200, y = 80, width = 40, height = 30,
    hurt = function(self, amount, source)
        self.health = self.health - amount
        self.total_damage = (self.total_damage or 0) + amount
        self.last_source = source
    end,
    ten_shadows_state = state,
}
local wave_user = {chara = {id = "vessel"}}
expect(state:beginUltimateBeam(wave_target, wave_user), true,
    "Wave integration test begins a pending beam")

local visual = UltimateBeam(30, 40, 220, 95)
state.ultimate_beam.visual = visual

Wave = {
    init = function() end,
    onEnd = function(self, death) self.base_on_end = true end,
}
local KnightTitanAssault = dofile("scripts/battle/waves/knight_titan_assault.lua")
local battle = {
    enemies = {wave_target},
    getActiveEnemies = function(self) return self.enemies end,
}
Game = {battle = battle}
modRequire = function(path)
    expect(path, "scripts/ten_shadows/runtime_shadows",
        "assault Wave loads its per-enemy end-turn helper")
    return {onEnemyTurnEnd = function() end}
end

local wave = KnightTitanAssault()
wave:onEnd(false)
expect(wave.base_on_end, true, "assault Wave preserves the base end handler")
expect(wave_target.total_damage, 580,
    "the ultimate beam applies its 580 damage after one enemy Wave")
expect(wave_target.health, 3420, "the selected boss loses 580 HP")
expect(wave_target.last_source, wave_user, "the resolved beam attributes damage to Vessel")
expect(state.ultimate_beam, nil, "resolved charge is cleared")
expect(state.last_ultimate_beam.target, wave_target, "last beam records its locked target")
expect(state.last_ultimate_beam.hit, true, "last beam records a successful hit")
expect(state.last_ultimate_beam.damage, 580, "last beam records the applied damage")
expect(visual.released, true, "Wave end releases the charged visual")
expect(visual.hit, true, "visual records a confirmed hit")
expect(visual.charge_time, 7.75, "release completes the full-turn charge animation")

DT = 0.8
visual:draw()
assert(graphics.lines > 0, "ultimate beam draws its large release beam")
assert(graphics.circles > 0, "ultimate beam draws charge and impact rings")
expect(visual.base_draws, 1, "ultimate beam preserves base object drawing")
visual:update()
expect(visual.removed, true, "released ultimate beam visual cleans itself up")

-- A locked target that has already been defeated is not damaged again.
local miss_state = CombatState.new()
local defeated_target = {
    health = 0,
    hurt = function(self) error("A defeated target must not be hit again") end,
}
expect(miss_state:beginUltimateBeam(defeated_target, wave_user), true,
    "ultimate beam may finish charging after its target is defeated")
local miss_battle = {
    enemies = {{ten_shadows_state = miss_state}},
    getActiveEnemies = function(self) return self.enemies end,
}
Game.battle = miss_battle
local miss_wave = KnightTitanAssault()
miss_wave:onEnd(false)
expect(miss_state.last_ultimate_beam.hit, false,
    "a defeated locked target causes the beam to miss")
expect(miss_state.last_ultimate_beam.damage, 0,
    "a missed ultimate beam applies no damage")

print("Vessel ultimate beam one-turn charge, target lock, release, and visual tests passed.")
