local actor, super = Class(Actor, "roaring_knight_titan")
local ActorFallback = modRequire("scripts/ten_shadows/actor_fallback")

function actor:init()
    super.init(self)

    -- The Titan has its own Actor identity and future sprite root. Its current
    -- frames remain a safe Kris fallback until dedicated Titan art is ready.
    ActorFallback.copyKrisConfiguration(
        self,
        "The Titan",
        "enemies/roaring_knight_titan"
    )
end

function actor:onSpriteInit(sprite)
    ActorFallback.forwardKrisSpriteInit(sprite)
end

return actor
