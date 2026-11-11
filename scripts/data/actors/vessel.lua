-- Vessel uses Kris's complete actor/animation set, but renders it as a distinct SOUL form.
local actor, super = Class(Actor, "vessel")

local VESSEL_SHADER = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    if (pixel.a < 0.01) {
        vec2 px = love_PixelSize;
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
    vec3 steel = vec3(gray * 0.88, gray * 0.90, gray * 0.94);
    return vec4(steel, pixel.a) * color;
}
]]

function actor:init()
    super.init(self)

    -- Clone Kris's actor data so every animation and sprite name remains valid,
    -- without mutating the shared Kris actor.
    local kris = Registry.getActor("kris")
    if kris then
        for key, value in pairs(kris) do
            if key ~= "id" then
                self[key] = value
            end
        end
    end

    self.name = "Vessel"
    self.color = {1, 0.035, 0.08}
end

function actor:onSpriteInit(sprite)
    local kris = Registry.getActor("kris")
    if kris and kris.onSpriteInit then
        kris:onSpriteInit(sprite)
    end
    if not sprite:getFX("vessel_gray_red_outline") then
        sprite:addFX(ShaderFX(VESSEL_SHADER, {}, 0), "vessel_gray_red_outline")
    end
end

return actor
