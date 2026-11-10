-- Ten Shadows Kris: data-driven flavor text registry.
-- Pure Lua 5.1 so it can be tested outside Kristal and reused by battle scripts.

local FlavorText = {}
local entries = {}

local function validateEntry(entry)
    if type(entry) == "string" then
        return {text = entry}
    end
    if type(entry) ~= "table" or type(entry.text) ~= "string" then
        error("Flavor text entries must be strings or tables with a text field.", 3)
    end
    if entry.when ~= nil and type(entry.when) ~= "function" then
        error("Flavor text entry 'when' must be a function.", 3)
    end
    return {
        text = entry.text,
        when = entry.when,
        tag = entry.tag,
    }
end

-- Registering the same ID more than once appends variants to that ID.
function FlavorText.register(id, lines)
    if type(id) ~= "string" or id == "" then
        error("Flavor text ID must be a non-empty string.", 2)
    end
    if type(lines) ~= "table" or #lines == 0 then
        error("Flavor text registration needs a non-empty array.", 2)
    end

    entries[id] = entries[id] or {}
    for _, entry in ipairs(lines) do
        entries[id][#entries[id] + 1] = validateEntry(entry)
    end
end

-- options.previous is the previously displayed line for this ID.
-- options.random(max) may be supplied by tests or a seeded encounter RNG.
function FlavorText.get(id, state, options)
    state = state or {}
    options = options or {}

    local registered = entries[id]
    if not registered then
        return options.fallback
    end

    local candidates = {}
    for _, entry in ipairs(registered) do
        local allowed = true
        if entry.when then
            local ok, result = pcall(entry.when, state)
            allowed = ok and not not result
        end
        if allowed then
            candidates[#candidates + 1] = entry
        end
    end

    if #candidates == 0 then
        return options.fallback
    end

    local previous = options.previous
    local pool = {}
    for _, entry in ipairs(candidates) do
        if entry.text ~= previous then
            pool[#pool + 1] = entry
        end
    end
    if #pool == 0 then
        pool = candidates
    end

    local pick
    if options.random then
        pick = options.random(#pool)
    else
        pick = math.random(#pool)
    end
    if type(pick) ~= "number" then
        error("Flavor text random selector must return a number.", 2)
    end
    pick = math.floor(pick)
    if pick < 1 or pick > #pool then
        error("Flavor text random selector returned an out-of-range index.", 2)
    end

    return pool[pick].text
end

function FlavorText.has(id)
    return entries[id] ~= nil
end

function FlavorText.count(id)
    return entries[id] and #entries[id] or 0
end

-- Confirmed Roaring Knight encounter text.
FlavorText.register("roaring_knight.early", {
    "You feel incoming dread."
})

FlavorText.register("roaring_knight.opening", {
    "No one is holding back anymore... Do your best. The fate of the world is in your hands"
})

FlavorText.register("roaring_knight.battle", {
    "All the winds blow fiercely."
})

FlavorText.register("items.odd_radio.inspect", {
    "A very, very interesting old radio. Wonder what it's for."
})

FlavorText.register("items.mayo_armor.inspect", {
    "It's mayonnaise. Somehow, it's protective."
})

FlavorText.register("gaster.radio_hint", {
    "Very, very interesting."
})

return FlavorText
