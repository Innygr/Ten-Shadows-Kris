local actor, super = Class(Actor, "berdly")
local ActorFallback = modRequire("scripts/ten_shadows/actor_fallback")

function actor:init()
    super.init(self)
    ActorFallback.copyKrisConfiguration(self, "Berdly", "party/berdly/dark")
    self.color = {0.12, 0.32, 0.78}
end

function actor:onSpriteInit(sprite)
    ActorFallback.forwardKrisSpriteInit(sprite)
end

return actor
