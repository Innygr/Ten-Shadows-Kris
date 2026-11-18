local calls = {}
local function record(name)
    return function(...)
        calls[#calls + 1] = {name = name, args = {...}}
    end
end
Object = {init = function() end, update = function() end, draw = function() end}
function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {__index = base})
    return class, base
end
love = {graphics = {
    push = record("push"), pop = record("pop"), setColor = record("setColor"),
    setLineWidth = record("setLineWidth"), rectangle = record("rectangle"),
    ellipse = record("ellipse"), circle = record("circle"),
    line = record("line"), polygon = record("polygon"),
}}
DT = 0.25
local Barrier = dofile("scripts/battle/objects/vessel_domain_barrier.lua")
local visual = setmetatable({}, Barrier)
visual:init(180, 142, true)
assert(visual.width == 180 and visual.height == 142,
    "Vessel barrier must use the active arena dimensions")
assert(visual.opening == 1 and visual.layer == 0,
    "new Vessel Domain must begin its expansion pulse on the arena mask")
visual:update()
assert(visual.time > 0 and visual.opening < 1 and visual.opening > 0,
    "Vessel barrier animation and opening pulse must advance")
visual:draw()
local counts = {}
for _, call in ipairs(calls) do counts[call.name] = (counts[call.name] or 0) + 1 end
assert(counts.push == 1 and counts.pop == 1,
    "Vessel barrier must restore LÖVE graphics state")
assert((counts.polygon or 0) >= 4,
    "Vessel Domain must render a layered six-sided barrier and central seal")
assert((counts.circle or 0) >= 25,
    "Vessel Domain must render six gates, central rings, sparks, and bloom")
assert((counts.line or 0) >= 12,
    "Vessel Domain must connect the six gates with energy traces")
print("Vessel Domain barrier visual tests passed")
