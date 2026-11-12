-- Regression test for Berdly's independent actor configuration.
local kris_lw = {
    id = "kris_lw",
    name = "Kris",
    width = 19,
    height = 37,
    path = "party/kris/light",
    default = "walk",
    color = {0, 1, 1},
    animations = {},
    mirror_sprites = { ["walk/down"] = "walk/up" },
    offsets = { ["walk/down"] = {0, 0} },
}

local kris = {
    id = "kris",
    name = "Kris",
    width = 19,
    height = 37,
    path = "party/kris/dark",
    default = "walk",
    color = {0, 1, 1},
    animations = {
        ["battle/idle"] = {"battle/idle", 1/6, true},
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
        if id == "kris_lw" then return kris_lw end
        return nil
    end,
}

local berdly = assert(dofile("scripts/data/actors/berdly.lua"))
berdly:init()

assert(berdly.id == "berdly", "Berdly must retain his own actor ID")
assert(berdly.name == "Berdly", "Berdly must have his own display name")
assert(berdly.color[3] > berdly.color[1], "Berdly must retain his blue actor color")
assert(berdly.path == kris.path and berdly.default == kris.default,
    "Berdly fallback must keep valid Kris sprite paths until Berdly art is mapped")
assert(berdly.width == kris.width and berdly.height == kris.height,
    "Berdly fallback must preserve valid actor dimensions")
assert(berdly.animations ~= kris.animations, "Berdly animation table must not be shared with Kris")
assert(berdly.offsets ~= kris.offsets, "Berdly offset table must not be shared with Kris")
assert(berdly.animations["battle/idle"] ~= kris.animations["battle/idle"],
    "Nested Berdly animation data must also be copied")

berdly.animations["battle/idle"][1] = "berdly/idle"
berdly.animations["battle/custom"] = {"berdly/custom", 1/8, true}
berdly.offsets["battle/idle"][1] = -99
assert(kris.animations["battle/idle"][1] == "battle/idle",
    "Changing Berdly's animation must not alter Kris")
assert(kris.animations["battle/custom"] == nil,
    "Adding a Berdly animation must not alter Kris")
assert(kris.offsets["battle/idle"][1] == -5,
    "Changing Berdly's offsets must not alter Kris")

local sprite = {}
berdly:onSpriteInit(sprite)
assert(sprite.kris_callback_called, "Berdly must preserve Kris sprite initialization behavior")

print("Berdly actor identity, fallback configuration, deep-copy isolation, and sprite callback checks passed")

local berdly_lw = assert(dofile("scripts/data/actors/berdly_lw.lua"))
berdly_lw:init()

assert(berdly_lw.id == "berdly_lw", "Light World Berdly must have its own actor ID")
assert(berdly_lw.name == "Berdly", "Light World Berdly must have its own display name")
assert(berdly_lw.path == kris_lw.path and berdly_lw.default == kris_lw.default,
    "Light World fallback must use the valid Light World actor sprite path")
assert(berdly_lw.width == kris_lw.width and berdly_lw.height == kris_lw.height,
    "Light World Berdly fallback must preserve actor dimensions")
assert(berdly_lw.mirror_sprites ~= kris_lw.mirror_sprites,
    "Light World Berdly must not share mirror mappings with Kris")
assert(berdly_lw.offsets ~= kris_lw.offsets,
    "Light World Berdly must not share offset mappings with Kris")
berdly_lw.mirror_sprites["walk/down"] = "berdly_custom/up"
berdly_lw.offsets["walk/down"][1] = 99
assert(kris_lw.mirror_sprites["walk/down"] == "walk/up",
    "Changing Berdly's Light World mirror mapping must not alter Kris")
assert(kris_lw.offsets["walk/down"][1] == 0,
    "Changing Berdly's Light World offsets must not alter Kris")

print("Berdly Dark World and Light World actor identities remain independent")
