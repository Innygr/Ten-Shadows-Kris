-- Berdly currently borrows Kris's working sprite configuration as a safe
-- fallback. Keep a distinct Actor registry entry so dedicated art can be
-- added later without changing Kris.
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
        local copied_tables = {}
        for key, value in pairs(kris) do
            if key ~= "id" then
                self[key] = copyActorValue(value, copied_tables)
            end
        end
    end

    self.name = "Berdly"
    self.color = {0.12, 0.32, 0.78}
    -- Reserved destination for dedicated art; the live path remains Kris's
    -- proven sprite set until Berdly's mapped frames are ready.
    self.ten_shadows_asset_path = "party/berdly/dark"
end

function actor:onSpriteInit(sprite)
    local kris = Registry.getActor("kris")
    if kris and kris.onSpriteInit then
        kris:onSpriteInit(sprite)
    end
end

return actor
