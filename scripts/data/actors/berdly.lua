-- Berdly currently borrows Kris's animation definitions as a safe fallback.
-- Keep a separate Actor registry entry so Berdly can receive his own sprite
-- mappings without changing Kris or Vessel.
local actor, super = Class(Actor, "berdly")

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

    local kris = Registry.getActor("kris")
    if kris then
        -- Actor settings include nested animation/offset tables. Deep-copy
        -- them so a future Berdly override cannot mutate Kris's shared data.
        local copied_tables = {}
        for key, value in pairs(kris) do
            if key ~= "id" then
                self[key] = copyActorValue(value, copied_tables)
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
