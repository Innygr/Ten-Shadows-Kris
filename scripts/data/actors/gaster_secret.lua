local actor, super = Class(Actor, "gaster_secret")

function actor:init()
    super.init(self)

    self.name = "W.D. Gaster"
    -- Keep Gaster's proportions, but make the sprite and its collision
    -- dimensions half their previous size.
    self.width = 48
    self.height = 96
    self.path = "enemies/gaster_secret"
    self.default = "idle"
    self.default_sprite = "idle"
    self.color = {0.62, 0.55, 0.78}
    self.animations = {}
    self.offsets = {}
end

function actor:onSpriteInit(sprite)
    sprite.scale_x = 0.5
    sprite.scale_y = 0.5
end

return actor
