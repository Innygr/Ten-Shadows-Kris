-- Mahoraga has an independent Actor identity so dedicated battle art can
-- be added later without changing Kris's shared actor configuration.
-- Until runtime-ready Mahoraga frames exist, the helper keeps Kris's known-good
-- sprite path as a safe visual fallback and records the intended asset path.
local actor, super = Class(Actor, "mahoraga")
local ActorFallback = modRequire("scripts/ten_shadows/actor_fallback")

function actor:init()
    super.init(self)
    ActorFallback.copyKrisConfiguration(self, "Mahoraga", "party/mahoraga")
    self.color = {1, 1, 1}
end

function actor:onSpriteInit(sprite)
    ActorFallback.forwardKrisSpriteInit(sprite)
end

return actor
