-- Regression test for THE ROARING's central safe-route indicator.
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
    setLineWidth = record("setLineWidth"),
    circle = record("circle"),
    line = record("line"),
    polygon = record("polygon"),
}}

local RoaringCore = dofile("scripts/battle/objects/roaring_core.lua")
local visual = RoaringCore(180, 142)
assert(visual.width == 180 and visual.height == 142,
    "the Roaring core must match the active arena dimensions")
assert(not visual.has_safe_route and visual.fade == 0,
    "the indicator must wait for the first volley before showing safe spokes")
assert(visual:setSafeWedges(2, 7, 0.035),
    "the visual must accept two opposite safe spokes and their rotation")
assert(visual.safe_wedges[2] and visual.safe_wedges[7]
    and not visual.safe_wedges[0],
    "only the two selected spokes may be marked safe")
assert(math.abs(visual.rotation - 0.035) < 0.0001,
    "safe-spoke markers must follow the pattern's radial rotation")
assert(not visual:setSafeWedges(2, 6, 0),
    "the visual must reject a pair that is not opposite")
assert(not visual:setSafeWedges(10, 5, 0),
    "the visual must reject spoke indices outside the ten-spoke ring")

DT = 0.25
visual:update()
assert(visual.time > 0 and visual.fade > 0,
    "the central indicator must animate and fade in")
visual:draw()

local counts = {}
for _, call in ipairs(draw_calls) do
    counts[call.name] = (counts[call.name] or 0) + 1
end
assert(counts.push == 1 and counts.pop == 1,
    "the Roaring visual must restore LÖVE's graphics state")
assert((counts.circle or 0) >= 14,
    "the visual must draw the core, rings, and all ten spoke markers")
assert((counts.line or 0) == 10,
    "all ten spoke directions must be drawn")
assert((counts.polygon or 0) == 2,
    "both safe directions must receive a distinct outward chevron")

-- Ensure the live Wave updates the central marker from the actual pattern data.
local wave_file = assert(io.open("scripts/battle/waves/knight_titan_assault.lua", "r"))
local wave_source = wave_file:read("*a")
wave_file:close()
assert(wave_source:find('scripts/battle/objects/roaring_core', 1, true),
    "the boss Wave must load the Roaring core visual")
assert(wave_source:find('marker.safe_wedge', 1, true)
    and wave_source:find('marker.opposite_wedge', 1, true)
    and wave_source:find('marker.rotation', 1, true),
    "the Wave must pass both safe spokes and the radial angle to the visual")
assert(wave_source:find('roaring_visual:setSafeWedges(', 1, true),
    "the safe-route indicator must update on each volley")

print("THE ROARING safe-route core visual and Wave integration tests passed.")
