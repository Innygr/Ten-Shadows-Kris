-- Test the live Granite Blast ACT route and its charge/launch effect.
local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local graphics
graphics = {lines = 0, circles = 0}
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

Object = {}
function Object:init(x, y) self.x, self.y = x or 0, y or 0 end
function Object:update() end
function Object:remove() self.removed = true end
function Object:draw() self.base_draws = (self.base_draws or 0) + 1 end

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

DT = 0.31
local GraniteBlast = dofile("scripts/battle/objects/granite_blast.lua")

local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local state = CombatState.new()
expect(state:expandFusionDomain(true), true, "test setup activates the Fusion Domain")

local spawned = {}
local battle = {
    arena = {x = 100, y = 200, width = 140, height = 120},
    soul = {x = 124, y = 248},
    addChild = function(self, child)
        spawned[#spawned + 1] = child
        child.parent = self
    end,
}
local target = {
    x = 400, y = 80, width = 20, height = 30,
    hurt = function(self, amount, user)
        self.damage = (self.damage or 0) + amount
        self.last_user = user
    end,
}
local user = {chara = {id = "vessel"}}
Game = {battle = battle}
modRequire = function(path)
    expect(path, "scripts/battle/objects/granite_blast",
        "live Granite Blast loads its presentation object")
    return GraniteBlast
end

target.ten_shadows_state = state
local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
local result = BossActions.onAct(target, user, "GRANITE BLAST", function()
    error("Granite Blast must not fall through to the engine ACT handler")
end)

expect(type(result), "table", "successful Granite Blast returns battle dialogue")
expect(target.damage, 58, "100% Granite Blast deals 58 damage once")
expect(target.last_user, user, "Granite Blast records Vessel as the attacker")
expect(state.fusion_domain.portal_routes, 1, "live V-ACT increments the real portal route counter")
expect(#spawned, 1, "live V-ACT spawns exactly one visual effect")

local visual = spawned[1]
expect(visual.entry.x, 216, "entry portal is placed opposite the exit")
expect(visual.entry.y, 272, "entry portal uses the mirrored y position")
expect(visual.exit.x, 124, "exit portal follows the active SOUL x position")
expect(visual.exit.y, 248, "exit portal follows the active SOUL y position")
expect(visual.target.x, 410, "blast targets the selected enemy's horizontal centre")
expect(visual.target.y, 95, "blast targets the selected enemy's vertical centre")
visual:update()
expect(visual.fired, true, "the blast enters its launch phase after charging")
visual:draw()
expect(graphics.lines > 0, "the launch phase draws a beam through the exit portal")
expect(graphics.circles > 0, "the blast draws entry, exit, and impact rings")
expect(visual.base_draws, 1, "the visual preserves the base Object draw")
DT = 0.5
visual:update()
expect(visual.removed, true, "the temporary V-ACT visual cleans itself up")

-- The handler must fail closed outside the active Domain: no damage, no
-- visual, and no portal route should be recorded.
local inactive_state = CombatState.new()
local inactive_target = {
    x = 10, y = 20,
    hurt = function(self, amount) self.damage = (self.damage or 0) + amount end,
    ten_shadows_state = inactive_state,
}
local before_spawn = #spawned
local denied = BossActions.onAct(inactive_target, user, "GRANITE BLAST", function()
    error("Unavailable Granite Blast must not fall through")
end)
expect(type(denied), "string", "inactive Domain returns an explanation")
expect(inactive_target.damage, nil, "inactive Domain cannot damage the selected boss")
expect(#spawned, before_spawn, "inactive Domain cannot create a visual")
expect(inactive_state.fusion_domain.portal_routes, 0,
    "inactive Domain cannot increment the route count")

-- The live menu only offers the V-ACT submenu while the shared Domain is up.
local mod_file = assert(io.open("mod.lua", "r"))
local mod_source = mod_file:read("*a")
mod_file:close()
assert(mod_source:find("boss_state.fusion_domain.active", 1, true),
    "Vessel's V-ACT submenu must be gated by the active Fusion Domain")

print("Granite Blast live routing, damage, visual, and Domain gating tests passed.")
