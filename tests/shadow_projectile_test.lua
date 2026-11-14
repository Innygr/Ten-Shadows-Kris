-- Exercise the real bullet class with a tiny Kristal-compatible test double.
local draw_lines = 0
local draw_circles = 0
local draw_polygons = 0

love = {
    graphics = {
        setColor = function() end,
        setLineWidth = function() end,
        line = function() draw_lines = draw_lines + 1 end,
        circle = function() draw_circles = draw_circles + 1 end,
        polygon = function() draw_polygons = draw_polygons + 1 end,
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

local titan_big_shot = ShadowProjectile(70, 80, 0, 4, "titan", {
    kind = "target",
    duration = 0.4,
    length = 120,
}, {
    kind = "titan_big_shot",
    tier = 3,
})
assert(titan_big_shot.is_titan_big_shot and titan_big_shot.big_shot_tier == 3,
    "Titan Big Shot tier must survive projectile construction")
assert(titan_big_shot.collider == nil and not titan_big_shot.armed,
    "Titan Big Shots must remain harmless during their telegraph")
titan_big_shot.telegraph_timer.callback()
assert(titan_big_shot.armed and titan_big_shot.collider.radius == 9,
    "Tier-three Big Shots must arm with the largest heavy-bolt hitbox")
titan_big_shot:draw()
assert(titan_big_shot.base_draw_count == 1,
    "Big Shot rendering must still call the base bullet draw")

local collision_shot = ShadowProjectile(72, 82, 0, 4, "knight", nil, {
    kind = "knight_titan_collision", source = "knight", path = 1,
    collision_x = 320, collision_y = 220,
})
assert(collision_shot.is_knight_titan_collision,
    "Collision marker must survive projectile construction")
collision_shot:draw()
assert(draw_polygons > 0, "Collision projectile must render its convergence flare")

local titan_hand = ShadowProjectile(70, 80, 0, 4, "titan", {
    kind = "lane",
    duration = 0.5,
    length = 168,
}, {
    kind = "titan_hand",
    side = "left",
    finger = 2,
})
assert(titan_hand.is_titan_hand, "Titan hand marker must survive projectile construction")
assert(titan_hand.width == 18 and titan_hand.height == 18,
    "Titan hand projectiles must use the larger fist footprint")
assert(not titan_hand.armed and titan_hand.collider == nil,
    "Titan hand projectiles must remain harmless during their lane tell")
titan_hand.telegraph_timer.callback()
assert(titan_hand.armed and titan_hand.collider.radius == 6,
    "Titan hand must retain its larger hitbox when the tell completes")
titan_hand:draw()
assert(draw_polygons > 0, "Titan hand projectile must draw its dedicated fist silhouette")
assert(titan_hand.base_draw_count == 1,
    "Titan hand rendering must still call the base bullet draw")

-- Chimera Shadow Garden root blades retain their dedicated marker through
-- telegraphing and render with the leaf-shaped violet projectile.
local domain_blade = ShadowProjectile(88, 96, math.pi / 2, 5, "combo", {
    kind = "target",
    duration = 0.44,
    length = 96,
}, {
    kind = "chimera_domain_blade",
    root = 3,
    side = "left",
})
assert(domain_blade.is_chimera_domain_blade,
    "Kris's domain root blade marker must survive projectile construction")
assert(domain_blade.collider == nil and not domain_blade.armed,
    "domain root blades must remain harmless until their warning completes")
domain_blade:draw()
assert(draw_lines >= 2, "domain root blade must add a violet tell over its trajectory")
domain_blade.telegraph_timer.callback()
assert(domain_blade.armed and domain_blade.collider.radius == 5,
    "domain root blade must arm with its dedicated hitbox")
domain_blade:draw()
assert(draw_polygons >= 2, "domain root blade must render its leaf-shaped visual")

-- The Roaring's dark shards keep a safe tell, dedicated hitbox, and
-- separate final-phase silhouette.
local roaring_shard = ShadowProjectile(92, 104, math.pi / 4, 6, "knight", {
    kind = "target",
    duration = 0.40,
    length = 124,
}, {
    kind = "roaring_shard",
    spoke = 2,
    safe_wedge = 1,
    opposite_wedge = 6,
})
assert(roaring_shard.is_roaring_shard,
    "The Roaring marker must survive projectile construction")
assert(not roaring_shard.armed and roaring_shard.collider == nil
    and roaring_shard.physics.speed == 0,
    "The Roaring shard must remain harmless during its tell")
roaring_shard:draw()
assert(draw_lines >= 4,
    "The Roaring shard must layer its dark-red warning over the standard trajectory")
roaring_shard.telegraph_timer.callback()
assert(roaring_shard.armed and roaring_shard.collider.radius == 6
    and roaring_shard.physics.speed == 6,
    "The Roaring shard must arm with its dedicated hitbox and speed")
local polygons_before_roar = draw_polygons
roaring_shard:draw()
assert(draw_polygons > polygons_before_roar,
    "The Roaring shard must render its dark angular silhouette")

print("Shadow projectile telegraph/arming and Titan hand rendering tests passed.")
