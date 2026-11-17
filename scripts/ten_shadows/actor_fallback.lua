-- Helpers for giving a character a distinct Actor registry identity before its
-- dedicated pixel-art frames are ready. Each target receives a deep copy of
-- Kris's known-good configuration so later animation edits stay isolated.
local ActorFallback = {}

local function copyValue(value, seen)
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
        copied[copyValue(key, seen)] = copyValue(child, seen)
    end
    return copied
end

function ActorFallback.copyKrisConfiguration(target, display_name, asset_path)
    local kris = Registry.getActor("kris")
    assert(kris, "Ten Shadows Kris: the built-in Kris actor is unavailable")

    local copied_tables = {}
    for key, value in pairs(kris) do
        if key ~= "id" then
            target[key] = copyValue(value, copied_tables)
        end
    end

    target.name = display_name
    target.ten_shadows_asset_path = asset_path
    target.ten_shadows_sprite_ready = false
end

function ActorFallback.forwardKrisSpriteInit(sprite)
    local kris = Registry.getActor("kris")
    if kris and kris.onSpriteInit then
        kris:onSpriteInit(sprite)
    end
end

return ActorFallback
