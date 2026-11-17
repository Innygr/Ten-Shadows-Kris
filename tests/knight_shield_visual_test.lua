local ellipse_calls, arc_calls = 0, 0
love = {graphics = {
    push = function() end,
    pop = function() end,
    setLineWidth = function() end,
    setColor = function() end,
    ellipse = function() ellipse_calls = ellipse_calls + 1 end,
    arc = function() arc_calls = arc_calls + 1 end,
}}
DT = 1 / 30

Object = {
    init = function() end,
    update = function() end,
    draw = function() end,
}
function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {__index = base})
    return class, base
end

local Shield = dofile("scripts/battle/objects/knight_shield_visual.lua")
local shield = setmetatable({}, Shield)
shield:init(24, 40)
shield:update()
shield:draw()

assert(ellipse_calls == 2 and arc_calls == 2,
    "Knight shield must render its decorative outline")
assert(shield.collider == nil and shield.damage == nil and shield.health == nil,
    "Knight shield must have no collision, damage, or HP mechanics")
assert(shield.alpha > 0 and shield.alpha <= 1,
    "Knight shield must retain a visible pulsing alpha")

print("Knight shield visual-only rendering passed")
