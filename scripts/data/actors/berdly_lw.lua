-- Light World Berdly actor. Until original runtime-ready Berdly artwork is
-- available, this variant safely reuses Kris's Light World sprite configuration.
-- Switch its path to party/berdly/light only after compatible frames exist there.
-- Its nested tables are copied so Berdly-specific work cannot mutate Kris.
local actor, super = Class(Actor, "berdly_lw")

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

    local kris_lw = Registry.getActor("kris_lw")
    if kris_lw then
        local copied_tables = {}
        for key, value in pairs(kris_lw) do
            if key ~= "id" then
                self[key] = copyActorValue(value, copied_tables)
            end
        end
    end

    self.name = "Berdly"
    self.color = {0.12, 0.32, 0.78}
end

function actor:onSpriteInit(sprite)
    local kris_lw = Registry.getActor("kris_lw")
    if kris_lw and kris_lw.onSpriteInit then
        kris_lw:onSpriteInit(sprite)
    end
end

return actor
