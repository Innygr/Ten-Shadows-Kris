-- Exercise the real bullet class with a tiny Kristal-compatible test double.
local draw_lines = 0
local draw_circles = 0

love = {
    graphics = {
        setColor = function() end,
        setLineWidth = function() end,
        line = function() draw_lines = draw_lines + 1 end,
        circle = function() draw_circles = draw_circles + 1 end,
        polygon = function() end,
    }
}

local BaseBullet = {}

function BaseBullet:init(x, y)
    self.x = x
    self.y = y
    self.physics = {}
    self.children = {}
end

function BaseBullet:addChild(child)
    self.children[#self.children + 1] = child
    child.parent = self
end

function BaseBullet:draw()
    self.base_draw_count = (self.base_draw_count or 0) + 1
end

Bullet = BaseBullet

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

function CircleCollider(object, x, y, radius)
    return {object = object, x = x, y = y, radius = radius}
end

function Timer()
    local timer = {}
    function timer:after(delay, callback)
        self.delay = delay
        self.callback = callback
    end
    return timer
end

local ShadowProjectile = dofile("scripts/battle/bullets/shadow_projectile.lua")

local immediate = ShadowProjectile(10, 20, math.pi, 4, "knight")
assert(immediate.armed, "ordinary projectiles should start armed")
assert(immediate.collider ~= nil, "ordinary projectiles should have a hitbox")
assert(immediate.physics.speed == 4, "ordinary projectiles should preserve their speed")

local warning = ShadowProjectile(30, 40, 0, 5, "titan", {
    kind = "lane",
    duration = 0.42,
    length = 160,
})
local execution = ShadowProjectile(50, 60, math.pi, 6, "knight", {
    kind = "target",
    duration = 0.55,
    length = 120,
}, {
    kind = "execution_slash",
})
assert(execution.is_execution_slash, "Knight's Execution marker must survive projectile construction")
assert(not warning.armed, "telegraphed projectiles must start unarmed")
assert(warning.collider == nil, "telegraph must not damage the player before launch")
assert(warning.physics.speed == 0, "telegraph must remain stationary")
assert(warning.telegraph_timer and warning.telegraph_timer.delay == 0.42,
    "telegraph must schedule its arming delay")

warning:draw()
assert(draw_lines >= 2, "telegraph should draw a visible attack lane")
assert(warning.base_draw_count == 1, "telegraph should still call the base bullet draw")

warning.telegraph_timer.callback()
assert(warning.armed, "projectile should arm when its warning timer completes")
assert(warning.telegraph == nil, "warning visual should be removed on launch")
assert(warning.collider ~= nil, "projectile should gain its hitbox when armed")
assert(warning.physics.speed == 5, "projectile should begin moving at its configured speed")

warning:draw()
assert(draw_circles > 0, "armed projectile should draw its normal body")
assert(warning.base_draw_count == 2, "armed projectile should still call the base bullet draw")

print("Shadow projectile telegraph/arming tests passed.")
