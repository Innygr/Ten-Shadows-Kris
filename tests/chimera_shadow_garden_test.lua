-- Draw-level regression test for the Chimera Shadow Garden visual.
local draw_calls = {}
local function record(name)
    return function(...)
        draw_calls[#draw_calls + 1] = {name = name, args = {...}}
    end
end

Object = {
    init = function(self) self.children = {} end,
    update = function() end,
    draw = function() end,
}

function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {
        __index = base,
        __call = function(cls, ...)
            local instance = setmetatable({}, cls)
            if instance.init then instance:init(...) end
            return instance
        end,
    })
    return class, base
end

love = {graphics = {
    push = record("push"),
    pop = record("pop"),
    setColor = record("setColor"),
    rectangle = record("rectangle"),
    ellipse = record("ellipse"),
    circle = record("circle"),
    line = record("line"),
    polygon = record("polygon"),
    setLineWidth = record("setLineWidth"),
}}

local Garden = dofile("scripts/battle/objects/chimera_shadow_garden.lua")
local visual = Garden(180, 142)
assert(visual.width == 180 and visual.height == 142, "garden must use the arena's dimensions")
assert(visual.time == 0 and visual.fade == 1 and visual.opening == 0,
    "an already-active garden must appear without replaying its opening bloom")
assert(visual.layer == 0, "garden must inherit the arena mask's visual layer")
local opening_visual = Garden(180, 142, true)
assert(opening_visual.fade == 0 and opening_visual.opening == 1,
    "first activation must start with an outward expansion bloom")

DT = 0.25
visual:update()
opening_visual:update()
assert(visual.time > 0, "garden idle animation must advance")
assert(opening_visual.opening < 1 and opening_visual.opening > 0,
    "the one-time opening bloom must animate outward")
opening_visual:draw()

local counts = {}
for _, call in ipairs(draw_calls) do
    counts[call.name] = (counts[call.name] or 0) + 1
end
assert(counts.push == 1 and counts.pop == 1, "garden draw must restore the graphics state")
assert((counts.rectangle or 0) >= 2, "garden must tint and frame the arena")
assert((counts.ellipse or 0) >= 2, "garden must draw layered shadow pools")
assert((counts.line or 0) >= 10, "garden must draw branching shadow roots")
assert((counts.circle or 0) >= 33,
    "garden must draw the expansion rings, central seal, and drifting motes")
assert((counts.polygon or 0) >= 20, "garden must draw ten shadow petals and boundary marks")

-- Ensure the live Wave attaches the effect to Arena.mask only while Kris's
-- three-turn domain is active. This is also a guard against an unreferenced
-- visual file accidentally passing the draw-only test.
local wave_file = assert(io.open("scripts/battle/waves/knight_titan_assault.lua", "r"))
local wave_source = wave_file:read("*a")
wave_file:close()
assert(wave_source:find("state.player_domain.active", 1, true),
    "the Knight + Titan Wave must check the active player domain")
assert(wave_source:find("player_domain.visual_pending", 1, true),
    "the first Wave must consume Kris's one-time opening animation flag")
assert(wave_source:find("spawnObjectTo(arena.mask", 1, true),
    "the garden must be attached to the arena mask")
assert(wave_source:find("scripts/battle/objects/chimera_shadow_garden", 1, true),
    "the live Wave must load the Chimera Shadow Garden object")
assert(wave_source:find("GardenVisual(arena.width, arena.height, opening)", 1, true),
    "the Wave must pass the opening animation state to the garden object")

print("Chimera Shadow Garden visual and Wave integration tests passed.")
