local function read(path)
    local file = assert(io.open(path, "r"))
    local value = file:read("*a")
    file:close()
    return value
end

local manifest = read("assets/sprites/characters/berdly/animation-map.json")
local expected_groups = {
    "Berdly (Unused)",
    "Berdly Attack",
    "Berdly Attack Unhappy",
    "Berdly Battle Idle",
    "Berdly Battle Idle Right",
    "Berdly Battle Idle Unhappy",
    "Berdly Fly",
    "Berdly Halbird",
    "Berdly Laugh",
    "Berdly Pointing Up",
    "Berdly Walk Down",
    "Berdly Walk Down (Dark World)",
    "Berdly Walk Down Book",
    "Berdly Walk Left",
    "Berdly Walk Left (Dark World)",
    "Berdly Walk Left Book",
    "Berdly Walk Right",
    "Berdly Walk Right (Dark World)",
    "Berdly Walk Right Book",
    "Berdly Walk Up",
    "Berdly Walk Up (Dark World)",
    "Berdly Walk Up Book",
    "Noelle Choking Berdly",
}

for _, group in ipairs(expected_groups) do
    assert(manifest:find('"source_group": "' .. group .. '"', 1, true),
        "Berdly animation map is missing source group: " .. group)
end

assert(#expected_groups == 23, "Berdly reference should list 23 animation groups")
assert(manifest:find('"frame_data_status": "not-mapped"', 1, true),
    "Frame data must remain explicitly unmapped until exact authorized frame metadata is available")
assert(manifest:find('"actor_id": "berdly"', 1, true),
    "Animation map must target the dedicated Berdly actor")
assert(not manifest:find('"frame_rectangles"', 1, true),
    "Do not invent frame rectangles without inspecting the actual authorized source frames")

print("Berdly animation-map source groups and frame-metadata safeguards passed")
