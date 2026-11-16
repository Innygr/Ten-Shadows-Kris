-- Runtime behaviour tests for the Vessel's custom Kristal Soul classes.
local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local graphics = {}
for _, name in ipairs({"push", "pop", "setColor", "setLineWidth", "line", "circle"}) do
    graphics[name] = function() end
end
love = {graphics = graphics}

local input_down, input_pressed = {}, {}
Input = {
    down = function(key) return input_down[key] == true end,
    pressed = function(key)
        local value = input_pressed[key] == true
        input_pressed[key] = false
        return value
    end,
}
local function press(key)
    input_down[key] = true
    input_pressed[key] = true
end
local function release(key)
    input_down[key] = false
    input_pressed[key] = false
end
local function clearPressed()
    input_pressed = {}
end

DT = 0.1
DTMULT = 1
SCREEN_WIDTH = 640
BATTLE_LAYERS = {bullets = 10}
Bullet = {}

local BaseSoul = {}
function BaseSoul:init(x, y, color)
    self.x, self.y, self.color = x or 0, y or 0, color or {1, 0, 0}
    self.sprite = {rotation = 0}
    self.speed = 4
    self.can_move = true
    self.transitioning = false
    self.inv_flash_timer = 0
end
function BaseSoul:update()
    if self.can_move then self:doMovement() end
    self.base_update_count = (self.base_update_count or 0) + 1
end
function BaseSoul:doMovement()
    local x, y = 0, 0
    if Input.down("left") then x = x - 1 end
    if Input.down("right") then x = x + 1 end
    if Input.down("up") then y = y - 1 end
    if Input.down("down") then y = y + 1 end
    self.moving_x, self.moving_y = x, y
    if x ~= 0 or y ~= 0 then self:move(x, y, self.speed * DTMULT) end
end
function BaseSoul:move(x, y, speed)
    self.x = self.x + x * speed
    self.y = self.y + y * speed
    return true, false
end
function BaseSoul:getExactPosition()
    return self.x, self.y
end
function BaseSoul:setPosition(x, y)
    self.x, self.y = x, y
end
function BaseSoul:setExactPosition(x, y)
    self.x, self.y = x, y
end
function BaseSoul:onCollide(bullet)
    self.base_collision_count = (self.base_collision_count or 0) + 1
    if bullet.onCollide then bullet:onCollide(self) end
end
function BaseSoul:draw() end

Soul = BaseSoul

local BaseObject = {}
function BaseObject:init(x, y)
    self.x, self.y = x or 0, y or 0
    self.removed = false
end
function BaseObject:update() end
function BaseObject:draw() end
function BaseObject:remove()
    self.removed = true
end
Object = BaseObject

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

local arena = {
    left = 0, right = 200, top = 0, bottom = 200,
    getLeft = function(self) return self.left end,
    getRight = function(self) return self.right end,
    getTop = function(self) return self.top end,
    getBottom = function(self) return self.bottom end,
}
local spawned = {}
local active_bullets = {}
Game = {
    battle = {
        state = "DEFENDING",
        arena = arena,
        addChild = function(_, object) spawned[#spawned + 1] = object end,
        enemies = {},
    },
    stage = {
        getObjects = function(_, class)
            expect(class, Bullet, "Yellow shot queries enemy bullets")
            return active_bullets
        end,
    },
}
Game.battle.getActiveEnemies = function() return Game.battle.enemies end
local YellowShot = dofile("scripts/objects/yellow_shot.lua")
modRequire = function(path)
    if path == "scripts/objects/yellow_shot" then return YellowShot end
    if path == "scripts/objects/cyan_soul" then return dofile("scripts/objects/cyan_soul.lua") end
    error("Unexpected Soul-mode module: " .. tostring(path))
end

-- BLUE: gravity accelerates the SOUL downward, and Up jumps against it.
local BlueSoul = dofile("scripts/objects/blue_soul.lua")
local blue = BlueSoul(60, 40)
local blue_start_y = blue.y
blue:update()
assert(blue.y > blue_start_y and blue.blue_velocity_y > 0,
    "Blue SOUL must accelerate downward under gravity")
blue.y = arena.bottom - 8
blue.blue_grounded = true
press("up")
blue:update()
release("up")
assert(blue.blue_velocity_y < 0 and blue.y < arena.bottom - 8,
    "Blue SOUL must jump upward when Up is pressed")

-- GREEN: arrow keys aim a directional shield; frontal projectiles are blocked.
local GreenSoul = dofile("scripts/objects/green_soul.lua")
local green = GreenSoul(100, 100)
press("left")
green:update()
release("left")
expect(green.green_direction, "left", "Green shield points in the selected direction")
local frontal = {
    x = 80, y = 100, removed = false,
    remove = function(self) self.removed = true end,
}
green:onCollide(frontal)
expect(frontal.removed, true, "Green shield removes a projectile from its facing side")
local rear = {
    x = 120, y = 100, removed = false,
    onCollide = function(self) self.hit = true end,
    remove = function(self) self.removed = true end,
}
green:onCollide(rear)
expect(rear.hit, true, "Green shield does not block projectiles from behind")

-- YELLOW: the SOUL faces right; a tap fires a small shot and a hold fires a big one.
local YellowSoul = dofile("scripts/objects/yellow_soul.lua")
local yellow = YellowSoul(40, 80)
expect(yellow.sprite.rotation, math.pi / 2, "Yellow SOUL faces right")
press("confirm")
yellow:update()
release("confirm")
yellow:update()
expect(yellow.yellow_fire_count, 1, "Yellow tap fires exactly one projectile")
expect(yellow.yellow_last_charged, false, "quick Yellow press creates a normal shot")
expect(spawned[1].charged, false, "normal Yellow projectile is small")

press("confirm")
for _ = 1, 9 do
    yellow:update()
    clearPressed()
end
release("confirm")
yellow:update()
expect(yellow.yellow_fire_count, 2, "charged Yellow release fires exactly once")
expect(yellow.yellow_last_charged, true, "holding Yellow confirm charges a large projectile")
expect(spawned[2].charged, true, "charged Yellow projectile is large")

local incoming = {
    x = 110, y = 80, armed = true, removed = false,
    remove = function(self) self.removed = true end,
}
active_bullets = {incoming}
spawned[1].x = 100
spawned[1].y = 80
spawned[1]:update()
expect(incoming.removed, true, "Yellow shot clears enemy projectiles in its path")

-- ORANGE: charge then release to dash forward; the dash phases through bullets.
local OrangeSoul = dofile("scripts/objects/orange_soul.lua")
local orange = OrangeSoul(40, 120)
local orange_start_x = orange.x
press("confirm")
for _ = 1, 4 do orange:update(); clearPressed() end
release("confirm")
orange:update()
expect(orange.orange_dashing, true, "Orange release starts a forward dash")
assert(orange.x > orange_start_x, "Orange dash propels the SOUL forward")
expect(orange.noclip, true, "Orange dash temporarily phases through solid barriers")
local phase_bullet = {
    removed = false,
    remove = function(self) self.removed = true end,
    onCollide = function(self) self.hit = true end,
}
orange:onCollide(phase_bullet)
expect(phase_bullet.removed, true, "Orange dash passes through incoming projectiles")
expect(phase_bullet.hit, nil, "Orange dash prevents projectile damage while phasing")
for _ = 1, 10 do orange:update(); clearPressed() end
expect(orange.orange_dashing, false, "Orange dash ends after its burst duration")
expect(orange.noclip, false, "Orange restores normal collision after its dash")

-- PURPLE: the SOUL is constrained to tracks, with Up/Down changing lanes.
local PurpleSoul = dofile("scripts/objects/purple_soul.lua")
local purple = PurpleSoul(100, 100)
expect(purple.purple_lane, 3, "Purple starts on the closest track")
press("down")
purple:update()
release("down")
expect(purple.purple_lane, 4, "Purple Down moves to the next track")
expect(purple.y, purple.purple_lane_y, "Purple remains aligned with its selected track")
local purple_x = purple.x
input_down.right = true
purple:update()
input_down.right = false
assert(purple.x > purple_x, "Purple moves horizontally along its track")

-- The encounter factory must build the matching live controller for every mode.
local function newBaseSoul(x, y, color)
    local soul = setmetatable({}, {__index = Soul})
    soul:init(x, y, color)
    return soul
end
Encounter = {
    createSoul = function(_, x, y, color) return newBaseSoul(x, y, color) end,
}
local Preview = dofile("scripts/battle/encounters/knight_titan_preview.lua")
modRequire = function(path)
    local map = {
        ["scripts/objects/blue_soul"] = BlueSoul,
        ["scripts/objects/green_soul"] = GreenSoul,
        ["scripts/objects/yellow_soul"] = YellowSoul,
        ["scripts/objects/orange_soul"] = OrangeSoul,
        ["scripts/objects/purple_soul"] = PurpleSoul,
    }
    if map[path] then return map[path] end
    if path == "scripts/objects/cyan_soul" then
        return function(x, y)
            return {x = x, y = y, ten_shadows_mode = "cyan", is_cyan_soul = true}
        end
    end
    error("Unexpected Soul factory path: " .. tostring(path))
end
local State = dofile("scripts/ten_shadows/combat_state.lua")
local state = State.new()
Game.battle.enemies = {{ten_shadows_state = state}}
for _, mode in ipairs({"blue", "green", "yellow", "orange", "purple", "cyan"}) do
    state:setSoulMode(mode)
    local soul = Preview.createSoul({}, 80, 90, {1, 0, 0})
    expect(soul.ten_shadows_mode, mode, mode .. " factory returns its matching controller")
end

-- Choosing a mode through ACT must swap the live Soul object immediately.
Game.battle.encounter = Preview
Game.battle.swapSoul = function(self, replacement)
    self.soul = replacement
    self.swap_count = (self.swap_count or 0) + 1
end
Game.battle.soul = newBaseSoul(22.25, 33.75, {1, 0, 0})
Game.battle.soul.inv_flash_timer = 0.42
local old_soul = Game.battle.soul
local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
local mode_enemy = {ten_shadows_state = state}
local vessel_battler = {chara = {id = "vessel"}}
local action_text = BossActions.onAct(mode_enemy, vessel_battler, "YELLOW SOUL", function()
    error("SOUL mode action must be handled by the custom dispatcher")
end)
assert(type(action_text) == "string", "SOUL mode ACT returns encounter text")
expect(Game.battle.swap_count, 1, "SOUL mode selection swaps the live object")
expect(Game.battle.soul == old_soul, false, "previous SOUL object is replaced")
expect(Game.battle.soul.ten_shadows_mode, "yellow", "replacement Soul uses the selected mode")
expect(Game.battle.soul.x, 22.25, "Soul swap preserves fractional x-position")
expect(Game.battle.soul.y, 33.75, "Soul swap preserves fractional y-position")
expect(Game.battle.soul.inv_flash_timer, 0.42, "Soul swap preserves damage-flash animation time")

print("Blue gravity, Green shield, Yellow shooting/charge, Orange dash, Purple tracks, and SOUL factory tests passed.")
