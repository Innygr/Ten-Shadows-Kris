-- Vessel uses a private copy of Kris's actor configuration, but renders it as a distinct SOUL form.
local actor, super = Class(Actor, "vessel")

local VESSEL_SHADER_SOURCE = [[
extern number vessel_presentation;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    if (pixel.a < 0.01) {
        // LÖVE 11.5 exposes the current render target dimensions through
        // love_ScreenSize; love_PixelSize is not a built-in shader variable.
        vec2 px = 1.0 / love_ScreenSize.xy;
        float around = 0.0;
        around = max(around, Texel(texture, texture_coords + vec2(-px.x, 0.0)).a);
        around = max(around, Texel(texture, texture_coords + vec2( px.x, 0.0)).a);
        around = max(around, Texel(texture, texture_coords + vec2(0.0, -px.y)).a);
        around = max(around, Texel(texture, texture_coords + vec2(0.0,  px.y)).a);
        around = max(around, Texel(texture, texture_coords + vec2(-px.x, -px.y)).a);
        around = max(around, Texel(texture, texture_coords + vec2( px.x, -px.y)).a);
        around = max(around, Texel(texture, texture_coords + vec2(-px.x,  px.y)).a);
        around = max(around, Texel(texture, texture_coords + vec2( px.x,  px.y)).a);
        if (around > 0.01) {
            return vec4(0.95, 0.035, 0.08, around) * color;
        }
        return vec4(0.0);
    }

    float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    vec3 steel;
    if (vessel_presentation < 0.5) {
        // Balanced, neutral steel.
        steel = vec3(gray * 0.88, gray * 0.90, gray * 0.94);
    } else if (vessel_presentation < 1.5) {
        // Masculine presentation: a slightly cooler graphite finish.
        steel = vec3(gray * 0.84, gray * 0.88, gray * 0.95);
    } else {
        // Feminine presentation: a slightly warmer silver finish.
        steel = vec3(gray * 0.95, gray * 0.91, gray * 0.90);
    }
    return vec4(steel, pixel.a) * color;
}
]]

-- ShaderFX resolves string IDs through Assets.getShader(). Compile this
-- inline source once and pass the resulting LÖVE shader object instead.
local vessel_shader

local function copyActorValue(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copied = {}
    seen[value] = copied
    for key, child in pairs(value) do
        copied[copyActorValue(key, seen)] = copyActorValue(child, seen)
    end
    return copied
end

function actor:init()
    super.init(self)

    -- Keep all of Kris's sprites and animation definitions, but isolate nested
    -- tables so Vessel-specific tuning can never mutate Kris's actor.
    local kris = Registry.getActor("kris")
    if kris then
        local copied_tables = {}
        for key, value in pairs(kris) do
            -- Copy serializable actor configuration, never executable callbacks.
            -- In particular, copying onSpriteInit here would overwrite Vessel's
            -- own method and silently skip its scale/shader setup.
            if key ~= "id" and type(value) ~= "function" then
                self[key] = copyActorValue(value, copied_tables)
            end
        end
    end

    local identity = Mod and Mod.vessel_identity and Mod.vessel_identity.get() or {}
    self.name = identity.name or "Vessel"
    self.gender = identity.gender or "unspecified"
    self.pronouns = identity.pronouns or "they/them"
    self.presentation = identity.presentation or "androgynous"
    self.color = {1, 0.035, 0.08}
end

function actor:onSpriteInit(sprite)
    local kris = Registry.getActor("kris")
    if kris and kris.onSpriteInit then
        kris:onSpriteInit(sprite)
    end

    -- Vessel keeps Kris's sprite proportions except for the requested 1.15x
    -- vertical stretch. Set an absolute scale so repeated init calls do not stack.
    sprite.scale_y = 1.15

    if not sprite:getFX("vessel_gray_red_outline") then
        local presentation_values = {androgynous = 0, masculine = 1, feminine = 2}
        if not vessel_shader then
            vessel_shader = love.graphics.newShader(VESSEL_SHADER_SOURCE)
        end
        sprite:addFX(ShaderFX(vessel_shader, {
            vessel_presentation = function()
                local identity = Mod and Mod.vessel_identity and Mod.vessel_identity.get() or {}
                return presentation_values[identity.presentation] or 0
            end,
        }, false, 0), "vessel_gray_red_outline")
    end
end

return actor
