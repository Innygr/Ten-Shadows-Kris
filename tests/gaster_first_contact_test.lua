-- Verify Gaster's first wave emits six spaced volleys and the bullet config is valid.
local function expect(actual, wanted, label)
    assert(actual == wanted, label .. ": expected " .. tostring(wanted) .. ", got " .. tostring(actual))
end

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

local every_callback
local after_callback
local every_interval
local every_limit
Wave = {
    init = function(self)
        self.timer = {
            every = function(_, interval, callback, limit)
                every_interval = interval
                every_limit = limit
                every_callback = callback
            end,
            after = function(_, delay, callback)
                assert(delay > 0, "the wave should leave a short end pause")
                after_callback = callback
            end,
        }
    end,
}

Game = {
    battle = {
        arena = {
            left = 100,
            right = 300,
            top = 50,
            bottom = 190,
            width = 200,
            height = 140,
        },
    },
}

local WaveClass = dofile("scripts/battle/waves/gaster_first_contact.lua")
local wave = WaveClass()
expect(wave.time, 7.2, "Gaster's first attack duration")
local spawned = {}
function wave:spawnBullet(id, x, y, direction, speed, phase)
    spawned[#spawned + 1] = {
        id = id, x = x, y = y, direction = direction, speed = speed, phase = phase,
    }
end
function wave:setFinished()
    self.finished = true
end

wave:onStart()
expect(every_interval, 0.82, "volley interval")
expect(every_limit, 6, "volley count")
assert(type(every_callback) == "function", "the wave must register its volley callback")

for volley = 1, 6 do
    every_callback()
end

expect(#spawned, 30, "six volleys with one safe lane each")
assert(type(after_callback) == "function", "the final volley must schedule wave completion")

for volley = 1, 6 do
    local gap = (volley * 2) % 5
    local expected_origin = volley % 2 == 0 and 300 + 14 or 100 - 14
    local direction = volley % 2 == 0 and math.rad(180) or 0
    local expected_speed = 3.2 + (volley % 3) * 0.35
    local seen_lanes = {}
    local volley_bullets = 0
    for _, bullet in ipairs(spawned) do
        if bullet.x == expected_origin and bullet.direction == direction and bullet.speed == expected_speed then
            local lane = math.floor((bullet.y - 50) / (140 / 7) + 0.5)
            volley_bullets = volley_bullets + 1
            assert(lane ~= gap + 1, "volley " .. volley .. " must leave its designated safe lane open")
            seen_lanes[lane] = true
            expect(bullet.id, "gaster_bullet", "Gaster projectile registry ID")
            assert(type(bullet.phase) == "number", "each bullet must receive a stable visual phase")
        end
    end
    expect(volley_bullets, 5, "projectiles emitted per volley")
    for lane = 1, 6 do
        expect(seen_lanes[lane] == true, lane == gap + 1 and false or true,
            "volley " .. volley .. " lane " .. lane .. " occupancy")
    end
end

after_callback()
expect(wave.finished, true, "the wave must finish after its end pause")

local collider
Bullet = {
    init = function(self, x, y)
        self.x, self.y = x, y
        self.physics = {}
    end,
    draw = function() end,
}
CircleCollider = function(owner, x, y, radius)
    collider = {owner = owner, x = x, y = y, radius = radius}
    return collider
end
local BulletClass = dofile("scripts/battle/bullets/gaster_bullet.lua")
local bullet = BulletClass(10, 20, math.pi, 3.5, 1.25)
expect(bullet.width, 14, "Gaster bullet sprite width")
expect(bullet.height, 14, "Gaster bullet sprite height")
expect(bullet.damage, 3, "Gaster bullet damage")
expect(bullet.physics.direction, math.pi, "Gaster bullet direction")
expect(bullet.physics.speed, 3.5, "Gaster bullet speed")
expect(collider.radius, 5, "Gaster bullet collision radius")

print("Gaster first-contact wave and projectile tests passed.")
