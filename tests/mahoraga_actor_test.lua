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
modRequire = function(path)
    assert(path == "scripts/ten_shadows/actor_fallback",
        "Mahoraga must use the shared actor fallback helper")
    return fallback
end

local mahoraga = assert(dofile("scripts/data/actors/mahoraga.lua"))
mahoraga:init()

assert(mahoraga.id == "mahoraga", "Mahoraga must have a unique actor ID")
assert(mahoraga.name == "Mahoraga", "Mahoraga actor must have its own display name")
assert(mahoraga.path == kris.path and mahoraga.default == kris.default,
    "Mahoraga must keep valid Kris frames until dedicated art is installed")
assert(mahoraga.ten_shadows_asset_path == "party/mahoraga",
    "Mahoraga actor must record its future dedicated asset path")
assert(mahoraga.ten_shadows_sprite_ready == false,
    "Mahoraga must remain on fallback frames until actual art is mapped")
assert(mahoraga.color[1] == 1 and mahoraga.color[2] == 1 and mahoraga.color[3] == 1,
    "Mahoraga actor must retain a white UI color")
assert(mahoraga.animations ~= kris.animations and mahoraga.offsets ~= kris.offsets,
    "Mahoraga must own independent animation and offset tables")
assert(mahoraga.animations["battle/idle"] ~= kris.animations["battle/idle"],
    "Mahoraga must deep-copy nested animation data")

mahoraga.animations["battle/idle"][1] = "mahoraga/idle"
mahoraga.offsets["battle/idle"][1] = -99
assert(kris.animations["battle/idle"][1] == "battle/idle",
    "Mahoraga animation changes must not mutate Kris")
assert(kris.offsets["battle/idle"][1] == -5,
    "Mahoraga offset changes must not mutate Kris")

local sprite = {}
mahoraga:onSpriteInit(sprite)
assert(sprite.kris_callback_called,
    "Mahoraga fallback must preserve the built-in sprite initialization")

local party = read("scripts/data/party/mahoraga.lua")
assert(party:find('self:setActor("mahoraga")', 1, true),
    "Mahoraga party member must use the dedicated actor")
assert(party:find("self.health = 999", 1, true),
    "Mahoraga must enter battle with 999 HP")
assert(party:find("self.color = {1, 1, 1}", 1, true),
    "Mahoraga's name and HP UI color must be white")
assert(party:find('self.menu_icon = "party/kris/head"', 1, true),
    "Mahoraga must keep a valid portrait fallback until his icon is ready")

print("Mahoraga actor identity, 999 HP, white UI, and safe sprite fallback passed.")
