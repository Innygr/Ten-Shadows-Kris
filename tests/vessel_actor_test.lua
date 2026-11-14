local kris = {
    id = "kris",
    name = "Kris",
    width = 19,
    height = 37,
    path = "party/kris",
    default = "walk",
    color = {0, 1, 1},
    animations = {
        ["battle/idle"] = {"battle/idle", 1/6, true},
        ["walk"] = {"walk", 1/8, true},
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

function ShaderFX(shader, uniforms, ...)
    return {shader = shader, uniforms = uniforms}
end

love = {
    graphics = {
        newShader = function(source)
            return {source = source}
        end,
    },
}

local vessel = assert(dofile("scripts/data/actors/vessel.lua"))
vessel:init()

assert(vessel.id == "vessel", "Vessel must retain its own actor ID")
assert(vessel.name == "Vessel", "Vessel must have its own display name")
assert(vessel.onSpriteInit ~= kris.onSpriteInit,
    "Vessel must not have its sprite callback overwritten by Kris's copied configuration")
assert(vessel.path == kris.path and vessel.default == kris.default,
    "Vessel must reuse Kris's sprite path and default animation")
assert(vessel.width == kris.width and vessel.height == kris.height,
    "Vessel must preserve Kris's actor dimensions")
assert(vessel.animations ~= kris.animations and vessel.offsets ~= kris.offsets,
    "Vessel must own independent animation and offset tables")
assert(vessel.animations["battle/idle"] ~= kris.animations["battle/idle"],
    "Vessel must deep-copy nested animation data")

vessel.animations["battle/idle"][1] = "vessel/idle"
vessel.offsets["battle/idle"][1] = -99
assert(kris.animations["battle/idle"][1] == "battle/idle",
    "Vessel animation edits must not mutate Kris")
assert(kris.offsets["battle/idle"][1] == -5,
    "Vessel offset edits must not mutate Kris")

local current_presentation = "androgynous"
Mod = {
    vessel_identity = {
        get = function()
            return {presentation = current_presentation}
        end,
    },
}

local fx = {}
local sprite = {
    scale_y = 1,
    getFX = function(self, id) return self[id] end,
    addFX = function(self, effect, id) self[id] = effect end,
}
vessel:onSpriteInit(sprite)
assert(sprite.kris_callback_called, "Vessel must preserve Kris sprite initialization")
assert(sprite.scale_y == 1.15, "Vessel sprite must be stretched vertically by exactly 1.15x")
assert(sprite.vessel_gray_red_outline, "Vessel must install its grayscale/red-outline shader")
assert(type(sprite.vessel_gray_red_outline.uniforms.vessel_presentation) == "function",
    "Vessel shader must read the saved visual presentation dynamically")
assert(sprite.vessel_gray_red_outline.uniforms.vessel_presentation() == 0,
    "Androgynous presentation must select the neutral steel palette")
current_presentation = "masculine"
assert(sprite.vessel_gray_red_outline.uniforms.vessel_presentation() == 1,
    "Masculine presentation must select its shader palette")
current_presentation = "feminine"
assert(sprite.vessel_gray_red_outline.uniforms.vessel_presentation() == 2,
    "Feminine presentation must select its shader palette")
assert(sprite.vessel_gray_red_outline.shader.source:find("dot(pixel.rgb", 1, true),
    "Vessel shader must convert the sprite to grayscale")
assert(sprite.vessel_gray_red_outline.shader.source:find("0.95, 0.035, 0.08", 1, true),
    "Vessel shader must retain its red outline")

-- Reinitialization must not stack shader effects or scale multipliers.
vessel:onSpriteInit(sprite)
assert(sprite.scale_y == 1.15, "Repeated sprite initialization must not compound Vessel's scale")
assert(sprite.vessel_gray_red_outline, "Vessel shader must remain installed after reinitialization")

local party_source = assert(io.open("scripts/data/party/vessel.lua", "r"))
local party_text = party_source:read("*a")
party_source:close()
assert(party_text:find('self:setActor("vessel")', 1, true),
    "Vessel party member must use the dedicated actor")

print("Vessel Kris-copy isolation, 1.15x vertical scale, and grayscale/red-outline shader passed")
