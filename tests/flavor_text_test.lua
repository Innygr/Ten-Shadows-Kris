local FlavorText = dofile("scripts/ten_shadows/flavor_text.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

expect(FlavorText.has("roaring_knight.early"), true, "early key exists")
expect(
    FlavorText.get("roaring_knight.early", {}, {random = function() return 1 end}),
    "* The red SOUL flickers beside {vessel_name}.",
    "early text retains the Vessel name placeholder"
)
expect(
    FlavorText.get("roaring_knight.opening", {}, {random = function() return 1 end}),
    "* The Knight raises its blade at {vessel_name}.",
    "opening dialogue retains the Vessel name placeholder"
)

FlavorText.register("test.multiple", {
    "First variant",
    "Second variant",
})
expect(FlavorText.count("test.multiple"), 2, "multiple variants registered")
expect(
    FlavorText.get("test.multiple", {}, {random = function() return 2 end}),
    "Second variant",
    "random selector chooses requested variant"
)
expect(
    FlavorText.get("test.multiple", {}, {
        previous = "First variant",
        random = function() return 1 end,
    }),
    "Second variant",
    "previous line is avoided when another exists"
)

FlavorText.register("test.multiple", {"Third variant"})
expect(FlavorText.count("test.multiple"), 3, "second registration appends")

FlavorText.register("test.conditional", {
    {text = "Phase one", when = function(state) return state.phase == 1 end},
    {text = "Phase three", when = function(state) return state.phase == 3 end},
})
expect(
    FlavorText.get("test.conditional", {phase = 3}),
    "Phase three",
    "conditional variant"
)
expect(
    FlavorText.get("test.conditional", {phase = 2}, {fallback = "Fallback"}),
    "Fallback",
    "fallback when no condition matches"
)
expect(
    FlavorText.get("not.registered", {}, {fallback = "Missing"}),
    "Missing",
    "fallback for unknown key"
)

-- Vessel identity placeholders are expanded only when an identity provider is active.
Mod = {
    vessel_identity = {
        format = function(text)
            return text:gsub("{vessel_name}", "Rowan"):gsub("{vessel_subject}", "they")
        end
    }
}
FlavorText.register("test.identity", {"{vessel_name} said {vessel_subject} were ready."})
expect(FlavorText.get("test.identity"), "Rowan said they were ready.", "Vessel identity formatting")

FlavorText.register("test.identity.repeat", {
    "{vessel_name} watches the arena.",
    "{vessel_name} waits for the next move.",
})
expect(
    FlavorText.get("test.identity.repeat", {}, {random = function() return 1 end}),
    "Rowan watches the arena.",
    "formatted first variant"
)
expect(
    FlavorText.get("test.identity.repeat", {}, {
        previous = "Rowan watches the arena.",
        random = function() return 1 end,
    }),
    "Rowan waits for the next move.",
    "formatted previous line is avoided"
)
Mod = nil

print("Flavor text tests passed.")
