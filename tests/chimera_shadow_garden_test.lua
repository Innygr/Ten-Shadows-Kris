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
opening_visual:setActiveRoots({2, 7})
assert(opening_visual.active_roots[2] and opening_visual.active_roots[7],
    "the two selected roots must be highlighted in the garden")
assert(not opening_visual.active_roots[1],
    "inactive roots must remain visually distinct")
opening_visual:setActiveRoots({})
assert(not next(opening_visual.active_roots),
    "root highlights must clear when the next volley has no root attacks")
opening_visual:setActiveRoots({2, 7})

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

-- Root tips are fixed to the same ten launch coordinates used by the attack
-- planner, even after the garden's idle animation has advanced.
for index = #draw_calls, 1, -1 do
    table.remove(draw_calls, index)
end
visual:draw()
local root_endpoints = {}
for _, call in ipairs(draw_calls) do
    if call.name == "line" and #call.args == 6 then
        root_endpoints[#root_endpoints + 1] = {x = call.args[5], y = call.args[6]}
    end
end
assert(#root_endpoints == 20, "each of ten roots must draw both of its stem layers")
local root_radius = math.min(visual.width, visual.height) * 0.43 * 0.72
for index = 1, 10 do
    local angle = (index - 1) * math.pi * 2 / 10
    local expected_x = visual.width / 2 + math.cos(angle) * root_radius
    local expected_y = visual.height / 2 + math.sin(angle) * root_radius
    for layer = 1, 2 do
        local endpoint = root_endpoints[(index - 1) * 2 + layer]
        assert(math.abs(endpoint.x - expected_x) < 0.001
            and math.abs(endpoint.y - expected_y) < 0.001,
            "animated garden root tips must remain aligned to the attack launch ring")
    end
end

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
assert(wave_source:find("garden_visual:setActiveRoots(active_roots)", 1, true),
    "the Wave must highlight whichever roots launch the current volley")

print("Chimera Shadow Garden visual and Wave integration tests passed.")
