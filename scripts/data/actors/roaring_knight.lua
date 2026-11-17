local actor, super = Class(Actor, "roaring_knight")
local ActorFallback = modRequire("scripts/ten_shadows/actor_fallback")

function actor:init()
    super.init(self)

    -- This is a distinct actor, not a shared reference to Kris's Actor table.
    -- Keep Kris's path/animations until real Knight frames are available.
    ActorFallback.copyKrisConfiguration(
        self,
        "The Roaring Knight",
        "enemies/roaring_knight"
    )
end

function actor:onSpriteInit(sprite)
    ActorFallback.forwardKrisSpriteInit(sprite)
end

return actor
