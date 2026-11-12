-- Berdly currently borrows Kris's animation definitions as a safe fallback.
-- This gives Berdly a distinct Actor registry entry so his real sprite sheet can
-- be mapped independently without changing Kris's actor or Vessel's shader.
-- Replace the inherited sprite/animation paths when licensed runtime-ready
-- Berdly frames are added under assets/sprites/characters/berdly/.
local actor, super = Class(Actor, "berdly")

function actor:init()
    super.init(self)

    local kris = Registry.getActor("kris")
    if kris then
        for key, value in pairs(kris) do
            if key ~= "id" then
                self[key] = value
            end
        end
    end

    self.name = "Berdly"
    self.color = {0.12, 0.32, 0.78}
end

function actor:onSpriteInit(sprite)
    local kris = Registry.getActor("kris")
    if kris and kris.onSpriteInit then
        kris:onSpriteInit(sprite)
    end
end

return actor
