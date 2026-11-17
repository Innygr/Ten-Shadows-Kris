local function read(path)
    local file = assert(io.open(path, "r"))
    local value = file:read("*a")
    file:close()
    return value
end

local kris = {
    id = "kris",
    name = "Kris",
    width = 19,
    height = 37,
    path = "party/kris",
    default = "walk",
    color = {0, 1, 1},
    animations = {
        ["battle/idle"] = {"battle/idle", 1 / 6, true},
        ["battle/attack"] = {"battle/attack", 1 / 8, false},
    },
    offsets = {
        ["battle/idle"] = {-5, -1},
    },
    onSpriteInit = function(self, sprite)
        sprite.kris_callback_called = true
    end,
}

Actor = {
    init = function(self)
        self.width = 0
        self.height = 0
        self.animations = {}
        self.offsets = {}
    end,
}

function Class(_, id)
    return {}, {
        init = function(self)
            Actor.init(self)
            self.id = id
        end,
    }
end

Registry = {
    getActor = function(id)
        if id == "kris" then return kris end
        return nil
    end,
}

local fallback = dofile("scripts/ten_shadows/actor_fallback.lua")
function modRequire(path)
    assert(path == "scripts/ten_shadows/actor_fallback", "Unexpected module requested: " .. tostring(path))
    return fallback
end

local knight_class = assert(dofile("scripts/data/actors/roaring_knight.lua"))
local titan_class = assert(dofile("scripts/data/actors/roaring_knight_titan.lua"))

local knight = {}
knight_class.init(knight)
local titan = {}
titan_class.init(titan)

assert(knight.id == "roaring_knight", "Knight must retain its dedicated Actor ID")
assert(titan.id == "roaring_knight_titan", "Titan must retain its dedicated Actor ID")
assert(knight.name == "The Roaring Knight" and titan.name == "The Titan",
    "Each boss must have its own display name")
assert(knight.ten_shadows_asset_path == "enemies/roaring_knight",
    "Knight must declare its future runtime sprite root")
assert(titan.ten_shadows_asset_path == "enemies/roaring_knight_titan",
    "Titan must declare its future runtime sprite root")
assert(not knight.ten_shadows_sprite_ready and not titan.ten_shadows_sprite_ready,
    "Actors must not claim dedicated sprites are ready before frames are mapped")

assert(knight.path == kris.path and titan.path == kris.path,
    "Both actors must use valid Kris sprite paths until their art is present")
assert(knight.width == kris.width and knight.height == kris.height,
    "Knight fallback must preserve Kris's valid dimensions")
assert(titan.width == kris.width and titan.height == kris.height,
    "Titan fallback must preserve Kris's valid dimensions")

assert(knight.animations ~= kris.animations and titan.animations ~= kris.animations,
    "Boss animation maps must be isolated from Kris")
assert(knight.animations ~= titan.animations,
    "Knight and Titan animation maps must also be isolated from one another")
assert(knight.offsets ~= kris.offsets and titan.offsets ~= kris.offsets,
    "Boss offset maps must be isolated from Kris")

knight.animations["battle/idle"][1] = "knight/custom"
titan.animations["battle/idle"][1] = "titan/custom"
knight.offsets["battle/idle"][1] = -40
assert(kris.animations["battle/idle"][1] == "battle/idle",
    "Editing Knight animations must not mutate Kris")
assert(kris.animations["battle/idle"][1] == "battle/idle",
    "Editing Titan animations must not mutate Kris")
assert(titan.animations["battle/idle"][1] == "titan/custom",
    "Editing Knight animations must not mutate Titan")
assert(kris.offsets["battle/idle"][1] == -5,
    "Editing Knight offsets must not mutate Kris")

local knight_sprite, titan_sprite = {}, {}
knight_class.onSpriteInit(knight, knight_sprite)
titan_class.onSpriteInit(titan, titan_sprite)
assert(knight_sprite.kris_callback_called and titan_sprite.kris_callback_called,
    "Fallback actors must preserve Kris's sprite initialization behavior")

local knight_enemy = read("scripts/battle/enemies/roaring_knight.lua")
local titan_enemy = read("scripts/battle/enemies/roaring_knight_titan.lua")
assert(knight_enemy:find('self:setActor("roaring_knight")', 1, true),
    "Knight battler must use its dedicated Actor")
assert(titan_enemy:find('self:setActor("roaring_knight_titan")', 1, true),
    "Titan battler must use its dedicated Actor")
assert(not knight_enemy:find('self:setActor("kris")', 1, true),
    "Knight battler must not directly borrow Kris's Actor")
assert(not titan_enemy:find('self:setActor("kris")', 1, true),
    "Titan battler must not directly borrow Kris's Actor")

print("Knight and Titan Actor identities, fallback paths, and configuration isolation passed")
