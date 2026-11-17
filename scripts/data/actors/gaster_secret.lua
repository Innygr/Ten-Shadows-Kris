local actor, super = Class(Actor, "gaster_secret")
local ActorFallback = modRequire("scripts/ten_shadows/actor_fallback")

function actor:init()
    super.init(self)
    ActorFallback.copyKrisConfiguration(self, "W.D. Gaster", "enemies/gaster_secret")
end

function actor:onSpriteInit(sprite)
    ActorFallback.forwardKrisSpriteInit(sprite)
end

return actor
