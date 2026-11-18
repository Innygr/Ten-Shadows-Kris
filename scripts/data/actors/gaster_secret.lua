local actor, super = Class(Actor, "gaster_secret")

function actor:init()
    super.init(self)

    self.name = "W.D. Gaster"
    self.width = 96
    self.height = 192
    self.path = "enemies/gaster_secret"
    self.default = "idle"
    self.default_sprite = "idle"
    self.color = {0.62, 0.55, 0.78}
    self.animations = {}
    self.offsets = {}
end

return actor
